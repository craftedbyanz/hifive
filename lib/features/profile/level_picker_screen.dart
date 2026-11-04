import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../core/design.dart';
import '../../core/state.dart';
import '../../widgets/press.dart';
import '../learning/learning.dart';
import 'settings_kit.dart';

class LevelPickerScreen extends StatefulWidget {
  const LevelPickerScreen({super.key});
  @override
  State<LevelPickerScreen> createState() => _LevelPickerScreenState();
}

class _LevelPickerScreenState extends State<LevelPickerScreen> {
  static const _colors = [
    Palette.levelA1,
    Palette.levelA2,
    Palette.levelB1,
    Palette.levelB2,
    Palette.levelC1,
    Palette.levelC2,
  ];
  String? selected;

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    selected ??= s.level;
    return SettingsPage(
      title: 'Chọn cấp độ',
      background: Colors.white,
      padding: const EdgeInsets.fromLTRB(24, 129, 24, 140),
      footer: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 50),
        child: SettingsCta(
          'Xác nhận',
          color: Palette.ctaGreen,
          onTap: () {
            s.setLevel(selected!);
            Navigator.pop(context);
          },
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Khung tham chiếu ngôn ngữ chung châu Âu (CEFR) chia trình độ thành 6 cấp, từ người mới bắt đầu đến thành thạo.',
            style: D.text(14.7, color: Palette.iconGrey, height: 21.5 / 14.7),
          ),
          const SizedBox(height: 11),
          Text(
            'AI sẽ tạo ra các bài viết dựa theo trình độ của bạn, hãy chọn mức độ phù hợp nhất.',
            style: D.text(13.6, color: Palette.levelNote, height: 20.7 / 13.6),
          ),
          const SizedBox(height: 19),
          Text(
            'Trình độ của bạn',
            style: D.text(19, weight: FontWeight.w700, height: 24 / 19),
          ),
          const SizedBox(height: 32),
          for (var i = 0; i < levels.length; i++) ...[
            _LevelRow(
              key: ValueKey('level-${levels[i].substring(0, 2)}'),
              title: levels[i],
              description: levelDescriptions[i],
              color: _colors[i],
              selected: selected == levels[i].substring(0, 2),
              onTap: () => setState(() => selected = levels[i].substring(0, 2)),
            ),
            if (i < levels.length - 1)
              const Padding(
                padding: EdgeInsets.only(left: 20, top: 16, bottom: 15),
                child: Divider(height: 1, color: Palette.settingsEdge),
              ),
          ],
        ],
      ),
    );
  }
}

class _LevelRow extends StatelessWidget {
  final String title, description;
  final Color color;
  final bool selected;
  final VoidCallback onTap;
  const _LevelRow({
    super.key,
    required this.title,
    required this.description,
    required this.color,
    required this.selected,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) => PressFade(
    onTap: onTap,
    child: IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            width: 4,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: D.text(15, weight: FontWeight.w700, height: 20 / 15),
                ),
                const SizedBox(height: 2),
                Padding(
                  padding: const EdgeInsets.only(right: 24),
                  child: Text(
                    description,
                    style: D.text(
                      12,
                      color: Palette.settingsMuted,
                      height: 17 / 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Align(
            alignment: Alignment.topRight,
            child: selected
                ? Container(
                    width: 24,
                    height: 24,
                    decoration: const BoxDecoration(
                      color: Palette.ctaGreen,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      CupertinoIcons.checkmark_alt,
                      size: 16,
                      color: Colors.white,
                    ),
                  )
                : Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Palette.ctaDisabled, width: 2),
                    ),
                  ),
          ),
        ],
      ),
    ),
  );
}
