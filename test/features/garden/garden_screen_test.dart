import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hifive/domain/garden/garden.dart';
import 'package:hifive/features/garden/garden.dart';
import 'package:hifive/state/state.dart';

import '../../helpers.dart';

FocusSession _focus(AppState s, DateTime start, int minutes, FocusOutcome o) =>
    FocusSession(
      id: s.newId(),
      start: start,
      end: start.add(Duration(minutes: minutes)),
      plannedMinutes: minutes,
      species: 'pine',
      outcome: o,
    );

void main() {
  setUpAll(loadAppFonts);

  test('periods start on the day, the Monday, the 1st and 1 January', () {
    final at = DateTime(2026, 11, 13, 15); // a Friday
    expect(periodRange(GardenPeriod.day, at).$1, DateTime(2026, 11, 13));
    expect(periodRange(GardenPeriod.week, at), (
      DateTime(2026, 11, 9),
      DateTime(2026, 11, 16),
    ));
    expect(periodRange(GardenPeriod.month, at).$2, DateTime(2026, 12));
    expect(periodRange(GardenPeriod.year, at).$1, DateTime(2026));
  });

  testWidgets('the garden counts trees and focus time of the chosen period', (
    tester,
  ) async {
    final state = fresh();
    final today = state.now();
    state
      ..recordFocus(_focus(state, today, 25, FocusOutcome.done))
      ..recordFocus(_focus(state, today, 6, FocusOutcome.withered))
      ..recordFocus(
        _focus(
          state,
          today.subtract(const Duration(days: 40)),
          60,
          FocusOutcome.done,
        ),
      );
    await mount(tester, state, const GardenScreen());

    expect(find.text('1 cây · 1 cây héo'), findsOneWidget);
    expect(find.text('0g 25p'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('garden-period-year')));
    await tester.pumpAndSettle();
    expect(find.text('2 cây · 1 cây héo'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('garden-period-day')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('garden-previous')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('garden-counts')), findsOneWidget);
    expect(
      find.text('Chưa có cây nào. Tập trung hoặc ôn từ để trồng cây đầu tiên.'),
      findsOneWidget,
    );
  });

  testWidgets('the study tree card changes the next study species', (
    tester,
  ) async {
    final state = fresh();
    await mount(tester, state, const GardenScreen());
    await tester.tap(find.byKey(const ValueKey('garden-study-tree')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('focus-species-pine')));
    await tester.pumpAndSettle();
    expect(state.studySpecies, 'pine');
  });

  testWidgets('the collection shows what unlocks each species', (tester) async {
    await mount(tester, fresh(), const GardenScreen());
    await tester.scrollUntilVisible(
      find.text('Đã mở 2/30 loài'),
      300,
      scrollable: find
          .descendant(
            of: find.byKey(const ValueKey('garden-list')),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('garden-species-galaxy')),
      300,
      scrollable: find
          .descendant(
            of: find.byKey(const ValueKey('garden-list')),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    expect(find.text('Chuỗi 365 ngày'), findsOneWidget);
    // The legendary galaxy tree sits in the last section, with no country.
    expect(find.text('Huyền thoại'), findsOneWidget);
    expect(find.text('Truyền thuyết'), findsOneWidget);
  });
}
