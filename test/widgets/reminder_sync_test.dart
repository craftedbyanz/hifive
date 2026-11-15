import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hifive/l10n/l10n.dart';
import 'package:hifive/state/state.dart';
import 'package:hifive/widgets/reminder_sync.dart';

import '../helpers.dart';

void main() {
  late List<MethodCall> calls;

  setUp(() {
    calls = [];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('hifive/screen'), (
          call,
        ) async {
          calls.add(call);
          return null;
        });
  });
  tearDown(
    () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('hifive/screen'), null),
  );

  Future<List<Map<Object?, Object?>>> scheduled(
    WidgetTester tester,
    AppState state,
  ) async {
    await tester.pumpWidget(
      AppScope(
        state: state,
        child: MaterialApp(
          locale: const Locale('vi'),
          supportedLocales: supportedAppLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          builder: (context, child) => ReminderSync(child: child!),
          home: const SizedBox(),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 3));
    final call = calls.lastWhere((c) => c.method == 'scheduleReminders');
    return (call.arguments as List).cast<Map<Object?, Object?>>();
  }

  testWidgets('days with nothing due get a nudge to learn new words', (
    tester,
  ) async {
    // The pinned clock is 01:43, so the first reminder is today at 20:00.
    final state = fresh()..setReminder(on: true, time: '20:00');
    final list = await scheduled(tester, state);
    expect(list, hasLength(ReminderSync.days));
    expect(list.first['title'], 'Học vài từ mới hôm nay nhé');
    expect(
      list.first['body'],
      '10 từ mới, khoảng 5 phút, và cây học của bạn được tưới.',
    );
  });

  testWidgets('no nudge on a day the learner already studied', (tester) async {
    final state = fresh()..setReminder(on: true, time: '20:00');
    // Rated "Dễ", the word is studied today and not due again for days.
    state.rate(state.decks.first.words.first, 3);
    final list = await scheduled(tester, state);
    DateTime at(Map<Object?, Object?> m) =>
        DateTime.fromMillisecondsSinceEpoch((m['at']! as double).round());
    expect(list.map(at), isNot(contains(state.nextReminder)));
    expect(at(list.first), state.nextReminder.add(const Duration(days: 1)));
  });

  testWidgets('no nudge for a learner who takes no new words', (tester) async {
    final state = fresh()
      ..setReminder(on: true, time: '20:00')
      ..setNewPerDay(0);
    await tester.pumpWidget(
      AppScope(
        state: state,
        child: MaterialApp(
          builder: (context, child) => ReminderSync(child: child!),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: supportedAppLocales,
          home: const SizedBox(),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 3));
    expect(calls.map((c) => c.method), isNot(contains('scheduleReminders')));
    expect(calls.last.method, 'cancelReminder');
  });
}
