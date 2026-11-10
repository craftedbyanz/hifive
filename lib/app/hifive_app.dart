import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../core/design/design.dart';
import '../features/home/home.dart';
import '../state/state.dart';
import '../widgets/ambient.dart';
import '../widgets/app_scroll.dart';

class HifiveApp extends StatelessWidget {
  final AppState state;
  final bool animateAmbient;
  const HifiveApp({super.key, required this.state, this.animateAmbient = true});
  @override
  Widget build(BuildContext context) => _Lifecycle(
    state: state,
    child: AppScope(
      state: state,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'hifive',
        theme: D.theme,
        locale: const Locale('vi'),
        supportedLocales: const [Locale('vi'), Locale('en')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        scrollBehavior: const AppScrollBehavior(),
        builder: (context, child) =>
            AmbientMotion(enabled: animateAmbient, child: textScaling(child!)),
        home: HomeScreen(animateAmbient: animateAmbient),
      ),
    ),
  );
}

/// Tells [AppState] when the app returns to or leaves the screen, which is
/// when it syncs with the learner's other devices.
class _Lifecycle extends StatefulWidget {
  final AppState state;
  final Widget child;
  const _Lifecycle({required this.state, required this.child});
  @override
  State<_Lifecycle> createState() => _LifecycleState();
}

class _LifecycleState extends State<_Lifecycle> {
  late final AppLifecycleListener _listener = AppLifecycleListener(
    onResume: widget.state.appResumed,
    onPause: widget.state.appPaused,
  );

  @override
  void initState() {
    super.initState();
    _listener;
  }

  @override
  void dispose() {
    _listener.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// The reference keeps its type size under a smaller system text size but
/// grows with a larger one: at the largest standard size (xxxLarge) its text
/// was about 1.38 times wider (physical iPhone, 4 November 2026). Accessibility
/// sizes beyond that were not seen, so the scale stops at xxxLarge's 23/17.
Widget textScaling(Widget child) => Builder(
  builder: (context) => MediaQuery.withClampedTextScaling(
    minScaleFactor: 1,
    maxScaleFactor: 23 / 17,
    child: child,
  ),
);
