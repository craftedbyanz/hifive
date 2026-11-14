part of 'garden_art.dart';

// The drawing kit every plant is built from: seeded randomness, leaf, petal
// and branch shapes, and clumps of leaves or flowers. Plants are drawn in a
// 200 × 200 box with the foot at (100, 182), lit from the upper left: each
// leaf carries its own soft gradient and leaves are laid from shaded to lit,
// so the lit ones sit on top.

const _tau = math.pi * 2;

/// A light and a dark end of one leaf tone.
typedef _Tone = (Color, Color);

/// Xorshift32 from [seed], so a plant draws the same every time.
double Function() _rng(int seed) {
  var s = (seed * 2654435761 + 1013904223) & 0xFFFFFFFF;
  if (s == 0) s = 0x9E3779B9;
  return () {
    s ^= (s << 13) & 0xFFFFFFFF;
    s ^= s >> 17;
    s ^= (s << 5) & 0xFFFFFFFF;
    return s / 4294967296;
  };
}

double _angDiff(double target, double a) {
  final d = (target - a) % _tau;
  return d > math.pi ? d - _tau : d;
}

/// Which of [n] tones a leaf lit by [light] (about -1 to 1) takes.
int _toneOf(double light, int n) =>
    ((light + 1.1) / 2.2 * n).floor().clamp(0, n - 1);

/// The shape of the leaves in a clump.
enum _Shape { oval, needle, star, fan, slim, round }

Offset Function(double a, double b) _frame(double bx, double by, double ang) {
  final dx = math.cos(ang), dy = math.sin(ang);
  return (a, b) => Offset(bx + dx * a - dy * b, by + dy * a + dx * b);
}

/// A soft, round-tipped leaf from ([bx], [by]) pointing at [ang].
Path _leaf(double bx, double by, double ang, double len, double w) {
  final p = _frame(bx, by, ang);
  final a1 = p(len * .18, w * .62), a2 = p(len * .78, w * .56);
  final b1 = p(len * .78, -w * .56), b2 = p(len * .18, -w * .62);
  final tip = p(len, 0);
  return Path()
    ..moveTo(bx, by)
    ..cubicTo(a1.dx, a1.dy, a2.dx, a2.dy, tip.dx, tip.dy)
    ..cubicTo(b1.dx, b1.dy, b2.dx, b2.dy, bx, by)
    ..close();
}

/// A narrow leaf or needle, widest near its base and sharp at the tip.
Path _needle(double bx, double by, double ang, double len, double w) {
  final p = _frame(bx, by, ang);
  final a1 = p(len * .25, w * .55), a2 = p(len * .7, w * .32);
  final b1 = p(len * .7, -w * .32), b2 = p(len * .25, -w * .55);
  final tip = p(len, 0);
  return Path()
    ..moveTo(bx, by)
    ..cubicTo(a1.dx, a1.dy, a2.dx, a2.dy, tip.dx, tip.dy)
    ..cubicTo(b1.dx, b1.dy, b2.dx, b2.dy, bx, by)
    ..close();
}

/// A five-lobed maple leaf.
Path _star(double bx, double by, double ang, double len, double w) {
  final p = _frame(bx, by, ang);
  const tips = [-1.15, -.58, 0.0, .58, 1.15];
  const reach = [.58, .86, 1.0, .86, .58];
  Offset at(double a, double r) =>
      p(math.cos(a) * len * r, math.sin(a) * w * r * 1.2);
  final path = Path()..moveTo(bx, by);
  var v = at(-1.5, .2);
  path.lineTo(v.dx, v.dy);
  for (var i = 0; i < 5; i++) {
    final t = at(tips[i], reach[i]);
    path.lineTo(t.dx, t.dy);
    v = at(i < 4 ? (tips[i] + tips[i + 1]) / 2 : 1.5, i < 4 ? .42 : .2);
    path.lineTo(v.dx, v.dy);
  }
  return path..close();
}

/// A ginkgo fan on a short stalk, notched in the middle.
Path _fan(double bx, double by, double ang, double len, double w) {
  final p = _frame(bx, by, ang);
  final s = p(len * .3, 0),
      l = p(len * .78, -w * .75),
      r = p(len * .78, w * .75);
  final cl = p(len * 1.05, -w * .42), cr = p(len * 1.05, w * .42);
  final n = p(len * .8, 0);
  return Path()
    ..moveTo(bx, by)
    ..lineTo(s.dx, s.dy)
    ..lineTo(l.dx, l.dy)
    ..quadraticBezierTo(cl.dx, cl.dy, n.dx, n.dy)
    ..quadraticBezierTo(cr.dx, cr.dy, r.dx, r.dy)
    ..lineTo(s.dx, s.dy)
    ..close();
}

Path _shape(_Shape s, double bx, double by, double ang, double len, double w) =>
    switch (s) {
      _Shape.needle || _Shape.slim => _needle(bx, by, ang, len, w),
      _Shape.star => _star(bx, by, ang, len, w),
      _Shape.fan => _fan(bx, by, ang, len, w),
      _Shape.oval || _Shape.round => _leaf(bx, by, ang, len, w),
    };

/// A branch or trunk from ([x1], [y1]) to ([x2], [y2]), [w1] wide at its
/// base and [w2] at its end, bowed by [bend] to its left.
Path _taper(
  double x1,
  double y1,
  double x2,
  double y2,
  double w1,
  double w2, [
  double bend = 0,
]) {
  final dx = x2 - x1,
      dy = y2 - y1,
      l = math.max(1e-6, math.sqrt(dx * dx + dy * dy));
  final nx = -dy / l, ny = dx / l;
  final cx = (x1 + x2) / 2 + nx * bend, cy = (y1 + y2) / 2 + ny * bend;
  final wm = (w1 + w2) / 4;
  return Path()
    ..moveTo(x1 + nx * w1 / 2, y1 + ny * w1 / 2)
    ..quadraticBezierTo(
      cx + nx * wm,
      cy + ny * wm,
      x2 + nx * w2 / 2,
      y2 + ny * w2 / 2,
    )
    ..lineTo(x2 - nx * w2 / 2, y2 - ny * w2 / 2)
    ..quadraticBezierTo(
      cx - nx * wm,
      cy - ny * wm,
      x1 - nx * w1 / 2,
      y1 - ny * w1 / 2,
    )
    ..close();
}

/// The point at [t] along the bowed line that [_taper] draws.
Offset _along(
  double x1,
  double y1,
  double x2,
  double y2,
  double bend,
  double t,
) {
  final dx = x2 - x1,
      dy = y2 - y1,
      l = math.max(1e-6, math.sqrt(dx * dx + dy * dy));
  final cx = (x1 + x2) / 2 - dy / l * bend, cy = (y1 + y2) / 2 + dx / l * bend;
  final u = 1 - t;
  return Offset(
    u * u * x1 + 2 * u * t * cx + t * t * x2,
    u * u * y1 + 2 * u * t * cy + t * t * y2,
  );
}

/// A branch: base, end, widths and bow, as [_taper] takes them.
typedef _Limb = (double, double, double, double, double, double, double);

/// Paints onto a canvas in the plant's box, and collects the places where a
/// bloom may open its flowers.
class _Pen {
  _Pen(this.c);
  final Canvas c;
  final spots = <Offset>[];

  /// [p] with a gradient across its bounds: from the upper left by default,
  /// left to right with [across], top to bottom with [down].
  void fill(Path p, _Tone t, {bool across = false, bool down = false}) {
    final r = p.getBounds();
    final a = down ? r.topCenter : (across ? r.centerLeft : r.topLeft);
    final b = down ? r.bottomCenter : (across ? r.centerRight : r.bottomRight);
    c.drawPath(p, Paint()..shader = ui.Gradient.linear(a, b, [t.$1, t.$2]));
  }

  void solid(Path p, Color color) => c.drawPath(p, Paint()..color = color);

  void limbs(List<_Limb> list, _Tone bark) {
    for (final b in list) {
      fill(
        _taper(b.$1, b.$2, b.$3, b.$4, b.$5, b.$6, b.$7),
        bark,
        across: true,
      );
    }
  }

  /// A sphere lit from the upper left: fruit, berries, pebbles.
  void ball(double x, double y, double r, Color lit, Color mid, Color dark) {
    c.drawCircle(
      Offset(x, y),
      r,
      Paint()
        ..shader = ui.Gradient.radial(
          Offset(x - .3 * r, y - .4 * r),
          1.6 * r,
          [lit, mid, dark],
          const [0, .55, 1],
        ),
    );
  }

  void oval(
    double x,
    double y,
    double rx,
    double ry,
    Color color, [
    double rot = 0,
  ]) {
    c
      ..save()
      ..translate(x, y)
      ..rotate(rot)
      ..drawOval(
        Rect.fromCenter(center: Offset.zero, width: rx * 2, height: ry * 2),
        Paint()..color = color,
      )
      ..restore();
  }

  void dot(double x, double y, double r, Color color) =>
      c.drawCircle(Offset(x, y), r, Paint()..color = color);

  void line(Offset a, Offset b, Color color, double w) => c.drawLine(
    a,
    b,
    Paint()
      ..color = color
      ..strokeWidth = w
      ..strokeCap = StrokeCap.round,
  );

  void stroke(Path p, Color color, double w) => c.drawPath(
    p,
    Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = w
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round,
  );

  /// The soft shadow a plant stands on.
  void ground(double cx, double cy, double rx) {
    c
      ..save()
      ..translate(cx, cy)
      ..scale(1, .17)
      ..drawCircle(
        Offset.zero,
        rx,
        Paint()
          ..shader = ui.Gradient.radial(
            Offset.zero,
            rx,
            const [Color(0x5224402A), Color(0x2124402A), Color(0x0024402A)],
            const [0, .6, 1],
          ),
      )
      ..restore();
  }

  /// A few blades of grass.
  void tuft(
    double x,
    double y,
    double s,
    double Function() rnd,
    List<_Tone> tones,
  ) {
    for (var i = 0; i < 6; i++) {
      final a = -math.pi / 2 + (rnd() - .5) * 1.4;
      final t = tones[(rnd() * tones.length).floor()];
      fill(
        _needle(x + (rnd() - .5) * 6 * s, y, a, (8 + rnd() * 6) * s, 2.6 * s),
        t,
      );
    }
  }

  /// A clump of a crown: a soft core, then [n] leaves around ([x], [y])
  /// sorted from shaded to lit. [bias] lifts (or darkens) the whole clump;
  /// [droop] bends leaves on the way down.
  void clump({
    required double x,
    required double y,
    required double r,
    required List<_Tone> tones,
    required int seed,
    int? n,
    double len = 12,
    double w = 8,
    double droop = .35,
    double bias = 0,
    Color? core,
    Color? vein,
    _Shape shape = _Shape.oval,
    bool spot = true,
    double squash = .9,
  }) {
    final rnd = _rng(seed);
    if (spot) spots.add(Offset(x, y));
    if (core != null) {
      oval(x + r * .06, y + r * .08, r * .78, r * .8 * squash, core);
    }
    final leaves = <(double, double, double, double, double, double)>[];
    for (var i = 0, count = n ?? (r * 2.2).round(); i < count; i++) {
      final a = rnd() * _tau;
      final d = r * (.12 + .86 * math.sqrt(rnd()));
      final px = x + math.cos(a) * d, py = y + math.sin(a) * d * squash;
      var dir = a + (rnd() - .5) * .9;
      dir += _angDiff(math.pi / 2, dir) * droop * rnd();
      final l = len * (.8 + .4 * rnd()), lw = w * (.85 + .3 * rnd());
      final light =
          (-(px - x) * .65 - (py - y) * .85) / r + bias + (rnd() - .5) * .38;
      leaves.add((
        px - math.cos(dir) * l * .3,
        py - math.sin(dir) * l * .3,
        dir,
        l,
        lw,
        light,
      ));
    }
    leaves.sort((a, b) => a.$6.compareTo(b.$6));
    for (final (bx, by, dir, l, lw, light) in leaves) {
      final t = _toneOf(light, tones.length);
      fill(_shape(shape, bx, by, dir, l, lw), tones[t]);
      if (vein != null && l > 9 && t >= 2) {
        line(
          Offset(bx, by),
          Offset(bx + math.cos(dir) * l * .75, by + math.sin(dir) * l * .75),
          vein.withValues(alpha: .35),
          .5,
        );
      }
    }
  }

  /// A five-petalled flower; [eye] paints a coloured heart under the centre.
  void flower(
    double x,
    double y,
    double r,
    Color petal,
    Color center,
    double rot, {
    int petals = 5,
    Color? eye,
    Color? edge,
  }) {
    for (var i = 0; i < petals; i++) {
      final a = rot + i * _tau / petals;
      final cx = x + math.cos(a) * r * .55, cy = y + math.sin(a) * r * .55;
      if (edge != null) oval(cx, cy, r * .62, r * .5, edge, a);
      oval(cx, cy, r * .58, r * .46, petal, a);
    }
    if (eye != null) dot(x, y, r * .42, eye);
    dot(x, y, r * .26, center);
  }

  /// A clump of flowers instead of leaves.
  void blossoms({
    required double x,
    required double y,
    required double r,
    required int n,
    required double size,
    required List<Color> tones,
    required Color center,
    required int seed,
    double bias = 0,
    Color? core,
    Color? eye,
    int petals = 5,
    bool spot = true,
    double squash = .9,
  }) {
    final rnd = _rng(seed);
    if (spot) spots.add(Offset(x, y));
    if (core != null) oval(x + r * .1, y + r * .14, r * .86, r * .78, core);
    final list = <(double, double, double, double, double)>[];
    for (var i = 0; i < n; i++) {
      final a = rnd() * _tau, d = r * math.sqrt(rnd());
      final fx = x + math.cos(a) * d, fy = y + math.sin(a) * d * squash;
      final light =
          (-(fx - x) * .65 - (fy - y) * .85) / r + bias + (rnd() - .5) * .38;
      list.add((fx, fy, light, size * (.8 + rnd() * .45), rnd() * 6));
    }
    list.sort((a, b) => a.$3.compareTo(b.$3));
    for (final (fx, fy, light, fr, rot) in list) {
      flower(
        fx,
        fy,
        fr,
        tones[_toneOf(light, tones.length)],
        center,
        rot,
        petals: petals,
        eye: eye,
      );
    }
  }

  /// Small petals or leaves scattered on the ground around the foot.
  void litter(
    double Function() rnd,
    int n,
    double spread,
    List<Color> colors, {
    double y = 184,
  }) {
    for (var i = 0; i < n; i++) {
      final x = 100 + (rnd() - .5) * spread, py = y + rnd() * 5;
      oval(
        x,
        py,
        2.5,
        1.5,
        colors[(rnd() * colors.length).floor()],
        rnd() * math.pi,
      );
    }
  }
}
