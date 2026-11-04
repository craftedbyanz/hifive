import 'package:flutter/material.dart';

import '../../core/design/design.dart';
import '../../widgets/common.dart';

class ArticleScreen extends StatelessWidget {
  final String title, body;
  final IconData icon;
  const ArticleScreen({
    super.key,
    required this.title,
    required this.body,
    this.icon = Icons.shield_outlined,
  });
  @override
  Widget build(BuildContext context) => AppPage(
    title: title,
    background: Colors.white,
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 35),
          Icon(icon, size: 52, color: D.blue),
          const SizedBox(height: 30),
          Text(title, style: D.text(31, weight: FontWeight.w800)),
          const SizedBox(height: 24),
          Text(body, style: D.text(15, height: 1.8, color: D.secondary)),
        ],
      ),
    ),
  );
}

/// Original vector drawings; reference screenshots are never bundled as assets.
class HelpIllustration extends CustomPainter {
  final int index;
  const HelpIllustration(this.index);
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 345, size.height / 294);
    final color = [
      D.purple,
      Palette.magenta,
      D.green,
      D.blue,
      D.orange,
      Palette.helpTeal,
      D.orange,
    ][index];
    final bg = Color.lerp(D.background, color, .035)!;
    void box(
      double x,
      double y,
      double w,
      double h,
      Color c, [
      double r = 12,
    ]) => canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(x, y, w, h), Radius.circular(r)),
      Paint()..color = c,
    );
    void line(
      double x,
      double y,
      double w, {
      double opacity = .3,
      double h = 5,
    }) => box(x, y, w, h, color.withValues(alpha: opacity), 3);
    void dot(double x, double y, double r, Color c) =>
        canvas.drawCircle(Offset(x, y), r, Paint()..color = c);
    void text(String t, double x, double y, double font, Color c) {
      final p = TextPainter(
        text: TextSpan(
          text: t,
          style: D.text(font, color: c, weight: FontWeight.w700),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      p.paint(canvas, Offset(x, y));
    }

    box(0, 0, 345, 294, bg, 24);
    if (index == 0) {
      line(38, 92, 72, opacity: .1);
      dot(290, 94, 3, color.withValues(alpha: .12));
      dot(303, 94, 3, color.withValues(alpha: .12));
      for (var i = 0; i < 3; i++) {
        final x = 75.0 + i * 97;
        if (i == 1) box(x - 43, 112, 86, 90, Colors.white, 16);
        dot(
          x,
          150,
          i == 1 ? 22 : 18,
          color.withValues(alpha: i == 1 ? 1 : .12),
        );
        final icon = [
          Icons.menu_book_rounded,
          Icons.bolt_rounded,
          Icons.chat_bubble_rounded,
        ][i];
        final p = TextPainter(
          text: TextSpan(
            text: String.fromCharCode(icon.codePoint),
            style: TextStyle(
              fontFamily: icon.fontFamily,
              fontSize: 25,
              color: i == 1 ? Colors.white : color.withValues(alpha: .6),
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        p.paint(canvas, Offset(x - 12, 137));
        line(x - 10, 182, 20, opacity: i == 1 ? 1 : .3, h: 4);
      }
    } else if (index == 1 || index == 2) {
      if (index == 2) box(17, 15, 311, 264, Colors.white, 16);
      box(
        73,
        index == 1 ? 33 : 49,
        166,
        100,
        index == 1 ? Colors.white : color.withValues(alpha: .05),
        14,
      );
      for (var j = 0; j < 3; j++) {
        line(84, 44.0 + j * 13, 144 - j * 27.0, opacity: .75 - j * .2);
      }
      if (index == 1) {
        box(84, 82, 144, 40, color.withValues(alpha: .04), 8);
        box(90, 89, 3, 26, color, 2);
        for (var j = 0; j < 3; j++) {
          line(100, 93.0 + j * 8, 100 - j * 16.0, opacity: .2);
        }
        box(73, 147, 40, 18, Colors.white, 10);
        text('•••', 83, 146, 12, color.withValues(alpha: .4));
      } else {
        box(142, 109, 138, 69, color, 13);
        for (var j = 0; j < 3; j++) {
          box(
            153,
            120.0 + j * 13,
            116 - j * 15.0,
            5,
            Colors.white.withValues(alpha: .5),
            3,
          );
        }
      }
      box(35, 218, 275, 43, Colors.white, 24);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(35, 218, 275, 43),
          const Radius.circular(24),
        ),
        Paint()
          ..color = color.withValues(alpha: .15)
          ..style = PaintingStyle.stroke,
      );
      line(74, 237, 108, opacity: .12);
      dot(288, 240, 12, color);
      text('↑', 281, 228, 18, Colors.white);
    } else if (index == 3 || index == 5) {
      final small = index == 5;
      final w = small ? 81.0 : 144.0, h = small ? 108.0 : 171.0;
      for (final angle in [-.15, .15, 0.0]) {
        canvas.save();
        canvas.translate(172, 150);
        canvas.rotate(angle);
        box(-w / 2, -h / 2, w, h, Colors.white, 15);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(-w / 2, -h / 2, w, h),
            const Radius.circular(15),
          ),
          Paint()
            ..color = color.withValues(alpha: .15)
            ..style = PaintingStyle.stroke,
        );
        if (!small) {
          box(-w / 2, -h / 2, w, 78, color.withValues(alpha: .15), 15);
          text('✦', -14, -72, 33, color.withValues(alpha: .6));
        }
        line(-w / 2 + 14, small ? -42 : 10, w * .5, opacity: .65);
        line(-w / 2 + 14, small ? 24 : 30, w * .38, opacity: .3);
        line(-w / 2 + 14, small ? 36 : 60, w * .7, opacity: .15);
        canvas.restore();
      }
    } else if (index == 4) {
      box(17, 70, 311, 153, Colors.white, 18);
      line(35, 88, 54, opacity: .6);
      line(35, 97, 36, opacity: .25, h: 3);
      text('Less ▪▪▪ More', 220, 89, 7, D.muted);
      for (var row = 0; row < 7; row++) {
        for (var col = 0; col < 14; col++) {
          box(
            46 + col * 12.0,
            120 + row * 12.0,
            9,
            9,
            color.withValues(
              alpha: [.05, .15, .35, .8][(row * 7 + col * 3) % 4],
            ),
            2,
          );
        }
      }
    } else {
      for (var row = 0; row < 2; row++) {
        final letters = (row == 0 ? 'TCA' : 'CAT').split('');
        for (var col = 0; col < 3; col++) {
          box(
            120 + col * 36.0,
            94 + row * 76.0,
            32,
            33,
            color.withValues(alpha: .1),
            8,
          );
          text(letters[col], 130 + col * 36.0, 98 + row * 76.0, 19, color);
        }
      }
      text('↘ ↓', 161, 139, 16, color.withValues(alpha: .5));
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(HelpIllustration oldDelegate) =>
      oldDelegate.index != index;
}
