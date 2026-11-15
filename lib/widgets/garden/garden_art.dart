import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../domain/garden/garden.dart';
import '../ambient.dart';

part 'garden_blooms.dart';
part 'garden_decor.dart';
part 'garden_kit.dart';
part 'garden_land.dart';
part 'garden_plants.dart';
part 'garden_trees.dart';

/// Whether [id] has a drawing. Every id in `species` has one.
bool hasTreeArt(String id) => _arts.containsKey(id);

/// A PNG of species [id] at [growth] on its sunlit patch, [size] pixels a
/// side, for the lock screen's Live Activity. Null if encoding fails.
Future<Uint8List?> plantPicture(
  String id,
  double growth, {
  int size = 240,
}) async {
  final recorder = ui.PictureRecorder();
  // Young plants are small: frame them closer so they fill the circle.
  final zoom = growth < .14 ? 2.1 : (growth < .45 ? 1.45 : 1.0);
  final canvas = Canvas(recorder)
    ..scale(size / 200)
    ..translate(100, 150)
    ..scale(zoom)
    ..translate(-100, -170);
  _patch(canvas);
  canvas
    ..translate(100, 170)
    ..scale(.8)
    ..translate(-100, -182);
  _plant(canvas, id, growth, 7.3, true);
  final image = await recorder.endRecording().toImage(size, size);
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  return data?.buffer.asUint8List();
}

/// One plant. With [island] it stands on a patch of sunlit grass, as on the
/// focus screen; without, alone on its soft shadow, as in the collection.
/// [growth] runs from a seed (0) through a sprout and a sapling to fully grown
/// (1); [bloom] from 0 to 1 opens white flowers one by one; a [withered]
/// plant keeps its shape in dry colours.
class TreeArt extends StatelessWidget {
  final String species;
  final double growth, bloom, size;
  final bool withered;

  /// A rare ancient tree: larger, in a warm halo, with drifting motes.
  final bool ancient;

  /// A study tree drooping, paler, for want of water.
  final bool thirsty;

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
    this.ancient = false,
    this.thirsty = false,
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
        raster: !animate,
        ancient: ancient,
        thirsty: thirsty,
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

  /// The sky over the garden; null draws none, as for past periods.
  final GardenWeather? weather;

  /// Decorations earned, by id from `decorations`, set along the edges.
  final List<String> decorations;
  const GardenScene({
    super.key,
    required this.plants,
    required this.width,
    this.cells = 5,
    this.weather,
    this.decorations = const [],
  });

  /// The grid side that fits [count] plants and [decor] decorations: at
  /// least 5.
  static int cellsFor(int count, [int decor = 0]) =>
      math.max(5, math.sqrt(count + decor).ceil());

  @override
  Widget build(BuildContext context) {
    final h = width / 2, d = width * .035 + 9;
    return _Animated(
      size: Size(width, h + d + width / cells * 1.35),
      // Only the weather moves: the sun's rays, the clouds and the rain.
      animate: weather != null,
      paint: (canvas, size, t, still) {
        final top = width / cells * 1.25;
        final sky = weather;
        canvas.clipRect(Offset.zero & size);
        if (sky != null) _weather(canvas, sky, size, top, t, behind: true);
        _garden(
          canvas,
          width / 2,
          top + h / 2,
          width,
          cells,
          plants,
          decorations,
        );
        if (sky != null) _weather(canvas, sky, size, top, t, behind: false);
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
    _follow();
  }

  /// A scene that stops animating (a past period has no weather) stops its
  /// ticker too.
  @override
  void didUpdateWidget(_Animated old) {
    super.didUpdateWidget(old);
    if (old.animate != widget.animate) _follow();
  }

  void _follow() {
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
