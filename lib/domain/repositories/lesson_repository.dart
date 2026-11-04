import '../models/models.dart';

/// Lesson catalog: categories, topics, collections and AI-generated practice.
/// Every call is asynchronous because a backend will serve it; callers must
/// handle loading, failure and empty results.
abstract interface class LessonRepository {
  Future<List<String>> categories(StudyMode mode);

  /// Topics in [category]. [refresh] counts presses of "Làm mới", which asks
  /// for a different selection of suggested topics.
  Future<List<Topic>> topics(StudyMode mode, String category, {int refresh});

  Future<List<Lesson>> lessons(Topic topic);

  /// Preset topics on the AI chooser.
  Future<List<String>> suggestions(StudyMode mode);

  /// Builds a practice lesson from a free-text topic (the AI generator).
  Future<Lesson> createPractice(String title, StudyMode mode);
}
