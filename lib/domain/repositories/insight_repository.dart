import '../models/models.dart';

/// AI suggestions on the Insight screen.
abstract interface class InsightRepository {
  /// Improvement tips based on this month's sessions.
  Future<List<String>> tips(List<StudySession> month);
}
