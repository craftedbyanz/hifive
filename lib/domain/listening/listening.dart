/// One day's listening to one video, stored as a `listen` record with the id
/// `<video>@<day>`. A day's record is rewritten as listening goes on, so the
/// later stamp wins; days and videos never collide across devices.
class ListenDay {
  /// The YouTube video id.
  final String video;

  /// The local date, `yyyy-mm-dd`.
  final String day;

  /// Where playback stood last, in seconds.
  final int position;

  /// Seconds actually heard that day; seeking adds nothing.
  final int heard;

  /// Whether the video played to its end that day.
  final bool done;

  /// When the record was last written.
  final DateTime at;

  const ListenDay({
    required this.video,
    required this.day,
    required this.position,
    required this.heard,
    required this.done,
    required this.at,
  });

  String get id => '$video@$day';

  Map<String, dynamic> toJson() => {
    'pos': position,
    'heard': heard,
    'done': done,
    'at': at.toUtc().toIso8601String(),
  };

  factory ListenDay.fromJson(String id, Map<String, dynamic> j) {
    final at = id.lastIndexOf('@');
    return ListenDay(
      video: id.substring(0, at),
      day: id.substring(at + 1),
      position: j['pos'] as int? ?? 0,
      heard: j['heard'] as int? ?? 0,
      done: j['done'] as bool? ?? false,
      at: DateTime.parse(j['at'] as String).toLocal(),
    );
  }
}

/// Where the learner stands with one video, from all its days.
class ListenProgress {
  /// The position of the latest day.
  final int position;

  /// Whether it was ever heard to the end.
  final bool done;

  /// When it was last played.
  final DateTime at;
  const ListenProgress({
    required this.position,
    required this.done,
    required this.at,
  });
}

/// The learner's listening, derived from [ListenDay] records.
class ListenLog {
  final Map<String, ListenDay> _days;
  ListenLog([Iterable<ListenDay> days = const []])
    : _days = {for (final d in days) d.id: d};

  /// Seconds heard in a day that make it a study day.
  static const studySeconds = 60;

  ListenDay? day(String video, String day) => _days['$video@$day'];

  Iterable<ListenDay> get days => _days.values;

  void put(ListenDay day) => _days[day.id] = day;

  /// Every video's progress, by video id.
  Map<String, ListenProgress> get progress {
    final out = <String, ListenProgress>{};
    for (final d in _days.values) {
      final p = out[d.video];
      final latest = p == null || d.at.isAfter(p.at);
      out[d.video] = ListenProgress(
        position: latest ? d.position : p.position,
        done: d.done || (p?.done ?? false),
        at: latest ? d.at : p.at,
      );
    }
    return out;
  }

  /// Seconds heard on [day], every video together.
  int heardOn(String day) => _days.values
      .where((d) => d.day == day)
      .fold(0, (sum, d) => sum + d.heard);

  /// Days with at least [studySeconds] heard.
  Set<String> get studyDays {
    final byDay = <String, int>{};
    for (final d in _days.values) {
      byDay[d.day] = (byDay[d.day] ?? 0) + d.heard;
    }
    return {
      for (final e in byDay.entries)
        if (e.value >= studySeconds) e.key,
    };
  }
}
