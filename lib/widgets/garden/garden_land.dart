part of 'garden_art.dart';

// The land tile, the tree dispatcher that picks a plant's form, and the
// garden grid.

const _grassTop = Color(0xFFB6F2A2), _grassBottom = Color(0xFF84D880);
const _lipLeft = Color(0xFF5CBE6C), _lipRight = Color(0xFF3FA05A);
const _soilLeft = [Color(0xFFC48E58), Color(0xFF9A683D)];
const _soilRight = [Color(0xFF93633A), Color(0xFF6C4425)];

Offset _iso(double cx, double cy, double w, double h, double u, double v) =>
    _o(cx + (u - v) * w / 2, cy - h / 2 + (u + v) * h / 2);

/// A diamond of grass [w] wide and [h] tall centred on [cx], [cy], over [d]
/// of soil; [n] cells a side. A [floating] tile has rocks and a shadow below.
void _land(
  _Ctx x,
  double cx,
  double cy,
  double w,
  double h,
  double d,
  int n,
  int seed,
  bool floating,
) {
  final l = _o(cx - w / 2, cy),
      r = _o(cx + w / 2, cy),
      t = _o(cx, cy - h / 2),
      b = _o(cx, cy + h / 2);
  final sc = (w / n / 46).clamp(.55, 1.5), rnd = _rng(seed);
  Offset mid(Offset a, double u, double dy) =>
      _o(a.dx + (b.dx - a.dx) * u, a.dy + (b.dy - a.dy) * u + dy);
  if (floating) {
    x
      ..save()
      ..translate(cx, cy + h / 2 + d + h * .42)
      ..scale(1, .26);
    _dot(
      x,
      0,
      0,
      w * .5,
      _rg(0, 0, 0, 0, 0, w * .5, const [
        Color.fromRGBO(18, 14, 80, .42),
        Color.fromRGBO(18, 14, 80, 0),
      ]),
    );
    x.restore();
    for (var k = 0; k < 6; k++) {
      final u = (k + .5) / 6,
          s = (3.5 + ((k * 7) % 5) * 1.5) * sc * (.5 + u * .9);
      final pl = mid(l, u, d), pr = mid(r, u, d);
      _poly(x, [
        _o(pl.dx - s * 1.3, pl.dy - 1),
        _o(pl.dx + s * 1.3, pl.dy - 1),
        _o(pl.dx + s * .3, pl.dy + s * 2),
      ], _soilLeft[1]);
      _poly(x, [
        _o(pr.dx - s * 1.3, pr.dy - 1),
        _o(pr.dx + s * 1.3, pr.dy - 1),
        _o(pr.dx - s * .3, pr.dy + s * 2),
      ], _soilRight[1]);
    }
  }
  _poly(x, [
    l,
    b,
    b + _o(0, d),
    l + _o(0, d),
  ], _lg(0, cy, 0, cy + h / 2 + d, _soilLeft));
  _poly(x, [
    r,
    b,
    b + _o(0, d),
    r + _o(0, d),
  ], _lg(0, cy, 0, cy + h / 2 + d, _soilRight));
  _poly(x, [
    mid(l, 0, d * .6),
    mid(l, 1, d * .6),
    mid(l, 1, d),
    mid(l, 0, d),
  ], const Color.fromRGBO(60, 30, 10, .17));
  _poly(x, [
    mid(r, 0, d * .6),
    mid(r, 1, d * .6),
    mid(r, 1, d),
    mid(r, 0, d),
  ], const Color.fromRGBO(40, 18, 6, .22));
  final stones = (3 + n * 1.5).round();
  for (var k = 0; k < stones * 2; k++) {
    final left = k.isEven,
        p = mid(left ? l : r, .06 + rnd() * .88, d * (.4 + rnd() * .48)),
        s = (1.5 + rnd() * 2.1) * sc;
    _ell(
      x,
      p.dx,
      p.dy,
      s * 1.3,
      s * .8,
      left ? .45 : -.45,
      Color.fromRGBO(255, 228, 190, left ? .42 : .24),
    );
  }
  final lip = math.max(3.0, d * .24), m = math.max(5, (w / 13).round());
  _poly(x, [l, b, b + _o(0, lip), l + _o(0, lip)], _lipLeft);
  _poly(x, [r, b, b + _o(0, lip), r + _o(0, lip)], _lipRight);
  for (var k = 0; k < m; k++) {
    final u = (k + .5) / m, rr = w / m * .3 * (.8 + ((k * 5) % 3) * .2);
    final a = mid(l, u, lip), c = mid(r, u, lip);
    _dot(x, a.dx, a.dy, rr, _lipLeft);
    _dot(x, c.dx, c.dy, rr, _lipRight);
  }
  _poly(x, [
    t,
    r,
    b,
    l,
  ], _lg(0, cy - h / 2, 0, cy + h / 2, const [_grassTop, _grassBottom]));
  if (n > 1) {
    for (var i = 0; i < n; i++) {
      for (var j = 0; j < n; j++) {
        if ((i + j).isOdd) {
          _poly(x, [
            _iso(cx, cy, w, h, i / n, j / n),
            _iso(cx, cy, w, h, (i + 1) / n, j / n),
            _iso(cx, cy, w, h, (i + 1) / n, (j + 1) / n),
            _iso(cx, cy, w, h, i / n, (j + 1) / n),
          ], _white(.14));
        }
      }
    }
  }
  _line(x, [l, b, r], 1, _white(.5));
  final specks = (n * n * 1.5 + 5).round();
  const flowers = [Colors.white, Color(0xFFFFE066), Color(0xFFFFC2D6)];
  for (var k = 0; k < specks; k++) {
    final p = _iso(cx, cy, w, h, .06 + rnd() * .88, .06 + rnd() * .88),
        q = rnd();
    if (q < .55) {
      x.begin();
      for (final dx in const [-1.7, 0.0, 1.7]) {
        x
          ..moveTo(p.dx, p.dy)
          ..lineTo(p.dx + dx * sc, p.dy - (3.2 - dx.abs() * .5) * sc);
      }
      x.stroke(const Color.fromRGBO(47, 148, 88, .6), .9 * sc);
    } else if (q < .86) {
      for (var a = 0; a < 5; a++) {
        _dot(
          x,
          p.dx + math.cos(a * 1.257) * 1.25 * sc,
          p.dy + math.sin(a * 1.257) * .85 * sc,
          .95 * sc,
          flowers[k % 3],
        );
      }
      _dot(x, p.dx, p.dy, .7 * sc, const Color(0xFFF59F00));
    } else {
      _ell(
        x,
        p.dx,
        p.dy,
        2.4 * sc,
        1.4 * sc,
        0,
        const Color.fromRGBO(125, 135, 145, .6),
      );
    }
  }
}

/// Draws [key] at [px], [py] in a box [s] wide. Below .14 [g] is a sprout;
/// woody species show a staked sapling up to .45, then fill out.
void _tree(
  _Ctx x,
  double px,
  double py,
  double s,
  String key,
  double g,
  double t,
  bool still, {
  double bloom = 0,
  bool dead = false,
  double pop = 1,
}) {
  final sp = _arts[key] ?? _arts[defaultSpecies]!;
  final e = _Env(t, still ? 0 : _wind(t, px * .07 + py * .05));
  final sh = (.3 + .7 * math.min(1.0, g)) * sp.shadow;
  x
    ..save()
    ..translate(px, py)
    ..scale(s / 100 * pop);
  if (sh > 0 || dead) {
    final q = dead ? 1.0 : sh;
    x
      ..save()
      ..translate(2, 1.5)
      ..scale(1, .32);
    _dot(
      x,
      0,
      0,
      27 * q,
      _rg(0, 0, 0, 0, 0, 27 * q, const [
        Color.fromRGBO(15, 40, 60, .34),
        Color.fromRGBO(15, 40, 60, .2),
        Color.fromRGBO(15, 40, 60, 0),
      ]),
    );
    x.restore();
  }
  if (dead) {
    _deadTree(x, e);
  } else if (g < .14) {
    _sprout(x, e, g);
  } else {
    x.rotate(e.w * .022 * sp.stiff);
    if (g < .45 && sp.wood) {
      _sapling(x, e, sp, (g - .14) / .31);
    } else {
      final k = sp.wood ? .6 + .4 * (g - .45) / .55 : .42 + .58 * g;
      x.scale(k);
      sp.draw(x, e);
      if (bloom > 0) {
        final spots = sp.spots;
        for (var i = 0; i < spots.length; i++) {
          final b = (bloom * spots.length * .9 - i * .8).clamp(0.0, 1.0),
              pop = b < 1 ? b * (1.7 - .7 * b) : 1.0;
          final bx = spots[i].dx + e.w * (1 - spots[i].dy * .03);
          _blossom(
            x,
            bx,
            spots[i].dy,
            4.8 * pop,
            Colors.white,
            _yolk,
            i + t * .2,
          );
          if (b > .5) {
            _star4(
              x,
              bx + 5.5,
              spots[i].dy - 5.5,
              (1.7 + math.sin(t * 3 + i) * .9) * b,
              _white(.95),
            );
          }
        }
      }
    }
  }
  x.restore();
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
  _Ctx x,
  double cx,
  double cy,
  double w,
  int n,
  List<Plant> plants,
  double t,
  bool still,
) {
  final h = w / 2, d = w * .035 + 9, tw = w / n;
  _land(x, cx, cy, w, h, d, n, n * 17, false);
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
    _tree(
      x,
      q.dx,
      q.dy + tw * .03,
      tw * 1.1,
      p.species,
      p.growth,
      t,
      still,
      dead: p.withered,
      bloom: p.bloomed ? 1 : 0,
    );
  }
}
