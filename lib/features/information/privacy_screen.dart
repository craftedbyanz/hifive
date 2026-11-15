import 'package:flutter/material.dart';

import '../../core/design/design.dart';
import '../../l10n/l10n.dart';
import '../../widgets/common.dart';

/// The reference's policy text, kept as its visible copy. Its statements describe
/// the original service: this clone stores everything on the device.
class PrivacyScreen extends StatelessWidget {
  /// From the Plus screen the policy is a sheet with "Done", not a pushed page.
  final bool asSheet;
  const PrivacyScreen({super.key, this.asSheet = false});

  static Future<void> showSheet(BuildContext context) =>
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        showDragHandle: false,
        backgroundColor: Colors.transparent,
        barrierColor: Palette.sheetBarrier,
        elevation: 0,
        builder: (ctx) => SizedBox(
          height: MediaQuery.sizeOf(ctx).height - 58,
          child: const ClipRSuperellipse(
            borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
            child: PrivacyScreen(asSheet: true),
          ),
        ),
      );

  static List<(String, String)> _sections(AppLocalizations t) => [
    (t.privacyAiCoach, t.privacyAiCoachBody),
    (t.privacyCollectTitle, t.privacyCollectBody),
    (t.privacyUseTitle, t.privacyUseBody),
    (t.privacyKeepTitle, t.privacyKeepBody),
    (t.privacySecurityTitle, t.privacySecurityBody),
    (t.privacyChildrenTitle, t.privacyChildrenBody),
  ];

  @override
  Widget build(BuildContext context) {
    final body = D.text(15.2, color: Palette.policyBody, height: 22.8 / 15.2);
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 6),
          child: SizedBox(
            width: 39,
            height: 48,
            child: FittedBox(
              child: CustomPaint(
                size: Size(19, 21),
                painter: ShieldPainter(color: Palette.policyHighlight),
              ),
            ),
          ),
        ),
        const SizedBox(height: 27),
        Text(
          context.t.privacyHeadline1,
          style: D.text(31, weight: FontWeight.w800, height: 40 / 31),
        ),
        const SizedBox(height: 3),
        Padding(
          padding: const EdgeInsets.only(right: 44),
          child: Text(
            context.t.privacyHeadline2,
            style: D.text(
              31,
              weight: FontWeight.w800,
              color: Palette.policyHighlight,
              height: 40 / 31,
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          context.t.privacyUpdated,
          style: D.text(13.5, color: Palette.settingsMuted, height: 17 / 13.5),
        ),
        const SizedBox(height: 31),
        Text(context.t.privacyIntro, style: body),
        for (final (title, text) in _sections(context.t)) ...[
          const SizedBox(height: 24),
          Text(
            title,
            style: D.text(17, weight: FontWeight.w700, height: 22 / 17),
          ),
          const SizedBox(height: 11),
          Text(text, style: body),
        ],
      ],
    );
    if (!asSheet) {
      return HeaderScrollPage(
        title: context.t.profilePrivacy,
        titleSize: 16.5,
        padding: const EdgeInsets.fromLTRB(24, 161, 24, 121),
        child: content,
      );
    }
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 119, 24, 121),
            child: content,
          ),
          Positioned(
            left: 16,
            top: 27,
            child: Text(
              context.t.profilePrivacy,
              style: D.text(16.5, weight: FontWeight.w700, height: 24 / 16.5),
            ),
          ),
          Positioned(
            right: 16,
            top: 17,
            child: PressFade(
              key: const ValueKey('privacy-done'),
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 65,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: Palette.sheetEdge),
                ),
                child: Text(
                  context.t.done,
                  style: D.text(15, weight: FontWeight.w600, height: 1),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
