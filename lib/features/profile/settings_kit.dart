import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/design/design.dart';
import '../../widgets/blur_header.dart';
import '../../widgets/press.dart';

/// Header title size shared by the Profile sub-screens.
const settingsTitleSize = 16.5;

/// The pinned footer's measured insets around a call to action at y = 746.
const settingsFooterPadding = EdgeInsets.fromLTRB(24, 18, 24, 50);

/// A Profile sub-screen with its measured header and page color.
class SettingsPage extends StatelessWidget {
  final String title;
  final Color background;
  final EdgeInsets padding;
  final Widget child;
  final Widget? footer;
  final Widget? trailing;
  const SettingsPage({
    super.key,
    required this.title,
    this.background = Palette.settingsPage,
    required this.padding,
    required this.child,
    this.footer,
    this.trailing,
  });
  @override
  Widget build(BuildContext context) => HeaderScrollPage(
    title: title,
    titleSize: settingsTitleSize,
    background: background,
    padding: padding,
    footer: footer,
    trailing: trailing,
    child: child,
  );
}

/// The full-width pill at the bottom of a settings screen.
class SettingsCta extends StatelessWidget {
  final String label;
  final Color color;
  final Color foreground;
  final VoidCallback? onTap;
  final Widget? icon;
  const SettingsCta(
    this.label, {
    super.key,
    required this.color,
    this.foreground = Colors.white,
    required this.onTap,
    this.icon,
  });
  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    enabled: onTap != null,
    child: PressFade(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 56,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(28),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: D.text(
                15.5,
                weight: FontWeight.w700,
                color: foreground,
                height: 20 / 15.5,
              ),
            ),
            if (icon != null) ...[const SizedBox(width: 8), icon!],
          ],
        ),
      ),
    ),
  );
}

/// A white list card. The selected one gains the reference's double ring and
/// grows by 5 pt on each vertical edge.
class SelectCard extends StatelessWidget {
  final bool selected;
  final double height;
  final VoidCallback onTap;
  final Widget child;
  const SelectCard({
    super.key,
    required this.selected,
    required this.height,
    required this.onTap,
    required this.child,
  });
  @override
  Widget build(BuildContext context) => PressFade(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      height: selected ? height + 10 : height,
      padding: EdgeInsets.all(selected ? 5 : 0),
      decoration: ShapeDecoration(
        shape: RoundedSuperellipseBorder(
          borderRadius: BorderRadius.circular(31),
          side: BorderSide(
            color: selected ? Palette.settingsEdge : Colors.transparent,
            width: 1.5,
          ),
        ),
      ),
      child: DecoratedBox(
        decoration: ShapeDecoration(
          color: Colors.white,
          shape: RoundedSuperellipseBorder(
            borderRadius: BorderRadius.circular(26),
            side: BorderSide(
              color: selected ? Palette.settingsPanel : Colors.transparent,
            ),
          ),
        ),
        child: child,
      ),
    ),
  );
}

/// The art, title and subtitle at the top of the language and voice screens.
class SettingsHero extends StatelessWidget {
  final Widget art;
  final String title, subtitle;
  final double gap, subtitleInset;
  const SettingsHero({
    super.key,
    required this.art,
    required this.title,
    required this.subtitle,
    this.gap = 15,
    this.subtitleInset = 1,
  });
  @override
  Widget build(BuildContext context) => Column(
    children: [
      art,
      SizedBox(height: gap),
      Text(
        title,
        textAlign: TextAlign.center,
        style: D.text(23, weight: FontWeight.w800, height: 30 / 23),
      ),
      const SizedBox(height: 11),
      Padding(
        padding: EdgeInsets.symmetric(horizontal: subtitleInset),
        child: Text(
          subtitle,
          textAlign: TextAlign.center,
          style: D.text(14, color: Palette.settingsMuted, height: 18 / 14),
        ),
      ),
    ],
  );
}

class SettingsSectionTitle extends StatelessWidget {
  final String text;
  const SettingsSectionTitle(this.text, {super.key});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(left: 4),
    child: Text(
      text,
      style: D.text(18, weight: FontWeight.w700, height: 25 / 18),
    ),
  );
}

/// The translated speech bubbles above the language list.
class TranslateBubblesPainter extends CustomPainter {
  const TranslateBubblesPainter();
  @override
  void paint(Canvas canvas, Size size) {
    final line = Paint()
      ..color = Palette.accentCyan
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeJoin = StrokeJoin.round;
    final left = Path()
      ..addRRect(RRect.fromLTRBR(1.5, 1.5, 44, 36, const Radius.circular(9)))
      ..moveTo(14, 36)
      ..lineTo(14, 44)
      ..lineTo(24, 36);
    canvas.drawPath(left, line);
    _letter(canvas, 'A', const Offset(21, 18), 22, Palette.accentCyan);
    final fill = Paint()..color = Palette.accentCyan;
    final right = Path()
      ..addRRect(RRect.fromLTRBR(32, 14, 74, 47, const Radius.circular(9)))
      ..moveTo(50, 46)
      ..lineTo(62, 55)
      ..lineTo(61, 46)
      ..close();
    canvas.drawPath(
      right,
      Paint()
        ..color = Palette.settingsPage
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5,
    );
    canvas.drawPath(right, fill);
    _letter(canvas, '文', const Offset(53, 30), 21, Colors.white);
  }

  void _letter(
    Canvas canvas,
    String text,
    Offset center,
    double size,
    Color c,
  ) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: D.text(size, weight: FontWeight.w700, color: c),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(canvas, center - painter.size.center(Offset.zero));
    painter.dispose();
  }

  @override
  bool shouldRepaint(TranslateBubblesPainter oldDelegate) => false;
}

/// Seven rounded bars above the voice list.
class VoiceBarsPainter extends CustomPainter {
  const VoiceBarsPainter();
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Palette.accentCyan
      ..strokeWidth = 3.6
      ..strokeCap = StrokeCap.round;
    const heights = [.26, .58, 1.0, .42, .72, .26];
    final step = (size.width - 3.6) / (heights.length - 1);
    for (final (i, height) in heights.indexed) {
      final x = 1.8 + i * step;
      final half = (size.height - 3.6) * height / 2;
      canvas.drawLine(
        Offset(x, size.height / 2 - half),
        Offset(x, size.height / 2 + half),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(VoiceBarsPainter oldDelegate) => false;
}

class KoreaFlagPainter extends CustomPainter {
  const KoreaFlagPainter();
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = Palette.settingsPanel);
    final c = size.center(Offset.zero);
    final r = size.height * .27;
    final disc = Rect.fromCircle(center: c, radius: r);
    canvas.drawArc(disc, math.pi * .15, math.pi, true, Paint()..color = D.blue);
    canvas.drawArc(
      disc,
      math.pi * 1.15,
      math.pi,
      true,
      Paint()..color = Palette.flagRed,
    );
    final bars = Paint()
      ..color = D.ink
      ..strokeWidth = 1.6;
    for (final (dx, dy) in const [
      (-1.0, -1.0),
      (1.0, -1.0),
      (-1.0, 1.0),
      (1.0, 1.0),
    ]) {
      for (var i = 0; i < 3; i++) {
        final center =
            c + Offset(dx * (r + 5 + i * 2.6), dy * (r * .72 + i * 1.8));
        final along = Offset(dy * 3.2, -dx * 3.2);
        canvas.drawLine(center - along, center + along, bars);
      }
    }
  }

  @override
  bool shouldRepaint(KoreaFlagPainter oldDelegate) => false;
}

class ChinaFlagPainter extends CustomPainter {
  const ChinaFlagPainter();
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = Palette.flagChinaRed);
    final gold = Paint()..color = Palette.inputYellow;
    _star(canvas, Offset(size.width * .19, size.height * .3), 5.6, gold);
    for (final p in const [(.37, .12), (.45, .25), (.45, .42), (.37, .55)]) {
      _star(canvas, Offset(size.width * p.$1, size.height * p.$2), 1.8, gold);
    }
  }

  void _star(Canvas canvas, Offset c, double r, Paint paint) {
    final path = Path();
    for (var i = 0; i < 10; i++) {
      final radius = i.isEven ? r : r * .42;
      final a = -math.pi / 2 + i * math.pi / 5;
      final p = c + Offset(math.cos(a), math.sin(a)) * radius;
      i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(path..close(), paint);
  }

  @override
  bool shouldRepaint(ChinaFlagPainter oldDelegate) => false;
}

class JapanFlagPainter extends CustomPainter {
  const JapanFlagPainter();
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = Palette.settingsPanel);
    canvas.drawCircle(
      size.center(Offset.zero),
      size.height * .31,
      Paint()..color = Palette.flagChinaRed,
    );
  }

  @override
  bool shouldRepaint(JapanFlagPainter oldDelegate) => false;
}
