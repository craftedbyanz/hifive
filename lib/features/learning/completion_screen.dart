import 'package:flutter/material.dart';

import '../../core/design/design.dart';
import '../../domain/models/models.dart';
import '../../l10n/l10n.dart';
import '../../state/state.dart';
import '../../widgets/common.dart';
import 'result_screen.dart';

class CompletionScreen extends StatefulWidget {
  final StudySession session;
  const CompletionScreen({super.key, required this.session});
  @override
  State<CompletionScreen> createState() => _CompletionScreenState();
}

class _CompletionScreenState extends State<CompletionScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController animation = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  )..forward();
  @override
  void dispose() {
    animation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final today = s.now().weekday;
    // Laid out from survey 174 (physical iPhone): flame 78–223, the count's
    // glyph at 351, circles at 524, button at 738. The reference shows no
    // confetti here.
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              AnimatedBuilder(
                animation: animation,
                builder: (_, child) => Transform.scale(
                  scale:
                      .7 + Curves.easeOutBack.transform(animation.value) * .3,
                  child: child,
                ),
                child: const StreakFlame(size: 200),
              ),
              // Flexible, so short screens never overflow.
              const Spacer(flex: 3),
              Text(
                '${s.streak}',
                style: D.text(
                  91,
                  weight: FontWeight.w800,
                  color: Palette.streakOrange,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                context.t.daysInARow,
                style: D.text(
                  27,
                  weight: FontWeight.w700,
                  color: Palette.streakOrange,
                ),
              ),
              const SizedBox(height: 36),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 1; i <= 7; i++)
                    SizedBox(
                      width: 44,
                      child: Column(
                        children: [
                          Container(
                            width: 37.6,
                            height: 37.6,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: i == today
                                  ? Palette.streakOrange.withValues(alpha: .14)
                                  : Colors.transparent,
                              border: i == today
                                  ? null
                                  : Border.all(color: D.line, width: 1.5),
                            ),
                            child: i == today
                                ? const Center(child: StreakFlame(size: 24))
                                : null,
                          ),
                          const SizedBox(height: 6.9),
                          Text(
                            context.t.weekdaysSunFirst.split(',')[i % 7],
                            style: D.text(
                              11,
                              weight: FontWeight.w700,
                              color: i == today ? D.ink : D.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 35),
              Text(
                context.t.newStreakStarted,
                style: D.text(23, weight: FontWeight.w800),
              ),
              const SizedBox(height: 9.5),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  context.t.greatStart,
                  textAlign: TextAlign.center,
                  style: D.text(15, color: D.secondary, height: 1.33),
                ),
              ),
              const Spacer(flex: 2),
              SizedBox(
                height: 56,
                child: ActionButton(
                  context.t.continueStep,
                  onTap: () => Navigator.of(context).pushReplacement(
                    MaterialPageRoute<void>(
                      builder: (_) =>
                          ResultScreen(session: widget.session, fresh: true),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
