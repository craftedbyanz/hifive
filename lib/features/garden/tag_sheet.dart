import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../core/design/design.dart';
import '../../domain/garden/garden.dart';
import '../../l10n/l10n.dart';
import '../../state/state.dart';
import '../../widgets/common.dart';

/// The name a tag shows: the learner's own, or a built-in one in the
/// learner's language.
String tagName(AppLocalizations t, FocusTag tag) => switch (tag.id) {
  'english' => t.focusTagEnglish,
  'writing' => t.focusTagWriting,
  'work' => t.focusTagWork,
  'other' => t.focusTagOther,
  _ => tag.name,
};

Color tagColor(FocusTag tag) =>
    Palette.tagColors[tag.color % Palette.tagColors.length];

/// Opens [TagSheet] over the focus screen, blurred and darkened behind.
Future<String?> showTagSheet(BuildContext context, String selected) =>
    showGeneralDialog<String>(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 260),
      pageBuilder: (_, _, _) => TagSheet(selected: selected),
      transitionBuilder: (_, animation, _, child) => FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
        child: child,
      ),
    );

/// Picks the focus tag, and makes, renames or deletes the learner's own,
/// as a column of frosted pills over the blurred focus screen. Pops the
/// picked tag id.
class TagSheet extends StatefulWidget {
  final String selected;
  const TagSheet({super.key, required this.selected});

  @override
  State<TagSheet> createState() => _TagSheetState();
}

class _TagSheetState extends State<TagSheet> {
  /// The tag being edited, '' for a new one, null while picking.
  String? _editing;
  final _name = TextEditingController();
  var _color = 4;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _edit(FocusTag? tag) => setState(() {
    _editing = tag?.id ?? '';
    _name.text = tag?.name ?? '';
    _color = tag?.color ?? 4 + AppScope.read(context).customTags.length % 4;
  });

  void _save() {
    final name = _name.text.trim();
    if (name.isEmpty) return;
    final state = AppScope.read(context);
    final id = _editing!;
    if (id.isEmpty) {
      Navigator.of(context).pop(state.addTag(name, _color));
    } else {
      state.editTag(id, name, _color);
      setState(() => _editing = null);
    }
  }

  Future<void> _delete() async {
    final t = context.t;
    final state = AppScope.read(context);
    final id = _editing!;
    final yes = await confirm(
      context,
      t.tagDeleteTitle,
      t.tagDeleteBody,
      action: t.tagDelete,
      cancel: t.cancel,
      destructive: true,
    );
    if (!yes || !mounted) return;
    state.deleteTag(id);
    setState(() => _editing = null);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final state = AppScope.of(context);
    final editing = _editing;
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
      child: Material(
        color: Palette.focusShade,
        child: SafeArea(
          child: Stack(
            children: [
              Positioned.fill(
                child: GestureDetector(
                  key: const ValueKey('tag-dismiss'),
                  behavior: HitTestBehavior.opaque,
                  onTap: () => editing == null
                      ? Navigator.of(context).pop()
                      : setState(() => _editing = null),
                ),
              ),
              SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(28, 24, 28, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (editing != null) ...[
                      Text(
                        editing.isEmpty ? t.tagNew : t.tagEditTitle,
                        textAlign: TextAlign.center,
                        style: D.text(
                          17,
                          weight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],
                    if (editing == null) ...[
                      for (final tag in state.focusTags)
                        _TagRow(
                          tag: tag,
                          name: tagName(t, tag),
                          picked: tag.id == widget.selected,
                          onPick: () => Navigator.of(context).pop(tag.id),
                          onEdit: tag.builtIn ? null : () => _edit(tag),
                        ),
                      const SizedBox(height: 18),
                      Center(
                        child: PressFade(
                          key: const ValueKey('tag-new'),
                          onTap: () => _edit(null),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  CupertinoIcons.add,
                                  size: 18,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  t.tagNew,
                                  style: D.text(
                                    15,
                                    weight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ] else ...[
                      TextField(
                        key: const ValueKey('tag-name'),
                        controller: _name,
                        autofocus: true,
                        maxLength: 24,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _save(),
                        style: D.text(
                          16,
                          weight: FontWeight.w600,
                          color: Colors.white,
                        ),
                        cursorColor: Colors.white,
                        decoration: InputDecoration(
                          hintText: t.tagNameHint,
                          hintStyle: D.text(
                            15,
                            color: Colors.white.withValues(alpha: .5),
                          ),
                          counterStyle: D.text(
                            11,
                            color: Colors.white.withValues(alpha: .5),
                          ),
                          filled: true,
                          fillColor: Colors.white.withValues(alpha: .12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          for (var i = 0; i < Palette.tagColors.length; i++)
                            PressFade(
                              key: ValueKey('tag-color-$i'),
                              onTap: () => setState(() => _color = i),
                              child: Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  color: Palette.tagColors[i],
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: i == _color
                                        ? Colors.white
                                        : Colors.transparent,
                                    width: 2.5,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          if (editing.isNotEmpty)
                            PressFade(
                              key: const ValueKey('tag-delete'),
                              onTap: _delete,
                              child: Text(
                                t.tagDelete,
                                style: D.text(
                                  15,
                                  weight: FontWeight.w600,
                                  color: Palette.wrong,
                                ),
                              ),
                            ),
                          const Spacer(),
                          ListenableBuilder(
                            listenable: _name,
                            builder: (context, _) => Opacity(
                              opacity: _name.text.trim().isEmpty ? .4 : 1,
                              child: PressFade(
                                key: const ValueKey('tag-save'),
                                onTap: _save,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 26,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(99),
                                  ),
                                  child: Text(
                                    t.tagSave,
                                    style: D.text(
                                      15,
                                      weight: FontWeight.w700,
                                      color: Palette.focusInk,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TagRow extends StatelessWidget {
  final FocusTag tag;
  final String name;
  final bool picked;
  final VoidCallback onPick;
  final VoidCallback? onEdit;
  const _TagRow({
    required this.tag,
    required this.name,
    required this.picked,
    required this.onPick,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: PressFade(
      key: ValueKey('tag-${tag.id}'),
      onTap: onPick,
      child: Container(
        height: 50,
        padding: const EdgeInsets.only(left: 18, right: 16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: picked ? .24 : .12),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: Colors.white.withValues(alpha: picked ? .95 : .28),
            width: picked ? 1.6 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: tagColor(tag),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: D.text(15, weight: FontWeight.w600, color: Colors.white),
              ),
            ),
            if (onEdit case final edit?)
              PressFade(
                key: ValueKey('tag-edit-${tag.id}'),
                onTap: edit,
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(
                    CupertinoIcons.pencil,
                    size: 19,
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),
      ),
    ),
  );
}
