import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../domain/garden/garden.dart';
import '../ambient.dart';

part 'garden_blooms.dart';
part 'garden_kit.dart';
part 'garden_land.dart';
part 'garden_plants.dart';
part 'garden_trees.dart';

/// Whether [id] has a drawing. Every id in `species` has one.
bool hasTreeArt(String id) => _arts.containsKey(id);

/// One plant. With [island] it stands on a patch of sunlit grass, as on the
/// focus screen; without, alone on its soft shadow, as in the collection.
/// [growth] runs from a seed (0) through a sprout and a sapling to fully grown
/// (1); [bloom] from 0 to 1 opens white flowers one by one; a [withered]
/// plant keeps its shape in dry colours.
class TreeArt extends StatelessWidget {
  final String species;
  final double growth, bloom, size;
  final bool withered;

  /// True stands the plant on a sunlit patch of grass.
  final bool island;

  /// False draws it once, still, as in grids of many plants, where each
  /// moving would cost a frame of its own.
  final bool animate;
  const TreeArt({
    super.key,
    required this.species,
    required this.size,
    this.growth = 1,
    this.bloom = 0,
    this.withered = false,
    this.island = true,
    this.animate = true,
  });

  @override
  Widget build(BuildContext context) => _Animated(
    size: Size(size, size),
    animate: animate,
    paint: (canvas, box, t, still) {
      canvas.scale(box.width / 200);
      if (island) {
        _patch(canvas);
        canvas
          ..save()
          ..translate(100, 170)
          ..scale(.8)
          ..translate(-100, -182);
      }
      _plant(
        canvas,
        species,
        growth,
        t,
        still,
        bloom: bloom,
        withered: withered,
      );
      if (island) canvas.restore();
    },
  );
}

/// The garden: an isometric grid of land with [plants] set on it, nearest
/// last. The tallest plants reach a little above the grid. [cells] is the
/// grid's side; plants beyond it are left out. It is drawn still: many
/// swaying plants would cost too much each frame.
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
      animate: false,
      paint: (canvas, size, t, still) {
        final top = width / cells * 1.25;
        _garden(canvas, width / 2, top + h / 2, width, cells, plants);
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
  final bool animate;
  const _Animated({
    required this.size,
    required this.paint,
    this.animate = true,
  });

  @override
  State<_Animated> createState() => _AnimatedState();
}

class _AnimatedState extends State<_Animated>
    with SingleTickerProviderStateMixin {
  // A moment where every plant looks its best when still.
  static const _restTime = 7.3;
  final _time = ValueNotifier<double>(_restTime);
  late final Ticker _ticker = createTicker(
    (elapsed) => _time.value = _restTime + elapsed.inMicroseconds / 1e6,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final on = widget.animate && AmbientMotion.of(context);
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
