part of 'preparing_view.dart';

/// The closing wait drawn as a neural network shaped like a brain seen from
/// the side: its outline traces in, about ninety nodes appear inside, a wave
/// of light spreads from the front along the links while pulses run between
/// lit nodes, then every node flies into its bar of the hifive logo and the
/// logo beats once. Colours run front to back through the logo's bars.
///
/// Built once from a fixed seed, so it draws the same every time. Pulses
/// follow the clock, not chance, so a frame depends only on [progress] and
/// [time]. Glows are images drawn once; nothing is blurred per frame.
class _BrainPainter extends CustomPainter {
  /// Through the whole timeline, 0 to 1.
  final double progress;

  /// Seconds, for the drift of the nodes and the pulses.
  final double time;
  _BrainPainter({required this.progress, required this.time});

  static final _net = _BrainNet.build();
  static List<ui.Image>? _glows;

  /// A soft round glow per logo colour, 64 pixels across.
  static List<ui.Image> get glows => _glows ??= [
    for (final c in Palette.logoBars)
      () {
        final recorder = ui.PictureRecorder();
        Canvas(recorder).drawCircle(
          const Offset(32, 32),
          32,
          Paint()
            ..shader = ui.Gradient.radial(
              const Offset(32, 32),
              32,
              [
                c.withValues(alpha: .55),
                c.withValues(alpha: .18),
                c.withValues(alpha: 0),
              ],
              const [0, .4, 1],
            ),
        );
        return recorder.endRecording().toImageSync(64, 64);
      }(),
  ];

  static double _seg(double v, double a, double b) =>
      ((v - a) / (b - a)).clamp(0.0, 1.0);
  static double _out(double t) => 1 - math.pow(1 - t, 3).toDouble();
  static double _inOut(double t) =>
      t < .5 ? 4 * t * t * t : 1 - math.pow(-2 * t + 2, 3).toDouble() / 2;

  @override
  void paint(Canvas canvas, Size size) {
    final net = _net, p = progress;
    final w = size.width, h = size.height;
    final s = math.min(w / 205, h / 175) * .95;
    final ox = w / 2 - 106 * s, oy = h / 2 - 82 * s;
    final tile = math.min(w, h) * .36, u = tile / 1024;
    final tx = w / 2 - tile / 2, ty = h / 2 - tile / 2;

    final gather = _inOut(_seg(p, .74, .9));
    final fade = 1 - _seg(p, .72, .84);
    final trace = _out(_seg(p, 0, .32));

    // The outline and its folds.
    if (fade > 0) {
      canvas
        ..save()
        ..translate(ox, oy)
        ..scale(s);
      canvas.drawPath(
        net.outline,
        Paint()
          ..color = Palette.storyBottom.withValues(alpha: .6 * fade * trace),
      );
      final line = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8 / s
        ..strokeCap = StrokeCap.round
        ..shader = ui.Gradient.linear(
          const Offset(14, 0),
          const Offset(200, 0),
          [for (final c in Palette.logoBars) c.withValues(alpha: .6 * fade)],
          const [0, .25, .5, .75, 1],
        );
      for (final m in net.outlineMetrics) {
        canvas.drawPath(m.extractPath(0, m.length * trace), line);
      }
      canvas
        ..save()
        ..clipPath(net.outline);
      final folds = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4 / s
        ..strokeCap = StrokeCap.round
        ..color = Palette.logoBars[2].withValues(
          alpha: .16 * fade * _seg(p, .12, .4),
        );
      for (final f in net.folds) {
        canvas.drawPath(f, folds);
      }
      canvas
        ..restore()
        ..restore();
    }

    // Where each node is now: drifting a little, then flying to the logo.
    final nodes = net.nodes;
    final pos = [
      for (final n in nodes)
        () {
          final drift =
              (1 - gather) * math.sin(time / .9 + n.jitter * 6.28) * .8;
          final ax = ox + n.x * s + drift, ay = oy + n.y * s + drift * .6;
          return Offset(
            ax + (tx + n.tx * u - ax) * gather,
            ay + (ty + n.ty * u - ay) * gather,
          );
        }(),
    ];
    final lit = [for (final n in nodes) _out(_seg(p, n.lit, n.lit + .08))];
    final born = [
      for (final n in nodes) _out(_seg(p, n.jitter * .14, n.jitter * .14 + .1)),
    ];
    final flash = List.filled(nodes.length, 0.0);

    // Links.
    final linkFade = 1 - _seg(p, .74, .82);
    if (linkFade > 0) {
      final paint = Paint()..strokeWidth = 1;
      for (final (a, b) in net.edges) {
        final on = math.min(lit[a], lit[b]);
        final alpha = (.1 + .38 * on) * math.min(born[a], born[b]) * linkFade;
        if (alpha <= 0) continue;
        paint.color = (on > 0 ? nodes[a].color : Palette.logoBars[2])
            .withValues(alpha: on > 0 ? alpha : alpha * .45);
        canvas.drawLine(pos[a], pos[b], paint);
      }
    }

    // Pulses, each on its own clock, from a lit node to the next.
    if (p > .12 && p < .76) {
      final glow = glows, dot = Paint()..color = Colors.white;
      for (final pulse in net.pulses) {
        if (lit[pulse.from] < 1) continue;
        final local = (time + pulse.offset) % pulse.period;
        if (local < _BrainNet.travel) {
          final q = local / _BrainNet.travel;
          final at = Offset.lerp(pos[pulse.from], pos[pulse.to], q)!;
          final paint = Paint()
            ..color = Colors.white.withValues(alpha: linkFade);
          canvas.drawImageRect(
            glow[nodes[pulse.from].bar],
            const Rect.fromLTWH(0, 0, 64, 64),
            Rect.fromCircle(center: at, radius: 9),
            paint,
          );
          canvas.drawCircle(at, 1.6, dot);
        } else if (local < _BrainNet.travel + .35) {
          final f = 1 - (local - _BrainNet.travel) / .35;
          if (f > flash[pulse.to]) flash[pulse.to] = f;
        }
      }
    }

    // The logo's tile, behind the gathering nodes.
    final tileIn = _out(_seg(p, .82, .94));
    if (tileIn > 0) {
      final beat = 1 + .07 * math.sin(math.pi * _seg(p, .94, 1));
      canvas
        ..save()
        ..translate(w / 2, h / 2)
        ..scale(beat)
        ..translate(-w / 2, -h / 2);
      canvas.drawRSuperellipse(
        RSuperellipse.fromRectAndRadius(
          Rect.fromLTWH(tx, ty, tile, tile),
          Radius.circular(230 * u),
        ),
        Paint()..color = D.ink.withValues(alpha: tileIn),
      );
      for (final (i, (left, top)) in _BrainNet.bars.indexed) {
        final grow = _out(_seg(p, .84 + i * .015, .95 + i * .01));
        final barTop = 760 - (760 - top) * grow;
        canvas.drawRRect(
          RRect.fromLTRBR(
            tx + left * u,
            ty + barTop * u,
            tx + (left + 84) * u,
            ty + 760 * u,
            Radius.circular(42 * u),
          ),
          Paint()..color = Palette.logoBars[i].withValues(alpha: tileIn),
        );
      }
      canvas.restore();
    }

    // Nodes.
    final nodeFade = 1 - _seg(p, .9, .96);
    if (nodeFade > 0) {
      final glow = glows, paint = Paint();
      for (var i = 0; i < nodes.length; i++) {
        final b = born[i] * nodeFade;
        if (b <= 0) continue;
        final n = nodes[i], on = lit[i], f = flash[i];
        final r =
            (1.8 + 1.4 * on + 1.6 * f) * (.4 + .6 * b) * (1 + gather * .4);
        if (on > 0) {
          final g = 12 + 10 * f;
          paint.color = Colors.white.withValues(
            alpha: (b * (on * .8 + f * .6)).clamp(0.0, 1.0),
          );
          canvas.drawImageRect(
            glow[n.bar],
            const Rect.fromLTWH(0, 0, 64, 64),
            Rect.fromCircle(center: pos[i], radius: g),
            paint,
          );
        }
        paint.color = (on > 0 ? n.color : Palette.logoBars[2]).withValues(
          alpha: on > 0 ? b * (.45 + .55 * on) : b * .3,
        );
        canvas.drawCircle(pos[i], r, paint);
        if (f > .05) {
          paint.color = Colors.white.withValues(alpha: b * f);
          canvas.drawCircle(pos[i], r * .5, paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(_BrainPainter old) =>
      old.progress != progress || old.time != time;
}

class _Node {
  final double x, y, jitter;
  late double lit, tx, ty;
  late Color color;
  late int bar;
  _Node(this.x, this.y, this.jitter);
}

typedef _Pulse = ({int from, int to, double period, double offset});

/// The brain's geometry and network, in a 200 by 165 box.
class _BrainNet {
  final Path outline;
  final List<ui.PathMetric> outlineMetrics;
  final List<Path> folds;
  final List<_Node> nodes;
  final List<(int, int)> edges;
  final List<_Pulse> pulses;
  _BrainNet(this.outline, this.folds, this.nodes, this.edges, this.pulses)
    : outlineMetrics = outline.computeMetrics().toList();

  /// Seconds a pulse takes along its link.
  static const travel = .45;

  /// The logo's bars on its 1024 grid: left edge and top; 84 wide, standing
  /// on 760 (as `LogoPainter`).
  static const bars = [
    (222.0, 470.0),
    (346.0, 300.0),
    (470.0, 230.0),
    (594.0, 290.0),
    (718.0, 400.0),
  ];

  static Path _outline() => Path()
    ..moveTo(34, 108)
    ..cubicTo(14, 96, 12, 58, 38, 40)
    ..cubicTo(50, 16, 90, 8, 112, 18)
    ..cubicTo(134, 6, 172, 16, 180, 44)
    ..cubicTo(198, 60, 196, 92, 178, 104)
    ..cubicTo(184, 120, 170, 136, 150, 132)
    ..cubicTo(140, 140, 124, 138, 118, 128)
    ..lineTo(117, 148)
    ..cubicTo(117, 157, 106, 157, 106, 148)
    ..lineTo(106, 123)
    ..cubicTo(90, 125, 70, 124, 58, 116)
    ..cubicTo(48, 121, 38, 117, 34, 108)
    ..close();

  static const List<List<double>> _foldCurves = [
    [104, 20, 98, 40, 106, 56, 96, 86],
    [58, 98, 84, 80, 118, 90, 150, 80],
    [46, 56, 60, 50, 70, 62, 84, 54],
    [128, 30, 120, 46, 134, 58, 124, 74],
    [150, 40, 160, 56, 150, 70, 166, 82],
    [64, 34, 74, 46, 66, 70, 78, 76],
    [128, 108, 140, 104, 150, 114, 164, 110],
    [120, 120, 134, 118, 146, 126, 160, 122],
  ];

  static _BrainNet build() {
    final outline = _outline();
    final rnd = math.Random(11);
    final nodes = <_Node>[];
    for (var k = 0; k < 6000 && nodes.length < 92; k++) {
      final x = 14 + rnd.nextDouble() * 186, y = 6 + rnd.nextDouble() * 154;
      if (!outline.contains(Offset(x, y))) continue;
      if (nodes.any(
        (n) => (n.x - x) * (n.x - x) + (n.y - y) * (n.y - y) < 12.5 * 12.5,
      )) {
        continue;
      }
      nodes.add(_Node(x, y, rnd.nextDouble()));
    }

    // Each node links to its three nearest, if near enough.
    final edges = <(int, int)>[];
    final seen = <int>{};
    final links = [for (final _ in nodes) <int>[]];
    for (var i = 0; i < nodes.length; i++) {
      final near = [
        for (var j = 0; j < nodes.length; j++)
          if (j != i)
            (
              j,
              math.pow(nodes[j].x - nodes[i].x, 2) +
                  math.pow(nodes[j].y - nodes[i].y, 2),
            ),
      ]..sort((a, b) => a.$2.compareTo(b.$2));
      for (final (j, d) in near.take(3)) {
        final key = (math.min(i, j) * 1000 + math.max(i, j)).toInt();
        if (d < 32 * 32 && seen.add(key)) {
          edges.add((i, j));
          links[i].add(j);
          links[j].add(i);
        }
      }
    }

    // Hops from the front of the brain set when each node lights.
    var seed = 0;
    for (var i = 1; i < nodes.length; i++) {
      if (nodes[i].x < nodes[seed].x) seed = i;
    }
    final hop = List.filled(nodes.length, 1 << 30);
    hop[seed] = 0;
    final queue = [seed];
    while (queue.isNotEmpty) {
      final i = queue.removeAt(0);
      for (final j in links[i]) {
        if (hop[j] > hop[i] + 1) {
          hop[j] = hop[i] + 1;
          queue.add(j);
        }
      }
    }
    final far = hop.where((v) => v < 1 << 30).fold<int>(1, math.max);
    final minX = nodes.map((n) => n.x).reduce(math.min);
    final maxX = nodes.map((n) => n.x).reduce(math.max);
    const colors = Palette.logoBars;
    for (var i = 0; i < nodes.length; i++) {
      final n = nodes[i];
      n.lit = .12 + .5 * (hop[i] < 1 << 30 ? hop[i] / far : 1) + .04 * n.jitter;
      final f = ((n.x - minX) / (maxX - minX)).clamp(0.0, .999) * 4;
      n.color = Color.lerp(colors[f.floor()], colors[f.floor() + 1], f % 1)!;
    }

    // Each node's place in the logo: five groups front to back, one per
    // bar, spread top to bottom along it.
    final order = [for (var i = 0; i < nodes.length; i++) i]
      ..sort((a, b) => nodes[a].x.compareTo(nodes[b].x));
    final per = (nodes.length / 5).ceil();
    for (var b = 0; b < 5; b++) {
      final group = order.skip(b * per).take(per).toList()
        ..sort((a, c) => nodes[a].y.compareTo(nodes[c].y));
      final (left, top) = bars[b];
      for (final (k, i) in group.indexed) {
        nodes[i]
          ..bar = b
          ..tx = left + 42
          ..ty =
              top +
              30 +
              (760 - top - 60) *
                  (group.length > 1 ? k / (group.length - 1) : .5);
      }
    }

    // About half the links carry pulses, from the node lit first.
    final pulses = <_Pulse>[
      for (final (a, b) in edges)
        if (rnd.nextDouble() < .5)
          (
            from: nodes[a].lit <= nodes[b].lit ? a : b,
            to: nodes[a].lit <= nodes[b].lit ? b : a,
            period: 1.4 + rnd.nextDouble() * 1.6,
            offset: rnd.nextDouble() * 3,
          ),
    ];

    final folds = [
      for (final c in _foldCurves)
        Path()
          ..moveTo(c[0], c[1])
          ..cubicTo(c[2], c[3], c[4], c[5], c[6], c[7]),
    ];
    return _BrainNet(outline, folds, nodes, edges, pulses);
  }
}
