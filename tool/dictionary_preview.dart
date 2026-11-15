// Opens the dictionary search alone, with the real pack downloaded from the
// Worker, for checking it on a simulator or device without signing in:
//   flutter run -t tool/dictionary_preview.dart -d <device> \
//     --dart-define=HIFIVE_API=https://hifive-api.hifive-worker.workers.dev \
//     --dart-define=Q=bank [--dart-define=ENTRY=1]
// Q is typed into the search; ENTRY opens the first result's page.
import 'package:flutter/material.dart';
import 'package:hifive/app/app.dart';
import 'package:hifive/core/design/design.dart';
import 'package:hifive/data/data.dart';
import 'package:hifive/features/flashcards/flashcards.dart';
import 'package:hifive/l10n/l10n.dart';
import 'package:hifive/state/state.dart';
import 'package:path_provider/path_provider.dart';

const _api = String.fromEnvironment('HIFIVE_API');
const _query = String.fromEnvironment('Q');
const _entry = bool.fromEnvironment('ENTRY');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final dir = await getApplicationSupportDirectory();
  final state = createAppState(
    store: MemoryRecordStore(),
    dictionaryStore: SqliteDictionaryStore(dir.path),
    dictionaryPacks: _api.isEmpty ? null : HttpDictionaryPacks(Uri.parse(_api)),
  );
  await state.load();
  final started = DateTime.now();
  await state.refreshDictionary(force: true);
  debugPrint(
    'dictionary-preview: ready=${state.dictionaryReady} '
    'in ${DateTime.now().difference(started).inMilliseconds} ms',
  );
  Widget home = const DictionaryScreen(query: _query);
  if (_entry && _query.isNotEmpty) {
    final hit = (await state.lookupWord(_query)).hits.firstOrNull;
    if (hit != null) home = DictionaryEntryScreen(entry: hit.entry);
  }
  final watch = Stopwatch()..start();
  await state.lookupWord(_query.isEmpty ? 'recieve' : _query);
  debugPrint('dictionary-preview: lookup ${watch.elapsedMilliseconds} ms');
  runApp(
    AppScope(
      state: state,
      child: MaterialApp(
        theme: D.theme,
        locale: const Locale('vi'),
        supportedLocales: supportedAppLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: home,
      ),
    ),
  );
}
