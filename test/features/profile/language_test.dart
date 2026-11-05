import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hifive/data/data.dart';
import 'package:hifive/domain/models/models.dart';
import 'package:hifive/features/profile/profile.dart';

import '../../helpers.dart';

const _tall = Size(393, 2100);

void main() {
  setUpAll(loadAppFonts);

  testWidgets('confirming English saves it as the study language', (
    tester,
  ) async {
    final state = fresh()..language = Language.korean;
    await mount(tester, state, const LanguageScreen(), size: _tall);
    // The saved language has no course, so the footer can't confirm it.
    expect(find.text('Sắp ra mắt'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('language-English')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Xác nhận'));
    await tester.pumpAndSettle();
    expect(state.language, Language.english);
    expect(find.byType(LanguageScreen), findsNothing);
  });

  testWidgets('a coming-soon language is never saved', (tester) async {
    final state = fresh();
    await mount(tester, state, const LanguageScreen(), size: _tall);
    await tester.tap(find.byKey(const ValueKey('language-Japanese')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sắp ra mắt'));
    await tester.pumpAndSettle();
    expect(state.language, Language.english);
    expect(find.byType(LanguageScreen), findsOneWidget);
  });

  testWidgets('the course list comes from the repository and can retry', (
    tester,
  ) async {
    final lessons = FailingLessonRepository();
    final state = fresh(lessons: lessons);
    await mount(tester, state, const LanguageScreen(), size: _tall);
    expect(find.text('Thử lại'), findsOneWidget);
    expect(find.text('Xác nhận'), findsNothing);
    expect(find.byKey(const ValueKey('language-English')), findsNothing);
    lessons.fail = false;
    await tester.tap(find.byKey(const ValueKey('async-retry')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('language-English')), findsOneWidget);
    expect(find.text('Xác nhận'), findsOneWidget);
  });

  testWidgets('the profile row shows the study language', (tester) async {
    final state = fresh()..language = Language.japanese;
    await mount(tester, state, const ProfileScreen(), size: _tall);
    expect(find.text('Japanese'), findsOneWidget);
    expect(find.text('日本語'), findsOneWidget);
  });

  test('words are spoken in the study language', () async {
    final feedback = RecordingFeedback();
    final state = fresh(feedback: feedback);
    await state.speak('hello');
    state.language = Language.korean;
    await state.speak('annyeong');
    expect(feedback.spoken, [('hello', 'en-US'), ('annyeong', 'ko-KR')]);
  });

  test('only English has a course; other catalogs are empty', () async {
    final repo = MockLessonRepository(latency: Duration.zero);
    final courses = await repo.courses();
    expect(courses.map((c) => c.language), Language.values);
    expect(
      [
        for (final c in courses)
          if (c.available) c.language,
      ],
      [Language.english],
    );
    expect(await repo.categories(Language.korean, StudyMode.grammar), isEmpty);
    expect(
      (await repo.generator(Language.korean, StudyMode.grammar)).presets,
      isEmpty,
    );
    await expectLater(
      repo.createPractice(Language.korean, 'x', StudyMode.grammar),
      throwsStateError,
    );
    final english = await repo.generator(Language.english, StudyMode.grammar);
    expect(english.presets.first.title, generatorPresets.first.$1);
    expect(english.examples, generatorExamples);
  });

  test('saved language codes are unique', () {
    final codes = Language.values.map((l) => l.code).toSet();
    expect(codes, hasLength(Language.values.length));
    expect(Language.fromCode('en'), Language.english);
    expect(Language.fromCode(null), isNull);
  });
}
