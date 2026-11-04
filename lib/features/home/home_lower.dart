import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../core/design/design.dart';
import '../../data/content/help_content.dart';
import '../../widgets/common.dart';
import '../flashcards/flashcards.dart';
import '../game/game.dart';
import '../information/information.dart';
import '../learning/learning.dart';
import 'home_design.dart';
import 'home_mini_art.dart';

/// The lower half of Home, measured against survey screenshots 91 and 92.
class HomeLowerContent extends StatelessWidget {
  const HomeLowerContent({super.key});
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hifive đề xuất',
              style: D.text(
                20,
                weight: FontWeight.w700,
                spacing: -.4,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              'Các chủ đề được chọn lọc để giúp bạn học nhanh hơn.',
              style: HomeDesign.body,
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),
      const RecommendationRow(
        items: [
          ('Làm tôi bất ngờ', CupertinoIcons.sparkles, 149.0, 38.0),
          ('Du lịch', CupertinoIcons.airplane, 97.0, 41.0),
          ('Kinh doanh', CupertinoIcons.briefcase_fill, 126.0, 42.0),
          ('Ẩm thực', Icons.restaurant_rounded, 103.0, 40.0),
          ('Mua sắm', Icons.shopping_bag_rounded, 111.0, 40.0),
        ],
      ),
      const SizedBox(height: 12),
      const RecommendationRow(
        items: [
          ('Sức khỏe', CupertinoIcons.heart_fill, 112.0, 40.0),
          ('Xã hội', CupertinoIcons.bubble_left_bubble_right_fill, 98.0, 46.0),
          ('IELTS', Icons.school_rounded, 91.0, 44.0),
          ('Đời sống', CupertinoIcons.sun_max_fill, 109.0, 42.0),
          ('Giải trí', Icons.movie_rounded, 97.0, 40.0),
        ],
      ),
      const SizedBox(height: 23.5),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: HomeFlashcardPromo(
          onTap: () => go<void>(context, const DeckListScreen()),
        ),
      ),
      const Padding(
        padding: EdgeInsets.fromLTRB(24, 23, 24, 24),
        child: Divider(height: 1, color: Palette.homeDivider),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: HomeGamePromo(
          onTap: () => go<void>(context, const GameHomeScreen()),
        ),
      ),
      const SizedBox(height: 23),
      Padding(
        padding: const EdgeInsets.only(left: 16, right: 26),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hifive 101',
              style: D.text(
                20,
                weight: FontWeight.w700,
                spacing: -.4,
                height: 1.25,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              'Tất cả những gì bạn cần biết về Hifive và cách ứng dụng giúp bạn học tập hiệu quả.',
              style: D.text(13, color: D.secondary, height: 17 / 13),
            ),
          ],
        ),
      ),
      const SizedBox(height: 15),
      SizedBox(
        height: 191,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: helpTitles.length,
          separatorBuilder: (_, _) => const SizedBox(width: 16),
          itemBuilder: (_, i) => HomeHelpCard(index: i),
        ),
      ),
    ],
  );
}

class RecommendationRow extends StatelessWidget {
  /// Label, icon, chip width, and where the label starts inside the chip.
  final List<(String, IconData, double, double)> items;
  const RecommendationRow({super.key, required this.items});
  @override
  Widget build(BuildContext context) => SizedBox(
    height: 38,
    child: ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: items.length,
      separatorBuilder: (_, _) => const SizedBox(width: 9),
      itemBuilder: (_, i) {
        final item = items[i], special = item.$1 == 'Làm tôi bất ngờ';
        // The measured width; the label's share grows with the text size.
        final label = item.$3 - item.$4 - 14;
        return SizedBox(
          width: item.$3 + context.grow(label) - label,
          child: Material(
            color: special ? Palette.chipSpecial : Colors.white,
            borderRadius: BorderRadius.circular(24),
            child: InkWell(
              borderRadius: BorderRadius.circular(24),
              onTap: () =>
                  go<void>(context, GeneratorScreen(initialTopic: item.$1)),
              child: Row(
                children: [
                  const SizedBox(width: 14),
                  SizedBox(
                    width: item.$4 - 14 - 4,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Icon(
                        item.$2,
                        size: item.$4 > 44 ? 22 : 19,
                        color: special ? Palette.chipSpecialIcon : D.secondary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    item.$1,
                    maxLines: 1,
                    softWrap: false,
                    style: D.text(
                      13.5,
                      weight: special ? FontWeight.w700 : FontWeight.w600,
                      color: special
                          ? Palette.chipSpecialText
                          : Palette.chipInk,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    ),
  );
}

class HomeFlashcardPromo extends StatelessWidget {
  final VoidCallback onTap;
  const HomeFlashcardPromo({super.key, required this.onTap});
  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: 'Mở Flashcard',
    child: GestureDetector(
      onTap: onTap,
      child: AspectRatio(
        aspectRatio: 361 / 209,
        child: ClipRSuperellipse(
          borderRadius: BorderRadius.circular(28),
          child: FittedBox(
            fit: BoxFit.fill,
            child: SizedBox(
              width: 361,
              height: 209,
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Palette.flashcardPromoStart,
                      Palette.flashcardPromoEnd,
                    ],
                  ),
                ),
                child: Stack(
                  children: [
                    // The reference is lighter toward the top right.
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: RadialGradient(
                            center: const Alignment(.35, -.9),
                            radius: 1.1,
                            colors: [
                              Colors.white.withValues(alpha: .14),
                              Colors.white.withValues(alpha: 0),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 20,
                      top: 29,
                      width: 155,
                      child: Text(
                        'VOCABULARY\nFLASHCARD',
                        style: D.text(
                          19.2,
                          weight: FontWeight.w700,
                          color: Colors.white,
                          height: 24.5 / 19.2,
                        ),
                      ),
                    ),
                    Positioned(
                      left: 20,
                      top: 89,
                      width: 175,
                      child: Text(
                        'Lưu từ mới, ôn tập theo\nSRS và theo dõi tiến bộ mỗi\nngày.',
                        style: D.text(
                          13,
                          color: Colors.white.withValues(alpha: .86),
                          height: 15.2 / 13,
                          spacing: -.35,
                        ),
                      ),
                    ),
                    Positioned(
                      left: 20,
                      top: 148,
                      child: Container(
                        height: 31,
                        padding: const EdgeInsets.only(left: 14, right: 11),
                        decoration: BoxDecoration(
                          color: Palette.promoAccent,
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: Row(
                          children: [
                            Text(
                              'Mở Flashcard',
                              style: D.text(
                                12.1,
                                weight: FontWeight.w700,
                                color: Palette.promoInk,
                              ),
                            ),
                            const SizedBox(width: 7),
                            const Icon(
                              Icons.arrow_forward_rounded,
                              size: 16,
                              color: Palette.promoInk,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Positioned(
                      right: 19,
                      top: 23,
                      child: PromoWordCard(
                        word: 'Resilient',
                        meaning: 'Kiên cường',
                        angle: .1,
                      ),
                    ),
                    const Positioned(
                      right: 19,
                      top: 108,
                      child: PromoWordCard(
                        word: 'Acquire',
                        meaning: 'Tiếp thu',
                        angle: -.03,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class PromoWordCard extends StatelessWidget {
  final String word, meaning;
  final double angle;
  const PromoWordCard({
    super.key,
    required this.word,
    required this.meaning,
    required this.angle,
  });
  @override
  Widget build(BuildContext context) => Transform.rotate(
    angle: angle,
    child: Container(
      width: 128,
      height: 76,
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: Palette.promoCard,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(word, style: D.text(12, weight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(meaning, style: D.text(11, color: D.secondary)),
          const SizedBox(height: 3),
          Container(
            width: 55,
            height: 4,
            decoration: BoxDecoration(
              color: Palette.promoCardLine,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    ),
  );
}

class HomeGamePromo extends StatelessWidget {
  final VoidCallback onTap;
  const HomeGamePromo({super.key, required this.onTap});
  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: 'Flow Letter — Thử ngay',
    child: GestureDetector(
      onTap: onTap,
      child: AspectRatio(
        aspectRatio: 361 / 120,
        child: ClipRSuperellipse(
          borderRadius: BorderRadius.circular(24),
          child: FittedBox(
            fit: BoxFit.fill,
            child: SizedBox(
              width: 361,
              height: 120,
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment(.16, .03),
                    radius: 1.7,
                    colors: [Palette.gamePromoStart, Palette.gamePromoEnd],
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      left: 16,
                      top: 11,
                      child: Text(
                        'Flow Letter',
                        style: D.text(
                          15.2,
                          weight: FontWeight.w700,
                          color: Colors.white,
                          height: 20 / 15.2,
                        ),
                      ),
                    ),
                    Positioned(
                      left: 16,
                      top: 32,
                      child: Text(
                        'Xếp chữ cái thành từ vựng',
                        style: D.text(
                          11.15,
                          color: Colors.white.withValues(alpha: .7),
                          height: 15 / 11.15,
                        ),
                      ),
                    ),
                    Positioned(
                      right: 16,
                      top: 20,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: .2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Thử ngay',
                          style: D.text(
                            10,
                            weight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 75,
                      top: 68.5,
                      child: Row(
                        children: [
                          for (final letter in 'HELLO'.split(''))
                            Container(
                              width: 35.5,
                              height: 35.5,
                              margin: const EdgeInsets.only(right: 8.4),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: .17),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: .24),
                                ),
                              ),
                              child: Text(
                                letter,
                                style: D.text(
                                  22,
                                  weight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class HomeHelpCard extends StatelessWidget {
  final int index;
  const HomeHelpCard({super.key, required this.index});
  @override
  Widget build(BuildContext context) => SizedBox(
    width: 160,
    child: Material(
      color: Colors.white,
      clipBehavior: Clip.antiAlias,
      shape: RoundedSuperellipseBorder(borderRadius: BorderRadius.circular(24)),
      child: InkWell(
        onTap: () => go<void>(context, HelpScreen(index: index)),
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              height: 120,
              child: CustomPaint(painter: HomeMiniArtwork(index)),
            ),
            Positioned(
              left: 16,
              right: 16,
              top: 131,
              child: Text(
                // The reference breaks this title after the colon.
                helpTitles[index].replaceFirst('Game: ', 'Game:\n'),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: D.text(
                  16,
                  weight: FontWeight.w700,
                  spacing: -.55,
                  height: 19.5 / 16,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
