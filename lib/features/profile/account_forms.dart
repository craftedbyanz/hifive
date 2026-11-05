import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../core/design/design.dart';
import '../../widgets/common.dart';

/// Opens a full-height sheet like the system ones the reference presents.
Future<T?> pageSheet<T>(BuildContext context, Widget child) =>
    showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Palette.sheetBarrier,
      showDragHandle: false,
      elevation: 0,
      builder: (ctx) => SizedBox(
        height: MediaQuery.sizeOf(ctx).height - 58,
        child: ClipRSuperellipse(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
          child: ColoredBox(color: Colors.white, child: child),
        ),
      ),
    );

/// Three crossing strokes forming the store's "A".
class _StoreGlyphPainter extends CustomPainter {
  const _StoreGlyphPainter();
  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = s * .085
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(s * .38, s * .2), Offset(s * .72, s * .78), paint);
    canvas.drawLine(Offset(s * .62, s * .2), Offset(s * .28, s * .78), paint);
    canvas.drawLine(Offset(s * .2, s * .62), Offset(s * .8, s * .62), paint);
  }

  @override
  bool shouldRepaint(_StoreGlyphPainter oldDelegate) => false;
}

class _GlassButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback? onTap;
  const _GlassButton({
    super.key,
    required this.icon,
    required this.color,
    required this.label,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: label,
    child: PressFade(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: Palette.sheetEdge),
          boxShadow: [
            BoxShadow(
              color: D.ink.withValues(alpha: .06),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Icon(icon, size: 25, color: color),
      ),
    ),
  );
}

class _AppIcon extends StatelessWidget {
  final double size;
  const _AppIcon(this.size);
  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    alignment: Alignment.center,
    decoration: ShapeDecoration(
      color: Colors.white,
      shape: RoundedSuperellipseBorder(
        borderRadius: BorderRadius.circular(size * .23),
        side: const BorderSide(color: Palette.ctaDisabled),
      ),
    ),
    child: AppLogo(size: size * .86),
  );
}

/// Stands in for the system's offer code sheet. No code is sent anywhere.
class RedemptionForm extends StatefulWidget {
  const RedemptionForm({super.key});
  @override
  State<RedemptionForm> createState() => _RedemptionFormState();
}

class _RedemptionFormState extends State<RedemptionForm> {
  final _code = TextEditingController();

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasCode = _code.text.trim().isNotEmpty;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 17, 16, 12),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: Palette.storeBlue,
                  borderRadius: BorderRadius.circular(7),
                ),
                child: const CustomPaint(painter: _StoreGlyphPainter()),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'App Store',
                  style: D.text(
                    16,
                    weight: FontWeight.w600,
                    color: Colors.black,
                    height: 22 / 16,
                  ),
                ),
              ),
              _GlassButton(
                icon: Icons.close_rounded,
                color: Colors.black,
                label: 'Close',
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: Palette.sheetEdge),
        const SizedBox(height: 32),
        const _AppIcon(81),
        const SizedBox(height: 23),
        Text(
          'Hifive',
          style: D.text(
            15,
            weight: FontWeight.w600,
            color: Palette.storeInk,
            height: 23 / 15,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Redeem Offer',
          style: D.text(
            25,
            weight: FontWeight.w800,
            color: Colors.black,
            height: 38 / 25,
          ),
        ),
        const SizedBox(height: 17),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 38),
          child: TextField(
            key: const ValueKey('redeem-code'),
            controller: _code,
            onChanged: (_) => setState(() {}),
            style: D.text(15, color: Colors.black, height: 20 / 15),
            decoration: InputDecoration(
              hintText: 'Code',
              hintStyle: D.text(
                15,
                color: Palette.ctaDisabled,
                height: 20 / 15,
              ),
              filled: true,
              fillColor: Palette.storeField,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 15,
              ),
              enabledBorder: _border,
              focusedBorder: _border,
            ),
          ),
        ),
        const Spacer(),
        Padding(
          padding: EdgeInsets.fromLTRB(
            38,
            0,
            38,
            38 + MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: PressFade(
            key: const ValueKey('redeem-continue'),
            onTap: hasCode
                ? () {
                    final messenger = ScaffoldMessenger.of(context);
                    Navigator.pop(context);
                    messenger.showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Bản cục bộ không kết nối App Store hoặc đổi mã.',
                        ),
                      ),
                    );
                  }
                : null,
            child: Container(
              height: 52,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: hasCode ? Palette.storeAction : Palette.storeField,
                borderRadius: BorderRadius.circular(26),
                border: Border.all(color: Palette.sheetEdge),
              ),
              child: Text(
                'Continue',
                style: D.text(
                  15,
                  weight: FontWeight.w600,
                  color: hasCode ? Colors.white : Palette.settingsHint,
                  height: 1,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  static final _border = OutlineInputBorder(
    borderRadius: BorderRadius.circular(25),
    borderSide: BorderSide.none,
  );
}

/// Stands in for the App Store's review sheet, because the clone has no store
/// page. A review goes nowhere, and the message says so.
class ReviewForm extends StatefulWidget {
  const ReviewForm({super.key});
  @override
  State<ReviewForm> createState() => _ReviewFormState();
}

class _ReviewFormState extends State<ReviewForm> {
  int _stars = 0;

  @override
  Widget build(BuildContext context) {
    Widget field(String label, Key key) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          SizedBox(
            width: 78,
            child: Text(
              label,
              style: D.text(
                15,
                weight: FontWeight.w600,
                color: Colors.black,
                height: 20 / 15,
              ),
            ),
          ),
          Expanded(
            child: TextField(
              key: key,
              style: D.text(15, color: Colors.black, height: 20 / 15),
              decoration: InputDecoration(
                isCollapsed: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
                hintText: 'Optional',
                hintStyle: D.text(
                  15,
                  color: Palette.ctaDisabled,
                  height: 20 / 15,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
              ),
            ),
          ),
        ],
      ),
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _GlassButton(
                icon: CupertinoIcons.xmark,
                color: Palette.storeAction,
                label: 'Close',
                onTap: () => Navigator.pop(context),
              ),
              _GlassButton(
                key: const ValueKey('review-send'),
                icon: CupertinoIcons.arrow_up,
                color: _stars > 0 ? Palette.storeAction : Palette.ctaDisabled,
                label: 'Send',
                onTap: _stars > 0
                    ? () {
                        final messenger = ScaffoldMessenger.of(context);
                        Navigator.pop(context);
                        messenger.showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Bản cục bộ không gửi đánh giá đi đâu cả.',
                            ),
                          ),
                        );
                      }
                    : null,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Write a Review',
            style: D.text(
              20,
              weight: FontWeight.w800,
              color: Colors.black,
              height: 28 / 20,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const _AppIcon(59),
              const SizedBox(width: 11),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hifive',
                    style: D.text(
                      16,
                      weight: FontWeight.w700,
                      color: Colors.black,
                      height: 22 / 16,
                    ),
                  ),
                  Text(
                    'Education',
                    style: D.text(
                      12.5,
                      color: Palette.storeInk,
                      height: 17 / 12.5,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  'Tap to Rate:',
                  style: D.text(
                    12.5,
                    color: Palette.ctaDisabled,
                    height: 17 / 12.5,
                  ),
                ),
              ),
              for (var i = 1; i <= 5; i++)
                GestureDetector(
                  key: ValueKey('review-star-$i'),
                  behavior: HitTestBehavior.opaque,
                  onTap: () => setState(() => _stars = i),
                  child: Padding(
                    padding: const EdgeInsets.only(left: 11),
                    child: Icon(
                      i <= _stars
                          ? CupertinoIcons.star_fill
                          : CupertinoIcons.star,
                      size: 24,
                      color: Palette.storeAction,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 22),
          Container(
            decoration: ShapeDecoration(
              color: Palette.reviewField,
              shape: RoundedSuperellipseBorder(
                borderRadius: BorderRadius.circular(22),
              ),
            ),
            child: Column(
              children: [
                field('Title', const ValueKey('review-title')),
                const Divider(
                  height: 1,
                  indent: 12,
                  color: Palette.ctaDisabled,
                ),
                field('Review', const ValueKey('review-body')),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.only(left: 16),
            child: Row(
              children: [
                const Icon(
                  CupertinoIcons.add_circled_solid,
                  size: 20,
                  color: Palette.storeAction,
                ),
                const SizedBox(width: 12),
                Text(
                  'Add Nickname',
                  style: D.text(
                    13.5,
                    weight: FontWeight.w500,
                    color: Palette.storeAction,
                    height: 18 / 13.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
