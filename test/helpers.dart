import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hifive/app/app.dart';
import 'package:hifive/core/design/design.dart';
import 'package:hifive/data/data.dart';
import 'package:hifive/domain/models/models.dart';
import 'package:hifive/domain/repositories/repositories.dart';
import 'package:hifive/state/state.dart';

/// Loads the bundled font, so layout in tests matches the app.
Future<void> loadAppFonts() async {
  final loader = FontLoader('PlusJakartaSans');
  for (final weight in ['Regular', 'Medium', 'SemiBold', 'Bold', 'ExtraBold']) {
    loader.addFont(rootBundle.load('assets/fonts/PlusJakartaSans-$weight.ttf'));
  }
  await loader.load();
}

/// The catalog answers at once in tests unless a test passes its own.
AppState fresh({
  bool includeExamples = false,
  AppRepository? repository,
  SystemActions? system,
  LessonRepository? lessons,
  GradingRepository? grading,
  ConversationRepository? conversation,
  DeckGenerator? deckGenerator,
  InsightRepository? insights,
}) => createAppState(
  repository: repository ?? MemoryAppRepository(),
  feedback: SilentFeedback(),
  system: system ?? RecordingSystemActions(),
  includeExamples: includeExamples,
  lessons: lessons ?? MockLessonRepository(latency: Duration.zero),
  grading: grading,
  conversation:
      conversation ?? const MockConversationRepository(latency: Duration.zero),
  deckGenerator: deckGenerator,
  insights: insights,
  now: () => DateTime(2026, 11, 1, 1, 43),
);

/// A grammar, writing or conversation lesson built from the bundled banks.
Lesson sampleLesson(StudyMode mode, {String title = 'Test'}) => Lesson(
  id: 'test-${mode.name}',
  title: title,
  description: 'Bài kiểm thử.',
  mode: mode,
  questions: switch (mode) {
    StudyMode.grammar => apologyQuestions.take(5).toList(),
    StudyMode.writing => paragraphQuestions,
    StudyMode.conversation => conversationQuestions,
  },
);

/// A repository call that always fails, for error states.
Future<T> failing<T>() async => throw StateError('offline');

class FailingLessonRepository implements LessonRepository {
  int calls = 0;
  final LessonRepository inner = MockLessonRepository(latency: Duration.zero);
  bool fail = true;
  Future<T> _maybe<T>(Future<T> Function() ok) {
    calls++;
    return fail ? failing<T>() : ok();
  }

  @override
  Future<List<String>> categories(StudyMode mode) => inner.categories(mode);
  @override
  Future<List<Topic>> topics(
    StudyMode mode,
    String category, {
    int refresh = 0,
  }) => _maybe(() => inner.topics(mode, category, refresh: refresh));
  @override
  Future<List<Lesson>> lessons(Topic topic) =>
      _maybe(() => inner.lessons(topic));
  @override
  Future<List<String>> suggestions(StudyMode mode) =>
      _maybe(() => inner.suggestions(mode));
  @override
  Future<Lesson> createPractice(String title, StudyMode mode) =>
      _maybe(() => inner.createPractice(title, mode));
}

class FailingGradingRepository implements GradingRepository {
  bool fail = true;
  final GradingRepository inner = const MockGradingRepository(
    latency: Duration.zero,
  );
  @override
  Future<Grade> grade(Question question, String submitted) =>
      fail ? failing<Grade>() : inner.grade(question, submitted);
  @override
  Future<List<String>> assist(Question question, String draft) =>
      inner.assist(question, draft);
}

/// Mounts [page] at the 393 × 852 reference viewport.
Future<void> mount(
  WidgetTester tester,
  AppState state,
  Widget page, {
  Size size = const Size(393, 852),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    AppScope(
      state: state,
      child: MaterialApp(
        key: UniqueKey(),
        theme: D.theme,
        builder: (context, child) => textScaling(child!),
        home: page,
      ),
    ),
  );
  await tester.pumpAndSettle();
}
