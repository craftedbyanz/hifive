import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../core/design/design.dart';
import '../../domain/repositories/repositories.dart';
import '../../state/state.dart';
import '../../widgets/common.dart';

/// What each sign-in failure tells the learner. Cancelling says nothing.
String? authMessage(AuthError error) => switch (error) {
  AuthError.cancelled => null,
  AuthError.wrongCredentials => 'Email hoặc mật khẩu không đúng.',
  AuthError.emailInUse => 'Email này đã có tài khoản. Hãy đăng nhập.',
  AuthError.weakPassword => 'Mật khẩu cần ít nhất 6 ký tự.',
  AuthError.invalidEmail => 'Email không hợp lệ.',
  AuthError.tooManyRequests => 'Bạn thử quá nhiều lần. Vui lòng đợi một lát.',
  AuthError.network => 'Không có kết nối mạng. Vui lòng thử lại.',
  AuthError.unavailable => 'Cách đăng nhập này chưa được bật.',
  AuthError.unknown => 'Không đăng nhập được. Vui lòng thử lại.',
};

/// Sign in with Apple (when the build allows it), Google or an email and
/// password, or create an email account. The last page of [WelcomeScreen];
/// once signed in, [AuthGate] shows Home.
class SignInPanel extends StatefulWidget {
  const SignInPanel({super.key});
  @override
  State<SignInPanel> createState() => _SignInPanelState();
}

class _SignInPanelState extends State<SignInPanel> {
  final email = TextEditingController(), password = TextEditingController();
  bool creating = false, busy = false;

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  /// Runs one sign-in call; success needs no word, because the gate opens
  /// Home. [done] is said after calls that keep the learner here.
  Future<void> _run(Future<void> Function() call, {String? done}) async {
    setState(() => busy = true);
    try {
      await call();
      if (mounted && done != null) toast(context, done);
    } on AuthException catch (e) {
      final message = authMessage(e.error);
      if (mounted && message != null) toast(context, message);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  void _submit(AppState s) => _run(
    () => creating
        ? s.createAccount(email.text, password.text)
        : s.signInWithEmail(email.text, password.text),
  );

  void _reset(AppState s) {
    if (email.text.trim().isEmpty) {
      toast(context, 'Nhập email để nhận liên kết đặt lại mật khẩu.');
      return;
    }
    _run(
      () => s.sendPasswordReset(email.text),
      done: 'Đã gửi email đặt lại mật khẩu.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final ready =
        !busy && email.text.trim().isNotEmpty && password.text.isNotEmpty;
    return SingleChildScrollView(
      key: const ValueKey('sign-in-scroll'),
      padding: EdgeInsets.fromLTRB(
        24,
        12,
        24,
        24 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Center(child: AppLogo(size: 64)),
          const SizedBox(height: 20),
          Text(
            creating ? 'Tạo tài khoản Hifive' : 'Bắt đầu với Hifive',
            textAlign: TextAlign.center,
            style: D.text(24, weight: FontWeight.w800, height: 30 / 24),
          ),
          const SizedBox(height: 8),
          Text(
            'Lưu tiến độ và học tiếp trên mọi thiết bị.',
            textAlign: TextAlign.center,
            style: D.text(14, color: Palette.settingsMuted, height: 20 / 14),
          ),
          const SizedBox(height: 28),
          if (s.auth.supportsApple) ...[
            ActionButton(
              'Tiếp tục với Apple',
              key: const ValueKey('sign-in-apple'),
              icon: Icons.apple,
              onTap: busy ? null : () => _run(s.signInWithApple),
            ),
            const SizedBox(height: 12),
          ],
          ActionButton(
            'Tiếp tục với Google',
            key: const ValueKey('sign-in-google'),
            icon: Icons.g_mobiledata_rounded,
            outlined: true,
            color: D.ink,
            foreground: D.ink,
            onTap: busy ? null : () => _run(s.signInWithGoogle),
          ),
          const SizedBox(height: 26),
          const _OrDivider(),
          const SizedBox(height: 22),
          _Field(
            key: const ValueKey('sign-in-email'),
            controller: email,
            hint: 'Email',
            keyboard: TextInputType.emailAddress,
            onChanged: () => setState(() {}),
          ),
          const SizedBox(height: 12),
          _Field(
            key: const ValueKey('sign-in-password'),
            controller: password,
            hint: 'Mật khẩu',
            obscure: true,
            onChanged: () => setState(() {}),
            onSubmitted: ready ? () => _submit(s) : null,
          ),
          const SizedBox(height: 18),
          ActionButton(
            busy
                ? 'Đang xử lý...'
                : creating
                ? 'Tạo tài khoản'
                : 'Đăng nhập',
            key: const ValueKey('sign-in-submit'),
            onTap: ready ? () => _submit(s) : null,
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _Link(
                creating ? 'Đã có tài khoản? Đăng nhập' : 'Tạo tài khoản mới',
                key: const ValueKey('sign-in-mode'),
                onTap: busy ? null : () => setState(() => creating = !creating),
              ),
              if (!creating)
                _Link(
                  'Quên mật khẩu?',
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

class _OrDivider extends StatelessWidget {
  const _OrDivider();
  @override
  Widget build(BuildContext context) => Row(
    children: [
      const Expanded(child: Divider(color: Palette.settingsPanel)),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Text(
          'hoặc dùng email',
          style: D.text(12.5, color: Palette.settingsMuted, height: 16 / 12.5),
        ),
      ),
      const Expanded(child: Divider(color: Palette.settingsPanel)),
    ],
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

/// The account line on Profile: who is signed in, or an invitation to.
String accountTitle(AuthUser? user) => switch (user) {
  null => 'Đăng nhập',
  AuthUser(email: final String email) => email,
  AuthUser(displayName: final String name) => name,
  _ => 'Tài khoản của bạn',
};

String accountSubtitle(AuthUser? user) => switch (user?.method) {
  null => 'Lưu tiến độ trên nhiều thiết bị',
  AuthMethod.apple => 'Đã đăng nhập bằng Apple',
  AuthMethod.google => 'Đã đăng nhập bằng Google',
  AuthMethod.email => 'Đã đăng nhập bằng email',
};

/// The sign-in method's name, shown before the sync status.
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
String? syncStatus(AppState s) {
  if (s.user == null || s.syncService == null) return null;
  if (s.syncing) return 'Đang đồng bộ...';
  if (s.syncError != null) return 'Chưa đồng bộ được';
  final at = s.lastSyncedAt;
  if (at == null) return 'Chưa đồng bộ';
  final now = s.now();
  final hm =
      '${at.hour.toString().padLeft(2, '0')}:${at.minute.toString().padLeft(2, '0')}';
  return DateUtils.isSameDay(at, now)
      ? 'Đã đồng bộ lúc $hm'
      : 'Đã đồng bộ ${at.day}/${at.month}';
}
