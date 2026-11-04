import 'study_mode.dart';

class Question {
  final String prompt, answer, explanation;
  final List<String> alternatives;

  /// A conversation line spoken by the partner rather than the learner. It is
  /// shown, not answered, and does not count towards the score.
  final bool partner;
  const Question(
    this.prompt,
    this.answer, {
    this.explanation = '',
    this.alternatives = const [],
    this.partner = false,
  });
  List<String> get hints => answer
      .replaceAll(RegExp(r'[^a-zA-Z ]'), '')
      .split(' ')
      .where((w) => w.length > 3)
      .take(5)
      .toList();
  Map<String, dynamic> toJson() => {
    'prompt': prompt,
    'answer': answer,
    'explanation': explanation,
    'alternatives': alternatives,
    if (partner) 'partner': true,
  };
  factory Question.fromJson(Map<String, dynamic> j) => Question(
    j['prompt'] as String,
    j['answer'] as String,
    explanation: j['explanation'] as String? ?? '',
    alternatives: List<String>.from(j['alternatives'] as List? ?? const []),
    partner: j['partner'] as bool? ?? false,
  );
}

class Topic {
  final String id, title, description, category;
  final StudyMode mode;
  final List<Question> questions;
  final int sets, icon;
  const Topic({
    required this.id,
    required this.title,
    required this.description,
    required this.mode,
    required this.questions,
    this.category = 'Dành cho bạn',
    this.sets = 5,
    this.icon = 0,
  });
}

class Lesson {
  final String id, title, description;
  final StudyMode mode;
  final List<Question> questions;
  const Lesson({
    required this.id,
    required this.title,
    required this.description,
    required this.mode,
    required this.questions,
  });
  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'mode': mode.index,
    'questions': questions.map((q) => q.toJson()).toList(),
  };
  factory Lesson.fromJson(Map<String, dynamic> j) => Lesson(
    id: j['id'] as String,
    title: j['title'] as String,
    description: j['description'] as String,
    mode: StudyMode.values[j['mode'] as int],
    questions: (j['questions'] as List)
        .map((q) => Question.fromJson(Map<String, dynamic>.from(q as Map)))
        .toList(),
  );
}
