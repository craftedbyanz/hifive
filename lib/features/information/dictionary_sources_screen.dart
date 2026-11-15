import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../core/design/design.dart';
import '../../l10n/l10n.dart';
import '../../state/state.dart';
import '../../widgets/common.dart';

/// Credits for the dictionary's open sources, which their licences require
/// (docs/dictionary-plan.md, Licensing and attribution).
class DictionarySourcesScreen extends StatelessWidget {
  const DictionarySourcesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final sources = [
      t.dictSourceWiktionaryVi,
      t.dictSourceWiktionaryEn,
      t.dictSourceTatoeba,
      t.dictSourceCefr,
      t.dictSourceFrequency,
      t.dictSourceIpa,
    ];
    return AppPage(
      title: t.dictSourcesTitle,
      background: Palette.settingsPage,
      child: ListView(
        padding: EdgeInsets.fromLTRB(
          20,
          8,
          20,
          MediaQuery.paddingOf(context).bottom + 24,
        ),
        children: [
          Text(t.dictSourcesIntro, style: D.text(15, color: D.secondary)),
          const SizedBox(height: 16),
          Surface(
            radius: 22,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Column(
              children: [
                for (final (i, s) in sources.indexed) ...[
                  if (i > 0) const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(s, style: D.text(14.5)),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          PressFade(
            key: const ValueKey('dict-license'),
            onTap: () => AppScope.read(context).system.openDictionaryLicense(),
            child: SizedBox(
              height: 44,
              child: Row(
                children: [
                  const Icon(CupertinoIcons.doc_text, size: 18, color: D.blue),
                  const SizedBox(width: 8),
                  Text(
                    t.dictSourcesLicense,
                    style: D.text(15, weight: FontWeight.w600, color: D.blue),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
