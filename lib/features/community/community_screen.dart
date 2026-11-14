import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../core/design/design.dart';
import '../../domain/community/community.dart';
import '../../domain/models/models.dart';
import '../../l10n/l10n.dart';
import '../../state/state.dart';
import '../../widgets/common.dart';
import 'circle_screen.dart';
import 'circle_sheets.dart';
import 'explore_screen.dart';
import 'share_errors.dart';

/// Opens one of the learner's decks; the flashcards area owns that screen.
typedef OpenDeck = void Function(BuildContext context, Deck deck);

/// Community: public decks to explore, study groups and classes, in tabs.
class CommunityScreen extends StatefulWidget {
  final OpenDeck? onOpenDeck;
  final int initialTab;
  const CommunityScreen({super.key, this.onOpenDeck, this.initialTab = 0});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  late int _tab = widget.initialTab;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return AppPage(
      title: t.communityTitle,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
            child: CupertinoSlidingSegmentedControl<int>(
              key: const ValueKey('community-tabs'),
              groupValue: _tab,
              onValueChanged: (v) => setState(() => _tab = v ?? 0),
              children: {
                for (final (i, label) in [
                  t.tabExplore,
                  t.tabGroups,
                  t.tabClasses,
                ].indexed)
                  i: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Text(
                      label,
                      key: ValueKey('community-tab-$i'),
                      style: D.text(13.5, weight: FontWeight.w700),
                    ),
                  ),
              },
            ),
          ),
          Expanded(
            child: switch (_tab) {
              0 => ExploreView(onAdded: widget.onOpenDeck),
              1 => CirclesView(
                key: const ValueKey('circles-group'),
                kind: CircleKind.group,
                onOpenDeck: widget.onOpenDeck,
              ),
              _ => CirclesView(
                key: const ValueKey('circles-class'),
                kind: CircleKind.classroom,
                onOpenDeck: widget.onOpenDeck,
              ),
            },
          ),
        ],
      ),
    );
  }
}

/// The learner's groups or classes, with ways to make or join one.
class CirclesView extends StatefulWidget {
  final CircleKind kind;
  final OpenDeck? onOpenDeck;
  const CirclesView({super.key, required this.kind, this.onOpenDeck});

  @override
  State<CirclesView> createState() => _CirclesViewState();
}

class _CirclesViewState extends State<CirclesView> {
  late final AppState _state = AppScope.read(context);
  late Future<List<Circle>> _circles = _load();

  Future<List<Circle>> _load() => _state.myCircles()..ignore();

  void _reload() => setState(() {
    _circles = _load();
  });

  Future<void> _open(Circle c) async {
    await go<void>(
      context,
      CircleScreen(circle: c, onOpenDeck: widget.onOpenDeck),
    );
    if (mounted) _reload();
  }

  Future<void> _create() async {
    final made = await sheet<Circle>(
      context,
      CircleFormSheet(kind: widget.kind),
    );
    if (made != null && mounted) {
      _reload();
      await _open(made);
    }
  }

  Future<void> _join() async {
    final joined = await sheet<Circle>(context, const JoinCircleSheet());
    if (joined != null && mounted) {
      _reload();
      await _open(joined);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final group = widget.kind == CircleKind.group;
    return FutureBuilder<List<Circle>>(
      future: _circles,
      builder: (context, snap) {
        final list = [
          for (final c in snap.data ?? const <Circle>[])
            if (c.kind == widget.kind) c,
        ];
        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
          children: [
            Text(
              group ? t.groupsIntro : t.classesIntro,
              style: D.text(13.5, color: D.secondary, height: 1.45),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: ActionButton(
                    group ? t.groupCreate : t.classCreate,
                    key: const ValueKey('circle-create'),
                    icon: CupertinoIcons.plus,
                    onTap: _create,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ActionButton(
                    t.circleJoin,
                    key: const ValueKey('circle-join'),
                    icon: CupertinoIcons.ticket,
                    outlined: true,
                    color: D.ink,
                    foreground: D.ink,
                    onTap: _join,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            if (snap.hasError)
              _Problem(text: shareErrorText(t, snap.error!), onRetry: _reload)
            else if (!snap.hasData)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 30),
                child: CupertinoActivityIndicator(),
              )
            else if (list.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 30),
                child: Text(
                  group ? t.groupsEmpty : t.classesEmpty,
                  key: const ValueKey('circles-empty'),
                  textAlign: TextAlign.center,
                  style: D.text(14, color: D.secondary, height: 1.5),
                ),
              )
            else
              for (final c in list)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: PressFade(
                    key: ValueKey('circle-${c.id}'),
                    onTap: () => _open(c),
                    child: Surface(
                      radius: 20,
                      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                      child: Row(
                        children: [
                          Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              color: (group ? D.green : Palette.menuFocus)
                                  .withValues(alpha: .14),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(
                              group
                                  ? CupertinoIcons.person_3_fill
                                  : CupertinoIcons.book_fill,
                              size: 22,
                              color: group ? D.green : Palette.menuFocus,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  c.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: D.text(15.5, weight: FontWeight.w800),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  [
                                    t.circleMembers(c.members),
                                    if (group) t.circleGoal(c.goal),
                                    if (!group && c.owner) t.circleTeacher,
                                  ].join(' · '),
                                  style: D.text(12.5, color: D.secondary),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            CupertinoIcons.chevron_right,
                            size: 15,
                            color: D.muted,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
          ],
        );
      },
    );
  }
}

class _Problem extends StatelessWidget {
  final String text;
  final VoidCallback onRetry;
  const _Problem({required this.text, required this.onRetry});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 24),
    child: Column(
      children: [
        Text(
          text,
          key: const ValueKey('circles-error'),
          textAlign: TextAlign.center,
          style: D.text(14, color: D.secondary, height: 1.45),
        ),
        TextButton(
          onPressed: onRetry,
          child: Text(
            context.t.retry,
            style: D.text(14.5, weight: FontWeight.w700, color: D.blue),
          ),
        ),
      ],
    ),
  );
}
