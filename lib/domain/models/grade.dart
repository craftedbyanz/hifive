enum GradeKind { correct, near, incorrect }

class Grade {
  final GradeKind kind;
  final double score;
  final String explanation;
  const Grade(this.kind, this.score, this.explanation);
}

enum TokenChange { unchanged, removed, added }

class DiffToken {
  final String text;
  final TokenChange change;
  const DiffToken(this.text, this.change);
}
