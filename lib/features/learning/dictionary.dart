import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/design/design.dart';
import '../../l10n/l10n.dart';
import '../../state/state.dart';
import '../../widgets/common.dart';

String dictionaryMeaning(String word) =>
    {
      'sorry': 'Cảm thấy hối tiếc hoặc buồn bã; một lời xin lỗi.',
      'late': 'Muộn, trễ hơn thời gian dự kiến.',
      'today': 'Hôm nay.',
      'morning': 'Buổi sáng.',
      'beautiful': 'Đẹp, xinh đẹp.',
      'city': 'Thành phố.',
      'work': 'Công việc; làm việc.',
      'friend': 'Bạn bè.',
      'patience': 'Sự kiên nhẫn.',
      'understanding': 'Sự thấu hiểu.',
      'cable': 'Dây cáp.',
      'fresh': 'Tươi, trong lành.',
    }[word.toLowerCase()] ??
    'Từ vựng trong bài học. Xem câu tham khảo để hiểu cách dùng trong ngữ cảnh.';

/// Short glosses and IPA for the lesson dictionary (survey 146 shows
/// "late · muộn · /leɪt/"); other words fall back to [dictionaryMeaning].
const _gloss = {
  'late': ('muộn', '/leɪt/'),
  'sorry': ('xin lỗi', '/ˈsɔːri/'),
  'today': ('hôm nay', '/təˈdeɪ/'),
  'morning': ('buổi sáng', '/ˈmɔːrnɪŋ/'),
  'traffic': ('giao thông', '/ˈtræfɪk/'),
  'meeting': ('cuộc họp', '/ˈmiːtɪŋ/'),
  'work': ('công việc', '/wɜːrk/'),
  'please': ('làm ơn', '/pliːz/'),
  'excuse': ('thứ lỗi', '/ɪkˈskjuːz/'),
  'alarm': ('báo thức', '/əˈlɑːrm/'),
  'office': ('văn phòng', '/ˈɔːfɪs/'),
  'apologize': ('xin lỗi', '/əˈpɑːlədʒaɪz/'),
  'beautiful': ('đẹp', '/ˈbjuːtɪfl/'),
  'city': ('thành phố', '/ˈsɪti/'),
  'friend': ('bạn bè', '/frend/'),
};

/// Function words the reference leaves out of the lesson dictionary.
const _common = {
  'this',
  'that',
  'with',
  'from',
  'have',
  'they',
  'them',
  'there',
  'their',
  'will',
  'would',
  'about',
  'your',
  'were',
  'been',
  'what',
  'when',
  'where',
  'which',
  'into',
  'then',
  'than',
  'very',
  'just',
  'some',
  'also',
  'here',
};

/// One entry of the lesson dictionary: the word, a short meaning, its IPA
/// when known, and the numbers of the sentences that use it.
class LessonWord {
  final String word, meaning;
  final String? ipa;
  final List<int> sentences;
  const LessonWord(this.word, this.meaning, this.ipa, this.sentences);
}

/// Words of a lesson's answers, most used first, as the reference lists them.
List<LessonWord> lessonWords(List<String> answers, {int limit = 30}) {
  final seen = <String, List<int>>{};
  final spelling = <String, String>{};
  for (var i = 0; i < answers.length; i++) {
    for (final raw in answers[i].split(RegExp(r'[^A-Za-z]+'))) {
      final key = raw.toLowerCase();
      if (raw.length <= 3 || _common.contains(key)) continue;
      spelling.putIfAbsent(key, () => key);
      final list = seen.putIfAbsent(key, () => []);
      if (!list.contains(i + 1)) list.add(i + 1);
    }
  }
  final keys = seen.keys.toList()
    ..sort((a, b) => seen[b]!.length.compareTo(seen[a]!.length));
  return [
    for (final k in keys.take(limit))
      LessonWord(
        spelling[k]!,
        _gloss[k]?.$1 ?? dictionaryMeaning(k),
        _gloss[k]?.$2,
        seen[k]!,
      ),
  ];
}

Future<void> showWord(BuildContext context, String word) => showDialog(
  context: context,
  builder: (ctx) => Dialog(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(word, style: D.text(27, weight: FontWeight.w800)),
              ),
              IconButton(
                tooltip: context.t.pronounceTooltip,
                onPressed: () => playWord(context, word),
                icon: const Icon(Icons.volume_up_rounded, color: D.purple),
              ),
              IconButton(
                tooltip: context.t.saveWord,
                onPressed: () {
                  AppScope.read(context)
                      .saveWord(word, dictionaryMeaning(word));
                  Navigator.pop(ctx);
                  toast(context, context.t.savedWord(word));
                },
                icon: const Icon(Icons.add_circle_rounded, color: D.green),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const PillBadge('A1  ·  Easy', color: D.green),
          const SizedBox(height: 18),
          const Divider(),
          const SizedBox(height: 12),
          Text(dictionaryMeaning(word), style: D.text(15, height: 1.7)),
          const SizedBox(height: 12),
        ],
      ),
    ),
  ),
);
