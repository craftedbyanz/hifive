import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hifive/features/information/information.dart';
import 'package:hifive/features/profile/profile.dart';
import 'package:hifive/state/state.dart';
import 'package:hifive/widgets/common.dart';
import 'package:hifive/widgets/press.dart';

import 'helpers.dart';

const _tall = Size(393, 2100);

Future<(AppState, RecordingSystemActions)> _profile(WidgetTester tester) async {
  final system = RecordingSystemActions();
  final state = fresh(system: system);
  await mount(tester, state, const ProfileScreen(), size: _tall);
  return (state, system);
}

void main() {
  setUpAll(loadAppFonts);

  testWidgets(
    'only Upgrade responds on the trial banner, and it opens a cover',
    (tester) async {
      await _profile(tester);
      await tester.tap(find.text('Dùng thử Hifive Plus'));
      await tester.pumpAndSettle();
      expect(find.byType(PlusScreen), findsNothing);

      await tester.tap(find.text('Upgrade'));
      await tester.pumpAndSettle();
      expect(find.byType(PlusScreen), findsOneWidget);
      expect(
        ModalRoute.of(tester.element(find.byType(PlusScreen))),
        isA<CoverRoute<void>>(),
      );
    },
  );

  testWidgets('a long hold on the header button still goes back', (
    tester,
  ) async {
    await mount(
      tester,
      fresh(),
      Builder(
        builder: (context) => TextButton(
          onPressed: () => go<void>(context, const NotificationScreen()),
          child: const Text('open'),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.byType(NotificationScreen), findsOneWidget);
    final gesture = await tester.startGesture(
      tester.getCenter(find.byTooltip('Quay lại')),
    );
    await tester.pump(const Duration(milliseconds: 700));
    await gesture.up();
    await tester.pumpAndSettle();
    expect(find.byType(NotificationScreen), findsNothing);
  });

  testWidgets('a held row fades to the measured opacity and recovers', (
    tester,
  ) async {
    await _profile(tester);
    final row = find.ancestor(
      of: find.text('Giao diện'),
      matching: find.byType(PressFade),
    );
    double opacity() => tester
        .widget<AnimatedOpacity>(
          find.descendant(of: row, matching: find.byType(AnimatedOpacity)),
        )
        .opacity;
    expect(opacity(), 1);
    final gesture = await tester.startGesture(tester.getCenter(row));
    await tester.pump(const Duration(milliseconds: 200));
    expect(opacity(), PressFade.pressedOpacity);
    await gesture.moveBy(const Offset(0, 200));
    await tester.pump(const Duration(milliseconds: 200));
    expect(opacity(), 1, reason: 'dragging away cancels the press');
    await gesture.up();
    await tester.pumpAndSettle();
    expect(find.byType(AppearanceScreen), findsNothing);
  });

  for (final (label, call) in const [
    ('Điều khoản dịch vụ', 'terms'),
    ('Gửi phản hồi', 'feedback'),
    ('Mời bạn bè', 'invite'),
  ]) {
    testWidgets('$label opens its system surface and stays on Profile', (
      tester,
    ) async {
      final (_, system) = await _profile(tester);
      await tester.tap(find.text(label));
      await tester.pumpAndSettle();
      expect(system.calls, [call]);
      expect(find.byType(ProfileScreen), findsOneWidget);
      expect(find.byType(SnackBar), findsNothing);
    });
  }

  testWidgets('a system surface that cannot open says so', (tester) async {
    final (_, system) = await _profile(tester);
    system.available = false;
    await tester.tap(find.text('Gửi phản hồi'));
    await tester.pumpAndSettle();
    expect(find.byType(SnackBar), findsOneWidget);
  });

  testWidgets('privacy shows the policy without any contact address', (
    tester,
  ) async {
    await _profile(tester);
    await tester.tap(find.text('Chính sách quyền riêng tư'));
    await tester.pumpAndSettle();
    expect(find.byType(PrivacyScreen), findsOneWidget);
    expect(find.text('5. Quyền riêng tư của trẻ em'), findsOneWidget);
    expect(find.textContaining('@'), findsNothing);
  });

  testWidgets('from Plus, privacy is a sheet that Done closes', (tester) async {
    await mount(tester, fresh(), const PlusScreen(), size: _tall);
    await tester.tap(find.text('Quyền riêng tư'));
    await tester.pumpAndSettle();
    expect(find.text('5. Quyền riêng tư của trẻ em'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('privacy-done')));
    await tester.pumpAndSettle();
    expect(find.text('5. Quyền riêng tư của trẻ em'), findsNothing);
    expect(find.byType(PlusScreen), findsOneWidget);
  });

  testWidgets('a review needs a rating, then goes nowhere', (tester) async {
    await _profile(tester);
    await tester.tap(find.text('Đánh giá ứng dụng'));
    await tester.pumpAndSettle();
    expect(find.text('Write a Review'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('review-send')));
    await tester.pumpAndSettle();
    expect(find.byType(ReviewForm), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('review-star-4')));
    await tester.pump();
    expect(find.byIcon(CupertinoIcons.star_fill), findsNWidgets(4));
    await tester.tap(find.byKey(const ValueKey('review-send')));
    await tester.pumpAndSettle();
    expect(find.byType(ReviewForm), findsNothing);
    expect(find.textContaining('không gửi đánh giá'), findsOneWidget);
  });

  testWidgets('a coming-soon language swaps the footer until English returns', (
    tester,
  ) async {
    final state = fresh();
    await mount(tester, state, const LanguageScreen(), size: _tall);
    expect(find.text('A1 - Beginner'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('language-Korean')));
    await tester.pumpAndSettle();
    expect(find.text('Sắp ra mắt'), findsOneWidget);
    expect(find.text('Xác nhận'), findsNothing);
    expect(find.text('A1 - Beginner'), findsNothing);
    await tester.tap(find.text('Sắp ra mắt'));
    await tester.pumpAndSettle();
    expect(find.byType(LanguageScreen), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('language-English')));
    await tester.pumpAndSettle();
    expect(find.text('Xác nhận'), findsOneWidget);
    expect(find.text('A1 - Beginner'), findsOneWidget);
  });

  testWidgets('a level is only saved on confirm', (tester) async {
    final state = fresh();
    await mount(tester, state, const LevelPickerScreen(), size: _tall);
    await tester.tap(find.byKey(const ValueKey('level-B2')));
    await tester.pump();
    expect(state.level, 'A1');
    await tester.tap(find.text('Xác nhận'));
    await tester.pumpAndSettle();
    expect(state.level, 'B2');
  });

  testWidgets('a chosen voice is saved', (tester) async {
    final repository = MemoryAppRepository();
    final state = fresh(repository: repository);
    await mount(tester, state, const VoiceScreen(), size: _tall);
    expect(state.voice, 'Aaron');
    await tester.tap(find.byKey(const ValueKey('voice-Nicky')));
    await tester.pump();
    expect(state.voice, 'Nicky');
    expect(state.toJson()['voice'], 'Nicky');
  });

  testWidgets('voice help opens and its pill closes it', (tester) async {
    await mount(tester, fresh(), const VoiceScreen(), size: _tall);
    await tester.tap(find.bySemanticsLabel('Cách cài đặt giọng đọc'));
    await tester.pumpAndSettle();
    expect(find.text('Tải giọng Premium hoặc Enhanced'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('voice-help-close')));
    await tester.pumpAndSettle();
    expect(find.text('Tải giọng Premium hoặc Enhanced'), findsNothing);
  });

  testWidgets('the Plus button never purchases, and follows the chosen plan', (
    tester,
  ) async {
    await mount(tester, fresh(), const PlusScreen(), size: _tall);
    expect(find.text('Dùng thử 7 ngày • sau đó 349.000đ/năm'), findsOneWidget);
    await tester.tap(find.text('Hàng tháng'));
    await tester.pumpAndSettle();
    expect(find.text('Dùng thử 3 ngày • sau đó 49.000đ/tháng'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('plus-cta')));
    await tester.pump();
    expect(find.textContaining('không có giao dịch'), findsOneWidget);
    expect(find.byType(PlusScreen), findsOneWidget);
  });

  testWidgets('the Plus headline advances every three seconds and wraps', (
    tester,
  ) async {
    await mount(tester, fresh(), const PlusScreen(), size: _tall);
    expect(find.text('hifive'), findsOneWidget);
    for (final next in ['hạn mức', 'chinh phục', 'hifive']) {
      await tester.pump(const Duration(seconds: 3));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text(next), findsOneWidget);
    }
  });

  testWidgets('save waits for a changed name; delete erases nothing', (
    tester,
  ) async {
    final state = fresh()..name = 'Linh';
    await mount(tester, state, const EditProfileScreen(), size: _tall);
    expect(find.text('4/12'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('profile-save')));
    await tester.pumpAndSettle();
    expect(find.byType(EditProfileScreen), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('profile-delete')));
    await tester.pump();
    expect(find.text('Bản cục bộ không có tài khoản để xóa.'), findsOneWidget);
    expect(state.name, 'Linh');

    await tester.enterText(find.byKey(const ValueKey('profile-name')), 'Mai');
    await tester.pump();
    expect(find.text('3/12'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('profile-save')));
    await tester.pumpAndSettle();
    expect(state.name, 'Mai');
  });

  testWidgets('the appearance preview swipes to the next card', (tester) async {
    await mount(tester, fresh(), const AppearanceScreen(), size: _tall);
    await tester.drag(
      find.byKey(const ValueKey('appearance-preview')),
      const Offset(-250, 0),
    );
    await tester.pumpAndSettle();
    expect(find.text('Fix common mistakes instantly.'), findsOneWidget);
  });
}
