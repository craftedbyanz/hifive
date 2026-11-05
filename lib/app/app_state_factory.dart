import '../data/data.dart';
import '../domain/repositories/repositories.dart';
import '../state/state.dart';

/// The composition root: builds an [AppState] with the local mock catalog
/// and English content, unless a caller passes its own implementation.
/// [store] is the device database; [legacy] is the old JSON blob, imported
/// on first launch. [includeExamples] shows three sample results.
AppState createAppState({
  required RecordStore store,
  AppRepository? legacy,
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
  store: store,
  legacy: legacy,
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
