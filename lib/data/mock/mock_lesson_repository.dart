import '../../domain/models/models.dart';
import '../../domain/repositories/lesson_repository.dart';
import '../content/en/lessons.dart';

/// Serves the English content in `data/content/en/lessons.dart` after a short wait, standing in for the network.
class MockLessonRepository implements LessonRepository {
  final Duration latency;
  MockLessonRepository({this.latency = const Duration(milliseconds: 350)});

  /// How many topics "Dành cho bạn" shows, as on the reference grammar screen.
  static const suggestedCount = {
    StudyMode.grammar: 12,
    StudyMode.writing: 12,
    StudyMode.conversation: 1,
  };

  Future<T> _serve<T>(T Function() value) async {
    if (latency > Duration.zero) await Future<void>.delayed(latency);
    return value();
  }

  @override
  Future<List<String>> categories(StudyMode mode) =>
      _serve(() => mockCategories(mode));

  @override
  Future<List<Topic>> topics(
    StudyMode mode,
    String category, {
    int refresh = 0,
  }) => _serve(() => topicsNow(mode, category, refresh: refresh));

  @override
  Future<List<Lesson>> lessons(Topic topic) => _serve(() => lessonsNow(topic));

  @override
  Future<List<String>> suggestions(StudyMode mode) =>
      _serve(() => generatorSuggestions);

  @override
  Future<Lesson> createPractice(String title, StudyMode mode) =>
      _serve(() => practiceNow(title, mode));

  /// Synchronous view of the catalog, for sample data and tests.
  static List<Topic> topicsNow(
    StudyMode mode,
    String category, {
    int refresh = 0,
  }) {
    final all = mockTopics(mode);
    final List<int> picks;
    if (category == mockCategories(mode).first) {
      final count = suggestedCount[mode]!.clamp(1, all.length);
      // Each refresh moves the window along, wrapping round the catalog.
      final start = (refresh * count) % all.length;
      picks = [for (var i = 0; i < count; i++) (start + i) % all.length];
    } else {
      picks = [
        for (var i = 0; i < all.length; i++)
          if (all[i].categories.contains(category)) i,
      ];
      if (refresh > 0 && picks.isNotEmpty) {
        final shift = refresh % picks.length;
        picks.insertAll(0, picks.sublist(shift));
        picks.removeRange(picks.length - shift, picks.length);
      }
    }
    return [for (final i in picks) _topic(mode, i, category)];
  }

  static Topic _topic(StudyMode mode, int index, String category) {
    final t = mockTopics(mode)[index];
    return Topic(
      id: '${mode.name}-$index',
      title: t.title,
      description: t.description,
      mode: mode,
      questions: t.sets.first.questions,
      sets: t.listed,
      icon: t.icon,
      category: category,
    );
  }

  static List<Lesson> lessonsNow(Topic topic) {
    final index = int.tryParse(topic.id.split('-').last);
    final all = mockTopics(topic.mode);
    if (index == null || index >= all.length) return [];
    final t = all[index];
    return [
      for (var i = 0; i < t.sets.length; i++)
        Lesson(
          id: '${topic.id}-$i',
          title: t.sets[i].title,
          description: t.sets[i].description.isEmpty
              ? t.description
              : t.sets[i].description,
          mode: topic.mode,
          questions: t.sets[i].questions,
        ),
    ];
  }

  /// Picks a catalog set for a free-text topic, so the same text always gives
  /// the same practice. Real generation would write new sentences.
  static Lesson practiceNow(String title, StudyMode mode) {
    final all = mockTopics(mode);
    final hash = title.codeUnits.fold<int>(0, (h, c) => (h * 31 + c) & 0xffff);
    final source = all[hash % all.length].sets.first;
    return Lesson(
      id: 'local-${mode.name}-$hash-${title.length}',
      title: title,
      description: 'Bài luyện tập tạo từ chủ đề của bạn.',
      mode: mode,
      questions: source.questions,
    );
  }
}
