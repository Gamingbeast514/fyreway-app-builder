import 'package:flutter/material.dart';

import '../config.dart';
import '../services/pro_controller.dart';
import '../services/settings_controller.dart';
import '../theme.dart';
import '../widgets/logo.dart';
import '../widgets/signature.dart';
import '../widgets/ui.dart';
import 'home_screen.dart';
import 'paywall_screen.dart';
import 'welcome_screen.dart';

/// 1.1 Splash: loads saved settings, then Welcome (first launch) or the
/// launch paywall / Home (returning users, as before).
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  // The six-star mark draws itself quietly while the app loads.
  late final AnimationController _mark = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))
    ..forward();
  late final AnimationController _dots = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))
    ..repeat();

  @override
  void dispose() {
    _mark.dispose();
    _dots.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    // Count the 1.6 s from the first painted frame, so slow starts (debug
    // builds, old phones) still show the splash and the mark drawing in.
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;
    _mark.forward(from: 0);
    await Future.wait([settings.load(), Future<void>.delayed(const Duration(milliseconds: 1600))]);
    if (!mounted) return;
    final Widget next;
    RouteSettings? rs;
    if (!settings.onboarded) {
      next = const WelcomeScreen();
    } else if (!pro.isPro && AppConfig.paywallEnabled) {
      next = const PaywallScreen(next: HomeScreen());
    } else {
      next = const HomeScreen();
      rs = kHomeRoute;
    }
    Navigator.of(context).pushReplacement(fadeRoute(next, settings: rs));
  }

  @override
  Widget build(BuildContext context) {
    final c = context.kc;
    final pad = MediaQuery.paddingOf(context);
    return Scaffold(
      backgroundColor: c.primary,
      body: AnnotatedRegion(
        value: kLightBars,
        child: Stack(
          children: [
            const Positioned.fill(child: BrandDecoration()),
            // Logo + name in the centre of the screen.
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 96,
                    height: 96,
                    padding: const EdgeInsets.all(12),
                    decoration:
                        BoxDecoration(color: Colors.white.withAlpha(38), borderRadius: BorderRadius.circular(30)),
                    child: const KovraLogo(size: 72),
                  ),
                  const SizedBox(height: 22),
                  Text(AppConfig.appName,
                      textAlign: TextAlign.center, style: KovraText.hero.copyWith(color: c.onPrimary)),
                  const SizedBox(height: 6),
                  Text('Private by default', style: TextStyle(fontSize: 15, color: c.onPrimary.withAlpha(204))),
                ],
              ),
            ),
            // Loader + the hidden mark near the bottom.
            Positioned(
              left: 0,
              right: 0,
              bottom: 40 + pad.bottom,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedBuilder(
                    animation: _dots,
                    builder: (_, __) => Row(mainAxisSize: MainAxisSize.min, children: [
                      for (var i = 0; i < 3; i++)
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withAlpha((_dots.value * 3).floor() == i ? 230 : 90),
                          ),
                        ),
                    ]),
                  ),
                  const SizedBox(height: 12),
                  Text('Getting things ready…', style: TextStyle(fontSize: 13, color: c.onPrimary.withAlpha(204))),
                  const SizedBox(height: 14),
                  // Same painter, timing and size as before. Drawn in white and
                  // violet so it still shows on the purple background.
                  Opacity(
                    opacity: 0.45,
                    child: AnimatedBuilder(
                      animation: _mark,
                      builder: (_, __) => SizedBox(
                        width: 26,
                        height: 26,
                        child: CustomPaint(painter: DConstellation(_mark.value, c.onAccent, c.green, glow: false)),
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
