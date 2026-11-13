part of 'garden_art.dart';

// The 28 species, ported from the mockup. Each draws itself fully grown in
// the 100-unit box; `_tree` scales it for younger forms.

class _Art {
  final void Function(_Ctx x, _Env e) draw;

  /// Woody trees show a staked sapling before they fill out.
  final bool wood;
  final _Tone tone;
  final _Bark bark;

  /// How much the wind leans the whole plant, and how big its shadow is.
  final double stiff, shadow;

  /// Where blooms open when a focus tree flowers.
  final List<Offset> spots;
  const _Art(
    this.draw, {
    this.wood = false,
    this.tone = _green,
    this.bark = _bark,
    this.stiff = 1,
    this.shadow = 1,
    this.spots = _spots,
  });
}

const _spots = [
  Offset(-17, -50),
  Offset(15, -56),
  Offset(0, -74),
  Offset(9, -42),
  Offset(-8, -62),
];
const _round = [
  [-25.0, -48.0, 14.0],
  [25.0, -50.0, 15.0],
  [-11.0, -39.0, 12.0],
  [13.0, -38.0, 12.0],
  [-15.0, -64.0, 14.0],
  [16.0, -66.0, 14.0],
  [0.0, -58.0, 19.0],
  [0.0, -79.0, 13.0],
];

void _forks(_Ctx x, _Bark k) {
  _limb(x, _o(0, -28), _o(-9, -36), _o(-16, -47), 4.6, k);
  _limb(x, _o(0, -28), _o(9, -37), _o(16, -49), 4.6, k);
}

final Map<String, _Art> _arts = {
  'oak': const _Art(_oak, wood: true),
  'pine': const _Art(
    _pine,
    tone: _deep,
    stiff: .6,
    spots: [
      Offset(-14, -22),
      Offset(12, -36),
      Offset(-8, -50),
      Offset(6, -64),
      Offset(0, -82),
    ],
  ),
  'sunflower': const _Art(
    _sunflower,
    spots: [Offset(-24, -4), Offset(22, -3), Offset(12, -6), Offset(-8, -3)],
  ),
  'tulip': const _Art(
    _tulip,
    spots: [Offset(-26, -3), Offset(26, -3), Offset(-4, -4)],
  ),
  'cherry': const _Art(_cherry, wood: true, tone: _pink, bark: _barkD),
  'apple': const _Art(_apple, wood: true),
  'orange': const _Art(_orange, wood: true, tone: _deep),
  'maple': const _Art(_maple, wood: true, tone: _fire),
  'birch': const _Art(_birchTree, wood: true, tone: _lime, bark: _birch),
  'ginkgo': const _Art(_ginkgo, wood: true, tone: _gold),
  'willow': const _Art(_willow, wood: true, tone: _lime),
  'lavender': const _Art(
    _lavender,
    spots: [Offset(-28, -3), Offset(28, -3), Offset(0, -5)],
  ),
  'mushroom': const _Art(
    _mushroom,
    stiff: .4,
    spots: [Offset(-28, -3), Offset(26, -3), Offset(4, -5)],
  ),
  'cactus': const _Art(
    _cactus,
    stiff: .3,
    spots: [Offset(-23, -50), Offset(24, -62), Offset(0, -70)],
  ),
  'bonsai': const _Art(
    _bonsai,
    stiff: .4,
    spots: [
      Offset(-26, -48),
      Offset(26, -58),
      Offset(-4, -76),
      Offset(12, -66),
    ],
  ),
  'baobab': const _Art(
    _baobab,
    stiff: .3,
    shadow: 1.2,
    spots: [
      Offset(-24, -74),
      Offset(-8, -84),
      Offset(12, -84),
      Offset(27, -74),
    ],
  ),
  'wisteria': const _Art(
    _wisteria,
    stiff: .5,
    shadow: 1.2,
    spots: [
      Offset(-30, -66),
      Offset(-12, -74),
      Offset(8, -75),
      Offset(28, -67),
    ],
  ),
  'bamboo': const _Art(
    _bamboo,
    spots: [
      Offset(-22, -40),
      Offset(12, -74),
      Offset(22, -48),
      Offset(-6, -22),
    ],
  ),
  'coconut': const _Art(
    _coconut,
    stiff: .8,
    spots: [Offset(8, -78), Offset(-12, -62), Offset(24, -64)],
  ),
  'banana': const _Art(
    _banana,
    shadow: 1.1,
    spots: [Offset(-26, -60), Offset(24, -64), Offset(0, -84)],
  ),
  'phuong': const _Art(_phuong, wood: true, tone: _red, shadow: 1.3),
  'bang': const _Art(
    _bang,
    shadow: 1.2,
    stiff: .7,
    spots: [
      Offset(-22, -42),
      Offset(20, -44),
      Offset(-14, -60),
      Offset(12, -62),
      Offset(0, -80),
    ],
  ),
  'mai': const _Art(_mai, shadow: 1.1),
  'dao': const _Art(_dao, shadow: 1.1),
  'lotus': const _Art(
    _lotus,
    shadow: 0,
    stiff: 0,
    spots: [Offset(-30, -2), Offset(30, -2)],
  ),
  'banyan': const _Art(
    _banyan,
    wood: true,
    tone: _deep,
    shadow: 1.6,
    stiff: .5,
  ),
  'snowpine': const _Art(
    _snowpine,
    stiff: .6,
    spots: [
      Offset(-14, -22),
      Offset(12, -36),
      Offset(-8, -50),
      Offset(6, -64),
      Offset(0, -82),
    ],
  ),
  'galaxy': const _Art(_galaxy, wood: true, tone: _cosmos),
};

void _oak(_Ctx x, _Env e) {
  _trunk(x, 38, 13, _bark);
  _forks(x, _bark);
  _ell(x, 1.5, -16, 2, 3, 0, _a(_bark.d, .85));
  _canopy(x, _round, _green, e, 11);
  final nuts = [_o(-20, -41), _o(9, -47), _o(22, -39)];
  for (var i = 0; i < nuts.length; i++) {
    final sx = nuts[i].dx + e.w * 2.2,
        sy = nuts[i].dy + math.sin(e.t * 2 + i) * .6;
    _ell(x, sx, sy, 2.4, 3.1, 0, const Color(0xFFC98A4B));
    _ell(x, sx, sy - 2.4, 2.8, 1.7, 0, const Color(0xFF7A4A22));
    _dot(x, sx - .8, sy - .3, .7, _white(.5));
  }
  _bird(
    x,
    -15 + e.w * 3,
    -78,
    e.t,
    const Color(0xFF5B8DEF),
    const Color(0xFF3B6BD6),
    1,
  );
}

void _tier(_Ctx x, double by, double w, double hh, Object f) {
  x
    ..begin()
    ..moveTo(0, by - hh)
    ..quad(w * .16, by - hh * .45, w / 2, by);
  for (var i = 0; i < 4; i++) {
    final x1 = w / 2 - (i + 1) * w / 4;
    x.quad(x1 + w / 8, by + w * .12, x1, by);
  }
  x
    ..quad(-w * .16, by - hh * .45, 0, by - hh)
    ..close()
    ..fill(f);
}

void _conifer(_Ctx x, _Env e, _Tone c, bool snow) {
  _trunk(x, 17, 9, _bark);
  for (var i = 0; i < 5; i++) {
    final by = -11 - i * 15.5, w = 58 - i * 10.5;
    const hh = 29.0;
    x
      ..save()
      ..translate(e.w * i * .8, 0)
      ..save()
      ..translate(2.5, 3.5);
    _tier(x, by, w, hh, c.u);
    x.restore();
    _tier(x, by, w, hh, _lg(-w / 2, 0, w / 2, 0, [c.l, c.m, c.d]));
    for (var k = 0; k < 4; k++) {
      final tx = -w * .3 + k * w * .2;
      _line(
        x,
        [_o(tx, by - 3), _o(tx + (k < 2 ? -2 : 2), by - 8)],
        .9,
        k < 2 ? c.hf : c.uf,
      );
    }
    if (snow) {
      _tier(
        x,
        by - hh * .36,
        w * .62,
        hh * .64,
        _lg(-w / 2, 0, w / 2, 0, const [
          Color(0xFFFFFFFF),
          Color(0xFFF2F7FD),
          Color(0xFFC9D9EE),
        ]),
      );
    }
    x.restore();
  }
  if (!snow) {
    for (final q in [_o(-13, -21), _o(11, -36), _o(-7, -52)]) {
      _ell(x, q.dx, q.dy, 2, 3, .2, const Color(0xFF8A5A33));
      _line(
        x,
        [_o(q.dx - 1.4, q.dy - .6), _o(q.dx + 1.4, q.dy - .6)],
        .5,
        const Color(0xFF5F3A1D),
      );
    }
  }
}

void _pine(_Ctx x, _Env e) => _conifer(x, e, _deep, false);

void _snowpine(_Ctx x, _Env e) {
  _ell(x, 0, 1, 26, 5, 0, const Color(0xFFEEF4FB));
  _ell(x, -5, 0, 12, 2.4, 0, Colors.white);
  _conifer(
    x,
    e,
    const _Tone(
      Color(0xFF12514A),
      Color(0xFF1B7466),
      Color(0xFF2A9C84),
      Color(0xFF74D9BE),
      Color(0xFFC8F5E6),
    ),
    true,
  );
  _fall(
    x,
    e.t,
    12,
    const [-42, 36, -104, 2],
    (i) => _dot(x, 0, 0, i % 3 != 0 ? 1.1 : 1.7, _white(.95)),
    .1,
  );
}

void _sunhead(_Ctx x, double a, double b, double r, double t) {
  for (var k = 0; k < 2; k++) {
    for (var i = 0; i < 16; i++) {
      final g = i * _tau / 16 + k * _tau / 32 + math.sin(t * .8) * .06,
          rr = r * (1.55 - k * .14);
      _ell(
        x,
        a + math.cos(g) * rr,
        b + math.sin(g) * rr,
        r * .85,
        r * .34,
        g,
        k == 1 ? const Color(0xFFFFD43B) : const Color(0xFFF59F00),
      );
    }
  }
  _fruit(x, a, b, r, const [
    Color(0xFFB07A47),
    Color(0xFF6E4424),
    Color(0xFF472A12),
  ]);
  for (var i = 1; i < 13; i++) {
    final g = i * 2.4, rr = r * .24 * math.sqrt(i);
    _dot(
      x,
      a + math.cos(g) * rr,
      b + math.sin(g) * rr,
      r * .07,
      const Color.fromRGBO(255, 220, 150, .6),
    );
  }
}

void _sunflower(_Ctx x, _Env e) {
  final w = e.w;
  _stem(x, _o(-13, 0), _o(-18 + w, -20), _o(-13 + w * 2, -40), 3, _stemG);
  _stem(x, _o(3, 0), _o(9 + w, -32), _o(2 + w * 3, -64), 4.5, _stemG);
  _leaf(x, 5, -20, 18, 6.5, -.5 + w * .05, _leafG, _leafD);
  _leaf(x, 5, -36, 17, 6, math.pi + .5, _leafM, _leafD);
  _leaf(x, -15, -14, 11, 4.5, math.pi + .4, _leafG, _leafD);
  _leaf(x, -15, -25, 10, 4, -.5, _leafM, _leafD);
  _sunhead(x, -13 + w * 2, -43, 5.5, e.t + 1);
  _sunhead(x, 2 + w * 3, -68, 9, e.t);
  _bee(x, 17, -62, e.t, 0);
}

void _tulip(_Ctx x, _Env e) {
  const cols = [
    [Color(0xFFFF8787), Color(0xFFE03131)],
    [Color(0xFFFFE066), Color(0xFFF59F00)],
    [Color(0xFFFFA8C5), Color(0xFFE64980)],
    [Color(0xFFC3B1FF), Color(0xFF7950F2)],
    [Color(0xFFFFFFFF), Color(0xFFCDD6E2)],
  ];
  const stems = [
    [-17.0, 30.0],
    [-8.0, 43.0],
    [2.0, 52.0],
    [12.0, 39.0],
    [20.0, 28.0],
  ];
  for (var i = 0; i < stems.length; i++) {
    final s = stems[i],
        sw = e.w * 3 + math.sin(e.t * 1.5 + i) * .8,
        tx = s[0] + sw,
        ty = -s[1],
        c = cols[i];
    _leaf(x, s[0], 0, s[1] * .62, 3.6, -1.5708 - .36, _leafG, _leafD);
    _leaf(x, s[0], 0, s[1] * .56, 3.3, -1.5708 + .4, _leafM, _leafD);
    _stem(x, _o(s[0], 0), _o(s[0], ty * .5), _o(tx, ty), 1.7, _stemG);
    x
      ..save()
      ..translate(tx, ty)
      ..rotate(sw * .03)
      ..begin()
      ..moveTo(-4.4, -1)
      ..quad(-5.6, -8, -3.2, -11.5)
      ..lineTo(-1.3, -7.8)
      ..lineTo(0, -12)
      ..lineTo(1.3, -7.8)
      ..lineTo(3.2, -11.5)
      ..quad(5.6, -8, 4.4, -1)
      ..quad(0, 3, -4.4, -1)
      ..close()
      ..fill(_lg(-5, 0, 5, 0, [c[0], c[0], c[1]]));
    _ell(x, -2, -5, 1, 3, .1, _white(.45));
    x.restore();
  }
  _butterfly(
    x,
    -6,
    -64,
    e.t,
    const Color(0xFF74C0FC),
    const Color(0xFF4DABF7),
    3,
    .8,
  );
}

void _cherry(_Ctx x, _Env e) {
  _trunk(x, 38, 10, _barkD, 7);
  _limb(x, _o(5, -30), _o(-4, -38), _o(-12, -47), 3.6, _barkD);
  _limb(x, _o(6, -34), _o(16, -38), _o(25, -45), 3.6, _barkD);
  _canopy(
    x,
    const [
      [-19, -50, 14],
      [28, -49, 13],
      [-5, -43, 12],
      [37, -39, 9],
      [-12, -65, 13],
      [23, -66, 13],
      [6, -61, 18],
      [5, -80, 11],
    ],
    _pink,
    e,
    5,
  );
  final fl = [
    _o(-17, -55),
    _o(9, -72),
    _o(28, -54),
    _o(0, -50),
    _o(19, -76),
    _o(-8, -70),
  ];
  for (var i = 0; i < fl.length; i++) {
    _blossom(
      x,
      fl[i].dx + e.w * 2.6,
      fl[i].dy,
      3,
      const Color(0xFFFFF7FA),
      const Color(0xFFFF8FB8),
      i.toDouble(),
    );
  }
  _fall(
    x,
    e.t,
    7,
    const [-34, 40, -58, 2],
    (i) => _ell(
      x,
      0,
      0,
      2.6,
      1.5,
      0,
      i.isOdd ? const Color(0xFFFFB3CF) : const Color(0xFFFFDCE9),
    ),
  );
}

void _apple(_Ctx x, _Env e) {
  _trunk(x, 36, 12, _bark);
  _forks(x, _bark);
  _canopy(x, _round, _green, e, 20);
  const fr = [Color(0xFFFFB3A7), Color(0xFFF03E3E), Color(0xFFB02525)];
  final ap = [
    _o(-21, -44),
    _o(-6, -57),
    _o(11, -46),
    _o(3, -74),
    _o(-13, -70),
    _o(-2, -40),
  ];
  for (var i = 0; i < ap.length; i++) {
    final px = ap[i].dx + e.w * 2.4,
        py = ap[i].dy + math.sin(e.t * 1.8 + i) * .5;
    _fruit(x, px, py, 4.4, fr);
    _leaf(x, px, py - 4, 4.4, 1.6, -.5, _leafD);
  }
  final u = (e.t * .2) % 1;
  var ay = -52.0, rot = 0.0;
  if (u > .5) {
    final v = math.min(1.0, (u - .5) / .13);
    ay = -52 + 51 * v * v;
    if (u > .63) {
      final b = math.min(1.0, (u - .63) / .1);
      ay = -1 - math.sin(b * math.pi) * 5;
      rot = b * .8;
    }
  }
  x
    ..save()
    ..alpha *= u > .9 ? (1 - u) / .1 : (u < .06 ? u / .06 : 1)
    ..translate(22 + (u > .5 ? 0 : e.w * 2.4) + rot * 6, ay)
    ..rotate(rot);
  _fruit(x, 0, 0, 4.4, fr);
  _leaf(x, 0, -4, 4.4, 1.6, -.5, _leafD);
  x.restore();
}

void _orange(_Ctx x, _Env e) {
  _trunk(x, 34, 11, _bark);
  _forks(x, _bark);
  _canopy(
    x,
    const [
      [-22, -46, 14],
      [22, -47, 15],
      [-9, -38, 12],
      [11, -38, 12],
      [-14, -62, 14],
      [15, -63, 14],
      [0, -55, 19],
      [0, -76, 13],
    ],
    _deep,
    e,
    6,
  );
  final fr = [
    _o(-21, -43),
    _o(-7, -56),
    _o(10, -45),
    _o(21, -58),
    _o(3, -73),
    _o(-13, -69),
    _o(15, -36),
    _o(-2, -40),
  ];
  for (var i = 0; i < fr.length; i++) {
    final px = fr[i].dx + e.w * 2.4,
        py = fr[i].dy + math.sin(e.t * 1.8 + i) * .5;
    _fruit(x, px, py, 4.4, const [
      Color(0xFFFFD9A0),
      Color(0xFFFF9A2E),
      Color(0xFFD9660A),
    ]);
    _leaf(x, px, py - 4, 4.2, 1.5, -.5, const Color(0xFF1F8450));
  }
  final fl = [_o(-16, -56), _o(8, -64), _o(18, -48)];
  for (var i = 0; i < fl.length; i++) {
    _blossom(
      x,
      fl[i].dx + e.w * 2.4,
      fl[i].dy,
      2,
      Colors.white,
      const Color(0xFFFFE066),
      i.toDouble(),
    );
  }
}

void _maple(_Ctx x, _Env e) {
  _trunk(x, 34, 11, _barkD);
  _forks(x, _barkD);
  _canopy(
    x,
    const [
      [-25, -46, 14],
      [25, -48, 14],
      [-10, -39, 12],
      [12, -39, 12],
      [-13, -61, 15],
      [15, -63, 15],
      [0, -54, 17],
      [0, -77, 14],
    ],
    _fire,
    e,
    7,
  );
  final lv = [
    _o(-25, -56),
    _o(26, -60),
    _o(0, -90),
    _o(-9, -44),
    _o(15, -42),
    _o(-2, -66),
  ];
  for (var i = 0; i < lv.length; i++) {
    x
      ..save()
      ..translate(lv[i].dx + e.w * 2.6, lv[i].dy)
      ..rotate(i + math.sin(e.t + i) * .2);
    _mleaf(x, 4.4, i.isOdd ? const Color(0xFFE03A1E) : const Color(0xFFFFD166));
    x.restore();
  }
  _fall(
    x,
    e.t,
    6,
    const [-34, 36, -52, 2],
    (i) => _mleaf(
      x,
      3,
      i.isOdd ? const Color(0xFFF2683A) : const Color(0xFFFFB347),
    ),
    .12,
  );
}

void _marks(_Ctx x, double h, double s) {
  var i = 0;
  for (var y = 9.0; y < h - 4; y += 8, i++) {
    final d = i.isOdd ? 1 : -1;
    _line(
      x,
      [_o(d * s * .1, -y), _o(d * s * .42, -y - .6)],
      1.3,
      const Color(0xFF4B4A48),
    );
  }
}

void _birchTree(_Ctx x, _Env e) {
  x
    ..save()
    ..translate(-14, 0);
  _trunk(x, 44, 6, _birch);
  _marks(x, 44, 6);
  _canopy(
    x,
    const [
      [-8, -43, 9],
      [8, -46, 9],
      [0, -55, 10],
      [0, -64, 7],
    ],
    _lime,
    e,
    3,
  );
  x
    ..restore()
    ..save()
    ..translate(6, 0);
  _trunk(x, 66, 8, _birch);
  _marks(x, 66, 8);
  _limb(x, _o(0, -44), _o(-6, -50), _o(-11, -55), 2.4, _birch);
  _limb(x, _o(0, -48), _o(6, -54), _o(11, -59), 2.4, _birch);
  _canopy(
    x,
    const [
      [-14, -58, 11],
      [14, -61, 11],
      [0, -51, 10],
      [-8, -74, 12],
      [9, -76, 12],
      [0, -66, 11],
      [0, -90, 10],
    ],
    _lime,
    e,
    4,
  );
  x.restore();
}

void _ginkgo(_Ctx x, _Env e) {
  _trunk(x, 40, 10, _barkD);
  _limb(x, _o(0, -32), _o(-7, -40), _o(-12, -48), 3.6, _barkD);
  _limb(x, _o(0, -32), _o(7, -40), _o(12, -50), 3.6, _barkD);
  _canopy(
    x,
    const [
      [-18, -48, 12],
      [18, -50, 12],
      [0, -42, 11],
      [-12, -63, 13],
      [13, -65, 13],
      [0, -56, 15],
      [-6, -78, 12],
      [7, -80, 12],
      [0, -92, 9],
    ],
    _gold,
    e,
    24,
  );
  _fall(
    x,
    e.t,
    7,
    const [-30, 32, -56, 2],
    (i) => _fan(
      x,
      2.8,
      i.isOdd ? const Color(0xFFF4CC3F) : const Color(0xFFFFE066),
    ),
    .12,
  );
}

void _willow(_Ctx x, _Env e) {
  const c = _lime;
  _trunk(x, 44, 12, _bark);
  _canopy(
    x,
    const [
      [-20, -52, 14],
      [20, -52, 14],
      [0, -62, 21],
    ],
    c,
    e,
    2,
  );
  for (var i = -7; i <= 7; i++) {
    final len = 46 - i.abs() * 3.0,
        x0 = i * 5.0,
        sw = e.w * 5 + math.sin(e.t * 1.5 + i * .8) * 1.5;
    final a = _o(x0, -58 + i.abs() * 1.1),
        m = _o(x0 * 1.2, a.dy + len * .4),
        b = _o(x0 * 1.28 + sw, a.dy + len);
    _curve(x, a, m, b, 1.2, i.isOdd ? c.m : c.d);
    for (var k = 1; k <= 6; k++) {
      final p = _qpt(a, m, b, k / 6);
      _leaf(
        x,
        p.dx,
        p.dy,
        4.6,
        1.4,
        1.5708 + (k.isOdd ? .6 : -.6),
        k.isOdd ? c.l : c.m,
      );
    }
  }
  _canopy(
    x,
    const [
      [-10, -70, 10],
      [11, -71, 10],
      [0, -78, 9],
    ],
    c,
    e,
    9,
  );
}

void _lavender(_Ctx x, _Env e) {
  for (var i = 0; i < 11; i++) {
    _leaf(
      x,
      (i - 5) * 2.0,
      0,
      15,
      2,
      -1.5708 + (i - 5) * .26,
      i.isOdd ? const Color(0xFF8DB58A) : const Color(0xFFA7C9A1),
    );
  }
  for (var i = 0; i < 11; i++) {
    final a = -1.5708 + (i - 5) * .19,
        len = 30.0 + ((i * 7) % 9),
        sw = e.w * 4 + math.sin(e.t * 1.6 + i) * .8;
    final bx = (i - 5) * 2.2,
        tx = bx + math.cos(a) * len + sw,
        ty = math.sin(a) * len;
    _curve(
      x,
      _o(bx, 0),
      _o(bx + math.cos(a) * len * .5, ty * .5),
      _o(tx, ty),
      1.1,
      const Color(0xFF6FA56B),
    );
    for (var k = 0; k < 7; k++) {
      final r = 2.5 - k * .25,
          px = tx + math.cos(a) * k * 2.3,
          py = ty + math.sin(a) * k * 2.3;
      _dot(
        x,
        px + (k.isOdd ? .9 : -.9),
        py,
        r,
        k.isOdd ? const Color(0xFFB197FC) : const Color(0xFF8F6FE0),
      );
      _dot(x, px - .6, py - .6, r * .35, _white(.45));
    }
  }
  _butterfly(
    x,
    10,
    -52,
    e.t,
    const Color(0xFFFFD43B),
    const Color(0xFFFFA94D),
    2,
    .8,
  );
}

void _shroom(_Ctx x, double a, double b, double s, List<Color> cap) {
  x
    ..save()
    ..translate(a, b)
    ..scale(s, s)
    ..begin()
    ..moveTo(-4, 0)
    ..quad(-5.5, -10, -3.5, -18)
    ..lineTo(3.5, -18)
    ..quad(5.5, -10, 4, 0)
    ..quad(0, 2, -4, 0)
    ..fill(
      _lg(-5, 0, 5, 0, const [
        Color(0xFFFFFAF0),
        Color(0xFFF3E6D0),
        Color(0xFFD9C5A5),
      ]),
    );
  _ell(x, 0, -18, 13.5, 3.6, 0, const Color(0xFFF1DFC4));
  for (var i = -4; i <= 4; i++) {
    _line(
      x,
      [_o(i * .8, -18), _o(i * 3.0, -16.2)],
      .35,
      const Color.fromRGBO(160, 120, 80, .45),
    );
  }
  x
    ..begin()
    ..moveTo(-15, -18)
    ..cubic(-15, -35, 15, -35, 15, -18)
    ..quad(0, -13.5, -15, -18)
    ..close()
    ..fill(_rg(-5, -29, 1, 0, -20, 19, cap));
  for (final d in const [
    [-7.0, -25.0, 2.2],
    [2.0, -28.5, 2.6],
    [8.0, -23.0, 1.8],
    [-2.0, -21.5, 1.4],
    [-11.0, -20.6, 1.2],
    [11.5, -19.6, 1.0],
  ]) {
    _ell(x, d[0], d[1], d[2], d[2] * .8, 0, _white(.93));
  }
  _ell(x, -6, -30, 3.4, 1.2, -.5, _white(.35));
  x.restore();
}

void _mushroom(_Ctx x, _Env e) {
  _shroom(x, -19, 0, .85, const [
    Color(0xFFFFD8A8),
    Color(0xFFFF922B),
    Color(0xFFD9480F),
  ]);
  _shroom(x, 18, 0, .62, const [
    Color(0xFFFFC9C9),
    Color(0xFFFA5252),
    Color(0xFFC92A2A),
  ]);
  _shroom(x, 0, 0, 2, const [
    Color(0xFFFFA8A8),
    Color(0xFFF03E3E),
    Color(0xFFB02525),
  ]);
  for (var i = 0; i < 7; i++) {
    final u = (e.t * .11 + i * .143) % 1;
    _dot(
      x,
      -14 + i * 5 + math.sin(u * 7 + i) * 3,
      -42 - u * 40,
      1.1,
      _white(.75 * (1 - u)),
    );
  }
  _snail(x, -26, 1.5, e.t);
}

void _cactus(_Ctx x, _Env e) {
  const m = Color(0xFF3FAF7A), d = Color(0xFF2B8F62), l = Color(0xFF7FDCA6);
  for (final p in [
    [_o(-9, -24), _o(-23, -24), _o(-23, -44)],
    [_o(9, -34), _o(24, -34), _o(24, -56)],
  ]) {
    _line(x, p, 11.5, d);
    _line(x, [for (final q in p) q - const Offset(1, .6)], 8, m);
    _line(x, [for (final q in p) q - const Offset(3, 1)], 1.6, _a(l, .7));
  }
  x
    ..begin()
    ..rrect(-11, -64, 22, 64, 11)
    ..fill(_lg(-11, 0, 11, 0, const [l, m, d]));
  for (final g in const [-5.5, 0.0, 5.5]) {
    _line(
      x,
      [_o(g, -57), _o(g, -5)],
      .8,
      const Color.fromRGBO(20, 90, 60, .35),
    );
  }
  for (var i = 0; i < 6; i++) {
    for (final g in const [-8.0, -2.7, 2.7, 8.0]) {
      _dot(x, g, -9 - i * 9 - (g > -3 && g < 3 ? 4 : 0), .8, _white(.9));
    }
  }
  _blossom(
    x,
    0,
    -66,
    4.4,
    const Color(0xFFFF8FB8),
    const Color(0xFFFFE066),
    e.t * .15,
  );
  _blossom(
    x,
    24,
    -58,
    2.8,
    const Color(0xFFFFD43B),
    const Color(0xFFF59F00),
    1,
  );
  _blossom(
    x,
    -23,
    -46,
    2.6,
    const Color(0xFFFF8FB8),
    const Color(0xFFFFE066),
    2,
  );
  x
    ..save()
    ..translate(18, 0);
  _fruit(x, 0, -5, 6.5, const [l, m, d]);
  for (var i = 0; i < 5; i++) {
    _line(
      x,
      [_o(-4 + i * 2.0, -10.5), _o(-4.6 + i * 2.3, -1)],
      .5,
      const Color.fromRGBO(20, 90, 60, .35),
    );
  }
  _blossom(x, 0, -11.5, 2.2, Colors.white, const Color(0xFFFFD43B));
  x.restore();
  _ell(x, -18, 2, 4, 1.9, 0, const Color(0xFFB9C2CC));
  _ell(x, -12, 3.2, 2.4, 1.2, 0, const Color(0xFFD5DBE2));
}

void _bonsai(_Ctx x, _Env e) {
  _poly(
    x,
    [_o(-17, -8), _o(17, -8), _o(13, 0), _o(-13, 0)],
    _lg(-17, 0, 17, 0, const [
      Color(0xFFFFFFFF),
      Color(0xFFE7EEF8),
      Color(0xFFB9C8DE),
    ]),
  );
  x.rect(-15.6, -6.4, 31.2, 1.2, const Color(0xFF3B5BDB));
  for (var i = -3; i <= 3; i++) {
    _dot(x, i * 4.0, -3, .9, const Color(0xFF3B5BDB));
  }
  _ell(x, 0, -8, 17, 3, 0, const Color(0xFF5B4636));
  _ell(x, -1, -8.5, 14, 2.1, 0, const Color(0xFF6FA85A));
  x
    ..begin()
    ..moveTo(0, -9)
    ..cubic(-20, -26, 16, -36, -4, -58)
    ..stroke(const Color(0xFF6E4424), 10)
    ..begin()
    ..moveTo(-2, -11)
    ..cubic(-21, -26, 13, -36, -6, -56)
    ..stroke(const Color(0xFFA06B40), 3.2);
  _curve(x, _o(5, -38), _o(14, -40), _o(24, -46), 4.5, const Color(0xFF6E4424));
  _curve(
    x,
    _o(-8, -26),
    _o(-18, -28),
    _o(-26, -36),
    4.5,
    const Color(0xFF6E4424),
  );
  _canopy(
    x,
    const [
      [-36, -40, 7],
      [-16, -40, 7],
      [-26, -44, 10],
    ],
    _deep,
    e,
    41,
  );
  _canopy(
    x,
    const [
      [16, -51, 7],
      [36, -51, 7],
      [26, -55, 10],
    ],
    _deep,
    e,
    42,
  );
  _canopy(
    x,
    const [
      [-18, -65, 8],
      [10, -66, 8],
      [-4, -71, 12],
    ],
    _deep,
    e,
    43,
  );
  _ell(x, 9, -9.4, 3, 1.5, 0, const Color(0xFFAEB7C2));
}

void _baobab(_Ctx x, _Env e) {
  x
    ..begin()
    ..moveTo(-18, 0)
    ..cubic(-23, -22, -13, -44, -9, -60)
    ..lineTo(9, -60)
    ..cubic(13, -44, 23, -22, 18, 0)
    ..quad(0, 3.5, -18, 0)
    ..close()
    ..fill(
      _lg(-18, 0, 18, 0, const [
        Color(0xFFE3BE98),
        Color(0xFFB98A64),
        Color(0xFF84593C),
      ]),
    );
  for (final g in const [-9.0, -2.0, 6.0]) {
    _curve(
      x,
      _o(g, -3),
      _o(g * 1.15, -28),
      _o(g * .5, -56),
      .9,
      const Color.fromRGBO(80, 45, 20, .3),
    );
  }
  for (final b in const [
    [-8.0, -58.0, -23.0, -70.0],
    [-3.0, -60.0, -8.0, -79.0],
    [4.0, -60.0, 10.0, -79.0],
    [8.0, -58.0, 25.0, -70.0],
  ]) {
    _line(
      x,
      [_o(b[0], b[1]), _o(b[2] + e.w, b[3])],
      4.6,
      const Color(0xFFA77B57),
    );
    _line(
      x,
      [_o(b[0] - .8, b[1]), _o(b[2] + e.w - .8, b[3])],
      1.4,
      _white(.22),
    );
  }
  _canopy(
    x,
    const [
      [-25, -72, 8],
      [27, -72, 8],
      [1, -75, 7],
      [-9, -81, 9],
      [11, -81, 9],
    ],
    _green,
    e,
    27,
  );
  _bird(
    x,
    12 + e.w * 3,
    -90,
    e.t,
    const Color(0xFFFF8787),
    const Color(0xFFE03131),
    3,
  );
}

void _wisteria(_Ctx x, _Env e) {
  _ell(x, -2, 0, 7, 2.2, 0, _barkD.d);
  _curve(x, _o(-2, 0), _o(-15, -20), _o(-2, -40), 8, _barkD.m);
  _curve(x, _o(-2, -40), _o(9, -52), _o(0, -61), 6, _barkD.m);
  _curve(x, _o(-4, -2), _o(-17, -20), _o(-4, -39), 2.2, _a(_barkD.l, .8));
  _curve(x, _o(0, -59), _o(-20, -68), _o(-37, -57), 3.6, _barkD.m);
  _curve(x, _o(0, -59), _o(20, -70), _o(39, -57), 3.6, _barkD.m);
  for (var i = 0; i < 9; i++) {
    final x0 = -34 + i * 8.5,
        y0 = -58 - math.sin(i / 8 * math.pi) * 7,
        len = 19.0 + ((i * 53) % 13);
    final sw = e.w * 4 + math.sin(e.t * 1.5 + i * .9) * 1.2;
    for (var k = 0; k < 8; k++) {
      final u = k / 7,
          px = x0 + sw * u * u,
          py = y0 + u * len,
          r = 3.4 * (1 - u * .72);
      _dot(
        x,
        px - 1.7 * (1 - u),
        py,
        r,
        k.isOdd ? const Color(0xFFB197FC) : const Color(0xFF9775FA),
      );
      _dot(
        x,
        px + 1.7 * (1 - u),
        py + .9,
        r * .9,
        k.isOdd ? const Color(0xFFD0BFFF) : const Color(0xFFB197FC),
      );
    }
  }
  _canopy(
    x,
    const [
      [-35, -60, 7],
      [36, -60, 7],
      [-21, -66, 8],
      [22, -66, 8],
      [-7, -69, 8],
      [8, -70, 8],
    ],
    _green,
    e,
    26,
  );
  _butterfly(
    x,
    -22,
    -30,
    e.t,
    const Color(0xFFFFA8C5),
    const Color(0xFFF06595),
    5,
    .7,
  );
}

void _bamboo(_Ctx x, _Env e) {
  for (final s in const [
    [-14.0, 72.0, 0.0],
    [2.0, 94.0, 1.0],
    [15.0, 60.0, 2.0],
  ]) {
    final bend = e.w * 5 + math.sin(e.t + s[2]) * .8;
    var i = 0;
    for (var y = 0.0; y < s[1]; y += 12, i++) {
      final a = s[0] + bend * math.pow(y / s[1], 2),
          b = s[0] + bend * math.pow((y + 12) / s[1], 2);
      _poly(x, [
        _o(a - 3.2, -y),
        _o(a + 3.2, -y),
        _o(b + 3.2, -y - 11.4),
        _o(b - 3.2, -y - 11.4),
      ], const Color(0xFF7CCB66));
      _poly(x, [
        _o(a + .7, -y),
        _o(a + 3.2, -y),
        _o(b + 3.2, -y - 11.4),
        _o(b + .7, -y - 11.4),
      ], const Color(0xFF55A84F));
      _line(x, [_o(a - 1.9, -y - 1.5), _o(b - 1.9, -y - 10)], 1, _white(.42));
      _line(
        x,
        [_o(b - 3.5, -y - 11.8), _o(b + 3.5, -y - 11.8)],
        1.4,
        const Color(0xFF3F8F45),
      );
      if (i > 1) {
        final d = (i + s[2].toInt()).isOdd ? 1 : -1;
        _leaf(
          x,
          b + d * 2,
          -y - 12,
          14,
          2.7,
          d > 0 ? -.45 : math.pi + .45,
          const Color(0xFF57B85A),
        );
        _leaf(
          x,
          b + d * 2,
          -y - 12,
          10.5,
          2.3,
          d > 0 ? .15 : math.pi - .15,
          _leafL,
        );
      }
    }
  }
  x
    ..save()
    ..translate(-4, 0);
  _poly(x, [
    _o(-4.2, 0),
    _o(0, -11),
    _o(4.2, 0),
  ], _lg(-4, 0, 4, 0, const [Color(0xFFD9A066), Color(0xFF9A683D)]));
  _line(x, [_o(-2.6, -3.4), _o(2.6, -3.4)], .7, const Color(0xFF6E4424));
  _line(x, [_o(-1.5, -6.6), _o(1.5, -6.6)], .7, const Color(0xFF6E4424));
  x.restore();
}

void _coconut(_Ctx x, _Env e) {
  Offset p(double u) => _o(2 * (1 - u) * u * 16 + u * u * 5, -u * 74);
  for (var i = 0; i <= 13; i++) {
    final u = i / 13, q = p(u), r = 6.6 - u * 2.6;
    _dot(
      x,
      q.dx,
      q.dy,
      r,
      i.isOdd ? const Color(0xFFB98A52) : const Color(0xFF93683A),
    );
    _dot(x, q.dx - r * .35, q.dy - r * .2, r * .35, _white(.2));
  }
  final top = p(1);
  const fronds = [
    [-1.05, 36.0],
    [-.55, 41.0],
    [-.08, 38.0],
    [.4, 34.0],
    [.85, 26.0],
  ];
  const k = [
    [Color(0xFF1C7C4E), Color(0xFF2FA866)],
    [Color(0xFF2FA866), Color(0xFF63CF8A)],
    [Color(0xFF3DBB74), Color(0xFF8FE4A5)],
    [Color(0xFF2A9D60), Color(0xFF63CF8A)],
    [Color(0xFF1C7C4E), Color(0xFF2FA866)],
  ];
  x
    ..save()
    ..translate(top.dx, top.dy);
  for (final d in const [-1.0, 1.0]) {
    for (var i = 0; i < fronds.length; i++) {
      final f = fronds[i], l = f[1];
      x
        ..save()
        ..scale(d, 1)
        ..rotate(
          f[0] + e.w * .07 * (i + 1) * d + math.sin(e.t * 1.3 + i) * .025,
        )
        ..begin()
        ..moveTo(0, 0)
        ..quad(l * .5, -l * .46, l, l * .18)
        ..quad(l * .5, -l * .1, 0, 0)
        ..fill(_lg(0, -l * .3, l, l * .1, k[(i + (d > 0 ? 0 : 2)) % 5]))
        ..begin()
        ..moveTo(2, -1)
        ..quad(l * .5, -l * .3, l * .94, l * .14)
        ..stroke(_white(.38), .8);
      for (var j = 1; j < 7; j++) {
        final u = j / 7,
            m = _qpt(Offset.zero, _o(l * .5, -l * .3), _o(l, l * .16), u);
        _line(
          x,
          [m, m + _o(l * .06, l * .11 * (1 - u * .5))],
          .7,
          const Color.fromRGBO(15, 80, 50, .45),
        );
      }
      x.restore();
    }
  }
  for (final q in [_o(-4.5, 3), _o(4.5, 4), _o(0, 7.5)]) {
    _fruit(x, q.dx, q.dy, 4.3, const [
      Color(0xFFB98A52),
      Color(0xFF7A4A22),
      Color(0xFF4A2C14),
    ]);
  }
  x.restore();
}

void _bleaf(
  _Ctx x,
  double a,
  double b,
  double dir,
  double rot,
  double len,
  double wid,
  double droop,
  List<Color> c,
) {
  x
    ..save()
    ..translate(a, b)
    ..scale(dir, 1)
    ..rotate(rot)
    ..begin()
    ..moveTo(0, 0)
    ..cubic(len * .3, -wid, len * .8, -wid * .8 + droop * .5, len, droop)
    ..cubic(len * .75, wid * .7 + droop * .6, len * .3, wid, 0, 0)
    ..fill(_lg(0, -wid, 0, wid + droop, c));
  final m1 = _o(len * .5, droop * .15), m2 = _o(len, droop);
  _curve(x, Offset.zero, m1, m2, 1.1, _white(.5));
  for (var k = 1; k < 8; k++) {
    final p = _qpt(Offset.zero, m1, m2, k / 8);
    _line(
      x,
      [p + _o(-2, -wid * .62), p, p + _o(-2, wid * .62)],
      .6,
      const Color.fromRGBO(20, 90, 50, .3),
    );
  }
  x.restore();
}

void _banana(_Ctx x, _Env e) {
  x
    ..begin()
    ..moveTo(-7, 0)
    ..quad(-5.4, -24, -3.6, -48)
    ..lineTo(3.6, -48)
    ..quad(5.4, -24, 7, 0)
    ..quad(0, 2.5, -7, 0)
    ..fill(
      _lg(-6.5, 0, 6.5, 0, const [
        Color(0xFFD8EC8E),
        Color(0xFF9CCB5A),
        Color(0xFF6A9F3C),
      ]),
    );
  for (final y in const [-10.0, -22.0, -34.0]) {
    _curve(
      x,
      _o(-6 - y * .05, y),
      _o(0, y + 1.6),
      _o(6 + y * .05, y),
      .8,
      const Color.fromRGBO(80, 110, 40, .45),
    );
  }
  const g = [Color(0xFFB6F08A), _leafG, _leafD],
      g2 = [Color(0xFF8FDD7A), _leafM, Color(0xFF237A47)];
  final w = e.w * .07;
  _bleaf(x, 0, -46, -1, .25 + w, 34, 8, 12, g2);
  _bleaf(x, 0, -46, 1, .3 - w, 33, 8, 12, g2);
  _bleaf(x, 0, -47, -1, -.4 + w, 40, 9, 6, g);
  _bleaf(x, 0, -47, 1, -.45 - w, 40, 9, 6, g);
  _bleaf(x, 0, -48, -1, -1.05 + w, 40, 8.5, 2, g2);
  _bleaf(x, 0, -48, 1, -1.15 - w, 42, 8.5, 2, g);
  _curve(
    x,
    _o(2, -44),
    _o(10, -42),
    _o(11 + e.w, -32),
    1.8,
    const Color(0xFF6A9F3C),
  );
  final bx = 11 + e.w;
  const by = -32.0;
  for (var r = 0; r < 2; r++) {
    for (var i = -2; i <= 2; i++) {
      x
        ..save()
        ..translate(bx + i * 2.1, by + r * 5.4)
        ..rotate(i * .16)
        ..begin()
        ..rrect(-1.5, 0, 3, 7.6, 1.5)
        ..fill(
          _lg(-1.5, 0, 1.5, 0, const [
            Color(0xFFFFF3A6),
            Color(0xFFFFD43B),
            Color(0xFFE8A80C),
          ]),
        )
        ..restore();
    }
  }
  _ell(x, bx, by + 16, 2.6, 4, 0, const Color(0xFF8B2F5C));
  _ell(x, bx - .8, by + 15, .9, 2.4, 0, _white(.3));
}

void _phuong(_Ctx x, _Env e) {
  _trunk(x, 34, 11, _bark);
  _limb(x, _o(0, -27), _o(-12, -34), _o(-24, -45), 4, _bark);
  _limb(x, _o(0, -27), _o(12, -35), _o(24, -47), 4, _bark);
  _limb(x, _o(0, -30), _o(1, -40), _o(0, -50), 3.6, _bark);
  for (final q in [_o(-19, -40), _o(15, -40)]) {
    _curve(
      x,
      q,
      q + _o(2, 8),
      _o(q.dx - 1 + e.w * 1.5, q.dy + 16),
      1.8,
      const Color(0xFF4A2C14),
    );
  }
  _canopy(
    x,
    const [
      [-37, -46, 10],
      [37, -47, 10],
      [-23, -51, 13],
      [23, -52, 13],
      [-10, -44, 10],
      [11, -44, 10],
      [0, -54, 15],
    ],
    _green,
    e,
    13,
  );
  for (var i = 0; i < 9; i++) {
    _leaf(
      x,
      -36 + i * 9 + e.w * 2,
      -40 - math.sin(i / 8 * math.pi) * 3,
      7,
      1.6,
      1.3 + math.sin(e.t * 1.4 + i) * .12,
      i.isOdd ? _leafG : _leafD,
    );
  }
  final r = _rng(77);
  final cl = [
    _o(-33, -55),
    _o(-22, -61),
    _o(-10, -63),
    _o(2, -67),
    _o(14, -63),
    _o(25, -60),
    _o(35, -54),
    _o(-16, -53),
    _o(8, -56),
    _o(-28, -48),
    _o(28, -49),
    _o(-3, -58),
  ];
  for (var i = 0; i < cl.length; i++) {
    final bx = cl[i].dx + e.w * (1 - cl[i].dy * .03), by = cl[i].dy;
    _dot(x, bx + 1, by + 1.4, 4.6, const Color.fromRGBO(150, 25, 30, .35));
    for (var k = 0; k < 3; k++) {
      final a = k * 2.1 + i;
      _blossom(
        x,
        bx + math.cos(a) * 2.6,
        by + math.sin(a) * 2.2,
        2.9 + r() * .9,
        k.isOdd ? const Color(0xFFFF6B5E) : const Color(0xFFF03E3E),
        const Color(0xFFFFE066),
        a,
      );
    }
  }
  _fall(
    x,
    e.t,
    7,
    const [-38, 36, -48, 2],
    (i) => _ell(
      x,
      0,
      0,
      2.3,
      1.3,
      0,
      i.isOdd ? const Color(0xFFF2514B) : const Color(0xFFFF8A5B),
    ),
  );
}

List<List<double>> _tierPuffs(double w) => [
  [-w * .76, 2, w * .3],
  [w * .76, 2, w * .3],
  [-w * .38, -2, w * .37],
  [w * .38, -2, w * .37],
  [0, -4, w * .42],
];

void _bang(_Ctx x, _Env e) {
  _trunk(x, 76, 9, _barkG);
  const tiers = [
    (-38.0, 31.0, _green),
    (-57.0, 24.0, _deep),
    (-74.0, 16.0, _green),
  ];
  for (var i = 0; i < tiers.length; i++) {
    final (y, w, tone) = tiers[i];
    final dx = e.w * (i + 1) * .9;
    _limb(
      x,
      _o(0, y + 5),
      _o(-w * .4, y + 3),
      _o(-w * .8 + dx, y + 1),
      2.2,
      _barkG,
    );
    _limb(
      x,
      _o(0, y + 5),
      _o(w * .4, y + 3),
      _o(w * .8 + dx, y + 1),
      2.2,
      _barkG,
    );
    x
      ..save()
      ..translate(dx, y)
      ..scale(1, .56);
    _canopy(x, _tierPuffs(w), tone, _Env(e.t, 0), 30 + i);
    x.restore();
    _leaf(
      x,
      -w * .9 + dx,
      y + 2,
      8,
      3.2,
      math.pi - .3,
      const Color(0xFFE8590C),
      const Color(0xFFB93E14),
    );
    _leaf(
      x,
      w * .55 + dx,
      y + 4,
      7.5,
      3,
      .5,
      i.isOdd ? const Color(0xFFF08C00) : const Color(0xFFE03A1E),
      const Color(0xFFB93E14),
    );
  }
  _canopy(
    x,
    [
      [e.w * 3, -82, 6.5],
    ],
    _green,
    _Env(e.t, 0),
    33,
  );
  _fall(
    x,
    e.t,
    3,
    const [-30, 30, -40, 2],
    (i) => _leaf(
      x,
      -3.5,
      0,
      7,
      2.8,
      0,
      i.isOdd ? const Color(0xFFE8590C) : const Color(0xFFF08C00),
    ),
    .1,
  );
}

void _lixi(_Ctx x, double a, double b, _Env e, double ph) {
  x
    ..save()
    ..translate(a, b)
    ..rotate(math.sin(e.t * 2 + ph) * .25 + e.w * .2);
  _line(x, [_o(0, 0), _o(0, 6)], .5, const Color(0xFFF59F00));
  x
    ..begin()
    ..rrect(-2.7, 6, 5.4, 7.6, .8)
    ..fill(const Color(0xFFE03131));
  _dot(x, 0, 9.8, 1.2, const Color(0xFFFFD43B));
  x.restore();
}

void _blossomTree(
  _Ctx x,
  _Env e,
  _Bark bk,
  int seed,
  Color petal,
  Color petal2,
  Color ctr,
  Color bud, [
  Color? leaf,
  Color? leaf2,
]) {
  final r = _rng(seed);
  final branches = [
    [_o(0, 0), _o(-9, -20), _o(3, -38)],
    [_o(3, -38), _o(15, -50), _o(9, -72)],
    [_o(3, -38), _o(-12, -46), _o(-24, -60)],
    [_o(-1, -16), _o(16, -24), _o(29, -38)],
    [_o(-3, -24), _o(-20, -28), _o(-32, -42)],
    [_o(11, -56), _o(22, -60), _o(30, -76)],
    [_o(-13, -49), _o(-9, -64), _o(-16, -80)],
    [_o(8, -66), _o(0, -76), _o(2, -90)],
  ];
  _ell(x, 0, .3, 8.5, 2.6, 0, bk.d);
  final ends = <Offset>[];
  for (var i = 0; i < branches.length; i++) {
    final b = branches[i], w = i > 0 ? math.max(1.7, 3.7 - i * .3) : 7.5;
    final en = _o(b[2].dx + (i > 0 ? e.w * 2 : 0), b[2].dy);
    ends.add(en);
    _curve(x, b[0], b[1], en, w, bk.m);
    final o = _o(w * .2, 0);
    _curve(x, b[0] - o, b[1] - o, en - o, w * .3, _a(bk.l, .8));
  }
  if (leaf != null) {
    for (var i = 1; i < branches.length; i++) {
      for (var k = 0; k < 3; k++) {
        final p = _qpt(branches[i][0], branches[i][1], ends[i], .3 + k * .26);
        _leaf(
          x,
          p.dx,
          p.dy,
          6.5,
          2.3,
          -1.57 + (r() - .5) * 2.4,
          k.isOdd ? leaf : leaf2!,
        );
      }
    }
  }
  for (var i = 1; i < branches.length; i++) {
    for (var k = 0; k < 6; k++) {
      final p = _qpt(branches[i][0], branches[i][1], ends[i], .2 + k * .16);
      final px = p.dx + (r() - .5) * 9, py = p.dy + (r() - .5) * 9;
      if (k % 5 == 4) {
        _dot(x, px, py, 1.6, bud);
      } else {
        _blossom(
          x,
          px,
          py,
          2.8 + r() * 1.4,
          k.isOdd ? petal : petal2,
          ctr,
          r() * 6,
        );
      }
    }
    _blossom(x, ends[i].dx, ends[i].dy, 3.4, petal, ctr, i.toDouble());
  }
}

void _mai(_Ctx x, _Env e) {
  _blossomTree(
    x,
    e,
    _barkD,
    21,
    const Color(0xFFFFD43B),
    const Color(0xFFFFE066),
    const Color(0xFFE8590C),
    const Color(0xFF9BD45A),
    const Color(0xFF8FCB52),
    const Color(0xFFB6E27C),
  );
  _lixi(x, 29 + e.w * 2, -38, e, 0);
  _lixi(x, -32 + e.w * 2, -42, e, 2);
  _fall(
    x,
    e.t,
    6,
    const [-34, 36, -60, 2],
    (i) => _ell(
      x,
      0,
      0,
      2.4,
      1.4,
      0,
      i.isOdd ? const Color(0xFFFFD43B) : const Color(0xFFFFE98A),
    ),
  );
}

void _dao(_Ctx x, _Env e) {
  _blossomTree(
    x,
    e,
    const _Bark(Color(0xFF96605A), Color(0xFF70403C), Color(0xFF4B2826)),
    35,
    const Color(0xFFFF8FB1),
    const Color(0xFFFFB3CB),
    const Color(0xFFD6336C),
    const Color(0xFFD6336C),
  );
  _fall(
    x,
    e.t,
    6,
    const [-34, 36, -60, 2],
    (i) => _ell(
      x,
      0,
      0,
      2.4,
      1.4,
      0,
      i.isOdd ? const Color(0xFFFF8FB1) : const Color(0xFFFFC9DA),
    ),
  );
}

void _pad(_Ctx x, double a, double b, double r, double rot) {
  x
    ..save()
    ..translate(a, b)
    ..scale(1, .5)
    ..rotate(rot)
    ..begin()
    ..moveTo(0, 0)
    ..arc(0, 0, r, .28, _tau - .28)
    ..close()
    ..fill(_lg(-r, -r, r, r, const [Color(0xFF8FE39A), _leafD]));
  for (var i = 0; i < 5; i++) {
    final g = .9 + i * 1.12;
    _line(
      x,
      [Offset.zero, _o(math.cos(g) * r * .85, math.sin(g) * r * .85)],
      .7,
      _white(.35),
    );
  }
  x.restore();
}

void _petal(
  _Ctx x,
  double a,
  double b,
  double ang,
  double len,
  double wid,
  Color col,
) {
  x
    ..save()
    ..translate(a, b)
    ..rotate(ang)
    ..begin()
    ..moveTo(0, 0)
    ..quad(wid, -len * .5, 0, -len)
    ..quad(-wid, -len * .5, 0, 0)
    ..fill(col)
    ..restore();
}

void _lotus(_Ctx x, _Env e) {
  x
    ..save()
    ..scale(1, .5);
  _dot(x, 0, 0, 36, const Color(0xFF2F8FAE));
  _dot(
    x,
    0,
    -1.5,
    34,
    _rg(-8, -10, 2, 0, 0, 34, const [
      Color(0xFFD2F7F2),
      Color(0xFF74D6DA),
      Color(0xFF3BA7C4),
    ]),
  );
  for (var i = 0; i < 2; i++) {
    final u = (e.t * .25 + i * .5) % 1;
    x
      ..begin()
      ..arc(10, 6, 5 + u * 17, 0, _tau - .001)
      ..stroke(_white(.55 * (1 - u)), 1.2);
  }
  x.restore();
  _pad(x, -17, 2, 10, .3);
  _pad(x, 15, 6, 8, -2);
  _pad(x, 1, -8, 7, 1.2);
  _pad(x, -5, 11, 6, 2.4);
  final w = e.w;
  const stemC = Color(0xFF4DA858);
  _stem(x, _o(19, 3), _o(21, -6), _o(20 + w, -14), 1.4, stemC);
  _ell(x, 20 + w, -16, 3.6, 2.6, 0, const Color(0xFF7BC77A));
  for (var i = -1; i <= 1; i++) {
    _dot(x, 20 + w + i * 1.8, -16.4, .6, _leafD);
  }
  _stem(x, _o(-12, 0), _o(-17 + w, -10), _o(-14 + w * 2, -21), 1.5, stemC);
  _petal(x, -14 + w * 2, -20, -.25, 9, 3.2, const Color(0xFFF06595));
  _petal(x, -14 + w * 2, -20, .25, 9, 3.2, const Color(0xFFFF8FB8));
  _petal(x, -14 + w * 2, -20, 0, 10, 3, const Color(0xFFFFC2D6));
  _stem(x, _o(6, 2), _o(10 + w, -14), _o(5 + w * 2, -30), 1.7, stemC);
  final fx = 5 + w * 2;
  const fy = -30.0;
  for (final g in const [-1.2, -.62, .62, 1.2]) {
    _petal(x, fx, fy, g, 11, 4.2, const Color(0xFFF06595));
  }
  for (final g in const [-.9, -.3, .3, .9]) {
    _petal(x, fx, fy, g, 11.6, 4.4, const Color(0xFFFF8FB8));
  }
  for (final g in const [-.45, 0.0, .45]) {
    _petal(x, fx, fy, g, 12, 4.6, const Color(0xFFFFC9DA));
  }
  _ell(x, fx, fy - 3.4, 3, 1.7, 0, const Color(0xFFFFD43B));
  _dragonfly(x, -6, -46, e.t);
}

void _banyan(_Ctx x, _Env e) {
  x
    ..save()
    ..translate(-18, 0);
  _trunk(x, 36, 5, _bark, 5);
  x
    ..restore()
    ..save()
    ..translate(19, 0);
  _trunk(x, 38, 5, _bark, -5);
  x.restore();
  _trunk(x, 38, 18, _bark);
  for (final g in const [-5.0, 0.0, 5.0]) {
    _line(x, [_o(g, -4), _o(g * .6, -33)], .9, _a(_bark.d, .55));
  }
  for (var i = 0; i < 9; i++) {
    final x0 = -35 + i * 8.7,
        len = 13.0 + ((i * 37) % 11),
        sw = e.w * 3 + math.sin(e.t * 1.4 + i);
    _curve(
      x,
      _o(x0, -41),
      _o(x0 + sw * .4, -41 + len * .5),
      _o(x0 + sw, -41 + len),
      .9,
      const Color(0xFFA9773F),
    );
  }
  x
    ..save()
    ..translate(30, -41)
    ..rotate(math.sin(e.t * 1.6) * .2 + e.w * .1);
  _line(x, [_o(-4, 0), _o(-4, 25)], .7, const Color(0xFFF1E3C4));
  _line(x, [_o(4, 0), _o(4, 25)], .7, const Color(0xFFF1E3C4));
  x
    ..begin()
    ..rrect(-6, 24, 12, 2.6, 1)
    ..fill(const Color(0xFFC98A4B))
    ..restore();
  _canopy(
    x,
    const [
      [-39, -48, 12],
      [41, -47, 12],
      [-26, -56, 15],
      [28, -56, 15],
      [-10, -44, 12],
      [12, -44, 12],
      [-12, -66, 16],
      [14, -67, 16],
      [0, -57, 17],
      [0, -79, 13],
    ],
    _deep,
    e,
    18,
  );
  _bird(
    x,
    22 + e.w * 3,
    -83,
    e.t,
    const Color(0xFFFFD43B),
    const Color(0xFFF08C00),
    2,
  );
}

void _galaxy(_Ctx x, _Env e) {
  _dot(
    x,
    0,
    -58,
    52,
    _rg(0, -58, 6, 0, -58, 52, const [
      Color.fromRGBO(170, 160, 255, .5),
      Color.fromRGBO(170, 160, 255, 0),
    ]),
  );
  const k = _Bark(Color(0xFFDAD8FF), Color(0xFF9892E0), Color(0xFF5750A8));
  _trunk(x, 38, 12, k);
  _forks(x, k);
  _canopy(x, _round, _cosmos, e, 28);
  _ell(
    x,
    -10 + e.w * 2,
    -62,
    15,
    8,
    -.4,
    const Color.fromRGBO(110, 225, 255, .25),
  );
  _ell(
    x,
    12 + e.w * 2,
    -50,
    13,
    7,
    .5,
    const Color.fromRGBO(255, 140, 225, .22),
  );
  final r = _rng(99);
  for (var i = 0; i < 18; i++) {
    final a = r() * _tau,
        rr = math.sqrt(r()) * 27,
        tw = .35 + .65 * math.sin(e.t * 2 + i * 1.7).abs();
    _star4(
      x,
      math.cos(a) * rr * 1.15 + e.w * 2.6,
      -58 + math.sin(a) * rr,
      (1.2 + r() * 2.2) * tw,
      _white(.45 + .55 * tw),
    );
  }
  x
    ..save()
    ..translate(15 + e.w * 3, -77)
    ..begin()
    ..arc(0, 0, 5, -1.9, 1.3);
  // The inner edge of the crescent, drawn back the other way.
  x._p.arcTo(
    Rect.fromCircle(center: const Offset(-2.2, -1.4), radius: 4.2),
    1.05,
    -1.7 - 1.05,
    false,
  );
  x
    ..close()
    ..fill(const Color(0xFFFFE98A))
    ..restore();
  for (var j = 0; j < 6; j++) {
    final a = e.t * 1.2 - j * .11;
    _dot(
      x,
      math.cos(a) * 38,
      -58 + math.sin(a) * 13,
      1.9 - j * .28,
      _white(.9 - j * .15),
    );
  }
}

void _deadTree(_Ctx x, _Env e) {
  _trunk(x, 46, 9, _barkG);
  final k = _barkG.m;
  _curve(x, _o(0, -30), _o(-8, -40), _o(-17, -46), 3, k);
  _curve(x, _o(0, -38), _o(8, -48), _o(15, -58), 3, k);
  _curve(x, _o(0, -44), _o(-3, -54), _o(-8, -64), 2.4, k);
  _curve(x, _o(-10, -41), _o(-14, -48), _o(-13, -54), 1.6, k);
  _curve(x, _o(9, -49), _o(14, -50), _o(20, -48), 1.6, k);
  _leaf(x, -14, 3, 6, 2.2, .4, const Color(0xFFC98A4B));
  _leaf(x, -9, 5.5, 6, 2.2, 2.6, const Color(0xFFB9793F));
  _leaf(x, -22, 2, 6, 2.2, -.3, const Color(0xFFD9A066));
  final u = (e.t * .18) % 1;
  x
    ..save()
    ..alpha *= u < .1 ? u * 10 : (u > .85 ? (1 - u) / .15 : 1);
  _leaf(
    x,
    15 - u * 10 + math.sin(u * 9) * 5,
    -56 + u * 58,
    6,
    2.3,
    u * 7,
    const Color(0xFFD9A066),
  );
  x.restore();
  final sw = math.sin(e.t * 2.2) * .8;
  _curve(x, _o(14, 1), _o(14, -3), _o(14 + sw, -7), 1.5, _stemG);
  _leaf(x, 14 + sw, -7, 6, 2.4, -.6, _leafL, _leafG);
  _leaf(x, 14 + sw, -7, 6, 2.4, math.pi + .6, _leafG, _leafD);
}

void _sprout(_Ctx x, _Env e, double g) {
  x.scale(.6 + g * 3.2);
  _ell(x, 0, .5, 7.5, 2.5, 0, const Color(0xFF8A5A33));
  _ell(x, -1.5, -.2, 3.4, 1, 0, _white(.2));
  final sw = e.w * 1.5 + math.sin(e.t * 2.4) * .6;
  _curve(x, Offset.zero, _o(0, -6), _o(sw, -11), 1.7, _stemG);
  _leaf(x, sw, -11, 7.5, 3, -.55 + sw * .05, _leafL, _leafG);
  _leaf(x, sw, -11, 7.5, 3, math.pi + .55 + sw * .05, _leafG, _leafD);
}

void _sapling(_Ctx x, _Env e, _Art sp, double u) {
  final h = 22 + u * 12, r = 5.5 + u * 3.5;
  _line(x, [_o(6, 0), _o(6, -h * .82)], 1.4, const Color(0xFFD9B37A));
  _trunk(x, h, 4.2, sp.bark);
  _line(x, [_o(-1, -h * .55), _o(6.6, -h * .55)], 1, const Color(0xFFF8EED8));
  _canopy(
    x,
    [
      [-r * .8, -h - r * .2, r * .8],
      [r * .8, -h - r * .3, r * .8],
      [0, -h - r * .9, r],
    ],
    sp.tone,
    e,
    3,
  );
}
