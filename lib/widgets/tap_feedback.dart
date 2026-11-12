import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import '../l10n/l10n.dart';

/// Gives a light haptic for every tap on something tappable anywhere under
/// it: buttons, cards, rows and chips, whatever widget draws them. Going back
/// stays silent, as do text fields and drags.
///
/// It watches the pointer at the root instead of each control: on a short tap
/// it hit-tests the spot and knocks when a tap handler is there.
class TapFeedback extends StatefulWidget {
  /// Semantics labels of controls that go back, in every app language.
  /// They stay silent.
  static final backLabels = {
    for (final locale in supportedAppLocales) ...[
      lookupAppLocalizations(locale).back,
      lookupAppLocalizations(locale).exitGame,
    ],
  };

  /// Farther than this, or longer, and the touch was a drag or a hold.
  static const _slop = 18.0;
  static const _hold = Duration(milliseconds: 600);

  final VoidCallback onTap;
  final Widget child;
  const TapFeedback({super.key, required this.onTap, required this.child});

  /// Whether a tap whose hit test gave [result] lands on a control that
  /// should knock.
  static bool wants(HitTestResult result) {
    var tappable = false;
    for (final entry in result.path) {
      final target = entry.target;
      if (target is RenderEditable) return false;
      if (target is RenderSemanticsAnnotations) {
        if (backLabels.contains(target.properties.label)) return false;
        // Material ink responses announce their tap here.
        if (target.properties.onTap != null) tappable = true;
      }
      // Every GestureDetector with a tap handler leaves one of these.
      if (target is RenderSemanticsGestureHandler && target.onTap != null) {
        tappable = true;
      }
    }
    return tappable;
  }

  @override
  State<TapFeedback> createState() => _TapFeedbackState();
}

class _TapFeedbackState extends State<TapFeedback> {
  final _down = <int, (Offset, Duration)>{};

  void _up(PointerUpEvent event) {
    final down = _down.remove(event.pointer);
    if (down == null) return;
    final (position, at) = down;
    if ((event.position - position).distance > TapFeedback._slop ||
        event.timeStamp - at > TapFeedback._hold) {
      return;
    }
    final result = HitTestResult();
    WidgetsBinding.instance.hitTestInView(result, event.position, event.viewId);
    if (TapFeedback.wants(result)) widget.onTap();
  }

  @override
  Widget build(BuildContext context) => Listener(
    behavior: HitTestBehavior.translucent,
    onPointerDown: (e) => _down[e.pointer] = (e.position, e.timeStamp),
    onPointerUp: _up,
    onPointerCancel: (e) => _down.remove(e.pointer),
    child: widget.child,
  );
}
