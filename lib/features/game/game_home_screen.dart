import 'dart:async';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/design/design.dart';
import '../../core/state.dart';
import '../../domain/models/models.dart';
import '../../widgets/common.dart';
import 'game_glass_button.dart';
import 'game_help_screen.dart';
import 'game_screen.dart';

class GameHomeScreen extends StatefulWidget {
  const GameHomeScreen({super.key});
  @override
  State<GameHomeScreen> createState() => _GameHomeScreenState();
}

class _GameHomeScreenState extends State<GameHomeScreen> {
  /// "Xoay" at the bottom of the reference's game home (survey 106) turns the
  /// screen; games opened from here start in the same orientation.
  bool landscape = false;

  void _applyOrientation() => unawaited(
    SystemChrome.setPreferredOrientations(
      landscape
          ? [DeviceOrientation.landscapeLeft]
          : [DeviceOrientation.portraitUp],
    ),
  );

  @override
  void dispose() {
    unawaited(
      SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]),
    );
    super.dispose();
  }

  Future<void> _play(GameScreen game) async {
    await go<void>(context, game);
    // The game resets to portrait when it closes.
    if (mounted) _applyOrientation();
  }

  void _resume(AppState state) {
    final r = state.gameResume!;
    final words = (r['words'] as List)
        .map((w) => FlashWord.fromJson(Map<String, dynamic>.from(w as Map)))
        .toList();
    _play(
      GameScreen(
        words: words,
        title: r['title'] as String,
        resume: true,
        startIndex: r['index'] as int,
        startScore: r['score'] as int,
        landscape: landscape,
      ),
    );
  }

  void _choose(AppState state) => sheet<void>(
    context,
    Column(
      children: [
        const SheetTitle('Chọn bộ từ vựng'),
        for (final deck in state.decks)
          ListTile(
            leading: const Icon(Icons.style_rounded),
            title: Text(deck.title),
            subtitle: Text('${deck.words.length} từ'),
            onTap: () {
              Navigator.pop(context);
              _play(
                GameScreen(
                  words: List.of(deck.words),
                  title: deck.title,
                  resume: true,
                  landscape: landscape,
                ),
              );
            },
          ),
      ],
    ),
  );

  /// Laid out from survey 106 (iPhone): a green gradient, the title as
  /// letter tiles, a frosted level card and frosted buttons with icons.
  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final resume = state.gameResume;
    final white = Colors.white.withValues(alpha: .7);
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Palette.gameTop, Palette.gameMiddle, Palette.gameBottom],
            stops: [0, .45, 1],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
            child: Column(
              children: [
                Row(
                  children: [
                    GameGlassButton(
                      icon: CupertinoIcons.xmark,
                      label: 'Đóng',
                      onTap: () => Navigator.maybePop(context),
                    ),
                    const Spacer(),
                    GameGlassButton(
                      icon: CupertinoIcons.question,
                      label: 'Hướng dẫn Flow Letter',
                      onTap: () => go<void>(context, const GameHelpScreen()),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const _TitleTiles(),
                const SizedBox(height: 19),
                Text(
                  'Xếp chữ cái thành từ vựng',
                  style: D.text(
                    16,
                    weight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 9),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.screen_rotation_alt_rounded,
                      size: 15,
                      color: white,
                    ),
                    const SizedBox(width: 7),
                    Flexible(
                      child: Text(
                        'Trải nghiệm tốt hơn khi xoay điện thoại',
                        style: D.text(14, color: white),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _GlassPanel(
                    radius: 22,
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Level 1',
                              style: D.text(
                                15,
                                weight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              'Best ${state.bestScore}',
                              style: D.text(
                                13,
                                weight: FontWeight.w700,
                                color: Palette.gameBest,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'XP tổng: ${state.totalXp}',
                              style: D.text(12, color: white),
                            ),
                            Text('Combo x0', style: D.text(12, color: white)),
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 9),
                          child: Container(
                            height: 4,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: .1),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Lần chơi: ${state.gamesPlayed}',
                              style: D.text(12, color: white),
                            ),
                            if (state.gamesPlayed == 0)
                              Text(
                                'Bắt đầu session đầu tiên',
                                style: D.text(12, color: white),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // The resume pill; its place stays empty without one.
                SizedBox(
                  height: 40,
                  child: resume == null
                      ? null
                      : GestureDetector(
                          onTap: () => _resume(state),
                          child: _GlassPanel(
                            radius: 20,
                            padding: const EdgeInsets.symmetric(horizontal: 13),
                            child: Row(
                              children: [
                                const Icon(
                                  CupertinoIcons.arrow_clockwise,
                                  size: 15,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Tiếp tục ${resume['title']}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: D.text(
                                      13,
                                      weight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                Text(
                                  '${(resume['index'] as int) + 1}/'
                                  '${(resume['words'] as List).length}',
                                  style: D.text(
                                    12,
                                    weight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                ),
                const SizedBox(height: 50),
                _GameButton(
                  key: const ValueKey('play-flowletter'),
                  icon: CupertinoIcons.play_fill,
                  label: 'Chơi',
                  onTap: () => _choose(state),
                ),
                const SizedBox(height: 16),
                _GameButton(
                  icon: Icons.speed_rounded,
                  label: 'Độ khó',
                  onTap: () => go<void>(context, const GameDifficultyScreen()),
                ),
                const SizedBox(height: 16),
                _GameButton(
                  icon: CupertinoIcons.gear_solid,
                  label: 'Cài đặt',
                  onTap: () => go<void>(context, const GameSettingsScreen()),
                ),
                const SizedBox(height: 24),
                GestureDetector(
                  key: const ValueKey('game-home-rotate'),
                  onTap: () {
                    setState(() => landscape = !landscape);
                    _applyOrientation();
                  },
                  child: _GlassPanel(
                    radius: 22,
                    dark: true,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 11,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.crop_rotate_rounded,
                          size: 18,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 9),
                        Text(
                          'Xoay',
                          style: D.text(
                            15,
                            weight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// "FLOW / LETTER" as 53 × 52 green tiles, 58 pt apart (survey 106).
class _TitleTiles extends StatelessWidget {
  const _TitleTiles();
  @override
  Widget build(BuildContext context) {
    Widget tile(String letter) => Container(
      width: 53,
      height: 52,
      margin: const EdgeInsets.symmetric(horizontal: 2.5),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Palette.gameTileTop, Palette.gameTileBottom],
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: .28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .18),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Text(
        letter,
        style: D.text(26, weight: FontWeight.w800, color: Colors.white),
      ),
    );
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [for (final l in 'FLOW'.split('')) tile(l)],
        ),
        const SizedBox(height: 8),
        FittedBox(
          child: Row(children: [for (final l in 'LETTER'.split('')) tile(l)]),
        ),
      ],
    );
  }
}

/// A frosted panel on the game's gradient backgrounds.
class _GlassPanel extends StatelessWidget {
  final Widget child;
  final double radius;
  final EdgeInsets padding;
  final bool dark;
  const _GlassPanel({
    required this.child,
    required this.radius,
    required this.padding,
    this.dark = false,
  });
  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(radius),
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          color: (dark ? Colors.black : Colors.white).withValues(
            alpha: dark ? .18 : .12,
          ),
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(color: Colors.white.withValues(alpha: .22)),
        ),
        child: child,
      ),
    ),
  );
}

/// The 313 × 50 frosted buttons: Chơi, Độ khó, Cài đặt.
class _GameButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _GameButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    child: GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: _GlassPanel(
          radius: 25,
          padding: EdgeInsets.zero,
          child: SizedBox(
            height: 50,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 18, color: Colors.white),
                const SizedBox(width: 10),
                Text(
                  label,
                  style: D.text(
                    17,
                    weight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

/// Độ khó and Cài đặt are full pages on their own gradients (survey
/// 107/108): a square frosted back button, a white title and frosted rows
/// grouped in the middle.
class _GamePage extends StatelessWidget {
  final String title;
  final List<Color> colors;
  final List<Widget> rows;
  const _GamePage({
    required this.title,
    required this.colors,
    required this.rows,
  });
  @override
  Widget build(BuildContext context) => Scaffold(
    body: DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: colors,
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: SizedBox(
                height: 44,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Text(
                      title,
                      style: D.text(
                        20,
                        weight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: GameGlassButton(
                        icon: CupertinoIcons.back,
                        label: 'Quay lại',
                        square: true,
                        onTap: () => Navigator.maybePop(context),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Column(mainAxisSize: MainAxisSize.min, children: rows),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

Widget _gameRow({required Widget child, VoidCallback? onTap, Key? key}) =>
    Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: GestureDetector(
        key: key,
        onTap: onTap,
        child: _GlassPanel(
          radius: 25.5,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: SizedBox(height: 51, child: child),
        ),
      ),
    );

class GameDifficultyScreen extends StatelessWidget {
  const GameDifficultyScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    return _GamePage(
      title: 'Độ khó',
      colors: const [Palette.difficultyTop, Palette.difficultyBottom],
      rows: [
        for (final level in ['Dễ', 'Vừa', 'Khó'])
          _gameRow(
            key: ValueKey('difficulty-$level'),
            onTap: () => state.setDifficulty(level),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    level,
                    style: D.text(
                      17,
                      weight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
                Icon(
                  state.difficulty == level
                      ? CupertinoIcons.checkmark_circle_fill
                      : CupertinoIcons.circle,
                  size: 22,
                  color: Colors.white.withValues(
                    alpha: state.difficulty == level ? 1 : .55,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class GameSettingsScreen extends StatelessWidget {
  const GameSettingsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    Widget toggle(
      IconData icon,
      String label,
      bool value,
      ValueChanged<bool> on,
    ) => _gameRow(
      child: Row(
        children: [
          SizedBox(width: 26, child: Icon(icon, color: Colors.white)),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              label,
              style: D.text(17, weight: FontWeight.w700, color: Colors.white),
            ),
          ),
          CupertinoSwitch(
            value: value,
            activeTrackColor: D.green,
            onChanged: on,
          ),
        ],
      ),
    );
    return _GamePage(
      title: 'Cài đặt',
      colors: const [Palette.settingsTop, Palette.settingsBottom],
      rows: [
        toggle(CupertinoIcons.speaker_2_fill, 'Âm thanh', s.sound, s.setSound),
        toggle(
          CupertinoIcons.device_phone_portrait,
          'Rung phản hồi',
          s.haptic,
          s.setHaptic,
        ),
      ],
    );
  }
}
