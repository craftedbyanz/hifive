/// Study groups and classes (Community, steps 3 and 4): circles joined by
/// a six-character code. Progress comes from the learning data members
/// sync, so it is the same progress the app shows.
enum CircleKind {
  /// Friends with a goal of study days a week.
  group,

  /// A teacher (the owner) and students; the teacher sets decks to learn.
  classroom;

  /// The name the server uses.
  String get wire => this == group ? 'group' : 'class';

  static CircleKind fromWire(String s) => s == 'class' ? classroom : group;
}

class Circle {
  final String id, name, code;
  final CircleKind kind;

  /// Study days a week the group aims for.
  final int goal;

  /// Whether the learner owns it: a group's founder, a class's teacher.
  final bool owner;
  final int members;
  const Circle({
    required this.id,
    required this.kind,
    required this.name,
    required this.code,
    this.goal = 3,
    this.owner = false,
    this.members = 1,
  });

  factory Circle.fromJson(Map<String, dynamic> j) => Circle(
    id: j['id'] as String,
    kind: CircleKind.fromWire(j['kind'] as String),
    name: j['name'] as String,
    code: j['code'] as String,
    goal: j['goal'] as int? ?? 3,
    owner: j['owner'] as bool? ?? false,
    members: j['members'] as int? ?? 1,
  );
}

/// A member as the learner sees them; [id] means nothing outside its circle.
class CirclePerson {
  final String id, name;
  final bool me, owner;

  /// The days of the week shown that they studied, `yyyy-mm-dd`.
  final Set<String> days;
  const CirclePerson({
    required this.id,
    required this.name,
    this.me = false,
    this.owner = false,
    this.days = const {},
  });

  factory CirclePerson.fromJson(Map<String, dynamic> j) => CirclePerson(
    id: j['id'] as String,
    name: j['name'] as String? ?? '',
    me: j['me'] as bool? ?? false,
    owner: j['owner'] as bool? ?? false,
    days: {...(j['days'] as List? ?? const []).cast<String>()},
  );
}

/// A shared deck a teacher set, due on [due] (`yyyy-mm-dd`).
class Assignment {
  final String id, shareCode, title, due;
  final int total;

  /// Words each member learned, by [CirclePerson.id]; a student gets only
  /// their own.
  final Map<String, int> progress;
  const Assignment({
    required this.id,
    required this.shareCode,
    required this.title,
    required this.due,
    required this.total,
    this.progress = const {},
  });

  factory Assignment.fromJson(Map<String, dynamic> j) => Assignment(
    id: j['id'] as String,
    shareCode: j['shareCode'] as String,
    title: j['title'] as String,
    due: j['due'] as String,
    total: j['total'] as int? ?? 0,
    progress: {
      for (final e in (j['progress'] as Map? ?? const {}).entries)
        e.key as String: e.value as int,
    },
  );
}

/// A circle with its week of study days and, for a class, its decks set.
class CircleDetail {
  final Circle circle;

  /// The seven days shown, Monday first.
  final List<String> week;
  final List<CirclePerson> people;
  final List<Assignment> assignments;
  const CircleDetail({
    required this.circle,
    required this.week,
    required this.people,
    this.assignments = const [],
  });

  factory CircleDetail.fromJson(Map<String, dynamic> j) => CircleDetail(
    circle: Circle.fromJson(j),
    week: (j['week'] as List).cast<String>(),
    people: [
      for (final p in (j['people'] as List).cast<Map<String, dynamic>>())
        CirclePerson.fromJson(p),
    ],
    assignments: [
      for (final a
          in (j['assignments'] as List? ?? const [])
              .cast<Map<String, dynamic>>())
        Assignment.fromJson(a),
    ],
  );
}
