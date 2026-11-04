import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hifive/core/state.dart';
import 'package:hifive/data/data.dart';
import 'package:hifive/domain/models/models.dart';
import 'package:hifive/features/insights/insight_screen.dart';

import 'helpers.dart';

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
    expect(find.text('10'), findsOneWidget);
    expect(find.text('CÂU'), findsOneWidget);
    expect(
      find.text(
        'Bạn đã hoàn thành 1 buổi tập trong Tháng 11, 2026, và 1 buổi trong năm nay.',
      ),
      findsOneWidget,
    );
    expect(find.text('1 lỗi ngữ pháp'), findsOneWidget);
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

  testWidgets('suggestion button loads, then shows the tips', (tester) async {
    await mount(tester, _state(), const InsightScreen(), size: _tall);
    await tester.tap(find.text('Xem gợi ý cải thiện'));
    await tester.pump();
    expect(find.text('Đang tạo gợi ý...'), findsOneWidget);
    expect(find.text('Gợi ý cải thiện'), findsNothing);
    await tester.pump(const Duration(seconds: 2));
    expect(find.text('Gợi ý cải thiện'), findsOneWidget);
    expect(find.text(mockInsightTips.first), findsOneWidget);
    expect(find.text('Xem gợi ý cải thiện'), findsNothing);
  });

  testWidgets('hides the suggestion button when there are no mistakes', (
    tester,
  ) async {
    final state = fresh();
    await mount(tester, state, const InsightScreen(), size: _tall);
    expect(find.text('Xem gợi ý cải thiện'), findsNothing);
  });

  testWidgets('first use is saved and restored', (tester) async {
    final state = _state();
    final saved = state.toJson();
    final repository = MemoryAppRepository();
    await repository.save(saved);
    final restored = fresh(repository: repository);
    await restored.load();
    expect(restored.firstUse, DateTime(2026, 10, 3));
  });
}
