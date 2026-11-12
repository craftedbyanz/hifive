import 'package:flutter/material.dart';

import '../../core/design/design.dart';
import '../../l10n/l10n.dart';
import '../../widgets/common.dart';

/// "Hướng dẫn Cài đặt", opened from ⓘ in the conversation settings popover
/// (survey 87). Only the top of the reference sheet was captured; the tone
/// descriptions below "Trang trọng" are the clone's own wording.
class ConversationGuide extends StatelessWidget {
  const ConversationGuide({super.key});
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SheetTitle(context.t.settingsGuideTitle),
      Text(
        context.t.settingsGuideBody,
        style: D.text(15, color: D.secondary, height: 1.5),
      ),
      const SizedBox(height: 26),
      _Heading(Icons.call_split_rounded, context.t.learningModeCaps),
      _Item(
        Icons.forum_outlined,
        D.purple,
        context.t.freeChat,
        context.t.freeChatBody,
      ),
      _Item(
        Icons.article_outlined,
        D.blue,
        context.t.scriptMode,
        context.t.scriptModeBody,
      ),
      const SizedBox(height: 18),
      _Heading(
        Icons.sentiment_satisfied_rounded,
        context.t.tonePersonalityCaps,
      ),
      _Item(
        Icons.work_outline_rounded,
        D.blue,
        context.t.toneFormal,
        context.t.toneFormalBody,
      ),
      _Item(
        Icons.local_cafe_outlined,
        D.orange,
        context.t.toneCasual,
        context.t.toneCasualBody,
      ),
      _Item(
        Icons.favorite_border_rounded,
        D.green,
        context.t.toneFriendly,
        context.t.toneFriendlyBody,
      ),
    ],
  );
}

class _Heading extends StatelessWidget {
  final IconData icon;
  final String text;
  const _Heading(this.icon, this.text);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Row(
      children: [
        Icon(icon, size: 20),
        const SizedBox(width: 10),
        Text(text, style: D.text(14, weight: FontWeight.w700, spacing: 1)),
      ],
    ),
  );
}

class _Item extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title, body;
  const _Item(this.icon, this.color, this.title, this.body);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 18),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: color.withValues(alpha: .12),
          child: Icon(icon, color: color),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: D.text(17, weight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(body, style: D.text(14, color: D.secondary, height: 1.5)),
            ],
          ),
        ),
      ],
    ),
  );
}
