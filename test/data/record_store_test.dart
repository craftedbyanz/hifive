import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hifive/data/data.dart';
import 'package:hifive/domain/repositories/repositories.dart';
import 'package:hifive/domain/sync/sync.dart';

SyncRecord _r(String kind, String id, Object? v, int ms) =>
    SyncRecord(kind, id, v == null ? null : {'v': v}, Hlc(ms, 0, 'a'));

void main() {
  final stores = <String, RecordStore Function()>{
    'sqlite': SqliteRecordStore.open,
    'memory': MemoryRecordStore.new,
  };
  for (final MapEntry(key: name, value: make) in stores.entries) {
    group(name, () {
      test('keeps the record with the later stamp', () async {
        final store = make();
        await store.write([_r('setting', 'voice', 'Mia', 2)]);
        await store.write([_r('setting', 'voice', 'Aaron', 1)]);
        final all = await store.loadAll();
        expect(all.single.data, {'v': 'Mia'});
        await store.write([_r('setting', 'voice', 'Zoe', 3)]);
        expect((await store.loadAll()).single.data, {'v': 'Zoe'});
      });

      test('keeps deletions so they can sync', () async {
        final store = make();
        await store.write([_r('deck', 'd', 'x', 1), _r('deck', 'd', null, 2)]);
        final all = await store.loadAll();
        expect(all.single.deleted, isTrue);
        expect(all.single.hlc, const Hlc(2, 0, 'a'));
      });

      test('lists dirty records oldest first, up to a limit', () async {
        final store = make();
        await store.write([
          _r('setting', 'b', 'x', 3),
          _r('setting', 'a', 'x', 1),
          _r('device', 'sound', false, 2),
          _r('setting', 'c', 'x', 2),
        ]);
        final dirty = await store.dirtyRecords(limit: 2);
        expect(dirty.map((r) => r.id), ['a', 'c']);
      });

      test('pulled records are kept by stamp and never dirty', () async {
        final store = make();
        await store.write([_r('setting', 'name', 'Mine', 5)]);
        await store.applyRemote([
          _r('setting', 'name', 'Older', 4),
          _r('setting', 'voice', 'Mia', 9),
        ]);
        final all = {for (final r in await store.loadAll()) r.id: r.data};
        expect(all, {
          'name': {'v': 'Mine'},
          'voice': {'v': 'Mia'},
        });
        expect((await store.dirtyRecords()).map((r) => r.id), ['name']);
        await store.applyRemote([_r('setting', 'name', 'Newer', 6)]);
        expect(await store.dirtyRecords(), isEmpty);
      });

      test('marking synced spares records changed since the push', () async {
        final store = make();
        final pushed = [_r('setting', 'a', 1, 1), _r('setting', 'b', 1, 1)];
        await store.write(pushed);
        await store.write([_r('setting', 'b', 2, 2)]);
        await store.markSynced(pushed);
        expect((await store.dirtyRecords()).map((r) => r.id), ['b']);
      });

      test('clearing records keeps meta values', () async {
        final store = make();
        await store.write([_r('setting', 'a', 1, 1)]);
        await store.setMeta('deviceId', 'abc');
        await store.setMeta('syncCursor:u1', '4');
        await store.clearRecords();
        await store.deleteMeta('syncCursor:u1');
        expect(await store.loadAll(), isEmpty);
        expect(await store.dirtyRecords(), isEmpty);
        expect(await store.meta('deviceId'), 'abc');
        expect(await store.meta('syncCursor:u1'), isNull);
      });

      test('stores small values about the install', () async {
        final store = make();
        expect(await store.meta('deviceId'), isNull);
        await store.setMeta('deviceId', 'abc');
        await store.setMeta('deviceId', 'def');
        expect(await store.meta('deviceId'), 'def');
      });
    });
  }

  test('sqlite marks synced kinds dirty and survives reopening', () async {
    final dir = await Directory.systemTemp.createTemp('hifive-store');
    addTearDown(() => dir.delete(recursive: true));
    final path = '${dir.path}/records.db';
    final first = SqliteRecordStore.open(path);
    await first.write([
      _r(RecordKind.setting, 'name', 'Lan', 1),
      _r(RecordKind.device, 'sound', false, 1),
    ]);
    expect(first.dirtyKeys(), [(RecordKind.setting, 'name')]);
    first.close();
    final second = SqliteRecordStore.open(path);
    addTearDown(second.close);
    expect(await second.loadAll(), hasLength(2));
  });

  test('a failed write leaves earlier records whole', () async {
    final store = SqliteRecordStore.open();
    await store.write([_r('setting', 'name', 'Lan', 1)]);
    const bad = SyncRecord('setting', 'x', {'v': Object()}, Hlc(2, 0, 'a'));
    await expectLater(
      store.write([_r('setting', 'name', 'Mai', 3), bad]),
      throwsA(anything),
    );
    expect((await store.loadAll()).single.data, {'v': 'Lan'});
  });
}
