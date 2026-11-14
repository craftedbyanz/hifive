import 'package:flutter_test/flutter_test.dart';
import 'package:hifive/app/app.dart';
import 'package:hifive/data/data.dart';
import 'package:hifive/domain/repositories/repositories.dart';
import 'package:hifive/domain/sync/sync.dart';
import 'package:hifive/domain/vocab/vocab.dart';
import 'package:hifive/state/state.dart';

var _now = DateTime(2026, 11, 14, 20);

AppState _state(RecordStore store) =>
    createAppState(store: store, feedback: SilentFeedback(), now: () => _now);

const _source = ListeningSource(
  id: 's',
  title: 'S',
  channel: 'C',
  level: 'A1',
  description: '',
  playlistId: 'p',
  coverVideoId: 'v1',
  episodes: [
    Episode(id: 'v1', title: 'One', seconds: 600),
    Episode(id: 'v2', title: 'Two', seconds: 600),
  ],
);

void main() {
  test('listening adds up per day, survives a reload and comes next', () async {
    final store = MemoryRecordStore();
    final state = _state(store);
    await state.load();
    state.listening = [_source];
    expect(state.listenNext, isNull);

    state.listened('v1', position: 40, heard: 40);
    state.listened('v1', position: 95, heard: 50);
    expect(state.listenedToday, 90);
    expect(state.listenNext, (source: _source, index: 0, position: 95));
    expect(state.streak, 1);
    await state.flush();
    expect(store.records.keys.where((k) => k.$1 == RecordKind.listen), [
      (RecordKind.listen, 'v1@2026-11-14'),
    ]);

    final next = _state(store);
    await next.load();
    next.listening = [_source];
    expect(next.listenedToday, 90);
    next.listened('v1', position: 600, done: true);
    expect(next.listenNext, (source: _source, index: 1, position: 0));

    // A new day starts a new record and today's count again.
    _now = DateTime(2026, 11, 15, 8);
    expect(next.listenedToday, 0);
    next.listened('v2', position: 600, heard: 600, done: true);
    expect(next.listenNext, isNull);
    expect(next.streak, 2);
  });

  test(
    'of two episodes played at the same moment, the later comes next',
    () async {
      final state = _state(MemoryRecordStore());
      await state.load();
      state
        ..listening = [_source]
        ..listened('v1', position: 600, heard: 600, done: true)
        ..listened('v2', position: 95, heard: 95);
      expect(state.listenNext, (source: _source, index: 1, position: 95));
    },
  );
}
