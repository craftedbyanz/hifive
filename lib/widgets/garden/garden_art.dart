import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../domain/garden/garden.dart';
import '../ambient.dart';

part 'garden_kit.dart';
part 'garden_land.dart';
part 'garden_species.dart';

/// Whether [id] has a drawing. Every id in `species` has one.
bool hasTreeArt(String id) => _arts.containsKey(id);

/// One tree on its floating tile of land, as on the focus screens and in the
/// species collection. [growth] runs from a seed (0) to fully grown (1);
/// [bloom] from 0 to 1 opens white flowers one by one.
class TreeArt extends StatelessWidget {
  final String species;
  final double growth, bloom, size;
  final bool withered;

  /// A floating tile casts a shadow below it and shows rocks under its soil.
  final bool floating;
  const TreeArt({
    super.key,
    required this.species,
    required this.size,
    this.growth = 1,
    this.bloom = 0,
    this.withered = false,
    this.floating = true,
  });

  @override
  Widget build(BuildContext context) => _Animated(
    size: Size(size, size),
    paint: (canvas, size, t, still) {
      final x = _Ctx(canvas), w = size.width;
      final cy = w * .72 + (still ? 0 : math.sin(t * .9) * w * .012);
      _land(x, w / 2, cy, w * .74, w * .38, w * .11, 1, 11, floating);
      _tree(
        x,
        w / 2,
        cy,
        w * .66,
        species,
        growth,
        t,
        still,
        bloom: bloom,
        dead: withered,
      );
    },
  );
}

/// The garden: an isometric grid of land with [plants] set on it, nearest
/// last. The tallest trees reach a little above the box, as in the mockup. [cells] is the grid's side; plants beyond it are left out.
class GardenScene extends StatelessWidget {
  final List<Plant> plants;
  final int cells;
  final double width;
  const GardenScene({
    super.key,
    required this.plants,
    required this.width,
    this.cells = 5,
  });

  /// The grid side that fits [count] plants: at least 5.
  static int cellsFor(int count) => math.max(5, math.sqrt(count).ceil());

  @override
  Widget build(BuildContext context) {
    final h = width / 2, d = width * .035 + 9;
    return _Animated(
      size: Size(width, h + d + width / cells * 1.35),
      paint: (canvas, size, t, still) {
        final x = _Ctx(canvas), top = width / cells * 1.25;
        _garden(x, width / 2, top + h / 2, width, cells, plants, t, still);
      },
    );
  }
}

typedef _Painter = void Function(
  Canvas canvas,
  Size size,
  double t,
  bool still,
);

/// Repaints every frame while ambient motion is on; otherwise draws one still
/// frame, so tests settle.
class _Animated extends StatefulWidget {
  final Size size;
  final _Painter paint;
  const _Animated({required this.size, required this.paint});

  @override
  State<_Animated> createState() => _AnimatedState();
}

class _AnimatedState extends State<_Animated>
    with SingleTickerProviderStateMixin {
  // A moment where every tree looks its best when still.
  static const _restTime = 7.3;
  final _time = ValueNotifier<double>(_restTime);
  late final Ticker _ticker = createTicker(
    (elapsed) => _time.value = _restTime + elapsed.inMicroseconds / 1e6,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final on = AmbientMotion.of(context);
    if (on && !_ticker.isActive) {
      _ticker.start();
    } else if (!on && _ticker.isActive) {
      _ticker.stop();
      _time.value = _restTime;
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    _time.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RepaintBoundary(
    child: CustomPaint(
      size: widget.size,
      painter: _ScenePainter(widget.paint, _time, !_ticker.isActive),
    ),
  );
}

class _ScenePainter extends CustomPainter {
  final _Painter draw;
  final ValueNotifier<double> time;
  final bool still;
  _ScenePainter(this.draw, this.time, this.still) : super(repaint: time);

  @override
  void paint(Canvas canvas, Size size) => draw(canvas, size, time.value, still);

  @override
  bool shouldRepaint(_ScenePainter old) =>
      old.draw != draw || old.still != still;
}
