import 'package:flutter/material.dart';

import '../core/design/design.dart';

class RoundButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final double size;
  final Color? color;
  const RoundButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.size = 46,
    this.color,
  });
  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: label,
    child: Tooltip(
      message: label,
      child: Material(
        color: color ?? Colors.white.withValues(alpha: .7),
        shape: CircleBorder(
          side: BorderSide(color: D.ink.withValues(alpha: .09)),
        ),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: size,
            height: size,
            child: Icon(
              icon,
              size: size * .49,
              color: onTap == null
                  ? D.muted
                  : color == D.ink
                  ? Colors.white
                  : D.ink,
            ),
          ),
        ),
      ),
    ),
  );
}

class ActionButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final Color color, foreground;
  final IconData? icon;

  /// A mark before the label in place of [icon], such as a brand's logo.
  final Widget? leading;

  /// An icon after the label, such as the arrow on a "Tiếp tục" button.
  final IconData? trailing;
  final bool outlined;
  const ActionButton(
    this.label, {
    super.key,
    required this.onTap,
    this.color = D.ink,
    this.foreground = Colors.white,
    this.icon,
    this.leading,
    this.trailing,
    this.outlined = false,
  });
  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    enabled: onTap != null,
    child: Material(
      color: outlined
          ? Colors.transparent
          : onTap == null
          ? D.line
          : color,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
        side: outlined
            ? const BorderSide(color: D.line, width: 1.5)
            : BorderSide.none,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(28),
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 52),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (leading case final mark?) ...[
                mark,
                const SizedBox(width: 10),
              ] else if (icon != null) ...[
                Icon(icon, color: outlined ? D.ink : foreground, size: 21),
                const SizedBox(width: 9),
              ],
              Flexible(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: D.text(
                    15,
                    weight: FontWeight.w700,
                    color: outlined
                        ? D.ink
                        : onTap == null
                        ? D.muted
                        : foreground,
                  ),
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 8),
                Icon(
                  trailing,
                  size: 19,
                  color: outlined
                      ? D.ink
                      : onTap == null
                      ? D.muted
                      : foreground,
                ),
              ],
            ],
          ),
        ),
      ),
    ),
  );
}
