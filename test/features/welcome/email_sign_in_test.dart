import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hifive/data/data.dart';
import 'package:hifive/domain/repositories/repositories.dart';
import 'package:hifive/features/profile/profile.dart';
import 'package:hifive/features/welcome/welcome.dart';
import 'package:hifive/widgets/common.dart';

import '../../helpers.dart';

const _tall = Size(393, 2100);

Future<void> _type(WidgetTester tester, String key, String text) async {
  await tester.enterText(find.byKey(ValueKey(key)), text);
  await tester.pump();
}

void main() {
  setUpAll(loadAppFonts);

  testWidgets('email sign-in signs in and links the store', (tester) async {
    final auth = MemoryAuthService()..accounts['lan@example.com'] = 'secret1';
    final store = MemoryRecordStore();
    final state = fresh(auth: auth, store: store);
    await mount(tester, state, const Scaffold(body: EmailSignInForm()));
    expect(
      tester
          .widget<ActionButton>(find.byKey(const ValueKey('sign-in-submit')))
          .onTap,
      isNull,
    );
    await _type(tester, 'sign-in-email', ' lan@example.com ');
    await _type(tester, 'sign-in-password', 'secret1');
    await tester.tap(find.byKey(const ValueKey('sign-in-submit')));
    await tester.pumpAndSettle();
    expect(state.user?.email, 'lan@example.com');
    await state.flush();
    expect(store.metadata['accountUid'], state.user!.uid);
  });

  testWidgets('a wrong password explains itself and stays', (tester) async {
    final auth = MemoryAuthService()..accounts['lan@example.com'] = 'secret1';
    final state = fresh(auth: auth);
    await mount(tester, state, const Scaffold(body: EmailSignInForm()));
    await _type(tester, 'sign-in-email', 'lan@example.com');
    await _type(tester, 'sign-in-password', 'nope');
    await tester.tap(find.byKey(const ValueKey('sign-in-submit')));
    await tester.pump();
    expect(find.text('Email hoặc mật khẩu không đúng.'), findsOneWidget);
    expect(state.user, isNull);
    expect(find.byType(EmailSignInForm), findsOneWidget);
  });

  testWidgets('a new account can be created', (tester) async {
    final auth = MemoryAuthService();
    final state = fresh(auth: auth);
    await mount(tester, state, const Scaffold(body: EmailSignInForm()));
    await tester.tap(find.byKey(const ValueKey('sign-in-mode')));
    await tester.pump();
    expect(find.text('Tạo tài khoản'), findsWidgets);
    await _type(tester, 'sign-in-email', 'mai@example.com');
    await _type(tester, 'sign-in-password', '123');
    await tester.tap(find.byKey(const ValueKey('sign-in-submit')));
    await tester.pump();
    expect(find.text('Mật khẩu cần ít nhất 6 ký tự.'), findsOneWidget);
    await _type(tester, 'sign-in-password', '123456');
    await tester.tap(find.byKey(const ValueKey('sign-in-submit')));
    await tester.pumpAndSettle();
    expect(auth.accounts, {'mai@example.com': '123456'});
    expect(state.user?.method, AuthMethod.email);
  });

  testWidgets('a cancelled Google sign-in says nothing', (tester) async {
    final auth = MemoryAuthService()..failNext = AuthError.cancelled;
    final state = fresh(auth: auth);
    await mount(tester, state, const WelcomeScreen());
    await tester.tap(find.byKey(const ValueKey('sign-in-google')));
    await tester.pump();
    expect(find.byType(SnackBar), findsNothing);
    expect(state.user, isNull);
    await tester.tap(find.byKey(const ValueKey('sign-in-google')));
    await tester.pumpAndSettle();
    expect(state.user?.method, AuthMethod.google);
  });

  testWidgets('Apple is offered only where the platform supports it', (
    tester,
  ) async {
    await mount(
      tester,
      fresh(auth: MemoryAuthService(supportsApple: false)),
      const WelcomeScreen(),
    );
    expect(find.byKey(const ValueKey('sign-in-apple')), findsNothing);
    await mount(
      tester,
      fresh(auth: MemoryAuthService()),
      const WelcomeScreen(),
    );
    expect(find.byKey(const ValueKey('sign-in-apple')), findsOneWidget);
  });

  testWidgets('a password reset needs an email first', (tester) async {
    final auth = MemoryAuthService();
    await mount(
      tester,
      fresh(auth: auth),
      const Scaffold(body: EmailSignInForm()),
    );
    await tester.tap(find.byKey(const ValueKey('sign-in-reset')));
    await tester.pump();
    expect(auth.resetsSent, isEmpty);
    expect(
      find.text('Nhập email để nhận liên kết đặt lại mật khẩu.'),
      findsOneWidget,
    );
    await mount(
      tester,
      fresh(auth: auth),
      const Scaffold(body: EmailSignInForm()),
    );
    await _type(tester, 'sign-in-email', ' lan@example.com');
    await tester.tap(find.byKey(const ValueKey('sign-in-reset')));
    await tester.pump();
    expect(auth.resetsSent, ['lan@example.com']);
    expect(find.text('Đã gửi email đặt lại mật khẩu.'), findsOneWidget);
  });

  testWidgets('signing out asks first and keeps local data', (tester) async {
    final auth = MemoryAuthService(
      signedIn: const AuthUser(
        uid: 'u1',
        method: AuthMethod.apple,
        email: 'lan@icloud.com',
      ),
    );
    final store = MemoryRecordStore();
    final state = fresh(auth: auth, store: store)..setName('Lan');
    await state.flush();
    await mount(tester, state, const ProfileScreen(), size: _tall);
    // The account lives on Edit Profile now, not on Profile.
    expect(find.text('lan@icloud.com'), findsNothing);
    await tester.tap(find.byKey(const ValueKey('profile-logout')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Huỷ'));
    await tester.pumpAndSettle();
    expect(state.user, isNotNull);
    await tester.tap(find.byKey(const ValueKey('profile-logout')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Đăng xuất').last);
    await tester.pumpAndSettle();
    expect(state.user, isNull);
    expect(state.name, 'Lan');
    expect(store.records, isNotEmpty);
  });

  testWidgets('signed out, the logout row says so', (tester) async {
    await mount(tester, fresh(), const ProfileScreen(), size: _tall);
    await tester.tap(find.byKey(const ValueKey('profile-logout')));
    await tester.pump();
    expect(find.text('Bạn chưa đăng nhập.'), findsOneWidget);
  });
}
