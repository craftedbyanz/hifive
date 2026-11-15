import 'dart:async';

import '../../domain/repositories/auth_service.dart';

/// Accounts kept in memory, for tests and builds without Firebase.
class MemoryAuthService implements AuthService {
  /// Email accounts by address, with their passwords.
  final accounts = <String, String>{};

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
  Future<AuthUser> signInWithEmail(String email, String password) async {
    _check();
    if (accounts[email] != password) {
      throw const AuthException(AuthError.wrongCredentials);
    }
    return _signIn(AuthMethod.email, email: email);
  }

  @override
  Future<AuthUser> createAccount(String email, String password) async {
    _check();
    if (accounts.containsKey(email)) {
      throw const AuthException(AuthError.emailInUse);
    }
    if (password.length < 6) {
      throw const AuthException(AuthError.weakPassword);
    }
    accounts[email] = password;
    return _signIn(AuthMethod.email, email: email);
  }

  /// Addresses a reset email was sent to.
  final resetsSent = <String>[];

  @override
  Future<void> sendPasswordReset(String email) async {
    _check();
    resetsSent.add(email);
  }

  @override
  Future<String?> idToken() async =>
      _current == null ? null : 'token-${_current!.uid}';

  @override
  Future<void> signOut() async {
    _current = null;
    _changes.add(null);
  }
}
