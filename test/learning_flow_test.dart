import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hifive/core/design/design.dart';
import 'package:hifive/core/state.dart';
import 'package:hifive/data/data.dart';
import 'package:hifive/domain/models/models.dart';
import 'package:hifive/domain/repositories/repositories.dart';
import 'package:hifive/features/flashcards/flashcards.dart';
import 'package:hifive/features/game/game.dart';
import 'package:hifive/features/history/history.dart';
import 'package:hifive/features/insights/insights.dart';
import 'package:hifive/features/learning/learning.dart';

import 'helpers.dart';

const tall = Size(393, 2400);

class _FailingConversation implements ConversationRepository {
  bool fail = true;
  final inner = const MockConversationRepository(latency: Duration.zero);
  @override
  Future<ChatTurn> respond({
    required Lesson lesson,
    required int index,
    required String answer,
    required ChatSettings settings,
  }) => fail
      ? failing<ChatTurn>()
      : inner.respond(
          lesson: lesson,
          index: index,
          answer: answer,
          settings: settings,
        );
}

class _FailingInsights implements InsightRepository {
  bool fail = true;
  @override
  Future<List<String>> tips(List<StudySession> month) =>
      fail ? failing<List<String>>() : Future.value(mockInsightTips);
}

class _FailingDecks implements DeckGenerator {
  @override
  Future<List<FlashWord>> generate({
    required String topic,
    required int count,
    List<FlashWord> exclude = const [],
  }) => failing<List<FlashWord>>();
}

Future<void> _type(WidgetTester tester, Key key, String text) async {
  await tester.enterText(find.byKey(key), text);
  await tester.pump();
}

void main() {
  setUpAll(loadAppFonts);

  group('topic screen', () {
    testWidgets('tile titles never end on a lone word', (tester) async {
      final style = D.text(
        13,
        weight: FontWeight.w800,
        height: 1.28,
        spacing: -.5,
      );
      // 131 pt is the tile's text width on a 393 pt screen.
      expect(
        NoOrphanText.wrap('Mở rộng vốn từ tự nhiên', style, 131),
        'Mở rộng vốn từ\ntự nhiên',
      );
      expect(
        NoOrphanText.wrap('Khám phá Nam Mỹ', style, 131),
        'Khám phá Nam Mỹ',
      );
      // As the reference wraps it.
      expect(
        NoOrphanText.wrap('Kỹ năng hội thoại cơ bản', style, 131),
        'Kỹ năng hội thoại\ncơ bản',
      );
    });

    testWidgets('shows loading, then the topics', (tester) async {
      final state = fresh(
        lessons: MockLessonRepository(
          latency: const Duration(milliseconds: 300),
        ),
      );
      tester.view.physicalSize = tall;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(
        AppScope(
          state: state,
          child: const MaterialApp(home: TopicScreen(mode: StudyMode.grammar)),
        ),
      );
      expect(find.text('Đang tải...'), findsOneWidget);
      expect(find.byType(TopicTile), findsNothing);
      await tester.pumpAndSettle();
      expect(find.text('Đi làm muộn'), findsOneWidget);
    });

    testWidgets('a failed load offers retry, which recovers', (tester) async {
      final lessons = FailingLessonRepository();
      await mount(
        tester,
        fresh(lessons: lessons),
        const TopicScreen(mode: StudyMode.grammar),
        size: tall,
      );
      expect(find.text('Không tải được nội dung'), findsOneWidget);
      expect(find.byType(TopicTile), findsNothing);
      lessons.fail = false;
      await tester.tap(find.byKey(const ValueKey('async-retry')));
      await tester.pumpAndSettle();
      expect(find.byType(TopicTile), findsWidgets);
    });

    testWidgets('categories show related topics and Làm mới reorders them', (
      tester,
    ) async {
      await mount(
        tester,
        fresh(),
        const TopicScreen(mode: StudyMode.grammar),
        size: tall,
      );
      expect(find.text('Chế độ Vô tận'), findsOneWidget);
      expect(find.byKey(const ValueKey('topics-refresh')), findsNothing);
      await tester.tap(find.text('Giao tiếp'));
      await tester.pumpAndSettle();
      expect(find.text('CHỦ ĐỀ LIÊN QUAN'), findsOneWidget);
      expect(find.text('Chế độ Vô tận'), findsNothing);
      String firstTile() =>
          tester.widget<TopicTile>(find.byType(TopicTile).first).topic.title;
      final before = firstTile();
      await tester.tap(find.byKey(const ValueKey('topics-refresh')));
      await tester.pumpAndSettle();
      expect(firstTile(), isNot(before));
    });

    testWidgets('conversation lists its own categories', (tester) async {
      await mount(
        tester,
        fresh(),
        const TopicScreen(mode: StudyMode.conversation),
        size: tall,
      );
      expect(find.text('Sân bay & Khách sạn'), findsOneWidget);
      expect(find.text('IELTS'), findsNothing);
      expect(find.text('1 chủ đề'), findsOneWidget);
    });

    testWidgets('a closed settings tip stays closed on later visits', (
      tester,
    ) async {
      final state = fresh();
      await mount(
        tester,
        state,
        const TopicScreen(mode: StudyMode.conversation),
      );
      await tester.tap(find.byKey(const ValueKey('chat-tip-close')));
      await tester.pump();
      expect(state.chatTipSeen, isTrue);
      expect(state.toJson()['chatTipSeen'], isTrue);
      await tester.pumpWidget(const SizedBox());
      await mount(
        tester,
        state,
        const TopicScreen(mode: StudyMode.conversation),
      );
      expect(find.text('Tùy chỉnh Bài học'), findsNothing);
    });

    testWidgets('conversation settings popover changes mode and voice', (
      tester,
    ) async {
      final state = fresh();
      await mount(
        tester,
        state,
        const TopicScreen(mode: StudyMode.conversation),
      );
      expect(find.text('Tùy chỉnh Bài học'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('chat-tip-close')));
      await tester.pump();
      expect(find.text('Tùy chỉnh Bài học'), findsNothing);
      await tester.tap(find.byKey(const ValueKey('chat-settings')));
      await tester.pumpAndSettle();
      expect(find.text('Trò chuyện Tự do'), findsOneWidget);
      expect(find.text('Giọng: Thoải mái'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('chat-mode')));
      await tester.pump();
      expect(state.chatFree, isFalse);
      expect(find.text('Chế độ Kịch bản'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('chat-tone')));
      await tester.pump();
      expect(state.chatTone, 'Trang trọng');
      await tester.tap(find.byKey(const ValueKey('chat-guide')));
      await tester.pumpAndSettle();
      expect(find.text('Hướng dẫn Cài đặt'), findsOneWidget);
      await tester.tap(find.byTooltip('Đóng'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('chat-settings-close')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('chat-settings')), findsOneWidget);
    });
  });

  testWidgets('a collection that fails to load can be retried', (tester) async {
    final lessons = FailingLessonRepository();
    final topic = MockLessonRepository.topicsNow(
      StudyMode.writing,
      'Dành cho bạn',
    ).first;
    await mount(
      tester,
      fresh(lessons: lessons),
      CollectionScreen(topic: topic),
    );
    expect(find.text('Không tải được nội dung'), findsOneWidget);
    lessons.fail = false;
    await tester.tap(find.byKey(const ValueKey('async-retry')));
    await tester.pumpAndSettle();
    expect(find.text('Cáp treo Medellín'), findsOneWidget);
  });

  testWidgets('a writing collection ends with the AI card', (tester) async {
    final topic = MockLessonRepository.topicsNow(
      StudyMode.writing,
      'Dành cho bạn',
    ).first;
    final count = MockLessonRepository.lessonsNow(topic).length;
    await mount(tester, fresh(), CollectionScreen(topic: topic));
    for (var i = 0; i < count; i++) {
      await tester.drag(find.byType(PageView), const Offset(-330, 0));
      await tester.pumpAndSettle();
    }
    expect(find.text('Chủ đề không có trong danh sách?'), findsOneWidget);
    await tester.tap(find.text('Tạo tùy chỉnh'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<GeneratorScreen>(find.byType(GeneratorScreen)).mode,
      StudyMode.writing,
    );
  });

  group('AI generator', () {
    testWidgets('the wheel selects a preset and starts it', (tester) async {
      await mount(tester, fresh(), const GeneratorScreen(), size: tall);
      expect(find.text('Tạo chủ đề độc đáo của riêng bạn.'), findsOneWidget);
      final index = generatorSuggestions.indexOf('Gọi cà phê') + 1;
      await tester.drag(
        find.byType(ListWheelScrollView),
        Offset(0, -64.0 * index),
      );
      await tester.pumpAndSettle();
      expect(find.text('Tùy chỉnh đồ uống một cách tự nhiên'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('generator-go')));
      await tester.pumpAndSettle();
      final practice = tester.widget<PracticeScreen>(
        find.byType(PracticeScreen),
      );
      expect(practice.lesson.title, 'Gọi cà phê');
    });

    testWidgets('tapping a row brings it to the middle', (tester) async {
      await mount(tester, fresh(), const GeneratorScreen(), size: tall);
      await tester.tap(find.text(generatorSuggestions[1]));
      await tester.pumpAndSettle();
      expect(
        find.text(generatorDescription(generatorSuggestions[1])),
        findsOneWidget,
      );
    });

    testWidgets('the editor offers the reference examples', (tester) async {
      await mount(tester, fresh(), const GeneratorScreen(), size: tall);
      await tester.tap(find.byKey(const ValueKey('generator-describe')));
      await tester.pumpAndSettle();
      // The chips scroll sideways; the first two are on screen.
      expect(find.text(generatorExamples[0]), findsOneWidget);
      expect(find.text(generatorExamples[1]), findsOneWidget);
      await tester.tap(find.text('Job Interview Questions'));
      await tester.pump();
      await tester.tap(find.text('Bắt Đầu Luyện Tập'));
      await tester.pumpAndSettle();
      expect(find.byType(PracticeScreen), findsOneWidget);
    });

    testWidgets('a conversation topic opens the chat', (tester) async {
      await mount(
        tester,
        fresh(),
        const GeneratorScreen(
          mode: StudyMode.conversation,
          initialTopic: 'Gọi cà phê',
        ),
        size: tall,
      );
      await tester.tap(find.byKey(const ValueKey('generator-go')));
      await tester.pumpAndSettle();
      expect(find.byType(ChatScreen), findsOneWidget);
    });

    testWidgets('a failed generation stays on the chooser', (tester) async {
      await mount(
        tester,
        fresh(lessons: FailingLessonRepository()..fail = false),
        const GeneratorScreen(initialTopic: 'Gọi cà phê'),
        size: tall,
      );
      final state = AppScope.read(tester.element(find.byType(GeneratorScreen)));
      (state.lessons as FailingLessonRepository).fail = true;
      await tester.tap(find.byKey(const ValueKey('generator-go')));
      await tester.pumpAndSettle();
      expect(find.byType(PracticeScreen), findsNothing);
      expect(find.textContaining('Không tạo được'), findsOneWidget);
    });
  });

  testWidgets('the streak screen ignores a keyboard left open', (tester) async {
    // A chat finishes with the keyboard up, and this screen opens over it.
    tester.view.padding = const FakeViewPadding(top: 59, bottom: 34);
    tester.view.viewInsets = const FakeViewPadding(bottom: 336);
    addTearDown(tester.view.resetPadding);
    addTearDown(tester.view.resetViewInsets);
    final lesson = sampleLesson(StudyMode.grammar);
    await mount(
      tester,
      fresh(),
      CompletionScreen(
        session: StudySession(
          id: 's',
          lesson: lesson,
          date: DateTime(2026, 11, 3),
          answers: const [],
          seconds: 1,
        ),
      ),
    );
    expect(tester.takeException(), isNull);
  });

  group('lesson result', () {
    StudySession session(double score) {
      final lesson = sampleLesson(StudyMode.grammar);
      return StudySession(
        id: 'r',
        lesson: lesson,
        date: DateTime(2026, 11, 3),
        answers: [
          for (final q in lesson.questions)
            AnswerRecord(q.answer, score, GradeKind.correct),
        ],
        seconds: 120,
      );
    }

    testWidgets('a mastered lesson reads Excellent! under its title', (
      tester,
    ) async {
      final s = session(1);
      await mount(tester, fresh(), ResultScreen(session: s, fresh: true));
      expect(find.text(s.lesson.title), findsOneWidget);
      expect(find.text('Excellent!'), findsOneWidget);
      expect(find.text('You have mastered this lesson'), findsOneWidget);
      expect(find.text('100%'), findsOneWidget);
      // No back button: "Tiếp tục" is the way out.
      expect(find.byTooltip('Quay lại'), findsNothing);
    });

    testWidgets('a weak lesson keeps the encouragement', (tester) async {
      await mount(
        tester,
        fresh(),
        ResultScreen(session: session(0), fresh: true),
      );
      expect(find.text('Excellent!'), findsNothing);
      expect(find.text('Tiếp tục cố gắng!'), findsOneWidget);
    });
  });

  group('practice', () {
    testWidgets('grading spins the next button, then opens the result', (
      tester,
    ) async {
      await mount(
        tester,
        fresh(),
        PracticeScreen(lesson: sampleLesson(StudyMode.grammar)),
      );
      await _type(tester, const ValueKey('answer-input'), 'I am sorry');
      await tester.tap(find.byKey(const ValueKey('submit-answer')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      // No sheet yet: the wait shows in the button.
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('submit-answer')),
          matching: find.byType(CupertinoActivityIndicator),
        ),
        findsOneWidget,
      );
      expect(find.text('Đang chấm điểm...'), findsNothing);
      expect(find.text('Chưa đúng'), findsNothing);
      await tester.pumpAndSettle();
      expect(find.text('Chưa đúng'), findsOneWidget);
    });

    testWidgets('Huỷ during the analysis returns to the feedback', (
      tester,
    ) async {
      await mount(
        tester,
        fresh(),
        PracticeScreen(lesson: sampleLesson(StudyMode.grammar)),
      );
      await _type(
        tester,
        const ValueKey('answer-input'),
        apologyQuestions.first.answer,
      );
      await tester.tap(find.byKey(const ValueKey('submit-answer')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.byKey(const ValueKey('feedback-analyze')),
      );
      await tester.tap(find.byKey(const ValueKey('feedback-analyze')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('Đang chấm điểm...'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('grading-cancel')));
      await tester.pumpAndSettle();
      expect(find.text('Đang chấm điểm...'), findsNothing);
      expect(find.text('Câu tiếp theo'), findsOneWidget);
      // The cancelled analysis arrives later and is ignored.
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('GIẢI THÍCH'), findsNothing);
    });

    testWidgets('a grading failure can be retried', (tester) async {
      final grading = FailingGradingRepository();
      await mount(
        tester,
        fresh(grading: grading),
        PracticeScreen(lesson: sampleLesson(StudyMode.grammar)),
      );
      await _type(
        tester,
        const ValueKey('answer-input'),
        apologyQuestions.first.answer,
      );
      await tester.tap(find.byKey(const ValueKey('submit-answer')));
      await tester.pumpAndSettle();
      expect(find.text('Không chấm được câu trả lời'), findsOneWidget);
      grading.fail = false;
      await tester.tap(find.byKey(const ValueKey('grading-retry')));
      await tester.pumpAndSettle();
      expect(find.text('Chính xác'), findsOneWidget);
    });

    testWidgets('a correct answer offers the AI analysis', (tester) async {
      await mount(
        tester,
        fresh(),
        PracticeScreen(lesson: sampleLesson(StudyMode.grammar)),
      );
      await _type(
        tester,
        const ValueKey('answer-input'),
        apologyQuestions.first.answer,
      );
      await tester.tap(find.byKey(const ValueKey('submit-answer')));
      await tester.pumpAndSettle();
      expect(find.text('Câu tiếp theo'), findsOneWidget);
      expect(find.text('GIẢI THÍCH'), findsNothing);
      await tester.ensureVisible(
        find.byKey(const ValueKey('feedback-analyze')),
      );
      await tester.tap(find.byKey(const ValueKey('feedback-analyze')));
      await tester.pump();
      expect(find.text('Đang chấm điểm...'), findsOneWidget);
      await tester.pumpAndSettle();
      expect(find.text('GIẢI THÍCH'), findsOneWidget);
      expect(find.text('Xuất sắc'), findsOneWidget);
      expect(find.text('SỬA LỖI'), findsOneWidget);
      expect(find.text('Sửa'), findsOneWidget);
      expect(find.text('Tiếp theo'), findsOneWidget);
    });

    testWidgets('a correct paragraph answer reads Câu tiếp theo', (
      tester,
    ) async {
      await mount(
        tester,
        fresh(),
        PracticeScreen(lesson: sampleLesson(StudyMode.writing)),
      );
      await _type(
        tester,
        const ValueKey('answer-input'),
        paragraphQuestions.first.answer,
      );
      await tester.tap(find.byKey(const ValueKey('submit-answer')));
      await tester.pumpAndSettle();
      expect(find.text('Câu tiếp theo'), findsOneWidget);
      expect(find.text('Next'), findsNothing);
    });

    testWidgets('✨ appears after typing and suggests missing words', (
      tester,
    ) async {
      await mount(
        tester,
        fresh(),
        PracticeScreen(lesson: sampleLesson(StudyMode.grammar)),
      );
      expect(find.byKey(const ValueKey('ai-assist')), findsNothing);
      await _type(tester, const ValueKey('answer-input'), 'I am');
      expect(find.byKey(const ValueKey('ai-assist')), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('ai-assist')));
      await tester.pumpAndSettle();
      expect(find.text('Gợi ý AI'), findsOneWidget);
      expect(find.textContaining('sorry'), findsWidgets);
    });

    testWidgets('the lesson menu matches the reference entries', (
      tester,
    ) async {
      final state = fresh();
      await mount(
        tester,
        state,
        PracticeScreen(lesson: sampleLesson(StudyMode.grammar)),
      );
      await tester.tap(find.byTooltip('Tùy chọn bài học'));
      await tester.pumpAndSettle();
      for (final label in [
        'Màu nền',
        'Hiển thị gợi ý',
        'Từ điển bài',
        'Thích',
        'Không thích',
      ]) {
        expect(find.text(label), findsOneWidget);
      }
      expect(find.text('Thông tin cấp độ'), findsNothing);
      await tester.tap(find.byKey(const ValueKey('lesson-like')));
      await tester.pumpAndSettle();
      expect(find.text('Đã ghi nhận đánh giá trong phiên học này'), findsOne);
      await tester.tap(find.byTooltip('Tùy chọn bài học'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Màu nền'));
      await tester.pumpAndSettle();
      for (final c in D.inputColors) {
        expect(find.text(c), findsOneWidget);
      }
      await tester.tap(find.text('Indigo'));
      await tester.pumpAndSettle();
      expect(state.inputColor, 'Indigo');
      // The submenu's title row goes back to the lesson menu.
      await tester.tap(find.byTooltip('Tùy chọn bài học'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Màu nền'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Màu nền').last);
      await tester.pumpAndSettle();
      expect(find.text('Từ điển bài'), findsOneWidget);
      expect(find.text('Indigo'), findsNothing);
    });

    testWidgets('a paragraph lesson is titled by its own lesson', (
      tester,
    ) async {
      await mount(
        tester,
        fresh(),
        PracticeScreen(
          lesson: sampleLesson(StudyMode.writing, title: 'Làng gốm'),
        ),
      );
      expect(find.text('LÀNG GỐM'), findsOneWidget);
      expect(find.text('THE MEDELLÍN METROCABLE VIEWS'), findsNothing);
    });
  });

  group('chat', () {
    Future<void> answerAll(WidgetTester tester, Lesson lesson) async {
      for (final line in lesson.questions.where((q) => !q.partner)) {
        await _type(tester, const ValueKey('chat-input'), line.answer);
        await tester.tap(find.byKey(const ValueKey('chat-send')));
        await tester.pumpAndSettle();
      }
    }

    testWidgets('a full scripted conversation is saved and scored', (
      tester,
    ) async {
      final state = fresh()..chatFree = false;
      final lesson = sampleLesson(StudyMode.conversation);
      await mount(tester, state, ChatScreen(lesson: lesson));
      expect(find.text(lesson.questions.first.answer), findsOneWidget);
      expect(
        find.text('Hãy nói: ${lesson.questions[1].prompt}'),
        findsOneWidget,
      );
      await answerAll(tester, lesson);
      expect(find.byType(CompletionScreen), findsOneWidget);
      expect(state.history, hasLength(1));
      final session = state.history.single;
      expect(session.lesson.mode, StudyMode.conversation);
      expect(session.scored, hasLength(4));
      expect(session.accuracy, 100);
    });

    testWidgets('two lessons finished at the same moment are both saved', (
      tester,
    ) async {
      // The clock is frozen, so ids built only from the time would collide.
      final state = fresh();
      final other = MockLessonRepository.lessonsNow(
        MockLessonRepository.topicsNow(
          StudyMode.conversation,
          'Sân bay & Khách sạn',
        ).first,
      ).first;
      for (final lesson in [sampleLesson(StudyMode.conversation), other]) {
        await mount(tester, state, ChatScreen(lesson: lesson));
        await answerAll(tester, lesson);
      }
      expect(state.history, hasLength(2));
    });

    testWidgets('free chat hides the line until Gợi ý', (tester) async {
      final lesson = sampleLesson(StudyMode.conversation);
      await mount(tester, fresh(), ChatScreen(lesson: lesson));
      expect(find.text('Trả lời tự do bằng tiếng Anh'), findsOneWidget);
      expect(find.textContaining(lesson.questions[1].prompt), findsNothing);
      await tester.tap(find.byKey(const ValueKey('chat-hint')));
      await tester.pump();
      expect(
        find.text('Hãy nói: ${lesson.questions[1].prompt}'),
        findsOneWidget,
      );
    });

    testWidgets('a wrong answer is marked and the partner still replies', (
      tester,
    ) async {
      final lesson = sampleLesson(StudyMode.conversation);
      await mount(tester, fresh(), ChatScreen(lesson: lesson));
      await _type(tester, const ValueKey('chat-input'), 'Banana phone');
      await tester.tap(find.byKey(const ValueKey('chat-send')));
      await tester.pumpAndSettle();
      expect(find.text('Chưa đúng'), findsOneWidget);
      expect(find.text(lesson.questions[2].answer), findsOneWidget);
      expect(find.text('1/4'), findsOneWidget);
    });

    testWidgets('a failed turn keeps the answer for retry', (tester) async {
      final conversation = _FailingConversation();
      final lesson = sampleLesson(StudyMode.conversation);
      await mount(
        tester,
        fresh(conversation: conversation),
        ChatScreen(lesson: lesson),
      );
      await _type(
        tester,
        const ValueKey('chat-input'),
        lesson.questions[1].answer,
      );
      await tester.tap(find.byKey(const ValueKey('chat-send')));
      await tester.pumpAndSettle();
      expect(find.text('Không gửi được câu trả lời.'), findsOneWidget);
      expect(find.text('0/4'), findsOneWidget);
      conversation.fail = false;
      await tester.tap(find.byKey(const ValueKey('chat-retry')));
      await tester.pumpAndSettle();
      expect(find.text('Chính xác'), findsOneWidget);
      expect(find.text('1/4'), findsOneWidget);
    });

    testWidgets('leaving early asks first and saves nothing', (tester) async {
      final state = fresh();
      await mount(
        tester,
        state,
        ChatScreen(lesson: sampleLesson(StudyMode.conversation)),
      );
      await tester.tap(find.byTooltip('Thoát hội thoại'));
      await tester.pumpAndSettle();
      expect(find.text('Thoát hội thoại?'), findsOneWidget);
      await tester.tap(find.text('Ở lại'));
      await tester.pumpAndSettle();
      expect(find.byType(ChatScreen), findsOneWidget);
      expect(state.history, isEmpty);
    });
  });

  testWidgets('history + starts a new lesson in the chosen mode', (
    tester,
  ) async {
    await mount(tester, fresh(includeExamples: true), const HistoryScreen());
    await tester.tap(find.byKey(const ValueKey('history-new')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('history-new-writing')));
    await tester.pumpAndSettle();
    final topics = tester.widget<TopicScreen>(find.byType(TopicScreen));
    expect(topics.mode, StudyMode.writing);
  });

  testWidgets('Xoay on the game home turns the screen and the game', (
    tester,
  ) async {
    final calls = <Object?>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'SystemChrome.setPreferredOrientations') {
          calls.add(call.arguments);
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    await mount(tester, fresh(), const GameHomeScreen(), size: tall);
    await tester.tap(find.byKey(const ValueKey('game-home-rotate')));
    await tester.pump();
    expect(calls.last, ['DeviceOrientation.landscapeLeft']);
    await tester.tap(find.byKey(const ValueKey('play-flowletter')));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(ListTile).first);
    await tester.pumpAndSettle();
    expect(
      tester.widget<GameScreen>(find.byType(GameScreen)).landscape,
      isTrue,
    );
  });

  testWidgets('Độ khó is its own page and picks a level', (tester) async {
    final state = fresh();
    await mount(tester, state, const GameHomeScreen(), size: tall);
    await tester.tap(find.text('Độ khó'));
    await tester.pumpAndSettle();
    expect(find.byType(GameDifficultyScreen), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('difficulty-Khó')));
    await tester.pump();
    expect(state.difficulty, 'Khó');
  });

  group('Insight', () {
    AppState withMistake(InsightRepository insights) =>
        fresh(insights: insights)
          ..history = [
            StudySession(
              id: 'one',
              lesson: sampleLesson(StudyMode.grammar),
              date: DateTime(2026, 11, 1),
              answers: const [AnswerRecord('x', 0, GradeKind.incorrect)],
              seconds: 30,
            ),
          ];

    testWidgets('failed suggestions can be retried', (tester) async {
      final insights = _FailingInsights();
      await mount(
        tester,
        withMistake(insights),
        const InsightScreen(),
        size: const Size(393, 1500),
      );
      await tester.tap(find.text('Xem gợi ý cải thiện'));
      await tester.pumpAndSettle();
      expect(find.text('Không tạo được gợi ý'), findsOneWidget);
      insights.fail = false;
      await tester.tap(find.byKey(const ValueKey('async-retry')));
      await tester.pumpAndSettle();
      expect(find.text(mockInsightTips.first), findsOneWidget);
    });

    testWidgets('Tạo bởi AI explains the suggestions', (tester) async {
      await mount(
        tester,
        withMistake(_FailingInsights()..fail = false),
        const InsightScreen(),
        size: const Size(393, 1500),
      );
      await tester.tap(find.byKey(const ValueKey('insight-ai-info')));
      await tester.pumpAndSettle();
      expect(find.textContaining('AI tổng hợp'), findsOneWidget);
    });
  });

  testWidgets('a failed deck generation keeps the form open', (tester) async {
    final state = fresh(deckGenerator: _FailingDecks());
    final count = state.decks.length;
    await mount(tester, state, const DeckListScreen());
    await tester.tap(find.byTooltip('Thêm bộ thẻ'));
    await tester.pumpAndSettle();
    await _type(tester, const ValueKey('deck-topic'), 'Du lịch');
    await tester.tap(find.byKey(const ValueKey('deck-generate')));
    await tester.pumpAndSettle();
    expect(state.decks, hasLength(count));
    expect(find.text('Không tạo được thẻ. Vui lòng thử lại.'), findsOneWidget);
    expect(find.byKey(const ValueKey('deck-generate')), findsOneWidget);
  });
}
