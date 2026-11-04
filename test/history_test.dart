import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hifive/features/history/history.dart';
import 'package:hifive/features/learning/learning.dart';

import 'helpers.dart';

const tall = Size(393, 1600);

void main() {
  setUpAll(loadAppFonts);
  searchAndMore();
  focusTest();

  testWidgets('search narrows results and reports no match', (tester) async {
    final state = fresh(includeExamples: true);
    await mount(tester, state, const HistoryScreen(), size: tall);
    expect(find.byType(SessionTile), findsWidgets);
    await tester.enterText(
      find.byKey(const ValueKey('history-search')),
      'zzz-not-a-title',
    );
    await tester.pumpAndSettle();
    expect(find.byType(SessionTile), findsNothing);
    expect(find.text('Không tìm thấy kết quả'), findsOneWidget);
  });

  testWidgets('opening a session shows its result', (tester) async {
    final state = fresh(includeExamples: true);
    await mount(tester, state, const HistoryScreen(), size: tall);
    await tester.tap(find.byType(SessionTile).first);
    await tester.pumpAndSettle();
    expect(find.byType(ResultScreen), findsOneWidget);
  });

  Future<void> openClear(WidgetTester tester) async {
    await tester.tap(find.byTooltip('Tùy chọn lịch sử'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Xóa tất cả'));
    await tester.pumpAndSettle();
  }

  testWidgets('clearing asks first and can be cancelled', (tester) async {
    final state = fresh(includeExamples: true);
    final count = state.history.length;
    await mount(tester, state, const HistoryScreen(), size: tall);
    await openClear(tester);
    await tester.tap(find.text('Huỷ'));
    await tester.pumpAndSettle();
    expect(state.history, hasLength(count));
  });

  testWidgets('confirming clears history and shows the empty state', (
    tester,
  ) async {
    final state = fresh(includeExamples: true);
    await mount(tester, state, const HistoryScreen(), size: tall);
    await openClear(tester);
    await tester.tap(find.text('Xóa tất cả').last);
    await tester.pumpAndSettle();
    expect(state.history, isEmpty);
    expect(find.text('Chưa có bài ôn tập'), findsOneWidget);
  });
}

void searchAndMore() {
  testWidgets('searching swaps + for ✕ and counts matches', (tester) async {
    final state = fresh(includeExamples: true);
    await mount(tester, state, const HistoryScreen(), size: tall);
    expect(find.byKey(const ValueKey('history-new')), findsOneWidget);
    final title = state.history.first.lesson.title;
    await tester.enterText(
      find.byKey(const ValueKey('history-search')),
      title.substring(0, 4),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('history-new')), findsNothing);
    expect(find.text('1'), findsWidgets);
    await tester.tap(find.byKey(const ValueKey('history-close')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('history-new')), findsOneWidget);
  });

  testWidgets('a section page counts its sessions', (tester) async {
    final state = fresh(includeExamples: true);
    final mode = state.history.first.lesson.mode;
    final count = state.history.where((s) => s.lesson.mode == mode).length;
    await mount(tester, state, HistoryScreen(mode: mode), size: tall);
    expect(find.text('$count sessions'), findsOneWidget);
  });
}

void focusTest() {
  testWidgets('the first tap on search keeps the keyboard', (tester) async {
    await mount(
      tester,
      fresh(includeExamples: true),
      const HistoryScreen(),
      size: tall,
    );
    await tester.tap(find.byKey(const ValueKey('history-search')));
    await tester.pumpAndSettle();
    // Hiding the title row must not rebuild the field and drop its focus.
    expect(tester.testTextInput.hasAnyClients, isTrue);
    expect(find.byKey(const ValueKey('history-close')), findsOneWidget);
  });
}
