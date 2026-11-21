import 'package:flutter/material.dart';

import '../config.dart';
import '../theme.dart';
import 'kovra_icons.dart';

/// The app's logo.
///
/// - White-label build with an uploaded logo: `assets/brand/custom_logo.png`.
/// - White-label build without one: a shield with the app's first letter, in
///   the customer's colours (so it never shows Kovra's mark).
/// - Kovra itself: the "shield + keyhole portal" mark, which changes with the
///   device time:
///     05:00–08:59  Dawn     (sunrise)
///     09:00–16:59  Minimal  (bright day)
///     17:00–19:59  Aurora   (evening)
///     20:00–04:59  Night    (official icon)
///   The home-screen icon itself always stays the official Night version.
class KovraLogo extends StatelessWidget {
  final double size;
  const KovraLogo({super.key, this.size = 30});

  static String assetForHour(int hour) {
    if (hour >= 5 && hour < 9) return 'assets/brand/logo_dawn.png';
    if (hour >= 9 && hour < 17) return 'assets/brand/logo_minimal.png';
    if (hour >= 17 && hour < 20) return 'assets/brand/logo_aurora.png';
    return 'assets/brand/logo_night.png';
  }

  @override
  Widget build(BuildContext context) {
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
          errorBuilder: (_, __, ___) => _InitialMark(size: size),
        ),
      );
    }
    if (AppConfig.isWhiteLabel) return _InitialMark(size: size);
    return Image.asset(
      assetForHour(DateTime.now().hour),
      width: size,
      height: size,
      filterQuality: FilterQuality.high,
      semanticLabel: AppConfig.appName,
      errorBuilder: (_, __, ___) => Image.asset('assets/brand/logo.png', width: size, height: size),
    );
  }
}

/// Shield with the app's first letter, for white-label builds without a logo.
class _InitialMark extends StatelessWidget {
  final double size;
  const _InitialMark({required this.size});

  @override
  Widget build(BuildContext context) {
    final c = context.kc;
    final name = AppConfig.appName.trim();
    final initial = name.isEmpty ? 'V' : name[0].toUpperCase();
    return Semantics(
      label: AppConfig.appName,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(size * 0.26),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [c.accent, c.deepBlue],
          ),
        ),
        child: Stack(alignment: Alignment.center, children: [
          Icon(PhosphorIconsFill.shield, size: size * 0.7, color: Colors.white.withAlpha(60)),
          Text(initial,
              style: TextStyle(fontSize: size * 0.36, fontWeight: FontWeight.w800, color: Colors.white, height: 1)),
        ]),
      ),
    );
  }
}
