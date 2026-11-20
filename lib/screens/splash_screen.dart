import 'package:flutter/material.dart';

import '../config.dart';
import '../theme.dart';
import '../widgets/glow_background.dart';
import '../widgets/logo.dart';
import '../widgets/signature.dart';
import 'home_screen.dart';
import 'paywall_screen.dart';

/// Loading screen shown on app start, then goes to Welcome.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  // The six-star mark draws itself quietly while the app loads.
  late final AnimationController _mark =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..forward();

  @override
  void dispose() {
    _mark.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // TODO(day2): load server list / settings here instead of a fixed wait.
    Future.delayed(const Duration(milliseconds: 1600), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 400),
          pageBuilder: (_, __, ___) => const PaywallScreen(next: HomeScreen()),
          transitionsBuilder: (_, a, __, child) => FadeTransition(opacity: a, child: child),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = context.kc;
    return Scaffold(
      body: GlowBackground(
        color: c.accent,
        child: Stack(
          children: [
            // Logo + name exactly in the centre of the screen.
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const KovraLogo(size: 112),
                  const SizedBox(height: 22),
                  Text(AppConfig.appName,
                      style: TextStyle(fontSize: 30, fontWeight: FontWeight.w700, letterSpacing: -0.3, color: c.text)),
                ],
              ),
            ),
            // Loader + tagline near the bottom.
            Positioned(
              left: 0,
              right: 0,
              bottom: 72 + MediaQuery.of(context).padding.bottom,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2.5, color: c.accent),
                  ),
                  const SizedBox(height: 14),
                  Text('Private by default', style: TextStyle(fontSize: 14, color: c.muted)),
                  const SizedBox(height: 14),
                  Opacity(
                    opacity: 0.45,
                    child: AnimatedBuilder(
                      animation: _mark,
                      builder: (_, __) => SizedBox(
                        width: 26,
                        height: 26,
                        child: CustomPaint(painter: DConstellation(_mark.value, c.accent, c.green, glow: false)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
