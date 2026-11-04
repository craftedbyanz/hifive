import 'package:flutter/widgets.dart';

/// Whether endless decorative motion may run. It is off unless the app turns it
/// on, because a looping animation keeps `pumpAndSettle` from finishing in tests.
class AmbientMotion extends InheritedWidget {
  final bool enabled;
  const AmbientMotion({super.key, required this.enabled, required super.child});

  static bool of(BuildContext context) =>
      // Not stopped by Reduce Motion: the reference keeps moving under it.
      context.dependOnInheritedWidgetOfExactType<AmbientMotion>()?.enabled ??
      false;

  @override
  bool updateShouldNotify(AmbientMotion oldWidget) =>
      enabled != oldWidget.enabled;
}
