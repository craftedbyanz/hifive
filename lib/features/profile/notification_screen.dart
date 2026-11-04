import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../core/design.dart';
import '../../core/state.dart';
import '../../widgets/common.dart';
import '../../widgets/press.dart';
import 'settings_kit.dart';

const _months = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];
const _days = [
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
];

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final today = s.now();
    return SettingsPage(
      title: 'Thông báo',
      background: Colors.white,
      padding: const EdgeInsets.fromLTRB(24, 132, 24, 60),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _LockScreenArt(
            date:
                '${_days[today.weekday - 1]}, ${_months[today.month - 1]} ${today.day}',
          ),
          const SizedBox(height: 24),
          Container(
            height: 76,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
            decoration: _boxDecoration,
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    color: Palette.pushDisc,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    CupertinoIcons.bell_fill,
                    size: 23,
                    color: Palette.pushBell,
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Thông báo đẩy',
                        style: D.text(
                          14.8,
                          weight: FontWeight.w700,
                          height: 20 / 14.8,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        // This app never asks for notification permission.
                        'Chưa bật trong Cài đặt',
                        style: D.text(
                          12.5,
                          color: Palette.settingsMuted,
                          height: 17 / 12.5,
                        ),
                      ),
                    ],
                  ),
                ),
                PressFade(
                  key: const ValueKey('notification-settings'),
                  onTap: () async {
                    final shown = await s.system.openAppSettings();
                    if (!shown && context.mounted) {
                      toast(context, 'Không mở được Cài đặt.');
                    }
                  },
                  child: Container(
                    width: 70,
                    height: 32,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Palette.pushPill,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      'Cài đặt',
                      style: D.text(
                        12.5,
                        weight: FontWeight.w600,
                        color: Palette.ctaGreen,
                        height: 1,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.fromLTRB(20, 21, 20, 21),
            decoration: _boxDecoration,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      CupertinoIcons.sparkles,
                      size: 19,
                      color: Palette.smartSpark,
                    ),
                    const SizedBox(width: 9),
                    Text(
                      'Lịch nhắc thông minh',
                      style: D.text(
                        14.8,
                        weight: FontWeight.w700,
                        height: 20 / 14.8,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 11),
                Text(
                  'Hifive tự động học thói quen của bạn. Chúng tôi sẽ nhắc bạn vào thời gian bạn thường học nhất.',
                  style: D.text(
                    13,
                    color: Palette.settingsMuted,
                    height: 20.5 / 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static final _boxDecoration = ShapeDecoration(
    color: Palette.settingsPage,
    shape: RoundedSuperellipseBorder(
      borderRadius: BorderRadius.circular(22),
      side: const BorderSide(color: Palette.settingsPanel),
    ),
  );
}

/// A lock screen drawn from vector shapes: the reference's wallpaper image and
/// glass numerals are not bundled.
class _LockScreenArt extends StatelessWidget {
  final String date;
  const _LockScreenArt({required this.date});
  @override
  Widget build(BuildContext context) => ClipRSuperellipse(
    borderRadius: BorderRadius.circular(38),
    child: SizedBox(
      height: 380,
      child: Stack(
        children: [
          const Positioned.fill(
            child: CustomPaint(painter: _WallpaperPainter()),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: 56,
            child: Text(
              date,
              textAlign: TextAlign.center,
              style: D.text(
                16,
                weight: FontWeight.w600,
                color: Colors.white.withValues(alpha: .88),
                height: 22 / 16,
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: 96,
            child: Center(
              child: Transform.scale(
                scaleX: .85,
                scaleY: 1.32,
                child: Stack(
                  children: [
                    Text(
                      '09:00',
                      style: D.text(
                        84,
                        weight: FontWeight.w800,
                        color: Colors.white.withValues(alpha: .34),
                        height: 92 / 84,
                      ),
                    ),
                    Text(
                      '09:00',
                      style: D
                          .text(84, weight: FontWeight.w800, height: 92 / 84)
                          .copyWith(
                            foreground: Paint()
                              ..style = PaintingStyle.stroke
                              ..strokeWidth = 2
                              ..color = Colors.white.withValues(alpha: .82),
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: 26,
            right: 26,
            top: 254,
            child: Container(
              height: 68,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .16),
                borderRadius: BorderRadius.circular(22),
              ),
            ),
          ),
          Positioned(
            left: 12,
            right: 12,
            top: 245,
            child: Container(
              height: 74,
              padding: const EdgeInsets.symmetric(horizontal: 22),
              decoration: BoxDecoration(
                color: Palette.sheetEdge.withValues(alpha: .78),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                children: [
                  const Flower(size: 28, strong: true),
                  const SizedBox(width: 22),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final (width, height) in const [
                        (80.0, 10.0),
                        (159.0, 7.0),
                        (99.0, 7.0),
                      ])
                        Container(
                          width: width,
                          height: height,
                          margin: const EdgeInsets.symmetric(vertical: 3.5),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: .85),
                            borderRadius: BorderRadius.circular(height / 2),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _WallpaperPainter extends CustomPainter {
  const _WallpaperPainter();
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(rect, Paint()..color = Palette.wallMist);
    canvas.drawCircle(
      Offset(size.width * .78, -size.height * .12),
      size.width * .62,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Palette.wallBlue, Palette.wallDeep],
        ).createShader(rect),
    );
    canvas.drawCircle(
      Offset(-size.width * .1, size.height * 1.02),
      size.width * .82,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Palette.wallTeal, Palette.wallMint],
        ).createShader(rect),
    );
    canvas.drawCircle(
      Offset(size.width * .98, size.height * .92),
      size.width * .46,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(.96, .84),
          radius: .62,
          colors: [
            Palette.wallBlue.withValues(alpha: .55),
            Palette.wallBlue.withValues(alpha: 0),
          ],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(_WallpaperPainter oldDelegate) => false;
}
