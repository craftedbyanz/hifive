import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hifive/app/app.dart';
import 'package:hifive/data/data.dart';
import 'package:hifive/domain/models/models.dart';
import 'package:hifive/domain/repositories/repositories.dart';
import 'package:hifive/domain/sync/sync.dart';
import 'package:hifive/features/profile/profile.dart';
import 'package:hifive/state/state.dart';

import '../../helpers.dart';
import '../../sync_fakes.dart';

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

  testWidgets('lesson settings set new words a day', (tester) async {
    final state = fresh();
    await mount(tester, state, const LessonSettingsScreen(), size: tall);
    await tester.tap(find.byKey(const ValueKey('new-per-day-more')));
    await tester.pump();
    expect(state.newPerDay, 15);
    // Tapping the number lets the learner type it exactly, up to 50.
    await tester.tap(find.byKey(const ValueKey('new-per-day')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('new-per-day-field')),
      '60',
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('new-per-day-save')));
    await tester.pumpAndSettle();
    expect(state.newPerDay, 15);
    await tester.enterText(
      find.byKey(const ValueKey('new-per-day-field')),
      '7',
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('new-per-day-save')));
    await tester.pumpAndSettle();
    expect(state.newPerDay, 7);
    expect(find.text('7'), findsOneWidget);
    // Words are studied on flip cards only: no exercise switches.
    expect(find.text('Bài tập gõ từ'), findsNothing);
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

  testWidgets('the avatar opens Edit Profile; there is no separate row', (
    tester,
  ) async {
    final state = fresh();
    await mount(tester, state, const ProfileScreen(), size: tall);
    expect(find.text('Chỉnh sửa hồ sơ'), findsNothing);
    await tester.tap(find.byKey(const ValueKey('profile-avatar')));
    await tester.pumpAndSettle();
    expect(find.byType(EditProfileScreen), findsOneWidget);
  });

  testWidgets('notifications show the permission state honestly', (
    tester,
  ) async {
    await mount(tester, fresh(), const NotificationScreen(), size: tall);
    expect(find.text('Chưa bật trong Cài đặt'), findsOneWidget);
  });

  testWidgets(
    'Edit Profile shows the account and no sync row: sync runs on its own',
    (tester) async {
      final server = FakeSyncServer();
      final state = createAppState(
        store: MemoryRecordStore(),
        auth: MemoryAuthService(
          signedIn: const AuthUser(
            uid: 'g1',
            method: AuthMethod.google,
            email: 'lan@gmail.com',
          ),
        ),
        sync: server,
        feedback: SilentFeedback(),
        now: () => DateTime(2026, 11, 11, 10, 20),
      )..onboarded = true;
      await state.load();
      await state.sync();
      await mount(tester, state, const EditProfileScreen(), size: tall);
      expect(find.text('lan@gmail.com'), findsOneWidget);
      expect(find.text('Google'), findsOneWidget);
      expect(find.byKey(const ValueKey('profile-linked')), findsOneWidget);
      expect(find.byKey(const ValueKey('profile-sync-now')), findsNothing);
      expect(find.textContaining('Đã đồng bộ'), findsNothing);
      state.dispose();
    },
  );

  testWidgets('without the sync API Edit Profile has no sync row', (
    tester,
  ) async {
    await mount(
      tester,
      fresh(auth: signedIn()),
      const EditProfileScreen(),
      size: tall,
    );
    expect(find.text('test@hifive.vn'), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
    expect(find.byKey(const ValueKey('profile-sync-now')), findsNothing);
  });

  testWidgets('deleting an email account asks twice, then removes it', (
    tester,
  ) async {
    final auth = MemoryAuthService(
      signedIn: const AuthUser(
        uid: 'u1',
        method: AuthMethod.email,
        email: 'lan@x.vn',
      ),
    )..accounts['lan@x.vn'] = 'secret1';
    final server = FakeSyncServer();
    final state = createAppState(
      store: MemoryRecordStore(),
      auth: auth,
      sync: server,
      feedback: SilentFeedback(),
      now: () => DateTime(2026, 11, 15, 9),
    )..onboarded = true;
    await state.load();
    await mount(tester, state, const EditProfileScreen(), size: tall);

    await tester.tap(find.byKey(const ValueKey('profile-delete')));
    await tester.pumpAndSettle();
    expect(find.text('Xóa tài khoản?'), findsOneWidget);
    await tester.tap(find.text('Xóa vĩnh viễn'));
    await tester.pumpAndSettle();
    // A wrong password deletes nothing.
    await tester.enterText(
      find.byKey(const ValueKey('delete-password')),
      'nope',
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('delete-confirm')));
    await tester.pumpAndSettle();
    expect(auth.deleted, isEmpty);
    expect(state.user, isNotNull);

    await tester.tap(find.byKey(const ValueKey('profile-delete')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Xóa vĩnh viễn'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('delete-password')),
      'secret1',
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('delete-confirm')));
    await tester.pumpAndSettle();
    expect(auth.deleted, ['u1']);
    expect(server.deletedAccounts, ['u1']);
    expect(state.user, isNull);
    expect(find.text('Đã xóa tài khoản của bạn.'), findsOneWidget);
    state.dispose();
  });

  testWidgets('cancelling the confirmation keeps the account', (tester) async {
    final auth = MemoryAuthService(
      signedIn: const AuthUser(uid: 'g1', method: AuthMethod.google),
    );
    final state = fresh(auth: auth);
    await mount(tester, state, const EditProfileScreen(), size: tall);
    await tester.tap(find.byKey(const ValueKey('profile-delete')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Huỷ'));
    await tester.pumpAndSettle();
    expect(auth.deleted, isEmpty);
    expect(state.user, isNotNull);
  });
}
