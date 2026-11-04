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

enum TokenChange { unchanged, removed, added }

class DiffToken {
  final String text;
  final TokenChange change;
  const DiffToken(this.text, this.change);
}
