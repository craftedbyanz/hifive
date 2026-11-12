import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/design/design.dart';
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

/// Opens [EmailSignInForm] in a sheet over the sign-in screen.
Future<void> showEmailSignIn(BuildContext context) =>
    sheet<void>(context, const EmailSignInForm());

/// Sign in with an email and password, create an email account, or ask for
/// a password reset. Closes its sheet once signed in.
class EmailSignInForm extends StatefulWidget {
  const EmailSignInForm({super.key});
  @override
  State<EmailSignInForm> createState() => _EmailSignInFormState();
}

class _EmailSignInFormState extends State<EmailSignInForm> {
  final email = TextEditingController(), password = TextEditingController();
  bool creating = false, busy = false;

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() call, {String? done}) async {
    setState(() => busy = true);
    final ok = await runAuth(context, call, done: done);
    if (!mounted) return;
    setState(() => busy = false);
    if (ok && done == null) Navigator.of(context).maybePop();
  }

  void _submit(AppState s) => _run(
    () => creating
        ? s.createAccount(email.text, password.text)
        : s.signInWithEmail(email.text, password.text),
  );

  void _reset(AppState s) {
    if (email.text.trim().isEmpty) {
      toast(context, context.t.resetNeedsEmail);
      return;
    }
    _run(() => s.sendPasswordReset(email.text), done: context.t.resetSent);
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final ready =
        !busy && email.text.trim().isNotEmpty && password.text.isNotEmpty;
    return SingleChildScrollView(
      key: const ValueKey('sign-in-scroll'),
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            creating
                ? context.t.createAccountTitle
                : context.t.emailSignInTitle,
            style: D.text(22, weight: FontWeight.w800, height: 28 / 22),
          ),
          const SizedBox(height: 6),
          Text(
            context.t.emailSignInBody,
            style: D.text(14, color: Palette.settingsMuted, height: 20 / 14),
          ),
          const SizedBox(height: 22),
          _Field(
            key: const ValueKey('sign-in-email'),
            controller: email,
            hint: context.t.emailHint,
            keyboard: TextInputType.emailAddress,
            onChanged: () => setState(() {}),
          ),
          const SizedBox(height: 12),
          _Field(
            key: const ValueKey('sign-in-password'),
            controller: password,
            hint: context.t.passwordHint,
            obscure: true,
            onChanged: () => setState(() {}),
            onSubmitted: ready ? () => _submit(s) : null,
          ),
          const SizedBox(height: 18),
          ActionButton(
            busy
                ? context.t.working
                : creating
                ? context.t.createAccount
                : context.t.signIn,
            key: const ValueKey('sign-in-submit'),
            onTap: ready ? () => _submit(s) : null,
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _Link(
                creating
                    ? context.t.haveAccountSignIn
                    : context.t.createNewAccount,
                key: const ValueKey('sign-in-mode'),
                onTap: busy ? null : () => setState(() => creating = !creating),
              ),
              if (!creating)
                _Link(
                  context.t.forgotPassword,
                  key: const ValueKey('sign-in-reset'),
                  onTap: busy ? null : () => _reset(s),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final bool obscure;
  final TextInputType? keyboard;
  final VoidCallback onChanged;
  final VoidCallback? onSubmitted;
  const _Field({
    super.key,
    required this.controller,
    required this.hint,
    required this.onChanged,
    this.obscure = false,
    this.keyboard,
    this.onSubmitted,
  });
  static OutlineInputBorder _border(Color color) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(18),
    borderSide: BorderSide(color: color),
  );
  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    obscureText: obscure,
    autocorrect: false,
    enableSuggestions: !obscure,
    keyboardType: keyboard,
    textInputAction: obscure ? TextInputAction.done : TextInputAction.next,
    autofillHints: [obscure ? AutofillHints.password : AutofillHints.email],
    onChanged: (_) => onChanged(),
    onSubmitted: (_) => onSubmitted?.call(),
    style: D.text(15.5, height: 20 / 15.5),
    decoration: InputDecoration(
      hintText: hint,
      hintStyle: D.text(15.5, color: Palette.settingsHint, height: 20 / 15.5),
      filled: true,
      fillColor: Palette.settingsPage,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      enabledBorder: _border(Palette.settingsPanel),
      focusedBorder: _border(Palette.ctaDisabled),
    ),
  );
}

/// A text button with a 44 pt hit box.
class _Link extends StatelessWidget {
  final String text;
  final VoidCallback? onTap;
  const _Link(this.text, {super.key, required this.onTap});
  @override
  Widget build(BuildContext context) => PressFade(
    onTap: onTap,
    child: ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 44),
      child: Center(
        widthFactor: 1,
        child: Text(
          text,
          style: D.text(13.5, weight: FontWeight.w600, color: D.blue),
        ),
      ),
    ),
  );
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
