import 'package:flutter/material.dart';

import '../config.dart';
import '../theme.dart';
import '../widgets/ui.dart';
import '../widgets/kovra_icons.dart';

/// 5.4 Shown after a successful purchase. No trial or renewal date: the store
/// doesn't give us one yet.
class UpgradeSuccessScreen extends StatelessWidget {
  /// Where to go next (Home after the splash paywall). Null = back to Home.
  final Widget? next;
  const UpgradeSuccessScreen({super.key, this.next});

  // Confetti specks: (x, y) in 0..1, size, angle.
  static const _specks = [
    (0.12, 0.17, 8.0, 0.4),
    (0.46, 0.13, 7.0, 0.2),
    (0.82, 0.19, 8.0, 0.7),
    (0.23, 0.26, 6.0, 0.9),
    (0.74, 0.31, 7.0, 0.3),
    (0.16, 0.50, 6.0, 0.6),
    (0.88, 0.48, 7.0, 0.1),
    (0.62, 0.08, 5.0, 0.5),
  ];

  void _done(BuildContext context) {
    final n = next;
    if (n != null) {
      Navigator.of(context).pushAndRemoveUntil(fadeRoute(n, settings: kHomeRoute), (_) => false);
    } else {
      popToHome(context); // closes this screen and anything opened above Home
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.kc;
    final size = MediaQuery.sizeOf(context);
    final pad = MediaQuery.paddingOf(context);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _done(context);
      },
      child: Scaffold(
        backgroundColor: c.primary,
        body: AnnotatedRegion(
          value: kLightBars,
          child: Stack(children: [
            const Positioned.fill(child: BrandDecoration()),
            for (final (x, y, s, a) in _specks)
              Positioned(
                left: x * size.width,
                top: y * size.height,
                child: Transform.rotate(
                  angle: a,
                  child: Container(
                    width: s,
                    height: s,
                    decoration:
                        BoxDecoration(color: Colors.white.withAlpha(140), borderRadius: BorderRadius.circular(2)),
                  ),
                ),
              ),
            Positioned.fill(
              child: Padding(
                padding: EdgeInsets.fromLTRB(28, pad.top, 28, 0),
                child: Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Container(
                      width: 104,
                      height: 104,
                      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                      child: Icon(PhosphorIconsBold.check, size: 48, color: c.primary),
                    ),
                    const SizedBox(height: 26),
                    Text("You're on ${AppConfig.proName}",
                        textAlign: TextAlign.center, style: KovraText.hero.copyWith(fontSize: 32, color: c.onPrimary)),
                    const SizedBox(height: 10),
                    Text(
                      'Pro locations are unlocked in your list. Thanks for supporting ${AppConfig.brand}.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 15.5, height: 1.45, color: c.onPrimary.withAlpha(220)),
                    ),
                  ]),
                ),
              ),
            ),
            Positioned(
              left: kPageX,
              right: kPageX,
              bottom: 28 + pad.bottom,
              child: KovraButton.white(label: 'Start using ${AppConfig.proName}', onPressed: () => _done(context)),
            ),
          ]),
        ),
      ),
    );
  }
}
