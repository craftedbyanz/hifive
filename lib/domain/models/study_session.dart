import 'grade.dart';
import 'lesson.dart';

class AnswerRecord {
  final String text;
  final double firstScore;
  final GradeKind kind;
  const AnswerRecord(this.text, this.firstScore, this.kind);
  Map<String, dynamic> toJson() => {
    'text': text,
    'score': firstScore,
    'kind': kind.index,
  };
  factory AnswerRecord.fromJson(Map<String, dynamic> j) => AnswerRecord(
    j['text'] as String,
    (j['score'] as num).toDouble(),
    GradeKind.values[j['kind'] as int],
  );
}

class StudySession {
  final String id;
  final Lesson lesson;
  final DateTime date;
  final List<AnswerRecord> answers;
  final int seconds;
  const StudySession({
    required this.id,
    required this.lesson,
    required this.date,
    required this.answers,
    required this.seconds,
  });

  /// Sample results seeded on a first launch to show the screens; they are
  /// not the learner's own study (`sampleHistory`).
  bool get isExample => id.startsWith('sample-');

  /// Answers the learner gave, leaving out partner lines in a conversation.
  List<AnswerRecord> get scored => [
    for (var i = 0; i < answers.length; i++)
      if (i >= lesson.questions.length || !lesson.questions[i].partner)
        answers[i],
  ];
  int get accuracy {
    final list = scored;
    return list.isEmpty
        ? 0
        : (list.fold<double>(0, (s, a) => s + a.firstScore) / list.length * 100)
              .round();
  }

  int get correct => scored.where((a) => a.firstScore >= .65).length;
  Map<String, dynamic> toJson() => {
    'id': id,
    'lesson': lesson.toJson(),
    'date': date.toIso8601String(),
    'answers': answers.map((a) => a.toJson()).toList(),
    'seconds': seconds,
  };
  factory StudySession.fromJson(Map<String, dynamic> j) => StudySession(
    id: j['id'] as String,
    lesson: Lesson.fromJson(Map<String, dynamic>.from(j['lesson'] as Map)),
    date: DateTime.parse(j['date'] as String),
    answers: (j['answers'] as List)
        .map((a) => AnswerRecord.fromJson(Map<String, dynamic>.from(a as Map)))
        .toList(),
    seconds: j['seconds'] as int,
  );
}
