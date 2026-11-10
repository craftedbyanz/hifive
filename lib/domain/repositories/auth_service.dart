/// How a learner signed in.
enum AuthMethod { apple, google, email }

/// The signed-in learner.
class AuthUser {
  final String uid;
  final String? email, displayName;
  final AuthMethod method;
  const AuthUser({
    required this.uid,
    required this.method,
    this.email,
    this.displayName,
  });
}

/// Why sign-in failed, so screens can explain it in Vietnamese.
enum AuthError {
  cancelled,
  wrongCredentials,
  emailInUse,
  weakPassword,
  invalidEmail,
  tooManyRequests,
  network,
  unavailable,
  unknown,
}

class AuthException implements Exception {
  final AuthError error;
  const AuthException(this.error);
  @override
  String toString() => 'AuthException(${error.name})';
}

/// Accounts. Firebase Authentication backs it in the app; tests use a
/// memory version. Every method throws [AuthException] on failure.
abstract interface class AuthService {
  /// The learner signed in now, or null.
  AuthUser? get current;

  /// Emits whenever the learner signs in or out.
  Stream<AuthUser?> get changes;

  /// Whether this platform offers Sign in with Apple (iOS only for now).
  bool get supportsApple;

  Future<AuthUser> signInWithApple();
  Future<AuthUser> signInWithGoogle();
  Future<AuthUser> signInWithEmail(String email, String password);
  Future<AuthUser> createAccount(String email, String password);
  Future<void> sendPasswordReset(String email);
  Future<void> signOut();

  /// A fresh ID token for the API, or null when signed out.
  Future<String?> idToken();
}
