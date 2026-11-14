part of 'garden_art.dart';

// How a plant is shown: its forms as it grows (a sprout, a young plant, then
// the grown drawing scaled up), the bloom and withered states, the sunlit
// patch of the focus screen, and the garden grid. Each form is recorded once
// into a Picture and replayed, so a frame only moves and scales it.

/// How a species looks between its sprout and its grown form.
enum _Young {
  /// A thin trunk with a few small clumps in the species' leaf tones.
  tree,

  /// A small fir of three tiers.
  conifer,

  /// A short stem with a few fronds.
  palm,

  /// The grown drawing, only smaller: flowers, shrubs and mushrooms.
  small,
}

/// A species' drawing and how it grows.
class _Art {
  final void Function(_Pen) draw;
  final _Young young;

  /// Leaf tones, darkest first, for its young form and fallen leaves.
  final List<_Tone> tones;
  final _Tone bark;

  /// How far wind sways it.
  final double stiff;
  const _Art(
    this.draw, {
    required this.tones,
    this.young = _Young.tree,
    this.bark = _wood,
    this.stiff = 1,
  });
}

const _wood = (Color(0xFFC49468), Color(0xFF7E5636));

final _pictures = <String, ui.Picture>{};
final _bloomSpots = <String, List<Offset>>{};

ui.Picture _record(String key, void Function(_Pen) draw) =>
    _pictures[key] ??= () {
      final recorder = ui.PictureRecorder();
      final pen = _Pen(Canvas(recorder));
      draw(pen);
      _bloomSpots[key] = _pickSpots(pen.spots, key.hashCode);
      return recorder.endRecording();
    }();

/// Up to nine places for bloom flowers, spread over the crown.
List<Offset> _pickSpots(List<Offset> spots, int seed) {
  if (spots.isEmpty) {
    return [
      for (var i = 0; i < 7; i++)
        Offset(100 + math.cos(i * 0.9) * 26, 90 + math.sin(i * 0.9) * 22),
    ];
  }
  final rnd = _rng(seed & 0xffff);
  final step = math.max(1, spots.length / 9);
  return [
    for (var i = 0.0; i < spots.length && i < 9 * step; i += step)
      spots[i.floor()] + Offset((rnd() - .5) * 12, (rnd() - .5) * 10),
  ];
}

// Dry, grey-brown colours for a withered plant.
const _dry = <double>[
  .25, .35, .10, 0, 24, //
  .22, .30, .09, 0, 18,
  .18, .25, .08, 0, 14,
  0, 0, 0, 1, 0,
];

double _step(double v, double a, double b) {
  final x = ((v - a) / (b - a)).clamp(0.0, 1.0);
  return x * x * (3 - 2 * x);
}

/// Draws species [id] at growth [g] in its 200 box, swaying with time [t].
void _plant(
  Canvas c,
  String id,
  double g,
  double t,
  bool still, {
  double bloom = 0,
  bool withered = false,
}) {
  final key = _arts.containsKey(id) ? id : defaultSpecies;
  final art = _arts[key]!;
  final grown = _record('$key/grown', art.draw);
  final sway = still
      ? 0.0
      : (math.sin(t * 1.1 + key.length) * .014 + math.sin(t * 2.3) * .004) *
            art.stiff;

  void pose(double scale, double rot, double opacity, void Function() draw) {
    if (opacity <= .001) return;
    c
      ..save()
      ..translate(100, 182)
      ..rotate(rot)
      ..scale(scale)
      ..translate(-100, -182);
    if (opacity < 1) {
      c.saveLayer(null, Paint()..color = Color.fromRGBO(0, 0, 0, opacity));
    }
    draw();
    if (opacity < 1) c.restore();
    c.restore();
  }

  if (withered) {
    pose(1, -.06, 1, () {
      c
        ..saveLayer(null, Paint()..colorFilter = const ColorFilter.matrix(_dry))
        ..drawPicture(grown)
        ..restore();
    });
    final pen = _Pen(c), rnd = _rng(key.length * 7 + 3);
    pen.litter(rnd, 7, 90, const [
      Color(0xFFA88A5E),
      Color(0xFF8E7450),
      Color(0xFFB9A07A),
    ]);
    return;
  }
  final small = art.young == _Young.small;
  final sprout = 1 - _step(g, .11, .16);
  final young = small ? 0.0 : _step(g, .11, .16) * (1 - _step(g, .42, .48));
  final full = small ? _step(g, .11, .16) : _step(g, .42, .48);
  pose(.45 + .55 * _step(g, 0, .12), sway * 1.6, sprout, () {
    c.drawPicture(_record('sprout', _sprout));
  });
  pose(.75 + .25 * _step(g, .14, .45), sway, young, () {
    c.drawPicture(_record('$key/young', (p) => _youngForm(p, art)));
  });
  final k = small ? .42 + .58 * _step(g, .12, 1) : .62 + .38 * _step(g, .45, 1);
  pose(k, sway * .8, full, () {
    c.drawPicture(grown);
    if (bloom > 0) _bloom(c, _bloomSpots['$key/grown']!, bloom, t, still);
  });
}

/// White flowers opening one by one at [spots], each with a glint.
void _bloom(Canvas c, List<Offset> spots, double bloom, double t, bool still) {
  final pen = _Pen(c);
  for (var i = 0; i < spots.length; i++) {
    final b = (bloom * spots.length * .9 - i * .8).clamp(0.0, 1.0);
    if (b <= 0) continue;
    final pop = b < 1 ? b * (1.7 - .7 * b) : 1.0, s = spots[i];
    pen.flower(
      s.dx,
      s.dy,
      5.6 * pop,
      Colors.white,
      const Color(0xFFFFC94A),
      i * 1.3,
      edge: const Color(0x33B08AA0),
    );
    if (b > .5) {
      final r = (1.8 + (still ? .4 : math.sin(t * 3 + i)) * .9) * b;
      final o = s + const Offset(6, -6);
      c.drawPath(
        Path()
          ..moveTo(o.dx, o.dy - r * 2)
          ..quadraticBezierTo(o.dx, o.dy, o.dx + r * 2, o.dy)
          ..quadraticBezierTo(o.dx, o.dy, o.dx, o.dy + r * 2)
          ..quadraticBezierTo(o.dx, o.dy, o.dx - r * 2, o.dy)
          ..quadraticBezierTo(o.dx, o.dy, o.dx, o.dy - r * 2),
        Paint()..color = const Color(0xF2FFF6C8),
      );
    }
  }
}

/// Two seed leaves on curved stems: the first form of every species.
void _sprout(_Pen p) {
  p.oval(100, 183, 16, 3.2, const Color(0x472E4A2A));
  final stem = _Pen(p.c);
  stem.stroke(
    Path()
      ..moveTo(99, 183)
      ..quadraticBezierTo(98, 166, 90, 152),
    const Color(0xFF6FAE4E),
    3,
  );
  stem.stroke(
    Path()
      ..moveTo(101, 183)
      ..quadraticBezierTo(103, 170, 110, 162),
    const Color(0xFF6FAE4E),
    2.6,
  );
  p
    ..fill(_leaf(91, 153, -2.55, 26, 19), (
      const Color(0xFF8FCB72),
      const Color(0xFF3F8048),
    ))
    ..line(
      const Offset(91, 153),
      const Offset(72, 140),
      const Color(0x99CDEBB8),
      .9,
    )
    ..fill(_leaf(109, 162, -.35, 20, 15), (
      const Color(0xFFA6E0B4),
      const Color(0xFF5FAE84),
    ))
    ..line(
      const Offset(109, 162),
      const Offset(126, 156),
      const Color(0x99E2F6E6),
      .8,
    );
}

/// The young form between the sprout and the grown plant.
void _youngForm(_Pen p, _Art art) {
  final tones = art.tones;
  p.ground(100, 183, 26);
  switch (art.young) {
    case _Young.conifer:
      p.fill(_taper(100, 184, 100, 150, 5, 3), art.bark, across: true);
      final rnd = _rng(9);
      for (final (top, bot, hw) in const [
        (128.0, 162.0, 26.0),
        (108.0, 142.0, 20.0),
        (90.0, 120.0, 13.0),
      ]) {
        for (var i = 0; i < hw * 3; i++) {
          final u = rnd() * 2 - 1, v = math.sqrt(rnd());
          final x = 100 + u * hw * v, y = top + (bot - top) * v;
          final dir = math.atan2(1, u * 1.5) + (rnd() - .5) * .5;
          final light = -u * .85 + (.45 - v) * .7 + (rnd() - .5) * .4;
          p.fill(
            _needle(x, y, dir, 8 + rnd() * 5, 3.2),
            tones[_toneOf(light, tones.length)],
          );
        }
      }
    case _Young.palm:
      p.fill(_taper(100, 184, 102, 140, 7, 5, -3), art.bark, across: true);
      for (final (a, l) in const [
        (-2.7, 30.0),
        (-1.9, 26.0),
        (-1.2, 28.0),
        (-.4, 30.0),
        (-3.3, 24.0),
      ]) {
        final light = -math.cos(a) * .4 - math.sin(a) * .4;
        p.fill(
          _needle(102, 140, a + .25, l, 9),
          tones[_toneOf(light, tones.length)],
        );
      }
    case _Young.tree || _Young.small:
      p
        ..fill(_taper(100, 184, 100, 128, 5, 2.6, -2), art.bark, across: true)
        ..fill(_taper(100, 150, 112, 140, 2, 1, 2), art.bark, across: true)
        ..fill(_leaf(112, 140, -.6, 12, 8), tones[tones.length - 2]);
      for (final (i, (x, y, r, bias)) in const [
        (88.0, 128.0, 11.0, .1),
        (112.0, 126.0, 12.0, -.1),
        (100.0, 114.0, 15.0, .35),
      ].indexed) {
        p.clump(
          x: x,
          y: y,
          r: r,
          bias: bias,
          n: (r * 2.4).round(),
          len: 9,
          w: 6.5,
          tones: tones,
          seed: 70 + i,
          core: tones.first.$2,
        );
      }
  }
}

/// A patch of grass in a pool of sunlight, under a plant on the focus screen.
void _patch(Canvas c) {
  c
    ..save()
    ..translate(100, 170)
    ..scale(1, .32)
    ..drawCircle(
      Offset.zero,
      124,
      Paint()
        ..shader = ui.Gradient.radial(Offset.zero, 124, const [
          Color(0x59FFF6D6),
          Color(0x00FFF6D6),
        ]),
    )
    ..scale(1, .29 / .32)
    ..drawCircle(
      Offset.zero,
      86,
      Paint()
        ..shader = ui.Gradient.radial(
          Offset.zero,
          86,
          const [
            Color(0xFAF6FFD9),
            Color(0xE6CDEE9E),
            Color(0x669FD58A),
            Color(0x009FD58A),
          ],
          const [0, .45, .78, 1],
        ),
    )
    ..restore();
}

// The garden grid's land.
const _grassTop = Color(0xFFB6F2A2), _grassBottom = Color(0xFF84D880);
const _lipLeft = Color(0xFF5CBE6C), _lipRight = Color(0xFF3FA05A);
const _soilLeft = [Color(0xFFC48E58), Color(0xFF9A683D)];
const _soilRight = [Color(0xFF93633A), Color(0xFF6C4425)];

Offset _iso(double cx, double cy, double w, double h, double u, double v) =>
    Offset(cx + (u - v) * w / 2, cy - h / 2 + (u + v) * h / 2);

Path _poly(List<Offset> pts) => Path()..addPolygon(pts, true);

/// A diamond of grass [w] wide and [h] tall centred on [cx], [cy], over [d]
/// of soil, with [n] cells a side.
void _land(
  Canvas c,
  double cx,
  double cy,
  double w,
  double h,
  double d,
  int n,
) {
  final l = Offset(cx - w / 2, cy), r = Offset(cx + w / 2, cy);
  final t = Offset(cx, cy - h / 2), b = Offset(cx, cy + h / 2);
  final down = Offset(0, d), lip = Offset(0, math.max(3.0, d * .24));
  Paint grad(List<Color> colors) => Paint()
    ..shader = ui.Gradient.linear(
      Offset(0, cy),
      Offset(0, cy + h / 2 + d),
      colors,
    );
  c
    ..drawPath(_poly([l, b, b + down, l + down]), grad(_soilLeft))
    ..drawPath(_poly([r, b, b + down, r + down]), grad(_soilRight))
    ..drawPath(_poly([l, b, b + lip, l + lip]), Paint()..color = _lipLeft)
    ..drawPath(_poly([r, b, b + lip, r + lip]), Paint()..color = _lipRight)
    ..drawPath(
      _poly([t, r, b, l]),
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(0, cy - h / 2),
          Offset(0, cy + h / 2),
          const [_grassTop, _grassBottom],
        ),
    );
  final cell = Paint()..color = const Color(0x24FFFFFF);
  for (var i = 0; i < n; i++) {
    for (var j = 0; j < n; j++) {
      if ((i + j).isOdd) {
        c.drawPath(
          _poly([
            _iso(cx, cy, w, h, i / n, j / n),
            _iso(cx, cy, w, h, (i + 1) / n, j / n),
            _iso(cx, cy, w, h, (i + 1) / n, (j + 1) / n),
            _iso(cx, cy, w, h, i / n, (j + 1) / n),
          ]),
          cell,
        );
      }
    }
  }
  c.drawPath(
    Path()
      ..moveTo(l.dx, l.dy)
      ..lineTo(t.dx, t.dy)
      ..lineTo(r.dx, r.dy),
    Paint()
      ..color = const Color(0x80FFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1,
  );
}

/// Cells in a fixed shuffled order, so plants spread over the grid instead
/// of filling it row by row, and keep their place as more are planted.
List<(int, int)> _cellOrder(int n) {
  final cells = [
    for (var i = 0; i < n; i++)
      for (var j = 0; j < n; j++) (i, j),
  ];
  final r = _rng(n * 31 + 7);
  for (var i = cells.length - 1; i > 0; i--) {
    final j = (r() * (i + 1)).floor();
    final c = cells[i];
    cells[i] = cells[j];
    cells[j] = c;
  }
  return cells;
}

void _garden(
  Canvas c,
  double cx,
  double cy,
  double w,
  int n,
  List<Plant> plants,
) {
  final h = w / 2, d = w * .035 + 9, tw = w / n;
  _land(c, cx, cy, w, h, d, n);
  final order = _cellOrder(n);
  final placed =
      [
        for (var i = 0; i < plants.length && i < order.length; i++)
          (order[i], plants[i]),
      ]..sort((a, b) {
        final s = (a.$1.$1 + a.$1.$2).compareTo(b.$1.$1 + b.$1.$2);
        return s != 0 ? s : a.$1.$1.compareTo(b.$1.$1);
      });
  for (final ((i, j), p) in placed) {
    final q = _iso(cx, cy, w, h, (i + .5) / n, (j + .5) / n);
    final s = tw / 140;
    c
      ..save()
      ..translate(q.dx, q.dy + tw * .04)
      ..scale(s)
      ..translate(-100, -182);
    _plant(
      c,
      p.species,
      p.growth,
      7.3,
      true,
      bloom: p.bloomed ? 1 : 0,
      withered: p.withered,
    );
    c.restore();
  }
}
