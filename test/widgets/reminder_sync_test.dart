import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hifive/l10n/l10n.dart';
import 'package:hifive/state/state.dart';
import 'package:hifive/widgets/reminder_sync.dart';

import '../helpers.dart';

void main() {
  late List<MethodCall> calls;

  /// What the phone says about notifications; null gives no answer.
  String? status;

  setUp(() {
    calls = [];
    status = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('hifive/screen'), (
          call,
        ) async {
          calls.add(call);
          return call.method == 'notificationStatus' ? status : null;
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

  testWidgets('a nudge offers only the new words the decks still hold', (
    tester,
  ) async {
    final state = fresh()..setReminder(on: true, time: '20:00');
    // Keep three new words: every other word was met days ago and isn't
    // due for a long while.
    final unseen = state.uniqueWords.values.skip(3).toList();
    for (final w in unseen) {
      w
        ..status = 'review'
        ..due = DateTime(2027);
    }
    var list = await scheduled(tester, state);
    expect(
      list.first['body'],
      '3 từ mới, khoảng 2 phút, và cây học của bạn được tưới.',
    );
    // With none left, there is nothing to nudge about.
    for (final w in state.uniqueWords.values) {
      w
        ..status = 'review'
        ..due = DateTime(2027);
    }
    calls.clear();
    state.setVoice('Nicky');
    await tester.pump(const Duration(seconds: 3));
    final call = calls.where((c) => c.method == 'scheduleReminders');
    list = call.isEmpty
        ? const []
        : (call.last.arguments as List).cast<Map<Object?, Object?>>();
    expect(list, isEmpty);
    expect(calls.map((c) => c.method), contains('cancelReminder'));
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

  testWidgets('a synced reminder asks a phone that was never asked', (
    tester,
  ) async {
    status = 'unasked';
    final state = fresh()..setReminder(on: true, time: '20:00');
    await scheduled(tester, state);
    expect(calls.where((c) => c.method == 'prepareWarning'), hasLength(1));
    // Once a run, not after every change.
    state.setNewPerDay(5);
    await tester.pump(const Duration(seconds: 3));
    expect(calls.where((c) => c.method == 'prepareWarning'), hasLength(1));
  });

  testWidgets('a phone that already answered is not asked again', (
    tester,
  ) async {
    status = 'denied';
    final state = fresh()..setReminder(on: true, time: '20:00');
    await scheduled(tester, state);
    expect(calls.map((c) => c.method), isNot(contains('prepareWarning')));
  });

  testWidgets(
    'word notes put studied words on the lock screen, and stop when off',
    (tester) async {
      final state = fresh();
      final word = state.decks.first.words.first;
      state.rate(word, 0);
      state.setWordNotes(true);
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
      final call = calls.lastWhere((c) => c.method == 'scheduleWordNotes');
      final notes = (call.arguments as List).cast<Map<Object?, Object?>>();
      expect(notes, isNotEmpty);
      expect(notes.first['word'], word.id);
      expect(notes.first['title'], startsWith(word.word));
      expect(notes.first['body'], word.meaning);
      // The pinned clock is 01:43: the first note is at 08:00 today.
      expect(
        DateTime.fromMillisecondsSinceEpoch(
          (notes.first['at']! as double).round(),
        ),
        DateTime(2026, 11, 1, 8),
      );

      state.setWordNotes(false);
      await tester.pump(const Duration(seconds: 3));
      expect(calls.last.method, isIn(['cancelWordNotes', 'cancelReminder']));
      expect(calls.map((c) => c.method), contains('cancelWordNotes'));
    },
  );
}
