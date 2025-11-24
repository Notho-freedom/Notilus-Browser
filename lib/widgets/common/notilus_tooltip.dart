import 'package:flutter/material.dart';
import '../../core/constants/notilus_colors.dart';

/// Tooltip personnalisé pour refléter l'identité visuelle de Notilus.
class NotilusTooltip extends StatelessWidget {
  final Widget child;
  final String message;
  final bool preferBelow;

  const NotilusTooltip({
    super.key,
    required this.child,
    required this.message,
    this.preferBelow = true,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: message,
      textStyle: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: Colors.white,
      ),
      decoration: BoxDecoration(
        color: NotilusColors.tooltipBackground,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(
          color: NotilusColors.neonRed.withOpacity(0.6),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: NotilusColors.neonRed.withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      waitDuration: const Duration(milliseconds: 250),
      preferBelow: preferBelow,
      child: child,
    );
  }
}

