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
  RecordStore? store,
  AppRepository? legacy,
  AuthService? auth,
  FeedbackService? feedback,
  SystemActions? system,
  LessonRepository? lessons,
  GradingRepository? grading,
  ConversationRepository? conversation,
  DeckGenerator? deckGenerator,
  InsightRepository? insights,
}) => createAppState(
  store: store ?? MemoryRecordStore(),
  legacy: legacy,
  auth: auth,
  feedback: feedback ?? SilentFeedback(),
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
  Future<List<Course>> courses() => _maybe(inner.courses);
  @override
  Future<List<String>> categories(Language language, StudyMode mode) =>
      inner.categories(language, mode);
  @override
  Future<List<Topic>> topics(
    Language language,
    StudyMode mode,
    String category, {
    int refresh = 0,
  }) => _maybe(() => inner.topics(language, mode, category, refresh: refresh));
  @override
  Future<List<Lesson>> lessons(Language language, Topic topic) =>
      _maybe(() => inner.lessons(language, topic));
  @override
  Future<GeneratorCatalog> generator(Language language, StudyMode mode) =>
      _maybe(() => inner.generator(language, mode));
  @override
  Future<Lesson> createPractice(
    Language language,
    String title,
    StudyMode mode,
  ) => _maybe(() => inner.createPractice(language, title, mode));
}

class FailingGradingRepository implements GradingRepository {
  bool fail = true;

  /// The language of every grade request.
  final languages = <Language>[];
  final GradingRepository inner = const MockGradingRepository(
    latency: Duration.zero,
  );
  @override
  Future<Grade> grade(Language language, Question question, String submitted) {
    languages.add(language);
    return fail ? failing<Grade>() : inner.grade(language, question, submitted);
  }

  @override
  Future<List<String>> assist(
    Language language,
    Question question,
    String draft,
  ) => inner.assist(language, question, draft);
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

/// Records what was spoken, and in which locale.
class RecordingFeedback extends SilentFeedback {
  final spoken = <(String, String)>[];
  @override
  Future<void> speak(String text, {required String locale}) async =>
      spoken.add((text, locale));
}

/// The mock catalog with [generator] answering from [catalog], to prove a
/// screen reads its copy through [LessonRepository].
class CatalogLessonRepository extends MockLessonRepository {
  final GeneratorCatalog catalog;
  CatalogLessonRepository(this.catalog) : super(latency: Duration.zero);
  @override
  Future<GeneratorCatalog> generator(Language language, StudyMode mode) async =>
      catalog;
}
