import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hifive/widgets/common.dart';

void main() {
  late int knocks;
  setUp(() => knocks = 0);

  Future<void> pump(WidgetTester tester) => tester.pumpWidget(
    TapFeedback(
      onTap: () => knocks++,
      child: MaterialApp(
        home: Scaffold(
          body: ListView(
            children: [
              ActionButton('Tiếp tục', onTap: () {}),
              GestureDetector(
                key: const ValueKey('card'),
                onTap: () {},
                child: const SizedBox(height: 80, child: Text('Thẻ')),
              ),
              RoundButton(
                icon: CupertinoIcons.back,
                label: 'Quay lại',
                onTap: () {},
              ),
              const TextField(key: ValueKey('field')),
              const SizedBox(height: 60, child: Text('Chữ thường')),
              for (var i = 0; i < 20; i++)
                SizedBox(height: 60, child: Text('$i')),
            ],
          ),
        ),
      ),
    ),
  );

  testWidgets('tapping a button or a card knocks once', (tester) async {
    await pump(tester);
    await tester.tap(find.text('Tiếp tục'));
    await tester.tap(find.byKey(const ValueKey('card')));
    expect(knocks, 2);
  });

  testWidgets('going back, typing and plain text stay silent', (tester) async {
    await pump(tester);
    await tester.tap(find.byTooltip('Quay lại'));
    await tester.tap(find.byKey(const ValueKey('field')));
    await tester.tap(find.text('Chữ thường'));
    expect(knocks, 0);
  });

  testWidgets('a drag across a button does not knock', (tester) async {
    await pump(tester);
    await tester.drag(find.text('Tiếp tục'), const Offset(0, -120));
    await tester.pumpAndSettle();
    expect(knocks, 0);
  });
}
