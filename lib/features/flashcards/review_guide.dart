import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../core/design/design.dart';
import '../../l10n/l10n.dart';
import '../../widgets/common.dart';

/// The swipe guide over a dark, heavily blurred copy of the session.
Future<void> showReviewGuide(BuildContext context) => showGeneralDialog<void>(
  context: context,
  barrierDismissible: false,
  barrierColor: Colors.transparent,
  transitionDuration: const Duration(milliseconds: 260),
  pageBuilder: (context, _, _) => const _Guide(),
  transitionBuilder: (context, animation, _, child) =>
      FadeTransition(opacity: animation, child: child),
);

class _Guide extends StatelessWidget {
  const _Guide();
  static List<(IconData, String, String)> _rows(AppLocalizations t) => [
    (CupertinoIcons.arrow_left, t.guideForgot, t.guideForgotBody),
    (CupertinoIcons.arrow_down, t.guideHard, t.guideHardBody),
    (CupertinoIcons.arrow_up, t.guideKnown, t.guideKnownBody),
    (CupertinoIcons.arrow_right, t.guideEasy, t.guideEasyBody),
  ];

  @override
  Widget build(BuildContext context) => Material(
    type: MaterialType.transparency,
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
      child: ColoredBox(
        color: Palette.guideBarrier,
        child: Stack(
          children: [
            Positioned(
              left: 0,
              right: 0,
              top: 160,
              child: Column(
                children: [
                  Text(
                    context.t.smartLearning,
                    style: D.text(
                      20.5,
                      weight: FontWeight.w700,
                      color: Colors.white,
                      height: 27 / 20.5,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 70),
                    child: Text(
                      context.t.swipeToRate,
                      textAlign: TextAlign.center,
                      style: D.text(
                        13.5,
                        color: Colors.white.withValues(alpha: .72),
                        height: 17 / 13.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 39),
                  for (final (icon, title, text) in _rows(context.t))
                    Padding(
                      padding: const EdgeInsets.only(
                        left: 38,
                        right: 70,
                        bottom: 28,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.white.withValues(alpha: .5),
                                  blurRadius: 12,
                                ),
                              ],
                            ),
                            child: Icon(
                              icon,
                              size: 20,
                              color: Palette.settingsMuted,
                            ),
                          ),
                          const SizedBox(width: 26),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  style: D.text(
                                    17,
                                    weight: FontWeight.w700,
                                    color: Colors.white,
                                    height: 23 / 17,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  text,
                                  style: D.text(
                                    13.5,
                                    color: Colors.white.withValues(alpha: .72),
                                    height: 17 / 13.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              top: 717,
              child: Center(
                child: PressFade(
                  key: const ValueKey('review-guide-close'),
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 211,
                    height: 51,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .22),
                      borderRadius: BorderRadius.circular(25.5),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: .4),
                      ),
                    ),
                    child: Text(
                      context.t.gotItStart,
                      style: D.text(
                        14.5,
                        weight: FontWeight.w700,
                        color: Colors.white,
                        height: 1,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
