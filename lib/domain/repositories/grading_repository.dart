import '../models/models.dart';

/// Grades answers and gives in-lesson help. A backend AI will replace the
/// local comparison; callers must handle slow responses and failures.
abstract interface class GradingRepository {
  Future<Grade> grade(Question question, String submitted);

  /// Help for the learner's current draft, behind the ✨ button in the hint
  /// row. The reference showed the button but was never seen pressing it.
  Future<List<String>> assist(Question question, String draft);
}
