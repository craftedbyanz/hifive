import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../core/design/design.dart';
import '../core/state.dart';

/// Sizes measured at the default text size grow with a larger system text
/// size, as the reference's boxes do; at the default they are unchanged.
extension TextGrow on BuildContext {
  double grow(double value) => MediaQuery.textScalerOf(this).scale(value);
}

/// A page presented from below as a full-screen cover, like the Plus screen.
mixin CoverPage on Widget {}

/// Measured from video: a cover opens in about 0.5 s, mostly in the first
/// 0.2 s, and closes in about 0.27 s. The page beneath does not move.
class CoverRoute<T> extends PageRouteBuilder<T> {
  CoverRoute({required Widget page})
    : super(
        fullscreenDialog: true,
        transitionDuration: const Duration(milliseconds: 500),
        reverseTransitionDuration: const Duration(milliseconds: 270),
        pageBuilder: (_, _, _) => page,
        transitionsBuilder: (_, animation, _, child) => SlideTransition(
          position: Tween(begin: const Offset(0, 1), end: Offset.zero).animate(
            CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutQuint,
              reverseCurve: Curves.easeOut,
            ),
          ),
          child: child,
        ),
      );
}

Future<T?> go<T>(BuildContext context, Widget page) =>
    Navigator.of(context).push<T>(
      page is CoverPage
          ? CoverRoute<T>(page: page)
          : CupertinoPageRoute<T>(builder: (_) => page),
    );
void toast(BuildContext context, String text) =>
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

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

class Header extends StatelessWidget {
  final String title;
  final Widget? trailing;
  final VoidCallback? onBack;
  const Header({super.key, this.title = '', this.trailing, this.onBack});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
    child: SizedBox(
      height: 46,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 52),
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: D.text(16, weight: FontWeight.w700, spacing: -.3),
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: RoundButton(
              icon: CupertinoIcons.back,
              label: 'Quay lại',
              onTap: onBack ?? () => Navigator.maybePop(context),
            ),
          ),
          if (trailing != null)
            Align(alignment: Alignment.centerRight, child: trailing!),
        ],
      ),
    ),
  );
}

class AppPage extends StatelessWidget {
  final bool resizeToAvoidBottomInset;
  final String title;
  final Widget child;
  final Widget? trailing;
  final Color background;
  final VoidCallback? onBack;
  const AppPage({
    super.key,
    this.resizeToAvoidBottomInset = true,
    required this.title,
    required this.child,
    this.trailing,
    this.background = D.background,
    this.onBack,
  });
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: background,
    resizeToAvoidBottomInset: resizeToAvoidBottomInset,
    body: SafeArea(
      child: Column(
        children: [
          Header(title: title, trailing: trailing, onBack: onBack),
          Expanded(child: child),
        ],
      ),
    ),
  );
}

class ActionButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final Color color, foreground;
  final IconData? icon;
  final bool outlined;
  const ActionButton(
    this.label, {
    super.key,
    required this.onTap,
    this.color = D.ink,
    this.foreground = Colors.white,
    this.icon,
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
              if (icon != null) ...[
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
            ],
          ),
        ),
      ),
    ),
  );
}

class Surface extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final Color color;
  final double radius;
  final VoidCallback? onTap;
  final bool shadow;
  const Surface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.color = Colors.white,
    this.radius = 28,
    this.onTap,
    this.shadow = false,
  });
  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: D.line.withValues(alpha: .7)),
      boxShadow: shadow ? D.shadow : null,
    ),
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(radius),
        onTap: onTap,
        child: Padding(padding: padding, child: child),
      ),
    ),
  );
}

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

class EmptyView extends StatelessWidget {
  final String title, subtitle;
  final IconData icon;
  final Widget? action;
  const EmptyView({
    super.key,
    required this.title,
    this.subtitle = '',
    this.icon = Icons.inbox_rounded,
    this.action,
  });
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 46, color: D.muted),
          const SizedBox(height: 20),
          Text(
            title,
            textAlign: TextAlign.center,
            style: D.text(17, weight: FontWeight.w700),
          ),
          if (subtitle.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: D.text(13, color: D.secondary),
            ),
          ],
          if (action != null) ...[const SizedBox(height: 22), action!],
        ],
      ),
    ),
  );
}

Future<T?> sheet<T>(BuildContext context, Widget child, {bool scroll = true}) =>
    showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      builder: (ctx) => AnimatedPadding(
        duration: const Duration(milliseconds: 180),
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(ctx).height * .87,
          ),
          child: scroll
              ? SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
                  child: child,
                )
              : child,
        ),
      ),
    );

/// The system alert as iOS 26 draws it (survey 151): a frosted 321 pt card,
/// title and message on the left in SF Pro, and two capsule buttons side by
/// side. [destructive] colours the action red.
Future<bool> confirm(
  BuildContext context,
  String title,
  String text, {
  String action = 'Thoát',
  String cancel = 'Ở lại',
  bool destructive = false,
}) async =>
    await showGeneralDialog<bool>(
      context: context,
      barrierDismissible: false,
      barrierColor: Palette.sheetBarrier,
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (ctx, _, _) =>
          _SystemAlert(title, text, action, cancel, destructive),
      transitionBuilder: (ctx, animation, _, child) => FadeTransition(
        opacity: animation,
        child: ScaleTransition(
          scale: Tween<double>(begin: 1.08, end: 1).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
          ),
          child: child,
        ),
      ),
    ) ??
    false;

class _SystemAlert extends StatelessWidget {
  final String title, text, action, cancel;
  final bool destructive;
  const _SystemAlert(
    this.title,
    this.text,
    this.action,
    this.cancel,
    this.destructive,
  );
  @override
  Widget build(BuildContext context) {
    TextStyle sf(double size, FontWeight weight, Color color) => TextStyle(
      fontFamily: 'CupertinoSystemText',
      fontSize: size,
      fontWeight: weight,
      color: color,
      letterSpacing: size >= 17 ? -.43 : -.23,
      decoration: TextDecoration.none,
    );
    Widget button(String label, Color color, bool value) => Expanded(
      child: Semantics(
        button: true,
        child: GestureDetector(
          onTap: () => Navigator.pop(context, value),
          child: Container(
            height: 49,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: .07),
              borderRadius: BorderRadius.circular(24.5),
            ),
            child: Text(label, style: sf(17, FontWeight.w500, color)),
          ),
        ),
      ),
    );
    // It sits 12 pt below the centre on the 852 pt screen.
    return Center(
      child: Container(
        width: 321,
        margin: const EdgeInsets.only(top: 24),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(34),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              color: Colors.white.withValues(alpha: .66),
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Text(
                      title,
                      style: sf(17, FontWeight.w600, Colors.black),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Text(
                      text,
                      style: sf(
                        15,
                        FontWeight.w400,
                        Palette.alertMessage,
                      ).copyWith(height: 1.45),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      button(cancel, Colors.black, false),
                      const SizedBox(width: 7),
                      button(
                        action,
                        destructive ? Palette.alertRed : Palette.alertBlue,
                        true,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class SheetTitle extends StatelessWidget {
  final String title;
  const SheetTitle(this.title, {super.key});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 24),
    child: Row(
      children: [
        Expanded(
          child: Text(title, style: D.text(19, weight: FontWeight.w700)),
        ),
        IconButton(
          tooltip: 'Đóng',
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.close_rounded),
        ),
      ],
    ),
  );
}

/// The app's logo as the reference draws it on white: long overlapping petals,
/// deepening toward the middle, around a white four-point star.
class AppLogo extends StatelessWidget {
  final double size;
  const AppLogo({super.key, required this.size});
  @override
  Widget build(BuildContext context) =>
      CustomPaint(size: Size.square(size), painter: const _AppLogoPainter());
}

class _AppLogoPainter extends CustomPainter {
  const _AppLogoPainter();
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final petal = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Palette.logoTop, Palette.logoMiddle, Palette.logoBottom],
      ).createShader(rect)
      ..color = Colors.white.withValues(alpha: .62);
    final w = size.width;
    final c = size.center(Offset.zero);
    for (var i = 0; i < 8; i++) {
      final angle = i * math.pi / 4;
      final along = Offset(math.sin(angle), -math.cos(angle)) * (w * .25);
      canvas.save();
      canvas.translate(c.dx + along.dx, c.dy + along.dy);
      canvas.rotate(angle);
      canvas.drawOval(
        Rect.fromCenter(center: Offset.zero, width: w * .34, height: w * .5),
        petal,
      );
      canvas.restore();
    }
    final r = w * .21;
    const k = .16;
    canvas.drawPath(
      Path()
        ..moveTo(c.dx, c.dy - r)
        ..quadraticBezierTo(c.dx + r * k, c.dy - r * k, c.dx + r, c.dy)
        ..quadraticBezierTo(c.dx + r * k, c.dy + r * k, c.dx, c.dy + r)
        ..quadraticBezierTo(c.dx - r * k, c.dy + r * k, c.dx - r, c.dy)
        ..quadraticBezierTo(c.dx - r * k, c.dy - r * k, c.dx, c.dy - r)
        ..close(),
      Paint()..color = Colors.white,
    );
  }

  @override
  bool shouldRepaint(_AppLogoPainter oldDelegate) => false;
}

class Flower extends StatelessWidget {
  final double size;

  /// Deeper petals for use on a white background.
  final bool strong;
  const Flower({super.key, this.size = 48, this.strong = false});
  @override
  Widget build(BuildContext context) => CustomPaint(
    size: Size.square(size),
    painter: _FlowerPainter(strong: strong),
  );
}

class _FlowerPainter extends CustomPainter {
  final bool strong;
  const _FlowerPainter({this.strong = false});
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, c = size.center(Offset.zero);
    canvas.save();
    canvas.translate(c.dx, c.dy);
    final area = Rect.fromCircle(center: Offset.zero, radius: w / 2);
    // One gradient across the whole flower, so petals overlap into a deep center.
    final petals = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Palette.flowerTop, Palette.flowerBottom],
      ).createShader(area);
    final petal = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(0, -w * .19),
            width: w * .36,
            height: w * .62,
          ),
          Radius.circular(w * .18),
        ),
      );
    canvas.saveLayer(area, Paint());
    for (var i = 0; i < 8; i++) {
      canvas.drawPath(
        petal.transform(Matrix4.rotationZ(i * math.pi / 4).storage),
        petals..color = Colors.white.withValues(alpha: strong ? .85 : .6),
      );
    }
    canvas.restore();
    final r = w * .2, q = r * .1;
    final star = Path()
      ..moveTo(0, -r)
      ..quadraticBezierTo(q, -q, r, 0)
      ..quadraticBezierTo(q, q, 0, r)
      ..quadraticBezierTo(-q, q, -r, 0)
      ..quadraticBezierTo(-q, -q, 0, -r);
    canvas.drawPath(
      star,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.white, Palette.flowerStarEnd],
        ).createShader(Rect.fromCircle(center: Offset.zero, radius: r)),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class Glass extends StatelessWidget {
  final Widget child;
  final double opacity;
  final Color? color;
  final BorderSide? border;
  final VoidCallback? onTap;
  final BorderRadius radius;
  final Color? pressColor;
  const Glass({
    super.key,
    this.opacity = .53,
    this.color,
    this.border,
    required this.child,
    this.onTap,
    this.radius = const BorderRadius.all(Radius.circular(50)),
    this.pressColor,
  });
  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: radius,
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
      child: Material(
        color: color ?? Colors.white.withValues(alpha: opacity),
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: border ?? BorderSide(color: Colors.white.withValues(alpha: .7)),
        ),
        child: InkWell(
          onTap: onTap,
          highlightColor: pressColor,
          splashFactory: pressColor == null ? null : NoSplash.splashFactory,
          child: child,
        ),
      ),
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

String timeLabel(int seconds) =>
    '${(seconds ~/ 60).toString().padLeft(2, '0')}:${(seconds % 60).toString().padLeft(2, '0')}';
void playWord(BuildContext context, String word) =>
    AppScope.read(context).feedback.speak(word);
