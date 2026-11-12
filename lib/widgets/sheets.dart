import 'dart:ui';

import 'package:flutter/material.dart';

import '../core/design/design.dart';
import '../l10n/l10n.dart';

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
  String? action,
  String? cancel,
  bool destructive = false,
}) async =>
    await showGeneralDialog<bool>(
      context: context,
      barrierDismissible: false,
      barrierColor: Palette.sheetBarrier,
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (ctx, _, _) => _SystemAlert(
        title,
        text,
        action ?? ctx.t.leave,
        cancel ?? ctx.t.stay,
        destructive,
      ),
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
          tooltip: context.t.close,
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.close_rounded),
        ),
      ],
    ),
  );
}
