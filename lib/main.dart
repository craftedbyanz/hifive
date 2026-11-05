import 'package:flutter/material.dart';

import 'app/app.dart';
import 'data/data.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final state = createAppState(
    repository: LocalAppRepository(),
    includeExamples: true,
  );
  await state.load();
  runApp(HifiveApp(state: state));
}
