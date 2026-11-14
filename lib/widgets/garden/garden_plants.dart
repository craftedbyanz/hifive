part of 'garden_art.dart';

// Palms, grasses, succulents, a bonsai and a mushroom, and the table of
// every species' drawing.

// ——— Bonsai (Japan): a glazed blue pot, an S-curved trunk and flat,
// layered pads of juniper.

const _junTones = [
  (Color(0xFF2A5E3A), Color(0xFF224E30)),
  (Color(0xFF367448), Color(0xFF2E643E)),
  (Color(0xFF4C9058), Color(0xFF417E4C)),
  (Color(0xFF74B074), Color(0xFF62A064)),
  (Color(0xFFA8D2A0), Color(0xFF94C68C)),
];
const _bonsaiBark = (Color(0xFFA67A56), Color(0xFF5E3E28));

void _bonsai(_Pen p) {
  final rnd = _rng(101);
  p.ground(100, 184, 54);
  p.limbs(const [
    (102, 168, 84, 140, 14, 10, 10),
    (84, 142, 108, 112, 10, 7, -10),
    (106, 116, 92, 86, 7, 4, 7),
    (86, 140, 56, 130, 5, 2.5, -3),
    (106, 116, 140, 106, 5, 2.5, 3),
    (94, 90, 120, 74, 3.5, 2, 2),
  ], _bonsaiBark);
  for (final (i, (x, y, r, bias)) in const [
    (54.0, 126.0, 18.0, -.1),
    (142.0, 102.0, 19.0, -.05),
    (90.0, 82.0, 21.0, .3),
    (122.0, 70.0, 16.0, .4),
    (104.0, 56.0, 14.0, .55),
  ].indexed) {
    p.clump(
      x: x,
      y: y,
      r: r,
      bias: bias,
      n: (r * 4).round(),
      len: 6,
      w: 3,
      shape: _Shape.needle,
      tones: _junTones,
      seed: 1010 + i,
      squash: .42,
      droop: 0,
      core: const Color(0xFF1E4A2C),
    );
  }
  p
    ..fill(
      Path()
        ..moveTo(62, 168)
        ..lineTo(138, 168)
        ..lineTo(132, 184)
        ..lineTo(68, 184)
        ..close(),
      (const Color(0xFF5A7AC0), const Color(0xFF24396B)),
      across: true,
    )
    ..fill(
      Path()..addRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(58, 164, 84, 6),
          const Radius.circular(3),
        ),
      ),
      (const Color(0xFF8AA4DC), const Color(0xFF3E5A96)),
      across: true,
    )
    ..oval(100, 165, 38, 2.4, const Color(0xFF5A4030))
    ..dot(72, 186, 2.2, const Color(0xFF24396B))
    ..dot(128, 186, 2.2, const Color(0xFF24396B));
  for (var i = 0; i < 6; i++) {
    p.oval(80 + rnd() * 40, 164.5, 3.4, 1.4, const Color(0xFF6E9E4A));
  }
}

// ——— Coconut palm (Vietnam): a leaning, ringed trunk, a crown of long
// fronds with a dry one hanging, and a cluster of green coconuts.

const _palmTones = [
  (Color(0xFF3C7C40), Color(0xFF326A37)),
  (Color(0xFF4C974A), Color(0xFF40833F)),
  (Color(0xFF69B655), Color(0xFF58A44B)),
  (Color(0xFF93D16E), Color(0xFF7CC25F)),
  (Color(0xFFC9EC94), Color(0xFFABDD7C)),
];
const _dryFrond = [
  (Color(0xFF9C7A45), Color(0xFF80633A)),
  (Color(0xFFB8955C), Color(0xFF9C7C4A)),
  (Color(0xFFCDB074), Color(0xFFB39660)),
];
const _palmBark = (Color(0xFFD8B282), Color(0xFF977049));

/// A frond from [c] towards [ang], [len] long, sagging by [droop].
void _frond(
  _Pen p,
  Offset c,
  double ang,
  double len,
  double droop,
  double bias,
  int seed,
  List<_Tone> tones, {
  double leaflet = 21,
}) {
  final r = _rng(seed);
  final tip =
      c + Offset(math.cos(ang) * len, math.sin(ang) * len + droop * len * .55);
  final ctl =
      c +
      Offset(
        math.cos(ang) * len * .55,
        math.sin(ang) * len * .55 - len * (.12 + r() * .12),
      );
  Offset q(double t) {
    final u = 1 - t;
    return c * (u * u) + ctl * (2 * u * t) + tip * (t * t);
  }

  Offset dq(double t) => (ctl - c) * (2 * (1 - t)) + (tip - ctl) * (2 * t);
  final leaves = <(Offset, double, double, double, double)>[];
  for (var t = .1; t <= 1.001; t += .05) {
    final pt = q(t), d = dq(t), a = math.atan2(d.dy, d.dx);
    for (final side in const [-1, 1]) {
      if (r() < .12) continue;
      var la = a + side * (1 + r() * .3);
      la += _angDiff(math.pi / 2, la) * (.28 + r() * .25);
      final l = (leaflet * (1 - .62 * t) + 4) * (.72 + r() * .5);
      final up = math.sin(la) < 0 ? .35 : -.25;
      leaves.add((pt, la, l, 3.2 + r() * 1.3, bias + up + (r() - .5) * .38));
    }
  }
  leaves.sort((a, b) => a.$5.compareTo(b.$5));
  for (final (pt, la, l, w, light) in leaves) {
    p.fill(
      _needle(pt.dx, pt.dy, la, l, w),
      tones[_toneOf(light, tones.length)],
    );
  }
  p.stroke(
    Path()
      ..moveTo(c.dx, c.dy)
      ..quadraticBezierTo(ctl.dx, ctl.dy, tip.dx, tip.dy),
    identical(tones, _dryFrond)
        ? const Color(0xFF8A6A3A)
        : const Color(0xFF6E9A44),
    1.5,
  );
}

void _coconut(_Pen p) {
  final rnd = _rng(103);
  p.ground(104, 182, 56);
  const p0 = Offset(96, 184), p1 = Offset(76, 124), p2 = Offset(114, 68);
  Offset b(double t) {
    final u = 1 - t;
    return p0 * (u * u) + p1 * (2 * u * t) + p2 * (t * t);
  }

  Offset d(double t) => (p1 - p0) * (2 * (1 - t)) + (p2 - p1) * (2 * t);
  for (var i = 0; i < 14; i++) {
    final t0 = i / 14, t1 = (i + 1) / 14;
    final a = b(t0), c = b(t1), da = d(t0), dc = d(t1);
    final wa = (7.6 - 2.8 * t0) * (t0 < .08 ? 1.25 : 1), wc = 7.6 - 2.8 * t1;
    final na = Offset(-da.dy, da.dx) / da.distance * wa;
    final nc = Offset(-dc.dy, dc.dx) / dc.distance * wc * 1.06;
    p
      ..fill(
        Path()..addPolygon([a + na, c + nc, c - nc, a - na], true),
        _palmBark,
        across: true,
      )
      ..stroke(
        Path()
          ..moveTo((c + nc).dx, (c + nc).dy)
          ..quadraticBezierTo(c.dx, c.dy + 1.4, (c - nc).dx, (c - nc).dy),
        const Color(0x8C86613E),
        1,
      );
  }
  const crown = Offset(114, 66);
  _frond(p, crown, 2.0, 34, 2.2, -.2, 109, _dryFrond);
  _frond(p, crown, -1.7, 42, .18, .45, 104, _palmTones);
  _frond(p, crown, -2.5, 50, .5, .3, 105, _palmTones);
  _frond(p, crown, -.8, 48, .42, .15, 106, _palmTones);
  for (final (x, y) in const [
    (107.0, 74.0),
    (117.0, 77.0),
    (111.0, 81.0),
    (122.0, 71.0),
  ]) {
    p.ball(
      x,
      y,
      6,
      const Color(0xFFC3D27A),
      const Color(0xFF7E9A48),
      const Color(0xFF4E6B2C),
    );
  }
  p.spots.addAll(const [Offset(80, 64), Offset(146, 62), Offset(114, 46)]);
  _frond(p, crown, 3.05, 58, .9, .05, 107, _palmTones);
  _frond(p, crown, .05, 60, 1.0, -.1, 108, _palmTones);
  _frond(p, crown, 2.5, 46, 1.3, -.2, 110, _palmTones);
  _frond(p, crown, .62, 50, 1.2, -.35, 111, _palmTones);
  p
    ..ball(
      140,
      183,
      5.6,
      const Color(0xFFC99A6A),
      const Color(0xFF8A5E3C),
      const Color(0xFF5E3D25),
    )
    ..tuft(80, 184, .9, rnd, _palmTones.sublist(2))
    ..tuft(152, 185, .8, rnd, _palmTones.sublist(2));
}

// ——— Banana (Vietnam): a clump of stems under huge torn paddle leaves,
// with a hanging hand of green bananas and its purple heart.

const _bananaTones = [
  (Color(0xFF4E9A44), Color(0xFF3C7E36)),
  (Color(0xFF64B04E), Color(0xFF529A44)),
  (Color(0xFF86C85E), Color(0xFF72B652)),
  (Color(0xFFADDC7C), Color(0xFF98CE6C)),
];

/// A banana leaf: a broad blade along a midrib that arches and sags by
/// [droop], torn here and there from the midrib to the edge.
void _paddle(
  _Pen p,
  Offset base,
  double ang,
  double len,
  double w,
  _Tone tone,
  int seed, {
  double droop = .35,
}) {
  final r = _rng(seed);
  final dir = Offset(math.cos(ang), math.sin(ang));
  final ctl = base + dir * (len * .6) + Offset(0, -len * .12);
  final tip = base + dir * len + Offset(0, droop * len * .5);
  Offset mid(double t) {
    final u = 1 - t;
    return base * (u * u) + ctl * (2 * u * t) + tip * (t * t);
  }

  Offset normal(double t) {
    final d = (ctl - base) * (2 * (1 - t)) + (tip - ctl) * (2 * t);
    return Offset(-d.dy, d.dx) / d.distance;
  }

  double half(double t) => w * .5 * math.pow(math.sin(math.pi * t), .6) + .3;
  final left = <Offset>[], right = <Offset>[];
  for (var i = 0; i <= 16; i++) {
    final t = i / 16, m = mid(t), n = normal(t);
    left.add(m + n * half(t));
    right.add(m - n * half(t) * .92);
  }
  p.fill(Path()..addPolygon([...left, ...right.reversed], true), tone);
  // The far half in shade, so the blade folds along its midrib.
  p.fill(
    Path()..addPolygon([
      for (var i = 0; i <= 16; i++) mid(i / 16),
      ...right.reversed,
    ], true),
    (Color.lerp(tone.$1, const Color(0xFF1E4A22), .25)!, tone.$2),
  );
  final rib = Path()..moveTo(base.dx, base.dy);
  for (var i = 1; i <= 16; i++) {
    final m = mid(i / 16);
    rib.lineTo(m.dx, m.dy);
  }
  p.stroke(rib, const Color(0x99EAF6C8), 1.1);
  for (var t = .18; t < .9; t += .08 + r() * .06) {
    final side = r() < .5 ? 1.0 : -1.0;
    final m = mid(t), n = normal(t);
    p.line(
      m + n * side * 1.5,
      m + n * side * half(t) * (.75 + r() * .25),
      const Color(0xB3F8FBF0),
      .7,
    );
  }
}

void _banana(_Pen p) {
  final rnd = _rng(113);
  p.ground(100, 182, 58);
  const stem = (Color(0xFFB8D47A), Color(0xFF6E9A44));
  p
    ..fill(_taper(98, 184, 100, 92, 13, 9, 2), stem, across: true)
    ..fill(_taper(124, 184, 126, 146, 7, 5, -2), stem, across: true);
  _paddle(p, const Offset(100, 96), -2.5, 66, 26, _bananaTones[1], 1131);
  _paddle(p, const Offset(100, 96), -.6, 68, 26, _bananaTones[0], 1132);
  _paddle(
    p,
    const Offset(100, 94),
    -1.7,
    58,
    22,
    _bananaTones[3],
    1133,
    droop: .1,
  );
  _paddle(p, const Offset(98, 104), 2.2, 48, 16, (
    const Color(0xFFC9A860),
    const Color(0xFF8E7238),
  ), 1134);
  p.stroke(
    Path()
      ..moveTo(104, 100)
      ..quadraticBezierTo(124, 104, 126, 118),
    const Color(0xFF6E9A44),
    2.4,
  );
  for (var row = 0; row < 3; row++) {
    for (var i = 0; i < 5; i++) {
      final x = 116 + i * 4.4 - row * .8, y = 118 + row * 8.0;
      p.fill(_leaf(x, y + 6, -1.75 + (i - 2) * .12, 12, 4.6), (
        const Color(0xFFC8E07A),
        const Color(0xFF7EA440),
      ));
    }
  }
  p
    ..fill(
      Path()
        ..moveTo(126, 146)
        ..quadraticBezierTo(118, 152, 126, 164)
        ..quadraticBezierTo(134, 152, 126, 146)
        ..close(),
      (const Color(0xFFB0507E), const Color(0xFF5E2040)),
    )
    ..stroke(
      Path()
        ..moveTo(126, 140)
        ..lineTo(126, 147),
      const Color(0xFF6E9A44),
      1.6,
    );
  _paddle(p, const Offset(100, 98), .1, 52, 18, _bananaTones[2], 1135);
  _paddle(p, const Offset(124, 150), -2.2, 30, 11, _bananaTones[2], 1136);
  p.spots.addAll(const [
    Offset(64, 64),
    Offset(140, 66),
    Offset(96, 50),
    Offset(140, 96),
  ]);
  p.tuft(76, 184, .9, rnd, _bananaTones.sublist(1));
}

// ——— Bamboo (Vietnam): a clump of jointed culms leaning a little apart,
// sprays of narrow leaves, and new shoots at the foot.

const _bambooTones = [
  (Color(0xFF3E7A3A), Color(0xFF346A32)),
  (Color(0xFF529648), Color(0xFF46863E)),
  (Color(0xFF72B258), Color(0xFF62A24E)),
  (Color(0xFF9CCF74), Color(0xFF88C266)),
  (Color(0xFFC6E69C), Color(0xFFB2DA88)),
];

void _bamboo(_Pen p) {
  final rnd = _rng(127);
  p.ground(100, 182, 50);
  const culms = [
    (82.0, 40.0, -10.0, 6.0),
    (92.0, 22.0, -4.0, 7.0),
    (102.0, 30.0, 2.0, 6.5),
    (110.0, 18.0, 6.0, 7.0),
    (120.0, 44.0, 12.0, 6.0),
    (74.0, 66.0, -16.0, 5.0),
    (128.0, 62.0, 18.0, 5.0),
  ];
  for (final (x, top, lean, w) in culms) {
    final x2 = x + lean;
    p.fill(_taper(x, 184, x2, top, w, w * .8, lean * .2), (
      const Color(0xFFB6D670),
      const Color(0xFF5E8E36),
    ), across: true);
    for (var y = 172.0; y > top + 6; y -= 15 + rnd() * 3) {
      final t = (184 - y) / (184 - top), cx = x + lean * t;
      p
        ..line(
          Offset(cx - w * .5, y),
          Offset(cx + w * .5, y),
          const Color(0xFF4E7A2E),
          1.4,
        )
        ..line(
          Offset(cx - w * .45, y - 1.4),
          Offset(cx + w * .45, y - 1.4),
          const Color(0x80E8F4C0),
          .8,
        );
    }
  }
  for (final (x, top, lean, _) in culms) {
    for (var k = 0; k < 3; k++) {
      final y = top + 10 + k * 22 + rnd() * 6;
      if (y > 140) break;
      final t = (184 - y) / (184 - top), cx = x + lean * t;
      final side = k.isEven ? -1 : 1;
      p.spots.add(Offset(cx + side * 8, y));
      for (var i = 0; i < 5; i++) {
        final a =
            (side < 0 ? math.pi : 0) +
            side * (-.5 + i * .28) +
            (rnd() - .5) * .2;
        final light = side < 0 ? .35 - i * .1 : -.1 - i * .1;
        p.fill(
          _needle(
            cx,
            y,
            a + _angDiff(math.pi / 2, a) * .25,
            15 + rnd() * 6,
            4.2,
          ),
          _bambooTones[_toneOf(light + (110 - y) / 120, _bambooTones.length)],
        );
      }
    }
  }
  for (final x in const [70.0, 134.0]) {
    p.fill(
      Path()
        ..moveTo(x - 4, 185)
        ..quadraticBezierTo(x - 3, 176, x, 168)
        ..quadraticBezierTo(x + 3, 176, x + 4, 185)
        ..close(),
      (const Color(0xFFC9B07A), const Color(0xFF7E6A3E)),
      across: true,
    );
  }
}

// ——— Saguaro cactus (Mexico): a ribbed column with two raised arms, pink
// flowers on top, a small barrel cactus and pebbles on sand.

const _cactusSkin = (Color(0xFF8ED096), Color(0xFF2E7E52));

void _cactus(_Pen p) {
  final rnd = _rng(131);
  p.c.drawOval(
    Rect.fromCenter(center: const Offset(100, 184), width: 120, height: 16),
    Paint()
      ..shader = ui.Gradient.radial(const Offset(100, 184), 60, const [
        Color(0xFFF2DCB0),
        Color(0x00F2DCB0),
      ]),
  );
  p.ground(100, 184, 40);
  Path column(double x, double top, double bottom, double w) => Path()
    ..moveTo(x - w / 2, bottom)
    ..lineTo(x - w / 2, top + w / 2)
    ..arcToPoint(Offset(x + w / 2, top + w / 2), radius: Radius.circular(w / 2))
    ..lineTo(x + w / 2, bottom)
    ..close();
  Path arm(double x0, double y0, double x1, double top, double w) {
    final s = x1 > x0 ? 1 : -1;
    return Path()
      ..moveTo(x0, y0 - w / 2)
      ..lineTo(x1 - s * w / 2, y0 - w / 2)
      ..lineTo(x1 - s * w / 2, top + w / 2)
      ..arcToPoint(
        Offset(x1 + s * w / 2, top + w / 2),
        radius: Radius.circular(w / 2),
        clockwise: s > 0,
      )
      ..lineTo(x1 + s * w / 2, y0 + w / 2 + 6)
      ..quadraticBezierTo(
        x1 + s * w / 2,
        y0 + w / 2 + 12,
        x1 - s * 4,
        y0 + w / 2 + 12,
      )
      ..lineTo(x0, y0 + w / 2 + 12)
      ..close();
  }

  p
    ..fill(arm(100, 118, 72, 92, 13), _cactusSkin, across: true)
    ..fill(arm(100, 102, 128, 74, 13), _cactusSkin, across: true)
    ..fill(column(100, 50, 184, 24), _cactusSkin, across: true);
  for (final (x, top, w) in const [
    (72.0, 92.0, 13.0),
    (128.0, 74.0, 13.0),
    (100.0, 50.0, 24.0),
  ]) {
    for (var k = -1; k <= 1; k++) {
      p.line(
        Offset(x + k * w * .28, top + w * .4),
        Offset(x + k * w * .28, x == 100 ? 182 : top + 34),
        k < 0 ? const Color(0x66E8F8E0) : const Color(0x4D1E5E3A),
        1,
      );
    }
  }
  for (var i = 0; i < 40; i++) {
    final x = 90 + rnd() * 20, y = 58 + rnd() * 120;
    p.dot(x, y, .7, const Color(0xFFF6F2D8));
  }
  for (final (x, y, r) in const [
    (96.0, 50.0, 6.0),
    (106.0, 52.0, 5.0),
    (128.0, 74.0, 4.5),
  ]) {
    p.flower(
      x,
      y - 2,
      r,
      const Color(0xFFFF8FB4),
      const Color(0xFFFFE07A),
      x / 10,
      edge: const Color(0xFFE0608E),
    );
    p.spots.add(Offset(x, y - 4));
  }
  p.ball(
    140,
    176,
    9,
    const Color(0xFFA6DCA8),
    const Color(0xFF4E9A62),
    const Color(0xFF2E6E44),
  );
  p.flower(140, 167, 3.4, const Color(0xFFFFD84A), const Color(0xFFE46A2E), 1);
  for (final (x, y, r) in const [
    (66.0, 184.0, 3.4),
    (74.0, 186.0, 2.2),
    (156.0, 185.0, 2.6),
  ]) {
    p.ball(
      x,
      y,
      r,
      const Color(0xFFE8E2D8),
      const Color(0xFFB4AA9A),
      const Color(0xFF8A806E),
    );
  }
}

// ——— Fly agaric (Finland): a red cap with white warts on a ringed stem, two
// young ones beside it, and moss.

void _cap(
  _Pen p,
  double x,
  double y,
  double rx,
  double ry,
  int seed, {
  bool warts = true,
}) {
  final r = _rng(seed);
  p
    ..oval(x, y + ry * .1, rx * .92, ry * .24, const Color(0xFFF2E2C8))
    ..fill(
      Path()
        ..moveTo(x - rx, y + ry * .15)
        ..cubicTo(
          x - rx,
          y - ry * 1.15,
          x + rx,
          y - ry * 1.15,
          x + rx,
          y + ry * .15,
        )
        ..quadraticBezierTo(x, y + ry * .45, x - rx, y + ry * .15)
        ..close(),
      (const Color(0xFFFF7A60), const Color(0xFFB8261C)),
    );
  if (!warts) return;
  for (var i = 0; i < (rx * .7).round(); i++) {
    final a = math.pi + r() * math.pi, d = math.sqrt(r()) * .82;
    final wx = x + math.cos(a) * rx * d,
        wy = y - math.sin(a).abs() * ry * d * .9;
    final s = 1.2 + r() * rx * .06;
    p
      ..oval(wx + .4, wy + .6, s * 1.1, s * .8, const Color(0x40801A10))
      ..oval(wx, wy, s, s * .75, const Color(0xFFFFF6EA));
  }
}

void _mushroom(_Pen p) {
  final rnd = _rng(137);
  p.ground(100, 183, 52);
  const stem = (Color(0xFFFFF8EC), Color(0xFFD8C4A4));
  p.clump(
    x: 100,
    y: 182,
    r: 30,
    n: 60,
    len: 5,
    w: 3,
    shape: _Shape.round,
    tones: const [
      (Color(0xFF4E7A36), Color(0xFF426A2E)),
      (Color(0xFF6E9A44), Color(0xFF5E8A3A)),
      (Color(0xFF94BE5E), Color(0xFF82AE52)),
    ],
    seed: 1371,
    squash: .18,
    droop: 0,
    spot: false,
  );
  p
    ..fill(_taper(132, 184, 133, 158, 7, 6), stem, across: true)
    ..fill(_taper(70, 185, 69, 168, 6, 5), stem, across: true);
  _cap(p, 133, 158, 15, 13, 1372);
  _cap(p, 69, 168, 9, 11, 1373, warts: false);
  p.fill(_taper(100, 184, 100, 112, 18, 13, 2), stem, across: true);
  p.fill(
    Path()
      ..moveTo(90, 136)
      ..quadraticBezierTo(100, 132, 110, 136)
      ..lineTo(113, 146)
      ..quadraticBezierTo(100, 150, 87, 146)
      ..close(),
    (const Color(0xFFFFFBF2), const Color(0xFFD8C4A4)),
    down: true,
  );
  _cap(p, 100, 110, 42, 40, 1374);
  p.spots.addAll(const [Offset(84, 88), Offset(112, 84), Offset(133, 148)]);
  p.fill(_leaf(150, 186, 2.9, 12, 7), (
    const Color(0xFFE0A84A),
    const Color(0xFFB8762E),
  ));
  p.tuft(56, 184, .8, rnd, const [
    (Color(0xFF6E9A44), Color(0xFF5E8A3A)),
    (Color(0xFF94BE5E), Color(0xFF82AE52)),
  ]);
}

/// Every species' drawing. Ids match `species` and never change.
const _arts = <String, _Art>{
  'oak': _Art(_oak, tones: _oakTones),
  'pine': _Art(
    _pine,
    tones: _pineTones,
    young: _Young.conifer,
    bark: _pineBark,
    stiff: .6,
  ),
  'sunflower': _Art(
    _sunflower,
    tones: _sunLeaf,
    young: _Young.small,
    stiff: 1.4,
  ),
  'tulip': _Art(_tulip, tones: _tulipLeaf, young: _Young.small, stiff: 1.4),
  'cherry': _Art(_cherry, tones: _cherryTones, bark: _cherryBark),
  'apple': _Art(_apple, tones: _appleTones),
  'orange': _Art(_orange, tones: _orangeTones),
  'maple': _Art(_maple, tones: _mapleTones),
  'birch': _Art(_birch, tones: _birchTones, bark: _birchBark, stiff: 1.3),
  'ginkgo': _Art(_ginkgo, tones: _ginkgoTones),
  'willow': _Art(_willow, tones: _willowTones, stiff: 1.4),
  'lavender': _Art(_lavender, tones: _lavLeaf, young: _Young.small, stiff: 1.5),
  'mushroom': _Art(_mushroom, tones: _bangTones, young: _Young.small, stiff: 0),
  'cactus': _Art(_cactus, tones: _junTones, young: _Young.small, stiff: 0),
  'bonsai': _Art(_bonsai, tones: _junTones, young: _Young.small, stiff: .3),
  'baobab': _Art(_baobab, tones: _baobabTones, bark: _baobabBark, stiff: .4),
  'wisteria': _Art(_wisteria, tones: _wisteriaTones, bark: _wisteriaBark),
  'bamboo': _Art(_bamboo, tones: _bambooTones, young: _Young.small, stiff: 1.5),
  'coconut': _Art(
    _coconut,
    tones: _palmTones,
    young: _Young.palm,
    bark: _palmBark,
  ),
  'banana': _Art(_banana, tones: _bananaTones, young: _Young.palm, stiff: 1.2),
  'phuong': _Art(_phuong, tones: _fernTones),
  'bang': _Art(_bang, tones: _bangTones),
  'mai': _Art(_mai, tones: _maiTones, bark: _maiBark),
  'dao': _Art(_dao, tones: _maiTones, bark: _daoBark),
  'lotus': _Art(_lotus, tones: _padTones, young: _Young.small, stiff: .8),
  'banyan': _Art(_banyan, tones: _banyanTones, bark: _banyanBark, stiff: .4),
  'snowpine': _Art(
    _snowpine,
    tones: _firTones,
    young: _Young.conifer,
    stiff: .5,
  ),
  'galaxy': _Art(
    _galaxy,
    tones: _galaxyTones,
    bark: (Color(0xFFF0EEFF), Color(0xFF9E98D8)),
  ),
  'olive': _Art(_olive, tones: _oliveTones, bark: _oliveBark),
  'mugunghwa': _Art(_mugunghwa, tones: _mugTones),
};

// Young leaves for the blossom trees, before their flowers.
const _maiTones = [
  (Color(0xFF6E8A2E), Color(0xFF5A7424)),
  (Color(0xFF8DA83E), Color(0xFF728C30)),
  (Color(0xFFB5CC5C), Color(0xFF98B448)),
];
