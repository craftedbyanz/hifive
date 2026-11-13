import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hifive/domain/vocab/vocab.dart';
import 'package:hifive/features/listening/listening.dart';

import '../../helpers.dart';

final _pack = File('worker/catalog/en/2.json').readAsStringSync();

void main() {
  setUpAll(loadAppFonts);

  test('the catalog pack lists the REACH A1 playlist', () {
    final sources = parseListening(_pack);
    expect(sources.single.playlistId, 'PLqYGyORvIQiz2lBQGAGxKcNoW6UAmmD7S');
    expect(sources.single.cover, contains('F5QyH36MnVo'));
    expect(parseCatalog(_pack), hasLength(3));
    expect(
      parseListening(File('worker/catalog/en/1.json').readAsStringSync()),
      isEmpty,
    );
  });

  testWidgets('without a catalog the screen says sources are loading', (
    tester,
  ) async {
    await mount(tester, fresh(), const ListeningScreen());
    expect(find.byKey(const ValueKey('listen-empty')), findsOneWidget);
  });

  testWidgets('sources show as cards', (tester) async {
    final state = fresh()..listening = parseListening(_pack);
    await mount(tester, state, const ListeningScreen());
    expect(find.text('A1 luyện nghe tiếng Anh cơ bản'), findsOneWidget);
    expect(find.text('Playlist YouTube · REACH'), findsOneWidget);
  });

  testWidgets('a word heard is saved for review', (tester) async {
    final state = fresh();
    final source = parseListening(_pack).single;
    await mount(
      tester,
      state,
      ListenScreen(
        source: source,
        player: (_) => const SizedBox(key: ValueKey('player'), height: 200),
      ),
    );
    expect(find.byKey(const ValueKey('player')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('listen-save-word')));
    await tester.pumpAndSettle();
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
