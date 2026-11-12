import 'package:flutter/cupertino.dart';

import '../../core/design/design.dart';
import '../../l10n/l10n.dart';
import '../../state/state.dart';
import 'settings_kit.dart';

/// Picks the interface language: the device's, or one of [appLanguages].
/// It changes at once; lesson content keeps its own language.
class AppLanguageScreen extends StatelessWidget {
  const AppLanguageScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context), t = context.t;
    final options = [
      ('', t.appLanguageSystem),
      for (final code in appLanguages) (code, appLanguageNames[code]!),
    ];
    return SettingsPage(
      title: t.appLanguageTitle,
      padding: const EdgeInsets.fromLTRB(24, 120, 24, 60),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (code, name) in options) ...[
            SelectCard(
              key: ValueKey('app-language-${code.isEmpty ? 'system' : code}'),
              selected: s.appLanguage == code,
              height: 64,
              onTap: () => s.setAppLanguage(code),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 22),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        style: D.text(16, weight: FontWeight.w700),
                      ),
                    ),
                    if (s.appLanguage == code)
                      const Icon(
                        CupertinoIcons.checkmark_alt,
                        size: 20,
                        color: D.ink,
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
          const SizedBox(height: 8),
          Text(
            t.appLanguageHint,
            textAlign: TextAlign.center,
            style: D.text(13, color: Palette.settingsHint, height: 1.4),
          ),
        ],
      ),
    );
  }
}
