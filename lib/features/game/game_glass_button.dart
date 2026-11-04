import 'package:flutter/material.dart';

/// The round frosted button of the game pages.
class GameGlassButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool square;
  const GameGlassButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.square = false,
  });
  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: label,
    child: Tooltip(
      message: label,
      triggerMode: TooltipTriggerMode.manual,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .38),
            borderRadius: BorderRadius.circular(square ? 14 : 22),
            border: Border.all(color: Colors.white.withValues(alpha: .4)),
          ),
          child: Icon(icon, size: 24, weight: 700, color: Colors.white),
        ),
      ),
    ),
  );
}
