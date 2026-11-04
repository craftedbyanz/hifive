import 'package:flutter/widgets.dart';

/// The reference's press feedback: the whole control fades while held, instead
/// of showing a ripple. Measured from video: it falls to about 20% over roughly
/// 0.35 s and recovers quickly on release.
class PressFade extends StatefulWidget {
  static const pressedOpacity = .2;
  final VoidCallback? onTap;
  final Widget child;
  const PressFade({super.key, required this.onTap, required this.child});
  @override
  State<PressFade> createState() => _PressFadeState();
}

class _PressFadeState extends State<PressFade> {
  bool _pressed = false;
  void _set(bool value) {
    if (value != _pressed) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) => MergeSemantics(
    child: Semantics(
      button: widget.onTap != null,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        onTapDown: widget.onTap == null ? null : (_) => _set(true),
        onTapUp: widget.onTap == null ? null : (_) => _set(false),
        onTapCancel: widget.onTap == null ? null : () => _set(false),
        child: AnimatedOpacity(
          opacity: _pressed ? PressFade.pressedOpacity : 1,
          duration: Duration(milliseconds: _pressed ? 350 : 150),
          curve: Curves.easeOut,
          child: widget.child,
        ),
      ),
    ),
  );
}
