import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../core/design/design.dart';
import '../l10n/l10n.dart';
import 'press.dart';

class GlassMenuItem<T> {
  final T value;
  final String label;
  final bool checked;
  final IconData? icon;
  final IconData? trailing;

  /// Red label and icon, for actions such as "Xóa tất cả".
  final bool danger;

  /// A colour swatch before the label, as in the lesson's "Màu nền".
  final Color? dot;
  const GlassMenuItem(
    this.value,
    this.label, {
    this.checked = false,
    this.icon,
    this.trailing,
    this.danger = false,
    this.dot,
  });
}

/// The reference's system pop-up menu: frosted, 250 pt wide, growing from the
/// control that opened it. In the upper half it hangs from the control's top; in
/// the lower half it sits on the control's bottom. Returns the chosen value.
Future<T?> showGlassMenu<T>(
  BuildContext anchor,
  List<GlassMenuItem<T>> items, {
  String? title,
  IconData titleIcon = Icons.brush_outlined,
  T? titleValue,
  GlassMenuItem<T>? behind,
  Widget Function(BuildContext context, ValueChanged<T> choose)? footer,
}) {
  final box = anchor.findRenderObject()! as RenderBox;
  final rect = box.localToGlobal(Offset.zero) & box.size;
  return showGeneralDialog<T>(
    context: anchor,
    barrierDismissible: true,
    barrierLabel: anchor.t.close,
    barrierColor: Colors.transparent,
    transitionDuration: const Duration(milliseconds: 240),
    pageBuilder: (context, _, _) => Material(
      type: MaterialType.transparency,
      child: _GlassMenu<T>(
        anchor: rect,
        items: items,
        title: title,
        titleIcon: titleIcon,
        titleValue: titleValue,
        behind: behind,
        footer: footer,
      ),
    ),
    transitionBuilder: (context, animation, _, child) {
      final size = MediaQuery.sizeOf(context);
      final alignment = Alignment(
        rect.center.dx < size.width / 2 ? -1 : 1,
        rect.center.dy < size.height / 2 ? -1 : 1,
      );
      return FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
        child: ScaleTransition(
          alignment: alignment,
          scale: Tween<double>(begin: .72, end: 1).animate(
            CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutBack,
              reverseCurve: Curves.easeIn,
            ),
          ),
          child: child,
        ),
      );
    },
  );
}

class _GlassMenu<T> extends StatelessWidget {
  final Rect anchor;
  final List<GlassMenuItem<T>> items;
  final String? title;
  final IconData titleIcon;

  /// Returned when the submenu's title row is tapped, to go back up.
  final T? titleValue;

  /// The parent's top row, dimmed behind an opened submenu.
  final GlassMenuItem<T>? behind;

  /// Content under a divider, such as the lesson menu's Thích / Không thích.
  final Widget Function(BuildContext context, ValueChanged<T> choose)? footer;
  const _GlassMenu({
    required this.anchor,
    required this.items,
    this.title,
    this.titleIcon = Icons.brush_outlined,
    this.titleValue,
    this.behind,
    this.footer,
  });

  static const width = 250.0;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final fromLeft = anchor.center.dx < size.width / 2;
    final fromTop = anchor.center.dy < size.height / 2;
    final panel = ClipRSuperellipse(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          width: title != null ? width + 5 : width,
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: ShapeDecoration(
            color: Colors.white.withValues(alpha: .84),
            shape: RoundedSuperellipseBorder(
              borderRadius: BorderRadius.circular(28),
              side: BorderSide(color: D.ink.withValues(alpha: .1), width: .5),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (title != null) ...[
                _Row(
                  label: title!,
                  bold: true,
                  icon: titleIcon,
                  trailing: CupertinoIcons.chevron_down,
                  onTap: () => Navigator.pop(context, titleValue),
                ),
                const Padding(
                  padding: EdgeInsets.fromLTRB(24, 10, 24, 12),
                  child: Divider(height: 1, color: Palette.settingsEdge),
                ),
              ],
              for (final item in items)
                _Row(
                  label: item.label,
                  checked: item.checked,
                  icon: item.icon,
                  trailing: item.trailing,
                  danger: item.danger,
                  dot: item.dot,
                  reserveCheck: items.any((i) => i.dot != null),
                  onTap: () => Navigator.pop(context, item.value),
                ),
              if (footer != null) ...[
                const Padding(
                  padding: EdgeInsets.fromLTRB(24, 6, 24, 4),
                  child: Divider(height: 1, color: Palette.settingsEdge),
                ),
                footer!(context, (value) => Navigator.pop(context, value)),
              ],
            ],
          ),
        ),
      ),
    );
    return Stack(
      children: [
        if (behind != null)
          Positioned(
            right: size.width - anchor.right,
            top: anchor.top - 2,
            child: Opacity(
              opacity: .55,
              child: Container(
                width: width,
                height: 80,
                alignment: Alignment.topCenter,
                padding: const EdgeInsets.only(top: 8),
                decoration: ShapeDecoration(
                  color: Colors.white,
                  shape: RoundedSuperellipseBorder(
                    borderRadius: BorderRadius.circular(28),
                    side: BorderSide(
                      color: D.ink.withValues(alpha: .2),
                      width: .5,
                    ),
                  ),
                ),
                child: _Row(
                  label: behind!.label,
                  icon: behind!.icon,
                  onTap: () => Navigator.pop(context),
                ),
              ),
            ),
          ),
        Positioned(
          left: fromLeft ? anchor.left : null,
          right: fromLeft ? null : size.width - anchor.right,
          top: fromTop ? anchor.top - 2 + (behind != null ? 38 : 0) : null,
          bottom: fromTop ? null : size.height - anchor.bottom,
          child: DecoratedBox(
            decoration: ShapeDecoration(
              shape: RoundedSuperellipseBorder(
                borderRadius: BorderRadius.circular(28),
              ),
              shadows: [
                BoxShadow(
                  color: D.ink.withValues(alpha: .14),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: panel,
          ),
        ),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final bool checked, bold, danger, reserveCheck;
  final IconData? icon, trailing;
  final Color? dot;
  final VoidCallback onTap;
  const _Row({
    required this.label,
    required this.onTap,
    this.checked = false,
    this.bold = false,
    this.danger = false,
    this.reserveCheck = false,
    this.dot,
    this.icon,
    this.trailing,
  });
  @override
  Widget build(BuildContext context) => PressFade(
    onTap: onTap,
    child: SizedBox(
      height: 40,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 20, color: danger ? Palette.alertRed : D.ink),
              const SizedBox(width: 13),
            ],
            if (checked) ...[
              const Icon(CupertinoIcons.checkmark_alt, size: 20, color: D.ink),
              const SizedBox(width: 13),
            ] else if (reserveCheck) ...[
              const SizedBox(width: 33),
            ],
            if (dot != null) ...[
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
              ),
              const SizedBox(width: 20),
            ],
            Expanded(
              child: Text(
                label,
                style: D.text(
                  16,
                  weight: bold ? FontWeight.w700 : FontWeight.w400,
                  height: 20 / 16,
                  color: danger ? Palette.alertRed : D.ink,
                ),
              ),
            ),
            if (trailing != null) Icon(trailing, size: 14, color: D.ink),
          ],
        ),
      ),
    ),
  );
}
