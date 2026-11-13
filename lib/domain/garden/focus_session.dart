/// How a focus session ended.
enum FocusOutcome {
  /// Ran to the end; its tree joins the garden.
  done,

  /// Given up, or the app was left too long; a withered tree joins the garden.
  withered,

  /// Stopped in the first seconds; leaves nothing in the garden.
  cancelled;

  static FocusOutcome fromName(String name) =>
      values.firstWhere((o) => o.name == name, orElse: () => withered);
}

/// What a focus session was for: a built-in tag or one the learner made.
/// Sessions store only [id], so renaming a tag renames its past sessions.
class FocusTag {
  final String id;

  /// The learner's name for it; empty for a built-in tag, which is named in
  /// the learner's language instead.
  final String name;

  /// An index into the tag colors.
  final int color;
  const FocusTag(this.id, {this.name = '', this.color = 0});

  bool get builtIn => builtInTags.any((t) => t.id == id);

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'color': color};
  factory FocusTag.fromJson(Map<String, dynamic> j) => FocusTag(
    j['id'] as String,
    name: j['name'] as String? ?? '',
    color: j['color'] as int? ?? 0,
  );
}

/// Tags every learner has. Their ids are stored, so they never change.
const builtInTags = [
  FocusTag('english', color: 0),
  FocusTag('writing', color: 1),
  FocusTag('work', color: 2),
  FocusTag('other', color: 3),
];

const defaultTag = 'english';

/// One finished focus session, stored as a `focus` record.
///
/// A session is written once when it ends; giving it a bloom after the break
/// review rewrites the same record, so the later stamp wins.
class FocusSession {
  final String id;
  final DateTime start, end;

  /// The length the learner chose; [end] is earlier when it withered.
  final int plannedMinutes;

  /// The [FocusTag.id] it was tagged with.
  final String tag;
  final String title, species;
  final FocusOutcome outcome;

  /// Whether the learner reviewed due words in the break that followed.
  final bool bloomed;

  const FocusSession({
    required this.id,
    required this.start,
    required this.end,
    required this.plannedMinutes,
    required this.species,
    required this.outcome,
    this.tag = defaultTag,
    this.title = '',
    this.bloomed = false,
  });

  /// Minutes actually focused.
  int get minutes => end.difference(start).inMinutes;

  /// Whether the session leaves a tree, living or withered.
  bool get planted => outcome != FocusOutcome.cancelled;

  FocusSession copyWith({bool? bloomed}) => FocusSession(
    id: id,
    start: start,
    end: end,
    plannedMinutes: plannedMinutes,
    tag: tag,
    title: title,
    species: species,
    outcome: outcome,
    bloomed: bloomed ?? this.bloomed,
  );

  Map<String, dynamic> toJson() => {
    'start': start.toIso8601String(),
    'end': end.toIso8601String(),
    'planned': plannedMinutes,
    'tag': tag,
    if (title.isNotEmpty) 'title': title,
    'species': species,
    'outcome': outcome.name,
    if (bloomed) 'bloomed': true,
  };

  factory FocusSession.fromJson(String id, Map<String, dynamic> j) =>
      FocusSession(
        id: id,
        start: DateTime.parse(j['start'] as String),
        end: DateTime.parse(j['end'] as String),
        plannedMinutes: j['planned'] as int,
        tag: j['tag'] as String? ?? defaultTag,
        title: j['title'] as String? ?? '',
        species: j['species'] as String,
        outcome: FocusOutcome.fromName(j['outcome'] as String),
        bloomed: j['bloomed'] as bool? ?? false,
      );
}
