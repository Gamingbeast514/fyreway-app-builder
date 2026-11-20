import 'package:flutter/material.dart';

/// Soft colour wash from the top-left corner. Animates when [color] changes
/// (indigo-blue when off, green when protected).
class GlowBackground extends StatelessWidget {
  final Color color;
  final Widget child;
  const GlowBackground({super.key, required this.color, required this.child});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: const Alignment(0.4, 0.5),
          colors: [color.withAlpha(115), color.withAlpha(28), color.withAlpha(0)],
          stops: const [0, 0.45, 1],
        ),
      ),
      child: child,
    );
  }
}
