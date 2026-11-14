import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../core/design/design.dart';
import '../../domain/community/community.dart';
import '../../domain/models/models.dart';
import '../../domain/repositories/repositories.dart';
import '../../l10n/l10n.dart';
import '../../state/state.dart';
import '../../widgets/common.dart';
import 'share_errors.dart';

/// What to tell the learner when a group or class call fails.
String circleErrorText(AppLocalizations t, Object error) =>
    switch (error is ShareException ? error.error : null) {
      ShareError.notFound => t.circleErrorNotFound,
      ShareError.tooMany => t.circleErrorTooMany,
      _ => shareErrorText(t, error),
    };

/// Makes a group or class, or edits [circle]'s name and goal. Returns the
/// circle made or changed.
class CircleFormSheet extends StatefulWidget {
  final CircleKind kind;
  final Circle? circle;
  const CircleFormSheet({super.key, required this.kind, this.circle});

  @override
  State<CircleFormSheet> createState() => _CircleFormSheetState();
}

class _CircleFormSheetState extends State<CircleFormSheet> {
  late final _name = TextEditingController(text: widget.circle?.name ?? '');
  late int _goal = widget.circle?.goal ?? 3;
  var _busy = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.isEmpty || _busy) return;
    final state = AppScope.read(context);
    final t = context.t;
    setState(() => _busy = true);
    try {
      final c = widget.circle;
      if (c == null) {
        final made = await state.createCircle(widget.kind, name, goal: _goal);
        if (mounted) Navigator.of(context).pop(made);
      } else {
        await state.updateCircle(c.id, name, _goal);
        if (!mounted) return;
        Navigator.of(context).pop(
          Circle(
            id: c.id,
            kind: c.kind,
            name: name,
            code: c.code,
            goal: _goal,
            owner: c.owner,
            members: c.members,
          ),
        );
      }
    } on Object catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      toast(context, circleErrorText(t, e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final group = widget.kind == CircleKind.group;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.circle != null
                ? t.circleEditTitle
                : group
                ? t.groupCreateTitle
                : t.classCreateTitle,
            style: D.text(20, weight: FontWeight.w800),
          ),
          const SizedBox(height: 14),
          TextField(
            key: const ValueKey('circle-name'),
            controller: _name,
            autofocus: true,
            maxLength: 60,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: t.circleNameHint,
              counterText: '',
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
          ),
          if (group) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text(
                    t.circleGoalLabel,
                    style: D.text(14.5, weight: FontWeight.w700),
                  ),
                ),
                _Step(
                  id: 'circle-goal-less',
                  icon: CupertinoIcons.minus,
                  onTap: _goal > 1 ? () => setState(() => _goal--) : null,
                ),
                SizedBox(
                  width: 70,
                  child: Text(
                    t.circleDays(_goal),
                    key: const ValueKey('circle-goal'),
                    textAlign: TextAlign.center,
                    style: D.text(15, weight: FontWeight.w800),
                  ),
                ),
                _Step(
                  id: 'circle-goal-more',
                  icon: CupertinoIcons.plus,
                  onTap: _goal < 7 ? () => setState(() => _goal++) : null,
                ),
              ],
            ),
          ],
          const SizedBox(height: 20),
          ActionButton(
            widget.circle != null
                ? t.save
                : group
                ? t.groupCreate
                : t.classCreate,
            key: const ValueKey('circle-save'),
            onTap: _name.text.trim().isEmpty || _busy ? null : _save,
          ),
        ],
      ),
    );
  }
}

class _Step extends StatelessWidget {
  final String id;
  final IconData icon;
  final VoidCallback? onTap;
  const _Step({required this.id, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => PressFade(
    key: ValueKey(id),
    onTap: onTap,
    child: Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: onTap == null ? D.background : Palette.settingsPage,
        shape: BoxShape.circle,
        border: Border.all(color: D.line),
      ),
      child: Icon(icon, size: 16, color: onTap == null ? D.muted : D.ink),
    ),
  );
}

/// Joins a group or class by its code; returns the circle joined.
class JoinCircleSheet extends StatefulWidget {
  const JoinCircleSheet({super.key});

  @override
  State<JoinCircleSheet> createState() => _JoinCircleSheetState();
}

class _JoinCircleSheetState extends State<JoinCircleSheet> {
  final _code = TextEditingController();
  String? _problem;
  var _busy = false;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _join() async {
    final t = context.t;
    final code = _code.text.toUpperCase().replaceAll(RegExp(r'[\s-]'), '');
    if (!RegExp(r'^[A-HJ-NP-Z2-9]{6}$').hasMatch(code)) {
      setState(() => _problem = t.importBadCode);
      return;
    }
    setState(() {
      _busy = true;
      _problem = null;
    });
    try {
      final joined = await AppScope.read(context).joinCircle(code);
      if (mounted) Navigator.of(context).pop(joined);
    } on Object catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _problem = circleErrorText(t, e);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(t.circleJoinTitle, style: D.text(20, weight: FontWeight.w800)),
          const SizedBox(height: 14),
          TextField(
            key: const ValueKey('circle-code'),
            controller: _code,
            autofocus: true,
            autocorrect: false,
            textCapitalization: TextCapitalization.characters,
            textInputAction: TextInputAction.go,
            onSubmitted: (_) => _join(),
            style: D.text(18, weight: FontWeight.w800, spacing: 3),
            decoration: InputDecoration(
              hintText: t.circleJoinHint,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
          ),
          if (_problem case final p?)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(
                p,
                key: const ValueKey('circle-join-problem'),
                style: D.text(13, color: Palette.wrong),
              ),
            ),
          const SizedBox(height: 18),
          ActionButton(
            t.circleJoin,
            key: const ValueKey('circle-join-go'),
            onTap: _busy ? null : _join,
          ),
        ],
      ),
    );
  }
}

/// The teacher picks one of their decks and a due date to set for class
/// [circleId]. Returns true once it is set.
class AssignDeckSheet extends StatefulWidget {
  final String circleId;
  const AssignDeckSheet({super.key, required this.circleId});

  @override
  State<AssignDeckSheet> createState() => _AssignDeckSheetState();
}

class _AssignDeckSheetState extends State<AssignDeckSheet> {
  late final AppState _state = AppScope.read(context);
  Deck? _deck;
  late DateTime _due = DateUtils.dateOnly(_state.now())
      .add(const Duration(days: 7));
  var _busy = false;

  Future<void> _pickDate() async {
    final today = DateUtils.dateOnly(_state.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: _due,
      firstDate: today,
      lastDate: today.add(const Duration(days: 365)),
    );
    if (picked != null && mounted) setState(() => _due = picked);
  }

  Future<void> _assign() async {
    final deck = _deck;
    if (deck == null || _busy) return;
    final t = context.t;
    setState(() => _busy = true);
    try {
      await _state.assignDeck(widget.circleId, deck, _due);
      if (mounted) Navigator.of(context).pop(true);
    } on Object catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      toast(context, circleErrorText(t, e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final decks = [
      for (final d in _state.decks)
        if (d.words.isNotEmpty) d,
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(t.classAssignTitle, style: D.text(20, weight: FontWeight.w800)),
          const SizedBox(height: 12),
          Text(
            t.classPickDeck,
            style: D.text(13, weight: FontWeight.w700, color: D.secondary),
          ),
          const SizedBox(height: 6),
          if (decks.isEmpty)
            Text(t.classNoDecks, style: D.text(14, color: D.secondary))
          else
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 260),
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final d in decks)
                    PressFade(
                      key: ValueKey('assign-deck-${d.id}'),
                      onTap: () => setState(() => _deck = d),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: _deck == d ? Palette.storyTop : D.background,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: _deck == d ? Palette.menuFocus : D.line,
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                d.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: D.text(14.5, weight: FontWeight.w700),
                              ),
                            ),
                            Text(
                              t.importWordCount(d.words.length),
                              style: D.text(12.5, color: D.secondary),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          const SizedBox(height: 12),
          PressFade(
            key: const ValueKey('assign-due'),
            onTap: _pickDate,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: D.background,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: D.line),
              ),
              child: Row(
                children: [
                  const Icon(
                    CupertinoIcons.calendar,
                    size: 18,
                    color: D.secondary,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    t.classDue,
                    style: D.text(14.5, weight: FontWeight.w600),
                  ),
                  const Spacer(),
                  Text(
                    MaterialLocalizations.of(context).formatMediumDate(_due),
                    style: D.text(14.5, weight: FontWeight.w800),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          ActionButton(
            t.classAssign,
            key: const ValueKey('assign-go'),
            onTap: _deck == null || _busy ? null : _assign,
          ),
        ],
      ),
    );
  }
}
