import '../models/models.dart';

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
  /// Grades the learner's [answer] to line [index] of [lesson], written in
  /// [language], and returns the partner's reply.
  Future<ChatTurn> respond({
    required Language language,
    required Lesson lesson,
    required int index,
    required String answer,
    required ChatSettings settings,
  });
}
