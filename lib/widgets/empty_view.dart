import 'package:flutter/material.dart';

import '../core/design/design.dart';

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
