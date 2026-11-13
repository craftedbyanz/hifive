import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hifive/core/services/system_actions.dart';
import 'package:hifive/domain/garden/garden.dart';
import 'package:hifive/features/garden/garden.dart';

import '../../helpers.dart';

void main() {
  setUpAll(loadAppFonts);

  testWidgets('a new tag is made from the focus screen and chosen', (
    tester,
  ) async {
    final state = fresh();
    await mount(tester, state, FocusScreen(clock: () => DateTime(2026)));
    await tester.tap(find.byKey(const ValueKey('focus-tag')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('tag-new')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('tag-name')), 'Đọc sách');
    await tester.tap(find.byKey(const ValueKey('tag-color-6')));
    await tester.tap(find.byKey(const ValueKey('tag-save')));
    await tester.pumpAndSettle();

    final tag = state.customTags.single;
    expect(tag.name, 'Đọc sách');
    expect(tag.color, 6);
    expect(state.focusTag, tag.id);
    expect(find.text('Đọc sách'), findsOneWidget);
  });

  testWidgets('an own tag can be renamed and deleted', (tester) async {
    final state = fresh();
    final id = state.addTag('Code', 4);
    await mount(tester, state, FocusScreen(clock: () => DateTime(2026)));
    await tester.tap(find.byKey(const ValueKey('focus-tag')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('tag-edit-english')), findsNothing);
    await tester.tap(find.byKey(ValueKey('tag-edit-$id')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('tag-name')), 'Lập trình');
    await tester.tap(find.byKey(const ValueKey('tag-save')));
    await tester.pumpAndSettle();
    expect(state.customTags.single.name, 'Lập trình');

    await tester.tap(find.byKey(ValueKey('tag-edit-$id')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('tag-delete')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Xoá nhãn').last);
    await tester.pumpAndSettle();
    expect(state.customTags, isEmpty);
  });

  testWidgets('the garden shows focus time by tag and shares a picture', (
    tester,
  ) async {
    final system = RecordingSystemActions();
    final state = fresh(system: system);
    final start = state.now();
    FocusSession session(String tag, int minutes) => FocusSession(
      id: state.newId(),
      start: start,
      end: start.add(Duration(minutes: minutes)),
      plannedMinutes: minutes,
      species: 'oak',
      outcome: FocusOutcome.done,
      tag: tag,
    );
    state
      ..recordFocus(session('work', 45))
      ..recordFocus(session('english', 15));
    await mount(tester, state, const GardenScreen());

    expect(find.text('0g 45p · 75%'), findsOneWidget);
    expect(find.text('0g 15p · 25%'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('garden-share')));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 300)),
    );
    await tester.pumpAndSettle();
    expect(system.calls, ['image']);
  });
}
