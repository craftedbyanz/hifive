import 'package:flutter/widgets.dart';

/// Google's four-colour "G", drawn from the mark in Google's sign-in
/// branding guidelines, for the "Continue with Google" button.
class GoogleLogo extends StatelessWidget {
  final double size;
  const GoogleLogo({super.key, this.size = 20});

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Google',
    image: true,
    child: CustomPaint(
      size: Size.square(size),
      painter: const _GooglePainter(),
    ),
  );
}

class _GooglePainter extends CustomPainter {
  const _GooglePainter();

  // The mark on a 48-unit square, as Google publishes it.
  static const _parts = [
    (
      Color(0xFFEA4335),
      'M24 9.5c3.54 0 6.71 1.22 9.21 3.6l6.85-6.85C35.9 2.38 30.47 0 24 0 '
          '14.62 0 6.51 5.38 2.56 13.22l7.98 6.19C12.43 13.72 17.74 9.5 24 9.5z',
    ),
    (
      Color(0xFF4285F4),
      'M46.98 24.55c0-1.57-.15-3.09-.38-4.55H24v9.02h12.94c-.58 2.96-2.26 '
          '5.48-4.78 7.18l7.73 6c4.51-4.18 7.09-10.36 7.09-17.65z',
    ),
    (
      Color(0xFFFBBC05),
      'M10.53 28.59c-.48-1.45-.76-2.99-.76-4.59s.27-3.14.76-4.59l-7.98-6.19'
          'C.92 16.46 0 20.12 0 24c0 3.88.92 7.54 2.56 10.78l7.97-6.19z',
    ),
    (
      Color(0xFF34A853),
      'M24 48c6.48 0 11.93-2.13 15.89-5.81l-7.73-6c-2.15 1.45-4.92 2.3-8.16 '
          '2.3-6.26 0-11.57-4.22-13.47-9.91l-7.98 6.19C6.51 42.62 14.62 48 24 48z',
    ),
  ];

  static final _paths = [for (final (_, d) in _parts) svgPath(d)];

  @override
  void paint(Canvas canvas, Size size) {
    canvas
      ..save()
      ..scale(size.width / 48, size.height / 48);
    for (final (i, (colour, _)) in _parts.indexed) {
      canvas.drawPath(_paths[i], Paint()..color = colour);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_GooglePainter old) => false;
}

/// A [Path] from SVG path data, for the commands the logo uses: M, L, H, V,
/// C, S and Z, absolute or relative.
Path svgPath(String d) {
  final tokens = RegExp(r'[MmLlHhVvCcSsZz]|-?(?:\d+\.?\d*|\.\d+)(?:e-?\d+)?')
      .allMatches(d)
      .map((m) => m.group(0)!)
      .toList();
  final path = Path();
  var i = 0, x = 0.0, y = 0.0, startX = 0.0, startY = 0.0;
  double? lastCx, lastCy;
  var command = 'M';
  double next() => double.parse(tokens[i++]);
  bool number() =>
      i < tokens.length && !RegExp(r'^[A-Za-z]$').hasMatch(tokens[i]);
  while (i < tokens.length) {
    if (!number()) command = tokens[i++];
    final rel = command == command.toLowerCase();
    final ox = rel ? x : 0.0, oy = rel ? y : 0.0;
    switch (command.toUpperCase()) {
      case 'M':
        x = ox + next();
        y = oy + next();
        path.moveTo(x, y);
        startX = x;
        startY = y;
        // Pairs after a move are lines.
        command = rel ? 'l' : 'L';
        lastCx = null;
      case 'L':
        x = ox + next();
        y = oy + next();
        path.lineTo(x, y);
        lastCx = null;
      case 'H':
        x = ox + next();
        path.lineTo(x, y);
        lastCx = null;
      case 'V':
        y = oy + next();
        path.lineTo(x, y);
        lastCx = null;
      case 'C':
        final c1x = ox + next(), c1y = oy + next();
        final c2x = ox + next(), c2y = oy + next();
        x = ox + next();
        y = oy + next();
        path.cubicTo(c1x, c1y, c2x, c2y, x, y);
        lastCx = c2x;
        lastCy = c2y;
      case 'S':
        final c1x = lastCx == null ? x : 2 * x - lastCx;
        final c1y = lastCy == null || lastCx == null ? y : 2 * y - lastCy;
        final c2x = ox + next(), c2y = oy + next();
        x = ox + next();
        y = oy + next();
        path.cubicTo(c1x, c1y, c2x, c2y, x, y);
        lastCx = c2x;
        lastCy = c2y;
      case 'Z':
        path.close();
        x = startX;
        y = startY;
        lastCx = null;
    }
  }
  return path;
}
