import '../data/data.dart';
import '../domain/models/models.dart';
import '../domain/repositories/repositories.dart';
import '../state/state.dart';

/// The composition root: builds an [AppState] with the local mock catalog
/// and English content, unless a caller passes its own implementation.
/// [store] is the device database; [legacy] is the old JSON blob, imported
/// on first launch. [includeExamples] shows three sample results, and
/// [sampleDecks] the bundled practice decks; both are test fixtures, so the
/// app (`main.dart`) turns them off and starts with hifive's catalog only.
AppState createAppState({
  required RecordStore store,
  AppRepository? legacy,
  AuthService? auth,
  SyncService? sync,
  CatalogRepository? catalog,
  DictionaryStore? dictionaryStore,
  DictionaryPacks? dictionaryPacks,
  ShareRepository? shares,
  CircleRepository? circles,
  bool includeExamples = false,
  bool sampleDecks = true,
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
  auth: auth ?? MemoryAuthService(),
  syncService: sync,
  catalog: catalog,
  dictionaryStore: dictionaryStore,
  dictionaryPacks: dictionaryPacks,
  shares: shares,
  circles: circles,
  lessons: lessons ?? MockLessonRepository(),
  grading: grading ?? const MockGradingRepository(),
  conversation: conversation ?? const MockConversationRepository(),
  deckGenerator: deckGenerator ?? MockDeckGenerator(now: now ?? DateTime.now),
  insights: insights ?? const MockInsightRepository(),
  decks: sampleDecks ? seedDecks() : <Deck>[],
  examples: includeExamples ? sampleHistory() : const [],
  feedback: feedback,
  system: system,
  now: now,
);
