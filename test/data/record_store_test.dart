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
