part of 'focus_screen.dart';

/// The tag and the session title at the top left, and the close button.
class FocusTopBar extends StatelessWidget {
  final String tag, title, titleHint;
  final Color color;

  /// Null while a session runs, when neither can change.
  final VoidCallback? onTag, onTitle;

  /// Null hides the close button, as while a session runs.
  final String? closeKey;
  final VoidCallback onClose;
  const FocusTopBar({
    super.key,
    required this.tag,
    required this.color,
    required this.title,
    required this.titleHint,
    required this.onTag,
    required this.onTitle,
    required this.closeKey,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(22, 14, 18, 0),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PressFade(
                key: const ValueKey('focus-tag'),
                onTap: onTag,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 7),
                    Flexible(
                      child: Text(
                        tag,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: D.text(
                          15,
                          weight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    if (onTag != null)
                      const Icon(
                        CupertinoIcons.chevron_right,
                        size: 13,
                        color: Colors.white,
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              PressFade(
                key: const ValueKey('focus-title'),
                onTap: onTitle,
                child: Text(
                  title.isEmpty ? titleHint : title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: D.text(
                    16,
                    weight: title.isEmpty ? FontWeight.w500 : FontWeight.w700,
                    color: Colors.white.withValues(
                      alpha: title.isEmpty ? .7 : 1,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (closeKey case final key?)
          PressFade(
            key: ValueKey(key),
            onTap: onClose,
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                CupertinoIcons.xmark,
                size: 16,
                color: Colors.white,
              ),
            ),
          ),
      ],
    ),
  );
}

/// The focus screen's sky: the logo's indigo softened by drifting mist, a
/// warm sunbeam slanting down onto the plant, and motes of light rising in
/// it. It moves only under [AmbientMotion].
class FocusBackdrop extends StatefulWidget {
  final Widget child;
  const FocusBackdrop({super.key, required this.child});

  @override
  State<FocusBackdrop> createState() => _FocusBackdropState();
}

class _FocusBackdropState extends State<FocusBackdrop>
    with SingleTickerProviderStateMixin {
  final _time = ValueNotifier<double>(4);
  late final Ticker _ticker = createTicker(
    (elapsed) => _time.value = 4 + elapsed.inMicroseconds / 1e6,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final on = AmbientMotion.of(context);
    if (on && !_ticker.isActive) {
      _ticker.start();
    } else if (!on && _ticker.isActive) {
      _ticker.stop();
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    _time.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Palette.focusSkyTop,
          Palette.focusSkyMiddle,
          Palette.focusSkyBottom,
        ],
      ),
    ),
    child: Stack(
      fit: StackFit.expand,
      children: [
        RepaintBoundary(child: CustomPaint(painter: _MistPainter(_time))),
        widget.child,
      ],
    ),
  );
}

class _MistPainter extends CustomPainter {
  final ValueNotifier<double> time;
  _MistPainter(this.time) : super(repaint: time);

  void _glow(Canvas c, Offset o, double rx, double ry, Color color) {
    c
      ..save()
      ..translate(o.dx, o.dy)
      ..scale(1, ry / rx)
      ..drawCircle(
        Offset.zero,
        rx,
        Paint()
          ..shader = RadialGradient(colors: [color, color.withValues(alpha: 0)])
              .createShader(Rect.fromCircle(center: Offset.zero, radius: rx)),
      )
      ..restore();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final t = time.value, w = size.width, h = size.height;
    double drift(double speed, double phase) => math.sin(t * speed + phase);
    // Mist: pale drifts above, a deep one below.
    _glow(
      canvas,
      Offset(w * (.15 + drift(.05, 1) * .04), h * .36),
      w * .55,
      h * .1,
      Palette.focusMist.withValues(alpha: .38),
    );
    _glow(
      canvas,
      Offset(w * (.9 + drift(.04, 3) * .04), h * .45),
      w * .5,
      h * .11,
      Palette.focusMist.withValues(alpha: .3),
    );
    _glow(
      canvas,
      Offset(w * (.45 + drift(.03, 5) * .05), h * .86),
      w * .7,
      h * .14,
      Palette.focusMistDeep.withValues(alpha: .5),
    );
    // The sun beyond the top right corner, and its beams onto the plant.
    _glow(
      canvas,
      Offset(w * 1.02, -h * .02),
      w * .55,
      w * .55,
      Palette.focusBeam.withValues(alpha: .42),
    );
    final target = Offset(w * .5, h * .56);
    for (final (dx, width, alpha, phase) in const [
      (.0, .3, .26, 0.0),
      (.12, .14, .18, 2.0),
      (-.14, .12, .14, 4.0),
    ]) {
      final top = Offset(w * (.82 + dx), -h * .05);
      final along = target - top;
      final n = Offset(-along.dy, along.dx) / along.distance;
      final half = w * width / 2;
      final a = alpha * (.75 + .25 * math.sin(t * .6 + phase));
      canvas.drawPath(
        Path()..addPolygon([
          top + n * half,
          top - n * half,
          target - n * half * .5,
          target + n * half * .5,
        ], true),
        Paint()
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14)
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Palette.focusBeam.withValues(alpha: a),
              Palette.focusBeam.withValues(alpha: 0),
            ],
          ).createShader(Rect.fromPoints(top, target)),
      );
    }
    // Motes of light rising from the sunlit ground.
    for (var i = 0; i < 12; i++) {
      final life = (t / (9 + (i % 4) * 1.6) + i / 12) % 1;
      final x =
          w * (.3 + ((i * 7.31 * 13.7) % 1) * .42) + math.sin(t * .7 + i) * 6;
      final y = h * .58 - life * h * .32;
      final a = math.sin(life * math.pi) * .8;
      canvas
        ..drawCircle(
          Offset(x, y),
          5,
          Paint()
            ..color = Palette.focusMote.withValues(alpha: a * .25)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
        )
        ..drawCircle(
          Offset(x, y),
          1.6,
          Paint()..color = Palette.focusMote.withValues(alpha: a),
        );
    }
  }

  @override
  bool shouldRepaint(_MistPainter old) => false;
}

class FocusTimer extends StatelessWidget {
  final Duration left;
  const FocusTimer(this.left, {super.key});

  @override
  Widget build(BuildContext context) {
    final s = left.inSeconds.clamp(0, 24 * 3600);
    final text =
        '${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';
    return Text(
      text,
      key: const ValueKey('focus-timer'),
      style: D
          .text(
            72,
            weight: FontWeight.w700,
            color: Colors.white,
            height: 1,
            spacing: 1,
          )
          .copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
    );
  }
}

class FocusTitle extends StatelessWidget {
  final String text;
  const FocusTitle(this.text, {super.key});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 24),
    child: Text(
      text,
      textAlign: TextAlign.center,
      style: D.text(
        22,
        weight: FontWeight.w800,
        color: Colors.white,
        spacing: -.3,
      ),
    ),
  );
}

class FocusNote extends StatelessWidget {
  final String text;
  const FocusNote(this.text, {super.key});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(32, 10, 32, 0),
    child: Text(
      text,
      textAlign: TextAlign.center,
      style: D.text(
        14,
        weight: FontWeight.w500,
        color: Colors.white.withValues(alpha: .92),
        height: 1.45,
      ),
    ),
  );
}

class FocusButton extends StatelessWidget {
  final String id, label;
  final VoidCallback onTap;
  const FocusButton(this.id, this.label, this.onTap, {super.key});

  @override
  Widget build(BuildContext context) => PressFade(
    key: ValueKey(id),
    onTap: onTap,
    child: Container(
      width: 220,
      padding: const EdgeInsets.symmetric(vertical: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(99),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: D.text(16, weight: FontWeight.w700, color: Palette.focusInk),
      ),
    ),
  );
}

class FocusLink extends StatelessWidget {
  final String id, label;
  final VoidCallback onTap;
  const FocusLink(this.id, this.label, this.onTap, {super.key});

  @override
  Widget build(BuildContext context) => PressFade(
    key: ValueKey(id),
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Text(
        label,
        style: D.text(15, weight: FontWeight.w600, color: Colors.white),
      ),
    ),
  );
}

/// The quiet text button that ends a running session: "Huỷ (n)" while it
/// can still be cancelled, then stop for the stopwatch, or give up.
class FocusStopButton extends StatelessWidget {
  final String id, label;
  final VoidCallback onTap;
  const FocusStopButton({
    super.key,
    required this.id,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => PressFade(
    key: ValueKey(id),
    onTap: onTap,
    child: Semantics(
      button: true,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 120, minHeight: 48),
        child: Center(
          child: Text(
            label,
            style: D.text(
              17,
              weight: FontWeight.w600,
              color: Colors.white.withValues(alpha: .92),
            ),
          ),
        ),
      ),
    ),
  );
}
