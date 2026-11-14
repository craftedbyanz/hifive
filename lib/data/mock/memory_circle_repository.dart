import '../../domain/community/community.dart';
import '../../domain/repositories/repositories.dart';
import 'memory_share_repository.dart';

/// [CircleRepository] in memory, for tests and offline builds, following
/// the server's rules. An ID token stands for its account; tests say who
/// studied when ([studied]), what they learned ([learned]) and their names
/// ([names]). Shared decks come from [shares]. Codes run GRUPA2, GRUPA3…
class MemoryCircleRepository implements CircleRepository {
  final MemoryShareRepository? shares;
  MemoryCircleRepository({this.shares});

  final circles = <String, ({Circle circle, String owner})>{};
  final members = <String, List<String>>{};
  final assignments =
      <
        String,
        List<
          ({
            String id,
            String code,
            String title,
            List<String> words,
            String due,
          })
        >
      >{};
  final names = <String, String>{};
  final studied = <String, Set<String>>{};
  final learned = <String, Set<String>>{};
  var _next = 0;

  String _member(String id, String token) =>
      '$id:$token'.hashCode.toRadixString(16);

  Circle _view(String id, String token) {
    final c = circles[id]!;
    return Circle(
      id: id,
      kind: c.circle.kind,
      name: c.circle.name,
      code: c.circle.code,
      goal: c.circle.goal,
      owner: c.owner == token,
      members: members[id]!.length,
    );
  }

  void _in(String id, String token) {
    if (!(members[id]?.contains(token) ?? false)) {
      throw const ShareException(ShareError.notFound);
    }
  }

  @override
  Future<List<Circle>> mine(String idToken) async => [
    for (final id in members.keys.toList().reversed)
      if (members[id]!.contains(idToken)) _view(id, idToken),
  ];

  @override
  Future<Circle> create(
    String idToken, {
    required CircleKind kind,
    required String name,
    int goal = 3,
  }) async {
    final id = 'c${_next++}';
    final code = 'GRUPA${'23456789'[_next % 8]}';
    circles[id] = (
      circle: Circle(id: id, kind: kind, name: name, code: code, goal: goal),
      owner: idToken,
    );
    members[id] = [idToken];
    assignments[id] = [];
    return _view(id, idToken);
  }

  @override
  Future<Circle> join(String idToken, String code) async {
    final id = circles.entries
        .where((e) => e.value.circle.code == code.toUpperCase())
        .map((e) => e.key)
        .firstOrNull;
    if (id == null) throw const ShareException(ShareError.notFound);
    if (!members[id]!.contains(idToken)) members[id]!.add(idToken);
    return _view(id, idToken);
  }

  @override
  Future<CircleDetail> detail(String idToken, String id, String monday) async {
    _in(id, idToken);
    final c = circles[id]!;
    final start = DateTime.parse(monday);
    final week = [
      for (var i = 0; i < 7; i++)
        start.add(Duration(days: i)).toIso8601String().substring(0, 10),
    ];
    final teacher = c.circle.kind == CircleKind.classroom && c.owner == idToken;
    final visible = c.circle.kind == CircleKind.classroom && !teacher
        ? members[id]!.where((t) => t == idToken || t == c.owner)
        : members[id]!;
    return CircleDetail(
      circle: _view(id, idToken),
      week: week,
      people: [
        for (final t in visible)
          CirclePerson(
            id: _member(id, t),
            name: names[t] ?? '',
            me: t == idToken,
            owner: t == c.owner,
            days: {...?studied[t]}.where(week.contains).toSet(),
          ),
      ],
      assignments: [
        for (final a in assignments[id]!)
          Assignment(
            id: a.id,
            shareCode: a.code,
            title: a.title,
            due: a.due,
            total: a.words.length,
            progress: {
              for (final t
                  in teacher
                      ? members[id]!.where((t) => t != idToken)
                      : [idToken])
                _member(id, t): a.words
                    .where((w) => learned[t]?.contains(w) ?? false)
                    .length,
            },
          ),
      ],
    );
  }

  @override
  Future<void> update(
    String idToken,
    String id, {
    required String name,
    required int goal,
  }) async {
    final c = circles[id];
    if (c == null || c.owner != idToken) {
      throw const ShareException(ShareError.notFound);
    }
    circles[id] = (
      circle: Circle(
        id: id,
        kind: c.circle.kind,
        name: name,
        code: c.circle.code,
        goal: goal,
      ),
      owner: c.owner,
    );
  }

  @override
  Future<void> leave(String idToken, String id) async {
    _in(id, idToken);
    members[id]!.remove(idToken);
    if (members[id]!.isEmpty) {
      circles.remove(id);
      members.remove(id);
      assignments.remove(id);
    } else if (circles[id]!.owner == idToken) {
      circles[id] = (circle: circles[id]!.circle, owner: members[id]!.first);
    }
  }

  @override
  Future<void> remove(String idToken, String id, String member) async {
    _in(id, idToken);
    if (circles[id]!.owner != idToken) {
      throw const ShareException(ShareError.notFound);
    }
    members[id]!.removeWhere((t) => t != idToken && _member(id, t) == member);
  }

  @override
  Future<void> assign(
    String idToken,
    String id,
    String shareCode,
    String due,
  ) async {
    _in(id, idToken);
    final deck = shares?.decks[shareCode];
    if (circles[id]!.owner != idToken || deck == null) {
      throw const ShareException(ShareError.notFound);
    }
    assignments[id]!.add((
      id: 'a${_next++}',
      code: shareCode,
      title: deck.title,
      words: {for (final w in deck.words) w.word.toLowerCase()}.toList(),
      due: due,
    ));
  }

  @override
  Future<void> unassign(String idToken, String id, String assignment) async {
    _in(id, idToken);
    assignments[id]!.removeWhere((a) => a.id == assignment);
  }
}
