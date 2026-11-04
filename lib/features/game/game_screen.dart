import 'dart:async';
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/design/design.dart';
import '../../core/models.dart';
import '../../core/state.dart';
import '../../widgets/common.dart';
import '../../widgets/confetti_painter.dart';
import 'game_glass_button.dart';

class GameScreen extends StatefulWidget {
  final List<FlashWord> words;
  final String title;
  final bool resume;
  final int startIndex, startScore;

  /// Starts with the screen turned, as chosen on the game home.
  final bool landscape;
  const GameScreen({
    super.key,
    required this.words,
    required this.title,
    this.resume = false,
    this.startIndex = 0,
    this.startScore = 0,
    this.landscape = false,
  });
  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen>
    with SingleTickerProviderStateMixin {
  late int index = widget.startIndex, score = widget.startScore;
  late List<(int, String)> letters;
  late final AnimationController celebration = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  );
  Timer? advanceTimer;
  bool solved = false, done = false, allowExit = false, hint = false;

  /// Words solved, the current and best run of solves, and hints used. The
  /// level rises with each solve but not with a skip, and its colour follows
  /// (reference, 3 November 2026: ten skips stayed on LEVEL 1).
  int solvedCount = 0, combo = 0, bestCombo = 0, hints = 0, attempted = 0;
  int get level => solvedCount + 1;

  /// The cue reads "Sắp xếp các chữ cái" until the first drag (survey 35/36).
  bool moved = false;
  late bool landscape = widget.landscape;
  FlashWord get word => widget.words[index];
  @override
  void initState() {
    super.initState();
    if (widget.words.isEmpty) {
      done = true;
      letters = [];
    } else {
      prepare();
    }
  }

  void prepare() {
    final chars = word.word
        .toUpperCase()
        .replaceAll(RegExp('[^A-Z]'), '')
        .split('');
    letters = List.generate(chars.length, (i) => (i, chars[i]));
    if (letters.length > 1) {
      final first = letters.removeAt(0);
      letters.add(first);
    }
    solved = false;
    hint = false;
  }

  @override
  void dispose() {
    advanceTimer?.cancel();
    celebration.dispose();
    unawaited(
      SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]),
    );
    super.dispose();
  }

  Future<void> exit() async {
    final text = widget.resume
        ? 'Bạn có thể tiếp tục từ trang Flow Letter.'
        : 'Tiến độ chơi hiện tại sẽ bị mất.';
    if (await confirm(context, 'Thoát game?', text, cancel: 'Huỷ')) {
      if (!mounted) return;
      setState(() => allowExit = true);
      await Future<void>.delayed(Duration.zero);
      if (mounted) Navigator.pop(context);
    }
  }

  void persist() {
    if (!widget.resume) return;
    final s = AppScope.read(context);
    s.saveGameProgress({
      'words': widget.words.map((w) => w.toJson()).toList(),
      'title': widget.title,
      'index': index,
      'score': score,
    });
  }

  void next({bool skipped = false}) {
    if (done) return;
    attempted++;
    if (skipped) combo = 0;
    if (index + 1 >= widget.words.length) {
      final s = AppScope.read(context);
      s.finishGame(score, clearResume: widget.resume);
      setState(() => done = true);
    } else {
      setState(() {
        index++;
        prepare();
      });
      persist();
    }
  }

  void reorder(int oldIndex, int newIndex) {
    if (solved) return;
    setState(() {
      moved = true;
      final item = letters.removeAt(oldIndex);
      letters.insert(newIndex, item);
    });
    AppScope.read(context).feedback.tap();
    if (letters.map((e) => e.$2).join() ==
        word.word.toUpperCase().replaceAll(RegExp('[^A-Z]'), '')) {
      setState(() {
        solved = true;
        score += 10;
        solvedCount++;
        combo++;
        bestCombo = max(bestCombo, combo);
      });
      AppScope.read(context).feedback.success();
      celebration.forward(from: 0);
      // The word holds about 1.07 s, then the next word's colour fades in over
      // about 0.3 s (recording 04, frame by frame).
      advanceTimer = Timer(const Duration(milliseconds: 1100), () {
        if (mounted) next();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (done) return _finished(context);
    final isLandscape =
        MediaQuery.sizeOf(context).width > MediaQuery.sizeOf(context).height;
    final width = MediaQuery.sizeOf(context).width;
    // Round 44 pt tiles in portrait; in landscape 58 pt rounded squares
    // 72 pt apart (survey 41).
    final tile = isLandscape
        ? min(58.0, (width - 140) / letters.length - 14)
        : min(44.0, (width - 40) / letters.length - 9);
    // Buttons share the width in portrait and are 100 pt each in landscape.
    Widget gameButton(String label, IconData icon, VoidCallback? onTap) =>
        Flexible(
          fit: isLandscape ? FlexFit.loose : FlexFit.tight,
          child: SizedBox(
            width: isLandscape ? 100 : null,
            child: Semantics(
              button: true,
              enabled: onTap != null,
              child: GestureDetector(
                onTap: onTap,
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .32),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: .35),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(icon, size: 16, color: Colors.white),
                      const SizedBox(width: 5),
                      Text(
                        label,
                        style: D.text(
                          13,
                          weight: FontWeight.w600,
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
    // Laid out from survey 35 (iPhone, portrait).
    final content = Column(
      children: [
        // The puzzle fades back while a solved word shows; the meaning stays
        // bright (survey 39).
        Expanded(
          child: AnimatedOpacity(
            opacity: solved ? .18 : 1,
            duration: const Duration(milliseconds: 100),
            child: Column(
              children: [
                SizedBox(
                  height: context.grow(44),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'LEVEL $level',
                            style: D.text(
                              15,
                              color: Colors.white.withValues(alpha: .85),
                              weight: FontWeight.w800,
                              spacing: 2.5,
                            ),
                          ),
                          Text(
                            widget.title,
                            style: D.text(
                              12,
                              color: Colors.white.withValues(alpha: .7),
                            ),
                          ),
                        ],
                      ),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: GameGlassButton(
                          icon: Icons.chevron_left_rounded,
                          label: 'Thoát game',
                          // Round in a session from the game's home, square
                          // in one from a deck (survey 35, reference resume).
                          square: !widget.resume,
                          onTap: exit,
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Container(
                          width: 44,
                          height: 44,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: .18),
                            borderRadius: BorderRadius.circular(
                              widget.resume ? 22 : 14,
                            ),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: .3),
                            ),
                          ),
                          child: Text(
                            '${index + 1}/${widget.words.length}',
                            style: D.text(
                              11,
                              weight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // The score pill of a session from the game's home.
                if (widget.resume) ...[
                  const SizedBox(height: 8),
                  Container(
                    height: 32,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .3),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: .35),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          size: 16,
                          color: Palette.gameTrophy,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '$score',
                          style: D.text(
                            13,
                            weight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                SizedBox(height: isLandscape ? 6 : 18),
                Text(
                  letters.map((e) => e.$2).join(' '),
                  textAlign: TextAlign.center,
                  style: D.text(
                    isLandscape ? 22 : 24,
                    color: Colors.white.withValues(alpha: .85),
                    weight: FontWeight.w800,
                    spacing: 4,
                  ),
                ),
                const Spacer(flex: 3),
                SizedBox(
                  height: isLandscape ? 58 : 46,
                  child: Center(
                    child: ReorderableListView(
                      scrollDirection: Axis.horizontal,
                      shrinkWrap: true,
                      buildDefaultDragHandles: false,
                      onReorderItem: reorder,
                      proxyDecorator: (child, _, animation) => Material(
                        color: Colors.transparent,
                        child: Transform.scale(scale: 1.08, child: child),
                      ),
                      children: [
                        for (var i = 0; i < letters.length; i++)
                          ReorderableDelayedDragStartListener(
                            key: ValueKey('letter-${letters[i].$1}'),
                            index: i,
                            child: Container(
                              width: tile,
                              margin: EdgeInsets.symmetric(
                                horizontal: isLandscape ? 7 : 4.5,
                              ),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: hint && i == 0
                                    ? D.lime.withValues(alpha: .6)
                                    : Colors.white.withValues(alpha: .12),
                                borderRadius: BorderRadius.circular(
                                  isLandscape ? 13 : tile / 2,
                                ),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: .35),
                                ),
                              ),
                              child: Text(
                                letters[i].$2,
                                style: D.text(
                                  isLandscape ? 27 : 21,
                                  weight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                // The letters sit below the middle (survey 35).
                if (isLandscape)
                  const SizedBox(height: 46)
                else
                  const Spacer(flex: 2),
                // One tick per word; the current one is taller and brighter. The
                // ruler and the cue are not shown in landscape (survey 41).
                if (!isLandscape)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (var i = 0; i < widget.words.length; i++)
                        Container(
                          width: i == index ? 3 : 2,
                          height: i == index ? 15 : 9,
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(
                              alpha: i == index ? 1 : .45,
                            ),
                            borderRadius: BorderRadius.circular(1.5),
                          ),
                        ),
                    ],
                  ),
                if (!isLandscape) ...[
                  const SizedBox(height: 22),
                  Text(
                    moved
                        ? '← Vuốt ngang để xem các chữ →'
                        : 'Sắp xếp các chữ cái',
                    style: D.text(
                      13,
                      color: Colors.white.withValues(alpha: .5),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    gameButton(
                      'Gợi ý',
                      CupertinoIcons.lightbulb_fill,
                      solved
                          ? null
                          : () {
                              setState(() {
                                hint = true;
                                hints++;
                              });
                              toast(
                                context,
                                'Chữ đầu tiên: ${word.word[0].toUpperCase()}',
                              );
                            },
                    ),
                    const SizedBox(width: 11),
                    gameButton('Xoay', Icons.crop_rotate_rounded, () {
                      landscape = !landscape;
                      SystemChrome.setPreferredOrientations(
                        landscape
                            ? [DeviceOrientation.landscapeLeft]
                            : [DeviceOrientation.portraitUp],
                      );
                    }),
                    const SizedBox(width: 11),
                    gameButton(
                      'Bỏ qua',
                      CupertinoIcons.arrow_right,
                      solved ? null : () => next(skipped: true),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: isLandscape ? 16 : 22),
        Text(
          word.meaning,
          textAlign: TextAlign.center,
          maxLines: isLandscape ? 1 : 2,
          overflow: TextOverflow.ellipsis,
          style: D.text(
            isLandscape ? 16 : 19,
            color: Colors.white,
            weight: FontWeight.w700,
          ),
        ),
        SizedBox(height: isLandscape ? 34 : 70),
      ],
    );
    return PopScope(
      canPop: allowExit,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) exit();
      },
      child: Scaffold(
        // Each word has its own colour: green, purple, then teal-green
        // (survey 35, 40, 47), repeating.
        body: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: Palette.gameWords[(level - 1) % Palette.gameWords.length],
            ),
          ),
          child: SafeArea(
            child: Stack(
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    isLandscape ? 40 : 20,
                    10,
                    isLandscape ? 40 : 20,
                    0,
                  ),
                  child: content,
                ),
                if (solved)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          AnimatedBuilder(
                            animation: celebration,
                            builder: (_, _) => CustomPaint(
                              painter: ConfettiPainter(celebration.value),
                              size: Size.infinite,
                            ),
                          ),
                          Text(
                            word.word,
                            style: D
                                .text(
                                  46,
                                  weight: FontWeight.w800,
                                  color: Colors.white,
                                )
                                .copyWith(
                                  shadows: [
                                    Shadow(
                                      color: Colors.white.withValues(alpha: .7),
                                      blurRadius: 24,
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
          ),
        ),
      ),
    );
  }

  /// The end of a session (reference, 3 November 2026): the header stays,
  /// a trophy in a frosted 110 pt circle, "Hoàn thành!", four frosted stat
  /// cards, the level's XP bar and "Về trang chủ", on the purple gradient.
  Widget _finished(BuildContext context) {
    final state = AppScope.of(context);
    final accuracy = attempted == 0
        ? 0
        : (solvedCount * 100 / attempted).round();
    Widget glass({
      required Widget child,
      double radius = 18,
      EdgeInsets? padding,
    }) => Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .3),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: Colors.white.withValues(alpha: .35)),
      ),
      child: child,
    );
    Widget stat(String label, String value) => Expanded(
      child: glass(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Column(
          children: [
            Text(
              label,
              style: D.text(12, color: Colors.white.withValues(alpha: .75)),
            ),
            const SizedBox(height: 1),
            Text(
              value,
              style: D.text(16, weight: FontWeight.w800, color: Colors.white),
            ),
          ],
        ),
      ),
    );
    final xp = state.totalXp % 500;
    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: Palette.gameWords[1],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 10, 24, 0),
            child: Column(
              children: [
                SizedBox(
                  height: context.grow(44),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'LEVEL $level',
                            style: D.text(
                              15,
                              color: Colors.white.withValues(alpha: .85),
                              weight: FontWeight.w800,
                              spacing: 2.5,
                            ),
                          ),
                          Text(
                            widget.title,
                            style: D.text(
                              12,
                              color: Colors.white.withValues(alpha: .7),
                            ),
                          ),
                        ],
                      ),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: GameGlassButton(
                          icon: Icons.chevron_left_rounded,
                          label: 'Quay lại',
                          onTap: () => Navigator.pop(context),
                        ),
                      ),
                      // The counter steps past the end as on the reference,
                      // which read 21/20 after a 20-word session.
                      Align(
                        alignment: Alignment.centerRight,
                        child: Container(
                          width: 44,
                          height: 44,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: .3),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withValues(alpha: .35),
                            ),
                          ),
                          child: Text(
                            '${widget.words.length + 1}/${widget.words.length}',
                            style: D.text(
                              11,
                              weight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 128),
                Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .22),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: .4),
                    ),
                  ),
                  child: const Icon(
                    Icons.emoji_events_rounded,
                    size: 76,
                    color: Palette.gameTrophy,
                  ),
                ),
                const SizedBox(height: 22),
                Text(
                  'Hoàn thành!',
                  style: D.text(
                    32,
                    weight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    stat('Điểm', '$score'),
                    const SizedBox(width: 12),
                    stat('Accuracy', '$accuracy%'),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    stat('Combo', 'x$bestCombo'),
                    const SizedBox(width: 12),
                    stat('Hint', '$hints'),
                  ],
                ),
                const SizedBox(height: 20),
                glass(
                  radius: 16,
                  padding: const EdgeInsets.fromLTRB(14, 10, 14, 9),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Level ${1 + state.totalXp ~/ 500}',
                              style: D.text(
                                14,
                                weight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          Text(
                            '$xp/500 XP',
                            style: D.text(
                              12,
                              color: Colors.white.withValues(alpha: .7),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: LinearProgressIndicator(
                          value: xp / 500,
                          minHeight: 4,
                          backgroundColor: Colors.white.withValues(alpha: .12),
                          valueColor: const AlwaysStoppedAnimation(
                            Palette.gameTrophy,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 19),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: glass(
                    radius: 27.5,
                    child: SizedBox(
                      width: 183,
                      height: 55,
                      child: Center(
                        child: Text(
                          'Về trang chủ',
                          style: D.text(
                            18,
                            weight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
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
