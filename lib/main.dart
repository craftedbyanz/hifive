import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import 'app/app.dart';
import 'data/data.dart';
import 'firebase_options.dart';

/// The sync Worker's address, set with `--dart-define=HIFIVE_API=https://…`.
/// Without it the app runs offline-only and never syncs.
const _api = String.fromEnvironment('HIFIVE_API');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  final dir = await getApplicationSupportDirectory();
  final state = createAppState(
    store: SqliteRecordStore.open('${dir.path}/hifive.db'),
    legacy: LocalAppRepository(),
    auth: FirebaseAuthService(
      iosClientId: DefaultFirebaseOptions.currentPlatform.iosClientId,
      // Off until the Apple Developer Program: personal teams can't sign
      // Sign in with Apple. Re-add CODE_SIGN_ENTITLEMENTS when turning it on.
      appleSignIn: const bool.fromEnvironment('HIFIVE_APPLE_SIGN_IN'),
      // The web OAuth client from google-services.json (client_type 3).
      webClientId: '440247164777-9q60d3r0p8s09t13igr9cbin8o1n59t2.apps.googleusercontent.com',
    ),
    sync: _api.isEmpty ? null : HttpSyncService(Uri.parse(_api)),
    catalog: _api.isEmpty ? null : HttpCatalogRepository(Uri.parse(_api)),
    includeExamples: true,
  );
  await state.load();
  runApp(HifiveApp(state: state));
}
