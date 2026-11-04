import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../core/design.dart';
import '../../widgets/blur_header.dart';
import '../../widgets/common.dart';
import '../../widgets/glyphs.dart';
import '../../widgets/press.dart';

/// The reference's policy text, kept as its visible copy. Its statements describe
/// the original service: this clone stores everything on the device.
class PrivacyScreen extends StatelessWidget {
  /// From the Plus screen the policy is a sheet with "Done", not a pushed page.
  final bool asSheet;
  const PrivacyScreen({super.key, this.asSheet = false});

  static Future<void> showSheet(BuildContext context) =>
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        showDragHandle: false,
        backgroundColor: Colors.transparent,
        barrierColor: Palette.sheetBarrier,
        elevation: 0,
        builder: (ctx) => SizedBox(
          height: MediaQuery.sizeOf(ctx).height - 58,
          child: const ClipRSuperellipse(
            borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
            child: PrivacyScreen(asSheet: true),
          ),
        ),
      );

  static const _sections = [
    (
      'Huấn luyện viên AI',
      'Hifive đồng bộ dữ liệu học tập của bạn lên cơ sở dữ liệu riêng tư để bạn có thể truy cập từ mọi nơi. Khi bạn sử dụng Huấn luyện viên AI, hệ thống sẽ xử lý các yêu cầu một cách bảo mật để đưa ra gợi ý, hoàn toàn không chia sẻ hay lưu trữ dữ liệu này cho mục đích khác.',
    ),
    (
      '1. Thông tin chúng tôi thu thập',
      'Chúng tôi thu thập thông tin để cung cấp dịch vụ tốt hơn cho tất cả người dùng. Bao gồm:\n• Dữ liệu cá nhân: Khi bạn đăng ký, chúng tôi có thể thu thập tên, địa chỉ email và ảnh đại diện của bạn.\n• Dữ liệu sử dụng: Chúng tôi thu thập thông tin về cách Dịch vụ được truy cập và sử dụng, chẳng hạn như loại thiết bị của bạn, phiên bản hệ điều hành và thời gian dành cho các trang.',
    ),
    (
      '2. Cách chúng tôi sử dụng thông tin của bạn',
      'Chúng tôi sử dụng dữ liệu đã thu thập cho nhiều mục đích khác nhau:\n• Để cung cấp và duy trì Dịch vụ của chúng tôi\n• Để thông báo cho bạn về những thay đổi đối với Dịch vụ của chúng tôi\n• Để cho phép bạn tham gia vào các tính năng tương tác khi bạn chọn làm như vậy\n• Để cung cấp hỗ trợ khách hàng\n• Để thu thập phân tích hoặc thông tin có giá trị để chúng tôi có thể cải thiện Dịch vụ của mình',
    ),
    (
      '3. Lưu giữ dữ liệu',
      'Hifive sẽ chỉ lưu giữ Dữ liệu cá nhân của bạn trong khoảng thời gian cần thiết cho các mục đích được nêu trong Chính sách quyền riêng tư này. Chúng tôi sẽ lưu giữ và sử dụng Dữ liệu cá nhân của bạn trong phạm vi cần thiết để tuân thủ các nghĩa vụ pháp lý của chúng tôi, giải quyết tranh chấp và thực thi các thỏa thuận và chính sách pháp lý của chúng tôi.',
    ),
    (
      '4. Bảo mật dữ liệu của bạn',
      'Bảo mật dữ liệu của bạn rất quan trọng đối với chúng tôi, nhưng hãy nhớ rằng không có phương thức truyền qua Internet hoặc phương thức lưu trữ điện tử nào là an toàn 100%. Mặc dù chúng tôi cố gắng sử dụng các phương tiện thương mại có thể chấp nhận được để bảo vệ Dữ liệu cá nhân của bạn, chúng tôi không thể đảm bảo tính bảo mật tuyệt đối của nó.',
    ),
    (
      '5. Quyền riêng tư của trẻ em',
      'Dịch vụ của chúng tôi không giải quyết bất kỳ ai dưới 13 tuổi. Chúng tôi không cố ý thu thập thông tin nhận dạng cá nhân từ bất kỳ ai dưới 13 tuổi. Nếu bạn là cha mẹ hoặc người giám hộ và bạn biết rằng Con bạn đã cung cấp cho chúng tôi Dữ liệu cá nhân, vui lòng liên hệ với chúng tôi.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final body = D.text(15.2, color: Palette.policyBody, height: 22.8 / 15.2);
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 6),
          child: SizedBox(
            width: 39,
            height: 48,
            child: FittedBox(
              child: CustomPaint(
                size: Size(19, 21),
                painter: ShieldPainter(color: Palette.policyHighlight),
              ),
            ),
          ),
        ),
        const SizedBox(height: 27),
        Text(
          'Hiểu những gì bạn cần,',
          style: D.text(31, weight: FontWeight.w800, height: 40 / 31),
        ),
        const SizedBox(height: 3),
        Padding(
          padding: const EdgeInsets.only(right: 44),
          child: Text(
            'chứ không phải bạn là ai',
            style: D.text(
              31,
              weight: FontWeight.w800,
              color: Palette.policyHighlight,
              height: 40 / 31,
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Cập nhật lần cuối: 07/01/2026',
          style: D.text(13.5, color: Palette.settingsMuted, height: 17 / 13.5),
        ),
        const SizedBox(height: 31),
        Text(
          'Quyền riêng tư của bạn là ưu tiên hàng đầu. Chúng tôi kinh doanh dựa trên sự ủng hộ (đăng ký) của bạn, không phải dữ liệu của bạn. Thông tin của bạn được lưu trữ an toàn trong cơ sở dữ liệu được mã hóa của chúng tôi. Chúng tôi tuyệt đối không chia sẻ dữ liệu cá nhân hay nội dung bạn sử dụng với AI cho bất kỳ bên thứ ba nào, và không sử dụng chúng để huấn luyện các mô hình AI công cộng.',
          style: body,
        ),
        for (final (title, text) in _sections) ...[
          const SizedBox(height: 24),
          Text(
            title,
            style: D.text(17, weight: FontWeight.w700, height: 22 / 17),
          ),
          const SizedBox(height: 11),
          Text(text, style: body),
        ],
        const SizedBox(height: 23),
        Text(
          'Liên hệ với chúng tôi',
          style: D.text(23.2, weight: FontWeight.w700, height: 30 / 23.2),
        ),
        const SizedBox(height: 15),
        Text(
          'Chúng mình luôn sẵn sàng lắng nghe bạn.',
          style: D.text(15.1, color: Palette.settingsMuted, height: 20 / 15.1),
        ),
        const SizedBox(height: 15),
        PressFade(
          key: const ValueKey('privacy-support'),
          // Never routes to the original app's developer.
          onTap: () => toast(context, 'Bản cục bộ không có email hỗ trợ.'),
          child: Container(
            height: 69,
            padding: const EdgeInsets.symmetric(horizontal: 18),
            decoration: ShapeDecoration(
              color: Colors.white,
              shape: RoundedSuperellipseBorder(
                borderRadius: BorderRadius.circular(20),
                side: const BorderSide(color: Palette.settingsPanel),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  CupertinoIcons.envelope_fill,
                  size: 26,
                  color: Palette.policyLink,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Email Hỗ trợ',
                        style: D.text(
                          13,
                          weight: FontWeight.w600,
                          height: 18 / 13,
                        ),
                      ),
                      Text(
                        'Không có ở bản cục bộ',
                        style: D.text(
                          13.5,
                          color: Palette.policyLink,
                          height: 19 / 13.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  CupertinoIcons.arrow_up_right,
                  size: 16,
                  color: Palette.settingsMuted,
                ),
              ],
            ),
          ),
        ),
      ],
    );
    if (!asSheet) {
      return HeaderScrollPage(
        title: 'Chính sách quyền riêng tư',
        titleSize: 16.5,
        padding: const EdgeInsets.fromLTRB(24, 161, 24, 121),
        child: content,
      );
    }
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 119, 24, 121),
            child: content,
          ),
          Positioned(
            left: 16,
            top: 27,
            child: Text(
              'Chính sách quyền riêng tư',
              style: D.text(16.5, weight: FontWeight.w700, height: 24 / 16.5),
            ),
          ),
          Positioned(
            right: 16,
            top: 17,
            child: PressFade(
              key: const ValueKey('privacy-done'),
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 65,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: Palette.sheetEdge),
                ),
                child: Text(
                  'Done',
                  style: D.text(15, weight: FontWeight.w600, height: 1),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
