part of 'garden_art.dart';

// Flowering trees and flowers.

// ——— Cherry (Japan): an umbrella of pale pink blossom over a dark trunk,
// petals drifting down.

const _cherryPink = [
  Color(0xFFD9809F),
  Color(0xFFEA9DBA),
  Color(0xFFF6BCD0),
  Color(0xFFFFD8E5),
  Color(0xFFFFF0F6),
];
const _cherryBark = (Color(0xFF8A5A4A), Color(0xFF4E3128));
const _cherryTones = [
  (Color(0xFF4F8A45), Color(0xFF427A3C)),
  (Color(0xFF6BA85A), Color(0xFF5C984F)),
  (Color(0xFF94C77C), Color(0xFF82B86C)),
];

void _cherry(_Pen p) {
  final rnd = _rng(53);
  p.ground(100, 182, 64);
  _roots(p, 16, _cherryBark);
  p.limbs(const [
    (100, 178, 96, 128, 18, 10, 7),
    (97, 134, 62, 98, 8, 3, -7),
    (98, 130, 140, 96, 8, 3, 7),
    (96, 128, 92, 76, 7, 3, 4),
  ], _cherryBark);
  for (final (i, (x, y, r, bias)) in const [
    (98.0, 64.0, 26.0, .35),
    (66.0, 82.0, 22.0, .15),
    (132.0, 78.0, 24.0, 0.0),
    (96.0, 90.0, 20.0, -.05),
    (52.0, 100.0, 14.0, -.15),
    (80.0, 104.0, 18.0, -.2),
    (118.0, 104.0, 20.0, -.3),
    (150.0, 96.0, 14.0, -.35),
  ].indexed) {
    p.blossoms(
      x: x,
      y: y,
      r: r,
      n: (r * 2.1).round(),
      size: 5.2,
      bias: bias,
      tones: _cherryPink,
      center: const Color(0xFFD0578A),
      core: const Color(0xFFE595B4),
      seed: 530 + i,
    );
  }
  p.limbs(const [
    (64, 98, 46, 92, 3, 1.4, -2),
    (140, 96, 158, 88, 3, 1.4, 2),
  ], _cherryBark);
  for (var i = 0; i < 5; i++) {
    final x = 52 + rnd() * 96, y = 118 + rnd() * 44;
    p.oval(x, y, 2.4, 1.5, _cherryPink[2 + (rnd() * 3).floor()], rnd() * 3);
  }
  p.litter(rnd, 7, 110, _cherryPink.sublist(1, 4));
}

// ——— Peach blossom, hoa đào Nhật Tân (Vietnam): an upright vase of dark
// branches crowded with deep pink double flowers, buds and new leaves.

const _daoPink = [
  Color(0xFFC2185B),
  Color(0xFFE0457E),
  Color(0xFFF06A9A),
  Color(0xFFFF8FB4),
  Color(0xFFFFB8D0),
];
const _daoBark = (Color(0xFF6E4636), Color(0xFF3A2219));

/// Flowers, buds and young leaves along the thin ends of [limbs].
void _alongTwigs(
  _Pen p,
  List<_Limb> limbs, {
  required int seed,
  required double every,
  required void Function(double x, double y, double r, double rot, double light)
  open,
  required _Tone bud,
  required _Tone leaf,
  double thin = 2.3,
}) {
  final rnd = _rng(seed);
  final items = <(double, double, double, double, double, double)>[];
  for (final b in limbs) {
    if (b.$6 > thin) continue;
    final len = math.sqrt(math.pow(b.$3 - b.$1, 2) + math.pow(b.$4 - b.$2, 2));
    final count = math.max(2, (len / every).round());
    for (var i = 0; i < count; i++) {
      final o = _along(b.$1, b.$2, b.$3, b.$4, b.$7, .2 + .8 * rnd());
      final x = o.dx + (rnd() - .5) * 6, y = o.dy + (rnd() - .5) * 6;
      final light = (100 - x) * .006 + (110 - y) * .012 + (rnd() - .5) * .3;
      items.add((x, y, rnd(), 3.6 + rnd() * 2.4, rnd() * 6, light));
    }
  }
  items.sort((a, b) => a.$6.compareTo(b.$6));
  for (final (i, (x, y, k, r, rot, light)) in items.indexed) {
    if (i % 5 == 0) p.spots.add(Offset(x, y));
    if (k < .16) {
      p.fill(_leaf(x, y, rot, 7, 4), leaf);
    } else if (k < .3) {
      p.c.drawOval(
        Rect.fromCenter(center: Offset(x, y), width: 3.6, height: 4.8),
        Paint()
          ..shader = ui.Gradient.radial(Offset(x - .6, y - 1), 3, [
            bud.$1,
            bud.$2,
          ]),
      );
    } else {
      open(x, y, r, rot, light);
    }
  }
}

void _dao(_Pen p) {
  final rnd = _rng(59);
  p.ground(100, 182, 56);
  _roots(p, 12, _daoBark);
  const limbs = <_Limb>[
    (100, 184, 100, 146, 13, 9, 3),
    (100, 150, 74, 110, 7, 4, -5),
    (100, 148, 128, 108, 7, 4, 5),
    (100, 146, 102, 98, 6, 3.5, -3),
    (74, 112, 56, 84, 4, 2, -4),
    (76, 114, 86, 74, 3.5, 1.8, 3),
    (128, 110, 146, 82, 4, 2, 4),
    (126, 112, 116, 72, 3.5, 1.8, -3),
    (102, 100, 94, 56, 3, 1.6, -3),
    (102, 102, 112, 58, 3, 1.6, 3),
    (56, 86, 44, 70, 1.8, .9, -2),
    (56, 88, 46, 98, 1.6, .8, 2),
    (86, 76, 80, 58, 1.8, .9, -2),
    (146, 84, 158, 70, 1.8, .9, 2),
    (146, 86, 156, 98, 1.6, .8, -2),
    (116, 74, 122, 56, 1.8, .9, 2),
    (94, 58, 86, 42, 1.6, .8, -2),
    (112, 60, 120, 44, 1.6, .8, 2),
    (100, 60, 102, 38, 1.4, .7, 0),
  ];
  p.limbs(limbs, _daoBark);
  _alongTwigs(
    p,
    limbs,
    seed: 591,
    every: 3.6,
    thin: 2.1,
    bud: (const Color(0xFFFF9EC0), const Color(0xFFC2185B)),
    leaf: (const Color(0xFF9CCB6A), const Color(0xFF6E9E44)),
    open: (x, y, r, rot, light) {
      final tone = _toneOf(light, _daoPink.length);
      p
        ..flower(
          x,
          y,
          r * 1.05,
          _daoPink[math.max(0, tone - 1)],
          _daoPink[0],
          rot,
        )
        ..flower(
          x,
          y,
          r * .62,
          _daoPink[math.min(4, tone + 1)],
          const Color(0xFFFFE07A),
          rot + .6,
        );
    },
  );
  p.litter(rnd, 7, 96, _daoPink.sublist(2));
}

// ——— Apricot blossom, hoa mai (Vietnam): a gnarled, open tree of thin
// twigs with yellow five-petalled flowers, buds and bronze-green new leaves.

const _maiGold = [
  Color(0xFFEDA91E),
  Color(0xFFF8C230),
  Color(0xFFFFD84A),
  Color(0xFFFFE57A),
  Color(0xFFFFF3B0),
];
const _maiBark = (Color(0xFF9A6A48), Color(0xFF5A3824));

void _mai(_Pen p) {
  final rnd = _rng(61);
  p.ground(100, 182, 58);
  _roots(p, 12, _maiBark);
  const limbs = <_Limb>[
    (100, 182, 96, 150, 15, 11, 6),
    (96, 152, 92, 128, 11, 8, -5),
    (93, 132, 68, 106, 7, 4.5, -7),
    (94, 130, 124, 102, 7, 4.5, 8),
    (92, 128, 96, 92, 6, 3.5, 5),
    (68, 106, 48, 86, 4.5, 2.2, -5),
    (70, 108, 80, 80, 3.5, 1.8, 4),
    (124, 102, 148, 84, 4.5, 2.2, 5),
    (122, 104, 116, 74, 3.5, 1.8, -4),
    (96, 94, 88, 62, 3.5, 1.8, -4),
    (96, 96, 108, 58, 3, 1.5, 4),
    (48, 86, 36, 72, 2, 1, -3),
    (48, 88, 38, 96, 1.6, .8, 2),
    (80, 82, 74, 64, 1.8, .9, -2),
    (148, 84, 162, 72, 2, 1, 3),
    (146, 86, 158, 98, 1.6, .8, -2),
    (116, 76, 126, 60, 1.8, .9, 3),
    (88, 64, 78, 48, 1.6, .8, -2),
    (108, 60, 118, 44, 1.6, .8, 2),
    (108, 60, 100, 42, 1.4, .7, -2),
    (68, 106, 58, 112, 1.6, .8, 2),
    (124, 102, 136, 110, 1.6, .8, -2),
  ];
  p.limbs(limbs, _maiBark);
  _alongTwigs(
    p,
    limbs,
    seed: 611,
    every: 6.5,
    bud: (const Color(0xFFFFF0A0), const Color(0xFFB89A30)),
    leaf: (const Color(0xFFB5CC5C), const Color(0xFF728C30)),
    open: (x, y, r, rot, light) => p.flower(
      x,
      y,
      r,
      _maiGold[_toneOf(light, _maiGold.length)],
      const Color(0xFFE46A2E),
      rot,
    ),
  );
  p.litter(rnd, 7, 90, _maiGold.sublist(1, 4));
}

// ——— Flamboyant, phượng vĩ (Vietnam): a wide, flat umbrella of feathery
// leaves set alight with red-orange flowers, long seed pods hanging below.

const _fernTones = [
  (Color(0xFF3E7A36), Color(0xFF346A2E)),
  (Color(0xFF529544), Color(0xFF46863C)),
  (Color(0xFF6FB052), Color(0xFF60A048)),
  (Color(0xFF98CC6E), Color(0xFF86BE60)),
];
const _flame = [
  Color(0xFFB8261C),
  Color(0xFFD83A22),
  Color(0xFFEF5A2C),
  Color(0xFFFF7E3E),
  Color(0xFFFFA45C),
];

void _phuong(_Pen p) {
  final rnd = _rng(67);
  p.ground(100, 183, 78);
  _roots(p, 16, _wood);
  p.limbs(const [
    (100, 184, 100, 120, 16, 10, -2),
    (100, 124, 50, 98, 8, 3, -8),
    (100, 122, 150, 96, 8, 3, 8),
    (100, 118, 84, 84, 6, 3, -4),
    (100, 118, 118, 82, 6, 3, 4),
  ], _wood);
  // Long seed pods hanging under the crown.
  for (var i = 0; i < 3; i++) {
    final x = 70 + i * 30 + rnd() * 8;
    p.fill(_taper(x, 98, x + 1 + rnd() * 3, 116 + rnd() * 10, 1.8, 1.4, 2), (
      const Color(0xFF7A5232),
      const Color(0xFF4A2E1A),
    ), across: true);
  }
  const clumps = [
    (40.0, 92.0, 16.0, -.1),
    (64.0, 78.0, 20.0, .15),
    (92.0, 70.0, 22.0, .35),
    (122.0, 70.0, 22.0, .25),
    (148.0, 80.0, 20.0, 0.0),
    (166.0, 94.0, 14.0, -.3),
    (80.0, 94.0, 18.0, -.1),
    (118.0, 92.0, 18.0, -.25),
  ];
  for (final (i, (x, y, r, bias)) in clumps.indexed) {
    p.clump(
      x: x,
      y: y,
      r: r * 1.18,
      bias: bias,
      n: (r * 4.2).round(),
      len: 9,
      w: 2.8,
      shape: _Shape.slim,
      tones: _fernTones,
      seed: 670 + i,
      squash: .55,
      core: const Color(0xFF2E5E2A),
      spot: false,
    );
  }
  for (final (i, (x, y, r, bias)) in clumps.indexed) {
    p.blossoms(
      x: x,
      y: y - r * .25,
      r: r * .8,
      n: (r * 1.15).round(),
      size: 4.6,
      bias: bias + .1,
      tones: _flame,
      center: const Color(0xFFFFE07A),
      eye: const Color(0xFFFFD27A),
      seed: 680 + i,
      squash: .5,
    );
  }
  p.litter(rnd, 8, 120, _flame.sublist(1, 4));
}

// ——— Wisteria (China): a twisting vine trunk under a flat green roof hung
// with long purple flower trails.

const _wisteriaTones = [
  (Color(0xFF3E7A36), Color(0xFF346A2E)),
  (Color(0xFF55964A), Color(0xFF4A8640)),
  (Color(0xFF79B45E), Color(0xFF68A452)),
  (Color(0xFFA6D27E), Color(0xFF94C66E)),
];
const _wisteriaBark = (Color(0xFF9A7458), Color(0xFF5A4030));

void _wisteria(_Pen p) {
  final rnd = _rng(71);
  p.ground(100, 182, 64);
  p.limbs(const [
    (96, 184, 106, 70, 10, 6, 14),
    (106, 184, 96, 72, 8, 5, -14),
    (102, 76, 62, 62, 6, 2.5, -6),
    (102, 74, 142, 60, 6, 2.5, 6),
  ], _wisteriaBark);
  _crown(
    p,
    const [
      (56, 62, 16, .2),
      (82, 52, 20, .45),
      (114, 50, 20, .35),
      (144, 60, 16, .1),
      (100, 64, 20, .1),
    ],
    _wisteriaTones,
    seed: 71,
    core: const Color(0xFF2E6228),
    len: 10,
    w: 6,
    squash: .55,
  );
  for (var k = 0; k < 13; k++) {
    final x = 46 + k * 9 + (rnd() - .5) * 4;
    final top = 62 + (x - 100).abs() * .08 + rnd() * 6;
    final len = 30 + rnd() * 30 - (x - 100).abs() * .12;
    p.spots.add(Offset(x, top + 6));
    for (var y = top; y < top + len; y += 2.4) {
      final t = (y - top) / len, w = 6 * (1 - t * .75);
      for (var j = 0; j < 2; j++) {
        final fx = x + (rnd() - .5) * w * 2 + math.sin(t * 2) * 2;
        final light = .4 - t * .9 - (fx - 100) / 200 + (rnd() - .5) * .3;
        final c = switch (_toneOf(light, 5)) {
          0 => const Color(0xFF6A4AB8),
          1 => const Color(0xFF8466C9),
          2 => const Color(0xFFA98BE8),
          3 => const Color(0xFFC6AEF4),
          _ => const Color(0xFFE2D4FC),
        };
        p.oval(fx, y, 2.4 * (1 - t * .4), 1.9 * (1 - t * .4), c, rnd());
      }
    }
  }
  p.litter(rnd, 6, 100, const [Color(0xFFA98BE8), Color(0xFFC6AEF4)]);
}

// ——— Mugunghwa, the rose of Sharon (Korea): a vase-shaped shrub tree with
// large pink-violet flowers, each with a crimson heart and a pale stamen.

const _mugTones = [
  (Color(0xFF3E7A3A), Color(0xFF346A32)),
  (Color(0xFF4E9446), Color(0xFF428440)),
  (Color(0xFF6CAE58), Color(0xFF5C9E4E)),
  (Color(0xFF98CC7A), Color(0xFF86BE6C)),
  (Color(0xFFC8E6A8), Color(0xFFB6DC94)),
];

void _mugunghwa(_Pen p) {
  final rnd = _rng(73);
  p.ground(100, 182, 52);
  p.limbs(const [
    (96, 184, 80, 104, 6, 3, -3),
    (100, 184, 100, 92, 6, 3, 0),
    (104, 184, 122, 102, 6, 3, 3),
  ], _wood);
  _crown(
    p,
    const [
      (100, 60, 20, .5),
      (78, 74, 20, .3),
      (122, 74, 20, .15),
      (72, 100, 18, .05),
      (128, 98, 18, -.2),
      (100, 90, 22, .1),
      (88, 120, 14, -.2),
      (112, 118, 14, -.35),
    ],
    _mugTones,
    seed: 73,
    core: const Color(0xFF2E6230),
    vein: const Color(0xFFE6F4D8),
    len: 11,
    w: 8,
  );
  for (var i = 0; i < 14; i++) {
    final a = rnd() * _tau, d = math.sqrt(rnd());
    final x = 100 + math.cos(a) * d * 40, y = 88 + math.sin(a) * d * 36;
    final light = (100 - x) / 60 + (90 - y) / 50;
    p
      ..flower(
        x,
        y,
        7,
        light > .3 ? const Color(0xFFF4C4E8) : const Color(0xFFE7A3D8),
        const Color(0xFFFFF4D6),
        rnd() * 6,
        eye: const Color(0xFFB0124A),
        edge: const Color(0xFFC77EBA),
      )
      ..line(
        Offset(x, y),
        Offset(x + 2.5, y - 4),
        const Color(0xFFFFF4D6),
        1.2,
      );
  }
  p.tuft(146, 184, .8, rnd, _mugTones.sublist(2));
}

// ——— Lavender (France): a rounded grey-green bush with tall stems, each
// ending in a spike of purple florets.

const _lavLeaf = [
  (Color(0xFF6E8A6A), Color(0xFF5E7A5A)),
  (Color(0xFF86A07E), Color(0xFF76906E)),
  (Color(0xFFA6BC9C), Color(0xFF94AC8A)),
];
const _lavPurple = [
  Color(0xFF5A40A8),
  Color(0xFF6E54C4),
  Color(0xFF8A70DC),
  Color(0xFFA68CEA),
  Color(0xFFC6B2F6),
];

void _lavender(_Pen p) {
  final rnd = _rng(79);
  p.ground(100, 182, 52);
  final stems = <(double, double, double)>[];
  for (var i = 0; i < 26; i++) {
    final a = -math.pi / 2 + (i / 25 - .5) * 1.7 + (rnd() - .5) * .12;
    stems.add((a, 70 + rnd() * 34 - (a + math.pi / 2).abs() * 20, rnd()));
  }
  stems.sort((a, b) => a.$3.compareTo(b.$3));
  for (final (a, l, depth) in stems) {
    final tip = Offset(100 + math.cos(a) * l, 172 + math.sin(a) * l);
    p.line(const Offset(100, 172), tip, const Color(0xFF7E9A6A), 1.3);
    p.spots.add(tip);
    for (var k = 0; k < 9; k++) {
      final t = k / 8, o = tip - Offset(math.cos(a), math.sin(a)) * (t * 22);
      final light = .3 - t * .3 - (o.dx - 100) / 80 + depth * .4 - .2;
      final c = _lavPurple[_toneOf(light, _lavPurple.length)];
      for (final side in const [-1, 1]) {
        p.oval(
          o.dx + side * 1.9 * math.cos(a + math.pi / 2),
          o.dy + side * 1.9 * math.sin(a + math.pi / 2),
          2.1 * (1 - t * .3),
          1.6,
          c,
          a,
        );
      }
    }
  }
  p.clump(
    x: 100,
    y: 168,
    r: 26,
    n: 80,
    len: 12,
    w: 3,
    shape: _Shape.slim,
    tones: _lavLeaf,
    seed: 791,
    squash: .45,
    droop: 0,
    spot: false,
  );
}

// ——— Tulips (Netherlands): a bunch of cupped tulips in red, yellow, pink
// and orange over broad blue-green leaves.

const _tulipLeaf = [
  (Color(0xFF4E8A5E), Color(0xFF3E7A50)),
  (Color(0xFF6AA676), Color(0xFF58966A)),
  (Color(0xFF8CC296), Color(0xFF78B286)),
];

void _cup(_Pen p, double x, double y, double s, _Tone outer, _Tone inner) {
  p
    ..fill(
      Path()
        ..moveTo(x - 7 * s, y - 2 * s)
        ..quadraticBezierTo(x - 9 * s, y - 14 * s, x - 3 * s, y - 20 * s)
        ..quadraticBezierTo(x, y - 12 * s, x + 3 * s, y - 20 * s)
        ..quadraticBezierTo(x + 9 * s, y - 14 * s, x + 7 * s, y - 2 * s)
        ..quadraticBezierTo(x, y + 4 * s, x - 7 * s, y - 2 * s)
        ..close(),
      inner,
    )
    ..fill(
      Path()
        ..moveTo(x - 7.5 * s, y - 3 * s)
        ..quadraticBezierTo(x - 9 * s, y - 13 * s, x - 5 * s, y - 18 * s)
        ..quadraticBezierTo(x + 1 * s, y - 12 * s, x + 1 * s, y + 1.5 * s)
        ..quadraticBezierTo(x - 5 * s, y + 1.5 * s, x - 7.5 * s, y - 3 * s)
        ..close(),
      outer,
    )
    ..fill(
      Path()
        ..moveTo(x + 7.5 * s, y - 3 * s)
        ..quadraticBezierTo(x + 9 * s, y - 13 * s, x + 4 * s, y - 19 * s)
        ..quadraticBezierTo(x - 2 * s, y - 12 * s, x - 1 * s, y + 1.5 * s)
        ..quadraticBezierTo(x + 5 * s, y + 1.5 * s, x + 7.5 * s, y - 3 * s)
        ..close(),
      (outer.$2, outer.$2),
    );
  p.spots.add(Offset(x, y - 10 * s));
}

void _tulip(_Pen p) {
  final rnd = _rng(83);
  p.ground(100, 182, 48);
  for (final (x, y, a, l) in const [
    (92.0, 182.0, -2.1, 46.0),
    (108.0, 182.0, -1.0, 44.0),
    (98.0, 183.0, -1.75, 52.0),
    (104.0, 183.0, -1.35, 40.0),
  ]) {
    p.fill(_needle(x, y, a, l, 12), _tulipLeaf[(rnd() * 3).floor()]);
  }
  const flowers = [
    (74.0, 110.0, .95, 0),
    (126.0, 104.0, 1.0, 1),
    (98.0, 86.0, 1.1, 2),
    (88.0, 124.0, .85, 3),
    (114.0, 128.0, .9, 4),
    (60.0, 132.0, .75, 1),
    (140.0, 134.0, .78, 0),
  ];
  const colors = [
    (
      (Color(0xFFFF6F7E), Color(0xFFD8334A)),
      (Color(0xFFFF9AA4), Color(0xFFE5506A)),
    ),
    (
      (Color(0xFFFFE07A), Color(0xFFF2B024)),
      (Color(0xFFFFF0B0), Color(0xFFF7C94A)),
    ),
    (
      (Color(0xFFFFA8C8), Color(0xFFE5679A)),
      (Color(0xFFFFD0E2), Color(0xFFF08FB4)),
    ),
    (
      (Color(0xFFFFA45C), Color(0xFFE5672A)),
      (Color(0xFFFFC890), Color(0xFFF58A48)),
    ),
    (
      (Color(0xFFFFF4F8), Color(0xFFE9B6CC)),
      (Color(0xFFFFFFFF), Color(0xFFF3D2E0)),
    ),
  ];
  for (final (x, y, _, _) in flowers) {
    p.stroke(
      Path()
        ..moveTo(100 + (x - 100) * .15, 182)
        ..quadraticBezierTo(x, 160, x, y),
      const Color(0xFF5E9A5A),
      2.2,
    );
  }
  for (final (x, y, s, c) in flowers) {
    _cup(p, x, y, s, colors[c].$1, colors[c].$2);
  }
  p.fill(_needle(96, 183, -1.95, 30, 10), _tulipLeaf[2]);
}

// ——— Sunflowers (United States): three heads of different sizes on tall
// stems with big heart-shaped leaves.

const _sunLeaf = [
  (Color(0xFF3E8248), Color(0xFF336F3D)),
  (Color(0xFF4F9A4B), Color(0xFF428843)),
  (Color(0xFF74BA55), Color(0xFF62A84B)),
  (Color(0xFFA3D86C), Color(0xFF8BC85E)),
];

void _sunHead(_Pen p, double x, double y, double r, int seed) {
  final rnd = _rng(seed);
  p.spots.add(Offset(x, y - r * .2));
  for (var ring = 0; ring < 2; ring++) {
    final tone = ring == 1
        ? (const Color(0xFFFFE780), const Color(0xFFF8C044))
        : (const Color(0xFFF6B43A), const Color(0xFFE39A28));
    for (var i = 0; i < 18; i++) {
      final a = (i + ring * .5) / 18 * _tau + rnd() * .08;
      p.fill(
        _leaf(
          x + math.cos(a) * r * .38,
          y + math.sin(a) * r * .35,
          a,
          r * (ring == 1 ? .68 : .75),
          r * .34,
        ),
        tone,
      );
    }
  }
  p.ball(
    x,
    y,
    r * .5,
    const Color(0xFFA87040),
    const Color(0xFF6E4424),
    const Color(0xFF4A2C14),
  );
  for (var i = 0; i < 46; i++) {
    final a = i * 2.39996, d = math.sqrt(i / 46) * r * .44;
    p.dot(
      x + math.cos(a) * d,
      y + math.sin(a) * d,
      r * .035,
      const Color(0xB3CC9A5E),
    );
  }
}

void _sunflower(_Pen p) {
  final rnd = _rng(89);
  p.ground(100, 182, 50);
  const stem = (Color(0xFF8FC862), Color(0xFF5A9A3E));
  p.limbs(const [
    (128, 182, 130, 104, 4.5, 3.2, 6),
    (92, 182, 68, 112, 4, 3, -6),
    (100, 183, 94, 74, 6, 4, -5),
  ], stem);
  for (final (x, y, a, l, w, t) in const [
    (96.0, 150.0, -2.6, 34.0, 22.0, 1),
    (99.0, 132.0, -.4, 32.0, 21.0, 2),
    (126.0, 150.0, -.6, 26.0, 18.0, 1),
    (80.0, 138.0, -2.4, 24.0, 17.0, 0),
    (97.0, 112.0, -2.9, 24.0, 17.0, 3),
  ]) {
    p
      ..fill(_leaf(x, y, a, l, w), _sunLeaf[t])
      ..line(
        Offset(x, y),
        Offset(x + math.cos(a) * l * .85, y + math.sin(a) * l * .85),
        const Color(0x80E2F5BE),
        .8,
      );
  }
  _sunHead(p, 68, 108, 12, 891);
  _sunHead(p, 130, 100, 15, 892);
  _sunHead(p, 94, 68, 22, 893);
  p
    ..tuft(74, 184, .9, rnd, _sunLeaf.sublist(1))
    ..tuft(132, 184, .9, rnd, _sunLeaf.sublist(1));
}

// ——— Lotus (Vietnam): a small pond with round pads, two pink flowers on
// tall stems, a bud and a seed pod.

const _padTones = [
  (Color(0xFF3E8A50), Color(0xFF2E7040)),
  (Color(0xFF5AA866), Color(0xFF489456)),
  (Color(0xFF80C486), Color(0xFF6CB474)),
];

void _pad(_Pen p, double x, double y, double rx, double ry, _Tone tone) {
  final r = Rect.fromCenter(
    center: Offset(x, y),
    width: rx * 2,
    height: ry * 2,
  );
  final path = Path()
    ..moveTo(x, y)
    ..arcTo(r, -1.35, _tau - .35, false)
    ..close();
  p.fill(path, tone);
  for (var i = 0; i < 7; i++) {
    final a = -1.1 + i * .85;
    p.line(
      Offset(x, y),
      Offset(x + math.cos(a) * rx * .85, y + math.sin(a) * ry * .85),
      const Color(0x40E6F6DA),
      .6,
    );
  }
}

void _lotusFlower(_Pen p, double x, double y, double s) {
  p.spots.add(Offset(x, y - 8 * s));
  const outer = (Color(0xFFFFE4EE), Color(0xFFE0608E));
  const inner = (Color(0xFFFFF4F8), Color(0xFFF08AB0));
  for (final (a, l, w, tone) in [
    (-2.75, 17.0, 10.0, outer),
    (-.39, 17.0, 10.0, outer),
    (-2.3, 19.0, 10.5, outer),
    (-.84, 19.0, 10.5, outer),
    (-1.95, 20.0, 9.5, inner),
    (-1.2, 20.0, 9.5, inner),
    (-1.57, 21.0, 9.0, inner),
  ]) {
    p.fill(_needle(x, y, a, l * s, w * s), (tone.$1, tone.$2), down: true);
  }
  p.dot(x, y - 6 * s, 2.4 * s, const Color(0xFFFFD84A));
}

void _lotus(_Pen p) {
  final rnd = _rng(97);
  p.c.drawOval(
    Rect.fromCenter(center: const Offset(100, 176), width: 150, height: 34),
    Paint()
      ..shader = ui.Gradient.radial(
        const Offset(92, 172),
        80,
        const [Color(0xFFB4E6F4), Color(0xFF6CC4E0), Color(0xFF3E9EC4)],
        const [0, .6, 1],
      ),
  );
  for (var i = 0; i < 3; i++) {
    p.stroke(
      Path()..addOval(
        Rect.fromCenter(
          center: Offset(70 + i * 30, 178 + i * 2.0),
          width: 22,
          height: 5,
        ),
      ),
      const Color(0x66FFFFFF),
      .8,
    );
  }
  _pad(p, 58, 176, 18, 6, _padTones[1]);
  _pad(p, 140, 180, 20, 6.5, _padTones[0]);
  const stem = Color(0xFF5E9A4E);
  for (final (x0, x1, y1) in const [
    (88.0, 80.0, 108.0),
    (110.0, 120.0, 92.0),
    (100.0, 98.0, 132.0),
    (124.0, 140.0, 126.0),
    (78.0, 62.0, 140.0),
  ]) {
    p.stroke(
      Path()
        ..moveTo(x0, 178)
        ..quadraticBezierTo((x0 + x1) / 2 + 4, 150, x1, y1),
      stem,
      2.2,
    );
  }
  p.fill(
    Path()
      ..moveTo(140, 126)
      ..quadraticBezierTo(126, 118, 128, 108)
      ..quadraticBezierTo(140, 116, 152, 108)
      ..quadraticBezierTo(154, 118, 140, 126)
      ..close(),
    _padTones[2],
  );
  _lotusFlower(p, 80, 108, 1);
  _lotusFlower(p, 120, 92, 1.15);
  p
    ..fill(
      Path()
        ..moveTo(92, 124)
        ..lineTo(104, 124)
        ..quadraticBezierTo(103, 132, 98, 133)
        ..quadraticBezierTo(93, 132, 92, 124)
        ..close(),
      (const Color(0xFFC6E08A), const Color(0xFF7EA448)),
    )
    ..oval(98, 124, 6, 1.8, const Color(0xFFA8C870))
    ..fill(_needle(62, 141, -1.45, 15, 8), (
      const Color(0xFFFFD6E4),
      const Color(0xFFE0608E),
    ), down: true);
  for (var i = 0; i < 4; i++) {
    p.dot(94.5 + i * 2.4, 124 + (i % 2) * .6, .9, const Color(0xFF5E7A2E));
  }
  p.spots.add(Offset(64 + rnd() * 2, 136));
}
