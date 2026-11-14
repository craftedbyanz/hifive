import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hifive/data/data.dart';
import 'package:hifive/domain/repositories/repositories.dart';
import 'package:hifive/features/profile/profile.dart';
import 'package:hifive/features/welcome/welcome.dart';

import '../../helpers.dart';

const _tall = Size(393, 2100);

void main() {
  setUpAll(loadAppFonts);

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
