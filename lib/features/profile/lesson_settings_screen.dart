import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../core/design/design.dart';
import '../../domain/models/models.dart';
import '../../l10n/l10n.dart';
import '../../state/state.dart';
import '../../widgets/common.dart';
import 'settings_kit.dart';

class LessonSettingsScreen extends StatelessWidget {
  const LessonSettingsScreen({super.key});
  static const _colors = D.inputColors;
  static Color _swatch(String name) => name == 'Default'
      ? Palette.previewDefault
      : StudyMode.grammar.inputColor(name);

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    return SettingsPage(
      title: context.t.lessonSettingsTitle,
      padding: const EdgeInsets.fromLTRB(16, 121, 16, 69),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Preview(color: _swatch(s.inputColor)),
          const SizedBox(height: 32),
          _Card(
            title: context.t.inputColor,
            bottom: 9,
            child: Column(
              children: [
                for (final row in [_colors.take(4), _colors.skip(4)])
                  _SwatchRow(
                    children: [
                      for (final color in row)
                        _Swatch(
                          name: color,
                          color: _swatch(color),
                          selected: s.inputColor == color,
                          onTap: () => s.setInputColor(color),
                        ),
                    ],
                  ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _Card(
            title: context.t.hintSettings,
            child: Container(
              height: 88,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: ShapeDecoration(
                color: Palette.settingsPage,
                shape: RoundedSuperellipseBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 43,
                    height: 43,
                    decoration: const BoxDecoration(
                      color: Palette.hintDisc,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      s.showHints
                          ? CupertinoIcons.lightbulb
                          : CupertinoIcons.lightbulb_slash,
                      size: 22,
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
                          context.t.alwaysShowHints,
                          style: D.text(
                            14,
                            weight: FontWeight.w600,
                            height: 18 / 14,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          context.t.showHintsWithoutTap,
                          style: D.text(
                            12,
                            color: Palette.settingsMuted,
                            height: 15.5 / 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _HintToggle(value: s.showHints, onChanged: s.setShowHints),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          _Card(
            title: context.t.memorySettings,
            child: Column(
              children: [
                _SettingRow(
                  title: context.t.newPerDayTitle,
                  body: context.t.newPerDayBody,
                  trailing: _Stepper(
                    value: s.newPerDay,
                    onChanged: s.setNewPerDay,
                  ),
                ),
                const SizedBox(height: 10),
                _SettingRow(
                  title: context.t.exTypingSetting,
                  body: context.t.exTypingSettingBody,
                  trailing: _HintToggle(
                    id: 'setting-typing',
                    label: context.t.exTypingSetting,
                    value: s.exTyping,
                    onChanged: (v) => s.setExercises(typing: v),
                  ),
                ),
                const SizedBox(height: 10),
                _SettingRow(
                  title: context.t.exListeningSetting,
                  body: context.t.exListeningSettingBody,
                  trailing: _HintToggle(
                    id: 'setting-listening',
                    label: context.t.exListeningSetting,
                    value: s.exListening,
                    onChanged: (v) => s.setExercises(listening: v),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SwatchRow extends StatelessWidget {
  final List<Widget> children;
  const _SwatchRow({required this.children});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 3),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: children,
    ),
  );
}

class _Card extends StatelessWidget {
  final String title;
  final Widget child;
  final double bottom;
  const _Card({required this.title, required this.child, this.bottom = 16});
  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.fromLTRB(20, 20, 20, bottom),
    decoration: ShapeDecoration(
      color: Colors.white,
      shape: RoundedSuperellipseBorder(
        borderRadius: BorderRadius.circular(26),
        side: const BorderSide(color: Palette.settingsEdge),
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: D.text(14.8, weight: FontWeight.w700, height: 19 / 14.8),
        ),
        const SizedBox(height: 13),
        child,
      ],
    ),
  );
}

class _Swatch extends StatelessWidget {
  final String name;
  final Color color;
  final bool selected;
  final VoidCallback onTap;
  const _Swatch({
    required this.name,
    required this.color,
    required this.selected,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) => PressFade(
    key: ValueKey('input-color-$name'),
    onTap: onTap,
    child: SizedBox(
      width: 66,
      height: 78,
      child: Column(
        children: [
          SizedBox(
            height: 48,
            child: Center(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                width: selected ? 48 : 44,
                height: selected ? 48 : 44,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                child: selected
                    ? const Icon(
                        CupertinoIcons.checkmark_alt,
                        size: 24,
                        color: Colors.white,
                      )
                    : null,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            name,
            style: D.text(
              12,
              weight: selected ? FontWeight.w500 : FontWeight.w400,
              color: selected ? D.ink : Palette.settingsMuted,
              height: 16 / 12,
            ),
          ),
        ],
      ),
    ),
  );
}

/// The wide iOS switch of the reference, which stock Flutter switches don't
/// match: 62 × 28 with a pill-shaped knob.
class _HintToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final String id;
  final String? label;
  const _HintToggle({
    required this.value,
    required this.onChanged,
    this.id = 'hints-toggle',
    this.label,
  });
  @override
  Widget build(BuildContext context) => Semantics(
    toggled: value,
    label: label ?? context.t.alwaysShowHints,
    child: GestureDetector(
      key: ValueKey(id),
      behavior: HitTestBehavior.opaque,
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        width: 62,
        height: 28,
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: value ? Palette.inputGreen : Palette.toggleOff,
          borderRadius: BorderRadius.circular(14),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 38,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    ),
  );
}

class _Preview extends StatelessWidget {
  final Color color;
  const _Preview({required this.color});
  @override
  Widget build(BuildContext context) => Container(
    height: 320,
    padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
    decoration: ShapeDecoration(
      color: Palette.settingsPanel,
      shape: RoundedSuperellipseBorder(borderRadius: BorderRadius.circular(32)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: const Icon(
              CupertinoIcons.arrow_up_arrow_down,
              size: 19,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 8),
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 160,
          alignment: Alignment.center,
          decoration: ShapeDecoration(
            color: color,
            shape: RoundedSuperellipseBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
          child: Text(
            context.t.typeTranslation,
            style: D.text(
              17.3,
              color: Colors.white.withValues(alpha: .6),
              height: 22 / 17.3,
            ),
          ),
        ),
        const SizedBox(height: 8),
        const SizedBox(height: 36, child: _HintChips()),
      ],
    ),
  );
}

/// The hint row under the preview: words hidden behind speckle until tapped.
class _HintChips extends StatelessWidget {
  const _HintChips();
  @override
  Widget build(BuildContext context) => Row(
    children: [
      _chip(
        36,
        const Icon(Icons.undo_rounded, size: 18, color: Palette.settingsHint),
      ),
      const SizedBox(width: 8),
      _chip(79, const _Speckle(seed: 1)),
      const SizedBox(width: 6),
      _chip(75, const _Speckle(seed: 2)),
      const SizedBox(width: 6),
      Expanded(
        child: ClipRect(
          child: OverflowBox(
            alignment: Alignment.centerLeft,
            maxWidth: 79,
            child: _chip(79, const _Speckle(seed: 3)),
          ),
        ),
      ),
      const SizedBox(width: 7),
      Container(
        width: 36,
        height: 36,
        decoration: const BoxDecoration(
          color: Palette.ctaDisabled,
          shape: BoxShape.circle,
        ),
        child: const Icon(
          CupertinoIcons.chevron_forward,
          size: 15,
          color: Colors.white,
        ),
      ),
    ],
  );

  static Widget _chip(double width, Widget child) => Container(
    width: width,
    height: 36,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
    ),
    child: child,
  );
}

class _Speckle extends StatelessWidget {
  final int seed;
  const _Speckle({required this.seed});
  @override
  Widget build(BuildContext context) =>
      CustomPaint(size: const Size(56, 20), painter: _SpecklePainter(seed));
}

class _SpecklePainter extends CustomPainter {
  final int seed;
  const _SpecklePainter(this.seed);
  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(seed);
    final paint = Paint()..color = Palette.settingsMuted;
    for (var i = 0; i < 190; i++) {
      canvas.drawCircle(
        Offset(
          random.nextDouble() * size.width,
          random.nextDouble() * size.height,
        ),
        .3 + random.nextDouble() * .25,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_SpecklePainter oldDelegate) => seed != oldDelegate.seed;
}

/// A titled setting with a short explanation and a control on the right.
class _SettingRow extends StatelessWidget {
  final String title, body;
  final Widget trailing;
  const _SettingRow({
    required this.title,
    required this.body,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
    decoration: ShapeDecoration(
      color: Palette.settingsPage,
      shape: RoundedSuperellipseBorder(borderRadius: BorderRadius.circular(20)),
    ),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: D.text(14, weight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text(
                body,
                style: D.text(12, color: Palette.settingsMuted, height: 1.3),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        trailing,
      ],
    ),
  );
}

/// Minus and plus around a number, in steps of five.
class _Stepper extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;
  const _Stepper({required this.value, required this.onChanged});

  Widget _button(String id, IconData icon, int next) => PressFade(
    key: ValueKey(id),
    onTap: () => onChanged(next),
    child: Container(
      width: 30,
      height: 30,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 15, color: D.ink),
    ),
  );

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      _button(
        'new-per-day-less',
        CupertinoIcons.minus,
        (value - 5).clamp(0, 50),
      ),
      SizedBox(
        width: 34,
        child: Text(
          '$value',
          key: const ValueKey('new-per-day'),
          textAlign: TextAlign.center,
          style: D.text(16, weight: FontWeight.w800),
        ),
      ),
      _button(
        'new-per-day-more',
        CupertinoIcons.plus,
        (value + 5).clamp(0, 50),
      ),
    ],
  );
}
