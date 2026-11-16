import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hifive/features/welcome/welcome.dart';

import '../../helpers.dart';

void main() {
  setUpAll(loadAppFonts);

  group('PreparingView', () {
    Widget view({Duration? duration, VoidCallback? onDone}) => MaterialApp(
      home: PreparingView(
        steps: const ['Một', 'Hai'],
        detail: 'Chờ',
        duration: duration,
        onDone: onDone,
      ),
    );

    testWidgets('steps through its lines, lifts away, then finishes', (
      tester,
    ) async {
      var done = 0;
      await tester.pumpWidget(
        view(duration: const Duration(seconds: 4), onDone: () => done++),
      );
      expect(find.text('Một'), findsOneWidget);
      await tester.pump(const Duration(seconds: 3));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Hai'), findsOneWidget);
      await tester.pump(const Duration(seconds: 1));
      expect(done, 0, reason: 'the screen lifts away first');
      await tester.pump(const Duration(milliseconds: 500));
      expect(done, 1);
    });

    testWidgets('an endless wait never finishes and keeps its brain lit', (
      tester,
    ) async {
      var done = 0;
      await tester.pumpWidget(view(onDone: () => done++));
      await tester.pump(const Duration(seconds: 30));
      expect(done, 0);
      expect(find.byKey(const ValueKey('preparing-brain')), findsOneWidget);
      expect(find.text('Một'), findsOneWidget);
    });
  });
}
