import 'package:flutter/material.dart';

import '../../core/design.dart';
import '../../widgets/common.dart';

/// "Hướng dẫn Cài đặt", opened from ⓘ in the conversation settings popover
/// (survey 87). Only the top of the reference sheet was captured; the tone
/// descriptions below "Trang trọng" are the clone's own wording.
class ConversationGuide extends StatelessWidget {
  const ConversationGuide({super.key});
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const SheetTitle('Hướng dẫn Cài đặt'),
      Text(
        'Hiểu rõ các cài đặt giúp bạn tối ưu hóa việc luyện tập hội thoại.',
        style: D.text(15, color: D.secondary, height: 1.5),
      ),
      const SizedBox(height: 26),
      const _Heading(Icons.call_split_rounded, 'CHẾ ĐỘ HỌC'),
      const _Item(
        Icons.forum_outlined,
        D.purple,
        'Trò chuyện Tự do',
        'Hội thoại mở. AI thích ứng với câu trả lời của bạn. Phù hợp cho luyện tập nâng cao.',
      ),
      const _Item(
        Icons.article_outlined,
        D.blue,
        'Chế độ Kịch bản',
        'Tuân theo kịch bản cụ thể. Phù hợp cho người mới bắt đầu cần hướng dẫn rõ ràng.',
      ),
      const SizedBox(height: 18),
      const _Heading(Icons.sentiment_satisfied_rounded, 'GIỌNG & TÍNH CÁCH'),
      const _Item(
        Icons.work_outline_rounded,
        D.blue,
        'Trang trọng',
        'Chuyên nghiệp và lịch sự. Phù hợp cho công việc và các tình huống trang trọng.',
      ),
      const _Item(
        Icons.local_cafe_outlined,
        D.orange,
        'Thoải mái',
        'Tự nhiên như trò chuyện với bạn bè, dùng nhiều cách nói đời thường.',
      ),
      const _Item(
        Icons.favorite_border_rounded,
        D.green,
        'Thân thiện',
        'Nhẹ nhàng, khích lệ và kiên nhẫn khi bạn cần thêm thời gian.',
      ),
    ],
  );
}

class _Heading extends StatelessWidget {
  final IconData icon;
  final String text;
  const _Heading(this.icon, this.text);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Row(
      children: [
        Icon(icon, size: 20),
        const SizedBox(width: 10),
        Text(text, style: D.text(14, weight: FontWeight.w700, spacing: 1)),
      ],
    ),
  );
}

class _Item extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title, body;
  const _Item(this.icon, this.color, this.title, this.body);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 18),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: color.withValues(alpha: .12),
          child: Icon(icon, color: color),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: D.text(17, weight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(body, style: D.text(14, color: D.secondary, height: 1.5)),
            ],
          ),
        ),
      ],
    ),
  );
}
