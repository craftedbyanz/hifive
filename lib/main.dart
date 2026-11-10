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
    auth: FirebaseAuthService(
      iosClientId: DefaultFirebaseOptions.currentPlatform.iosClientId,
      // The web OAuth client from google-services.json (client_type 3).
      webClientId: '440247164777-9q60d3r0p8s09t13igr9cbin8o1n59t2.apps.googleusercontent.com',
    ),
    includeExamples: true,
  );
  await state.load();
  runApp(HifiveApp(state: state));
}
