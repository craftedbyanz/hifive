part of 'garden_art.dart';

// The garden's weather, in the plants' illustrated manner: a soft sky wash,
// painted clouds lit from above, slanting sunbeams, rain in two depths with
// ripples and splashes, mist, a rainbow once the rain has passed.
//
// It is cheap to animate. The land and its plants sit on a layer of their
// own that never repaints; the sky behind and the weather in front are two
// thin layers. Everything soft (the sky, clouds, beams, mist, a cloud's
// shadow) is drawn once into an image and per frame only moved or faded;
// blurs never run per frame. Per frame only small sharp marks are drawn:
// raindrops in four batched calls, motes, ripples, splashes and glints.

/// Images of soft weather, by state, part and scene size.
final _weatherImages = <String, (ui.Image, Rect)>{};

/// The image [key], drawn by [draw] once inside [box] at [scale] pixels a
/// point, with the box it covers.
(ui.Image, Rect) _soft(
  String key,
  Rect box,
  double scale,
  void Function(Canvas) draw,
) => _weatherImages[key] ??= () {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder)
    ..scale(scale)
    ..translate(-box.left, -box.top);
  draw(canvas);
  final image = recorder.endRecording().toImageSync(
    (box.width * scale).ceil(),
    (box.height * scale).ceil(),
  );
  return (image, box);
}();

final _imagePaint = Paint()..filterQuality = FilterQuality.low;

/// Draws [soft] moved by [at] at [opacity].
void _put(
  (ui.Image, Rect) soft,
  Canvas c, [
  Offset at = Offset.zero,
  double opacity = 1,
]) {
  final (image, box) = soft;
  if (opacity <= .004) return;
  _imagePaint.color = Color.fromRGBO(0, 0, 0, opacity.clamp(0.0, 1.0));
  c.drawImageRect(
    image,
    Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
    box.shift(at),
    _imagePaint,
  );
}

/// Smooth back and forth between 0 and 1 over [period] seconds.
double _ease(double t, double period) =>
    .5 - .5 * math.cos(t * math.pi / period);

/// How a painted cloud is coloured: its fill from top to bottom and the
/// shade pooling under it.
typedef _CloudLook = (List<Color>, Color);

const _litCloud = [Color(0xFFFFFFFF), Color(0xFFF3F1F8), Color(0xFFD9DAEC)];
const _greyCloud = [Color(0xFFF2F3F8), Color(0xFFD5D8E6), Color(0xFFAEB3CB)];
const _rainCloud = [Color(0xFFD3D7E6), Color(0xFFA9AFC8), Color(0xFF7E86A8)];

/// One cloud in a scene: its look, seed, place (x across the width, y down
/// the sky), size, how many seconds it takes to drift one way, which way it
/// starts, and how strongly it shows.
typedef _CloudSpot = (
  _CloudLook,
  int,
  double,
  double,
  double,
  double,
  double,
  double,
);

/// A cumulus [s] wide (1 is about 140 points) around the origin: lobes in an
/// arch, lit from above and shaded below, small puffs breaking the outline
/// as paint spreads on wet paper, and pigment gathering at the edge.
void _paintCloud(Canvas c, double s, _CloudLook look, int seed) {
  final (fill, shade) = look;
  final r = _rng(seed);
  final n = 6 + (r() * 3).floor();
  final lobes = <(Offset, double)>[];
  for (var i = 0; i < n; i++) {
    final q = i / (n - 1), arch = math.sin(q * math.pi);
    lobes.add((
      Offset(
        (q - .5) * 70 * s + (r() - .5) * 8 * s,
        -arch * 14 * s - r() * 6 * s,
      ),
      (13 + arch * 13 + r() * 4) * s,
    ));
  }
  c.drawOval(
    Rect.fromCenter(center: Offset(0, 9 * s), width: 88 * s, height: 18 * s),
    Paint()
      ..color = shade.withValues(alpha: .55)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 3 * s),
  );
  var body = Path();
  for (final (o, rr) in lobes) {
    final lobe = Path()..addOval(Rect.fromCircle(center: o, radius: rr));
    for (var j = 0; j < 3; j++) {
      final a = -math.pi * (.12 + r() * .76);
      lobe.addOval(
        Rect.fromCircle(
          center: o + Offset(math.cos(a), math.sin(a)) * rr * .86,
          radius: rr * (.2 + r() * .16),
        ),
      );
    }
    body = Path.combine(ui.PathOperation.union, body, lobe);
  }
  final b = body.getBounds();
  c
    ..drawPath(
      body,
      Paint()
        ..shader = ui.Gradient.linear(b.topCenter, b.bottomCenter, fill, const [
          0,
          .55,
          1,
        ])
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 1.4 * s),
    )
    ..drawPath(
      body,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6 * s
        ..color = shade.withValues(alpha: .28)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 1.3 * s),
    );
  final rim = Paint()
    ..color = const Color(0x45FFFFFF)
    ..maskFilter = MaskFilter.blur(BlurStyle.normal, 2.2 * s);
  for (final (o, rr) in lobes) {
    c.drawCircle(o + Offset(-rr * .2, -rr * .35), rr * .45, rim);
  }
}

/// A raindrop: where it starts across, how fast it falls, its phase and
/// length, in units of a 360-wide scene.
typedef _Drop = (double, double, double, double);

List<_Drop> _drops(
  int seed,
  int n,
  double speed,
  double spread,
  double len,
) => [
  for (var i = 0; i < n; i++)
    () {
      final r = _rng(seed + i);
      return (r() * 380, speed + r() * spread, r() * 300, len + r() * len * .6);
    }(),
];

final _farDrops = _drops(300, 60, 150, 60, 7);
final _nearDrops = _drops(500, 44, 260, 90, 14);

final _rainTail = Paint()
  ..strokeCap = StrokeCap.round
  ..style = PaintingStyle.stroke;
final _rainHead = Paint()
  ..strokeCap = StrokeCap.round
  ..style = PaintingStyle.stroke;

/// A four-pointed glint, 3 points from its centre to each tip.
final _glint = Path()
  ..addPolygon(const [
    Offset(0, -3),
    Offset(.7, -.7),
    Offset(3, 0),
    Offset(.7, .7),
    Offset(0, 3),
    Offset(-.7, .7),
    Offset(-3, 0),
    Offset(-.7, -.7),
  ], true);

/// The weather over a garden scene of [size] whose land's back corner is at
/// [top]: [under] paints the sky behind the land, [over] what drifts or
/// falls in front of it. [puddle] is the centre of the cell holding a
/// puddle after rain, [cell] a cell's width.
class _Weather {
  final GardenWeather kind;
  final Size size;
  final double top, cell;
  final Offset? puddle;
  _Weather(this.kind, this.size, this.top, this.cell, this.puddle);

  double get w => size.width;
  double get h => size.height;

  /// Scale from the 360-wide design.
  double get k => size.width / 360;

  /// Where the land's left and right corners are: the horizon.
  double get horizon => top + size.width / 4;

  String get _key => '${kind.name}/${w.round()}x${h.round()}/${top.round()}';

  Rect get _all => Offset.zero & size;

  // ---- behind the land ----

  /// The still sky wash, on a layer that is drawn once.
  void sky(Canvas c, Size _, double t, bool still) =>
      _put(_soft('sky/$_key', _all, 1.5, _sky), c);

  void under(Canvas c, Size _, double t, bool still) {
    c.clipRect(_all);
    for (final spot in _clouds) {
      _cloud(c, t, spot);
    }
    if (kind == GardenWeather.rain) {
      _rain(c, t, _farDrops, horizon * .32, horizon * 1.2, .08, .9, const [
        Color(0x30C9D7F0),
        Color(0x80C9D7F0),
      ]);
    }
  }

  /// The sky wash with what stays still in it: the sun's glow, a rainbow,
  /// veils of rain; faded out at the top, the bottom and both sides.
  void _sky(Canvas c) {
    c.saveLayer(_all, Paint());
    final colors = switch (kind) {
      GardenWeather.sunny => const [
        Color(0xFFFFE6AE),
        Color(0xFFFFF3D6),
        Color(0xFFF8FBFC),
      ],
      GardenWeather.cloudy => const [
        Color(0xFFD6D9EC),
        Color(0xFFE8EAF4),
        Color(0xFFF6F8FB),
      ],
      GardenWeather.rain => const [
        Color(0xFFA9B1CD),
        Color(0xFFC7CDE0),
        Color(0xFFE4E8F1),
      ],
      GardenWeather.clearing => const [
        Color(0xFFD7E2F3),
        Color(0xFFEAF0F8),
        Color(0xFFF8FBFC),
      ],
    };
    c.drawRect(
      _all,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset.zero,
          Offset(0, horizon * 1.3),
          colors,
          const [0, .55, 1],
        ),
    );
    void glow(Offset o, double r, double opacity) => c.drawCircle(
      o,
      r,
      Paint()
        ..shader = ui.Gradient.radial(
          o,
          r,
          [
            Color.fromRGBO(255, 244, 200, .95 * opacity),
            Color.fromRGBO(255, 231, 163, .55 * opacity),
            const Color(0x00FFE7A3),
          ],
          const [0, .35, 1],
        ),
    );
    switch (kind) {
      case GardenWeather.sunny:
        glow(Offset(w * .88, 40 * k), 150 * k, 1);
      case GardenWeather.clearing:
        final o = Offset(w / 2, horizon + 6 * k);
        final band = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 5.5 * k
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, 3 * k);
        for (final (i, color) in const [
          Color(0xFFF6A5A5),
          Color(0xFFF8CB8A),
          Color(0xFFF6E98E),
          Color(0xFFA9DDA2),
          Color(0xFF9CC6EE),
          Color(0xFFB7A6E8),
        ].indexed) {
          band.color = color.withValues(alpha: .5);
          c.drawArc(
            Rect.fromCircle(center: o, radius: w * .4 - i * 5 * k),
            math.pi,
            math.pi,
            false,
            band,
          );
        }
        glow(Offset(w * .83, 10 * k), 110 * k, .7);
      case GardenWeather.rain:
        final veil = Paint()
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, 12 * k);
        for (final (x0, x1) in const [(.11, .44), (.53, .92)]) {
          final r = Rect.fromLTRB(w * x0, horizon * .4, w * x1, horizon * 1.05);
          veil.shader = ui.Gradient.linear(r.topCenter, r.bottomCenter, const [
            Color(0x738C95B8),
            Color(0x008C95B8),
          ]);
          c.drawRect(r, veil);
        }
      case GardenWeather.cloudy:
        break;
    }
    final fade = Paint()..blendMode = BlendMode.dstIn;
    c
      ..drawRect(
        _all,
        fade
          ..shader = ui.Gradient.linear(
            Offset.zero,
            Offset(0, h),
            const [
              Color(0x00000000),
              Color(0xFF000000),
              Color(0xFF000000),
              Color(0x00000000),
            ],
            const [0, .16, .7, 1],
          ),
      )
      ..drawRect(
        _all,
        fade
          ..shader = ui.Gradient.linear(
            Offset.zero,
            Offset(w, 0),
            const [
              Color(0x00000000),
              Color(0xFF000000),
              Color(0xFF000000),
              Color(0x00000000),
            ],
            const [0, .08, .92, 1],
          ),
      )
      ..restore();
  }

  /// Sunbeam [i] slanting down from the upper right.
  List<Offset> _beamShape(int i) {
    final y = h / 330;
    final (a, b, cc, d) = const [
      (300.0, 360.0, 210.0, 150.0),
      (250.0, 280.0, 120.0, 92.0),
      (340.0, 360.0, 290.0, 266.0),
    ][i];
    final top = i == 2 ? 0.0 : -20 * y;
    return [
      Offset(a * k, top),
      Offset(b * k, top),
      Offset(cc * k, 300 * y),
      Offset(d * k, 300 * y),
    ];
  }

  /// Only the part of the scene beam [i] covers, so a frame blends no more
  /// pixels than it needs to.
  Rect _beamBox(int i) =>
      _poly(_beamShape(i)).getBounds().inflate(30 * k).intersect(_all);

  void _beam(Canvas c, int i) {
    final shape = _beamShape(i);
    final top = shape.first.dy, bottom = shape.last.dy;
    c.drawPath(
      _poly(shape),
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(0, top),
          Offset(0, bottom),
          const [Color(0xD9FFF8DE), Color(0x40FFF8DE), Color(0x00FFF8DE)],
          const [0, .6, 1],
        )
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 12 * k),
    );
  }

  List<_CloudSpot> get _clouds => switch (kind) {
    GardenWeather.sunny => const [
      ((_litCloud, Color(0xFFE3DDE9)), 2, .23, .42, .7, 38, 1, 1),
      ((_litCloud, Color(0xFFE8E2EC)), 9, .53, .2, .45, 54, -1, 1),
    ],
    GardenWeather.cloudy => const [
      ((_greyCloud, Color(0xFFB9BCD3)), 12, .19, .52, .6, 54, -1, .75),
      ((_greyCloud, Color(0xFFB9BCD3)), 13, .83, .56, .55, 54, -1, .75),
      ((_greyCloud, Color(0xFFA9AECA)), 5, .56, .3, .95, 38, 1, 1),
      ((_greyCloud, Color(0xFFB1B5CF)), 8, .26, .22, .7, 26, 1, 1),
    ],
    GardenWeather.rain => const [
      ((_rainCloud, Color(0xFF7A82A3)), 21, .19, .42, .75, 54, -1, .8),
      ((_rainCloud, Color(0xFF7A82A3)), 22, .83, .45, .7, 54, -1, .8),
      ((_rainCloud, Color(0xFF6E7699)), 23, .53, .26, 1.05, 38, 1, 1),
    ],
    GardenWeather.clearing => const [
      ((_litCloud, Color(0xFFCFD3E3)), 31, .27, .36, .7, 38, 1, 1),
    ],
  };

  void _cloud(Canvas c, double t, _CloudSpot spot) {
    final (look, seed, x, y, s, period, way, opacity) = spot;
    final size = s * k;
    final soft = _soft(
      'cloud/${look.$2.toARGB32()}/$seed/${(size * 100).round()}',
      Rect.fromLTRB(-82 * size, -66 * size, 82 * size, 34 * size),
      2,
      (c) => _paintCloud(c, size, look, seed),
    );
    final drift = way * (1 + 15 * math.sin(t * math.pi / period)) * k;
    // Low enough that its top never leaves the scene.
    final cy = math.max(horizon * y, 54 * size + 4);
    _put(soft, c, Offset(w * x + drift, cy), opacity);
  }

  /// Falling rain from [drops] between [from] and [to], slanting by [lean]:
  /// each drop a faint tail and a brighter head, all drawn in two calls.
  void _rain(
    Canvas c,
    double t,
    List<_Drop> drops,
    double from,
    double to,
    double lean,
    double width,
    List<Color> tones,
  ) {
    final span = to - from;
    final tails = Float32List(drops.length * 4);
    final heads = Float32List(drops.length * 4);
    for (final (i, (x0, speed, phase, len)) in drops.indexed) {
      final y = from + ((t * speed + phase) * k) % span;
      final x = x0 * k - (y - from) * lean;
      final l = len * k, mid = y + l * .55;
      tails
        ..[i * 4] = x
        ..[i * 4 + 1] = y
        ..[i * 4 + 2] = x - l * .55 * lean
        ..[i * 4 + 3] = mid;
      heads
        ..[i * 4] = x - l * .55 * lean
        ..[i * 4 + 1] = mid
        ..[i * 4 + 2] = x - l * lean
        ..[i * 4 + 3] = y + l;
    }
    _rainTail
      ..color = tones[0]
      ..strokeWidth = width * k;
    _rainHead
      ..color = tones[1]
      ..strokeWidth = width * k;
    c
      ..drawRawPoints(ui.PointMode.lines, tails, _rainTail)
      ..drawRawPoints(ui.PointMode.lines, heads, _rainHead);
  }

  // ---- in front of the land ----

  void over(Canvas c, Size _, double t, bool still) {
    c.clipRect(_all);
    switch (kind) {
      case GardenWeather.sunny:
        _beams(c, t);
        _motes(c, t);
        _butterfly(c, t);
      case GardenWeather.cloudy:
        _cloudShadow(c, t);
      case GardenWeather.rain:
        _ripples(c, t);
        _splashes(c, t);
        _rain(c, t, _nearDrops, horizon * .28, h, .12, 1.5, const [
          Color(0x40DCE8FA),
          Color(0xE6E3EEFF),
        ]);
        _mist(c, t);
      case GardenWeather.clearing:
        _glints(c, t);
    }
  }

  /// Sunbeams slanting over the garden, each slowly brightening and fading.
  void _beams(Canvas c, double t) {
    for (final (i, strength, phase) in const [
      (0, .8, 0.0),
      (1, .55, 3.0),
      (2, .5, 5.0),
    ]) {
      _put(
        _soft('beam$i/$_key', _beamBox(i), 1, (c) => _beam(c, i)),
        c,
        Offset.zero,
        strength * (.35 + .65 * _ease(t + phase, 7)),
      );
    }
  }

  /// Motes of light rising through the sun.
  void _motes(Canvas c, double t) {
    final low = h * .82, high = h * .12;
    final sprites = <(Offset, double, double)>[];
    for (var i = 0; i < 26; i++) {
      final r = _rng(100 + i);
      final x0 = (60 + r() * 260) * k, speed = (7 + r() * 9) * k;
      final phase = r() * 200 * k, size = (.8 + r() * 1.6) * k;
      final sway = r() * 6 * k;
      final y = low - (t * speed + phase) % (low - high);
      final x = x0 + math.sin(t * .6 + i) * sway;
      final a =
          (math.min(1.0, (low - y) / (40 * k)) *
                  math.min(1.0, (y - high) / (60 * k)) *
                  .9)
              .clamp(0.0, 1.0);
      if (a > 0) sprites.add((Offset(x, y), size, a));
    }
    _sprites(c, _moteSprite, sprites);
  }

  /// A small butterfly fluttering across the garden.
  void _butterfly(Canvas c, double t) {
    final left = w * .17, run = w * .83;
    final x = left + (t * 18 * k) % run;
    final y = h * .45 + (math.sin(t * 1.3) * 18 + math.sin(t * 3.1) * 4) * k;
    final a = math.min(1.0, math.min(x - left, w - x) / (20 * k));
    if (a <= 0) return;
    final flap = 1 - .75 * _ease(t, .22);
    final wing = Paint();
    c
      ..save()
      ..translate(x, y)
      ..rotate(math.sin(t * 1.3) * 12 * math.pi / 180)
      ..scale(1.15 * k);
    for (final (side, color) in const [
      (-1.0, Color(0xFFFFB86B)),
      (1.0, Color(0xFFFFCB8E)),
    ]) {
      wing.color = color.withValues(alpha: a);
      c
        ..save()
        ..scale(side * flap, 1)
        ..drawPath(
          Path()
            ..moveTo(0, 0)
            ..cubicTo(7, -9, 12, -2, 1, 1)
            ..close(),
          wing,
        )
        ..restore();
    }
    c
      ..drawCircle(
        Offset.zero,
        1,
        Paint()..color = const Color(0xFF6B4A2C).withValues(alpha: a),
      )
      ..restore();
  }

  /// The land: its grass and the soil below, for what falls only on it.
  Path get _land {
    final cx = w / 2, cy = horizon, hw = w / 2, hh = w / 4;
    final d = Offset(0, w * .035 + 9);
    final l = Offset(cx - hw, cy), r = Offset(cx + hw, cy);
    final b = Offset(cx, cy + hh);
    return _poly([l, Offset(cx, cy - hh), r, r + d, b + d, l + d]);
  }

  /// A cloud's shadow gliding over the land.
  void _cloudShadow(Canvas c, double t) {
    final rx = w * .26, ry = w * .1;
    final soft = _soft(
      'shade/${w.round()}',
      Rect.fromCenter(center: Offset.zero, width: rx * 3, height: ry * 3.4),
      1,
      (c) => c.drawOval(
        Rect.fromCenter(center: Offset.zero, width: rx * 2, height: ry * 2),
        Paint()
          ..color = const Color(0x382E3458)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, 12 * k),
      ),
    );
    final x = -rx * 1.4 + ((t / 16) % 1) * (w + rx * 2.8);
    c
      ..save()
      ..clipPath(_land);
    _put(soft, c, Offset(x, horizon + w * .02));
    c.restore();
  }

  /// Rings spreading where drops land in the puddle.
  void _ripples(Canvas c, double t) {
    final p = puddle;
    if (p == null) return;
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = .8;
    for (var i = 0; i < 6; i++) {
      final r = _rng(700 + i);
      final o = p + Offset((r() - .5) * cell * .5, (r() - .5) * cell * .16);
      final q = (t * .7 + r()) % 1;
      ring.color = Color.fromRGBO(255, 255, 255, .7 * (1 - q));
      c.drawOval(
        Rect.fromCenter(
          center: o,
          width: (2 + q * 18) * k * cell / 70,
          height: (.8 + q * 5.2) * k * cell / 70,
        ),
        ring,
      );
    }
  }

  /// Drops bursting into three beads where they hit the grass.
  void _splashes(Canvas c, double t) {
    final bead = Paint();
    final cx = w / 2, cy = horizon;
    for (var i = 0; i < 12; i++) {
      final r = _rng(900 + i);
      final at = _iso(cx, cy, w, w / 2, .12 + r() * .76, .12 + r() * .76);
      final period = .7 + r() * .6;
      final q = (t / period + r()) % 1;
      if (q >= .5) continue;
      bead.color = Color.fromRGBO(234, 242, 255, 1 - q * 2);
      for (var j = 0; j < 3; j++) {
        final a = -math.pi / 2 + (j - 1) * .9;
        c.drawCircle(
          at +
              Offset(
                math.cos(a) * q * 6 * k,
                (math.sin(a) * q * 7 + q * q * 8) * k,
              ),
          .9 * k,
          bead,
        );
      }
    }
  }

  /// Mist drifting low over the wet ground.
  void _mist(Canvas c, double t) {
    final band = Rect.fromLTRB(-20 * k, h * .66, w + 20 * k, h);
    final soft = _soft('mist/${w.round()}x${h.round()}', band, 1, (c) {
      final paint = Paint()
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 12 * k);
      for (final (x, y, rx, ry) in const [
        (80.0, .79, 120.0, 14.0),
        (290.0, .8, 110.0, 12.0),
      ]) {
        final o = Offset(x * k, h * y);
        paint.shader = ui.Gradient.radial(o, rx * k, const [
          Color(0x80FFFFFF),
          Color(0x00FFFFFF),
        ]);
        c
          ..save()
          ..translate(o.dx, o.dy)
          ..scale(1, ry / rx)
          ..translate(-o.dx, -o.dy)
          ..drawCircle(o, rx * k, paint)
          ..restore();
      }
    });
    _put(soft, c, Offset((1 + 15 * math.sin(t * math.pi / 20)) * k, 0));
  }

  /// Raindrops left on leaves and grass, glinting in the returning sun.
  void _glints(Canvas c, double t) {
    final sprites = <(Offset, double, double)>[];
    for (var i = 0; i < 22; i++) {
      final r = _rng(1100 + i);
      final x = (70 + r() * 230) * k, y = h * (.36 + r() * .4);
      final q = (math.sin(t * 1.4 + r() * 6) + 1) / 2;
      final a = q * q * q;
      if (a >= .02) sprites.add((Offset(x, y), (.3 + q * .9) * k, a));
    }
    _sprites(c, _glintSprite, sprites);
  }
}

/// Pixels a point in the sprites below.
const _spriteScale = 4.0;

/// A mote of light: a soft glow around a bright core of radius 1.
(ui.Image, Rect) get _moteSprite => _soft(
  'sprite/mote',
  const Rect.fromLTRB(-3.5, -3.5, 3.5, 3.5),
  _spriteScale,
  (c) => c
    ..drawCircle(
      Offset.zero,
      3.4,
      Paint()
        ..shader = ui.Gradient.radial(Offset.zero, 3.4, const [
          Color(0x80FFF0BE),
          Color(0x00FFF0BE),
        ]),
    )
    ..drawCircle(Offset.zero, 1, Paint()..color = const Color(0xFFFFF8DA)),
);

/// A white four-pointed glint.
(ui.Image, Rect) get _glintSprite => _soft(
  'sprite/glint',
  const Rect.fromLTRB(-3.2, -3.2, 3.2, 3.2),
  _spriteScale,
  (c) => c.drawPath(_glint, Paint()..color = Colors.white),
);

final _spritePaint = Paint()..filterQuality = FilterQuality.low;

/// Draws [sprite] at each place, scale and opacity in one call.
void _sprites(
  Canvas c,
  (ui.Image, Rect) sprite,
  List<(Offset, double, double)> at,
) {
  if (at.isEmpty) return;
  final (image, _) = sprite;
  final side = image.width.toDouble(), half = side / 2;
  final source = Rect.fromLTWH(0, 0, side, side);
  c.drawAtlas(
    image,
    [
      for (final (o, scale, _) in at)
        RSTransform.fromComponents(
          rotation: 0,
          scale: scale / _spriteScale,
          anchorX: half,
          anchorY: half,
          translateX: o.dx,
          translateY: o.dy,
        ),
    ],
    [for (final _ in at) source],
    [for (final (_, _, a) in at) Color.fromRGBO(255, 255, 255, a)],
    BlendMode.modulate,
    null,
    _spritePaint,
  );
}

/// The free cell nearest the front where a puddle lies after rain, or null
/// when plants and decorations fill the land.
(int, int)? _puddleCell(int n, int plants, int decor) {
  final taken = _decorCells(n).take(decor).toSet();
  final free = [
    for (final cell in _cellOrder(n))
      if (!taken.contains(cell)) cell,
  ].skip(plants);
  (int, int)? best;
  for (final (i, j) in free) {
    // Not on the very front tip, where it would hang over the edge.
    if (i + j > 2 * n - 3) continue;
    if (best == null || i + j > best.$1 + best.$2) best = (i, j);
  }
  return best;
}

/// How the weather lies on the grass, under the plants: sunlight pooling,
/// a cloud's cool tint, or the darker sheen of wet grass and a puddle.
void _ground(
  Canvas c,
  GardenWeather weather,
  double cx,
  double cy,
  double w,
  double h,
  int n,
  (int, int)? puddle,
) {
  final grass = _poly([
    Offset(cx, cy - h / 2),
    Offset(cx + w / 2, cy),
    Offset(cx, cy + h / 2),
    Offset(cx - w / 2, cy),
  ]);
  final wet =
      weather == GardenWeather.rain || weather == GardenWeather.clearing;
  c
    ..save()
    ..clipPath(grass);
  if (weather == GardenWeather.cloudy) {
    c.drawPath(grass, Paint()..color = const Color(0x1F4A5480));
  }
  if (wet) {
    c
      ..drawPath(
        grass,
        Paint()
          ..color = weather == GardenWeather.rain
              ? const Color(0x33204A30)
              : const Color(0x22204A30),
      )
      ..drawPath(
        Path()
          ..moveTo(cx - w * .42, cy)
          ..lineTo(cx, cy - h * .42)
          ..lineTo(cx + w * .42, cy),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = w * .03
          ..color = const Color(0x2EFFFFFF)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, w * .014),
      );
  }
  if (weather == GardenWeather.sunny || weather == GardenWeather.clearing) {
    final o = Offset(cx + w * .06, cy - h * .02), r = w * .3;
    final a = weather == GardenWeather.sunny ? 1.0 : .7;
    c
      ..save()
      ..translate(o.dx, o.dy)
      ..scale(1, h / w)
      ..drawCircle(
        Offset.zero,
        r,
        Paint()
          ..shader = ui.Gradient.radial(
            Offset.zero,
            r,
            [
              Color.fromRGBO(251, 255, 224, .75 * a),
              Color.fromRGBO(233, 247, 184, .4 * a),
              const Color(0x00E9F7B8),
            ],
            const [0, .55, 1],
          ),
      )
      ..restore();
  }
  c.restore();
  if (!wet || puddle == null) return;
  final (i, j) = puddle;
  final o = _iso(cx, cy, w, h, (i + .5) / n, (j + .5) / n);
  final rx = w / n * (weather == GardenWeather.rain ? .42 : .36);
  c
    ..save()
    ..translate(o.dx, o.dy)
    ..scale(1, .42)
    ..drawCircle(
      Offset.zero,
      rx,
      Paint()
        ..shader = ui.Gradient.radial(
          Offset.zero,
          rx,
          const [Color(0xC0E4EEFF), Color(0x80B8CBEA), Color(0x009EB3D8)],
          const [0, .6, 1],
        ),
    )
    ..drawOval(
      Rect.fromCenter(
        center: Offset(-rx * .1, -rx * .18),
        width: rx * 1.1,
        height: rx * .34,
      ),
      Paint()
        ..color = const Color(0x59FFFFFF)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, rx * .08),
    )
    ..restore();
}
