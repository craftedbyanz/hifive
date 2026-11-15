import 'package:flutter/services.dart';
import 'package:flutter_email_sender/flutter_email_sender.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

/// System surfaces the reference opens from Profile. Each returns whether the
/// surface could be shown.
abstract interface class SystemActions {
  /// The in-app browser, showing the terms page the reference points to.
  Future<bool> openTerms();

  /// The mail composer, addressed to hifive's feedback inbox
  /// ([PlatformSystemActions.feedbackEmail]).
  Future<bool> composeFeedback();

  /// The share sheet.
  Future<bool> shareInvite();

  /// This app's page in the system Settings.
  Future<bool> openAppSettings();

  /// The share sheet with a PNG picture and a line of text.
  Future<bool> shareImage(Uint8List png, String text);

  /// The share sheet with [text].
  Future<bool> shareText(String text);

  /// The in-app browser on the CC BY-SA 4.0 licence the dictionary data
  /// is published under.
  Future<bool> openDictionaryLicense();
}

class PlatformSystemActions implements SystemActions {
  static final termsUrl = Uri.parse(
    'https://www.apple.com/legal/internet-services/itunes/dev/stdeula/',
  );
  static final inviteUrl = Uri.parse('https://apps.apple.com/');

  /// Where "Hifive Feedback" mail goes.
  static const feedbackEmail = 'anznguyen.dev@gmail.com';
  static final dictionaryLicenseUrl = Uri.parse(
    'https://creativecommons.org/licenses/by-sa/4.0/',
  );
  const PlatformSystemActions();

  @override
  Future<bool> openDictionaryLicense() => _guard(
    () => launchUrl(dictionaryLicenseUrl, mode: LaunchMode.inAppBrowserView),
  );

  @override
  Future<bool> openTerms() =>
      _guard(() => launchUrl(termsUrl, mode: LaunchMode.inAppBrowserView));

  @override
  Future<bool> composeFeedback() => _guard(() async {
    await FlutterEmailSender.send(
      const Email(
        subject: 'Hifive Feedback',
        recipients: [feedbackEmail],
        isHTML: false,
      ),
    );
    return true;
  });

  @override
  Future<bool> shareInvite() => _guard(() async {
    await SharePlus.instance.share(ShareParams(uri: inviteUrl));
    return true;
  });

  @override
  Future<bool> openAppSettings() =>
      _guard(() => launchUrl(Uri.parse('app-settings:')));

  @override
  Future<bool> shareImage(Uint8List png, String text) => _guard(() async {
    await SharePlus.instance.share(
      ShareParams(
        text: text,
        files: [
          XFile.fromData(png, mimeType: 'image/png', name: 'hifive-garden.png'),
        ],
      ),
    );
    return true;
  });

  @override
  Future<bool> shareText(String text) => _guard(() async {
    await SharePlus.instance.share(ShareParams(text: text));
    return true;
  });

  static Future<bool> _guard(Future<bool> Function() action) async {
    try {
      return await action();
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }
}

/// Records calls instead of leaving the app. Used by tests.
class RecordingSystemActions implements SystemActions {
  final calls = <String>[];
  bool available = true;
  Future<bool> _record(String name) async {
    calls.add(name);
    return available;
  }

  @override
  Future<bool> openTerms() => _record('terms');
  @override
  Future<bool> openDictionaryLicense() => _record('dictionaryLicense');
  @override
  Future<bool> composeFeedback() => _record('feedback');
  @override
  Future<bool> shareInvite() => _record('invite');
  @override
  Future<bool> openAppSettings() => _record('settings');
  @override
  Future<bool> shareImage(Uint8List png, String text) => _record('image');

  /// The text of each [shareText], in order.
  final texts = <String>[];
  @override
  Future<bool> shareText(String text) {
    texts.add(text);
    return _record('text');
  }
}
