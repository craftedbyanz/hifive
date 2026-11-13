part of 'garden_art.dart';

// Drawing kit for the garden art. It mirrors the 2D canvas calls the approved
// mockup (`docs/mockups/garden.html`) was drawn with, so each species ports
// line by line. Trees are drawn in a 100-unit box with the base at 0,0 and up
// as negative y.

const _tau = math.pi * 2;

/// A seeded generator, the same sequence as the mockup's, so speckles and
/// petals land in the same places on every frame.
double Function() _rng(int seed) {
  var s = seed & 0xFFFFFFFF;
  if (s == 0) s = 1;
  return () {
    s = (s * 1664525 + 1013904223) & 0xFFFFFFFF;
    return s / 4294967296;
  };
}

/// Gusts: a slow swell times two quicker sways, between about -1 and 1.
double _wind(double t, double ph) {
  final g = .55 + .45 * math.sin(t * .31 + ph * .7);
  return (math.sin(t * 1.15 + ph) * .65 + math.sin(t * 2.6 + ph * 1.9) * .35) *
      g;
}

Color _a(Color c, double a) => c.withValues(alpha: c.a * a);
Color _white(double a) => Color.fromRGBO(255, 255, 255, a);

/// The time and wind a tree is drawn with.
class _Env {
  final double t, w;
  const _Env(this.t, this.w);
}

/// A thin layer over [Canvas] with a current path, like a 2D context.
class _Ctx {
  final Canvas c;
  _Ctx(this.c);

  Path _p = Path();
  double alpha = 1;
  final _alphas = <double>[];

  void save() {
    c.save();
    _alphas.add(alpha);
  }

  void restore() {
    c.restore();
    alpha = _alphas.removeLast();
  }

  void translate(double x, double y) => c.translate(x, y);
  void rotate(double r) => c.rotate(r);
  void scale(double x, [double? y]) => c.scale(x, y ?? x);

  void begin() => _p = Path();
  void moveTo(double x, double y) => _p.moveTo(x, y);
  void lineTo(double x, double y) => _p.lineTo(x, y);
  void quad(double cx, double cy, double x, double y) =>
      _p.quadraticBezierTo(cx, cy, x, y);
  void cubic(double ax, double ay, double bx, double by, double x, double y) =>
      _p.cubicTo(ax, ay, bx, by, x, y);
  void close() => _p.close();
  void arc(double x, double y, double r, double a0, double a1) => _p.arcTo(
    Rect.fromCircle(center: Offset(x, y), radius: r),
    a0,
    a1 - a0,
    false,
  );
  void rrect(double x, double y, double w, double h, double r) =>
      _p.addRRect(RRect.fromLTRBR(x, y, x + w, y + h, Radius.circular(r)));

  Paint _paint(Object f) {
    final p = Paint()..isAntiAlias = true;
    if (f is Color) {
      p.color = _a(f, alpha);
    } else {
      p
        ..shader = f as Shader
        ..color = Color.fromRGBO(0, 0, 0, alpha);
    }
    return p;
  }

  void fill(Object f) => c.drawPath(_p, _paint(f));
  void stroke(Color col, double w) => c.drawPath(
    _p,
    _paint(col)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round,
  );
  void clip() => c.clipPath(_p);
  void rect(double x, double y, double w, double h, Object f) =>
      c.drawRect(Rect.fromLTWH(x, y, w, h), _paint(f));
}

Shader _lg(double x0, double y0, double x1, double y1, List<Color> cs) =>
    ui.Gradient.linear(Offset(x0, y0), Offset(x1, y1), cs, _stops(cs.length));

Shader _rg(
  double fx,
  double fy,
  double fr,
  double cx,
  double cy,
  double r,
  List<Color> cs,
) => ui.Gradient.radial(
  Offset(cx, cy),
  r,
  cs,
  _stops(cs.length),
  TileMode.clamp,
  null,
  Offset(fx, fy),
  fr,
);

List<double> _stops(int n) => [
  for (var i = 0; i < n; i++) n > 1 ? i / (n - 1) : 0,
];

void _poly(_Ctx x, List<Offset> p, Object f) {
  x.begin();
  x.moveTo(p[0].dx, p[0].dy);
  for (var i = 1; i < p.length; i++) {
    x.lineTo(p[i].dx, p[i].dy);
  }
  x.close();
  x.fill(f);
}

void _dot(_Ctx x, double a, double b, double r, Object f) {
  if (!(r > 0)) return;
  x.c.drawCircle(Offset(a, b), r, x._paint(f));
}

void _ell(
  _Ctx x,
  double a,
  double b,
  double rx,
  double ry,
  double rot,
  Object f,
) {
  if (!(rx > 0 && ry > 0)) return;
  x.c
    ..save()
    ..translate(a, b)
    ..rotate(rot)
    ..drawOval(
      Rect.fromCenter(center: Offset.zero, width: rx * 2, height: ry * 2),
      x._paint(f),
    )
    ..restore();
}

void _line(_Ctx x, List<Offset> p, double w, Color c) {
  x.begin();
  x.moveTo(p[0].dx, p[0].dy);
  for (var i = 1; i < p.length; i++) {
    x.lineTo(p[i].dx, p[i].dy);
  }
  x.stroke(c, w);
}

void _curve(_Ctx x, Offset a, Offset c, Offset b, double w, Color col) {
  x
    ..begin()
    ..moveTo(a.dx, a.dy)
    ..quad(c.dx, c.dy, b.dx, b.dy)
    ..stroke(col, w);
}

Offset _qpt(Offset a, Offset c, Offset b, double u) {
  final v = 1 - u;
  return a * (v * v) + c * (2 * v * u) + b * (u * u);
}

const _o = Offset.new;

/// Five tones of one hue, from shadow [u] to highlight [h].
class _Tone {
  final Color u, d, m, l, h;
  const _Tone(this.u, this.d, this.m, this.l, this.h);
  Color get hf => _a(h, .55);
  Color get uf => _a(u, .3);
}

const _green = _Tone(
  Color(0xFF1C6B45),
  Color(0xFF2F9458),
  Color(0xFF4DBB6A),
  Color(0xFFA2EC93),
  Color(0xFFD4FAB8),
);
const _deep = _Tone(
  Color(0xFF125A39),
  Color(0xFF1F8450),
  Color(0xFF2FA866),
  Color(0xFF78DA90),
  Color(0xFFB4F2BC),
);
const _lime = _Tone(
  Color(0xFF4A8A2C),
  Color(0xFF6BAE3F),
  Color(0xFF8FCB52),
  Color(0xFFCBF08A),
  Color(0xFFEAFBBC),
);
const _pink = _Tone(
  Color(0xFFCF6494),
  Color(0xFFEE8FB5),
  Color(0xFFFFB3CF),
  Color(0xFFFFE3ED),
  Color(0xFFFFFFFF),
);
const _fire = _Tone(
  Color(0xFFB4381A),
  Color(0xFFDF5A22),
  Color(0xFFF78A2F),
  Color(0xFFFFC866),
  Color(0xFFFFE7A6),
);
const _gold = _Tone(
  Color(0xFFB48512),
  Color(0xFFDBAA22),
  Color(0xFFF4CC3F),
  Color(0xFFFFEC94),
  Color(0xFFFFF8CF),
);
const _red = _Tone(
  Color(0xFFA81F2B),
  Color(0xFFD4303A),
  Color(0xFFF2514B),
  Color(0xFFFF9A7A),
  Color(0xFFFFD0B8),
);
const _cosmos = _Tone(
  Color(0xFF1E1663),
  Color(0xFF3B2FA3),
  Color(0xFF6C5CE7),
  Color(0xFFA9A0FF),
  Color(0xFFDCD8FF),
);

/// Bark: light, middle and dark.
class _Bark {
  final Color l, m, d;
  const _Bark(this.l, this.m, this.d);
}

const _bark = _Bark(Color(0xFFB07A47), Color(0xFF8A5A33), Color(0xFF5F3A1D));
const _barkD = _Bark(Color(0xFF8A6050), Color(0xFF684338), Color(0xFF452A22));
const _barkG = _Bark(Color(0xFFA89B8E), Color(0xFF857565), Color(0xFF5E5046));
const _birch = _Bark(Color(0xFFFFFFFF), Color(0xFFF1EEE6), Color(0xFFCFC9BC));

const _leafG = Color(0xFF4DBB6A),
    _leafD = Color(0xFF2F9458),
    _leafM = Color(0xFF3FAE60);
const _stemG = Color(0xFF3E9B4F),
    _leafL = Color(0xFF9BE88F),
    _yolk = Color(0xFFFFC53D);

/// Round puffs of leaves, each shaded from a highlight to a shadow, with leaf
/// flecks; they drift a little with the wind.
void _canopy(_Ctx x, List<List<double>> list, _Tone c, _Env e, int seed) {
  final r = _rng(seed * 977 + 13);
  final pts = [
    for (var i = 0; i < list.length; i++)
      [
        list[i][0] +
            math.sin(e.t * 1.6 + i * 1.9) * list[i][2] * .04 +
            e.w * (1 - list[i][1] * .03),
        list[i][1] + math.cos(e.t * 1.3 + i * 1.3) * list[i][2] * .03,
        list[i][2],
      ],
  ];
  for (final p in pts) {
    _dot(x, p[0] + p[2] * .1, p[1] + p[2] * .22, p[2] + .8, c.u);
  }
  for (final p in pts) {
    _dot(
      x,
      p[0],
      p[1],
      p[2],
      ui.Gradient.radial(
        Offset(p[0], p[1]),
        p[2] * 1.02,
        [c.l, c.m, c.d],
        const [0, .55, 1],
        TileMode.clamp,
        null,
        Offset(p[0] - p[2] * .38, p[1] - p[2] * .42),
        p[2] * .05,
      ),
    );
  }
  for (final p in pts) {
    for (var k = 0; k < 4; k++) {
      final an = r() * _tau, rr = (.25 + r() * .5) * p[2];
      final up = math.cos(an) + math.sin(an) < -.2;
      _ell(
        x,
        p[0] + math.cos(an) * rr,
        p[1] + math.sin(an) * rr,
        p[2] * .17,
        p[2] * .075,
        -.7 + r() * .5,
        up ? c.hf : c.uf,
      );
    }
  }
  for (var i = 0; i < pts.length; i += 2) {
    final p = pts[i];
    _ell(
      x,
      p[0] - p[2] * .36,
      p[1] - p[2] * .5,
      p[2] * .24,
      p[2] * .1,
      -.6,
      _white(.3),
    );
  }
}

void _trunk(_Ctx x, double h, double w, _Bark c, [double ln = 0]) {
  x
    ..begin()
    ..moveTo(-w * 1.25, .5)
    ..quad(-w * .5, -h * .06, -w * .42 + ln * .4, -h * .45)
    ..lineTo(-w * .3 + ln, -h)
    ..lineTo(w * .3 + ln, -h)
    ..lineTo(w * .42 + ln * .4, -h * .45)
    ..quad(w * .5, -h * .06, w * 1.25, .5)
    ..quad(w * .45, -1.4, 0, 1.3)
    ..quad(-w * .45, -1.4, -w * 1.25, .5)
    ..close()
    ..fill(_lg(-w * .6 + ln * .5, 0, w * .6 + ln * .5, 0, [c.l, c.m, c.d]));
  x
    ..save()
    ..clip()
    ..rect(
      -w * 2 + ln,
      -h,
      w * 4,
      h * .5,
      _lg(0, -h, 0, -h * .5, const [
        Color.fromRGBO(40, 20, 10, .38),
        Color.fromRGBO(40, 20, 10, 0),
      ]),
    );
  for (final b in const [
    [-.16, .18, .5],
    [.2, .32, .7],
    [-.04, .58, .86],
  ]) {
    x
      ..begin()
      ..moveTo(w * b[0] + ln * b[1], -h * b[1])
      ..quad(
        w * (b[0] + .14) + ln * b[2],
        -h * (b[1] + b[2]) / 2,
        w * b[0] + ln * b[2],
        -h * b[2],
      )
      ..stroke(_a(c.d, .5), .8);
  }
  x.restore();
}

void _limb(_Ctx x, Offset a, Offset c, Offset b, double w, _Bark k) {
  _curve(x, a, c, b, w, k.m);
  final o = _o(w * .2, w * .1);
  _curve(x, a - o, c - o, b - o, w * .32, _a(k.l, .75));
}

void _stem(_Ctx x, Offset a, Offset c, Offset b, double w, Color col) {
  _curve(x, a, c, b, w, col);
  final o = _o(w * .22, 0);
  _curve(x, a - o, c - o, b - o, w * .3, _white(.32));
}

void _leaf(
  _Ctx x,
  double a,
  double b,
  double len,
  double wid,
  double rot,
  Color col, [
  Color? vein,
]) {
  x
    ..save()
    ..translate(a, b)
    ..rotate(rot)
    ..begin()
    ..moveTo(0, 0)
    ..quad(len * .45, -wid, len, 0)
    ..quad(len * .45, wid, 0, 0)
    ..fill(col);
  if (vein != null) {
    x
      ..begin()
      ..moveTo(len * .08, 0)
      ..lineTo(len * .9, 0)
      ..stroke(vein, math.max(.5, wid * .13));
  }
  x.restore();
}

void _blossom(
  _Ctx x,
  double a,
  double b,
  double r,
  Color col, [
  Color ctr = _yolk,
  double rot = 0,
]) {
  if (!(r > 0)) return;
  for (var i = 0; i < 5; i++) {
    final g = i * _tau / 5 + rot;
    _ell(
      x,
      a + math.cos(g) * r * .62,
      b + math.sin(g) * r * .62,
      r * .58,
      r * .42,
      g,
      col,
    );
  }
  _dot(x, a, b, r * .34, ctr);
}

void _star4(_Ctx x, double a, double b, double r, Color col) {
  if (!(r > 0)) return;
  x.begin();
  for (var i = 0; i < 8; i++) {
    final g = i * _tau / 8, rr = i.isOdd ? r * .3 : r;
    i == 0
        ? x.moveTo(a + math.cos(g) * rr, b + math.sin(g) * rr)
        : x.lineTo(a + math.cos(g) * rr, b + math.sin(g) * rr);
  }
  x
    ..close()
    ..fill(col);
}

void _mleaf(_Ctx x, double r, Color col) => _poly(x, [
  _o(0, -r),
  _o(r * .3, -r * .35),
  _o(r, -r * .4),
  _o(r * .5, r * .15),
  _o(r * .65, r * .9),
  _o(0, r * .5),
  _o(-r * .65, r * .9),
  _o(-r * .5, r * .15),
  _o(-r, -r * .4),
  _o(-r * .3, -r * .35),
], col);

void _fan(_Ctx x, double r, Color col) {
  x
    ..begin()
    ..moveTo(0, r * .95)
    ..arc(0, r * .15, r, math.pi + .4, _tau - .4)
    ..close()
    ..fill(col);
}

/// [n] things falling through the box [a] (left, right, top, bottom), each
/// fading in and out, drawn by [draw] at the origin.
void _fall(
  _Ctx x,
  double t,
  int n,
  List<double> a,
  void Function(int i) draw, [
  double sp = .14,
]) {
  for (var i = 0; i < n; i++) {
    final k = (i * .618) % 1, u = (t * sp * (.7 + k * .6) + i * .37) % 1;
    x
      ..save()
      ..alpha *= u < .1 ? u * 10 : (u > .82 ? (1 - u) / .18 : 1)
      ..translate(
        a[0] +
            ((i * .739 + .13) % 1) * (a[1] - a[0]) +
            math.sin(u * 6 + i * 2) * 5 +
            u * 7,
        a[2] + u * (a[3] - a[2]),
      )
      ..rotate(u * 7 + i);
    draw(i);
    x.restore();
  }
}

void _fruit(_Ctx x, double a, double b, double r, List<Color> c) =>
    _dot(x, a, b, r, _rg(a - r * .35, b - r * .4, r * .08, a, b, r, c));

// Small animals.

void _bird(
  _Ctx x,
  double a,
  double b,
  double t,
  Color col,
  Color cd,
  double ph,
) {
  final v = t * .6 + ph, u = v % 5;
  final hop = u < .35 ? -math.sin(u / .35 * math.pi) * 3.5 : 0.0;
  final tilt = u > 2 && u < 2.6 ? .4 : 0.0;
  x
    ..save()
    ..translate(a, b + hop)
    ..scale(v % 10 < 5 ? 1 : -1, 1);
  _poly(x, [_o(-3.6, -1.4), _o(-8.8, -3.4), _o(-7.6, .6)], cd);
  _ell(x, 0, -2.6, 4.7, 3.7, -.15, col);
  _ell(x, .9, -1.5, 3, 2.3, -.1, const Color(0xFFFFE9C7));
  _ell(x, -1.3, -3, 2.7, 1.7, .5, cd);
  x
    ..save()
    ..translate(3.4, -5.7)
    ..rotate(tilt);
  _dot(x, 0, 0, 2.8, col);
  _poly(x, [_o(2.2, -.6), _o(5, .2), _o(2.2, 1)], const Color(0xFFFFA62B));
  _dot(x, .9, -.6, .7, const Color(0xFF1B1B2F));
  _dot(x, 1.15, -.85, .24, Colors.white);
  x.restore();
  _line(x, [_o(-.6, .9), _o(-.6, 2.5)], .6, const Color(0xFFC97B2A));
  _line(x, [_o(1.2, .9), _o(1.2, 2.5)], .6, const Color(0xFFC97B2A));
  x.restore();
}

void _bee(_Ctx x, double cx, double cy, double t, double ph) {
  final a = t * 2.2 + ph, f = math.sin(t * 40) > 0 ? 1.0 : .5;
  x
    ..save()
    ..translate(
      cx + math.cos(a) * 9 + math.sin(a * .37) * 4,
      cy + math.sin(a * 1.3) * 5,
    )
    ..scale(math.sin(a) > 0 ? -1 : 1, 1);
  _ell(x, -.6, -2, 2, 1.2, -.5, _white(.75 * f));
  _ell(x, 1, -2, 2, 1.2, .5, _white(.6 * f));
  _ell(x, 0, 0, 2.6, 1.9, 0, const Color(0xFFFFD43B));
  _line(x, [_o(-.5, -1.6), _o(-.5, 1.6)], .8, const Color(0xFF3B2A14));
  _line(x, [_o(.9, -1.4), _o(.9, 1.4)], .8, const Color(0xFF3B2A14));
  _dot(x, -2.2, -.2, 1, const Color(0xFF3B2A14));
  x.restore();
}

void _butterfly(
  _Ctx x,
  double cx,
  double cy,
  double t,
  Color c1,
  Color c2,
  double ph, [
  double amp = 1,
]) {
  final a = t * .8 + ph, f = .25 + .75 * math.sin(t * 10 + ph).abs();
  x
    ..save()
    ..translate(
      cx + (math.sin(a) * 13 + math.sin(a * 2.3) * 5) * amp,
      cy + (math.cos(a * 1.3) * 7 + math.sin(a * 3.1) * 2) * amp,
    )
    ..rotate(math.cos(a) * .35);
  for (final d in const [-1.0, 1.0]) {
    x
      ..save()
      ..scale(d * f, 1);
    _ell(x, 2.7, -1.3, 2.9, 2.3, -.4, c1);
    _ell(x, 2.1, 1.7, 2, 1.6, .5, c2);
    _dot(x, 3, -1.4, .8, _white(.7));
    x.restore();
  }
  _line(x, [_o(0, -2.4), _o(0, 2.6)], .9, const Color(0xFF3B2A14));
  x.restore();
}

// ignore: unused_element, kept for the garden screen's evening sky.
void _firefly(_Ctx x, double px, double py, double t, double ph) {
  final a = .3 + .7 * math.sin(t * 1.7 + ph).abs();
  _dot(
    x,
    px,
    py,
    6,
    _rg(px, py, 0, px, py, 6, [
      Color.fromRGBO(255, 244, 160, a),
      const Color.fromRGBO(255, 244, 160, 0),
    ]),
  );
  _dot(x, px, py, 1, Color.fromRGBO(255, 255, 235, a));
}

void _dragonfly(_Ctx x, double cx, double cy, double t) {
  final a = t * 1.1, f = math.sin(t * 38) > 0 ? 1.0 : .55;
  x
    ..save()
    ..translate(
      cx + math.sin(a) * 12 + math.sin(a * 2.7) * 3,
      cy + math.cos(a * 1.6) * 5,
    )
    ..scale(math.cos(a) > 0 ? 1 : -1, 1);
  _ell(x, -1, -2.4, 5, 1.4, -.3, _white(.8 * f));
  _ell(x, 1.5, -2.2, 4.4, 1.3, .3, _white(.65 * f));
  _line(x, [_o(-7, 0), _o(3, 0)], 1.3, const Color(0xFF22B8CF));
  _dot(x, 3.6, 0, 1.5, const Color(0xFF0C8599));
  x.restore();
}

void _snail(_Ctx x, double a, double b, double t) {
  final u = (t * .03) % 1;
  x
    ..save()
    ..alpha *= u < .08 ? u / .08 : (u > .92 ? (1 - u) / .08 : 1)
    ..translate(a + u * 46, b);
  _ell(x, 0, 0, 5, 1.6, 0, const Color(0xFFF3D9A4));
  _dot(x, -1, -2.6, 3.2, const Color(0xFFC98A4B));
  _dot(x, -1, -2.6, 1.9, const Color(0xFFE0A868));
  _dot(x, -1, -2.6, .8, const Color(0xFFC98A4B));
  final w = math.sin(t * 3) * .4;
  _line(x, [_o(4, -.6), _o(5.4, -3.4 + w)], .6, const Color(0xFFF3D9A4));
  _dot(x, 5.4, -3.6 + w, .7, const Color(0xFF3B2A14));
  x.restore();
}
