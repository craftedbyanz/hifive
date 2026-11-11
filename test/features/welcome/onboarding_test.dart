import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hifive/app/app.dart';
import 'package:hifive/data/data.dart';
import 'package:hifive/domain/repositories/repositories.dart';
import 'package:hifive/domain/sync/sync.dart';
import 'package:hifive/features/home/home.dart';
import 'package:hifive/features/welcome/welcome.dart';
import 'package:hifive/state/state.dart';
import 'package:hifive/widgets/common.dart';

import '../../helpers.dart';
import '../../sync_fakes.dart';

Future<void> _openApp(WidgetTester tester, AppState s) async {
  tester.view.physicalSize = const Size(393, 852);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(HifiveApp(state: s, animateAmbient: false));
  await tester.pumpAndSettle();
}

Future<void> _tapKey(WidgetTester tester, String key) async {
  await tester.tap(find.byKey(ValueKey(key)));
  await tester.pumpAndSettle();
}

/// A step heading, whose title and accent lines are one rich text.
Finder _heading(String text) => find.textContaining(text, findRichText: true);

/// The welcome stack, labelled by its front card.
Finder _practice(String title) => find.byWidgetPredicate(
  (w) => w is Semantics && w.properties.label == title,
);

bool _canContinue(WidgetTester tester) =>
    tester
        .widget<ActionButton>(find.byKey(const ValueKey('onboarding-next')))
        .onTap !=
    null;

void main() {
  setUpAll(loadAppFonts);

  testWidgets('the demos respond, then name, level and goals are saved', (
    tester,
  ) async {
    final store = MemoryRecordStore();
    final s = fresh(auth: signedIn(), store: store, onboarded: false);
    await _openApp(tester, s);
    expect(find.byType(OnboardingScreen), findsOneWidget);
    expect(find.byKey(const ValueKey('onboarding-back')), findsNothing);

    // Welcome: a tap deals the next way to practise to the front.
    expect(_practice('Viết đoạn văn'), findsOneWidget);
    await _tapKey(tester, 'onboarding-practice-stack');
    expect(_practice('Sửa câu'), findsOneWidget);
    await _tapKey(tester, 'onboarding-next');

    // Flashcards: a tap flips the card; rating it sends it away and says
    // when it comes back.
    await _tapKey(tester, 'onboarding-card');
    expect(find.text('tò mò'), findsOneWidget);
    await _tapKey(tester, 'onboarding-remembered');
    expect(find.text('Ôn lại sau 4 ngày'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('onboarding-card')),
        matching: find.text('journey'),
      ),
      findsOneWidget,
    );
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    await _tapKey(tester, 'onboarding-next');

    // Writing: grading thinks, then explains.
    await tester.tap(find.byKey(const ValueKey('onboarding-grade')));
    await tester.pump();
    expect(find.text('Đang chấm...'), findsOneWidget);
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(find.text('Gần đúng'), findsOneWidget);
    await _tapKey(tester, 'onboarding-next');

    // Grammar: a wrong pick says so; the right one explains.
    await _tapKey(tester, 'onboarding-option-go');
    expect(find.text('Chưa đúng, thử lại nhé'), findsOneWidget);
    await _tapKey(tester, 'onboarding-option-goes');
    expect(find.text('Chính xác!'), findsOneWidget);
    expect(find.text('She goes to work by bus every day.'), findsOneWidget);
    await _tapKey(tester, 'onboarding-next');

    // Conversation: the blunt reply earns a tip and an answer.
    await _tapKey(tester, 'onboarding-reply-1');
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(
      find.text('Lịch sự hơn: "Could I have a coffee, please?"'),
      findsOneWidget,
    );
    expect(find.text('Sure! What kind of coffee?'), findsOneWidget);
    await _tapKey(tester, 'onboarding-next');

    // Name: the account has no display name, so it starts empty.
    expect(_heading('Bạn tên là gì?'), findsOneWidget);
    expect(_canContinue(tester), isFalse);
    await tester.enterText(find.byKey(const ValueKey('onboarding-name')), '  ');
    await tester.pump();
    expect(_canContinue(tester), isFalse);
    await tester.enterText(
      find.byKey(const ValueKey('onboarding-name')),
      ' Lan ',
    );
    await tester.pump();
    expect(find.text('3/12'), findsOneWidget);
    expect(_canContinue(tester), isTrue);
    await _tapKey(tester, 'onboarding-next');

    // Level: required.
    expect(_canContinue(tester), isFalse);
    await _tapKey(tester, 'onboarding-level-B1');
    expect(_canContinue(tester), isTrue);
    await _tapKey(tester, 'onboarding-next');

    // Goals: at least one, at most three.
    expect(find.text('Hoàn tất'), findsOneWidget);
    expect(_canContinue(tester), isFalse);
    for (final id in ['travel', 'work', 'exam', 'media']) {
      await tester.ensureVisible(find.byKey(ValueKey('onboarding-goal-$id')));
      await _tapKey(tester, 'onboarding-goal-$id');
    }
    expect(find.text('Đã chọn 3/3 mục tiêu.'), findsOneWidget);
    await _tapKey(tester, 'onboarding-goal-work');
    expect(find.text('Đã chọn 2/3 mục tiêu.'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('onboarding-next')));
    await tester.pump(const Duration(milliseconds: 400));

    // The wait shows the answers, then opens Home.
    expect(find.text('Đang lưu hồ sơ của Lan'), findsOneWidget);
    expect(s.onboarded, isFalse);
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(s.name, 'Lan');
    expect(s.level, 'B1');
    expect(s.goals, ['travel', 'exam']);
    expect(s.onboarded, isTrue);

    await s.flush();
    final settings = {
      for (final r in store.records.values)
        if (r.kind == RecordKind.setting) r.id: r.data!['v'],
    };
    expect(settings, {
      'name': 'Lan',
      'level': 'B1',
      'goals': ['travel', 'exam'],
      'onboarded': true,
    });
  });

  testWidgets('back returns to the step before, keeping its answer', (
    tester,
  ) async {
    await _openApp(tester, fresh(auth: signedIn(), onboarded: false));
    for (var i = 0; i < 5; i++) {
      await _tapKey(tester, 'onboarding-next');
    }
    await tester.enterText(find.byKey(const ValueKey('onboarding-name')), 'An');
    await tester.pump();
    await _tapKey(tester, 'onboarding-next');
    expect(_heading('của bạn là gì?'), findsOneWidget);
    await _tapKey(tester, 'onboarding-back');
    expect(_heading('Bạn tên là gì?'), findsOneWidget);
    expect(find.text('An'), findsOneWidget);
    expect(_canContinue(tester), isTrue);
  });

  testWidgets('a Google name fills the name step, shortened to fit', (
    tester,
  ) async {
    final auth = MemoryAuthService(
      signedIn: const AuthUser(
        uid: 'g1',
        method: AuthMethod.google,
        displayName: 'Nguyễn Thị Thanh Hương',
      ),
    );
    await _openApp(tester, fresh(auth: auth, onboarded: false));
    for (var i = 0; i < 5; i++) {
      await _tapKey(tester, 'onboarding-next');
    }
    expect(find.text('Hương'), findsOneWidget);
    expect(_canContinue(tester), isTrue);
  });

  testWidgets('a second device waits for the account, then skips onboarding', (
    tester,
  ) async {
    final server = FakeSyncServer();
    const lan = AuthUser(uid: 'u1', method: AuthMethod.email, email: 'l@x.vn');

    // The first device finished onboarding and synced.
    final first = createAppState(
      store: MemoryRecordStore(),
      auth: MemoryAuthService(signedIn: lan),
      sync: server,
      feedback: SilentFeedback(),
    );
    await first.load();
    first.completeOnboarding(name: 'Lan', level: 'B2', goals: ['work']);
    await first.sync();
    first.dispose();

    final second = createAppState(
      store: MemoryRecordStore(),
      auth: MemoryAuthService(signedIn: lan),
      sync: server,
      feedback: SilentFeedback(),
    );
    void Function([FutureOr<void>?]) release = ([_]) {};
    server.during = () {
      final gate = Completer<void>();
      release = gate.complete;
      return gate.future;
    };
    await second.load();
    await _openApp(tester, second);
    expect(find.text('Đang tải dữ liệu của bạn'), findsOneWidget);
    expect(find.byType(OnboardingScreen), findsNothing);
    server.during = null;
    release();
    await tester.pumpAndSettle();
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(second.name, 'Lan');
    expect(second.goals, ['work']);
    second.dispose();
  });

  testWidgets('a failed first sync goes on to onboarding', (tester) async {
    final server = FakeSyncServer()..failBefore = SyncError.unavailable;
    final s = createAppState(
      store: MemoryRecordStore(),
      auth: signedIn(),
      sync: server,
      feedback: SilentFeedback(),
    );
    await s.load();
    await s.sync();
    await _openApp(tester, s);
    expect(find.byType(OnboardingScreen), findsOneWidget);
    s.dispose();
  });

  test('signing out forgets onboarding with the rest of the account', () async {
    final s = createAppState(
      store: MemoryRecordStore(),
      auth: signedIn(),
      sync: FakeSyncServer(),
      feedback: SilentFeedback(),
    );
    await s.load();
    s.completeOnboarding(name: 'Lan', level: 'A2', goals: ['daily']);
    await s.signOut();
    expect(s.onboarded, isFalse);
    expect(s.goals, isEmpty);
    expect(s.name, 'An');
    s.dispose();
  });

  testWidgets('signing in raises a veil, then the heading writes itself', (
    tester,
  ) async {
    final feedback = RecordingFeedback();
    final s = fresh(feedback: feedback, onboarded: false);
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(HifiveApp(state: s));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.byKey(const ValueKey('sign-in-google')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    // Signed in, but sign-in stays under the rising veil for now.
    expect(s.user, isNotNull);
    expect(find.byType(WelcomeScreen), findsOneWidget);
    expect(find.byType(OnboardingScreen), findsNothing);
    expect(find.bySemanticsLabel('Đang đăng nhập'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 800));
    // Frame by frame, as a device draws them.
    for (var i = 0; i < 25; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    expect(find.byType(WelcomeScreen), findsNothing);
    expect(find.byType(OnboardingScreen), findsOneWidget);

    // The title is part-way written, ticking as it goes; the demo waits.
    const title = 'Chào mừng\nđến với Hifive';
    final partTitle = find.byWidgetPredicate((w) {
      if (w is! RichText) return false;
      final text = w.text.toPlainText();
      return text.isNotEmpty && text != title && title.startsWith(text);
    });
    expect(partTitle, findsOneWidget);
    expect(feedback.taps, greaterThan(2));
    double gradeOpacity() => tester
        .widget<AnimatedOpacity>(
          find
              .ancestor(
                of: find.byKey(const ValueKey('onboarding-practice-stack')),
                matching: find.byType(AnimatedOpacity),
              )
              .first,
        )
        .opacity;
    expect(gradeOpacity(), 0);
    await tester.pump(const Duration(seconds: 3));
    await tester.pump(const Duration(milliseconds: 400));
    expect(partTitle, findsNothing);
    expect(_heading(title), findsOneWidget);
    expect(gradeOpacity(), 1);
    await tester.pumpWidget(const SizedBox());
  });
}
