// Renders the app icons and launch images from LogoPainter, so they always
// match the logo drawn in the app. Run with scripts/make_icons.sh, which
// also strips the alpha channel the App Store refuses on iOS icons.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hifive/widgets/common.dart';

Future<void> _write(String path, int px, LogoPainter painter) async {
  final recorder = ui.PictureRecorder();
  painter.paint(Canvas(recorder), Size.square(px.toDouble()));
  final image = await recorder.endRecording().toImage(px, px);
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  File(path)
    ..parent.createSync(recursive: true)
    ..writeAsBytesSync(data!.buffer.asUint8List());
}

/// Android density folders and their scale from mdpi.
const _densities = {
  'mdpi': 1.0,
  'hdpi': 1.5,
  'xhdpi': 2.0,
  'xxhdpi': 3.0,
  'xxxhdpi': 4.0,
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('iOS app icons', () async {
    const dir = 'ios/Runner/Assets.xcassets/AppIcon.appiconset';
    const sizes = {
      'Icon-App-20x20@1x.png': 20,
      'Icon-App-20x20@2x.png': 40,
      'Icon-App-20x20@3x.png': 60,
      'Icon-App-29x29@1x.png': 29,
      'Icon-App-29x29@2x.png': 58,
      'Icon-App-29x29@3x.png': 87,
      'Icon-App-40x40@1x.png': 40,
      'Icon-App-40x40@2x.png': 80,
      'Icon-App-40x40@3x.png': 120,
      'Icon-App-60x60@2x.png': 120,
      'Icon-App-60x60@3x.png': 180,
      'Icon-App-76x76@1x.png': 76,
      'Icon-App-76x76@2x.png': 152,
      'Icon-App-83.5x83.5@2x.png': 167,
      'Icon-App-1024x1024@1x.png': 1024,
    };
    // Square and opaque: iOS rounds the corners itself.
    for (final MapEntry(key: name, value: px) in sizes.entries) {
      await _write('$dir/$name', px, const LogoPainter(rounded: false));
    }
  });

  test('iOS launch image', () async {
    const dir = 'ios/Runner/Assets.xcassets/LaunchImage.imageset';
    // 120 pt, centred on white by LaunchScreen.storyboard.
    for (final (suffix, px) in [('', 120), ('@2x', 240), ('@3x', 360)]) {
      await _write('$dir/LaunchImage$suffix.png', px, const LogoPainter());
    }
  });

  test('Android launcher icons and launch logo', () async {
    const res = 'android/app/src/main/res';
    for (final MapEntry(key: density, value: scale) in _densities.entries) {
      // Legacy icon, 48 dp, with its own rounded tile.
      await _write(
        '$res/mipmap-$density/ic_launcher.png',
        (48 * scale).round(),
        const LogoPainter(),
      );
      // Adaptive icon foreground, 108 dp: the bars alone, shrunk into the
      // 66 dp safe zone; the ink background is a color resource.
      await _write(
        '$res/mipmap-$density/ic_launcher_foreground.png',
        (108 * scale).round(),
        const LogoPainter(tile: false, scale: .7),
      );
      // Launch screen logo, 120 dp.
      await _write(
        '$res/drawable-$density/launch_logo.png',
        (120 * scale).round(),
        const LogoPainter(),
      );
    }
  });
}
