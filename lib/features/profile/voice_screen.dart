import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../core/design/design.dart';
import '../../state/state.dart';
import '../../widgets/blur_header.dart';
import '../../widgets/press.dart';
import 'settings_kit.dart';

class VoiceScreen extends StatelessWidget {
  const VoiceScreen({super.key});
  static const _voices = [
    ('Aaron', 'United States'),
    ('Arthur', 'United Kingdom'),
    ('Catherine', 'Australia'),
    ('Gordon', 'Australia'),
    ('Martha', 'United Kingdom'),
    ('Nicky', 'United States'),
  ];

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    return SettingsPage(
      title: 'Giọng đọc',
      padding: const EdgeInsets.fromLTRB(24, 157, 24, 130),
      trailing: HeaderRoundButton(
        icon: CupertinoIcons.question_circle,
        iconSize: 26,
        label: 'Cách cài đặt giọng đọc',
        width: 48,
        onTap: () => _showHelp(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SettingsHero(
            art: Center(
              child: CustomPaint(
                size: Size(44, 50),
                painter: VoiceBarsPainter(),
              ),
            ),
            gap: 11,
            subtitleInset: 19,
            title: 'Neural Voice Engine',
            subtitle: 'Hifive sử dụng công nghệ Neural Audio của Apple để mang lại trải nghiệm nghe tự nhiên và sống động nhất.',
          ),
          const SizedBox(height: 31),
          const SettingsSectionTitle('Voice Models'),
          const SizedBox(height: 15),
          for (final (name, region) in _voices)
            Padding(
              padding: const EdgeInsets.only(bottom: 15),
              child: SelectCard(
                key: ValueKey('voice-$name'),
                selected: s.voice == name,
                height: 89,
                onTap: () {
                  s.setVoice(name);
                  s.feedback.speak(
                    'Welcome to Hifive. Let us learn something new today.',
                  );
                },
                child: Row(
                  children: [
                    const SizedBox(width: 20),
                    Container(
                      width: 48,
                      height: 48,
                      decoration: const BoxDecoration(
                        color: Palette.settingsPage,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        CupertinoIcons.play_fill,
                        size: 20,
                        color: Palette.settingsMuted,
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: D.text(
                              16,
                              weight: FontWeight.w600,
                              height: 21 / 16,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Text(
                                region,
                                style: D.text(
                                  13.2,
                                  color: Palette.settingsMuted,
                                  height: 18 / 13.2,
                                ),
                              ),
                              Text(
                                '   ·   ',
                                style: D.text(
                                  10,
                                  color: Palette.settingsMuted,
                                  height: 1,
                                ),
                              ),
                              Text(
                                'Normal',
                                style: D.text(
                                  11,
                                  weight: FontWeight.w700,
                                  color: Palette.voiceNormal,
                                  height: 18 / 11,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  static Future<void> _showHelp(BuildContext context) =>
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        barrierColor: Palette.sheetBarrier,
        showDragHandle: false,
        elevation: 0,
        builder: (_) => const _VoiceHelpSheet(),
      );
}

/// The floating frosted sheet. Its grabber, its "Đóng" pill and dragging it down
/// all close it.
class _VoiceHelpSheet extends StatelessWidget {
  const _VoiceHelpSheet();
  static const _steps = [
    (
      'Mở Cài đặt (Settings)',
      'Truy cập ứng dụng Cài đặt trên màn hình chính của iPhone.',
      CupertinoIcons.gear_alt,
    ),
    (
      'Vào Trợ năng (Accessibility)',
      'Tìm và chọn mục Trợ năng trong danh sách\ncài đặt.',
      Icons.accessibility_new_rounded,
    ),
    (
      'Mở Nội dung được đọc',
      "Chọn 'Đọc & Nói' (Read & Speak) -> 'Giọng nói' (Voices).",
      CupertinoIcons.chat_bubble_2_fill,
    ),
    (
      'Tải giọng Premium hoặc Enhanced',
      "Chọn 'Tiếng Anh' (English) -> Chọn 1 giọng (ví dụ: Ava, Tom) -> Tải về bản 'Cao cấp' (Premium) hoặc 'Nâng cao' (Enhanced).",
      CupertinoIcons.arrow_down_circle_fill,
    ),
  ];

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
    child: ClipRSuperellipse(
      borderRadius: BorderRadius.circular(38),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
        child: Container(
          decoration: ShapeDecoration(
            color: Palette.sheetGlass,
            shape: RoundedSuperellipseBorder(
              borderRadius: BorderRadius.circular(38),
              side: const BorderSide(color: Colors.white),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(22, 8, 16, 34),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Palette.settingsHint,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              const SizedBox(height: 5),
              Align(
                alignment: Alignment.centerRight,
                child: PressFade(
                  key: const ValueKey('voice-help-close'),
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 71,
                    height: 44,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .7),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: Palette.sheetEdge),
                    ),
                    child: Text(
                      'Đóng',
                      style: D.text(15.5, weight: FontWeight.w600, height: 1),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 30),
              Text(
                'Cách cài đặt giọng đọc',
                style: D.text(24, weight: FontWeight.w800, height: 34 / 24),
              ),
              const SizedBox(height: 11),
              Padding(
                padding: const EdgeInsets.only(right: 20),
                child: Text(
                  'Để có trải nghiệm nghe tốt nhất, hãy tải về các gói giọng đọc Neural chất lượng cao từ Apple trên chính Iphone của bạn.',
                  style: D.text(
                    14.6,
                    color: Palette.iconGrey,
                    height: 18 / 14.6,
                  ),
                ),
              ),
              const SizedBox(height: 31),
              for (final (i, step) in _steps.indexed)
                Padding(
                  padding: EdgeInsets.only(bottom: i == 3 ? 0 : 30),
                  child: _Step(
                    number: i + 1,
                    title: step.$1,
                    body: step.$2,
                    icon: step.$3,
                  ),
                ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _Step extends StatelessWidget {
  final int number;
  final String title, body;
  final IconData icon;
  const _Step({
    required this.number,
    required this.title,
    required this.body,
    required this.icon,
  });
  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        width: 38,
        height: 38,
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
        child: Text(
          '$number',
          style: D.text(14.5, weight: FontWeight.w600, height: 1),
        ),
      ),
      const SizedBox(width: 15),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: D.text(
                      14.3,
                      weight: FontWeight.w700,
                      height: 20 / 14.3,
                    ),
                  ),
                ),
                Icon(icon, size: 23, color: Palette.settingsHint),
              ],
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: Text(
                body,
                style: D.text(
                  12.65,
                  color: Palette.settingsMuted,
                  height: 19.5 / 12.65,
                ),
              ),
            ),
          ],
        ),
      ),
    ],
  );
}
