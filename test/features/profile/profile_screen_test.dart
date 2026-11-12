import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hifive/data/data.dart';
import 'package:hifive/features/information/information.dart';
import 'package:hifive/features/profile/profile.dart';
import 'package:hifive/widgets/common.dart';

import '../../helpers.dart';

const _tall = Size(393, 2100);

void main() {
  setUpAll(loadAppFonts);

  testWidgets('banner line changes every three seconds and cycles', (
    tester,
  ) async {
    await mount(tester, fresh(), const ProfileScreen(), size: _tall);
    const lines = [
      'Nâng cấp để có giới hạn cao hơn',
      'Truy cập sớm các tính năng mới',
      'Mở khóa toàn bộ sức mạnh AI',
    ];
    expect(find.text(lines[0]), findsOneWidget);
    expect(find.text(lines[1]), findsNothing);
    await tester.pump(const Duration(seconds: 2));
    expect(find.text(lines[1]), findsNothing);

    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(milliseconds: 200));
    // Both lines are on screen while they swap.
    expect(find.text(lines[0]), findsOneWidget);
    expect(find.text(lines[1]), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text(lines[0]), findsNothing);

    await tester.pump(const Duration(seconds: 3));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text(lines[2]), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text(lines[0]), findsOneWidget);
  });

  testWidgets('tapping the avatar opens profile editing', (tester) async {
    await mount(tester, fresh(), const ProfileScreen(), size: _tall);
    await tester.tap(find.byKey(const ValueKey('profile-avatar')));
    await tester.pumpAndSettle();
    expect(find.byType(EditProfileScreen), findsOneWidget);
  });

  testWidgets('the upgrade banner only opens the local Plus screen', (
    tester,
  ) async {
    await mount(tester, fresh(), const ProfileScreen(), size: _tall);
    await tester.tap(find.text('Upgrade'));
    await tester.pumpAndSettle();
    expect(find.byType(PlusScreen), findsOneWidget);
  });

  testWidgets('logout without an account changes nothing', (tester) async {
    final store = MemoryRecordStore();
    final state = fresh(store: store);
    state.name = 'Linh';
    await mount(tester, state, const ProfileScreen(), size: _tall);
    await tester.tap(find.byKey(const ValueKey('profile-logout')));
    await tester.pump();
    expect(find.text('Bạn chưa đăng nhập.'), findsOneWidget);
    expect(state.name, 'Linh');
    expect(find.byType(ProfileScreen), findsOneWidget);
    expect(store.records, isEmpty);
  });

  testWidgets('every settings row is listed in reference order', (
    tester,
  ) async {
    await mount(tester, fresh(), const ProfileScreen(), size: _tall);
    const rows = [
      'Chỉnh sửa hồ sơ',
      'Cài đặt bài học',
      'Giọng đọc',
      'Giao diện',
      'Thông báo',
      'Gói đăng ký',
      'Nhập mã ưu đãi',
      'Mời bạn bè',
      'Đánh giá ứng dụng',
      'Gửi phản hồi',
      'Điều khoản dịch vụ',
      'Chính sách quyền riêng tư',
    ];
    final ys = [for (final row in rows) tester.getTopLeft(find.text(row)).dy];
    expect(ys, orderedEquals([...ys]..sort()));
    expect(ys[1] - ys[0], closeTo(81, .5));
  });

  testWidgets('footer signs off under the version with the Vietnam flag', (
    tester,
  ) async {
    await mount(tester, fresh(), const ProfileScreen(), size: _tall);
    final version = tester.getTopLeft(find.text('Hifive v1.0.0 (2)')).dy;
    expect(
      tester.getTopLeft(find.text('Học một chút mỗi ngày')).dy,
      greaterThan(version),
    );
    final credit = find.byKey(const ValueKey('profile-credit'));
    expect(
      find.descendant(
        of: credit,
        matching: find.text('Develop and Design by Anz in VietNam'),
      ),
      findsOneWidget,
    );
    final flag = find.descendant(
      of: credit,
      matching: find.byType(VietnamFlag),
    );
    expect(tester.getSize(flag), const Size(18, 13));
    // The old local-copy note is gone.
    expect(find.textContaining('Bản sao cục bộ'), findsNothing);
  });
}
