import 'package:flutter/material.dart';

import '../theme.dart';

/// Country flag in a round chip (e.g. "DE" -> German flag). "AUTO" shows a rocket.
class CodeBadge extends StatelessWidget {
  final String code;
  final double size;
  const CodeBadge({super.key, required this.code, this.size = 40});

  static String flag(String cc) {
    if (cc.length != 2) return cc;
    final up = cc.toUpperCase();
    return String.fromCharCodes(up.codeUnits.map((u) => 0x1F1E6 + (u - 0x41)));
  }

  @override
  Widget build(BuildContext context) {
    final c = context.kc;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: c.badge, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: code == 'AUTO'
          ? Icon(Icons.rocket_launch_outlined, size: size * 0.5, color: c.accent)
          : Text(flag(code), style: TextStyle(fontSize: size * 0.52, height: 1.1)),
    );
  }
}
