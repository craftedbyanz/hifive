import 'dart:async';

import '../../domain/repositories/auth_service.dart';

/// Accounts kept in memory, for tests and builds without Firebase.
class MemoryAuthService implements AuthService {
  /// When set, the next call fails with it.
  AuthError? failNext;
  @override
  bool supportsApple;
  final _changes = StreamController<AuthUser?>.broadcast();
  AuthUser? _current;
  var _count = 0;
  MemoryAuthService({this.supportsApple = true, AuthUser? signedIn})
    : _current = signedIn;

  @override
  AuthUser? get current => _current;

  @override
  Stream<AuthUser?> get changes => _changes.stream;

  Future<AuthUser> _signIn(AuthMethod method, {String? email}) async {
    _check();
    final user = AuthUser(
      uid: 'user-${++_count}',
      method: method,
      email: email,
    );
    _current = user;
    _changes.add(user);
    return user;
  }

  void _check() {
    final error = failNext;
    if (error != null) {
      failNext = null;
      throw AuthException(error);
    }
  }

  @override
  Future<AuthUser> signInWithApple() => _signIn(AuthMethod.apple);

  @override
  Future<AuthUser> signInWithGoogle() => _signIn(AuthMethod.google);

  @override
  Future<String?> idToken() async =>
      _current == null ? null : 'token-${_current!.uid}';

  @override
  Future<void> signOut() async {
    _current = null;
    _changes.add(null);
  }
}
