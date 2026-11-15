part of 'garden_art.dart';

// Decorations earned by finishing a week's quests, and the garden's weather.
// Decorations are drawn in the same 200 box as plants, foot at (100, 182),
// but kept small so they sit beside the trees rather than compete.

const _stone = (Color(0xFFD6D2CA), Color(0xFF8E887E));
const _plank = (Color(0xFFC9935F), Color(0xFF7E5636));

void _decoration(_Pen p, String id) {
  switch (id) {
    case 'stoneLantern':
      p
        ..ground(100, 182, 30)
        ..fill(
          Path()..addRect(const Rect.fromLTWH(88, 168, 24, 14)),
          _stone,
          across: true,
        )
        ..fill(
          Path()..addRect(const Rect.fromLTWH(95, 136, 10, 34)),
          _stone,
          across: true,
        )
        ..fill(
          Path()..addRect(const Rect.fromLTWH(86, 114, 28, 24)),
          _stone,
          across: true,
        )
        ..fill(Path()..addRect(const Rect.fromLTWH(92, 119, 16, 14)), (
          const Color(0xFFFFF0B8),
          const Color(0xFFFFB54A),
        ), down: true)
        ..fill(
          Path()
            ..moveTo(78, 116)
            ..quadraticBezierTo(100, 100, 122, 116)
            ..lineTo(100, 96)
            ..close(),
          _stone,
          across: true,
        )
        ..dot(100, 94, 3, const Color(0xFF8E887E));
    case 'bench':
      p
        ..ground(100, 182, 40)
        ..fill(
          Path()..addRect(const Rect.fromLTWH(66, 160, 68, 7)),
          _plank,
          across: true,
        )
        ..fill(
          Path()..addRect(const Rect.fromLTWH(66, 140, 68, 6)),
          _plank,
          across: true,
        )
        ..fill(
          Path()..addRect(const Rect.fromLTWH(66, 149, 68, 5)),
          _plank,
          across: true,
        );
      for (final x in const [70.0, 126.0]) {
        p.fill(Path()..addRect(Rect.fromLTWH(x, 140, 5, 42)), (
          const Color(0xFF6E6A66),
          const Color(0xFF3E3A36),
        ), across: true);
      }
    case 'pond':
      p.c.drawOval(
        Rect.fromCenter(center: const Offset(100, 174), width: 92, height: 26),
        Paint()
          ..shader = ui.Gradient.radial(
            const Offset(94, 170),
            48,
            const [Color(0xFFB8E8F6), Color(0xFF5EB8DA), Color(0xFF3A92BA)],
            const [0, .6, 1],
          ),
      );
      for (var i = 0; i < 9; i++) {
        final a = i / 9 * _tau;
        p.ball(
          100 + math.cos(a) * 47,
          175 + math.sin(a) * 14,
          4 + (i % 3),
          const Color(0xFFE8E2D8),
          const Color(0xFFB4AA9A),
          const Color(0xFF8A806E),
        );
      }
      p
        ..fill(_leaf(86, 172, -.2, 16, 10), (
          const Color(0xFF8CCB72),
          const Color(0xFF4E9A4A),
        ))
        ..flower(
          112,
          170,
          4.5,
          const Color(0xFFFFC2D6),
          const Color(0xFFFFE07A),
          .5,
        );
    case 'birdhouse':
      p
        ..ground(100, 182, 22)
        ..fill(_taper(100, 183, 100, 128, 5, 4), _plank, across: true)
        ..fill(Path()..addRect(const Rect.fromLTWH(86, 106, 28, 26)), (
          const Color(0xFFF6D7A8),
          const Color(0xFFC9935F),
        ), across: true)
        ..fill(
          Path()
            ..moveTo(80, 108)
            ..lineTo(100, 90)
            ..lineTo(120, 108)
            ..close(),
          (const Color(0xFFE07A5A), const Color(0xFFA84A32)),
          across: true,
        )
        ..dot(100, 118, 4.5, const Color(0xFF4A2E1A))
        ..line(
          const Offset(100, 126),
          const Offset(100, 129),
          const Color(0xFF7E5636),
          1.6,
        );
    case 'redLantern':
      p
        ..ground(100, 182, 22)
        ..fill(_taper(92, 183, 92, 100, 5, 4), _plank, across: true)
        ..fill(_taper(92, 102, 120, 102, 3, 3), _plank, across: true)
        ..line(
          const Offset(116, 102),
          const Offset(116, 112),
          const Color(0xFF5A3A20),
          1,
        )
        ..ball(
          116,
          126,
          13,
          const Color(0xFFFF8A6A),
          const Color(0xFFD8261C),
          const Color(0xFF8A1410),
        )
        ..fill(Path()..addRect(const Rect.fromLTWH(110, 111, 12, 3)), (
          const Color(0xFFFFD86A),
          const Color(0xFFD9A020),
        ))
        ..fill(Path()..addRect(const Rect.fromLTWH(110, 138, 12, 3)), (
          const Color(0xFFFFD86A),
          const Color(0xFFD9A020),
        ))
        ..line(
          const Offset(116, 141),
          const Offset(116, 152),
          const Color(0xFFFFC94A),
          2,
        );
    case 'flowerBed':
      p.c.drawOval(
        Rect.fromCenter(center: const Offset(100, 176), width: 84, height: 20),
        Paint()..color = const Color(0xFF8A5E3C),
      );
      p.clump(
        x: 100,
        y: 170,
        r: 30,
        n: 40,
        len: 7,
        w: 5,
        tones: _oakTones,
        seed: 905,
        squash: .32,
        droop: .1,
        spot: false,
      );
      p.blossoms(
        x: 100,
        y: 166,
        r: 30,
        n: 16,
        size: 4.2,
        tones: const [
          Color(0xFFFF8FB4),
          Color(0xFFFFD84A),
          Color(0xFFB48CFF),
          Color(0xFFFFFFFF),
        ],
        center: const Color(0xFFFFE07A),
        seed: 906,
        squash: .3,
        spot: false,
      );
  }
}

/// The sky over the garden at time [t] (seconds): behind the garden a soft
/// wash with the sun and its turning rays, or drifting clouds; in front of
/// it, falling rain. Everything stays inside [size], which the scene clips
/// to, so nothing reaches the date line above the garden. [top] is where
/// the garden's back corner sits.
void _weather(
  Canvas c,
  GardenWeather w,
  Size size,
  double top,
  double t, {
  required bool behind,
}) {
  final width = size.width;
  if (behind) {
    final wash = switch (w) {
      GardenWeather.sunny => const Color(0x40FFE7A3),
      GardenWeather.cloudy => const Color(0x30C3CAD6),
      GardenWeather.rain => const Color(0x40A9B6C9),
    };
    final sky = Rect.fromLTWH(0, 0, width, top * 1.9);
    c.drawRect(
      sky,
      Paint()
        // Faded at both ends, so the wash has no edge under the date line.
        ..shader = ui.Gradient.linear(
          sky.topCenter,
          sky.bottomCenter,
          [wash.withValues(alpha: 0), wash, wash.withValues(alpha: 0)],
          const [0, .35, 1],
        ),
    );
    if (w == GardenWeather.sunny) {
      final o = Offset(width * .82, top * .55);
      final r = math.min(width * .045, top * .24);
      c.drawCircle(
        o,
        r * 4.2,
        Paint()
          ..shader = ui.Gradient.radial(o, r * 4.2, const [
            Color(0x66FFE9A6),
            Color(0x00FFE9A6),
          ]),
      );
      final ray = Paint()
        ..color = const Color(0xCCFFD45C)
        ..strokeWidth = math.max(2, r * .16)
        ..strokeCap = StrokeCap.round;
      for (var i = 0; i < 12; i++) {
        final a = i * math.pi / 6 + t * .12;
        final long = i.isEven ? 1.0 : .7;
        final d = Offset(math.cos(a), math.sin(a));
        c.drawLine(o + d * r * 1.45, o + d * r * (1.45 + .55 * long), ray);
      }
      c.drawCircle(
        o,
        r,
        Paint()
          ..shader = ui.Gradient.radial(o - Offset(r, r) * .3, r * 1.3, const [
            Color(0xFFFFF0B0),
            Color(0xFFFFC94A),
          ]),
      );
      // Two small fair-weather clouds drifting across.
      for (final (x, y, s, speed) in const [
        (.18, .42, .75, 5.0),
        (.5, .3, .55, 3.0),
      ]) {
        final dx = (width * x + t * speed) % (width * 1.2) - width * .1;
        _cloud(
          c,
          Offset(dx, top * y),
          top * .2 * s,
          const Color(0xF2FFFFFF),
          null,
        );
      }
      return;
    }
    final (body, shade) = w == GardenWeather.rain
        ? (const Color(0xFFB2BACA), const Color(0xFF98A1B3))
        : (const Color(0xFFD3D8E0), const Color(0xFFBCC3CE));
    for (final (x, y, s, phase) in const [
      (.17, .5, .85, 0.0),
      (.5, .38, 1.15, 1.7),
      (.83, .52, .9, 3.1),
    ]) {
      final drift = math.sin(t * .35 + phase) * width * .015;
      _cloud(
        c,
        Offset(width * x + drift, top * y),
        math.min(width * .06, top * .3) * s,
        body,
        shade,
      );
    }
    return;
  }
  if (w != GardenWeather.rain) return;
  final drop = Paint()
    ..strokeWidth = 1.4
    ..strokeCap = StrokeCap.round;
  final rnd = _rng(77);
  final from = top * .75, span = size.height - from;
  for (var i = 0; i < 70; i++) {
    final x = rnd() * width;
    final speed = 120 + rnd() * 80;
    final len = 8 + rnd() * 6;
    final y = from + (rnd() * span + t * speed) % span;
    drop.color = Color.fromRGBO(98, 140, 196, .35 + rnd() * .3);
    c.drawLine(Offset(x, y), Offset(x - len * .3, y + len), drop);
  }
}

/// A puffy cloud of four circles around [o], [r] across its middle circle,
/// with a darker underside when [shade] is given.
void _cloud(Canvas c, Offset o, double r, Color body, Color? shade) {
  const puffs = [
    (-1.1, .25, .72),
    (0.0, 0.0, 1.0),
    (1.05, .22, .8),
    (.45, .38, .7),
  ];
  if (shade != null) {
    for (final (dx, dy, k) in puffs) {
      c.drawCircle(
        o + Offset(dx * r, dy * r + r * .14),
        r * k,
        Paint()..color = shade,
      );
    }
  }
  for (final (dx, dy, k) in puffs) {
    c.drawCircle(o + Offset(dx * r, dy * r), r * k, Paint()..color = body);
  }
  // Light on the top of the cloud, soft so it reads as volume, not a spot.
  final light = o + Offset(-r * .2, -r * .45);
  c.drawCircle(
    light,
    r * .9,
    Paint()
      ..shader = ui.Gradient.radial(light, r * .9, [
        Colors.white.withValues(alpha: .3),
        Colors.white.withValues(alpha: 0),
      ]),
  );
}
