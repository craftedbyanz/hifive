import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

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
