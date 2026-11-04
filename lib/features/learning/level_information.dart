import 'package:flutter/material.dart';

import '../../core/design/design.dart';
import '../../state/state.dart';

const levels = [
  'A1 - Beginner',
  'A2 - Elementary',
  'B1 - Intermediate',
  'B2 - Upper Intermediate',
  'C1 - Advanced',
  'C2 - Proficient',
];
const levelDescriptions = [
  'Có thể viết lại và hoàn thành các câu rất ngắn với từ vựng quen thuộc. Phù hợp để luyện mẫu câu cơ bản và diễn đạt ý đơn giản.',
  'Có thể viết và chỉnh sửa các câu đơn giản về chủ đề quen thuộc. Bắt đầu nối ý ngắn thành đoạn và giảm lỗi ngữ pháp cơ bản.',
  'Có thể viết đoạn văn rõ ý về chủ đề quen thuộc, diễn đạt trải nghiệm, kế hoạch và quan điểm ngắn. Phù hợp để luyện mở rộng câu và liên kết ý.',
  'Có thể viết câu và đoạn văn khá tự nhiên, có cấu trúc rõ ràng, diễn đạt quan điểm và lập luận chi tiết hơn. Phù hợp để luyện paraphrase và kiểm soát ngữ pháp tốt hơn.',
  'Có thể viết mạch lạc, linh hoạt theo nhiều mục đích học thuật, công việc và cá nhân. Có thể chọn từ ngữ và cấu trúc câu phù hợp với ngữ cảnh.',
  'Có thể viết chính xác, tinh tế và tự nhiên gần như người thành thạo. Có thể diễn đạt ý phức tạp rõ ràng và kiểm soát sắc thái ngôn ngữ tốt.',
];

/// Bar colour for each level on the information sheet, sampled on the iPhone.
const levelColors = [
  Palette.levelGreen,
  Palette.levelLime,
  Palette.levelAmber,
  Palette.categorySelected,
  Palette.levelRed,
  Palette.levelDeepRed,
];

/// Opens the CEFR sheet: a floating sheet inset 9 pt that opens at half
/// height and drags up to nearly full (physical iPhone, 3 November 2026).
Future<void> showLevelInformation(BuildContext context) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: false,
      backgroundColor: Colors.transparent,
      barrierColor: Palette.sheetBarrier,
      elevation: 0,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: .53,
        minChildSize: .3,
        maxChildSize: .93,
        snap: true,
        snapSizes: const [.53],
        expand: false,
        builder: (ctx, scroll) => Padding(
          padding: EdgeInsets.fromLTRB(
            9,
            0,
            9,
            MediaQuery.paddingOf(ctx).bottom > 0 ? 9 : 0,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(38),
            child: ColoredBox(
              color: D.background,
              child: LevelInformation(controller: scroll),
            ),
          ),
        ),
      ),
    );

class LevelInformation extends StatelessWidget {
  final ScrollController? controller;
  const LevelInformation({super.key, this.controller});
  @override
  Widget build(BuildContext context) {
    final current = AppScope.of(context).level;
    return ListView(
      controller: controller,
      padding: const EdgeInsets.fromLTRB(15, 12, 15, 24),
      children: [
        Center(
          child: Container(
            width: 36,
            height: 5,
            decoration: BoxDecoration(
              color: D.line,
              borderRadius: BorderRadius.circular(2.5),
            ),
          ),
        ),
        const SizedBox(height: 18),
        Text(
          'Thông tin cấp độ',
          textAlign: TextAlign.center,
          style: D.text(17, weight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        Text(
          'Khung tham chiếu ngôn ngữ chung châu Âu (CEFR) chia trình độ thành 6 cấp, từ người mới bắt đầu đến thành thạo.',
          textAlign: TextAlign.center,
          style: D.text(14, color: D.secondary, height: 1.38),
        ),
        const SizedBox(height: 14),
        Text(
          'Bạn có thể thay đổi cấp độ trong Cài đặt',
          textAlign: TextAlign.center,
          style: D.text(12, color: D.muted),
        ),
        const SizedBox(height: 18),
        for (var i = 0; i < levels.length; i++) ...[
          if (i > 0 && levels[i - 1].substring(0, 2) != current)
            const Padding(
              padding: EdgeInsets.only(left: 20),
              child: Divider(height: 1, thickness: .5, color: D.line),
            ),
          _LevelRow(
            title: levels[i],
            description: levelDescriptions[i],
            color: levelColors[i],
            current: levels[i].startsWith(current),
          ),
        ],
      ],
    );
  }
}

class _LevelRow extends StatelessWidget {
  final String title, description;
  final Color color;
  final bool current;
  const _LevelRow({
    required this.title,
    required this.description,
    required this.color,
    required this.current,
  });
  @override
  Widget build(BuildContext context) => Container(
    color: current ? Palette.levelCurrent : null,
    child: IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // The bar stops 8 pt short of the row's top and bottom.
          Container(
            width: 4,
            margin: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 20, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(title, style: D.text(16, weight: FontWeight.w700)),
                      if (current) ...[
                        const SizedBox(width: 9),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Palette.levelGreen,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Hiện tại',
                            style: D.text(
                              9,
                              weight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: D.text(13, color: D.secondary, height: 1.43),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
