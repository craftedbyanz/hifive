import '../domain/models/models.dart';
import 'grading_repository.dart';

/// Settings from the conversation topic screen's popover.
class ChatSettings {
  final bool freeChat;
  final String tone;
  const ChatSettings({this.freeChat = true, this.tone = 'Thoải mái'});
}

/// The result of one learner turn.
class ChatTurn {
  final Grade grade;

  /// The partner's next line, or null when the conversation has ended.
  final Question? reply;
  const ChatTurn(this.grade, this.reply);
}

/// Live conversation. The reference only showed this behind its Plus gate, so
/// the chat screen and this contract are the clone's own design, to be backed
/// by an AI service later.
abstract interface class ConversationRepository {
  /// Grades the learner's [answer] to line [index] of [lesson] and returns the
  /// partner's reply.
  Future<ChatTurn> respond({
    required Lesson lesson,
    required int index,
    required String answer,
    required ChatSettings settings,
  });
}

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
