import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

import '../../core/design/design.dart';
import '../../core/services/focus_shield.dart';
import '../../l10n/l10n.dart';
import '../../state/state.dart';
import '../../widgets/common.dart';

/// Minutes a focus session can be set to: 0 is the stopwatch, then every
/// 5 minutes up to [maxMinutes].
const minuteStep = 5, maxMinutes = 180;

/// The choice the timer sheet returns: the minutes, and whether to start.
typedef TimerChoice = ({int minutes, bool start});

/// A frosted sheet over the focus screen for choosing the length on a ruler,
/// or the stopwatch at its left end. Dragging knocks once per mark.
Future<TimerChoice?> showTimerSheet(BuildContext context, int minutes) =>
    showGeneralDialog<TimerChoice>(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 320),
      pageBuilder: (_, _, _) => _TimerSheet(minutes: minutes),
      transitionBuilder: (_, animation, _, child) => SlideTransition(
        position: Tween(begin: const Offset(0, 1), end: Offset.zero).animate(
          CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
            reverseCurve: Curves.easeInCubic,
          ),
        ),
        child: child,
      ),
    );

class _TimerSheet extends StatefulWidget {
  final int minutes;
  const _TimerSheet({required this.minutes});

  @override
  State<_TimerSheet> createState() => _TimerSheetState();
}

class _TimerSheetState extends State<_TimerSheet> {
  late var _minutes = widget.minutes;
  ShieldStatus _shield = FocusShield.off;

  @override
  void initState() {
    super.initState();
    FocusShield.status().then((s) {
      if (mounted) setState(() => _shield = s);
    });
  }

  Future<void> _switchShield(bool on) async {
    final t = context.t;
    final (status, error) = await FocusShield.setEnabled(
      on,
      title: t.focusShieldPickerTitle,
      done: t.focusShieldDone,
    );
    if (!mounted) return;
    setState(() => _shield = status);
    if (error != null) {
      toast(
        context,
        error == ShieldError.denied
            ? t.focusShieldDenied
            : t.focusShieldUnavailable,
      );
    }
  }

  Future<void> _pickApps() async {
    final t = context.t;
    final status = await FocusShield.pick(
      title: t.focusShieldPickerTitle,
      done: t.focusShieldDone,
    );
    if (mounted) setState(() => _shield = status);
  }

  void _close({bool start = false}) =>
      Navigator.of(context).pop((minutes: _minutes, start: start));

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final stopwatch = _minutes == 0;
    final bottom = MediaQuery.paddingOf(context).bottom;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (popped, _) {
        if (!popped) _close();
      },
      child: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              key: const ValueKey('timer-dismiss'),
              behavior: HitTestBehavior.opaque,
              onTap: _close,
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(34),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.fromLTRB(20, 22, 20, 20 + bottom),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .62),
                    border: Border(
                      top: BorderSide(
                        color: Colors.white.withValues(alpha: .8),
                      ),
                    ),
                  ),
                  child: Material(
                    type: MaterialType.transparency,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          stopwatch ? t.stopwatchTitle : t.timerTitle,
                          style: D.text(16, weight: FontWeight.w700),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          stopwatch ? t.stopwatchSubtitle : t.timerSubtitle,
                          style: D.text(13, color: D.secondary),
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          height: 40,
                          child: Center(
                            child: stopwatch
                                ? const Icon(
                                    CupertinoIcons.stopwatch,
                                    size: 32,
                                    color: D.ink,
                                  )
                                : Text(
                                    t.focusMinutes(_minutes),
                                    key: const ValueKey('timer-value'),
                                    style: D.text(
                                      30,
                                      weight: FontWeight.w800,
                                      spacing: -.5,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        MinuteRuler(
                          minutes: _minutes,
                          onChanged: (m) => setState(() => _minutes = m),
                        ),
                        if (_shield.available) ...[
                          const SizedBox(height: 18),
                          ShieldRow(
                            status: _shield,
                            onSwitch: _switchShield,
                            onPick: _pickApps,
                          ),
                          const SizedBox(height: 18),
                        ] else
                          const SizedBox(height: 26),
                        PressFade(
                          key: const ValueKey('timer-start'),
                          onTap: () => _close(start: true),
                          child: Container(
                            height: 54,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(27),
                              boxShadow: D.shadow,
                            ),
                            child: Text(
                              t.focusStart,
                              style: D.text(
                                16,
                                weight: FontWeight.w700,
                                color: Palette.focusInk,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The switch that blocks the chosen apps while a session runs, with how
/// many are chosen and a way to change them.
class ShieldRow extends StatelessWidget {
  final ShieldStatus status;
  final ValueChanged<bool> onSwitch;
  final VoidCallback onPick;
  const ShieldRow({
    super.key,
    required this.status,
    required this.onSwitch,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final detail = !status.enabled
        ? t.focusShieldOff
        : status.picked == 0
        ? t.focusShieldNone
        : t.focusShieldPicked(status.picked);
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 8, 10, 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .7),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          const Icon(
            CupertinoIcons.shield_lefthalf_fill,
            size: 22,
            color: Palette.focusInk,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: PressFade(
              key: const ValueKey('shield-pick'),
              onTap: status.enabled ? onPick : null,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t.focusShieldTitle,
                    style: D.text(14, weight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Text(detail, style: D.text(12, color: D.secondary)),
                ],
              ),
            ),
          ),
          CupertinoSwitch(
            key: const ValueKey('shield-switch'),
            value: status.enabled,
            activeTrackColor: Palette.focusInk,
            onChanged: onSwitch,
          ),
        ],
      ),
    );
  }
}

/// A horizontal ruler of marks every [minuteStep] minutes under a fixed
/// pointer. Dragging moves it with momentum, knocks once per mark crossed
/// and settles on the nearest mark. The left end is the stopwatch.
class MinuteRuler extends StatefulWidget {
  final int minutes;
  final ValueChanged<int> onChanged;
  const MinuteRuler({
    super.key,
    required this.minutes,
    required this.onChanged,
  });

  /// Points between two marks.
  static const spacing = 22.0;
  static const marks = maxMinutes ~/ minuteStep;

  @override
  State<MinuteRuler> createState() => _MinuteRulerState();
}

class _MinuteRulerState extends State<MinuteRuler>
    with SingleTickerProviderStateMixin {
  late double _offset = widget.minutes / minuteStep * MinuteRuler.spacing;
  late int _mark = widget.minutes ~/ minuteStep;
  late final AnimationController _motion = AnimationController.unbounded(
    vsync: this,
  )..addListener(() => _moveTo(_motion.value));

  static const _max = MinuteRuler.marks * MinuteRuler.spacing;

  @override
  void dispose() {
    _motion.dispose();
    super.dispose();
  }

  void _moveTo(double offset) {
    final o = offset.clamp(0.0, _max);
    final mark = (o / MinuteRuler.spacing).round();
    setState(() => _offset = o);
    if (mark != _mark) {
      _mark = mark;
      AppScope.read(context).feedback.tap();
      widget.onChanged(mark * minuteStep);
    }
  }

  void _settle(double velocity) {
    // Coast with friction, then snap to the mark nearest where it stops.
    // A slow release just settles; only a flick coasts.
    final coast = FrictionSimulation(
      .12,
      _offset,
      velocity.abs() < 300 ? 0 : -velocity,
    );
    final target =
        ((coast.finalX.clamp(0.0, _max)) / MinuteRuler.spacing).round() *
        MinuteRuler.spacing;
    final distance = (target - _offset).abs();
    _motion
      ..value = _offset
      ..animateTo(
        target,
        duration: Duration(
          milliseconds: (180 + distance * 1.6).clamp(180, 900).round(),
        ),
        curve: Curves.easeOutCubic,
      );
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
    key: const ValueKey('timer-ruler'),
    behavior: HitTestBehavior.opaque,
    onHorizontalDragDown: (_) => _motion.stop(),
    onHorizontalDragUpdate: (d) => _moveTo(_offset - d.delta.dx),
    onHorizontalDragEnd: (d) => _settle(d.velocity.pixelsPerSecond.dx),
    child: SizedBox(
      height: 44,
      width: double.infinity,
      child: CustomPaint(painter: _RulerPainter(_offset)),
    ),
  );
}

class _RulerPainter extends CustomPainter {
  final double offset;
  _RulerPainter(this.offset);

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2, cy = size.height / 2;
    final paint = Paint()..strokeCap = StrokeCap.round;
    for (var i = 0; i <= MinuteRuler.marks; i++) {
      final x = cx + i * MinuteRuler.spacing - offset;
      if (x < -10 || x > size.width + 10) continue;
      // Marks fade towards the edges.
      final fade = (1 - ((x - cx).abs() / (size.width / 2)) * .75).clamp(
        .15,
        1.0,
      );
      if (i == 0) {
        _stopwatch(canvas, Offset(x, cy), fade);
        continue;
      }
      final hour = i % 12 == 0;
      paint
        ..color = D.ink.withValues(alpha: (hour ? .55 : .3) * fade)
        ..strokeWidth = 1.4;
      final h = hour ? 9.0 : 6.0;
      canvas.drawLine(Offset(x, cy - h), Offset(x, cy + h), paint);
    }
    paint
      ..color = D.ink
      ..strokeWidth = 3;
    canvas.drawLine(Offset(cx, cy - 13), Offset(cx, cy + 13), paint);
  }

  void _stopwatch(Canvas canvas, Offset c, double fade) {
    final paint = Paint()
      ..color = D.ink.withValues(alpha: .55 * fade)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    canvas
      ..drawCircle(c + const Offset(0, 1), 5.5, paint)
      ..drawLine(c + const Offset(0, -6.5), c + const Offset(0, -8.5), paint)
      ..drawLine(c + const Offset(0, 1), c + const Offset(0, -2.5), paint);
  }

  @override
  bool shouldRepaint(_RulerPainter old) => old.offset != offset;
}

/// The session title, edited in a sheet with the keyboard up. Pops the new
/// title, or null when dismissed.
class SessionTitleSheet extends StatefulWidget {
  final String title;
  const SessionTitleSheet({super.key, required this.title});

  @override
  State<SessionTitleSheet> createState() => _SessionTitleSheetState();
}

class _SessionTitleSheetState extends State<SessionTitleSheet> {
  late final _text = TextEditingController(text: widget.title);

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(t.sessionTitleSheet, style: D.text(16, weight: FontWeight.w700)),
          const SizedBox(height: 14),
          TextField(
            key: const ValueKey('session-title-field'),
            controller: _text,
            autofocus: true,
            maxLength: 40,
            textInputAction: TextInputAction.done,
            onSubmitted: (v) => Navigator.of(context).pop(v.trim()),
            decoration: InputDecoration(hintText: t.sessionTitleHint),
          ),
        ],
      ),
    );
  }
}
