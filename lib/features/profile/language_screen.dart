import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../core/design.dart';
import '../../core/state.dart';
import '../../widgets/common.dart';
import '../../widgets/glyphs.dart';
import '../../widgets/press.dart';
import '../learning/learning.dart';
import 'level_picker_screen.dart';
import 'settings_kit.dart';

/// Picking a language that is coming soon moves the ring and swaps the footer
/// for a disabled "Sắp ra mắt", as on the reference. Nothing is saved.
class LanguageScreen extends StatefulWidget {
  const LanguageScreen({super.key});
  @override
  State<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends State<LanguageScreen> {
  static const _languages = [
    ('English', 'English', FlagPainter()),
    ('Korean', '한국어', KoreaFlagPainter()),
    ('Chinese', '中文', ChinaFlagPainter()),
    ('Japanese', '日本語', JapanFlagPainter()),
  ];
  String _selected = 'English';

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final soon = _selected != 'English';
    return SettingsPage(
      title: 'Ngôn ngữ học',
      padding: const EdgeInsets.fromLTRB(24, 133, 24, 215),
      footer: Padding(
        padding: EdgeInsets.fromLTRB(24, soon ? 0 : 11, 24, 50),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!soon) ...[
              _LevelBox(
                level: s.level,
                onTap: () => go<void>(context, const LevelPickerScreen()),
              ),
              const SizedBox(height: 12),
            ],
            soon
                ? const SettingsCta(
                    'Sắp ra mắt',
                    color: Palette.ctaDisabled,
                    onTap: null,
                    icon: Icon(
                      CupertinoIcons.clock_fill,
                      size: 17,
                      color: Colors.white,
                    ),
                  )
                : SettingsCta(
                    'Xác nhận',
                    color: Palette.ctaCyan,
                    onTap: () => Navigator.pop(context),
                  ),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SettingsHero(
            art: Center(
              child: CustomPaint(
                size: Size(75, 55),
                painter: TranslateBubblesPainter(),
              ),
            ),
            title: 'Chọn ngôn ngữ học',
            subtitle: 'Hifive hiện hỗ trợ lên tới 4 ngôn ngữ và sẽ mở rộng thêm trong tương lai.',
          ),
          const SizedBox(height: 31),
          const SettingsSectionTitle('Ngôn ngữ'),
          const SizedBox(height: 14),
          for (final (name, native, flag) in _languages)
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: SelectCard(
                key: ValueKey('language-$name'),
                selected: _selected == name,
                height: 82,
                onTap: () => setState(() => _selected = name),
                child: Row(
                  children: [
                    SizedBox(width: name == 'English' ? 20 : 21),
                    CustomPaint(
                      size: name == 'English'
                          ? const Size(44, 27)
                          : const Size(48, 33),
                      painter: flag,
                    ),
                    SizedBox(width: name == 'English' ? 22 : 18),
                    Expanded(
                      child: _LanguageText(
                        name: name,
                        native: native,
                        soon: name != 'English',
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
}

class _LanguageText extends StatelessWidget {
  final String name, native;
  final bool soon;
  const _LanguageText({
    required this.name,
    required this.native,
    required this.soon,
  });
  @override
  Widget build(BuildContext context) => Column(
    mainAxisAlignment: MainAxisAlignment.center,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Text(
            name,
            style: D.text(
              16.5,
              weight: FontWeight.w600,
              color: soon ? Palette.settingsMuted : D.ink,
              height: 22 / 16.5,
            ),
          ),
          const SizedBox(width: 6),
          if (soon)
            Container(
              height: 18,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Palette.soonFill,
                borderRadius: BorderRadius.circular(9),
              ),
              child: Text(
                'Coming soon',
                style: D.text(
                  10.5,
                  weight: FontWeight.w600,
                  color: Palette.soonInk,
                  height: 1,
                ),
              ),
            )
          else
            const Icon(
              CupertinoIcons.star_circle_fill,
              size: 17,
              color: Palette.nativeStar,
            ),
        ],
      ),
      const SizedBox(height: 3),
      Text(
        native,
        style: D.text(13.5, color: Palette.settingsMuted, height: 18 / 13.5),
      ),
    ],
  );
}

class _LevelBox extends StatelessWidget {
  final String level;
  final VoidCallback onTap;
  const _LevelBox({required this.level, required this.onTap});
  @override
  Widget build(BuildContext context) => PressFade(
    key: const ValueKey('language-level'),
    onTap: onTap,
    child: Container(
      height: 63,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: ShapeDecoration(
        color: Colors.white,
        shape: RoundedSuperellipseBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: Palette.settingsEdge),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'TRÌNH ĐỘ HIỆN TẠI',
                  style: D.text(
                    11,
                    weight: FontWeight.w700,
                    color: Palette.settingsMuted,
                    spacing: .4,
                    height: 15 / 11,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  levels.firstWhere((l) => l.startsWith(level)),
                  style: D.text(14, weight: FontWeight.w600, height: 19 / 14),
                ),
              ],
            ),
          ),
          const Icon(
            CupertinoIcons.chevron_forward,
            size: 16,
            color: Palette.settingsMuted,
          ),
        ],
      ),
    ),
  );
}
