import '../data/data.dart';
import '../domain/repositories/repositories.dart';
import '../state/state.dart';

/// The composition root: builds an [AppState] with the local mock catalog
/// and English content, unless a caller passes its own implementation.
/// [includeExamples] seeds three sample results.
AppState createAppState({
  required AppRepository repository,
  bool includeExamples = false,
  LessonRepository? lessons,
  GradingRepository? grading,
  ConversationRepository? conversation,
  DeckGenerator? deckGenerator,
  InsightRepository? insights,
  FeedbackService? feedback,
  SystemActions? system,
  DateTime Function()? now,
}) => AppState(
  repository: repository,
  lessons: lessons ?? MockLessonRepository(),
  grading: grading ?? const MockGradingRepository(),
  conversation: conversation ?? const MockConversationRepository(),
  deckGenerator: deckGenerator ?? MockDeckGenerator(now: now ?? DateTime.now),
  insights: insights ?? const MockInsightRepository(),
  decks: seedDecks(),
  examples: includeExamples ? sampleHistory() : const [],
  feedback: feedback,
  system: system,
  now: now,
);
