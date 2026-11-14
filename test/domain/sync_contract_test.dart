import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hifive/domain/sync/sync.dart';
import 'package:hifive/state/app_records.dart';

/// Every kind the app writes and syncs. A new kind must be added here, to
/// the Worker's `syncedKinds` and to the merge table in the backend plan.
const _appSynced = {
  RecordKind.setting,
  RecordKind.session,
  RecordKind.historyCleared,
  RecordKind.deck,
  RecordKind.word,
  RecordKind.review,
  RecordKind.game,
  RecordKind.focus,
  RecordKind.listen,
  RecordKind.share,
  RecordKind.legacyStats,
  AppKinds.firstUse,
};

void main() {
  test('the Worker accepts exactly the kinds the app syncs', () {
    final source = File('worker/src/sync.ts').readAsStringSync();
    final block = RegExp(r'syncedKinds = new Set\(\[([^\]]*)\]\)')
        .firstMatch(source)!
        .group(1)!;
    final worker = RegExp(r'"([A-Za-z]+)"').allMatches(block).map((m) => m[1]!);
    expect(worker.toSet(), _appSynced);
    expect(_appSynced.intersection(RecordKind.local), isEmpty);
  });

  test('stamps match the pattern the Worker checks', () {
    final pattern = RegExp(r'^\d{15}:[0-9a-z]{4,8}:[A-Za-z0-9-]{1,64}$');
    final stamp = Hlc(
      DateTime(2026, 11, 10).millisecondsSinceEpoch,
      37,
      uuidV7(DateTime(2026)),
    );
    expect(pattern.hasMatch(stamp.toString()), isTrue);
  });
}
