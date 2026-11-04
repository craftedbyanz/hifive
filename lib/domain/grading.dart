import 'dart:math';

import 'models/grade.dart';
import 'models/lesson.dart';

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
