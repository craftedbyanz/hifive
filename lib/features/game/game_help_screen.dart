import 'package:flutter/material.dart';

import '../../core/design.dart';
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
    title: 'Hướng dẫn',
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        children: [
          const SizedBox(height: 35),
          Text('F L O W', style: D.text(26, weight: FontWeight.w800)),
          const SizedBox(height: 20),
          Text(
            'Cách chơi Flow Letter',
            style: D.text(21, weight: FontWeight.w700),
          ),
          const SizedBox(height: 32),
          for (final item in [
            ('1', 'Mục tiêu', 'Sắp xếp các chữ cái thành từ vựng đúng.'),
            ('2', 'Cách di chuyển', 'Giữ và kéo một chữ cái để đổi vị trí.'),
            ('3', 'Hoàn thành', 'Đúng từ sẽ tự động chuyển sang từ tiếp theo.'),
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
                        child: const Text('Nhấn để xem'),
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
