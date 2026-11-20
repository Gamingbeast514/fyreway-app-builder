import 'package:flutter/material.dart';

import '../config.dart';
import '../theme.dart';

/// White-label logo: uses uploaded `assets/brand/custom_logo.png` if provided,
/// otherwise renders a dynamic branded shield using the active theme colors.
class KovraLogo extends StatelessWidget {
  final double size;
  const KovraLogo({super.key, this.size = 30});

  @override
  Widget build(BuildContext context) {
    final c = context.kc;
    if (AppConfig.hasCustomLogo) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(size * 0.24),
        child: Image.asset(
          'assets/brand/custom_logo.png',
          width: size,
          height: size,
          fit: BoxFit.cover,
          filterQuality: FilterQuality.high,
          semanticLabel: AppConfig.appName,
          errorBuilder: (_, __, ___) => _dynamicMark(c),
        ),
      );
    }
    return _dynamicMark(c);
  }

  Widget _dynamicMark(KovraColors c) {
    final initial = AppConfig.appName.isNotEmpty ? AppConfig.appName[0].toUpperCase() : 'V';
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.26),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [c.cyan, c.deepBlue],
        ),
        boxShadow: [
          BoxShadow(color: c.accent.withAlpha(70), blurRadius: size * 0.28, offset: Offset(0, size * 0.08)),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(Icons.shield_outlined, size: size * 0.62, color: Colors.white.withAlpha(230)),
          Text(
            initial,
            style: TextStyle(
              fontSize: size * 0.30,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}
