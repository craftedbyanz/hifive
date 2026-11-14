import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hifive/app/app.dart';
import 'package:hifive/data/data.dart';
import 'package:hifive/domain/repositories/repositories.dart';
import 'package:hifive/features/home/home.dart';
import 'package:hifive/features/profile/profile.dart';
import 'package:hifive/features/welcome/welcome.dart';
import 'package:hifive/state/state.dart';
import 'package:hifive/widgets/common.dart';

import '../../helpers.dart';

Future<void> _openApp(
  WidgetTester tester,
  AppState s, {
  bool animate = false,
}) async {
  tester.view.physicalSize = const Size(393, 852);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(HifiveApp(state: s, animateAmbient: animate));
  if (animate) {
    await tester.pump(const Duration(milliseconds: 400));
  } else {
    await tester.pumpAndSettle();
  }
}

const _writing = 'Viết thật nhiều,\nsửa từng câu';
const _chat = 'Trò chuyện\nkhông sợ sai';
const _cards = 'Nhớ từ mới\nlâu hơn';

void main() {
  setUpAll(loadAppFonts);

  testWidgets('signed out, the app opens on sign-in with the first demo', (
    tester,
  ) async {
    await _openApp(tester, fresh(auth: MemoryAuthService()));
    expect(find.byType(WelcomeScreen), findsOneWidget);
    expect(find.byType(HomeScreen), findsNothing);
    expect(find.text(_writing), findsOneWidget);
    for (final key in ['sign-in-apple', 'sign-in-google']) {
      expect(find.byKey(ValueKey(key)), findsOneWidget);
    }
    // Only Apple and Google: no email and password.
    expect(find.byKey(const ValueKey('sign-in-email-open')), findsNothing);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('sign-in-google')),
        matching: find.byType(GoogleLogo),
      ),
      findsOneWidget,
    );
    // Without autoplay the demo shows its finished frame.
    expect(find.text("Let's go to the beach this weekend!"), findsOneWidget);
  });

  testWidgets('the demos play one after another and loop', (tester) async {
    await _openApp(tester, fresh(), animate: true);
    expect(find.text(_writing), findsOneWidget);
    // Mid-way through the first demo the answer is still being typed.
    await tester.pump(const Duration(milliseconds: 1600));
    expect(find.text("Let's go to the beach this weekend!"), findsNothing);
    await tester.pump(const Duration(seconds: 3));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text(_chat), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 4800));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text(_cards), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 4800));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text(_writing), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('dots and swipes choose a demo', (tester) async {
    await _openApp(tester, fresh());
    await tester.tap(find.byKey(const ValueKey('welcome-dot-2')));
    await tester.pumpAndSettle();
    expect(find.text(_cards), findsOneWidget);
    await tester.fling(
      find.byKey(const ValueKey('welcome-stage')),
      const Offset(-300, 0),
      1000,
    );
    await tester.pumpAndSettle();
    expect(find.text(_writing), findsOneWidget);
    await tester.fling(
      find.byKey(const ValueKey('welcome-stage')),
      const Offset(300, 0),
      1000,
    );
    await tester.pumpAndSettle();
    expect(find.text(_cards), findsOneWidget);
  });

  testWidgets('Google signs in and opens Home', (tester) async {
    final s = fresh(auth: MemoryAuthService());
    await _openApp(tester, s);
    await tester.tap(find.byKey(const ValueKey('sign-in-google')));
    await tester.pumpAndSettle();
    expect(s.user?.method, AuthMethod.google);
    expect(find.byType(HomeScreen), findsOneWidget);
  });

  testWidgets('a first sign-in opens onboarding instead of Home', (
    tester,
  ) async {
    final s = fresh(onboarded: false);
    await _openApp(tester, s);
    await tester.tap(find.byKey(const ValueKey('sign-in-google')));
    await tester.pumpAndSettle();
    expect(find.byType(OnboardingScreen), findsOneWidget);
    expect(find.byType(HomeScreen), findsNothing);
  });

  testWidgets('signing out from Profile closes it and shows sign-in', (
    tester,
  ) async {
    final s = fresh(auth: signedIn());
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
    expect(find.byType(WelcomeScreen), findsOneWidget);
  });

  testWidgets('with Reduce Motion the demos hold still but can be chosen', (
    tester,
  ) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await _openApp(tester, fresh(), animate: true);
    expect(find.text("Let's go to the beach this weekend!"), findsOneWidget);
    await tester.pump(const Duration(seconds: 6));
    expect(find.text(_writing), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('welcome-dot-1')));
    await tester.pump();
    expect(find.text(_chat), findsOneWidget);
  });

  testWidgets('a signed-in learner opens straight on Home, without the veil', (
    tester,
  ) async {
    // With motion on, as on a phone: the veil is for signing in, not for
    // opening the app with an account already signed in.
    final feedback = RecordingFeedback();
    await _openApp(
      tester,
      fresh(auth: signedIn(), feedback: feedback),
      animate: true,
    );
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.byType(WelcomeScreen), findsNothing);
    expect(find.bySemanticsLabel('Đang đăng nhập'), findsNothing);
    expect(feedback.impacts, isEmpty);
    await tester.pumpWidget(const SizedBox());
  });
}
