import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../core/design/design.dart';
import '../l10n/l10n.dart';

/// Spaced capitals that name a section: "DANH MỤC", "BỘ SƯU TẬP" at 10 pt,
/// or the smaller "GIẢI THÍCH", "MẸO" of the feedback sheet with [small].
/// See docs/design-system.md.
class CapsLabel extends StatelessWidget {
  static final style = D.text(
    10,
    weight: FontWeight.w700,
    color: D.muted,
    spacing: 2,
  );
  static final smallStyle = D.text(
    9,
    weight: FontWeight.w800,
    color: D.muted,
    spacing: 1.8,
  );
  final String text;
  final bool small;

  /// Replaces the muted ink, for a label inside a mode-colored card.
  final Color? color;
  const CapsLabel(this.text, {super.key, this.small = false, this.color});
  @override
  Widget build(BuildContext context) =>
      Text(text, style: (small ? smallStyle : style).copyWith(color: color));
}

class PillBadge extends StatelessWidget {
  final String text;
  final Color color;
  const PillBadge(this.text, {super.key, this.color = D.blue});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .12),
      borderRadius: BorderRadius.circular(18),
    ),
    child: Text(
      text,
      style: D.text(11, color: color, weight: FontWeight.w700),
    ),
  );
}

class Stat extends StatelessWidget {
  final String value, label;
  final IconData? icon;
  final Color color;
  const Stat(
    this.value,
    this.label, {
    super.key,
    this.icon,
    this.color = D.blue,
  });
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      if (icon != null) ...[
        Icon(icon, size: 21, color: color),
        const SizedBox(height: 12),
      ],
      Text(value, style: D.text(28, weight: FontWeight.w800)),
      const SizedBox(height: 7),
      Text(label, style: D.text(11, color: D.muted)),
    ],
  );
}

/// Marks a feature whose content is still simulated: it is shown, can't be
/// opened, and carries this pill. [light] suits a coloured background.
class SoonBadge extends StatelessWidget {
  final bool light;
  const SoonBadge({super.key, this.light = false});
  @override
  Widget build(BuildContext context) {
    final ink = light ? D.ink : Colors.white;
    return Container(
      key: const ValueKey('soon-badge'),
      padding: const EdgeInsets.fromLTRB(8, 4, 10, 4),
      decoration: BoxDecoration(
        color: light ? Colors.white.withValues(alpha: .92) : D.ink,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(CupertinoIcons.clock_fill, size: 11, color: ink),
          const SizedBox(width: 4),
          Text(
            context.t.comingSoon,
            style: D.text(
              10.5,
              weight: FontWeight.w700,
              color: ink,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}
