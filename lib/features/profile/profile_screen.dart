import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../core/design/design.dart';
import '../../domain/models/models.dart';
import '../../state/state.dart';
import '../../widgets/common.dart';
import '../information/information.dart';
import 'account_forms.dart';
import 'appearance_screen.dart';
import 'edit_profile_screen.dart';
import 'language_screen.dart';
import 'lesson_settings_screen.dart';
import 'notification_screen.dart';
import 'voice_screen.dart';

/// Layout measured against the reference on a 393 × 852 iPhone.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    void open(Widget page) => go<void>(context, page);
    return HeaderScrollPage(
      title: 'Profile',
      titleSize: 16.5,
      scrollKey: const ValueKey('profile-scroll'),
      padding: const EdgeInsets.fromLTRB(24, 127, 24, 105),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: PressFade(
              key: const ValueKey('profile-avatar'),
              onTap: () => open(const EditProfileScreen()),
              child: Column(
                children: [
                  const _Avatar(),
                  const SizedBox(height: 16),
                  Text(
                    s.name,
                    style: D.text(
                      22.5,
                      weight: FontWeight.w800,
                      height: 30 / 22.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 15.5),
          _TrialBanner(onTap: () => open(const PlusScreen())),
          const SizedBox(height: 49),
          const _Label('Đang học'),
          _Card(
            children: [
              _LanguageRow(
                language: s.language,
                level: s.level,
                onTap: () => open(const LanguageScreen()),
              ),
            ],
          ),
          const SizedBox(height: 30),
          const _Label('Cài đặt chung'),
          _Card(
            children: [
              _Row(
                'Chỉnh sửa hồ sơ',
                const _RowIcon(CupertinoIcons.person_crop_circle_fill),
                () => open(const EditProfileScreen()),
              ),
              _Row(
                'Cài đặt bài học',
                const CustomPaint(
                  size: Size.square(20),
                  painter: _ShapesGlyphPainter(),
                ),
                () => open(const LessonSettingsScreen()),
              ),
              _Row(
                'Giọng đọc',
                const CustomPaint(
                  size: Size.square(20),
                  painter: _WaveGlyphPainter(),
                ),
                () => open(const VoiceScreen()),
              ),
              _Row(
                'Giao diện',
                const CustomPaint(
                  size: Size.square(22),
                  painter: GearGlyphPainter(color: Palette.iconGrey),
                ),
                () => open(const AppearanceScreen()),
              ),
              _Row(
                'Thông báo',
                const _RowIcon(CupertinoIcons.bell_fill),
                () => open(const NotificationScreen()),
              ),
              _Row(
                'Gói đăng ký',
                const CustomPaint(
                  size: Size.square(20),
                  painter: _CardsGlyphPainter(),
                ),
                () => open(const PlusScreen()),
              ),
              _Row(
                'Nhập mã ưu đãi',
                const _RowIcon(CupertinoIcons.gift_fill),
                () => pageSheet<void>(context, const RedemptionForm()),
              ),
              _Row(
                'Mời bạn bè',
                const _RowIcon(Icons.share_rounded, size: 19),
                () => _system(context, s.system.shareInvite),
              ),
              _Row(
                'Đánh giá ứng dụng',
                const _RowIcon(CupertinoIcons.star_circle_fill, size: 21),
                () => pageSheet<void>(context, const ReviewForm()),
              ),
            ],
          ),
          const SizedBox(height: 23),
          const _Label('Khác'),
          _Card(
            children: [
              _Row(
                'Gửi phản hồi',
                const _RowIcon(Icons.email_rounded, size: 20),
                () => _system(context, s.system.composeFeedback),
              ),
              _Row(
                'Điều khoản dịch vụ',
                const CustomPaint(
                  size: Size(16, 19),
                  painter: _DocGlyphPainter(),
                ),
                () => _system(context, s.system.openTerms),
              ),
              _Row(
                'Chính sách quyền riêng tư',
                const CustomPaint(
                  size: Size(19, 21),
                  painter: ShieldPainter(color: Palette.iconGrey),
                ),
                () => open(const PrivacyScreen()),
              ),
            ],
          ),
          const SizedBox(height: 32),
          _LogoutRow(onTap: () => _signOut(context, s)),
          const SizedBox(height: 32),
          const _Footer(),
        ],
      ),
    );
  }

  /// Signs out after a confirmation. With sync, pending changes are pushed
  /// first and the device's copy is deleted; a failed push asks again.
  static Future<void> _signOut(BuildContext context, AppState s) async {
    if (s.user == null) {
      toast(context, 'Bạn chưa đăng nhập.');
      return;
    }
    final synced = s.syncService != null;
    final ok = await confirm(
      context,
      'Đăng xuất?',
      synced
          ? 'Dữ liệu học đã được lưu vào tài khoản và sẽ bị xoá khỏi máy này.'
          : 'Dữ liệu học trên máy này vẫn được giữ lại.',
      action: 'Đăng xuất',
      cancel: 'Huỷ',
      destructive: true,
    );
    if (!ok || !context.mounted) return;
    if (!await s.pushBeforeSignOut()) {
      if (!context.mounted) return;
      final anyway = await confirm(
        context,
        'Chưa đồng bộ xong',
        'Một số thay đổi chưa được lưu vào tài khoản và sẽ bị mất. Vẫn đăng xuất?',
        action: 'Vẫn đăng xuất',
        cancel: 'Huỷ',
        destructive: true,
      );
      if (!anyway) return;
    }
    // No toast: the gate swaps to the welcome screen, which says enough,
    // and a snack bar during that swap would show on two scaffolds.
    await s.signOut();
  }

  static Future<void> _system(
    BuildContext context,
    Future<bool> Function() action,
  ) async {
    final shown = await action();
    if (!shown && context.mounted) {
      toast(context, 'Thiết bị này chưa mở được mục này.');
    }
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar();
  @override
  Widget build(BuildContext context) => SizedBox(
    width: 98,
    height: 105,
    child: Stack(
      alignment: Alignment.topCenter,
      children: [
        Container(
          width: 98,
          height: 98,
          padding: const EdgeInsets.all(5.5),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Palette.insightDot, width: 3),
          ),
          child: Container(
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Palette.profileDisc,
            ),
            child: const Icon(
              CupertinoIcons.person_fill,
              size: 60,
              color: Palette.profileMuted,
            ),
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

/// The reference's trial banner: its second line changes every three seconds,
/// the old text sinking and fading as the new one rises into place.
class _TrialBanner extends StatefulWidget {
  final VoidCallback onTap;
  const _TrialBanner({required this.onTap});
  static const lines = [
    'Nâng cấp để có giới hạn cao hơn',
    'Truy cập sớm các tính năng mới',
    'Mở khóa toàn bộ sức mạnh AI',
  ];
  static const interval = Duration(seconds: 3);
  @override
  State<_TrialBanner> createState() => _TrialBannerState();
}

class _TrialBannerState extends State<_TrialBanner>
    with SingleTickerProviderStateMixin {
  late final _swap = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 467),
    value: 1,
  );
  late final Timer _timer = Timer.periodic(_TrialBanner.interval, (_) {
    if (!mounted) return;
    setState(() => _line = (_line + 1) % _TrialBanner.lines.length);
    _swap.forward(from: 0);
  });
  int _line = 0;

  @override
  void initState() {
    super.initState();
    _timer;
  }

  @override
  void dispose() {
    _timer.cancel();
    _swap.dispose();
    super.dispose();
  }

  Widget _text(int line, double offset, double opacity) => Transform.translate(
    offset: Offset(0, offset),
    child: Opacity(
      opacity: opacity.clamp(0, 1),
      child: SizedBox(
        width: 152,
        child: Text(
          _TrialBanner.lines[line],
          style: D.text(12.5, color: Colors.white, height: 16 / 12.5),
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) => ClipRSuperellipse(
    borderRadius: BorderRadius.circular(26),
    child: Container(
      height: 88,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Palette.trialStart, Palette.trialMiddle, Palette.trialEnd],
        ),
      ),
      child: Stack(
        children: [
          const Positioned.fill(child: BannerStars()),
          const Positioned(left: 23, top: 28, child: AppLogo(size: 36)),
          Positioned(
            left: 80,
            top: 19,
            child: Text(
              'Dùng thử Hifive Plus',
              style: D.text(
                14.3,
                weight: FontWeight.w700,
                color: Colors.white,
                height: 19 / 14.3,
              ),
            ),
          ),
          Positioned(
            left: 80,
            top: 39,
            child: AnimatedBuilder(
              animation: _swap,
              builder: (context, _) {
                final t = Curves.easeInOutSine.transform(_swap.value);
                final count = _TrialBanner.lines.length;
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    if (t < 1)
                      _text((_line + count - 1) % count, 32 * t, .95 * (1 - t)),
                    _text(_line, 32 * (1 - t), .95 * t),
                  ],
                );
              },
            ),
          ),
          Positioned(
            right: 12,
            top: 26,
            child: PressFade(
              key: const ValueKey('profile-trial'),
              onTap: widget.onTap,
              child: Container(
                width: 88,
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .2),
                  borderRadius: BorderRadius.circular(19),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: .55),
                    width: 1.4,
                  ),
                ),
                child: Text(
                  'Upgrade',
                  style: D.text(
                    13,
                    weight: FontWeight.w700,
                    color: Colors.white,
                    height: 1,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(left: 4, bottom: 11),
    child: Text(
      text,
      style: D.text(
        13,
        weight: FontWeight.w700,
        color: D.secondary,
        height: 17 / 13,
      ),
    ),
  );
}

class _Card extends StatelessWidget {
  final List<Widget> children;
  const _Card({required this.children});
  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    clipBehavior: Clip.antiAlias,
    shape: RoundedSuperellipseBorder(
      borderRadius: BorderRadius.circular(26),
      side: const BorderSide(color: Palette.profileEdge),
    ),
    child: Column(
      children: [
        for (final (i, child) in children.indexed)
          Stack(
            children: [
              child,
              if (i < children.length - 1)
                const Positioned(
                  left: 76,
                  right: 0,
                  bottom: 0,
                  child: Divider(height: 1, color: Palette.profileLine),
                ),
            ],
          ),
      ],
    ),
  );
}

class _RowIcon extends StatelessWidget {
  final IconData icon;
  final double size;
  const _RowIcon(this.icon, {this.size = 22});
  @override
  Widget build(BuildContext context) =>
      Icon(icon, size: size, color: Palette.iconGrey);
}

class _Row extends StatelessWidget {
  final String title;
  final Widget icon;
  final VoidCallback onTap;
  const _Row(this.title, this.icon, this.onTap);
  @override
  Widget build(BuildContext context) => PressFade(
    onTap: onTap,
    child: SizedBox(
      height: 81,
      child: Row(
        children: [
          const SizedBox(width: 20),
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: Palette.profileIconDisc,
              shape: BoxShape.circle,
            ),
            child: icon,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: D.text(13, weight: FontWeight.w700, height: 18 / 13),
            ),
          ),
          const Icon(
            CupertinoIcons.chevron_forward,
            size: 16,
            color: Palette.profileChevron,
          ),
          const SizedBox(width: 17),
        ],
      ),
    ),
  );
}

class _LanguageRow extends StatelessWidget {
  final Language language;
  final String level;
  final VoidCallback onTap;
  const _LanguageRow({
    required this.language,
    required this.level,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    final (flag, size) = languageFlag(language);
    return PressFade(
      key: const ValueKey('profile-language'),
      onTap: onTap,
      child: SizedBox(
        height: 81,
        child: Row(
          children: [
            const SizedBox(width: 22),
            CustomPaint(size: size, painter: flag),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    language.title,
                    style: D.text(17, weight: FontWeight.w600, height: 22 / 17),
                  ),
                  Text(
                    language.nativeTitle,
                    style: D.text(13, color: D.secondary, height: 17 / 13),
                  ),
                  const SizedBox(height: 2),
                ],
              ),
            ),
            Container(
              width: 32,
              height: 24,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: D.purple.withValues(alpha: .12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                level,
                style: D.text(
                  12,
                  weight: FontWeight.w700,
                  color: D.purple,
                  height: 1,
                ),
              ),
            ),
            const SizedBox(width: 20),
          ],
        ),
      ),
    );
  }
}

class _LogoutRow extends StatelessWidget {
  final VoidCallback onTap;
  const _LogoutRow({required this.onTap});
  @override
  Widget build(BuildContext context) => Material(
    color: Palette.logoutFill,
    clipBehavior: Clip.antiAlias,
    shape: RoundedSuperellipseBorder(
      borderRadius: BorderRadius.circular(26),
      side: const BorderSide(color: Palette.logoutEdge),
    ),
    child: PressFade(
      key: const ValueKey('profile-logout'),
      onTap: onTap,
      child: SizedBox(
        height: 80,
        child: Row(
          children: [
            const SizedBox(width: 20),
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const CustomPaint(
                size: Size(21, 20),
                painter: SignOutPainter(color: Palette.wrong),
              ),
            ),
            const SizedBox(width: 16),
            Text(
              'Đăng xuất',
              style: D.text(
                13,
                weight: FontWeight.w700,
                color: Palette.wrong,
                height: 18 / 13,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _Footer extends StatelessWidget {
  const _Footer();
  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      children: [
        const SizedBox(height: 33, child: Center(child: AppLogo(size: 24))),
        const SizedBox(height: 5),
        Text(
          'Hifive v1.0.0 (1)',
          style: D.text(
            10.5,
            weight: FontWeight.w600,
            color: Palette.insightFaint,
            spacing: 1,
            height: 14 / 10.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Bản sao cục bộ, không kết nối tài khoản.',
          style: D.text(10, color: Palette.profileMuted, height: 13 / 10),
        ),
      ],
    ),
  );
}

/// "Cài đặt bài học": two rounded shapes, a circle and three lines.
class _ShapesGlyphPainter extends CustomPainter {
  const _ShapesGlyphPainter();
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Palette.iconGrey;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(1, 1, 8, 8),
        const Radius.circular(2.5),
      ),
      paint,
    );
    canvas.drawPath(
      Path()
        ..moveTo(15, 1)
        ..lineTo(19.5, 9)
        ..lineTo(10.5, 9)
        ..close(),
      paint
        ..strokeWidth = 1
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(const Offset(5, 15), 4.2, paint);
    for (final y in const [11.5, 15.0, 18.5]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(11, y - .9, 8.5, 1.8),
          const Radius.circular(.9),
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_ShapesGlyphPainter oldDelegate) => false;
}

/// "Điều khoản dịch vụ": a rounded sheet with two lines cut out.
class _DocGlyphPainter extends CustomPainter {
  const _DocGlyphPainter();
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(4.5)),
      Paint()..color = Palette.iconGrey,
    );
    final line = Paint()
      ..color = Palette.profileIconDisc
      ..strokeWidth = 1.7
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(4.5, size.height * .4),
      Offset(size.width - 4.5, size.height * .4),
      line,
    );
    canvas.drawLine(
      Offset(4.5, size.height * .65),
      Offset(size.width - 7, size.height * .65),
      line,
    );
  }

  @override
  bool shouldRepaint(_DocGlyphPainter oldDelegate) => false;
}

/// "Giọng đọc": five vertical bars.
class _WaveGlyphPainter extends CustomPainter {
  const _WaveGlyphPainter();
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Palette.iconGrey
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;
    const heights = [6.0, 12.0, 19.0, 12.0, 6.0];
    for (final (i, height) in heights.indexed) {
      final x = 3.2 + i * 3.4;
      canvas.drawLine(
        Offset(x, 10 - height / 2),
        Offset(x, 10 + height / 2),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_WaveGlyphPainter oldDelegate) => false;
}

/// "Gói đăng ký": a card in front of the outline of another.
class _CardsGlyphPainter extends CustomPainter {
  const _CardsGlyphPainter();
  @override
  void paint(Canvas canvas, Size size) {
    final back = Paint()
      ..color = Palette.iconGrey
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.7
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(
      Path()
        ..moveTo(1.2, 11)
        ..lineTo(1.2, 5.5)
        ..quadraticBezierTo(1.2, 3, 3.8, 3)
        ..lineTo(13, 3),
      back,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(4, 6, 15.5, 11.5),
        const Radius.circular(3),
      ),
      Paint()..color = Palette.iconGrey,
    );
    canvas.drawRect(
      const Rect.fromLTWH(4, 8.8, 15.5, 1.4),
      Paint()..color = Palette.profileIconDisc,
    );
    canvas.drawRect(
      const Rect.fromLTWH(14, 13.2, 3.2, 1.4),
      Paint()..color = Palette.profileIconDisc,
    );
  }

  @override
  bool shouldRepaint(_CardsGlyphPainter oldDelegate) => false;
}
