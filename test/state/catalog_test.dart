import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hifive/app/app.dart';
import 'package:hifive/data/data.dart';
import 'package:hifive/domain/repositories/repositories.dart';
import 'package:hifive/domain/vocab/vocab.dart';
import 'package:hifive/state/state.dart';

/// The real starter pack from `worker/catalog`.
final _pack = File('worker/catalog/en/1.json').readAsStringSync();

class _Catalog implements CatalogRepository {
  int? version = 1;
  var fail = false;
  var fetched = 0;
  @override
  Future<int?> latestVersion(String language) async {
    if (fail) throw const SocketException('offline');
    return version;
  }

  @override
  Future<String> pack(String language, int version) async {
    fetched++;
    return _pack;
  }
}

void main() {
  var now = DateTime(2026, 11, 13, 9);
  late MemoryRecordStore store;
  late _Catalog catalog;

  AppState make() => createAppState(
    store: store,
    catalog: catalog,
    feedback: SilentFeedback(),
    now: () => now,
  );

  setUp(() {
    now = DateTime(2026, 11, 13, 9);
    store = MemoryRecordStore();
    catalog = _Catalog();
  });

  test('the starter pack parses into three A1 decks of twelve words', () {
    final decks = parseCatalog(_pack);
    expect(decks.map((d) => d.words.length), [12, 12, 12]);
    final ids = decks.expand((d) => d.words).map((w) => w.id).toSet();
    expect(ids, hasLength(36));
  });

  test('catalog decks arrive, are cached, and keep their reviews', () async {
    final state = make();
    await state.load();
    await state.refreshCatalog();
    final family = state.decks.firstWhere((d) => d.id == 'cat-en-a1-family');
    state.rate(family.words.first, 2);
    await state.flush();

    // Offline next time: the cached pack still shows, with its review.
    catalog.fail = true;
    final next = make();
    await next.load();
    final again = next.decks.firstWhere((d) => d.id == 'cat-en-a1-family');
    expect(again.words.first.status, 'review');
    expect(catalog.fetched, 1);
  });

  test('the manifest is checked about once a day', () async {
    final state = make();
    await state.load();
    await state.refreshCatalog();
    catalog.version = 2;
    now = now.add(const Duration(hours: 2));
    await state.refreshCatalog();
    expect(catalog.fetched, 1);
    now = now.add(const Duration(days: 1));
    await state.refreshCatalog();
    expect(catalog.fetched, 2);
  });

  test('catalog words count as hifive decks, after the learner own', () async {
    final state = make();
    await state.load();
    await state.refreshCatalog();
    state.setNewPerDay(50);
    final fresh = state.today.fresh;
    expect(fresh.any((w) => w.id.startsWith('cat-en-')), isTrue);
  });

  test('a server without a catalog is asked again next time', () async {
    catalog.version = null;
    final state = make();
    await state.load();
    await state.refreshCatalog();
    catalog.version = 1;
    await state.refreshCatalog();
    expect(catalog.fetched, 1);
  });

  test('a forced refresh skips the daily wait', () async {
    final state = make();
    await state.load();
    await state.refreshCatalog();
    catalog.version = 2;
    await state.refreshCatalog(force: true);
    expect(catalog.fetched, 2);
  });
}
