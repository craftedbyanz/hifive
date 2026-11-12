import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../core/design/design.dart';
import '../../domain/models/models.dart';
import '../../l10n/l10n.dart';
import '../../state/state.dart';
import '../../widgets/common.dart';
import 'chat_screen.dart';
import 'generator_screen.dart';
import 'level_information.dart';
import 'practice_screen.dart';

/// A topic's sets as a carousel, measured on the physical iPhone
/// (3 November 2026) for writing and grammar, and from survey 84/89 for
/// conversation and the loading state.
class CollectionScreen extends StatefulWidget {
  final Topic topic;
  const CollectionScreen({super.key, required this.topic});
  @override
  State<CollectionScreen> createState() => _CollectionScreenState();
}

/// Writing and grammar mark the title's period and pager in lime and ink;
/// conversation uses blue throughout.
Color _accent(StudyMode mode) =>
    mode == StudyMode.conversation ? Palette.chatBlue : Palette.grammarAccent;

class _CollectionScreenState extends State<CollectionScreen> {
  int index = 0;

  // A page is 335 of 393 pt: a 307.6 pt card and 27.4 pt between cards.
  final pages = PageController(viewportFraction: 335 / 393);

  Future<List<Lesson>> load() {
    final state = AppScope.read(context);
    return state.lessons.lessons(state.language, widget.topic);
  }

  @override
  void dispose() {
    pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context), topic = widget.topic;
    return Scaffold(
      backgroundColor: D.background,
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                height: 44,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Text(
                      context.t.lessonsTitle,
                      style: D.text(16, weight: FontWeight.w600),
                    ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: HeaderRoundButton(
                        icon: CupertinoIcons.back,
                        iconSize: 31,
                        label: context.t.back,
                        onTap: () => Navigator.maybePop(context),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 25.9, 24, 0),
              child: Column(
                children: [
                  Text(
                    context.t.collectionCaps,
                    style: D.text(
                      10,
                      weight: FontWeight.w700,
                      color: D.muted,
                      spacing: 2,
                    ),
                  ),
                  const SizedBox(height: 15.2),
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(text: topic.title),
                        TextSpan(
                          text: '.',
                          style: TextStyle(color: _accent(topic.mode)),
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: D.text(
                      28,
                      weight: FontWeight.w800,
                      height: 1.24,
                      spacing: -.5,
                    ),
                  ),
                  const SizedBox(height: 15.6),
                  Text(
                    topic.description,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: D.text(
                      13,
                      color: D.secondary,
                      weight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _LevelPill(level: state.level),
                ],
              ),
            ),
            const SizedBox(height: 29.3),
            Expanded(
              child: AsyncView<List<Lesson>>(
                load: load,
                isEmpty: (l) =>
                    l.isEmpty && topic.mode != StudyMode.conversation,
                empty: EmptyView(
                  title: context.t.noLessons,
                  subtitle: context.t.noLessonsBody,
                ),
                loading: _carousel(topic, const [], loading: true),
                builder: (context, lessons) => _carousel(topic, lessons),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _carousel(Topic topic, List<Lesson> lessons, {bool loading = false}) {
    // Every collection ends with a card that opens the AI generator.
    final count = loading ? topic.sets + 1 : lessons.length + 1;
    return Column(
      children: [
        Expanded(
          child: PageView.builder(
            controller: pages,
            physics: loading ? const NeverScrollableScrollPhysics() : null,
            itemCount: loading ? 1 : count,
            onPageChanged: (i) => setState(() => index = i),
            itemBuilder: (_, i) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 13.7),
              child: loading
                  ? const _SkeletonCard()
                  : i == lessons.length
                  ? _CreateCard(mode: topic.mode)
                  : _SetCard(topic: topic, lesson: lessons[i], index: i),
            ),
          ),
        ),
        const SizedBox(height: 46),
        _Dots(
          count: count,
          index: loading ? 0 : index,
          color: topic.mode == StudyMode.conversation
              ? Palette.chatBlue
              : D.ink,
        ),
        const SizedBox(height: 46),
      ],
    );
  }
}

/// "CẤP ĐỘ A1 ⓘ": white, hairline edge, 25 pt tall. Opens the CEFR sheet.
class _LevelPill extends StatelessWidget {
  final String level;
  const _LevelPill({required this.level});
  @override
  Widget build(BuildContext context) => PressFade(
    onTap: () => showLevelInformation(context),
    child: Container(
      height: 25,
      padding: const EdgeInsets.only(left: 12.7, right: 12.4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.5),
        border: Border.all(color: D.line),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            context.t.levelCapsLabel,
            style: D.text(10, weight: FontWeight.w700, color: D.muted),
          ),
          const SizedBox(width: 8.6),
          Text(
            level,
            style: D.text(
              10,
              weight: FontWeight.w800,
              color: Palette.levelGreen,
            ),
          ),
          const SizedBox(width: 8.3),
          const Icon(CupertinoIcons.info_circle, size: 11, color: D.muted),
        ],
      ),
    ),
  );
}

/// White card with a 32 pt corner and a hairline edge, 307.6 pt wide.
BoxDecoration _cardDecoration(Color color, {bool edge = true}) => BoxDecoration(
  color: color,
  borderRadius: BorderRadius.circular(32),
  border: edge ? Border.all(color: D.line) : null,
  boxShadow: [
    BoxShadow(
      color: D.ink.withValues(alpha: .04),
      blurRadius: 18,
      offset: const Offset(0, 6),
    ),
  ],
);

class _SetCard extends StatelessWidget {
  final Topic topic;
  final Lesson lesson;
  final int index;
  const _SetCard({
    required this.topic,
    required this.lesson,
    required this.index,
  });

  /// Each set on the reference has its own pale illustration (a closed book,
  /// a hammer, a waving hand); these stand in for them by position.
  static const _art = [
    Icons.menu_book_rounded,
    Icons.handyman_rounded,
    Icons.waving_hand_rounded,
    Icons.map_rounded,
    Icons.account_balance_rounded,
    Icons.local_cafe_rounded,
  ];

  @override
  Widget build(BuildContext context) {
    final mode = topic.mode;
    final chat = mode == StudyMode.conversation;
    final (fill, ink) = switch (mode) {
      StudyMode.writing => (D.ink, Colors.white),
      StudyMode.grammar => (Palette.grammarAccent, D.ink),
      StudyMode.conversation => (Palette.chatBlue, Colors.white),
    };
    return Container(
      decoration: _cardDecoration(Colors.white),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(
            right: 12,
            bottom: 12,
            child: Transform.rotate(
              angle: -.26,
              child: Icon(
                chat
                    ? CupertinoIcons.chat_bubble_2_fill
                    : _art[index % _art.length],
                size: 150,
                color: chat ? Palette.chatArt : Palette.setArt,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(32.5, 32.3, 31.3, 32.7),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        lesson.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: D.text(
                          27,
                          weight: FontWeight.w800,
                          height: 1.26,
                          spacing: -1,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      (index + 1).toString().padLeft(2, '0'),
                      style: D.text(
                        17,
                        weight: FontWeight.w700,
                        color: D.line,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 7.1),
                Padding(
                  padding: const EdgeInsets.only(right: 30),
                  child: Text(
                    lesson.description,
                    maxLines: chat ? 2 : 3,
                    overflow: TextOverflow.ellipsis,
                    style: D.text(13, color: D.muted, height: 1.35),
                  ),
                ),
                const Spacer(),
                PressFade(
                  onTap: () => go<void>(
                    context,
                    chat
                        ? ChatScreen(lesson: lesson)
                        : PracticeScreen(lesson: lesson),
                  ),
                  child: Container(
                    height: 44.3,
                    padding: const EdgeInsets.symmetric(horizontal: 32.6),
                    decoration: BoxDecoration(
                      color: fill,
                      borderRadius: BorderRadius.circular(22.15),
                      boxShadow: [
                        BoxShadow(
                          color: fill.withValues(alpha: .25),
                          blurRadius: 14,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Center(
                      widthFactor: 1,
                      child: Text(
                        mode.action(context),
                        style: D.text(13, weight: FontWeight.w600, color: ink),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The last card, which opens the AI generator. Writing and grammar show the
/// lime card measured on the iPhone (its text says "ngữ pháp" in both);
/// conversation's text is from survey 84, which only showed its pale blue edge,
/// so its layout follows the lime card.
class _CreateCard extends StatelessWidget {
  final StudyMode mode;
  const _CreateCard({required this.mode});
  @override
  Widget build(BuildContext context) {
    final chat = mode == StudyMode.conversation;
    return Container(
      decoration: _cardDecoration(
        chat ? Palette.chatArt : Palette.grammarAccent,
        edge: false,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: chat ? Colors.white : Palette.createDisc,
              shape: BoxShape.circle,
            ),
            child: const Icon(CupertinoIcons.sparkles, size: 46, color: D.ink),
          ),
          const SizedBox(height: 25),
          Text(
            chat ? context.t.createScenarioQ : context.t.topicNotListed,
            textAlign: TextAlign.center,
            style: D.text(
              21,
              weight: FontWeight.w800,
              height: 1.27,
              spacing: -.5,
            ),
          ),
          const SizedBox(height: 4.9),
          Text(
            chat ? context.t.roleplayAnything : context.t.customGrammar,
            textAlign: TextAlign.center,
            style: D.text(13, color: D.ink.withValues(alpha: .7)),
          ),
          const SizedBox(height: 24.8),
          PressFade(
            onTap: () => go<void>(context, GeneratorScreen(mode: mode)),
            child: Container(
              width: 139.3,
              height: 42.3,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(21.15),
                boxShadow: [
                  BoxShadow(
                    color: D.ink.withValues(alpha: .08),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Text(
                context.t.createCustom,
                style: D.text(13, weight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The card while sets load (survey 89): grey bars and a spinner where the
/// button will be.
class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard();
  @override
  Widget build(BuildContext context) {
    Widget bar(double width, double height) => Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Palette.skeleton,
        borderRadius: BorderRadius.circular(height / 2.6),
      ),
    );
    return Container(
      decoration: _cardDecoration(Colors.white),
      padding: const EdgeInsets.fromLTRB(32.5, 34, 32.5, 32.7),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          bar(230, 34),
          const SizedBox(height: 12),
          bar(230, 15),
          const SizedBox(height: 12),
          bar(160, 15),
          const Spacer(),
          Container(
            width: 176,
            height: 44.3,
            padding: const EdgeInsets.symmetric(horizontal: 18),
            decoration: BoxDecoration(
              color: Palette.skeleton.withValues(alpha: .5),
              borderRadius: BorderRadius.circular(22.15),
            ),
            child: Row(
              children: [
                const CupertinoActivityIndicator(radius: 8),
                const SizedBox(width: 12),
                Expanded(child: bar(double.infinity, 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 8 pt dots 8 pt apart; the current one is a 20 pt pill.
class _Dots extends StatelessWidget {
  final int count, index;
  final Color color;
  const _Dots({required this.count, required this.index, required this.color});
  @override
  Widget build(BuildContext context) => SizedBox(
    height: 8,
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < count; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: i == index ? 20 : 8,
            height: 8,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: i == index ? color : D.line,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
      ],
    ),
  );
}
