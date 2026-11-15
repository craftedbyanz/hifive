import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../core/design/design.dart';
import '../../domain/repositories/repositories.dart';
import '../../l10n/l10n.dart';
import '../../state/state.dart';
import '../../widgets/common.dart';
import '../welcome/welcome.dart';
import 'settings_kit.dart';

/// The display name, the account (its email and how it signs in), and
/// account deletion. Sync runs on its own, so there is no sync row.
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});
  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  static const _maxName = 12;
  TextEditingController? name;
  var _deleting = false;

  /// Deletes the account after a red confirmation; an email account types
  /// its password, Google and Apple sign in again in their sheet. On
  /// success the learner lands on sign-in, as after signing out.
  Future<void> _delete(AppState s) async {
    final t = context.t;
    final sure = await confirm(
      context,
      t.deleteAccountTitle,
      t.deleteAccountConfirm,
      action: t.deleteAccountAction,
      cancel: t.cancel,
      destructive: true,
    );
    if (!sure || !mounted) return;
    String? password;
    if (s.user?.method == AuthMethod.email) {
      password = await sheet<String>(context, const _PasswordSheet());
      if (password == null || !mounted) return;
    }
    setState(() => _deleting = true);
    try {
      await s.deleteAccount(password: password);
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      Navigator.of(context).popUntil((r) => r.isFirst);
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(t.deleteAccountDone)));
    } on AuthException catch (e) {
      final message = authMessage(e.error, t);
      if (mounted && message != null) toast(context, message);
    } on Object {
      if (mounted) toast(context, t.deleteAccountFailed);
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  @override
  void dispose() {
    name?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    name ??= TextEditingController(text: s.name);
    final value = name!.text.trim();
    final canSave = value.isNotEmpty && value != s.name;
    return SettingsPage(
      title: context.t.profileEdit,
      background: Colors.white,
      padding: const EdgeInsets.fromLTRB(24, 135, 24, 140),
      footer: Padding(
        padding: settingsFooterPadding,
        child: SettingsCta(
          context.t.saveChanges,
          key: const ValueKey('profile-save'),
          color: canSave ? D.ink : Palette.saveDisabled,
          onTap: canSave
              ? () {
                  s.setName(value);
                  Navigator.pop(context);
                }
              : null,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Center(child: _BigAvatar()),
          const SizedBox(height: 35),
          Row(
            children: [
              Expanded(child: _FieldLabel(context.t.displayName)),
              Text(
                '${name!.text.characters.length}/$_maxName',
                style: D.text(
                  12,
                  weight: FontWeight.w600,
                  color: Palette.settingsMuted,
                  height: 15 / 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            key: const ValueKey('profile-name'),
            controller: name,
            maxLength: _maxName,
            onChanged: (_) => setState(() {}),
            style: D.text(15.5, height: 20 / 15.5),
            decoration: InputDecoration(
              counterText: '',
              filled: true,
              fillColor: Palette.settingsPage,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 13,
                vertical: 16,
              ),
              enabledBorder: _border(Palette.settingsPanel),
              focusedBorder: _border(Palette.ctaDisabled),
            ),
          ),
          const SizedBox(height: 24),
          _FieldLabel(context.t.emailAddress),
          const SizedBox(height: 8),
          _Box(
            height: 51,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    s.user?.email ?? context.t.noEmail,
                    style: D.text(
                      15.5,
                      color: Palette.settingsMuted,
                      height: 20 / 15.5,
                    ),
                  ),
                ),
                const Icon(
                  CupertinoIcons.lock_fill,
                  size: 16,
                  color: Palette.settingsHint,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _FieldLabel(context.t.signedInWith),
          const SizedBox(height: 11),
          _Box(
            height: 61,
            child: Row(
              children: [
                Icon(accountIcon(s.user), size: 24, color: D.ink),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(switch (s.user) {
                    final AuthUser u => accountMethod(u),
                    null => context.t.notSignedInShort,
                  }, style: D.text(15.5, height: 20 / 15.5)),
                ),
                if (s.user != null)
                  _Badge(
                    context.t.connected,
                    key: const ValueKey('profile-linked'),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 48),
          Text(
            context.t.dangerZone,
            style: D.text(
              13,
              weight: FontWeight.w600,
              color: Palette.dangerInk,
              height: 17 / 13,
            ),
          ),
          const SizedBox(height: 11),
          PressFade(
            key: const ValueKey('profile-delete'),
            onTap: s.user == null || _deleting ? null : () => _delete(s),
            child: Container(
              height: 68,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: ShapeDecoration(
                color: Palette.dangerFill,
                shape: RoundedSuperellipseBorder(
                  borderRadius: BorderRadius.circular(18),
                  side: const BorderSide(color: Palette.dangerEdge),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    CupertinoIcons.trash_fill,
                    size: 20,
                    color: Palette.dangerInk,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.t.deleteAccount,
                          style: D.text(
                            15,
                            weight: FontWeight.w600,
                            color: Palette.dangerInk,
                            height: 20 / 15,
                          ),
                        ),
                        Text(
                          context.t.deleteAccountBody,
                          style: D.text(
                            11.5,
                            color: Palette.dangerInk.withValues(alpha: .75),
                            height: 15 / 11.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_deleting)
                    Semantics(
                      label: context.t.deleteAccountWorking,
                      child: const CupertinoActivityIndicator(),
                    )
                  else
                    Icon(
                      CupertinoIcons.chevron_forward,
                      size: 16,
                      color: Palette.dangerInk.withValues(alpha: .7),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static OutlineInputBorder _border(Color color) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(18),
    borderSide: BorderSide(color: color),
  );
}

/// "Đã kết nối": a small pill tinted in the link blue.
class _Badge extends StatelessWidget {
  final String text;
  const _Badge(this.text, {super.key});
  @override
  Widget build(BuildContext context) => Container(
    height: 26,
    padding: const EdgeInsets.symmetric(horizontal: 12),
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: Palette.chatBlue.withValues(alpha: .1),
      borderRadius: BorderRadius.circular(13),
    ),
    child: Text(
      text,
      style: D.text(
        12,
        weight: FontWeight.w700,
        color: Palette.chatBlue,
        height: 1,
      ),
    ),
  );
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);
  @override
  Widget build(BuildContext context) => Text(
    text,
    style: D.text(13, weight: FontWeight.w600, height: 17 / 13),
  );
}

class _Box extends StatelessWidget {
  final double height;
  final Widget child;
  const _Box({required this.height, required this.child});
  @override
  Widget build(BuildContext context) => Container(
    height: height,
    padding: const EdgeInsets.symmetric(horizontal: 16),
    decoration: ShapeDecoration(
      color: Colors.white,
      shape: RoundedSuperellipseBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: Palette.settingsPanel),
      ),
    ),
    child: child,
  );
}

class _BigAvatar extends StatelessWidget {
  const _BigAvatar();
  @override
  Widget build(BuildContext context) => SizedBox(
    width: 124,
    height: 130,
    child: Stack(
      alignment: Alignment.topCenter,
      children: [
        Container(
          width: 122,
          height: 122,
          decoration: BoxDecoration(
            color: Palette.profileDisc,
            shape: BoxShape.circle,
            border: Border.all(color: Palette.settingsEdge, width: 3),
          ),
          child: const Icon(
            CupertinoIcons.person_fill,
            size: 80,
            color: Palette.profileMuted,
          ),
        ),
        Positioned(
          bottom: 0,
          child: Container(
            width: 39,
            height: 21,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Palette.profilePill,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Text(
              context.t.planFree,
              style: D.text(
                11,
                weight: FontWeight.w700,
                color: D.secondary,
                height: 1,
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

/// Asks an email account for its password before deleting it; pops with
/// the password, or nothing when closed.
class _PasswordSheet extends StatefulWidget {
  const _PasswordSheet();
  @override
  State<_PasswordSheet> createState() => _PasswordSheetState();
}

class _PasswordSheetState extends State<_PasswordSheet> {
  final _password = TextEditingController();

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  void _done() {
    if (_password.text.isEmpty) return;
    Navigator.of(context).pop(_password.text);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            t.deleteAccountPassword,
            style: D.text(18, weight: FontWeight.w800),
          ),
          const SizedBox(height: 14),
          TextField(
            key: const ValueKey('delete-password'),
            controller: _password,
            autofocus: true,
            obscureText: true,
            autocorrect: false,
            enableSuggestions: false,
            textInputAction: TextInputAction.done,
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) => _done(),
            decoration: const InputDecoration(
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
          ),
          const SizedBox(height: 16),
          ActionButton(
            t.deleteAccountAction,
            key: const ValueKey('delete-confirm'),
            color: Palette.dangerInk,
            onTap: _password.text.isEmpty ? null : _done,
          ),
        ],
      ),
    );
  }
}
