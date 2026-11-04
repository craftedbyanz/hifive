import 'package:flutter/material.dart';

import '../core/design/design.dart';

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
  const CapsLabel(this.text, {super.key, this.small = false});
  @override
  Widget build(BuildContext context) =>
      Text(text, style: small ? smallStyle : style);
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
