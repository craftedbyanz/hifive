part of 'today_screen.dart';

/// The question area of one exercise.
class _Exercise extends StatelessWidget {
  final ExerciseKind kind;
  final FlashWord word;
  final List<String> choices;
  final TextEditingController input;
  final FocusNode focus;
  final int hints;
  final Answer? answer;
  final String? picked;
  final bool revealed;
  final VoidCallback onSpeak, onReveal, onSubmit;
  final ValueChanged<String> onChoose;
  const _Exercise({
    super.key,
    required this.kind,
    required this.word,
    required this.choices,
    required this.input,
    required this.focus,
    required this.hints,
    required this.answer,
    required this.picked,
    required this.revealed,
    required this.onSpeak,
    required this.onChoose,
    required this.onReveal,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final prompt = switch (kind) {
      ExerciseKind.intro => t.exIntro,
      ExerciseKind.choice => t.exChoose,
      ExerciseKind.typing => t.exType,
      ExerciseKind.listening => t.exListen,
      ExerciseKind.cloze => t.exCloze,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          prompt,
          key: ValueKey('ex-kind-${kind.name}'),
          style: D.text(13, weight: FontWeight.w700, color: D.secondary),
        ),
        const SizedBox(height: 14),
        Surface(
          radius: 24,
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
          child: switch (kind) {
            ExerciseKind.intro => _Intro(
              word: word,
              revealed: revealed,
              onSpeak: onSpeak,
              onReveal: onReveal,
            ),
            ExerciseKind.choice => _WordHead(word: word, onSpeak: onSpeak),
            ExerciseKind.typing => _Meaning(word: word),
            ExerciseKind.listening => Center(
              child: PressFade(
                key: const ValueKey('ex-play'),
                onTap: onSpeak,
                child: Container(
                  width: 84,
                  height: 84,
                  decoration: const BoxDecoration(
                    color: Palette.menuFocus,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    CupertinoIcons.speaker_2_fill,
                    size: 34,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            ExerciseKind.cloze => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  clozeOf(word) ?? '',
                  style: D.system(21, weight: FontWeight.w500, height: 1.4),
                ),
                const SizedBox(height: 10),
                Text(word.meaning, style: D.text(13, color: D.secondary)),
              ],
            ),
          },
        ),
        const SizedBox(height: 16),
        if (kind == ExerciseKind.choice)
          for (final c in choices)
            _Choice(
              text: c,
              state: answer == null
                  ? null
                  : c == word.meaning
                  ? Answer.correct
                  : c == picked
                  ? Answer.wrong
                  : null,
              onTap: () => onChoose(c),
            )
        else if (kind != ExerciseKind.intro) ...[
          TextField(
            key: const ValueKey('ex-input'),
            controller: input,
            focusNode: focus,
            autofocus: true,
            enabled: answer == null,
            autocorrect: false,
            enableSuggestions: false,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => onSubmit(),
            style: D.text(20, weight: FontWeight.w700),
            decoration: InputDecoration(
              hintText: hints > 0
                  ? hintFor(word.word, hints - 1)
                  : t.exAnswerHint,
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: const BorderSide(color: D.line),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _WordHead extends StatelessWidget {
  final FlashWord word;
  final VoidCallback onSpeak;
  const _WordHead({required this.word, required this.onSpeak});

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              word.word,
              style: D.text(32, weight: FontWeight.w800, spacing: -.6),
            ),
            if (word.phonetic.isNotEmpty)
              Text(word.phonetic, style: D.text(14, color: D.secondary)),
          ],
        ),
      ),
      PressFade(
        key: const ValueKey('ex-speak'),
        onTap: onSpeak,
        child: const Icon(
          CupertinoIcons.speaker_2_fill,
          size: 26,
          color: Palette.menuFocus,
        ),
      ),
    ],
  );
}

class _Meaning extends StatelessWidget {
  final FlashWord word;
  const _Meaning({required this.word});

  @override
  Widget build(BuildContext context) => Text(
    word.meaning,
    style: D.text(20, weight: FontWeight.w700, height: 1.35),
  );
}

class _Intro extends StatelessWidget {
  final FlashWord word;
  final bool revealed;
  final VoidCallback onSpeak, onReveal;
  const _Intro({
    required this.word,
    required this.revealed,
    required this.onSpeak,
    required this.onReveal,
  });

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _WordHead(word: word, onSpeak: onSpeak),
      if (word.example.isNotEmpty) ...[
        const SizedBox(height: 14),
        Text(
          word.example,
          style: D.system(16, color: D.secondary, height: 1.4),
        ),
      ],
      const SizedBox(height: 18),
      if (revealed)
        Text(
          word.meaning,
          key: const ValueKey('ex-meaning'),
          style: D.text(18, weight: FontWeight.w700, color: Palette.menuFocus),
        )
      else
        PressFade(
          key: const ValueKey('ex-reveal'),
          onTap: onReveal,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 13),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: D.background,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: D.line),
            ),
            child: Text(
              context.t.exShowMeaning,
              style: D.text(15, weight: FontWeight.w700),
            ),
          ),
        ),
    ],
  );
}

class _Choice extends StatelessWidget {
  final String text;
  final Answer? state;
  final VoidCallback onTap;
  const _Choice({required this.text, required this.state, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final (fill, edge) = switch (state) {
      Answer.correct => (Palette.correctFill, D.green),
      Answer.wrong => (Palette.wrongFill, Palette.wrong),
      _ => (Colors.white, D.line),
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: PressFade(
        key: ValueKey('ex-choice-$text'),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: fill,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: edge, width: state == null ? 1 : 1.6),
          ),
          child: Text(text, style: D.text(15, weight: FontWeight.w600)),
        ),
      ),
    );
  }
}

/// The actions under an exercise: hint, "Không biết" and "Kiểm tra" while
/// answering; the verdict with "Tiếp" (and "Quá dễ") after; the four
/// self-ratings for a new word.
class _BottomBar extends StatelessWidget {
  final ExerciseKind kind;
  final FlashWord word;
  final Answer? answer;
  final bool revealed;
  final List<Duration> intervals;
  final int hintsUsed;
  final VoidCallback onHint, onDontKnow, onCheck;
  final ValueChanged<int> onRate;
  const _BottomBar({
    required this.kind,
    required this.word,
    required this.answer,
    required this.revealed,
    required this.intervals,
    required this.hintsUsed,
    required this.onHint,
    required this.onDontKnow,
    required this.onCheck,
    required this.onRate,
  });

  String _span(Duration d) => d.inDays > 0 ? '${d.inDays}d' : '${d.inMinutes}m';

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final Widget child;
    if (kind == ExerciseKind.intro) {
      if (!revealed) return const SizedBox(height: 16);
      final labels = [t.rateAgain, t.rateHardCard, t.rateGood, t.rateEasyCard];
      child = Row(
        children: [
          for (var i = 0; i < 4; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            Expanded(
              child: _Pill(
                id: 'ex-rate-$i',
                label: labels[i],
                sub: _span(intervals[i]),
                primary: i == 2,
                onTap: () => onRate(i),
              ),
            ),
          ],
        ],
      );
    } else if (answer == null) {
      child = Row(
        children: [
          if (kind != ExerciseKind.choice) ...[
            Expanded(
              child: _Pill(id: 'ex-hint', label: t.exHint, onTap: onHint),
            ),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: _Pill(
              id: 'ex-dont-know',
              label: t.exDontKnow,
              onTap: onDontKnow,
            ),
          ),
          if (kind != ExerciseKind.choice) ...[
            const SizedBox(width: 8),
            Expanded(
              flex: 2,
              child: _Pill(
                id: 'ex-check',
                label: t.exCheck,
                primary: true,
                onTap: onCheck,
              ),
            ),
          ],
        ],
      );
    } else {
      final verdict = answer!;
      final rating = ratingFor(verdict, hints: hintsUsed);
      final (text, color) = switch (verdict) {
        Answer.correct => (t.exCorrect, D.green),
        Answer.almost => (t.exAlmost, Palette.menuPlus),
        Answer.wrong => (t.exWrong, Palette.wrong),
      };
      child = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            text,
            key: ValueKey('ex-verdict-${verdict.name}'),
            style: D.text(16, weight: FontWeight.w800, color: color),
          ),
          if (verdict != Answer.correct) ...[
            const SizedBox(height: 4),
            Text(
              '${word.word} · ${word.meaning}',
              style: D.text(14, weight: FontWeight.w600),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              if (rating == 2) ...[
                Expanded(
                  child: _Pill(
                    id: 'ex-too-easy',
                    label: t.exTooEasy,
                    onTap: () => onRate(3),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                flex: 2,
                child: _Pill(
                  id: 'ex-next',
                  label: t.exNext,
                  primary: true,
                  onTap: () => onRate(rating),
                ),
              ),
            ],
          ),
        ],
      );
    }
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: D.line)),
      ),
      child: child,
    );
  }
}

class _Pill extends StatelessWidget {
  final String id, label;
  final String? sub;
  final bool primary;
  final VoidCallback onTap;
  const _Pill({
    required this.id,
    required this.label,
    required this.onTap,
    this.sub,
    this.primary = false,
  });

  @override
  Widget build(BuildContext context) => PressFade(
    key: ValueKey(id),
    onTap: onTap,
    child: Container(
      height: sub == null ? 50 : 58,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: primary ? Palette.menuFocus : D.background,
        borderRadius: BorderRadius.circular(16),
        border: primary ? null : Border.all(color: D.line),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: D.text(
              14.5,
              weight: FontWeight.w700,
              color: primary ? Colors.white : D.ink,
            ),
          ),
          if (sub case final s?)
            Text(
              s,
              style: D.text(
                11,
                weight: FontWeight.w600,
                color: primary ? Colors.white.withValues(alpha: .85) : D.muted,
              ),
            ),
        ],
      ),
    ),
  );
}

class _AllDone extends StatelessWidget {
  final VoidCallback onClose;
  const _AllDone({required this.onClose});

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return AppPage(
      title: t.todayTitle,
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              CupertinoIcons.checkmark_seal_fill,
              size: 56,
              color: D.green,
            ),
            const SizedBox(height: 16),
            Text(
              t.todayAllDone,
              key: const ValueKey('today-all-done'),
              style: D.text(22, weight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              t.todayAllDoneBody,
              textAlign: TextAlign.center,
              style: D.text(14, color: D.secondary, height: 1.45),
            ),
          ],
        ),
      ),
    );
  }
}
