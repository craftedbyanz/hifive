import 'package:flutter/material.dart';

import '../../core/design/design.dart';
import '../../widgets/common.dart';
import 'article_screen.dart';
import 'help_content.dart';

class HelpScreen extends StatelessWidget {
  final int index;
  const HelpScreen({super.key, required this.index});
  @override
  Widget build(BuildContext context) => AppPage(
    title: helpTitles[index],
    child: SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 345 / 294,
            child: CustomPaint(painter: HelpIllustration(index)),
          ),
          const SizedBox(height: 24),
          Text(
            helpTitles[index],
            style: D.text(
              25,
              weight: FontWeight.w800,
              height: 1.3,
              spacing: -.8,
            ),
          ),
          const SizedBox(height: 12),
          // Darker grey and 23.5 pt lines (survey 93).
          Text(
            helpBodies[index],
            style: D.text(15, color: Palette.helpBody, height: 1.57),
          ),
        ],
      ),
    ),
  );
}
