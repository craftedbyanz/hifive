import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hifive/app/app.dart';
import 'package:hifive/features/profile/profile.dart';
import 'package:hifive/l10n/l10n.dart';

import '../../helpers.dart';

void main() {
  setUpAll(loadAppFonts);

  test('the device language is used when the app speaks it', () {
    expect(resolveAppLocale(const [Locale('ko', 'KR')]), const Locale('ko'));
    expect(
      resolveAppLocale(const [Locale('fr'), Locale('zh', 'CN')]),
      const Locale('zh'),
    );
    expect(resolveAppLocale(const [Locale('fr')]), const Locale('vi'));
    expect(appLocale(''), isNull);
  });

  testWidgets('picking a language switches the app at once and is saved', (
    tester,
  ) async {
    final state = fresh(auth: signedIn());
    await tester.pumpWidget(HifiveApp(state: state, animateAmbient: false));
    await tester.pumpAndSettle();
    final nav = tester.state<NavigatorState>(find.byType(Navigator).first);
    nav.push(
      MaterialPageRoute<void>(builder: (_) => const AppLanguageScreen()),
    );
    await tester.pumpAndSettle();
    expect(find.text('Ngôn ngữ ứng dụng'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('app-language-ko')));
    await tester.pumpAndSettle();
    expect(state.appLanguage, 'ko');
    expect(find.text('앱 언어'), findsOneWidget);

    tester.platformDispatcher.localesTestValue = const [Locale('en', 'US')];
    addTearDown(
      () => tester.platformDispatcher.localesTestValue = const [Locale('vi')],
    );
    await tester.tap(find.byKey(const ValueKey('app-language-system')));
    await tester.pumpAndSettle();
    expect(state.appLanguage, '');
    // Following the device, which now speaks English.
    expect(find.text('App language'), findsOneWidget);
  });
}
