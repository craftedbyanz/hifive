import '../../domain/models/models.dart';
import '../../domain/repositories/conversation_repository.dart';
import '../../domain/repositories/grading_repository.dart';
import 'mock_grading_repository.dart';

/// Follows the lesson's script: grading is the local comparison, and the reply
/// is the next partner line.
class MockConversationRepository implements ConversationRepository {
  final Duration latency;
  final GradingRepository grading;
  const MockConversationRepository({
    this.latency = const Duration(milliseconds: 700),
    this.grading = const MockGradingRepository(latency: Duration.zero),
  });

  @override
  Future<ChatTurn> respond({
    required Lesson lesson,
    required int index,
    required String answer,
    required ChatSettings settings,
  }) async {
    if (latency > Duration.zero) await Future<void>.delayed(latency);
    final grade = await grading.grade(lesson.questions[index], answer);
    final next = index + 1;
    final reply =
        next < lesson.questions.length && lesson.questions[next].partner
        ? lesson.questions[next]
        : null;
    return ChatTurn(grade, reply);
  }
}
