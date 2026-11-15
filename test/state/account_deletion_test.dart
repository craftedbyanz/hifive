import 'package:flutter_test/flutter_test.dart';
import 'package:hifive/app/app.dart';
import 'package:hifive/data/data.dart';
import 'package:hifive/domain/repositories/repositories.dart';
import 'package:hifive/state/state.dart';

import '../sync_fakes.dart';

const _lan = AuthUser(uid: 'u1', method: AuthMethod.email, email: 'lan@x.vn');

void main() {
  late FakeSyncServer server;
  late MemoryRecordStore store;
  late MemoryAuthService auth;
  final opened = <AppState>[];

  setUp(() {
    server = FakeSyncServer();
    store = MemoryRecordStore();
    auth = MemoryAuthService(signedIn: _lan)..accounts['lan@x.vn'] = 'secret1';
  });
  tearDown(() {
    for (final s in opened) {
      s.dispose();
    }
    opened.clear();
  });

  Future<AppState> device() async {
    final s = createAppState(
      store: store,
      auth: auth,
      sync: server,
      feedback: SilentFeedback(),
      now: () => DateTime(2026, 11, 15, 9),
    );
    opened.add(s);
    await s.load();
    s.setName('Lan');
    s.rate(s.decks.first.words.first, 2);
    await s.sync();
    return s;
  }

  test(
    'deleting removes the server data, the account and this device copy',
    () async {
      final s = await device();
      expect(server.recordsOf('u1'), isNotEmpty);

      await s.deleteAccount(password: 'secret1');

      expect(server.deletedAccounts, ['u1']);
      expect(server.recordsOf('u1'), isEmpty);
      expect(auth.deleted, ['u1']);
      expect(auth.current, isNull);
      expect(s.user, isNull);
      expect(s.name, 'An');
      expect(await store.meta('accountUid'), isNull);
      expect(store.records.containsKey(('setting', 'name')), isFalse);
    },
  );

  test('a wrong password deletes nothing', () async {
    final s = await device();
    await expectLater(
      s.deleteAccount(password: 'nope'),
      throwsA(isA<AuthException>()),
    );
    expect(server.deletedAccounts, isEmpty);
    expect(auth.deleted, isEmpty);
    expect(s.user?.uid, 'u1');
    expect(s.name, 'Lan');
  });

  test('offline, the account stays and deleting again later works', () async {
    final s = await device();
    server.failBefore = SyncError.unavailable;
    await expectLater(
      s.deleteAccount(password: 'secret1'),
      throwsA(isA<SyncException>()),
    );
    expect(auth.deleted, isEmpty);
    expect(s.name, 'Lan');

    await s.deleteAccount(password: 'secret1');
    expect(auth.deleted, ['u1']);
    expect(s.user, isNull);
  });

  test(
    'a Google account is confirmed in its own sheet, without a password',
    () async {
      auth = MemoryAuthService(
        signedIn: const AuthUser(uid: 'g1', method: AuthMethod.google),
      );
      final s = await device();
      await s.deleteAccount();
      expect(auth.deleted, ['g1']);
      expect(server.deletedAccounts, ['g1']);
    },
  );

  test('a cancelled sign-in sheet deletes nothing', () async {
    auth = MemoryAuthService(
      signedIn: const AuthUser(uid: 'g1', method: AuthMethod.google),
    );
    final s = await device();
    auth.failNext = AuthError.cancelled;
    await expectLater(s.deleteAccount(), throwsA(isA<AuthException>()));
    expect(auth.deleted, isEmpty);
    expect(server.deletedAccounts, isEmpty);
  });
}
