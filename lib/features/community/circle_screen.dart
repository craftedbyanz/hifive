import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../core/design/design.dart';
import '../../domain/community/community.dart';
import '../../domain/models/models.dart';
import '../../l10n/l10n.dart';
import '../../state/state.dart';
import '../../widgets/common.dart';
import 'circle_sheets.dart';

/// One group or class: its invite code, this week's study days for each
/// member and, for a class, the decks set with each student's progress.
class CircleScreen extends StatefulWidget {
  final Circle circle;
  final void Function(BuildContext context, Deck deck)? onOpenDeck;
  const CircleScreen({super.key, required this.circle, this.onOpenDeck});

  @override
  State<CircleScreen> createState() => _CircleScreenState();
}

class _CircleScreenState extends State<CircleScreen> {
  late final AppState _state = AppScope.read(context);
  late Future<CircleDetail> _detail = _load();
  late Circle _circle = widget.circle;

  Future<CircleDetail> _load() => _state.circle(widget.circle.id)..ignore();

  void _reload() => setState(() {
    _detail = _load();
  });

  bool get _group => _circle.kind == CircleKind.group;

  Future<void> _run(Future<void> Function() call) async {
    final t = context.t;
    try {
      await call();
      if (mounted) _reload();
    } on Object catch (e) {
      if (mounted) toast(context, circleErrorText(t, e));
    }
  }

  Future<void> _edit() async {
    final changed = await sheet<Circle>(
      context,
      CircleFormSheet(kind: _circle.kind, circle: _circle),
    );
    if (changed != null && mounted) {
      setState(() => _circle = changed);
      _reload();
    }
  }

  Future<void> _leave() async {
    final t = context.t;
    final yes = await confirm(
      context,
      t.circleLeaveTitle(_circle.name),
      t.circleLeaveBody,
      action: _group ? t.circleLeave : t.classLeave,
      cancel: t.cancel,
      destructive: true,
    );
    if (!yes || !mounted) return;
    try {
      await _state.leaveCircle(_circle.id);
      if (mounted) Navigator.of(context).pop();
    } on Object catch (e) {
      if (mounted) toast(context, circleErrorText(t, e));
    }
  }

  Future<void> _remove(CirclePerson p, String name) async {
    final t = context.t;
    final yes = await confirm(
      context,
      t.circleRemoveTitle(name),
      t.circleRemoveBody,
      action: t.circleRemove,
      cancel: t.cancel,
      destructive: true,
    );
    if (yes && mounted) {
      await _run(() => _state.removeFromCircle(_circle.id, p.id));
    }
  }

  Future<void> _assign() async {
    final done = await sheet<bool>(
      context,
      AssignDeckSheet(circleId: _circle.id),
    );
    if (done == true && mounted) _reload();
  }

  Future<void> _study(Assignment a) async {
    final t = context.t;
    try {
      final deck = await _state.assignedDeck(a);
      if (mounted) widget.onOpenDeck?.call(context, deck);
    } on Object catch (e) {
      if (mounted) toast(context, circleErrorText(t, e));
    }
  }

  String _nameOf(AppLocalizations t, CirclePerson p) => p.me
      ? t.circleYou
      : p.name.trim().isEmpty
      ? t.circleMemberUnknown
      : p.name.trim();

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return AppPage(
      title: _circle.name,
      trailing: _circle.owner
          ? HeaderRoundButton(
              key: const ValueKey('circle-edit'),
              icon: CupertinoIcons.pencil,
              iconSize: 20,
              label: t.circleEdit,
              onTap: _edit,
            )
          : null,
      child: FutureBuilder<CircleDetail>(
        future: _detail,
        builder: (context, snap) {
          final d = snap.data;
          return ListView(
            key: const ValueKey('circle-list'),
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
            children: [
              _InviteCard(circle: d?.circle ?? _circle),
              const SizedBox(height: 20),
              if (snap.hasError)
                Column(
                  children: [
                    Text(
                      circleErrorText(t, snap.error!),
                      textAlign: TextAlign.center,
                      style: D.text(14, color: D.secondary, height: 1.45),
                    ),
                    TextButton(
                      onPressed: _reload,
                      child: Text(
                        t.retry,
                        style: D.text(
                          14.5,
                          weight: FontWeight.w700,
                          color: D.blue,
                        ),
                      ),
                    ),
                  ],
                )
              else if (d == null)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 30),
                  child: CupertinoActivityIndicator(),
                )
              else ...[
                if (!_group) ..._classPart(t, d),
                _Heading(_group ? t.circleThisWeek : t.classStudents),
                if (!_group &&
                    _circle.owner &&
                    d.people.where((p) => !p.me).isEmpty)
                  Text(
                    t.classNoStudents,
                    style: D.text(14, color: D.secondary, height: 1.45),
                  )
                else
                  _Week(
                    week: d.week,
                    today: AppState.dayKey(_state.now()),
                    goal: _group ? _circle.goal : null,
                    people: [
                      for (final p in d.people)
                        if (_group || !_circle.owner || !p.me) p,
                    ],
                    nameOf: (p) => _nameOf(t, p),
                    onRemove: _circle.owner
                        ? (p) => _remove(p, _nameOf(t, p))
                        : null,
                  ),
              ],
              const SizedBox(height: 28),
              Center(
                child: TextButton(
                  key: const ValueKey('circle-leave'),
                  onPressed: _leave,
                  child: Text(
                    _group ? t.circleLeave : t.classLeave,
                    style: D.text(
                      14,
                      weight: FontWeight.w700,
                      color: Palette.wrong,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  List<Widget> _classPart(AppLocalizations t, CircleDetail d) {
    final today = AppState.dayKey(_state.now());
    final students = [
      for (final p in d.people)
        if (!p.owner) p,
    ];
    return [
      _Heading(t.classAssignments),
      if (d.assignments.isEmpty)
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Text(
            t.classNoAssignments,
            key: const ValueKey('class-no-assignments'),
            style: D.text(14, color: D.secondary),
          ),
        ),
      for (final a in d.assignments)
        _circle.owner
            ? _TeacherAssignment(
                assignment: a,
                students: students,
                today: today,
                nameOf: (p) => _nameOf(t, p),
                onRemove: () => _run(() => _state.unassign(_circle.id, a.id)),
              )
            : _StudentAssignment(
                assignment: a,
                today: today,
                onStudy: () => _study(a),
              ),
      if (_circle.owner) ...[
        const SizedBox(height: 4),
        ActionButton(
          t.classAssign,
          key: const ValueKey('class-assign'),
          icon: CupertinoIcons.plus,
          onTap: _assign,
        ),
      ],
      const SizedBox(height: 22),
    ];
  }
}

class _Heading extends StatelessWidget {
  final String text;
  const _Heading(this.text);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(text, style: D.text(17, weight: FontWeight.w800)),
  );
}

/// The invite code to copy or send.
class _InviteCard extends StatelessWidget {
  final Circle circle;
  const _InviteCard({required this.circle});

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final state = AppScope.read(context);
    final group = circle.kind == CircleKind.group;
    return Surface(
      radius: 22,
      padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  [
                    t.circleMembers(circle.members),
                    if (group) t.circleGoal(circle.goal),
                  ].join(' · '),
                  style: D.text(12.5, color: D.secondary),
                ),
                const SizedBox(height: 6),
                Text(
                  t.circleCode.toUpperCase(),
                  style: D.text(
                    10.5,
                    weight: FontWeight.w800,
                    color: D.muted,
                    spacing: .5,
                  ),
                ),
                PressFade(
                  key: const ValueKey('circle-code-copy'),
                  onTap: () async {
                    await Clipboard.setData(ClipboardData(text: circle.code));
                    if (context.mounted) toast(context, t.shareCopied);
                  },
                  child: Text(
                    circle.code,
                    key: const ValueKey('circle-code-text'),
                    style: D.text(
                      26,
                      weight: FontWeight.w800,
                      color: Palette.focusInk,
                      spacing: 4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          ActionButton(
            t.circleInvite,
            key: const ValueKey('circle-invite'),
            icon: CupertinoIcons.share,
            onTap: () => state.system.shareText(
              group
                  ? t.groupInviteMessage(circle.name, circle.code)
                  : t.classInviteMessage(circle.name, circle.code),
            ),
          ),
        ],
      ),
    );
  }
}

/// Each member's study days this week as seven dots, with how far they are
/// towards the group's [goal].
class _Week extends StatelessWidget {
  final List<String> week;
  final String today;
  final int? goal;
  final List<CirclePerson> people;
  final String Function(CirclePerson) nameOf;
  final void Function(CirclePerson)? onRemove;
  const _Week({
    required this.week,
    required this.today,
    required this.goal,
    required this.people,
    required this.nameOf,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final locale = t.localeName;
    final sorted = [...people]
      ..sort((a, b) => b.days.length.compareTo(a.days.length));
    return Surface(
      radius: 22,
      padding: const EdgeInsets.fromLTRB(14, 12, 10, 8),
      child: Column(
        children: [
          Row(
            children: [
              const Expanded(child: SizedBox()),
              for (final d in week)
                SizedBox(
                  width: 24,
                  child: Text(
                    _weekday(locale, DateTime.parse(d)),
                    textAlign: TextAlign.center,
                    style: D.text(
                      11,
                      weight: FontWeight.w800,
                      color: d == today ? Palette.menuFocus : D.muted,
                    ),
                  ),
                ),
              const SizedBox(width: 66),
            ],
          ),
          const SizedBox(height: 4),
          for (final p in sorted)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                key: ValueKey('circle-person-${p.id}'),
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Flexible(
                          child: Text(
                            nameOf(p),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: D.text(
                              14,
                              weight: p.me ? FontWeight.w800 : FontWeight.w600,
                            ),
                          ),
                        ),
                        if (p.owner) ...[
                          const SizedBox(width: 4),
                          Icon(
                            goal == null
                                ? CupertinoIcons.book_fill
                                : CupertinoIcons.star_fill,
                            size: 11,
                            color: Palette.menuPlus,
                          ),
                        ],
                      ],
                    ),
                  ),
                  for (final d in week)
                    SizedBox(
                      width: 24,
                      child: Center(
                        child: Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            color: p.days.contains(d) ? D.green : D.line,
                            shape: BoxShape.circle,
                            border: d == today
                                ? Border.all(
                                    color: Palette.menuFocus,
                                    width: 1.5,
                                  )
                                : null,
                          ),
                        ),
                      ),
                    ),
                  SizedBox(
                    width: 66,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (goal case final g?) ...[
                            if (p.days.length >= g)
                              const Icon(
                                CupertinoIcons.checkmark_seal_fill,
                                size: 14,
                                color: D.green,
                              ),
                            const SizedBox(width: 2),
                            Text(
                              '${p.days.length}/$g',
                              style: D.text(12, weight: FontWeight.w800),
                            ),
                          ] else
                            Text(
                              '${p.days.length}',
                              style: D.text(12, weight: FontWeight.w800),
                            ),
                          if (onRemove != null && !p.me)
                            PressFade(
                              key: ValueKey('circle-remove-${p.id}'),
                              onTap: () => onRemove!(p),
                              child: const Padding(
                                padding: EdgeInsets.only(left: 4),
                                child: Icon(
                                  CupertinoIcons.xmark_circle_fill,
                                  size: 16,
                                  color: D.muted,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// A short weekday name: T2…CN in Vietnamese, one or two letters elsewhere.
String _weekday(String locale, DateTime day) {
  if (locale.startsWith('vi')) {
    return day.weekday == DateTime.sunday ? 'CN' : 'T${day.weekday + 1}';
  }
  final name = DateFormat.E(locale).format(day);
  if (locale.startsWith('zh')) return name.substring(name.length - 1);
  return name.length > 2 ? name.substring(0, 2) : name;
}

String _dueText(BuildContext context, String due) => context.t.classDueOn(
  DateFormat.MMMd(context.t.localeName).format(DateTime.parse(due)),
);

/// A deck set, as a student sees it: their progress and a way to study.
class _StudentAssignment extends StatelessWidget {
  final Assignment assignment;
  final String today;
  final VoidCallback onStudy;
  const _StudentAssignment({
    required this.assignment,
    required this.today,
    required this.onStudy,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final a = assignment;
    final done = a.progress.values.firstOrNull ?? 0;
    final finished = a.total > 0 && done >= a.total;
    final late = !finished && today.compareTo(a.due) > 0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Surface(
        key: ValueKey('assignment-${a.id}'),
        radius: 20,
        padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(a.title, style: D.text(15, weight: FontWeight.w800)),
                  const SizedBox(height: 2),
                  Text(
                    '${_dueText(context, a.due)} · ${t.classProgress(done, a.total)}',
                    style: D.text(
                      12.5,
                      color: late ? Palette.wrong : D.secondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: LinearProgressIndicator(
                      value: a.total == 0 ? 0 : done / a.total,
                      minHeight: 6,
                      color: finished ? D.green : Palette.menuFocus,
                      backgroundColor: D.line,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            finished
                ? Text(
                    t.classDone,
                    style: D.text(13, weight: FontWeight.w800, color: D.green),
                  )
                : PressFade(
                    key: ValueKey('assignment-study-${a.id}'),
                    onTap: onStudy,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: D.ink,
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(
                        t.classStudy,
                        style: D.text(
                          13,
                          weight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}

/// A deck set, as the teacher sees it: how many students are done, and
/// each student's progress when opened.
class _TeacherAssignment extends StatefulWidget {
  final Assignment assignment;
  final List<CirclePerson> students;
  final String today;
  final String Function(CirclePerson) nameOf;
  final VoidCallback onRemove;
  const _TeacherAssignment({
    required this.assignment,
    required this.students,
    required this.today,
    required this.nameOf,
    required this.onRemove,
  });

  @override
  State<_TeacherAssignment> createState() => _TeacherAssignmentState();
}

class _TeacherAssignmentState extends State<_TeacherAssignment> {
  var _open = false;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final a = widget.assignment;
    final past = widget.today.compareTo(a.due) > 0;
    int done(CirclePerson p) => a.progress[p.id] ?? 0;
    final finished = widget.students
        .where((p) => a.total > 0 && done(p) >= a.total)
        .length;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Surface(
        key: ValueKey('assignment-${a.id}'),
        radius: 20,
        padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PressFade(
              key: ValueKey('assignment-open-${a.id}'),
              onTap: () => setState(() => _open = !_open),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          a.title,
                          style: D.text(15, weight: FontWeight.w800),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${_dueText(context, a.due)} · ${t.classDoneCount(finished, widget.students.length)}',
                          style: D.text(12.5, color: D.secondary),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _open
                        ? CupertinoIcons.chevron_up
                        : CupertinoIcons.chevron_down,
                    size: 15,
                    color: D.muted,
                  ),
                ],
              ),
            ),
            if (_open) ...[
              const SizedBox(height: 10),
              for (final p in widget.students)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Row(
                    key: ValueKey('report-${a.id}-${p.id}'),
                    children: [
                      SizedBox(
                        width: 110,
                        child: Text(
                          widget.nameOf(p),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: D.text(13.5, weight: FontWeight.w600),
                        ),
                      ),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(99),
                          child: LinearProgressIndicator(
                            value: a.total == 0 ? 0 : done(p) / a.total,
                            minHeight: 6,
                            color: done(p) >= a.total
                                ? D.green
                                : Palette.menuFocus,
                            backgroundColor: D.line,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 64,
                        child: Text(
                          done(p) >= a.total
                              ? t.classDone
                              : past
                              ? t.classLate
                              : '${done(p)}/${a.total}',
                          textAlign: TextAlign.end,
                          style: D.text(
                            12.5,
                            weight: FontWeight.w800,
                            color: done(p) >= a.total
                                ? D.green
                                : past
                                ? Palette.wrong
                                : D.ink,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  key: ValueKey('assignment-remove-${a.id}'),
                  onPressed: widget.onRemove,
                  child: Text(
                    t.classUnassign,
                    style: D.text(
                      13,
                      weight: FontWeight.w700,
                      color: Palette.wrong,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
