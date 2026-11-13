import 'package:flutter/material.dart';

import '../../core/design/design.dart';
import '../../l10n/l10n.dart';
import '../../widgets/common.dart';
import 'article_screen.dart';
import 'help_content.dart';

class HelpScreen extends StatelessWidget {
  final int index;
  const HelpScreen({super.key, required this.index});
  @override
  Widget build(BuildContext context) => AppPage(
    title: helpTitle(context.t, index),
    child: SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 345 / 294,
            // The first article is hifive's own story; the rest keep their
            // illustrations.
            child: index == 0
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: const LogoStoryArt(),
                  )
                : CustomPaint(painter: HelpIllustration(index - 1)),
          ),
          const SizedBox(height: 24),
          Text(
            helpTitle(context.t, index),
            style: D.text(
              25,
              weight: FontWeight.w800,
              height: 1.3,
              spacing: -.8,
            ),
          ),
          const SizedBox(height: 16),
          ArticleBody(helpBody(context.t, index)),
        ],
      ),
    ),
  );
}

/// Help text laid out by its shape: a short line on its own is a heading, a
/// line ending in ":" leads into what follows, "•" lines are a list and
/// "1." lines a numbered list. In a list item, a short label before ":" is
/// bold.
class ArticleBody extends StatelessWidget {
  final String text;
  const ArticleBody(this.text, {super.key});

  static final _numbered = RegExp(r'^(\d+)\.\s+');

  @override
  Widget build(BuildContext context) {
    final blocks = text.split(RegExp(r'\n\s*\n'));
    final children = <Widget>[];
    for (final raw in blocks) {
      final block = raw.trim();
      if (block.isEmpty) continue;
      final lines = block.split('\n');
      final isList = lines.every(
        (l) => l.trimLeft().startsWith('•') || _numbered.hasMatch(l.trim()),
      );
      if (children.isNotEmpty) children.add(const SizedBox(height: 14));
      if (isList) {
        for (final l in lines) {
          final line = l.trim();
          final number = _numbered.firstMatch(line);
          children.add(
            _Item(
              marker: number?.group(1),
              text: number != null
                  ? line.substring(number.end)
                  : line.substring(1).trim(),
            ),
          );
        }
      } else if (lines.length == 1 &&
          block.length <= 40 &&
          !RegExp(r'[.:!?。：]$').hasMatch(block)) {
        children
          ..add(const SizedBox(height: 6))
          ..add(
            Text(
              block,
              style: D.text(18, weight: FontWeight.w800, spacing: -.3),
            ),
          );
      } else {
        children.add(
          Text(
            block,
            style: D.text(
              15.5,
              weight: block.endsWith(':') || block.endsWith('：')
                  ? FontWeight.w600
                  : FontWeight.w500,
              color: D.ink,
              height: 1.55,
            ),
          ),
        );
      }
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }
}

class _Item extends StatelessWidget {
  /// The number of a numbered item; null draws a dot.
  final String? marker;
  final String text;
  const _Item({required this.marker, required this.text});

  @override
  Widget build(BuildContext context) {
    final colon = text.indexOf(RegExp('[:：]'));
    final label = colon > 0 && colon <= 40 ? text.substring(0, colon + 1) : '';
    final rest = text.substring(label.length).trimLeft();
    final style = D.text(
      15,
      weight: FontWeight.w500,
      color: D.ink,
      height: 1.5,
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: D.line),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 22,
              height: 22,
              margin: const EdgeInsets.only(top: 1, right: 12),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Palette.menuFocus.withValues(alpha: .12),
                shape: BoxShape.circle,
              ),
              child: marker == null
                  ? Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: Palette.menuFocus,
                        shape: BoxShape.circle,
                      ),
                    )
                  : Text(
                      marker!,
                      style: D.text(
                        12,
                        weight: FontWeight.w800,
                        color: Palette.menuFocus,
                      ),
                    ),
            ),
            Expanded(
              child: Text.rich(
                TextSpan(
                  children: [
                    if (label.isNotEmpty)
                      TextSpan(
                        text: '$label ',
                        style: style.copyWith(fontWeight: FontWeight.w700),
                      ),
                    TextSpan(text: rest),
                  ],
                ),
                style: style,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
