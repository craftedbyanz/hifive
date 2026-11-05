import '../models/models.dart';

/// Lesson catalog: courses, categories, topics, collections and AI-generated
/// practice. Every call is asynchronous because a backend will serve it;
/// callers must handle loading, failure and empty results. Each call names the
/// study [Language] whose course it reads.
abstract interface class LessonRepository {
  /// Every language Hifive lists, with whether its course has content.
  Future<List<Course>> courses();

  Future<List<String>> categories(Language language, StudyMode mode);

  /// Topics in [category]. [refresh] counts presses of "Làm mới", which asks
  /// for a different selection of suggested topics.
  Future<List<Topic>> topics(
    Language language,
    StudyMode mode,
    String category, {
    int refresh,
  });

  Future<List<Lesson>> lessons(Language language, Topic topic);

  /// Presets and sample prompts on the AI chooser.
  Future<GeneratorCatalog> generator(Language language, StudyMode mode);

  /// Builds a practice lesson from a free-text topic (the AI generator).
  Future<Lesson> createPractice(
    Language language,
    String title,
    StudyMode mode,
  );
}
