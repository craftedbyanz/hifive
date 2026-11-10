import 'package:flutter/material.dart';

import '../../widgets/common.dart';

/// Element entering (design system motion table).
const welcomeEnter = Duration(milliseconds: 300);

/// Page change, as a panel moves.
const welcomeTurn = Duration(milliseconds: 350);

/// Whether the welcome and onboarding demos play by themselves: off under
/// Reduce Motion and in tests that turn ambient motion off, where every demo
/// shows its finished state instead.
bool welcomeAutoplay(BuildContext context) =>
    AmbientMotion.of(context) && !MediaQuery.disableAnimationsOf(context);

/// Fades and lifts its child in when [active] turns on, after [delay].
class Reveal extends StatefulWidget {
  final bool active;
  final Duration delay;
  final Widget child;
  const Reveal({
    super.key,
    required this.child,
    this.active = true,
    this.delay = Duration.zero,
  });
  @override
  State<Reveal> createState() => _RevealState();
}

class _RevealState extends State<Reveal> {
  bool shown = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _schedule();
  }

  @override
  void didUpdateWidget(Reveal old) {
    super.didUpdateWidget(old);
    if (widget.active != old.active) _schedule();
  }

  void _schedule() {
    if (!widget.active || shown) return;
    if (MediaQuery.disableAnimationsOf(context) ||
        widget.delay == Duration.zero) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => shown = true);
      });
    } else {
      Future<void>.delayed(widget.delay, () {
        if (mounted && widget.active) setState(() => shown = true);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final still = MediaQuery.disableAnimationsOf(context);
    final visible = shown || still;
    return AnimatedOpacity(
      opacity: visible ? 1 : 0,
      duration: still ? Duration.zero : welcomeEnter,
      curve: Curves.easeOutCubic,
      child: AnimatedSlide(
        offset: visible ? Offset.zero : const Offset(0, .08),
        duration: still ? Duration.zero : welcomeEnter,
        curve: Curves.easeOutCubic,
        child: widget.child,
      ),
    );
  }
}

/// [t] mapped onto the part of a timeline from [begin] to [end], eased.
double phase(
  double t,
  double begin,
  double end, [
  Curve curve = Curves.easeOutCubic,
]) => curve.transform(((t - begin) / (end - begin)).clamp(0.0, 1.0));

/// Fades and lifts [child] in by [value] (0 hidden, 1 in place).
Widget appear(double value, Widget child, {double lift = 10}) => Opacity(
  opacity: value.clamp(0.0, 1.0),
  child: Transform.translate(
    offset: Offset(0, (1 - value) * lift),
    child: child,
  ),
);
