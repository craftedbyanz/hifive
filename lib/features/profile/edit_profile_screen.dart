import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../core/design/design.dart';
import '../../domain/repositories/repositories.dart';
import '../../state/state.dart';
import '../../widgets/common.dart';
import '../welcome/welcome.dart';
import 'settings_kit.dart';

/// The display name, the account (its email, how it signs in and when it
/// last synced), and account deletion, which isn't built yet.
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});
  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  static const _maxName = 12;
  TextEditingController? name;

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
      title: 'Chỉnh sửa hồ sơ',
      background: Colors.white,
      padding: const EdgeInsets.fromLTRB(24, 135, 24, 140),
      footer: Padding(
        padding: settingsFooterPadding,
        child: SettingsCta(
          'Lưu thay đổi',
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
              const Expanded(child: _FieldLabel('Tên hiển thị')),
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
          const _FieldLabel('Địa chỉ Email'),
          const SizedBox(height: 8),
          _Box(
            height: 51,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    s.user?.email ?? 'Tài khoản không có email',
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
          const _FieldLabel('Kết nối qua'),
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
                    null => 'Chưa đăng nhập',
                  }, style: D.text(15.5, height: 20 / 15.5)),
                ),
                if (s.user != null)
                  const _Badge('Đã kết nối', key: ValueKey('profile-linked')),
              ],
            ),
          ),
          if (syncStatus(s) case final String status) ...[
            const SizedBox(height: 24),
            const _FieldLabel('Đồng bộ'),
            const SizedBox(height: 11),
            _Box(
              height: 61,
              child: Row(
                children: [
                  const Icon(
                    CupertinoIcons.arrow_2_circlepath,
                    size: 22,
                    color: D.ink,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      status,
                      key: const ValueKey('profile-sync-status'),
                      style: D.text(15.5, height: 20 / 15.5),
                    ),
                  ),
                  if (!s.syncing)
                    PressFade(
                      key: const ValueKey('profile-sync-now'),
                      onTap: s.sync,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(minHeight: 44),
                        child: Center(
                          widthFactor: 1,
                          child: Text(
                            'Đồng bộ ngay',
                            style: D.text(
                              13,
                              weight: FontWeight.w700,
                              color: Palette.chatBlue,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 48),
          Text(
            'Vùng nguy hiểm',
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
            // Deletion comes before release (docs/backend-plan.md).
            onTap: () => toast(
              context,
              'Xóa tài khoản sẽ có trong bản phát hành chính thức.',
            ),
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
                          'Xóa tài khoản',
                          style: D.text(
                            15,
                            weight: FontWeight.w600,
                            color: Palette.dangerInk,
                            height: 20 / 15,
                          ),
                        ),
                        Text(
                          'Xóa vĩnh viễn tất cả dữ liệu của bạn',
                          style: D.text(
                            11.5,
                            color: Palette.dangerInk.withValues(alpha: .75),
                            height: 15 / 11.5,
                          ),
                        ),
                      ],
                    ),
                  ),
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
              'Free',
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
