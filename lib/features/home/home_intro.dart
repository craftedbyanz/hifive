import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../core/design.dart';
import '../../core/state.dart';
import '../../widgets/common.dart';
import '../../widgets/plus_banner.dart';
import '../information/information.dart';
import '../learning/learning.dart';
import 'home_painters.dart';

class HomeIntro extends StatelessWidget {
  final Animation<double> ambient;
  const HomeIntro({super.key, required this.ambient});
  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final hour = state.now().hour;
    final greeting = hour < 5 || hour >= 22
        ? 'Chúc ngủ ngon,'
        : hour < 12
        ? 'Chào buổi sáng,'
        : hour < 18
        ? 'Chào buổi chiều,'
        : 'Chào buổi tối,';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(greeting, style: HomeDesign.greeting),
          Text(state.name, style: HomeDesign.name),
          const SizedBox(height: 18),
          Text('Bạn chưa biết học gì hôm nay?', style: HomeDesign.body),
          const SizedBox(height: 4),
          GestureDetector(
            onTap: () => go<void>(context, const GeneratorScreen()),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  children: [
                    Positioned(
                      left: 0,
                      bottom: 0,
                      width: 70,
                      height: 6,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Palette.aiUnderline,
                          borderRadius: BorderRadius.circular(1),
                        ),
                      ),
                    ),
                    Text('Tạo bài học với AI', style: HomeDesign.aiLink),
                  ],
                ),
                const SizedBox(width: 12),
                AiOrb(size: 30, animation: ambient),
              ],
            ),
          ),
          const SizedBox(height: 39),
          PlusBanner(onTap: () => go<void>(context, const PlusScreen())),
          const SizedBox(height: 23),
          Text('Chế độ học tập', style: HomeDesign.section),
          const SizedBox(height: 3),
          Text(
            'Nâng cao kỹ năng viết, ngữ pháp và giao tiếp cùng AI.',
            style: HomeDesign.body,
          ),
        ],
      ),
    );
  }
}
