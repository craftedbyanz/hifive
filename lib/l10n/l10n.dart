import 'package:flutter/widgets.dart';

import 'gen/app_localizations.dart';

export 'gen/app_localizations.dart';

/// The app's interface languages, in the order the picker lists them.
/// Vietnamese is the fallback for any other device language.
const appLanguages = ['vi', 'en', 'zh', 'ko'];

/// Each language's own name, as the picker shows it.
const appLanguageNames = {
  'vi': 'Tiếng Việt',
  'en': 'English',
  'zh': '中文（简体）',
  'ko': '한국어',
};

const supportedAppLocales = [
  Locale('vi'),
  Locale('en'),
  Locale('zh'),
  Locale('ko'),
];

/// The chosen language as a locale, or null to follow the device.
Locale? appLocale(String code) =>
    appLanguages.contains(code) ? Locale(code) : null;

/// The first of the device's languages the app speaks, else Vietnamese.
Locale resolveAppLocale(List<Locale>? device) {
  for (final locale in device ?? const <Locale>[]) {
    if (appLanguages.contains(locale.languageCode)) {
      return Locale(locale.languageCode);
    }
  }
  return const Locale('vi');
}

extension AppText on BuildContext {
  /// The interface strings in the current language.
  AppLocalizations get t => AppLocalizations.of(this);
}
