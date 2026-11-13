import 'package:flutter/material.dart';

import '../core/design/design.dart';
import '../features/home/home.dart';
import '../features/welcome/welcome.dart';
import '../l10n/l10n.dart';
import '../state/state.dart';
import '../widgets/ambient.dart';
import '../widgets/app_scroll.dart';
import '../widgets/reminder_sync.dart';
import '../widgets/tap_feedback.dart';

class HifiveApp extends StatelessWidget {
  final AppState state;
  final bool animateAmbient;
  const HifiveApp({super.key, required this.state, this.animateAmbient = true});
  @override
  Widget build(BuildContext context) => _Lifecycle(
    state: state,
    child: AppScope(
      state: state,
      child: ListenableBuilder(
        listenable: state,
        builder: (context, _) => MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'hifive',
          theme: D.theme,
          // Empty follows the device, falling back to Vietnamese.
          locale: appLocale(state.appLanguage),
          localeListResolutionCallback: (device, _) => resolveAppLocale(device),
          supportedLocales: supportedAppLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          scrollBehavior: const AppScrollBehavior(),
          builder: (context, child) => ReminderSync(
            child: TapFeedback(
              onTap: state.feedback.buttonTap,
              child: AmbientMotion(
                enabled: animateAmbient,
                child: textScaling(child!),
              ),
            ),
          ),
          home: AuthGate(child: HomeScreen(animateAmbient: animateAmbient)),
        ),
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
