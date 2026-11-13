import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hifive/app/app.dart';
import 'package:hifive/data/data.dart';
import 'package:hifive/domain/models/models.dart';
import 'package:hifive/features/flashcards/flashcards.dart';
import 'package:hifive/features/game/game.dart';
import 'package:hifive/features/home/home.dart';
import 'package:hifive/features/information/information.dart';
import 'package:hifive/features/insights/insights.dart';
import 'package:hifive/features/learning/learning.dart';
import 'package:hifive/features/profile/profile.dart';

import '../helpers.dart';

void main() {
  setUpAll(loadAppFonts);
  testWidgets('home menu opens flashcards and back restores home', (
    tester,
  ) async {
    final s = fresh(auth: signedIn());
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(HifiveApp(state: s, animateAmbient: false));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Menu'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Học flashcard'));
    await tester.pumpAndSettle();
    expect(find.byType(DeckListScreen), findsOneWidget);
    await tester.tap(find.byTooltip('Quay lại'));
    await tester.pumpAndSettle();
    expect(find.text('Chúc ngủ ngon,'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'wrong answer, edit, correct feedback and complete persist a new result',
    (tester) async {
      final s = fresh();
      const lesson = Lesson(
        id: 'test',
        title: 'Lời xin lỗi',
        description: 'Test',
        mode: StudyMode.grammar,
        questions: [Question('Xin lỗi', 'I am sorry.')],
      );
      await mount(tester, s, const PracticeScreen(lesson: lesson));
      await tester.enterText(
        find.byKey(const ValueKey('answer-input')),
        'I is yesterday',
      );
      await tester.pump();
      await tester.tap(find.byTooltip('Chuyển tiếp'));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();
      expect(find.text('Chưa đúng'), findsOneWidget);
      await tester.tap(find.text('Sửa'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('answer-input')),
        'I am sorry.',
      );
      await tester.pump();
      await tester.tap(find.byTooltip('Chuyển tiếp'));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();
      expect(find.text('Chính xác'), findsOneWidget);
      await tester.tap(find.text('Câu tiếp theo'));
      await tester.pumpAndSettle();
      expect(find.byType(CompletionScreen), findsOneWidget);
      expect(s.history.length, 1);
      expect(s.history.first.answers.first.text, 'I am sorry.');
      expect(
        s.history.first.correct,
        0,
        reason: 'First-attempt result is retained after retry.',
      );
      expect(s.streak, 1);
      await s.flush();
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'deck search filters content and review card flips to an example',
    (tester) async {
      final s = fresh(), deck = seedDecks().last;
      await mount(tester, s, DeckScreen(deck: deck));
      await tester.tap(find.byTooltip('Tìm kiếm thẻ'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('deck-search')),
        'Guava',
      );
      await tester.pumpAndSettle();
      expect(find.text('Guava'), findsWidgets);
      expect(find.text('Melon'), findsNothing);
      await mount(
        tester,
        s,
        ReviewScreen(deck: deck, words: [deck.words.first]),
      );
      await tester.tap(find.byKey(const ValueKey('review-card')));
      await tester.pumpAndSettle();
      expect(
        find.text('"Guava juice is popular in the summer."'),
        findsOneWidget,
      );
      await tester.tap(find.text('Tốt'));
      await tester.pumpAndSettle();
      expect(find.text('Xuất sắc!'), findsOneWidget);
      expect(deck.words.first.status, 'review');
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'short screen settings and informational sheets lay out without errors',
    (tester) async {
      final s = fresh();
      for (final page in [
        const ProfileScreen(),
        const LanguageScreen(),
        const LessonSettingsScreen(),
        const AppearanceScreen(),
        const VoiceScreen(),
        const StreakScreen(),
        const InsightScreen(),
        const PlusScreen(),
        const GeneratorScreen(),
        const GameHomeScreen(),
      ]) {
        await mount(tester, s, page, size: const Size(360, 740));
        expect(
          tester.takeException(),
          isNull,
          reason: '${page.runtimeType} should fit',
        );
      }
    },
  );
  testWidgets('calendar month controls navigate across a year boundary', (
    tester,
  ) async {
    final s = fresh();
    await mount(tester, s, const StreakScreen());
    await tester.tap(find.byTooltip('Tháng trước'));
    await tester.pumpAndSettle();
    expect(find.text('tháng 10 năm 2026'), findsOneWidget);
    await tester.tap(find.byTooltip('Tháng sau'));
    await tester.pumpAndSettle();
    expect(find.text('tháng 11 năm 2026'), findsOneWidget);
  });
  testWidgets('game skip completes a new game and records local score', (
    tester,
  ) async {
    final s = fresh();
    final words = [FlashWord(id: 'cat', word: 'Cat', meaning: 'Con mèo')];
    await mount(tester, s, GameScreen(words: words, title: 'Animals'));
    await tester.tap(find.text('Bỏ qua'));
    await tester.pumpAndSettle();
    expect(find.text('Hoàn thành!'), findsOneWidget);
    // A skip neither raises the level nor counts as correct.
    expect(find.text('LEVEL 1'), findsOneWidget);
    expect(find.text('0%'), findsOneWidget);
    expect(s.gamesPlayed, 1);
    await tester.tap(find.text('Về trang chủ'));
    await tester.pumpAndSettle();
    expect(find.byType(GameScreen), findsNothing);
    expect(tester.takeException(), isNull);
  });
  testWidgets('flashcard swipe right schedules an easy card', (tester) async {
    final state = fresh(), deck = seedDecks().last;
    await mount(
      tester,
      state,
      ReviewScreen(deck: deck, words: [deck.words.first]),
    );
    await tester.drag(
      find.byKey(const ValueKey('review-card')),
      const Offset(140, 0),
    );
    await tester.pumpAndSettle();
    expect(find.text('Xuất sắc!'), findsOneWidget);
    // FSRS: a new card rated Dễ starts at about 16 days of stability.
    expect(deck.words.first.due, state.now().add(const Duration(days: 16)));
  });
  testWidgets('Flow Letter long press drag solves a word and awards XP', (
    tester,
  ) async {
    final state = fresh();
    await mount(
      tester,
      state,
      GameScreen(
        words: [FlashWord(id: 'cat', word: 'Cat', meaning: 'Con mèo')],
        title: 'Animals',
      ),
    );
    final source = tester.getCenter(find.byKey(const ValueKey('letter-0')));
    final target = tester.getTopLeft(find.byKey(const ValueKey('letter-1')));
    final gesture = await tester.startGesture(source);
    await tester.pump(const Duration(milliseconds: 600));
    await gesture.moveBy(const Offset(-10, 0));
    await tester.pump(const Duration(milliseconds: 100));
    await gesture.moveTo(Offset(target.dx - 60, source.dy));
    await tester.pump(const Duration(milliseconds: 100));
    await gesture.moveBy(const Offset(-8, 0));
    await tester.pump(const Duration(milliseconds: 700));
    await gesture.up();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(state.bestScore, 10);
    expect(state.totalXp, 10);
    expect(find.text('Hoàn thành!'), findsOneWidget);
    // A solve raises the level and counts towards accuracy and combo.
    expect(find.text('LEVEL 2'), findsOneWidget);
    expect(find.text('100%'), findsOneWidget);
    expect(find.text('x1'), findsOneWidget);
  });
  testWidgets('Flow Letter remains usable in landscape', (tester) async {
    await mount(
      tester,
      fresh(),
      GameScreen(
        words: [FlashWord(id: 'cat', word: 'Cat', meaning: 'Con mèo')],
        title: 'Animals',
      ),
      size: const Size(852, 393),
    );
    expect(find.text('Bỏ qua'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('lesson exit cancellation preserves the draft', (tester) async {
    final state = fresh();
    await mount(
      tester,
      state,
      PracticeScreen(lesson: sampleLesson(StudyMode.grammar, title: 'Test')),
    );
    await tester.enterText(
      find.byKey(const ValueKey('answer-input')),
      'My unfinished answer',
    );
    await tester.pump();
    await tester.tap(find.byTooltip('Thoát bài tập'));
    await tester.pumpAndSettle();
    expect(find.text('Thoát bài tập?'), findsOneWidget);
    await tester.tap(find.text('Ở lại'));
    await tester.pumpAndSettle();
    expect(find.text('My unfinished answer'), findsOneWidget);
    expect(state.history, isEmpty);
  });
  testWidgets('lesson menu changes hints and input color locally', (
    tester,
  ) async {
    final state = fresh();
    await mount(
      tester,
      state,
      PracticeScreen(lesson: sampleLesson(StudyMode.grammar, title: 'Test')),
    );
    await tester.tap(find.byTooltip('Tùy chọn bài học'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hiển thị gợi ý'));
    await tester.pumpAndSettle();
    expect(state.showHints, isTrue);
    expect(find.text('sorry'), findsOneWidget);
    await tester.tap(find.byTooltip('Tùy chọn bài học'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Màu nền'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Green'));
    await tester.pumpAndSettle();
    expect(state.inputColor, 'Green');
    expect(tester.takeException(), isNull);
  });
  testWidgets('starting a conversation opens the chat, not the Plus gate', (
    tester,
  ) async {
    final state = fresh();
    await mount(
      tester,
      state,
      CollectionScreen(
        topic: MockLessonRepository.topicsNow(
          StudyMode.conversation,
          'Dành cho bạn',
        ).first,
      ),
    );
    await tester.tap(find.text('Bắt đầu chat'));
    await tester.pumpAndSettle();
    expect(find.byType(ChatScreen), findsOneWidget);
    expect(find.byType(PlusScreen), findsNothing);
    expect(state.history, isEmpty);
    expect(tester.takeException(), isNull);
  });
  testWidgets('sample saved results render all three verified modes', (
    tester,
  ) async {
    final state = fresh();
    for (final session in sampleHistory()) {
      await mount(
        tester,
        state,
        ResultScreen(session: session),
        size: const Size(360, 740),
      );
      expect(find.text('CÂU TRẢ LỜI CỦA BẠN'), findsOneWidget);
      expect(tester.takeException(), isNull, reason: session.lesson.mode.name);
    }
    await tester.tap(find.text('Làm lại bài tập'));
    await tester.pumpAndSettle();
    expect(find.byType(ChatScreen), findsOneWidget);
  });
  testWidgets(
    'Home menu moves through intermediate frames and closes reversibly',
    (tester) async {
      tester.view.physicalSize = const Size(393, 852);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        HifiveApp(state: fresh(auth: signedIn()), animateAmbient: false),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Menu'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 80));
      final entering = tester.getTopLeft(find.text('Insight')).dy;
      await tester.pumpAndSettle();
      final resting = tester.getTopLeft(find.text('Insight')).dy;
      expect(entering, greaterThan(resting));
      await tester.tapAt(const Offset(20, 220));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 60));
      expect(find.text('Insight'), findsOneWidget);
      expect(tester.getTopLeft(find.text('Insight')).dy, greaterThan(resting));
      await tester.pumpAndSettle();
      expect(find.text('Insight'), findsNothing);
    },
  );
  testWidgets(
    'Home carousel scales vertically while a drag is still in progress',
    (tester) async {
      tester.view.physicalSize = const Size(393, 852);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        HifiveApp(state: fresh(auth: signedIn()), animateAmbient: false),
      );
      await tester.pumpAndSettle();
      final card = find.ancestor(
        of: find.text('Đoạn văn'),
        matching: find.byType(ModeCard),
      );
      final before = Rect.fromPoints(
        tester.getTopLeft(card),
        tester.getBottomRight(card),
      );
      final gesture = await tester.startGesture(const Offset(270, 600));
      await gesture.moveBy(const Offset(-10, 0));
      await tester.pump(const Duration(milliseconds: 16));
      await gesture.moveBy(const Offset(-100, 0));
      await tester.pump(const Duration(milliseconds: 16));
      await gesture.moveBy(const Offset(-60, 0));
      await tester.pump(const Duration(milliseconds: 30));
      final during = Rect.fromPoints(
        tester.getTopLeft(card),
        tester.getBottomRight(card),
      );
      expect(during.height, lessThan(before.height));
      expect(during.height, greaterThan(before.height * .95));
      expect(during.width, closeTo(before.width, .1));
      expect(during.bottom, closeTo(before.bottom, .1));
      await gesture.up();
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );
}
