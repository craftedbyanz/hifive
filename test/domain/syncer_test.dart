import 'package:flutter_test/flutter_test.dart';
import 'package:hifive/app/app.dart';
import 'package:hifive/data/data.dart';
import 'package:hifive/domain/models/models.dart';
import 'package:hifive/domain/repositories/repositories.dart';
import 'package:hifive/domain/sync/sync.dart';
import 'package:hifive/state/state.dart';

import '../sync_fakes.dart';

/// One device: its own store and clock, signed in as [uid].
class _Device {
  final MemoryRecordStore store = MemoryRecordStore();
  final DateTime Function() clock;
  late AppState state;
  late String id;
  _Device(this.clock);

  Future<void> open() async {
    state = createAppState(
      store: store,
      feedback: SilentFeedback(),
      now: clock,
    );
    await state.load();
    id = (await store.meta('deviceId'))!;
  }

  Future<SyncOutcome> sync(SyncService server, {String uid = 'u1'}) async {
    await state.flush();
    return Syncer(
      store: store,
      service: server,
    ).run(uid: uid, deviceId: id, idToken: 'token-$uid');
  }

  /// What a fresh launch on this device would show.
  Future<AppState> reopened() async {
    final next = createAppState(
      store: store,
      feedback: SilentFeedback(),
      now: clock,
    );
    await next.load();
    return next;
  }
}

void main() {
  final t = DateTime(2026, 11, 10, 9);
  late FakeSyncServer server;
  late _Device iphone, ipad;
  setUp(() async {
    server = FakeSyncServer();
    iphone = _Device(() => t);
    ipad = _Device(() => t.add(const Duration(minutes: 1)));
    await iphone.open();
    await ipad.open();
  });

  Future<void> syncBoth() async {
    await iphone.sync(server);
    await ipad.sync(server);
    await iphone.sync(server);
  }

  test('settings changed on each device both arrive on both', () async {
    iphone.state.setVoice('Mia');
    ipad.state.setAppearance('Mono');
    await syncBoth();
    for (final device in [iphone, ipad]) {
      final s = await device.reopened();
      expect((s.voice, s.appearance), ('Mia', 'Mono'));
    }
  });

  test('the later change to one setting wins on both', () async {
    iphone.state.setName('Lan');
    ipad.state.setName('Linh');
    await syncBoth();
    expect((await iphone.reopened()).name, 'Linh');
    expect((await ipad.reopened()).name, 'Linh');
  });

  test('reviews of one card on two devices both count', () async {
    final word = iphone.state.decks.first.words.first;
    iphone.state.rate(word, 2);
    ipad.state.rate(ipad.state.decks.first.words.first, 2);
    await syncBoth();
    final card = (await iphone.reopened()).decks.first.words.first;
    // Good, then Good again a minute later: the same-day review nudges the
    // three-day interval up.
    expect(card.status, 'review');
    expect(card.intervalDays, greaterThan(3));
  });

  test('games, saved words and results merge', () async {
    iphone.state
      ..finishGame(10, clearResume: true)
      ..saveWord('Sorry', 'xin lỗi');
    ipad.state
      ..finishGame(30, clearResume: true)
      ..saveWord('sorry', 'xin lỗi');
    await syncBoth();
    final s = await iphone.reopened();
    expect((s.gamesPlayed, s.totalXp, s.bestScore), (2, 40, 30));
    expect(s.decks.singleWhere((d) => d.id == 'saved').words, hasLength(1));
  });

  test(
    'clearing history hides older results everywhere, not later ones',
    () async {
      const lesson = Lesson(
        id: 'l',
        title: 'L',
        description: '',
        mode: StudyMode.grammar,
        questions: [],
      );
      StudySession at(String id, DateTime date) => StudySession(
        id: id,
        lesson: lesson,
        date: date,
        answers: const [],
        seconds: 1,
      );
      ipad.state.complete(at('old', t.subtract(const Duration(hours: 1))));
      await ipad.sync(server);
      iphone.state.clearHistory();
      ipad.state.complete(at('later', t.add(const Duration(hours: 1))));
      await syncBoth();
      expect((await ipad.reopened()).history.map((s) => s.id), ['later']);
      expect((await iphone.reopened()).history.map((s) => s.id), ['later']);
    },
  );

  test('device-only settings never leave the device', () async {
    iphone.state.setSound(false);
    await syncBoth();
    expect((await ipad.reopened()).sound, isTrue);
    expect(
      server.recordsOf('u1').where((r) => r.kind == RecordKind.device),
      isEmpty,
    );
  });

  test('a lost response is retried without duplicates', () async {
    iphone.state.setName('Lan');
    server.dropResponse = true;
    await expectLater(iphone.sync(server), throwsA(isA<SyncException>()));
    expect(iphone.store.dirty, isNotEmpty);
    final retry = await iphone.sync(server);
    expect(iphone.store.dirty, isEmpty);
    expect(retry.pushed, greaterThan(0));
    expect(server.recordsOf('u1').where((r) => r.id == 'name'), hasLength(1));
  });

  test('a failed request leaves everything to push next time', () async {
    iphone.state.setName('Lan');
    server.failBefore = SyncError.unavailable;
    await expectLater(iphone.sync(server), throwsA(isA<SyncException>()));
    expect(server.recordsOf('u1'), isEmpty);
    await iphone.sync(server);
    await ipad.sync(server);
    expect((await ipad.reopened()).name, 'Lan');
  });

  test('a change made during a request is pushed by a second round', () async {
    iphone.state.setName('Lan');
    await iphone.state.flush();
    server.during = () async {
      server.during = null;
      iphone.state.setName('Linh');
      await iphone.state.flush();
    };
    await iphone.sync(server);
    // The first round's "Lan" couldn't clear the newer record's flag, so
    // the same sync pushed "Linh" in a second request.
    expect(server.requests, 2);
    expect(iphone.store.dirty, isEmpty);
    expect(server.recordsOf('u1').singleWhere((r) => r.id == 'name').data, {
      'v': 'Linh',
    });
  });

  test('pulls page through many changes', () async {
    server = FakeSyncServer(pageSize: 3);
    for (var i = 0; i < 10; i++) {
      iphone.state.saveWord('word$i', 'nghĩa $i');
    }
    await iphone.sync(server);
    final outcome = await ipad.sync(server);
    expect(outcome.pulled, greaterThanOrEqualTo(11));
    final saved = (await ipad.reopened()).decks.singleWhere(
      (d) => d.id == 'saved',
    );
    expect(saved.words, hasLength(10));
    expect(server.requests, greaterThan(4));
  });

  test('the outcome reports the latest pulled stamp', () async {
    ipad.state.setName('Linh');
    await ipad.sync(server);
    final outcome = await iphone.sync(server);
    final stamps = server.recordsOf('u1').map((r) => r.hlc).toList()..sort();
    expect(outcome.latest, stamps.last);
  });

  test('each account keeps its own cursor', () async {
    ipad.state.setName('Linh');
    await ipad.sync(server);
    await iphone.sync(server);
    final u1 = await iphone.store.meta(Syncer.cursorKey('u1'));
    expect(int.parse(u1!), greaterThan(0));
    await iphone.sync(server, uid: 'u2');
    expect(await iphone.store.meta(Syncer.cursorKey('u2')), '0');
    expect(await iphone.store.meta(Syncer.cursorKey('u1')), u1);
  });

  test('a bad token is reported, not retried', () async {
    await expectLater(
      Syncer(
        store: iphone.store,
        service: server,
      ).run(uid: 'u1', deviceId: iphone.id, idToken: 'expired'),
      throwsA(
        isA<SyncException>().having(
          (e) => e.error,
          'error',
          SyncError.unauthorized,
        ),
      ),
    );
    expect(server.requests, 1);
  });
}
