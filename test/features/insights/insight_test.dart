import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hifive/data/data.dart';
import 'package:hifive/domain/models/models.dart';
import 'package:hifive/features/insights/insight_screen.dart';
import 'package:hifive/state/state.dart';

import '../../helpers.dart';

const _tall = Size(393, 1500);

StudySession _session(DateTime date, {StudyMode mode = StudyMode.grammar}) =>
    StudySession(
      id: '$date',
      lesson: Lesson(
        id: 'l',
        title: 't',
        description: '',
        mode: mode,
        questions: [
          for (var i = 0; i < 10; i++) const Question('p', 'one two three'),
        ],
      ),
      date: date,
      answers: [
        const AnswerRecord('', .2, GradeKind.incorrect),
        for (var i = 0; i < 9; i++)
          const AnswerRecord('', 1, GradeKind.correct),
      ],
      seconds: 34 * 60,
    );

AppState _state() => fresh()
  ..firstUse = DateTime(2026, 10, 3)
  ..history = [_session(DateTime(2026, 11, 1, 1))];

void main() {
  setUpAll(loadAppFonts);

  test('session badge uses English ordinals', () {
    expect([1, 2, 3, 4, 11, 12, 13, 21, 22, 23].map(ordinalBadge), [
      '1ST',
      '2ND',
      '3RD',
      '4TH',
      '11TH',
      '12TH',
      '13TH',
      '21ST',
      '22ND',
      '23RD',
    ]);
  });

  testWidgets('shows totals in the units the reference uses', (tester) async {
    await mount(tester, _state(), const InsightScreen(), size: _tall);
    expect(find.text('Tháng 11, 2026'), findsOneWidget);
    expect(find.text('1ST'), findsOneWidget);
    expect(find.text('30'), findsOneWidget);
    expect(find.text('TỪ'), findsOneWidget);
    expect(find.text('00:34'), findsOneWidget);
    expect(find.text('GIỜ'), findsOneWidget);
    // Listening, games and focus, the second row, are all still at zero.
    expect(find.text('PHÚT'), findsNWidgets(2));
    expect(find.text('LƯỢT'), findsOneWidget);
    expect(find.text('CÂU'), findsNothing);
    // The time it was worked out, not a fixed one.
    expect(find.text('Cập nhật lúc 01:43 hôm nay'), findsOneWidget);
    expect(
      find.text(
        'Bạn đã hoàn thành 1 buổi tập trong Tháng 11, 2026, và 1 buổi trong năm nay.',
      ),
      findsOneWidget,
    );
    expect(find.text('1 lỗi ngữ pháp'), findsOneWidget);
  });

  testWidgets('counts words, listening, games and focus, not only lessons', (
    tester,
  ) async {
    final state = fresh();
    final deck = state.decks.first;
    // Two words in one sitting, timed at 20 s and 50 s, and one untimed.
    state
      ..rate(deck.words[0], 2, ms: 20000)
      ..rate(deck.words[1], 3, ms: 50000)
      ..rate(deck.words[1], 3)
      ..listened('video', position: 300, heard: 300)
      ..finishGame(40, clearResume: false);
    await mount(tester, state, const InsightScreen(), size: _tall);
    final summary = state.activityBetween(
      DateTime(2026, 11),
      DateTime(2026, 12),
    );
    expect(summary.words, 2);
    expect(summary.seconds, 20 + 50 + 12 + 300);
    expect(summary.listenSeconds, 300);
    expect(summary.games, 1);
    // A vocabulary session, a video heard and a game.
    expect(summary.sessions, 3);
    expect(find.text('3RD'), findsOneWidget);
    expect(find.text('00:06'), findsOneWidget);
    expect(find.text('5'), findsWidgets);
    // No lesson this month: nothing claims there were no grammar mistakes.
    expect(find.textContaining('lỗi ngữ pháp'), findsNothing);
    expect(find.byKey(const ValueKey('insight-ai-info')), findsNothing);
    // Today's bar counts all three.
    expect(find.byKey(const ValueKey('insight-bar-6')), findsOneWidget);
  });

  testWidgets('counts days with Hifive from the first use', (tester) async {
    await mount(tester, _state(), const InsightScreen(), size: _tall);
    expect(find.textContaining('29 ngày.', findRichText: true), findsOneWidget);
  });

  testWidgets('week chart ends on today, with one dot per day of the month', (
    tester,
  ) async {
    await mount(tester, _state(), const InsightScreen(), size: _tall);
    // The clock is pinned to Sunday 1 November 2026.
    final labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final xs = [
      for (final label in labels) tester.getCenter(find.text(label)).dx,
    ];
    expect(xs, orderedEquals([...xs]..sort()));
    expect(find.byKey(const ValueKey('insight-bar-6')), findsOneWidget);
    expect(find.byKey(const ValueKey('insight-bar-5')), findsNothing);
    expect(find.byKey(const ValueKey('insight-day-30')), findsOneWidget);
    expect(find.byKey(const ValueKey('insight-day-31')), findsNothing);
  });

  testWidgets('suggestions are coming soon and do not load', (tester) async {
    await mount(tester, _state(), const InsightScreen(), size: _tall);
    expect(find.text('Sắp ra mắt'), findsOneWidget);
    await tester.tap(find.text('Xem gợi ý cải thiện'));
    await tester.pump(const Duration(seconds: 2));
    expect(find.text('Đang tạo gợi ý...'), findsNothing);
    expect(find.text('Gợi ý cải thiện'), findsNothing);
  });

  testWidgets('hides the suggestion button when there are no mistakes', (
    tester,
  ) async {
    final state = fresh();
    await mount(tester, state, const InsightScreen(), size: _tall);
    expect(find.text('Xem gợi ý cải thiện'), findsNothing);
  });

  testWidgets('first use is saved and restored', (tester) async {
    final store = MemoryRecordStore();
    final first = fresh(
      store: store,
      legacy: MemoryAppRepository()
        ..data = {'firstUse': '2026-10-03T00:00:00.000'},
    );
    await first.load();
    expect(first.firstUse, DateTime(2026, 10, 3));
    final restored = fresh(store: store);
    await restored.load();
    expect(restored.firstUse, DateTime(2026, 10, 3));
  });
}
