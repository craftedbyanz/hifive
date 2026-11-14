import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hifive/domain/vocab/vocab.dart';
import 'package:hifive/features/listening/listening.dart';
import 'package:hifive/state/state.dart';

import '../../helpers.dart';

final _pack = File('worker/catalog/en/3.json').readAsStringSync();

/// Plays nothing; tests move it by hand.
class FakePlayer extends ListenPlayer {
  final loads = <(String, int, bool)>[];
  String? playlist;

  @override
  Widget view() => const SizedBox(key: ValueKey('player'), height: 200);

  @override
  void load(String video, {int start = 0, bool autoplay = false}) {
    loads.add((video, start, autoplay));
    position = start.toDouble();
    playing = autoplay;
    notifyListeners();
  }

  @override
  void loadPlaylist(String playlist) => this.playlist = playlist;

  @override
  void play() => _set(playing: true);

  @override
  void pause() => _set(playing: false);

  @override
  void seekTo(double seconds) => _set(position: seconds);

  @override
  void setRate(double rate) {
    this.rate = rate;
    notifyListeners();
  }

  /// Plays on for [seconds], reporting each second like the web view.
  void run(int seconds) {
    for (var i = 0; i < seconds; i++) {
      _set(position: position + 1);
    }
  }

  void _set({double? position, bool? playing}) {
    this.position = position ?? this.position;
    this.playing = playing ?? this.playing;
    notifyListeners();
  }
}

void main() {
  setUpAll(loadAppFonts);
  final source = parseListening(_pack).single;

  test('pack 3 lists the REACH playlist with its episodes', () {
    expect(source.playlistId, 'PLqYGyORvIQiz2lBQGAGxKcNoW6UAmmD7S');
    expect(source.episodes, hasLength(100));
    expect(source.episodes.first.title, 'Bạn trai bị bệnh');
    expect(source.episodes.first.seconds, 1216);
    expect(source.episodes.first.thumbnail, contains('F5QyH36MnVo'));
    expect(parseCatalog(_pack), hasLength(3));
    final older = File('worker/catalog/en/2.json').readAsStringSync();
    expect(parseListening(older).single.episodes, isEmpty);
  });

  testWidgets('without a catalog the screen says sources are loading', (
    tester,
  ) async {
    await mount(tester, fresh(), const ListeningScreen());
    expect(find.byKey(const ValueKey('listen-empty')), findsOneWidget);
    expect(find.byKey(const ValueKey('listen-resume')), findsNothing);
  });

  testWidgets('a source shows its episodes and how many were heard', (
    tester,
  ) async {
    final state = fresh()..listening = [source];
    state.listened(source.episodes[0].id, position: 1216, heard: 600);
    state.listened(source.episodes[0].id, position: 1216, done: true);
    await mount(tester, state, const ListeningScreen());
    expect(find.text('A1 luyện nghe tiếng Anh cơ bản'), findsOneWidget);
    expect(find.text('100 tập'), findsOneWidget);
    expect(find.text('Đã nghe 1/100'), findsOneWidget);
    expect(find.byKey(const ValueKey('listen-today-minutes')), findsOneWidget);
    expect(find.text('10'), findsOneWidget);
    // The first episode was heard to the end, so the second comes next.
    expect(find.text('Ăn chay'), findsOneWidget);
  });

  testWidgets('listening is counted, saved and resumed where it stopped', (
    tester,
  ) async {
    final state = fresh()..listening = [source];
    final player = FakePlayer();
    await mount(
      tester,
      state,
      ListenScreen(source: source, player: () => player),
    );
    expect(player.loads.single, ('F5QyH36MnVo', 0, false));
    expect(find.byKey(const ValueKey('listen-now-title')), findsOneWidget);
    expect(find.text('Bạn trai bị bệnh'), findsWidgets);

    await tester.tap(find.byKey(const ValueKey('listen-toggle')));
    player.run(40);
    // A seek is not listening.
    await tester.tap(find.byKey(const ValueKey('listen-forward')));
    await tester.tap(find.byKey(const ValueKey('listen-toggle')));
    await tester.pump();

    final day = state.listenLog.day(
      'F5QyH36MnVo',
      AppState.dayKey(state.now()),
    )!;
    expect(day.heard, 40);
    expect(day.position, 45);
    expect(state.listenNext?.position, 45);

    // Closing the screen while it plays saves what was heard since.
    player
      ..play()
      ..run(10);
    await mount(tester, state, const SizedBox());
    expect(state.listenLog.progress['F5QyH36MnVo']?.position, 55);
    final again = FakePlayer();
    await mount(
      tester,
      state,
      ListenScreen(source: source, player: () => again),
    );
    expect(again.loads.single, ('F5QyH36MnVo', 55, false));
  });

  testWidgets('an episode played to the end is ticked and the next plays', (
    tester,
  ) async {
    final state = fresh()..listening = [source];
    final player = FakePlayer();
    await mount(
      tester,
      state,
      ListenScreen(source: source, player: () => player),
    );
    player
      ..play()
      ..run(70)
      ..onEnded!();
    await tester.pump();

    expect(state.listenLog.progress['F5QyH36MnVo']?.done, isTrue);
    expect(player.loads.last, ('CzXqkWprDjY', 0, true));
    expect(find.text('Đã nghe 1/100'), findsOneWidget);
    // A minute heard makes today a study day.
    expect(state.studyDays, contains(AppState.dayKey(state.now())));
    await tester.pump(const Duration(seconds: 4));
  });

  testWidgets('the speed steps through slower ones and back', (tester) async {
    final player = FakePlayer();
    await mount(
      tester,
      fresh(),
      ListenScreen(source: source, player: () => player),
    );
    await tester.tap(find.byKey(const ValueKey('listen-rate')));
    await tester.pump();
    expect(player.rate, .75);
    expect(find.text('0.75×'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('listen-rate')));
    await tester.tap(find.byKey(const ValueKey('listen-rate')));
    await tester.tap(find.byKey(const ValueKey('listen-rate')));
    expect(player.rate, 1);
    await tester.tap(find.byKey(const ValueKey('listen-back')));
    expect(player.position, 0);
  });

  testWidgets('tapping an episode plays it', (tester) async {
    final player = FakePlayer();
    await mount(
      tester,
      fresh(),
      ListenScreen(source: source, player: () => player),
    );
    await tester.tap(find.byKey(const ValueKey('listen-episode-3')));
    await tester.pump();
    expect(player.loads.last, ('WV0LNIvCfvE', 0, true));
    expect(find.text('ĐANG PHÁT'), findsOneWidget);
  });

  testWidgets('a source without episodes plays its whole playlist', (
    tester,
  ) async {
    final older = parseListening(
      File('worker/catalog/en/2.json').readAsStringSync(),
    ).single;
    final player = FakePlayer();
    await mount(
      tester,
      fresh(),
      ListenScreen(source: older, player: () => player),
    );
    expect(player.playlist, 'PLqYGyORvIQiz2lBQGAGxKcNoW6UAmmD7S');
    expect(find.byKey(const ValueKey('listen-episodes')), findsNothing);
  });

  testWidgets('a word heard is saved for review', (tester) async {
    final state = fresh();
    final player = FakePlayer();
    await mount(
      tester,
      state,
      ListenScreen(source: source, player: () => player),
    );
    player.play();
    await tester.tap(find.byKey(const ValueKey('listen-save-word')));
    await tester.pumpAndSettle();
    expect(player.playing, isFalse);
    await tester.enterText(
      find.byKey(const ValueKey('listen-word')),
      'boyfriend',
    );
    await tester.enterText(
      find.byKey(const ValueKey('listen-meaning')),
      'bạn trai',
    );
    await tester.tap(find.byKey(const ValueKey('listen-save')));
    await tester.pumpAndSettle();

    final saved = state.decks.singleWhere((d) => d.id == 'saved');
    expect(saved.words.map((w) => w.word), contains('boyfriend'));
    expect(state.today.fresh.first.word, 'boyfriend');
  });
}
