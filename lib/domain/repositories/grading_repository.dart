import '../models/models.dart';

/// Grades answers and gives in-lesson help. A backend AI will replace the
/// local comparison; callers must handle slow responses and failures. Each
/// call names the study [Language] the answer is written in.
abstract interface class GradingRepository {
  Future<Grade> grade(Language language, Question question, String submitted);

  /// Help for the learner's current draft, behind the ✨ button in the hint
  /// row. The reference showed the button but was never seen pressing it.
  Future<List<String>> assist(
    Language language,
    Question question,
    String draft,
  );
}
