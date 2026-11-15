import 'dart:async';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../domain/repositories/auth_service.dart';

/// [AuthService] on Firebase Authentication (project `hifive-3371b`).
/// Apple uses the native sheet through Firebase; Google signs in with
/// `google_sign_in` and hands its ID token to Firebase.
class FirebaseAuthService implements AuthService {
  /// The iOS OAuth client, from `GoogleService-Info.plist`.
  final String? iosClientId;

  /// The project's web OAuth client, which Android needs to get an ID token.
  final String webClientId;

  /// Whether the build carries the Sign in with Apple entitlement, which a
  /// personal (free) Apple team can't have.
  final bool appleSignIn;
  final FirebaseAuth _auth;
  FirebaseAuthService({
    required this.iosClientId,
    required this.webClientId,
    this.appleSignIn = false,
    FirebaseAuth? auth,
  }) : _auth = auth ?? FirebaseAuth.instance;

  Future<void>? _googleReady;

  static AuthUser? _user(User? u) {
    if (u == null) return null;
    final providers = u.providerData.map((p) => p.providerId).toSet();
    return AuthUser(
      uid: u.uid,
      email: u.email,
      displayName: u.displayName,
      method: providers.contains('apple.com')
          ? AuthMethod.apple
          : providers.contains('google.com')
          ? AuthMethod.google
          : AuthMethod.email,
    );
  }

  @override
  AuthUser? get current => _user(_auth.currentUser);

  @override
  Stream<AuthUser?> get changes => _auth.authStateChanges().map(_user);

  @override
  bool get supportsApple => appleSignIn && Platform.isIOS;

  Future<AuthUser> _run(Future<UserCredential> Function() call) async {
    try {
      return _user((await call()).user)!;
    } on FirebaseAuthException catch (e) {
      throw AuthException(_error(e.code));
    } on GoogleSignInException catch (e) {
      throw AuthException(
        e.code == GoogleSignInExceptionCode.canceled
            ? AuthError.cancelled
            : AuthError.unknown,
      );
    } on SocketException {
      throw const AuthException(AuthError.network);
    }
  }

  static AuthError _error(String code) => switch (code) {
    'invalid-credential' ||
    'wrong-password' ||
    'user-not-found' ||
    'user-disabled' => AuthError.wrongCredentials,
    'email-already-in-use' ||
    'account-exists-with-different-credential' => AuthError.emailInUse,
    'weak-password' => AuthError.weakPassword,
    'invalid-email' || 'missing-email' => AuthError.invalidEmail,
    'too-many-requests' => AuthError.tooManyRequests,
    'network-request-failed' => AuthError.network,
    'operation-not-allowed' => AuthError.unavailable,
    _ when code.contains('cancel') => AuthError.cancelled,
    _ => AuthError.unknown,
  };

  @override
  Future<AuthUser> signInWithApple() => _run(
    () => _auth.signInWithProvider(
      AppleAuthProvider()
        ..addScope('email')
        ..addScope('name'),
    ),
  );

  @override
  Future<AuthUser> signInWithGoogle() => _run(() async {
    final google = GoogleSignIn.instance;
    await (_googleReady ??= google.initialize(
      clientId: Platform.isIOS ? iosClientId : null,
      serverClientId: webClientId,
    ));
    final account = await google.authenticate();
    final token = account.authentication.idToken;
    if (token == null) {
      throw FirebaseAuthException(code: 'missing-id-token');
    }
    return _auth.signInWithCredential(
      GoogleAuthProvider.credential(idToken: token),
    );
  });

  @override
  Future<AuthUser> signInWithEmail(String email, String password) => _run(
    () => _auth.signInWithEmailAndPassword(email: email, password: password),
  );

  @override
  Future<AuthUser> createAccount(String email, String password) => _run(
    () =>
        _auth.createUserWithEmailAndPassword(email: email, password: password),
  );

  @override
  Future<void> sendPasswordReset(String email) async {
    try {
      await _auth.setLanguageCode('vi');
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw AuthException(_error(e.code));
    }
  }

  @override
  Future<String?> idToken() async => _auth.currentUser?.getIdToken();

  @override
  Future<void> signOut() async {
    await _auth.signOut();
    if (_googleReady != null) {
      try {
        await GoogleSignIn.instance.signOut();
      } on GoogleSignInException {
        // Firebase is already signed out; a stale Google session is harmless.
      }
    }
  }
}
