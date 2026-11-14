part of 'garden_art.dart';

// Broadleaf trees and conifers. Each has its own silhouette, leaf, bark and
// one thing it is known by, so no two read alike even as small shapes.

typedef _Clump = (double, double, double, double);

void _crown(
  _Pen p,
  List<_Clump> clumps,
  List<_Tone> tones, {
  required int seed,
  Color? core,
  Color? vein,
  double len = 12,
  double w = 8,
  double density = 2.2,
  double droop = .35,
  double squash = .9,
  _Shape shape = _Shape.oval,
}) {
  final sorted = [...clumps]..sort((a, b) => a.$2.compareTo(b.$2));
  for (final (i, (x, y, r, bias)) in sorted.indexed) {
    p.clump(
      x: x,
      y: y,
      r: r,
      bias: bias,
      n: (r * density).round(),
      len: len,
      w: w,
      droop: droop,
      tones: tones,
      core: core,
      vein: vein,
      shape: shape,
      squash: squash,
      seed: seed * 31 + i,
    );
  }
}

/// Flared roots spreading into the ground at the foot of a trunk [w] wide.
void _roots(_Pen p, double w, _Tone bark) {
  final h = w * .8;
  p.fill(
    Path()
      ..moveTo(100 - w * 1.05, 185)
      ..quadraticBezierTo(100 - w * .5, 182, 100 - w * .45, 182 - h)
      ..lineTo(100 + w * .45, 182 - h)
      ..quadraticBezierTo(100 + w * .5, 182, 100 + w * 1.1, 185)
      ..quadraticBezierTo(100, 189, 100 - w * 1.05, 185)
      ..close(),
    bark,
    across: true,
  );
}

// ——— Oak (Germany): a broad, round crown over a stout trunk; acorns.

const _oakTones = [
  (Color(0xFF3E8248), Color(0xFF336F3D)),
  (Color(0xFF4F9A4B), Color(0xFF428843)),
  (Color(0xFF6AB452), Color(0xFF5AA44A)),
  (Color(0xFF91CD66), Color(0xFF7CBF5A)),
  (Color(0xFFC2E592), Color(0xFFA9D97C)),
];

void _oak(_Pen p) {
  final rnd = _rng(3);
  p.ground(100, 182, 66);
  _roots(p, 20, _wood);
  p.limbs(const [
    (100, 178, 100, 112, 22, 12, -3),
    (99, 132, 70, 96, 9, 4, -5),
    (101, 126, 132, 92, 9, 4, 5),
    (100, 116, 98, 78, 8, 4, 2),
  ], _wood);
  p
    ..stroke(
      Path()
        ..moveTo(95, 172)
        ..quadraticBezierTo(93, 150, 96, 130),
      const Color(0x596B4A2E),
      1,
    )
    ..stroke(
      Path()
        ..moveTo(104, 168)
        ..quadraticBezierTo(106, 150, 103, 134),
      const Color(0x596B4A2E),
      1,
    );
  _crown(
    p,
    const [
      (82, 50, 20, .5),
      (118, 52, 20, .35),
      (100, 62, 30, .3),
      (70, 78, 26, .1),
      (132, 76, 26, -.05),
      (58, 98, 18, -.15),
      (84, 98, 24, -.1),
      (118, 98, 24, -.25),
      (142, 96, 18, -.35),
      (100, 106, 22, -.3),
    ],
    _oakTones,
    seed: 3,
    core: const Color(0xFF2F6A3A),
    vein: const Color(0xFFEEF8D8),
  );
  p
    ..tuft(66, 183, 1, rnd, _oakTones.sublist(2))
    ..tuft(140, 184, .9, rnd, _oakTones.sublist(2));
  for (final (x, y) in const [(128.0, 186.0), (136.0, 187.0)]) {
    p
      ..ball(
        x,
        y,
        3.4,
        const Color(0xFFD4A86E),
        const Color(0xFFA87A48),
        const Color(0xFF7E5636),
      )
      ..solid(
        Path()
          ..moveTo(x - 3.6, y - .6)
          ..quadraticBezierTo(x, y - 5, x + 3.6, y - .6)
          ..close(),
        const Color(0xFF7E5636),
      );
  }
}

// ——— Apple (Kazakhstan): a compact, bright ball of a crown full of red
// apples, two fallen.

const _appleTones = [
  (Color(0xFF4C8F3A), Color(0xFF3F7C32)),
  (Color(0xFF5FA845), Color(0xFF4F9440)),
  (Color(0xFF7FC452), Color(0xFF6AB24A)),
  (Color(0xFFA7DB6A), Color(0xFF8FCB5E)),
  (Color(0xFFD2EE9A), Color(0xFFBBE184)),
];

void _apple(_Pen p) {
  final rnd = _rng(5);
  p.ground(100, 182, 58);
  _roots(p, 15, _wood);
  p.limbs(const [
    (100, 180, 100, 118, 15, 9, -2),
    (100, 130, 78, 106, 6, 3, -4),
    (100, 126, 124, 104, 6, 3, 4),
  ], _wood);
  _crown(
    p,
    const [
      (82, 58, 17, .5),
      (118, 60, 17, .35),
      (100, 70, 28, .3),
      (74, 84, 22, .1),
      (126, 84, 22, -.05),
      (100, 96, 22, -.1),
      (84, 106, 20, -.15),
      (116, 106, 20, -.3),
    ],
    _appleTones,
    seed: 5,
    core: const Color(0xFF3C7A33),
    vein: const Color(0xFFF2FAD8),
    len: 11,
    w: 7.5,
  );
  for (final (x, y) in const [
    (78.0, 82.0),
    (96.0, 62.0),
    (118.0, 74.0),
    (134.0, 92.0),
    (88.0, 104.0),
    (110.0, 112.0),
    (68.0, 98.0),
    (122.0, 56.0),
    (104.0, 88.0),
    (142.0, 78.0),
  ]) {
    p
      ..ball(
        x,
        y,
        4.8,
        const Color(0xFFFF9A86),
        const Color(0xFFE5483D),
        const Color(0xFFA82E2A),
      )
      ..line(
        Offset(x, y - 4.6),
        Offset(x + 1, y - 7),
        const Color(0xFF6B4A2E),
        .9,
      );
  }
  for (final (x, y) in const [(78.0, 186.0), (128.0, 187.0)]) {
    p.ball(
      x,
      y,
      4.4,
      const Color(0xFFFF9A86),
      const Color(0xFFE5483D),
      const Color(0xFFA82E2A),
    );
  }
  p.tuft(146, 184, .9, rnd, _appleTones.sublist(2));
}

// ——— Orange (Spain): a dense, glossy dark dome with oranges and a sprinkle
// of white orange blossom.

const _orangeTones = [
  (Color(0xFF245C30), Color(0xFF1E4E29)),
  (Color(0xFF2F7339), Color(0xFF27622F)),
  (Color(0xFF3F8C45), Color(0xFF357A3C)),
  (Color(0xFF5DAA55), Color(0xFF4C9748)),
  (Color(0xFF93CF7E), Color(0xFF7BBF6D)),
];

void _orange(_Pen p) {
  final rnd = _rng(7);
  p.ground(100, 182, 56);
  _roots(p, 13, _wood);
  p.limbs(const [
    (100, 180, 100, 124, 13, 8, 0),
    (100, 134, 82, 116, 5, 3, -3),
    (100, 132, 120, 114, 5, 3, 3),
  ], _wood);
  _crown(
    p,
    const [
      (100, 50, 24, .45),
      (78, 68, 22, .25),
      (122, 68, 22, .1),
      (70, 94, 20, -.05),
      (130, 94, 20, -.25),
      (100, 84, 26, .1),
      (86, 112, 18, -.2),
      (114, 112, 18, -.35),
    ],
    _orangeTones,
    seed: 7,
    core: const Color(0xFF1F4A28),
    vein: const Color(0xFFDDF2CF),
    len: 11,
    w: 6.5,
    density: 2.5,
  );
  for (final (x, y) in const [
    (80.0, 70.0),
    (104.0, 54.0),
    (122.0, 80.0),
    (92.0, 92.0),
    (136.0, 102.0),
    (66.0, 96.0),
    (110.0, 108.0),
    (86.0, 116.0),
    (118.0, 64.0),
  ]) {
    p
      ..ball(
        x,
        y,
        4.7,
        const Color(0xFFFFD08A),
        const Color(0xFFFF9A2E),
        const Color(0xFFD9690F),
      )
      ..dot(x + .6, y - 4.2, .9, const Color(0xFF2F6A2A));
  }
  for (final (x, y, r) in const [
    (94.0, 46.0, 1.0),
    (72.0, 84.0, 4.0),
    (128.0, 88.0, 2.0),
    (100.0, 74.0, 3.0),
    (116.0, 52.0, 5.0),
    (80.0, 104.0, 6.0),
  ]) {
    p.flower(x, y, 3, Colors.white, const Color(0xFFF5C542), r);
  }
  p
    ..ball(
      74,
      186,
      4.4,
      const Color(0xFFFFD08A),
      const Color(0xFFFF9A2E),
      const Color(0xFFD9690F),
    )
    ..tuft(132, 184, .9, rnd, _orangeTones.sublist(2));
}

// ——— Maple (Canada): a tall oval of five-lobed leaves in red, orange and
// gold; fallen leaves around it.

const _mapleTones = [
  (Color(0xFFA8321F), Color(0xFF8E2A1A)),
  (Color(0xFFC9452A), Color(0xFFB03A24)),
  (Color(0xFFE5663A), Color(0xFFCF5530)),
  (Color(0xFFF58F4A), Color(0xFFE77B3E)),
  (Color(0xFFFFC06A), Color(0xFFF7A955)),
];

void _maple(_Pen p) {
  final rnd = _rng(11);
  p.ground(100, 182, 56);
  _roots(p, 14, _wood);
  p.limbs(const [
    (100, 180, 100, 112, 14, 7, 0),
    (100, 128, 82, 100, 5, 2.5, -3),
    (100, 124, 120, 98, 5, 2.5, 3),
  ], _wood);
  _crown(
    p,
    const [
      (100, 40, 19, .55),
      (85, 58, 22, .4),
      (116, 58, 22, .25),
      (76, 84, 22, .1),
      (124, 84, 22, -.1),
      (100, 74, 26, .2),
      (88, 108, 20, -.2),
      (114, 108, 20, -.35),
    ],
    _mapleTones,
    seed: 11,
    core: const Color(0xFF8A2A1A),
    shape: _Shape.star,
    len: 12,
    w: 10,
    density: 2.4,
    droop: .2,
  );
  for (var i = 0; i < 7; i++) {
    final x = 100 + (rnd() - .5) * 100, y = 183 + rnd() * 6;
    p.fill(
      _star(x, y, rnd() * _tau, 7, 6),
      _mapleTones[1 + (rnd() * 4).floor()],
    );
  }
}

// ——— Birch (Russia): three slender white trunks with black marks, and a
// light, airy crown of small leaves that lets the sky through.

const _birchTones = [
  (Color(0xFF6E9E3A), Color(0xFF5E8A32)),
  (Color(0xFF86B648), Color(0xFF76A340)),
  (Color(0xFFA6CE5C), Color(0xFF92BE50)),
  (Color(0xFFC6E27A), Color(0xFFB2D46A)),
  (Color(0xFFE4F3A8), Color(0xFFD2EA92)),
];

const _birchBark = (Color(0xFFF7F4EE), Color(0xFFC9C1B4));

void _birch(_Pen p) {
  final rnd = _rng(13);
  p.ground(100, 182, 52);
  const trunks = <_Limb>[
    (92, 184, 82, 66, 7, 3, -3),
    (108, 184, 118, 58, 7, 3, 3),
    (100, 184, 100, 84, 5, 2.5, 0),
  ];
  p.limbs(trunks, _birchBark);
  for (final b in trunks) {
    for (var i = 0; i < 9; i++) {
      final t = .06 + i * .1 + rnd() * .04;
      final o = _along(b.$1, b.$2, b.$3, b.$4, b.$7, t);
      final w = b.$5 + (b.$6 - b.$5) * t;
      p.line(
        Offset(o.dx - w * (.1 + rnd() * .35), o.dy),
        Offset(o.dx + w * (.05 + rnd() * .3), o.dy + .4),
        const Color(0xFF3A3632),
        1 + rnd() * .8,
      );
    }
  }
  p.limbs(const [
    (86, 100, 70, 88, 2, 1, -2),
    (114, 96, 132, 84, 2, 1, 2),
  ], _birchBark);
  _crown(
    p,
    const [
      (84, 68, 18, .45),
      (118, 60, 20, .35),
      (100, 50, 15, .55),
      (74, 92, 16, .05),
      (128, 84, 18, -.1),
      (100, 80, 18, .15),
      (86, 108, 12, -.2),
      (116, 104, 12, -.3),
    ],
    _birchTones,
    seed: 13,
    len: 8,
    w: 6,
    density: 2.2,
    droop: .6,
  );
  p.tuft(70, 184, .8, rnd, _birchTones.sublist(1));
}

// ——— Ginkgo (China): an upright cone of golden fans, and a carpet of
// fallen fans.

const _ginkgoTones = [
  (Color(0xFFC98A1A), Color(0xFFB27A16)),
  (Color(0xFFDFA526), Color(0xFFCC9220)),
  (Color(0xFFF0C03A), Color(0xFFE3AE30)),
  (Color(0xFFFAD864), Color(0xFFF2C952)),
  (Color(0xFFFFF0A0), Color(0xFFFBE58A)),
];

void _ginkgo(_Pen p) {
  final rnd = _rng(17);
  p.ground(100, 182, 52);
  _roots(p, 12, _wood);
  p.limbs(const [
    (100, 180, 100, 60, 12, 4, 0),
    (100, 120, 80, 100, 4, 2, -2),
    (100, 110, 120, 92, 4, 2, 2),
    (100, 90, 86, 76, 3, 1.5, -2),
  ], _wood);
  _crown(
    p,
    const [
      (100, 30, 14, .55),
      (92, 48, 17, .45),
      (110, 50, 17, .3),
      (84, 72, 19, .25),
      (118, 72, 19, .05),
      (100, 64, 19, .3),
      (78, 98, 19, 0),
      (122, 98, 19, -.2),
      (100, 96, 21, 0),
      (90, 118, 15, -.25),
      (112, 118, 15, -.35),
    ],
    _ginkgoTones,
    seed: 17,
    core: const Color(0xFFB07818),
    shape: _Shape.fan,
    len: 11,
    w: 9,
    density: 2.3,
    droop: .2,
  );
  for (var i = 0; i < 14; i++) {
    final x = 100 + (rnd() - .5) * 110, y = 182 + rnd() * 8;
    p.fill(
      _fan(x, y, rnd() * _tau, 7, 6),
      _ginkgoTones[2 + (rnd() * 3).floor()],
    );
  }
}

// ——— Weeping willow (England): a leaning trunk and long green curtains
// that sweep down almost to the ground.

const _willowTones = [
  (Color(0xFF5E8A34), Color(0xFF527A2E)),
  (Color(0xFF76A440), Color(0xFF679238)),
  (Color(0xFF93BE52), Color(0xFF82AE48)),
  (Color(0xFFB4D86E), Color(0xFFA2CA60)),
  (Color(0xFFD6EC9A), Color(0xFFC6E286)),
];

void _willow(_Pen p) {
  final rnd = _rng(19);
  p.ground(100, 182, 64);
  _roots(p, 15, _wood);
  p.limbs(const [
    (98, 182, 104, 102, 15, 7, 5),
    (104, 112, 78, 82, 6, 3, -4),
    (104, 108, 130, 80, 6, 3, 4),
    (103, 104, 104, 66, 5, 3, 0),
  ], _wood);
  void strands(bool front) {
    for (var k = 0; k < 15; k++) {
      final x0 = 46 + k * 7.6 + (rnd() - .5) * 4;
      final y0 = 60 + (x0 - 104).abs() * .22 + rnd() * 6;
      final end = 132 + rnd() * 40 - (x0 - 104).abs() * .25;
      final drift = (x0 - 104) * .12;
      final bias = front ? .1 : -.45;
      for (var y = y0; y < end; y += 4.2) {
        final t = (y - y0) / (end - y0);
        final x = x0 + drift * t + math.sin(t * 3 + k) * 1.5;
        for (final side in const [-1, 1]) {
          final a = math.pi / 2 + side * (.5 + rnd() * .35);
          final light =
              bias - (x - 100) / 70 * .6 - t * .5 + (rnd() - .5) * .35;
          p.fill(
            _needle(x, y, a, 7 + rnd() * 3 - t * 2, 2.6),
            _willowTones[_toneOf(light, _willowTones.length)],
          );
        }
      }
    }
  }

  strands(false);
  _crown(
    p,
    const [
      (104, 56, 20, .5),
      (80, 68, 18, .3),
      (128, 66, 18, .15),
      (104, 72, 20, .2),
    ],
    _willowTones,
    seed: 19,
    shape: _Shape.slim,
    len: 10,
    w: 3,
    density: 3.4,
    droop: .8,
  );
  strands(true);
}

// ——— Olive (Greece): a gnarled, twisted trunk split by a hollow, silver
// grey-green leaves and small dark olives.

const _oliveTones = [
  (Color(0xFF5A6E4A), Color(0xFF4C5E3E)),
  (Color(0xFF6E8458), Color(0xFF5E7350)),
  (Color(0xFF8A9E70), Color(0xFF7A8F62)),
  (Color(0xFFAFC096), Color(0xFF9DB083)),
  (Color(0xFFD6E0C4), Color(0xFFC4D1AE)),
];

const _oliveBark = (Color(0xFFB4A089), Color(0xFF6B5A48));

void _olive(_Pen p) {
  final rnd = _rng(23);
  p.ground(100, 182, 62);
  _roots(p, 20, _oliveBark);
  p.limbs(const [
    (88, 184, 96, 118, 15, 8, 12),
    (112, 184, 104, 116, 13, 7, -11),
    (96, 122, 66, 90, 7, 3, -6),
    (104, 120, 134, 88, 7, 3, 6),
    (100, 118, 100, 74, 6, 3, 4),
    (66, 92, 52, 96, 3, 1.5, 2),
  ], _oliveBark);
  p
    ..oval(100, 160, 4.2, 12, const Color(0xFF3E2C1E))
    ..stroke(
      Path()
        ..moveTo(92, 176)
        ..quadraticBezierTo(90, 150, 97, 128),
      const Color(0x664A3A2C),
      1.2,
    );
  _crown(
    p,
    const [
      (70, 80, 20, .25),
      (100, 64, 24, .45),
      (132, 78, 20, .1),
      (86, 98, 18, -.05),
      (118, 96, 18, -.2),
      (150, 94, 12, -.3),
      (54, 96, 12, -.1),
    ],
    _oliveTones,
    seed: 23,
    shape: _Shape.slim,
    len: 12,
    w: 3.8,
    density: 3.6,
    droop: .25,
  );
  for (var i = 0; i < 12; i++) {
    final a = rnd() * _tau, d = rnd() * 26;
    final x = 100 + math.cos(a) * d * 1.6, y = 86 + math.sin(a) * d * .6;
    p.ball(
      x,
      y,
      2.3,
      i.isEven ? const Color(0xFF8A7090) : const Color(0xFFB6C26A),
      i.isEven ? const Color(0xFF4A3550) : const Color(0xFF7E8E3A),
      i.isEven ? const Color(0xFF2A1C2E) : const Color(0xFF55622A),
    );
  }
  p.tuft(146, 184, .8, rnd, _oliveTones.sublist(2));
}

// ——— Banyan (India): a vast, low crown held up by a buttressed trunk and
// a colonnade of aerial roots.

const _banyanTones = [
  (Color(0xFF2E6A36), Color(0xFF265A2E)),
  (Color(0xFF3A7E40), Color(0xFF316D37)),
  (Color(0xFF4E9A4B), Color(0xFF428843)),
  (Color(0xFF72B45E), Color(0xFF62A453)),
  (Color(0xFFA6D488), Color(0xFF92C676)),
];

const _banyanBark = (Color(0xFFB08868), Color(0xFF6E4E36));

void _banyan(_Pen p) {
  final rnd = _rng(29);
  p.ground(100, 183, 84);
  for (final (x, w) in const [
    (40.0, 2.2),
    (50.0, 3.0),
    (62.0, 6.0),
    (72.0, 2.4),
    (130.0, 2.4),
    (140.0, 6.0),
    (152.0, 3.0),
    (162.0, 2.2),
  ]) {
    p.fill(
      _taper(x, 108, x + (rnd() - .5) * 4, 184, w * .7, w),
      _banyanBark,
      across: true,
    );
  }
  _roots(p, 30, _banyanBark);
  p.limbs(const [
    (100, 184, 100, 104, 30, 16, 0),
    (100, 118, 52, 96, 10, 5, -6),
    (100, 114, 150, 94, 10, 5, 6),
    (100, 108, 96, 70, 9, 4, 3),
  ], _banyanBark);
  p.stroke(
    Path()
      ..moveTo(92, 180)
      ..quadraticBezierTo(90, 150, 94, 118)
      ..moveTo(108, 180)
      ..quadraticBezierTo(111, 150, 106, 120),
    const Color(0x664A3424),
    1.4,
  );
  _crown(
    p,
    const [
      (40, 94, 18, -.1),
      (62, 76, 24, .2),
      (92, 60, 28, .45),
      (124, 62, 26, .3),
      (150, 78, 24, .05),
      (168, 96, 16, -.3),
      (78, 98, 22, -.1),
      (110, 92, 26, .05),
      (140, 100, 20, -.25),
      (56, 106, 14, -.3),
      (160, 108, 12, -.4),
    ],
    _banyanTones,
    seed: 29,
    core: const Color(0xFF24552C),
    vein: const Color(0xFFE2F2D2),
    len: 12,
    w: 8.5,
    density: 2,
  );
}

// ——— Baobab (Madagascar): a huge bottle of a trunk, with short stubby
// branches like roots in the sky and small tufts of leaves.

const _baobabBark = (Color(0xFFE2CDB4), Color(0xFF9A7F64));
const _baobabTones = [
  (Color(0xFF3E7A36), Color(0xFF346A2E)),
  (Color(0xFF55964A), Color(0xFF4A8640)),
  (Color(0xFF79B45E), Color(0xFF68A452)),
  (Color(0xFFA6D27E), Color(0xFF94C66E)),
];

void _baobab(_Pen p) {
  final rnd = _rng(31);
  p.ground(100, 182, 58);
  p.limbs(const [
    (92, 100, 62, 72, 6, 3, -4),
    (96, 98, 76, 58, 6, 3, -3),
    (100, 98, 96, 46, 6, 3, 2),
    (104, 98, 116, 50, 6, 3, 3),
    (108, 100, 136, 62, 6, 3, 4),
    (110, 102, 146, 80, 5, 2.5, 3),
  ], _baobabBark);
  p.fill(
    Path()
      ..moveTo(76, 184)
      ..cubicTo(66, 150, 76, 120, 86, 100)
      ..lineTo(114, 100)
      ..cubicTo(126, 120, 136, 150, 124, 184)
      ..quadraticBezierTo(100, 190, 76, 184)
      ..close(),
    _baobabBark,
    across: true,
  );
  p
    ..stroke(
      Path()
        ..moveTo(88, 176)
        ..cubicTo(82, 150, 86, 126, 92, 106),
      const Color(0x4D6E5640),
      1.2,
    )
    ..stroke(
      Path()
        ..moveTo(108, 178)
        ..cubicTo(114, 150, 112, 126, 108, 106),
      const Color(0x4D6E5640),
      1.2,
    );
  for (final (i, (x, y)) in const [
    (62.0, 70.0),
    (76.0, 56.0),
    (96.0, 44.0),
    (116.0, 48.0),
    (136.0, 60.0),
    (146.0, 78.0),
  ].indexed) {
    p.clump(
      x: x,
      y: y - 2,
      r: 10,
      n: 22,
      len: 8,
      w: 5.5,
      tones: _baobabTones,
      seed: 310 + i,
      bias: .2 - (x - 100).abs() / 200,
      squash: .55,
    );
  }
  p.tuft(70, 184, .9, rnd, _baobabTones.sublist(1));
}

// ——— Tropical almond, cây bàng (Vietnam): straight trunk with tiers of
// level branches, broad leaves, some turned red.

const _bangTones = [
  (Color(0xFF3E8A3C), Color(0xFF347736)),
  (Color(0xFF55A447), Color(0xFF4A9340)),
  (Color(0xFF76BE58), Color(0xFF66AE4E)),
  (Color(0xFFA2D676), Color(0xFF90CA68)),
  (Color(0xFFCFEAA8), Color(0xFFBEE292)),
];
const _bangRed = [
  (Color(0xFFE07A3A), Color(0xFFC96A32)),
  (Color(0xFFC8432A), Color(0xFFA63624)),
];

void _bang(_Pen p) {
  final rnd = _rng(37);
  p.ground(100, 182, 70);
  _roots(p, 11, _wood);
  p.limbs(const [(100, 184, 100, 52, 11, 4, 0)], _wood);
  const tiers = [
    (154.0, 66.0, -.35),
    (126.0, 54.0, -.15),
    (99.0, 41.0, .05),
    (74.0, 28.0, .25),
    (52.0, 14.0, .45),
  ];
  for (final (k, (y, hw, bias)) in tiers.indexed) {
    p.limbs([
      (100, y + 4, 100 - hw * .85, y, 4, 1.5, -2),
      (100, y + 4, 100 + hw * .85, y, 4, 1.5, 2),
    ], _wood);
    final n = math.max(1, (hw / 13).round());
    for (var i = 0; i < n * 2 + 1; i++) {
      final x = 100 + (i - n) * hw / (n + .4);
      p.clump(
        x: x,
        y: y - 4,
        r: 13,
        n: 20,
        len: 11,
        w: 8.5,
        tones: _bangTones,
        seed: 370 + k * 10 + i,
        bias: bias - (x - 100) / 160,
        squash: .3,
        droop: .1,
        core: const Color(0xFF2E6A30),
        spot: i == n,
      );
    }
    for (var i = 0; i < 3; i++) {
      final x = 100 + (rnd() - .5) * hw * 1.6, y2 = y - 6 + rnd() * 6;
      p.fill(_leaf(x, y2, rnd() * _tau, 10, 7), _bangRed[(rnd() * 2).floor()]);
    }
  }
  p.litter(rnd, 5, 100, const [Color(0xFFE07A3A), Color(0xFFC8432A)]);
}

// ——— Galaxy (legend): a silver spiral trunk under a deep blue crown that
// glows, full of stars, with a crescent moon among the leaves.

const _galaxyTones = [
  (Color(0xFF2B2A7A), Color(0xFF24236A)),
  (Color(0xFF3B3A9E), Color(0xFF33328A)),
  (Color(0xFF5B5BD6), Color(0xFF4E4EC4)),
  (Color(0xFF8C8CF2), Color(0xFF7A7AE4)),
  (Color(0xFFC2C2FF), Color(0xFFB0B0FA)),
];

void _galaxy(_Pen p) {
  final rnd = _rng(41);
  p.c.drawCircle(
    const Offset(100, 80),
    84,
    Paint()
      ..shader = ui.Gradient.radial(const Offset(100, 80), 84, const [
        Color(0x668C8CF2),
        Color(0x00C2C2FF),
      ]),
  );
  p.ground(100, 182, 56);
  const silver = (Color(0xFFF0EEFF), Color(0xFF9E98D8));
  p.limbs(const [
    (94, 184, 104, 116, 11, 6, 10),
    (106, 184, 96, 116, 9, 5, -10),
    (100, 120, 76, 96, 5, 2.5, -3),
    (100, 118, 126, 94, 5, 2.5, 3),
  ], silver);
  _crown(
    p,
    const [
      (82, 52, 19, .5),
      (118, 54, 19, .35),
      (100, 64, 28, .3),
      (72, 82, 24, .1),
      (130, 80, 24, -.05),
      (86, 102, 20, -.15),
      (116, 102, 20, -.3),
    ],
    _galaxyTones,
    seed: 41,
    core: const Color(0xFF23226A),
    len: 11,
    w: 8,
  );
  for (var i = 0; i < 16; i++) {
    final x = 60 + rnd() * 80, y = 40 + rnd() * 70, r = .8 + rnd() * 1.6;
    p.c.drawCircle(
      Offset(x, y),
      r * 3,
      Paint()
        ..shader = ui.Gradient.radial(Offset(x, y), r * 3, const [
          Color(0xCCFFFFFF),
          Color(0x00FFFFFF),
        ]),
    );
    p.dot(x, y, r * .7, Colors.white);
  }
  p.solid(
    Path()
      ..addOval(Rect.fromCircle(center: const Offset(134, 44), radius: 9))
      ..addOval(Rect.fromCircle(center: const Offset(139, 40), radius: 8))
      ..fillType = PathFillType.evenOdd,
    const Color(0xFFFFE27A),
  );
  for (var i = 0; i < 6; i++) {
    final x = 40 + rnd() * 120, y = 20 + rnd() * 140;
    p.dot(x, y, 1.2, const Color(0xFFDCD8FF));
  }
}

// ——— Dalat pine, thông ba lá (Vietnam): a tall straight red-brown trunk
// with a high, open crown of needle tufts in level layers.

const _pineTones = [
  (Color(0xFF1F5A44), Color(0xFF194D3A)),
  (Color(0xFF2A7354), Color(0xFF236447)),
  (Color(0xFF3E8E66), Color(0xFF347D59)),
  (Color(0xFF62AE80), Color(0xFF52A072)),
  (Color(0xFF9CD6A8), Color(0xFF86C894)),
];
const _pineBark = (Color(0xFFC07A4E), Color(0xFF7A3A22));

void _pineTuft(_Pen p, double x, double y, double r, double bias, int seed) {
  final rnd = _rng(seed);
  p
    ..spots.add(Offset(x, y))
    ..oval(x, y + 1, r * .62, r * .28, const Color(0xFF194D3A));
  // Needles fan out to every side but reach furthest sideways, so a tuft
  // reads as a level cloud.
  final needles = <(double, double, double, double)>[];
  for (var i = 0; i < r * 5.5; i++) {
    final a = rnd() * _tau;
    final reach = r * (.55 + .45 * math.cos(a).abs()) * (.75 + rnd() * .45);
    final ox = (rnd() - .5) * r * .5, oy = (rnd() - .5) * r * .18;
    final light =
        -math.cos(a) * .45 - math.sin(a) * .8 + bias + (rnd() - .5) * .4;
    needles.add((a, light, reach, ox + oy * 0));
  }
  needles.sort((a, b) => a.$2.compareTo(b.$2));
  for (final (a, light, l, ox) in needles) {
    p.fill(
      _needle(x + ox, y + math.sin(a) * 1.5, a, l, 2.4),
      _pineTones[_toneOf(light, _pineTones.length)],
    );
  }
}

void _pine(_Pen p) {
  final rnd = _rng(43);
  p.ground(100, 182, 46);
  p.limbs(const [
    (100, 184, 100, 30, 10, 4, 0),
    (100, 104, 54, 94, 3.5, 1.6, -3),
    (100, 100, 146, 90, 3.5, 1.6, 3),
    (100, 84, 68, 74, 3.2, 1.5, -2),
    (100, 80, 134, 70, 3.2, 1.5, 2),
    (100, 62, 80, 52, 3, 1.4, -2),
    (100, 58, 122, 48, 3, 1.4, 2),
  ], _pineBark);
  for (var i = 0; i < 12; i++) {
    final y = 112.0 + i * 6;
    p.line(
      Offset(97 + rnd() * 2, y),
      Offset(100 + rnd() * 3, y + 2),
      const Color(0x805A2614),
      1,
    );
  }
  for (final (i, (x, y, r, bias)) in const [
    (52.0, 94.0, 19.0, -.35),
    (148.0, 90.0, 19.0, -.45),
    (68.0, 74.0, 21.0, -.1),
    (134.0, 70.0, 21.0, -.2),
    (100.0, 84.0, 17.0, -.15),
    (80.0, 52.0, 20.0, .2),
    (122.0, 48.0, 20.0, .1),
    (100.0, 64.0, 16.0, .15),
    (100.0, 30.0, 18.0, .45),
  ].indexed) {
    _pineTuft(p, x, y, r, bias, 430 + i);
  }
  for (final (x, y) in const [(70.0, 186.0), (132.0, 185.0)]) {
    p.ball(
      x,
      y,
      4.2,
      const Color(0xFFD29A66),
      const Color(0xFF9A6438),
      const Color(0xFF6A3E20),
    );
    p.line(Offset(x - 3, y), Offset(x + 3, y), const Color(0xFF6A3E20), .7);
  }
  p.tuft(148, 184, .8, rnd, _pineTones.sublist(2));
}

// ——— Norway spruce under snow (Norway): a dark blue-green cone in tiers,
// snow lying on every tier and around the foot.

const _firTones = [
  (Color(0xFF1E4E4E), Color(0xFF184242)),
  (Color(0xFF276462), Color(0xFF215756)),
  (Color(0xFF347E78), Color(0xFF2D6E69)),
  (Color(0xFF54A096), Color(0xFF47908A)),
  (Color(0xFF90CCC2), Color(0xFF7ABEB4)),
];

void _snowpine(_Pen p) {
  final rnd = _rng(47);
  p
    ..oval(100, 184, 62, 9, const Color(0xFFE3EEF8))
    ..oval(98, 182, 56, 7, const Color(0xFFF8FBFF));
  p.fill(_taper(100, 186, 100, 140, 13, 9), _wood, across: true);
  const tiers = [
    (114.0, 162.0, 60.0, -.25),
    (90.0, 138.0, 50.0, -.1),
    (66.0, 112.0, 40.0, .05),
    (44.0, 86.0, 30.0, .2),
    (22.0, 60.0, 19.0, .35),
  ];
  for (final (top, bot, hw, bias) in tiers) {
    p.spots.add(Offset(100, (top + bot) / 2));
    p.solid(
      Path()
        ..moveTo(100, top)
        ..lineTo(100 - hw, bot)
        ..quadraticBezierTo(100, bot + 9, 100 + hw, bot)
        ..close(),
      const Color(0xFF173E3C),
    );
    final needles = <(double, double, double, double, double)>[];
    for (var i = 0; i < hw * 3.1; i++) {
      final u = rnd() * 2 - 1, v = math.sqrt(rnd());
      final x = 100 + u * hw * v;
      final y = top + (bot - top) * v + 7 * (1 - u * u) * v - 3;
      final dir = math.atan2(1, u * 1.5) + (rnd() - .5) * .5;
      final light = -u * .85 + (.45 - v) * .7 + bias + (rnd() - .5) * .38;
      needles.add((x, y, dir, light, v));
    }
    needles.sort(
      (a, b) => (a.$5 * .5 + a.$4 * .5).compareTo(b.$5 * .5 + b.$4 * .5),
    );
    for (final (x, y, dir, light, _) in needles) {
      final l = 10 + rnd() * 7;
      p.fill(
        _leaf(
          x - math.cos(dir) * l * .3,
          y - math.sin(dir) * l * .3,
          dir,
          l,
          4,
        ),
        _firTones[_toneOf(light, _firTones.length)],
      );
    }
    // Snow along the tier's sagging edge, and a cap near its top.
    for (var i = 0; i < 7; i++) {
      final u = -.85 + i * .28;
      final x = 100 + u * hw, y = bot + 7 * (1 - u * u) - 5;
      p
        ..oval(x + 1, y + 1.6, hw * .13, 2.6, const Color(0xFFC9DCEE))
        ..oval(x, y, hw * .13, 2.6, Colors.white);
    }
    p
      ..oval(100, top + (bot - top) * .3, hw * .2, 3, const Color(0xFFC9DCEE))
      ..oval(99, top + (bot - top) * .3 - 1.4, hw * .2, 2.8, Colors.white);
  }
  for (var i = 0; i < 14; i++) {
    final x = 30 + rnd() * 140, y = 20 + rnd() * 150;
    p.dot(x, y, .9 + rnd() * 1.2, const Color(0xFFCFE0F4));
  }
}
