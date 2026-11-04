import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../core/design/design.dart';
import 'app_scroll.dart';
import 'press.dart';

/// A scrolling page under a pinned, blurred header, measured on a 393 × 852
/// iPhone. The hairline appears once the content has moved. An optional footer
/// stays pinned to the bottom edge on the same glass.
class HeaderScrollPage extends StatefulWidget {
  static const headerHeight = 112.0;
  final String title;
  final String? subtitle;
  final double titleSize;
  final Key? scrollKey;
  final EdgeInsets padding;
  final Widget child;
  final Color background;
  final IconData leadingIcon;
  final double leadingIconSize, leadingWidth;
  final String leadingLabel;
  final Widget? trailing;
  final Widget? footer;
  const HeaderScrollPage({
    super.key,
    required this.title,
    this.subtitle,
    this.titleSize = 18,
    this.scrollKey,
    required this.padding,
    required this.child,
    this.background = Colors.white,
    this.leadingIcon = CupertinoIcons.back,
    this.leadingIconSize = 28,
    this.leadingWidth = 44,
    this.leadingLabel = 'Quay lại',
    this.trailing,
    this.footer,
  });
  @override
  State<HeaderScrollPage> createState() => _HeaderScrollPageState();
}

class _HeaderScrollPageState extends State<HeaderScrollPage> {
  final _scroll = ScrollController();
  bool _scrolled = false;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      final scrolled = _scroll.offset > 1;
      if (scrolled != _scrolled) setState(() => _scrolled = scrolled);
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: widget.background,
    body: Stack(
      children: [
        SingleChildScrollView(
          key: widget.scrollKey,
          controller: _scroll,
          physics: const HomeScrollPhysics(),
          padding: widget.padding,
          child: widget.child,
        ),
        Positioned(
          left: 0,
          right: 0,
          top: 0,
          height: HeaderScrollPage.headerHeight,
          child: _BlurHeader(
            title: widget.title,
            subtitle: widget.subtitle,
            titleSize: widget.titleSize,
            scrolled: _scrolled,
            background: widget.background,
            leadingIcon: widget.leadingIcon,
            leadingIconSize: widget.leadingIconSize,
            leadingWidth: widget.leadingWidth,
            leadingLabel: widget.leadingLabel,
            trailing: widget.trailing,
          ),
        ),
        if (widget.footer != null)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: widget.background.withValues(alpha: .78),
                    border: const Border(
                      top: BorderSide(color: Palette.settingsPanel),
                    ),
                  ),
                  child: widget.footer,
                ),
              ),
            ),
          ),
      ],
    ),
  );
}

/// The round glass button of the pinned header.
class HeaderRoundButton extends StatelessWidget {
  final IconData icon;
  final double iconSize;
  final String label;
  final VoidCallback onTap;
  final double width;
  const HeaderRoundButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.iconSize = 28,
    this.width = 44,
  });
  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: label,
    child: Tooltip(
      message: label,
      // A long press must still act as a tap, as on the reference.
      triggerMode: TooltipTriggerMode.manual,
      child: PressFade(
        onTap: onTap,
        child: Container(
          width: width,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: Palette.insightBackEdge, width: .5),
            boxShadow: [
              BoxShadow(
                color: D.ink.withValues(alpha: .06),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Icon(icon, size: iconSize, color: D.ink),
        ),
      ),
    ),
  );
}

class _BlurHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final double titleSize;
  final bool scrolled;
  final Color background;
  final IconData leadingIcon;
  final double leadingIconSize, leadingWidth;
  final String leadingLabel;
  final Widget? trailing;
  const _BlurHeader({
    required this.title,
    required this.subtitle,
    required this.titleSize,
    required this.scrolled,
    required this.background,
    required this.leadingIcon,
    required this.leadingIconSize,
    required this.leadingWidth,
    required this.leadingLabel,
    required this.trailing,
  });
  @override
  Widget build(BuildContext context) => ClipRect(
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: background.withValues(alpha: .78),
          border: Border(
            bottom: BorderSide(
              color: scrolled ? Palette.insightDot : Colors.transparent,
            ),
          ),
        ),
        child: Padding(
          padding: EdgeInsets.only(top: MediaQuery.paddingOf(context).top),
          child: Stack(
            children: [
              Positioned(
                left: 0,
                right: 0,
                top: subtitle == null ? 10 : 2,
                child: Column(
                  children: [
                    Text(
                      title,
                      style: D.text(
                        titleSize,
                        weight: FontWeight.w700,
                        height: 24 / titleSize,
                      ),
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle!,
                        style: D.text(
                          12.8,
                          color: D.secondary,
                          height: 15 / 12.8,
                        ),
                      ),
                  ],
                ),
              ),
              Positioned(
                left: 16,
                top: 0,
                child: HeaderRoundButton(
                  icon: leadingIcon,
                  iconSize: leadingIconSize,
                  width: leadingWidth,
                  label: leadingLabel,
                  onTap: () => Navigator.maybePop(context),
                ),
              ),
              if (trailing != null)
                Positioned(right: 16, top: 0, child: trailing!),
            ],
          ),
        ),
      ),
    ),
  );
}
