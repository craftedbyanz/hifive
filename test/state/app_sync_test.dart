import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hifive/app/app.dart';
import 'package:hifive/data/data.dart';
import 'package:hifive/domain/models/models.dart';
import 'package:hifive/domain/repositories/repositories.dart';
import 'package:hifive/domain/sync/sync.dart';
import 'package:hifive/features/profile/profile.dart';
import 'package:hifive/features/welcome/welcome.dart';
import 'package:hifive/l10n/l10n.dart';
import 'package:hifive/state/state.dart';

import '../helpers.dart';
import '../sync_fakes.dart';

final _t = DateTime(2026, 11, 10, 9);
const _lan = AuthUser(uid: 'u1', method: AuthMethod.email, email: 'lan@x.vn');

AppState _device(
  FakeSyncServer server, {
  MemoryRecordStore? store,
  AuthUser? user = _lan,
  DateTime Function()? clock,
  MemoryAuthService? auth,
}) => createAppState(
  store: store ?? MemoryRecordStore(),
  auth: auth ?? MemoryAuthService(signedIn: user),
  sync: server,
  feedback: SilentFeedback(),
  now: clock ?? () => _t,
);

void main() {
  late FakeSyncServer server;
  final opened = <AppState>[];
  setUp(() => server = FakeSyncServer());
  tearDown(() {
    for (final s in opened) {
      s.dispose();
    }
    opened.clear();
  });
  Future<AppState> open(AppState s) async {
    opened.add(s);
    await s.load();
    await s.sync();
    return s;
  }

  test('without a sync API nothing syncs and sign-out keeps data', () async {
    final store = MemoryRecordStore();
    final s = createAppState(
      store: store,
      auth: MemoryAuthService(signedIn: _lan),
      feedback: SilentFeedback(),
    );
    opened.add(s);
    await s.load();
    s.setName('Lan');
    await s.sync();
    await s.signOut();
    expect(s.name, 'Lan');
    expect(store.data(RecordKind.setting, 'name'), {'v': 'Lan'});
  });

  test('opening the app pulls what another device saved', () async {
    final ipad = await open(_device(server));
    ipad.setName('Linh');
    await ipad.sync();
    final iphone = await open(_device(server));
    expect(iphone.name, 'Linh');
    expect(iphone.lastSyncedAt, _t);
    expect(iphone.syncError, isNull);
  });

  test('signing in pushes what was done as a guest', () async {
    final auth = MemoryAuthService();
    final guest = await open(_device(server, user: null, auth: auth));
    guest.setName('Mai');
    await guest.flush();
    expect(server.requests, 0);
    await guest.signInWithGoogle();
    await guest.sync();
    final uid = guest.user!.uid;
    expect(server.recordsOf(uid).singleWhere((r) => r.id == 'name').data, {
      'v': 'Mai',
    });
  });

  test('an edit after pulling a device with a fast clock still wins', () async {
    final ahead = await open(
      _device(server, clock: () => _t.add(const Duration(hours: 1))),
    );
    ahead.setName('Từ máy chạy nhanh');
    await ahead.sync();
    final behind = await open(_device(server));
    expect(behind.name, 'Từ máy chạy nhanh');
    behind.setName('Sửa sau');
    await behind.sync();
    await ahead.sync();
    expect(ahead.name, 'Sửa sau');
  });

  test(
    'signing out pushes, clears the device and signing in restores',
    () async {
      final store = MemoryRecordStore();
      final auth = MemoryAuthService(signedIn: _lan);
      final s = await open(_device(server, store: store, auth: auth));
      s
        ..setName('Lan')
        ..setVoice('Mia')
        ..finishGame(20, clearResume: true);
      expect(await s.pushBeforeSignOut(), isTrue);
      await s.signOut();
      await s.flush();
      expect((s.user, s.name, s.voice, s.totalXp), (null, 'An', 'Aaron', 0));
      expect(store.records.keys.map((k) => k.$1), ['firstUse']);
      expect(await store.meta(Syncer.cursorKey('u1')), isNull);
      expect(await store.meta('deviceId'), isNotNull);

      final again = await open(_device(server, store: store));
      expect((again.name, again.voice, again.totalXp), ('Lan', 'Mia', 20));
    },
  );

  test('a failed push before sign-out is reported', () async {
    final s = await open(_device(server));
    s.setName('Lan');
    await s.flush();
    server.failBefore = SyncError.unavailable;
    expect(await s.pushBeforeSignOut(), isFalse);
    expect(s.syncError, SyncError.unavailable);
    expect(s.user, isNotNull);
  });

  test('sign-out resets every setting to a fresh install', () async {
    final s = await open(_device(server));
    s
      ..setName('X')
      ..setLevel('C1')
      ..setAppearance('Mono')
      ..setInputColor('Blue')
      ..setVoice('Mia')
      ..setDifficulty('Khó')
      ..setChatTone('Trang trọng')
      ..setChatFree(false)
      ..setShowHints(true)
      ..setSound(false)
      ..setHaptic(false)
      ..setLanguage(Language.japanese)
      ..dismissChatTip()
      ..moveMode(0, 2)
      ..saveGameProgress({'title': 'T'});
    await s.signOut();
    final fresh = _device(server, user: null);
    opened.add(fresh);
    String snapshot(AppState a) => [
      a.name,
      a.level,
      a.appearance,
      a.inputColor,
      a.voice,
      a.difficulty,
      a.chatTone,
      a.chatFree,
      a.showHints,
      a.sound,
      a.haptic,
      a.language,
      a.chatTipSeen,
      a.modeOrder,
      a.gameResume,
      a.gamesPlayed,
      a.decks.length,
    ].join('|');
    expect(snapshot(s), snapshot(fresh));
  });

  testWidgets('changes sync once, a while after the last one', (tester) async {
    final s = _device(server);
    opened.add(s);
    await s.load();
    await s.sync();
    final after = server.requests;
    s
      ..setName('A')
      ..setName('B');
    await tester.pump(const Duration(seconds: 10));
    s.setName('C');
    await tester.pump(const Duration(seconds: 10));
    expect(server.requests, after);
    await tester.pump(AppState.syncDelay);
    await tester.pump();
    expect(server.requests, after + 1);
    expect(server.recordsOf('u1').singleWhere((r) => r.id == 'name').data, {
      'v': 'C',
    });
    s.dispose();
    opened.remove(s);
  });

  testWidgets('leaving the app syncs at once', (tester) async {
    final s = _device(server);
    opened.add(s);
    await s.load();
    await s.sync();
    s.setName('Lan');
    final before = server.requests;
    s.appPaused();
    await tester.pump();
    expect(server.requests, before + 1);
    s.dispose();
    opened.remove(s);
  });

  group('Profile', () {
    setUpAll(loadAppFonts);

    testWidgets('without the sync API the account line has no sync status', (
      tester,
    ) async {
      final s = fresh(auth: MemoryAuthService(signedIn: _lan));
      await mount(
        tester,
        s,
        const ProfileScreen(),
        size: const Size(393, 2100),
      );
      expect(find.text('Email'), findsNothing);
      expect(syncStatus(s, lookupAppLocalizations(const Locale('vi'))), isNull);
    });

    test('status reads naturally', () {
      final s = _device(server);
      opened.add(s);
      s.lastSyncedAt = _t.subtract(const Duration(minutes: 3));
      expect(
        syncStatus(s, lookupAppLocalizations(const Locale('vi'))),
        'Đã đồng bộ lúc 08:57',
      );
      s.lastSyncedAt = DateTime(2026, 11, 8, 20);
      expect(
        syncStatus(s, lookupAppLocalizations(const Locale('vi'))),
        'Đã đồng bộ 8/11',
      );
      s.syncError = SyncError.unavailable;
      expect(
        syncStatus(s, lookupAppLocalizations(const Locale('vi'))),
        'Chưa đồng bộ được',
      );
      s.syncing = true;
      expect(
        syncStatus(s, lookupAppLocalizations(const Locale('vi'))),
        'Đang đồng bộ...',
      );
    });

    testWidgets('a failed push asks again before signing out', (tester) async {
      final store = MemoryRecordStore();
      final s = _device(server, store: store);
      await s.load();
      await s.sync();
      s.setName('Lan');
      server.failBefore = SyncError.unavailable;
      await mount(
        tester,
        s,
        const ProfileScreen(),
        size: const Size(393, 2100),
      );
      await tester.tap(find.byKey(const ValueKey('profile-logout')));
      await tester.pumpAndSettle();
      expect(find.textContaining('sẽ bị xoá khỏi máy này'), findsOneWidget);
      await tester.tap(find.text('Đăng xuất').last);
      await tester.pumpAndSettle();
      expect(find.text('Chưa đồng bộ xong'), findsOneWidget);
      await tester.tap(find.text('Huỷ'));
      await tester.pumpAndSettle();
      expect(s.user, isNotNull);
      expect(s.name, 'Lan');
      s.dispose();
    });
  });
}
