import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../core/design/design.dart';
import '../../domain/models/models.dart';
import '../../state/state.dart';
import '../../widgets/common.dart';
import '../learning/learning.dart';
import 'level_picker_screen.dart';
import 'settings_kit.dart';

/// Lists every course from [LessonRepository.courses]. Picking one without
/// content moves the ring and swaps the footer for a disabled "Sắp ra mắt",
/// as on the reference; "Xác nhận" saves an available choice.
class LanguageScreen extends StatefulWidget {
  const LanguageScreen({super.key});
  @override
  State<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends State<LanguageScreen> {
  late Language _selected = AppScope.read(context).language;
  late Future<List<Course>> _courses = _load();

  Future<List<Course>> _load() =>
      AppScope.read(context).lessons.courses()..ignore();

  @override
  Widget build(BuildContext context) => FutureBuilder<List<Course>>(
    future: _courses,
    builder: (context, snapshot) {
      final done = snapshot.connectionState == ConnectionState.done;
      final courses = done && !snapshot.hasError ? snapshot.data : null;
      return _page(
        courses,
        list: !done
            ? const LoadingView()
            : snapshot.hasError
            ? ErrorView(
                onRetry: () => setState(() {
                  _courses = _load();
                }),
              )
            : courses!.isEmpty
            ? const EmptyView(
                title: 'Chưa có khoá học',
                subtitle: 'Hãy quay lại sau.',
              )
            : null,
      );
    },
  );

  /// The page around [courses], or around [list] while they load or fail.
  Widget _page(List<Course>? courses, {Widget? list}) {
    final s = AppScope.of(context);
    final ready = list == null;
    final soon =
        ready && !courses!.any((c) => c.language == _selected && c.available);
    return SettingsPage(
      title: 'Ngôn ngữ học',
      padding: const EdgeInsets.fromLTRB(24, 133, 24, 215),
      footer: !ready
          ? null
          : Padding(
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
                          onTap: () {
                            if (_selected != s.language) {
                              s.setLanguage(_selected);
                            }
                            Navigator.pop(context);
                          },
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
          ?list,
          for (final course in courses ?? const <Course>[])
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _LanguageCard(
                course: course,
                selected: _selected == course.language,
                onTap: () => setState(() => _selected = course.language),
              ),
            ),
        ],
      ),
    );
  }
}

class _LanguageCard extends StatelessWidget {
  final Course course;
  final bool selected;
  final VoidCallback onTap;
  const _LanguageCard({
    required this.course,
    required this.selected,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    final language = course.language;
    final english = language == Language.english;
    final (flag, size) = languageFlag(language);
    return SelectCard(
      key: ValueKey('language-${language.title}'),
      selected: selected,
      height: 82,
      onTap: onTap,
      child: Row(
        children: [
          SizedBox(width: english ? 20 : 21),
          CustomPaint(size: size, painter: flag),
          SizedBox(width: english ? 22 : 18),
          Expanded(
            child: _LanguageText(
              name: language.title,
              native: language.nativeTitle,
              soon: !course.available,
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
