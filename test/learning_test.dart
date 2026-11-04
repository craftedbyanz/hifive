import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hifive/core/catalog.dart';
import 'package:hifive/core/models.dart';
import 'package:hifive/features/learning/learning.dart';

import 'helpers.dart';

const tall = Size(393, 2400);

void main() {
  setUpAll(loadAppFonts);

  group('topic browser', () {
    for (final mode in StudyMode.values) {
      testWidgets('${mode.name} lists topics and opens a collection', (
        tester,
      ) async {
        final state = fresh();
        await mount(tester, state, TopicScreen(mode: mode), size: tall);
        final topics = MockLessonRepository.topicsNow(
          mode,
          lessonCategories.first,
        );
        expect(topics, isNotEmpty);
        await tester.tap(find.byType(TopicTile).first);
        await tester.pumpAndSettle();
        expect(find.byType(CollectionScreen), findsOneWidget);
      });
    }

    testWidgets('changing category changes the section label', (tester) async {
      await mount(
        tester,
        fresh(),
        const TopicScreen(mode: StudyMode.grammar),
        size: tall,
      );
      expect(find.text('CHỦ ĐỀ CỦA BẠN'), findsOneWidget);
      await tester.tap(find.text(lessonCategories[1]));
      await tester.pump();
      expect(find.text('CHỦ ĐỀ LIÊN QUAN'), findsOneWidget);
    });

    testWidgets('the AI button opens the local generator', (tester) async {
      await mount(
        tester,
        fresh(),
        const TopicScreen(mode: StudyMode.grammar),
        size: tall,
      );
      await tester.tap(find.text('AI'));
      await tester.pumpAndSettle();
      expect(find.byType(GeneratorScreen), findsOneWidget);
    });
  });

  testWidgets('collection level badge explains CEFR levels', (tester) async {
    final state = fresh();
    final topic = MockLessonRepository.topicsNow(
      StudyMode.grammar,
      lessonCategories.first,
    ).first;
    await mount(tester, state, CollectionScreen(topic: topic), size: tall);
    await tester.tap(find.textContaining('CẤP ĐỘ'));
    await tester.pumpAndSettle();
    expect(find.byType(LevelInformation), findsOneWidget);
    // The learner's own level is marked.
    expect(find.text('Hiện tại'), findsOneWidget);
    final current = tester.getTopLeft(find.text('Hiện tại')).dy;
    final a1 = tester.getTopLeft(find.text(levels.first)).dy;
    expect((current - a1).abs(), lessThan(10));
  });

  group('dictionary', () {
    test('lesson words list the most used first with their sentences', () {
      final words = lessonWords([
        'I am late today.',
        'Sorry, I am late.',
        'The alarm failed.',
      ]);
      expect(words.first.word, 'late');
      expect(words.first.sentences, [1, 2]);
      expect(words.first.meaning, 'muộn');
      expect(words.first.ipa, '/leɪt/');
      expect(words.map((w) => w.word), contains('alarm'));
    });

    test('known words have a meaning and others a fallback', () {
      expect(dictionaryMeaning('today'), 'Hôm nay.');
      expect(dictionaryMeaning('TODAY'), 'Hôm nay.');
      expect(dictionaryMeaning('zzz'), contains('Từ vựng trong bài học'));
    });

    testWidgets('saving a word adds it to the saved deck', (tester) async {
      final state = fresh();
      await mount(
        tester,
        state,
        Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => showWord(context, 'today'),
              child: const Text('open'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Lưu từ'));
      await tester.pumpAndSettle();
      final saved = state.decks.firstWhere((d) => d.id == 'saved');
      expect(saved.words.single.word, 'today');
      expect(find.text('Đã lưu today'), findsOneWidget);
    });
  });
}
