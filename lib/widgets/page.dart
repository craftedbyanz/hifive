import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../core/design/design.dart';
import '../l10n/l10n.dart';
import 'buttons.dart';

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
              label: context.t.back,
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
