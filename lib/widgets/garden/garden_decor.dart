part of 'garden_art.dart';

// Decorations earned by finishing a week's quests.
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
