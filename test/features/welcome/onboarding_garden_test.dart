import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hifive/app/app.dart';
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

Future<void> _tapKey(WidgetTester tester, String key) async {
  await tester.tap(find.byKey(ValueKey(key)));
  await tester.pumpAndSettle();
}

/// Opens onboarding on step [index] (0 is the welcome).
Future<void> _openStep(WidgetTester tester, int index) async {
  await _openApp(tester, fresh(auth: signedIn(), onboarded: false));
  for (var i = 0; i < index; i++) {
    await _tapKey(tester, 'onboarding-next');
  }
}

String? _focusTitle(WidgetTester tester) => tester
    .widget<Text>(find.byKey(const ValueKey('onboarding-focus-title')))
    .data;

void main() {
  setUpAll(loadAppFonts);

  testWidgets('the garden step changes the tree between the first species', (
    tester,
  ) async {
    await _openStep(tester, 2);
    expect(find.text('Sồi · Đổi'), findsOneWidget);
    await _tapKey(tester, 'onboarding-garden-species');
    expect(find.text('Thông · Đổi'), findsOneWidget);
    await _tapKey(tester, 'onboarding-garden-species');
    expect(find.text('Sồi · Đổi'), findsOneWidget);
  });

  testWidgets('a full day takes no more drops until the next day', (
    tester,
  ) async {
    await _openStep(tester, 2);
    await tester.tap(find.byKey(const ValueKey('onboarding-water-1')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('onboarding-water-1')));
    await tester.pump();
    // The day is full: this tap waits for the next day.
    await tester.tap(find.byKey(const ValueKey('onboarding-water-1')));
    await tester.pump();
    expect(
      find.text('Cây học đang lớn · 9/10 giọt nước · 2/3 ngày'),
      findsOneWidget,
    );
    await tester.pumpAndSettle(const Duration(seconds: 3));
  });

  testWidgets('leaving during the demo warns, then withers the tree', (
    tester,
  ) async {
    await _openStep(tester, 3);
    await tester.tap(find.byKey(const ValueKey('onboarding-focus-try')));
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    await tester.tap(find.byKey(const ValueKey('onboarding-focus-leave')));
    await tester.pump();
    expect(
      find.text('Quay lại Hifive trong 30 giây để giữ cây.'),
      findsOneWidget,
    );
    await tester.pump(const Duration(milliseconds: 1500));
    expect(
      find.text('Quay lại Hifive trong 15 giây để giữ cây.'),
      findsOneWidget,
    );
    await tester.pump(const Duration(seconds: 2));
    expect(_focusTitle(tester), 'Không sao, thử lại nhé');
    expect(
      find.byKey(const ValueKey('onboarding-focus-replant')),
      findsOneWidget,
    );

    // Planting again starts over.
    await tester.tap(find.byKey(const ValueKey('onboarding-focus-replant')));
    await tester.pump();
    expect(_focusTitle(tester), '25:00');
    await tester.pumpAndSettle(const Duration(seconds: 10));
    expect(_focusTitle(tester), 'Hoàn thành 25 phút');
  });

  testWidgets('coming back in time keeps the session going', (tester) async {
    await _openStep(tester, 3);
    await tester.tap(find.byKey(const ValueKey('onboarding-focus-try')));
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    await tester.tap(find.byKey(const ValueKey('onboarding-focus-leave')));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.tap(find.byKey(const ValueKey('onboarding-focus-return')));
    await tester.pump();
    await tester.pump(const Duration(seconds: 3));
    expect(
      find.byKey(const ValueKey('onboarding-focus-leave')),
      findsOneWidget,
    );
    await tester.pumpAndSettle(const Duration(seconds: 10));
    expect(_focusTitle(tester), 'Hoàn thành 25 phút');
  });

  testWidgets('Android has no app blocking to mention', (tester) async {
    await _openStep(tester, 3);
    expect(find.text('Tự chặn ứng dụng khác'), findsNothing);
    expect(find.text('Khoá màn hình vẫn tính'), findsOneWidget);
  });

  testWidgets('on iOS the focus step says other apps are blocked', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    await _openStep(tester, 3);
    expect(find.text('Tự chặn ứng dụng khác'), findsOneWidget);
    debugDefaultTargetPlatformOverride = null;
  });
}
