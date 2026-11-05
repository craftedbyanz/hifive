import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hifive/data/data.dart';
import 'package:hifive/domain/models/models.dart';
import 'package:hifive/features/flashcards/flashcards.dart';
import 'package:hifive/features/game/game.dart';
import 'package:hifive/features/history/history.dart';
import 'package:hifive/features/home/home.dart';
import 'package:hifive/features/insights/insights.dart';
import 'package:hifive/features/learning/learning.dart';
import 'package:hifive/features/profile/profile.dart';

import '../helpers.dart';

/// The reference grows its text with a larger system size; every screen must
/// still lay out at the largest standard size on a 393 × 852 iPhone.
void main() {
  setUpAll(loadAppFonts);

  testWidgets('text follows a larger system size but not a smaller one', (
    tester,
  ) async {
    late double scale;
    Future<void> measure(double system) async {
      tester.platformDispatcher.textScaleFactorTestValue = system;
      await mount(
        tester,
        fresh(),
        Builder(
          builder: (context) {
            scale = MediaQuery.textScalerOf(context).scale(17) / 17;
            return const SizedBox();
          },
        ),
      );
    }

    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await measure(16 / 17);
    expect(scale, 1);
    await measure(23 / 17);
    expect(scale, closeTo(23 / 17, .001));
    await measure(3);
    expect(scale, closeTo(23 / 17, .001));
  });

  testWidgets('screens lay out at the largest standard text size', (
    tester,
  ) async {
    await layOut(tester, scale: 23 / 17, size: const Size(393, 852));
  });

  testWidgets('screens lay out on the 411 × 914 Android emulator', (
    tester,
  ) async {
    await layOut(tester, scale: 1, size: const Size(411, 914));
  });
}

Future<void> layOut(
  WidgetTester tester, {
  required double scale,
  required Size size,
}) async {
  tester.platformDispatcher.textScaleFactorTestValue = scale;
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  final s = fresh(includeExamples: true);
  final grammar = MockLessonRepository.topicsNow(
    StudyMode.grammar,
    'Dành cho bạn',
  ).first;
  final pages = <String, Widget>{
    'home': const HomeScreen(animateAmbient: false),
    'topics': const TopicScreen(mode: StudyMode.grammar),
    'collection': CollectionScreen(topic: grammar),
    'lesson': PracticeScreen(lesson: sampleLesson(StudyMode.grammar)),
    'paragraph': PracticeScreen(lesson: sampleLesson(StudyMode.writing)),
    'generator': const GeneratorScreen(),
    'history': const HistoryScreen(),
    'streak': const StreakScreen(),
    'insight': const InsightScreen(),
    'profile': const ProfileScreen(),
    'decks': const DeckListScreen(),
    'deck': DeckScreen(deck: s.decks.first),
    'game home': const GameHomeScreen(),
    'game': GameScreen(words: s.decks.first.words, title: 'T'),
  };
  final failures = <String>{};
  var current = '';
  final previous = FlutterError.onError;
  FlutterError.onError = (details) {
    final text = details.toString();
    final where = RegExp(r'lib/[a-z_/]+\.dart:\d+').firstMatch(text)?[0];
    failures.add(
      '$current: ${details.exceptionAsString().split('\n').first}'
              ' ${where ?? ''}'
          .replaceAll(RegExp(r'\s+'), ' '),
    );
  };
  for (final entry in pages.entries) {
    current = entry.key;
    await mount(tester, s, entry.value, size: size);
    await tester.pump(const Duration(seconds: 1));
  }
  FlutterError.onError = previous;
  expect(failures.toList(), isEmpty);
}
