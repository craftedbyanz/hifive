import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import 'app/app.dart';
import 'data/data.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final dir = await getApplicationSupportDirectory();
  final state = createAppState(
    store: SqliteRecordStore.open('${dir.path}/hifive.db'),
    legacy: LocalAppRepository(),
    includeExamples: true,
  );
  await state.load();
  runApp(HifiveApp(state: state));
}
