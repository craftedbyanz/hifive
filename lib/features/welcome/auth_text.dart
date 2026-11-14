import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../domain/repositories/repositories.dart';
import '../../l10n/l10n.dart';
import '../../state/state.dart';
import '../../widgets/common.dart';

/// What each sign-in failure tells the learner. Cancelling says nothing.
String? authMessage(AuthError error, AppLocalizations t) => switch (error) {
  AuthError.cancelled => null,
  AuthError.wrongCredentials => t.authWrongCredentials,
  AuthError.emailInUse => t.authEmailInUse,
  AuthError.weakPassword => t.authWeakPassword,
  AuthError.invalidEmail => t.authInvalidEmail,
  AuthError.tooManyRequests => t.authTooManyRequests,
  AuthError.network => t.authNetwork,
  AuthError.unavailable => t.authUnavailable,
  AuthError.unknown => t.authUnknown,
};

/// Runs one sign-in call and toasts its failure; cancelling says nothing.
/// Success needs no word, because [AuthGate] moves on. [done] is said after
/// calls that keep the learner where they are. True when the call succeeded.
Future<bool> runAuth(
  BuildContext context,
  Future<void> Function() call, {
  String? done,
}) async {
  final t = context.t;
  try {
    await call();
    if (context.mounted && done != null) toast(context, done);
    return true;
  } on AuthException catch (e) {
    final message = authMessage(e.error, t);
    if (context.mounted && message != null) toast(context, message);
    return false;
  }
}

/// The sign-in method's name, on Edit Profile.
String accountMethod(AuthUser user) => switch (user.method) {
  AuthMethod.apple => 'Apple',
  AuthMethod.google => 'Google',
  AuthMethod.email => 'Email',
};

IconData accountIcon(AuthUser? user) => switch (user?.method) {
  null => CupertinoIcons.person_crop_circle_badge_plus,
  AuthMethod.apple => Icons.apple,
  AuthMethod.google => Icons.g_mobiledata_rounded,
  AuthMethod.email => CupertinoIcons.mail_solid,
};

/// The sync line under the account, or null when there is nothing to say:
/// signed out, or a build without the sync API.
String? syncStatus(AppState s, AppLocalizations t) {
  if (s.user == null || s.syncService == null) return null;
  if (s.syncing) return t.syncing;
  if (s.syncError != null) return t.syncFailed;
  final at = s.lastSyncedAt;
  if (at == null) return t.neverSynced;
  final now = s.now();
  final hm =
      '${at.hour.toString().padLeft(2, '0')}:${at.minute.toString().padLeft(2, '0')}';
  return DateUtils.isSameDay(at, now)
      ? t.syncedAtTime(hm)
      : t.syncedOnDate(DateFormat.Md(t.localeName).format(at));
}
