import 'package:flutter/material.dart';

import '../../core/design/design.dart';
import '../../l10n/l10n.dart';
import '../../widgets/common.dart';

class GameHelpScreen extends StatefulWidget {
  const GameHelpScreen({super.key});
  @override
  State<GameHelpScreen> createState() => _GameHelpScreenState();
}

class _GameHelpScreenState extends State<GameHelpScreen> {
  bool demo = false;
  @override
  Widget build(BuildContext context) => AppPage(
    title: context.t.guide,
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        children: [
          const SizedBox(height: 35),
          Text('F L O W', style: D.text(26, weight: FontWeight.w800)),
          const SizedBox(height: 20),
          Text(
            context.t.gameHowToTitle,
            style: D.text(21, weight: FontWeight.w700),
          ),
          const SizedBox(height: 32),
          for (final item in [
            ('1', context.t.gameGoal, context.t.gameGoalBody),
            ('2', context.t.gameMove, context.t.gameMoveBody),
            ('3', context.t.gameDone, context.t.gameDoneBody),
          ])
            Padding(
              padding: const EdgeInsets.only(bottom: 26),
              child: Surface(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${item.$1}   ${item.$2}',
                      style: D.text(19, weight: FontWeight.w700),
                    ),
                    const SizedBox(height: 12),
                    Text(item.$3, style: D.text(13, color: D.secondary)),
                    if (item.$1 == '2') ...[
                      const SizedBox(height: 20),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 500),
                        child: Text(
                          demo ? 'C   A   T' : 'A   C   T',
                          key: ValueKey(demo),
                          style: D.text(27, weight: FontWeight.w800),
                        ),
                      ),
                      TextButton(
                        onPressed: () => setState(() => demo = !demo),
                        child: Text(context.t.tapToSee),
                      ),
                    ],
                  ],
                ),
              ),
            ),
        ],
      ),
    ),
  );
}
