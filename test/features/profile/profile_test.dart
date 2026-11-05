import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hifive/data/data.dart';
import 'package:hifive/domain/models/models.dart';
import 'package:hifive/domain/sync/sync.dart';
import 'package:hifive/features/profile/profile.dart';

import '../../helpers.dart';

const tall = Size(393, 1800);

void main() {
  setUpAll(loadAppFonts);

  testWidgets('editing the name saves a trimmed value', (tester) async {
    final store = MemoryRecordStore();
    final state = fresh(store: store);
    await mount(tester, state, const EditProfileScreen());
    await tester.enterText(find.byType(TextField).first, '  Linh  ');
    await tester.pump();
    await tester.tap(find.text('Lưu thay đổi'));
    await tester.pump();
    await state.flush();
    expect(state.name, 'Linh');
    expect(store.data(RecordKind.setting, 'name'), {'v': 'Linh'});
  });

  testWidgets('a blank name cannot be saved', (tester) async {
    final state = fresh();
    await mount(tester, state, const EditProfileScreen());
    await tester.enterText(find.byType(TextField).first, '   ');
    await tester.pump();
    await tester.tap(find.text('Lưu thay đổi'));
    await tester.pump();
    expect(state.name, 'An');
  });

  testWidgets('choosing a level applies only after confirming', (tester) async {
    final state = fresh();
    await mount(tester, state, const LevelPickerScreen(), size: tall);
    await tester.tap(find.text('B1 - Intermediate'));
    await tester.pump();
    expect(state.level, 'A1');
    await tester.tap(find.text('Xác nhận'));
    await tester.pump();
    expect(state.level, 'B1');
  });

  testWidgets('lesson settings change hints and input color', (tester) async {
    final state = fresh();
    await mount(tester, state, const LessonSettingsScreen(), size: tall);
    await tester.tap(find.byKey(const ValueKey('hints-toggle')));
    await tester.pump();
    expect(state.showHints, isTrue);
    await tester.tap(find.text('Blue'));
    await tester.pump();
    expect(state.inputColor, 'Blue');
  });

  testWidgets('appearance changes style and resets card order', (tester) async {
    final state = fresh();
    state.modeOrder = StudyMode.values.reversed.toList();
    await mount(tester, state, const AppearanceScreen(), size: tall);
    await tester.tap(find.text('Mono'));
    await tester.pump();
    expect(state.appearance, 'Mono');
    await tester.tap(find.text('Reset'));
    await tester.pump();
    expect(state.modeOrder, StudyMode.values);
  });

  testWidgets('unavailable languages only announce coming soon', (
    tester,
  ) async {
    final state = fresh();
    await mount(tester, state, const LanguageScreen(), size: tall);
    await tester.tap(find.text('Korean'));
    await tester.pump();
    expect(find.text('Coming soon'), findsWidgets);
    expect(find.text('Sắp ra mắt'), findsOneWidget);
    expect(state.level, 'A1');
  });

  testWidgets('profile opens its settings screens', (tester) async {
    final state = fresh();
    await mount(tester, state, const ProfileScreen(), size: tall);
    await tester.tap(find.text('Chỉnh sửa hồ sơ'));
    await tester.pumpAndSettle();
    expect(find.byType(EditProfileScreen), findsOneWidget);
  });

  testWidgets('an offer code goes nowhere and says so', (tester) async {
    final state = fresh();
    await mount(
      tester,
      state,
      const ProfileScreen(),
      size: const Size(393, 2100),
    );
    await tester.tap(find.text('Nhập mã ưu đãi'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('redeem-continue')));
    await tester.pumpAndSettle();
    expect(find.byType(RedemptionForm), findsOneWidget, reason: 'needs a code');
    await tester.enterText(find.byKey(const ValueKey('redeem-code')), 'ABC');
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('redeem-continue')));
    await tester.pumpAndSettle();
    expect(find.byType(RedemptionForm), findsNothing);
    expect(
      find.text('Bản cục bộ không kết nối App Store hoặc đổi mã.'),
      findsOneWidget,
    );
  });

  testWidgets('notifications show the permission state honestly', (
    tester,
  ) async {
    await mount(tester, fresh(), const NotificationScreen(), size: tall);
    expect(find.text('Chưa bật trong Cài đặt'), findsOneWidget);
  });
}
