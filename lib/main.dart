import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import 'app/app.dart';
import 'data/data.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  final dir = await getApplicationSupportDirectory();
  final state = createAppState(
    store: SqliteRecordStore.open('${dir.path}/hifive.db'),
    legacy: LocalAppRepository(),
    includeExamples: true,
  );
  await state.load();
  runApp(HifiveApp(state: state));
}
