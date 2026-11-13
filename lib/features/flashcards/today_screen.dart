import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../core/design/design.dart';
import '../../domain/models/models.dart';
import '../../domain/vocab/vocab.dart';
import '../../l10n/l10n.dart';
import '../../state/state.dart';
import '../../widgets/common.dart';
import 'review_complete.dart';

part 'today_exercises.dart';

/// One leg of today's review: due words lowest recall first, new words woven
/// in, each asked the way its memory calls for (`pickExercise`). A word
/// answered wrong comes back at the end of the leg.
class TodayScreen extends StatefulWidget {
  /// The words of this leg; null plans one from [AppState.today].
  final List<FlashWord>? words;
  const TodayScreen({super.key, this.words});

  @override
  State<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends State<TodayScreen> {
  late final AppState _state = AppScope.read(context);
  late final List<FlashWord> _queue = List.of(
    widget.words ?? _state.today.leg(),
  );
  late final int _total = _queue.length;
  late final int _wateredBefore = _state.countedStudyCredits.length;
  final _missed = <String>{};
  var _known = 0, _again = 0;

  // The exercise on screen.
  late ExerciseKind _kind;
  var _hints = 0;
  Answer? _answer;
  final _watch = Stopwatch();
  final _input = TextEditingController();
  final _focus = FocusNode();
  bool _revealed = false;
  String? _picked;

  FlashWord? get _word => _queue.isEmpty ? null : _queue.first;

  @override
  void initState() {
    super.initState();
    if (_queue.isNotEmpty) _prepare();
  }

  @override
  void dispose() {
    _input.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _prepare() {
    final w = _queue.first;
    _kind = _missed.contains(w.id)
        ? ExerciseKind.choice
        : pickExercise(
            w,
            _state.now(),
            typing: _state.exTyping,
            listening: _state.exListening,
          );
    _hints = 0;
    _answer = null;
    _revealed = false;
    _picked = null;
    _input.clear();
    _watch
      ..reset()
      ..start();
    if (_kind == ExerciseKind.listening) _speak();
  }

  void _speak() {
    final w = _word;
    if (w != null) _state.speak(w.word);
  }

  /// Logs the review and moves on. A wrong answer sends the word to the end
  /// of the queue, asked as a choice next time.
  void _rate(int rating) {
    final w = _queue.first;
    _state.rate(
      w,
      rating,
      mode: _kind.mode,
      skill: _kind.skill,
      source: 'today',
      ms: _watch.elapsedMilliseconds,
      hints: _hints,
    );
    setState(() {
      _queue.removeAt(0);
      if (rating == 0) {
        _again++;
        _missed.add(w.id);
        _queue.add(w);
      } else if (!_missed.contains(w.id)) {
        _known++;
      }
      if (_queue.isNotEmpty) _prepare();
    });
  }

  void _check() {
    final w = _queue.first;
    _watch.stop();
    final answer = gradeTyped(_input.text, w.word);
    if (answer == Answer.correct) _state.feedback.success();
    setState(() => _answer = answer);
  }

  void _choose(String meaning) {
    if (_answer != null) return;
    _watch.stop();
    final right = meaning == _queue.first.meaning;
    if (right) _state.feedback.success();
    setState(() {
      _picked = meaning;
      _answer = right ? Answer.correct : Answer.wrong;
    });
  }

  void _giveUp() {
    _watch.stop();
    setState(() => _answer = Answer.wrong);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final word = _word;
    if (word == null) {
      return _total == 0
          ? _AllDone(onClose: () => Navigator.of(context).pop())
          : ReviewComplete(
              key: const ValueKey('today-complete'),
              deckTitle: t.todayTitle,
              seen: _total,
              known: _known,
              again: _again,
              watered: _state.countedStudyCredits.length - _wateredBefore,
              onContinue: () => Navigator.of(context).pop(),
            );
    }
    final done = _total - _queue.where((w) => !_missed.contains(w.id)).length;
    return Scaffold(
      backgroundColor: D.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 20, 8),
              child: Row(
                children: [
                  PressFade(
                    key: const ValueKey('today-close'),
                    onTap: () => Navigator.of(context).pop(),
                    child: const Padding(
                      padding: EdgeInsets.all(8),
                      child: Icon(CupertinoIcons.xmark, size: 20, color: D.ink),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(99),
                      child: LinearProgressIndicator(
                        value: _total == 0 ? 0 : done / _total,
                        minHeight: 8,
                        color: Palette.menuFocus,
                        backgroundColor: D.line,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    t.exProgress(done, _total),
                    key: const ValueKey('today-progress'),
                    style: D.text(
                      13,
                      weight: FontWeight.w700,
                      color: D.secondary,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                child: _Exercise(
                  key: ValueKey('ex-${word.id}-${_kind.name}-$_again'),
                  kind: _kind,
                  word: word,
                  choices: _kind == ExerciseKind.choice
                      ? choicesFor(word, _state.uniqueWords.values)
                      : const [],
                  input: _input,
                  focus: _focus,
                  hints: _hints,
                  answer: _answer,
                  picked: _picked,
                  revealed: _revealed,
                  onSpeak: _speak,
                  onChoose: _choose,
                  onReveal: () => setState(() => _revealed = true),
                  onSubmit: _check,
                ),
              ),
            ),
            _BottomBar(
              kind: _kind,
              word: word,
              answer: _answer,
              revealed: _revealed,
              intervals: word.nextIntervals(_state.now()),
              onHint: () => setState(() => _hints++),
              onDontKnow: _giveUp,
              onCheck: _check,
              onRate: _rate,
              hintsUsed: _hints,
            ),
          ],
        ),
      ),
    );
  }
}
