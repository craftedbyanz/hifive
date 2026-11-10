import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hifive/app/app.dart';
import 'package:hifive/data/data.dart';
import 'package:hifive/features/home/home.dart';
import 'package:hifive/features/profile/profile.dart';
import 'package:hifive/features/welcome/welcome.dart';
import 'package:hifive/state/state.dart';

import '../../helpers.dart';

Future<void> _openApp(WidgetTester tester, AppState s) async {
  tester.view.physicalSize = const Size(393, 852);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(HifiveApp(state: s, animateAmbient: false));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(loadAppFonts);

  testWidgets('signed out, the app opens on the welcome pages', (tester) async {
    final s = fresh();
    await _openApp(tester, s);
    expect(find.byType(WelcomeScreen), findsOneWidget);
    expect(find.byType(HomeScreen), findsNothing);
    expect(find.text('Học ngoại ngữ bằng cách viết và nói'), findsOneWidget);
    expect(find.text('Tiếp tục'), findsOneWidget);
  });

  testWidgets('the pages lead to sign-in, which is remembered', (tester) async {
    final store = MemoryRecordStore();
    final s = fresh(store: store);
    await s.load();
    await _openApp(tester, s);
    for (final title in ['Ba cách luyện tập', 'Nhớ lâu hơn mỗi ngày']) {
      await tester.tap(find.byKey(const ValueKey('welcome-next')));
      await tester.pumpAndSettle();
      expect(find.text(title), findsOneWidget);
    }
    expect(find.text('Bắt đầu'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('welcome-next')));
    await tester.pumpAndSettle();
    expect(find.text('Bắt đầu với Hifive'), findsOneWidget);
    expect(find.byKey(const ValueKey('welcome-next')), findsNothing);
    await s.flush();
    expect(s.introSeen, isTrue);
    expect(await store.meta('introSeen'), '1');
  });

  testWidgets('skip goes straight to sign-in', (tester) async {
    await _openApp(tester, fresh());
    await tester.tap(find.byKey(const ValueKey('welcome-skip')));
    await tester.pumpAndSettle();
    expect(find.byType(SignInPanel), findsOneWidget);
    expect(find.text('Bắt đầu với Hifive'), findsOneWidget);
  });

  testWidgets('a device that saw the pages opens on sign-in', (tester) async {
    final store = MemoryRecordStore()..metadata['introSeen'] = '1';
    final s = fresh(store: store);
    await s.load();
    await _openApp(tester, s);
    expect(find.text('Bắt đầu với Hifive'), findsOneWidget);
    expect(find.byKey(const ValueKey('welcome-skip')), findsNothing);
  });

  testWidgets('signing in opens Home', (tester) async {
    final auth = MemoryAuthService()..accounts['lan@x.vn'] = 'secret1';
    final s = fresh(auth: auth)..introSeen = true;
    await _openApp(tester, s);
    await tester.enterText(
      find.byKey(const ValueKey('sign-in-email')),
      'lan@x.vn',
    );
    await tester.enterText(
      find.byKey(const ValueKey('sign-in-password')),
      'secret1',
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('sign-in-submit')));
    await tester.pumpAndSettle();
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.byType(WelcomeScreen), findsNothing);
  });

  testWidgets('signing out from Profile closes it and shows sign-in', (
    tester,
  ) async {
    final s = fresh(auth: signedIn())..introSeen = true;
    await _openApp(tester, s);
    final nav = tester.state<NavigatorState>(find.byType(Navigator).first);
    nav.push(MaterialPageRoute<void>(builder: (_) => const ProfileScreen()));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('profile-logout')),
      300,
      scrollable: find
          .descendant(
            of: find.byKey(const ValueKey('profile-scroll')),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.tap(find.byKey(const ValueKey('profile-logout')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Đăng xuất').last);
    await tester.pumpAndSettle();
    expect(s.user, isNull);
    expect(find.byType(ProfileScreen), findsNothing);
    expect(find.text('Bắt đầu với Hifive'), findsOneWidget);
  });

  testWidgets('with Reduce Motion the pages still work', (tester) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await _openApp(tester, fresh());
    expect(find.text('Học ngoại ngữ bằng cách viết và nói'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('welcome-skip')));
    await tester.pump();
    expect(find.byType(SignInPanel), findsOneWidget);
  });
}
