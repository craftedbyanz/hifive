import 'package:flutter/material.dart';

/// Sizes measured at the default text size grow with a larger system text
/// size, as the reference's boxes do; at the default they are unchanged.
extension TextGrow on BuildContext {
  double grow(double value) => MediaQuery.textScalerOf(this).scale(value);
}
