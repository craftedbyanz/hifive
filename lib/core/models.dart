import 'dart:math';

enum StudyMode { writing, grammar, conversation }

extension ModeLabels on StudyMode {
  String get title => ['Đoạn văn', 'Sửa câu', 'Hội thoại'][index];
  String get category => ['LUYỆN VIẾT', 'NGỮ PHÁP', 'GIAO TIẾP'][index];
  String get headline => ['Viết nên', 'Hoàn thiện', 'Thực hành'][index];
  String get accentTitle => ['câu chuyện', 'ngữ pháp', 'giao tiếp'][index];
  String get action => ['Bắt đầu', 'Sửa nhanh', 'Bắt đầu chat'][index];
}

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

enum GradeKind { correct, near, incorrect }

class Grade {
  final GradeKind kind;
  final double score;
  final String explanation;
  const Grade(this.kind, this.score, this.explanation);
  String get title => switch (kind) {
    GradeKind.correct => 'Chính xác',
    GradeKind.near => 'Gần đúng',
    GradeKind.incorrect => 'Chưa đúng',
  };
}

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

class FlashWord {
  final String id, word, meaning, phonetic, example, partOfSpeech, definition;
  String status;
  DateTime? due;

  /// Days until the next review once the card is known. Zero while learning.
  int intervalDays;
  FlashWord({
    required this.id,
    required this.word,
    required this.meaning,
    this.phonetic = '',
    this.example = '',
    this.partOfSpeech = 'NOUN',
    this.definition = '',
    this.status = 'new',
    this.due,
    this.intervalDays = 0,
  });

  bool isDue(DateTime now) =>
      status == 'new' || due == null || !due!.isAfter(now);

  /// Mock scheduling fitted to the labels seen on the reference, which showed
  /// 1m/6m/1d/4d, 1m/1d/3d/4d and 1m/5d/10d/12d. Its real algorithm is unknown.
  List<Duration> get nextIntervals {
    if (status != 'review') {
      return const [
        Duration(minutes: 1),
        Duration(minutes: 6),
        Duration(days: 1),
        Duration(days: 4),
      ];
    }
    int grow(double factor, int least) =>
        (intervalDays * factor).ceil().clamp(least, 36500);
    return [
      const Duration(minutes: 1),
      Duration(days: grow(1.2, 1)),
      Duration(days: grow(2.5, 3)),
      Duration(days: grow(3, 4)),
    ];
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'word': word,
    'meaning': meaning,
    'phonetic': phonetic,
    'example': example,
    'partOfSpeech': partOfSpeech,
    'definition': definition,
    'status': status,
    'due': due?.toIso8601String(),
    'intervalDays': intervalDays,
  };
  factory FlashWord.fromJson(Map<String, dynamic> j) => FlashWord(
    id: j['id'] as String,
    word: j['word'] as String,
    meaning: j['meaning'] as String,
    phonetic: j['phonetic'] as String? ?? '',
    example: j['example'] as String? ?? '',
    partOfSpeech: j['partOfSpeech'] as String? ?? 'NOUN',
    definition: j['definition'] as String? ?? '',
    status: j['status'] as String? ?? 'new',
    due: j['due'] == null ? null : DateTime.parse(j['due'] as String),
    intervalDays: j['intervalDays'] as int? ?? 0,
  );
}

class Deck {
  final String id, title, description;
  final int icon;
  final List<FlashWord> words;
  Deck({
    required this.id,
    required this.title,
    required this.description,
    required this.words,
    this.icon = 0,
  });
  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'icon': icon,
    'words': words.map((w) => w.toJson()).toList(),
  };
  factory Deck.fromJson(Map<String, dynamic> j) => Deck(
    id: j['id'] as String,
    title: j['title'] as String,
    description: j['description'] as String,
    icon: j['icon'] as int? ?? 0,
    words: (j['words'] as List)
        .map((w) => FlashWord.fromJson(Map<String, dynamic>.from(w as Map)))
        .toList(),
  );
}

String normalizeAnswer(String value) => value
    .toLowerCase()
    .replaceAll('’', "'")
    .replaceAll("i'm", 'i am')
    .replaceAll("don't", 'do not')
    .replaceAll("didn't", 'did not')
    .replaceAll("it's", 'it is')
    .replaceAll(RegExp(r"[^a-z0-9à-ỹ ]"), '')
    .replaceAll(RegExp(r'\s+'), ' ')
    .trim();

/// A deterministic, replaceable local grader. It does not impersonate remote AI.
Grade gradeLocally(Question question, String input) {
  final a = normalizeAnswer(input);
  if ([
    question.answer,
    ...question.alternatives,
  ].any((v) => normalizeAnswer(v) == a)) {
    return Grade(
      GradeKind.correct,
      1,
      question.explanation.isNotEmpty ? question.explanation : 'Bạn đã diễn đạt đúng câu trả lời tham khảo. Hãy chú ý cách dùng từ và cấu trúc câu này.',
    );
  }
  final expected = normalizeAnswer(question.answer).split(' '),
      actual = a.split(' ');
  final intersection = actual.toSet().intersection(expected.toSet()).length;
  final similarity =
      intersection / max(expected.toSet().length, actual.toSet().length);
  if (similarity >= .65) {
    return const Grade(
      GradeKind.near,
      .7,
      'Bạn đã diễn đạt được ý chính. Hãy đối chiếu các từ được đánh dấu với câu tham khảo để hoàn thiện cấu trúc và cách dùng từ.',
    );
  }
  return Grade(
    GradeKind.incorrect,
    .2 * similarity,
    'Câu trả lời còn khác với nội dung tham khảo. ${question.explanation.isEmpty ? 'Kiểm tra chủ ngữ, động từ, thời gian và những ý còn thiếu.' : question.explanation}',
  );
}

enum TokenChange { unchanged, removed, added }

class DiffToken {
  final String text;
  final TokenChange change;
  const DiffToken(this.text, this.change);
}

/// Longest common subsequence preserves unchanged words in correction feedback.
List<DiffToken> diffWords(String submitted, String expected) {
  final pattern = RegExp(
    r"[A-Za-z0-9À-ỹ]+(?:['’][A-Za-z]+)?|[^\sA-Za-z0-9À-ỹ]",
  );
  List<String> tokens(String s) =>
      pattern.allMatches(s).map((m) => m.group(0)!).toList();
  final a = tokens(submitted), b = tokens(expected);
  final lcs = List.generate(a.length + 1, (_) => List.filled(b.length + 1, 0));
  for (var i = a.length - 1; i >= 0; i--) {
    for (var j = b.length - 1; j >= 0; j--) {
      lcs[i][j] = a[i] == b[j]
          ? 1 + lcs[i + 1][j + 1]
          : max(lcs[i + 1][j], lcs[i][j + 1]);
    }
  }
  final result = <DiffToken>[];
  var i = 0, j = 0;
  while (i < a.length || j < b.length) {
    if (i < a.length && j < b.length && a[i] == b[j]) {
      result.add(DiffToken(b[j++], TokenChange.unchanged));
      i++;
    } else if (i < a.length &&
        (j == b.length || lcs[i + 1][j] >= lcs[i][j + 1])) {
      result.add(DiffToken(a[i++], TokenChange.removed));
    } else {
      result.add(DiffToken(b[j++], TokenChange.added));
    }
  }
  return result;
}
