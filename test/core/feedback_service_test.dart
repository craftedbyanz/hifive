import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hifive/core/services/feedback_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late List<String?> haptics;
  setUp(() {
    haptics = [];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          if (call.method == 'HapticFeedback.vibrate') {
            haptics.add(call.arguments as String?);
          }
          return null;
        });
  });

  test('a button knock is not doubled by the control\'s own tap', () {
    final feedback = PlatformFeedback()..buttonTap();
    feedback.tap();
    expect(haptics, ['HapticFeedbackType.lightImpact']);
  });

  test('a control\'s own impact is not followed by a button knock', () {
    final feedback = PlatformFeedback()..impact(heavy: true);
    feedback.buttonTap();
    expect(haptics, ['HapticFeedbackType.heavyImpact']);
  });

  test('turning haptics off silences button knocks', () {
    (PlatformFeedback()..haptic = false).buttonTap();
    expect(haptics, isEmpty);
  });

  test('quick ticks of their own still all play', () {
    PlatformFeedback()
      ..tap()
      ..tap();
    expect(haptics, hasLength(2));
  });
}
