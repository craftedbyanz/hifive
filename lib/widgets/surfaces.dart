import 'dart:ui';

import 'package:flutter/material.dart';

import '../core/design/design.dart';

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
