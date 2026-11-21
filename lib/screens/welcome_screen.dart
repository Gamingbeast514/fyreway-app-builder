import 'package:flutter/material.dart';

import '../config.dart';
import '../services/settings_controller.dart';
import '../theme.dart';
import '../widgets/logo.dart';
import '../widgets/ui.dart';
import 'permission_screen.dart';
import '../widgets/kovra_icons.dart';

/// 1.2 Welcome (first launch). Every line here is true for Kovra today.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  void _start(BuildContext context) {
    settings.setOnboarded();
    Navigator.of(context).pushReplacement(fadeRoute(const PermissionScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final c = context.kc;
    final h = BrandSheetLayout.fit(context, 400);
    final top = MediaQuery.paddingOf(context).top;
    return Scaffold(
      body: BrandSheetLayout(
        brandHeight: h,
        brand: BrandArea(
          height: h,
          protected: true,
          child: Padding(
            padding: EdgeInsets.only(top: top, bottom: kSheetOverlap),
            child: LayoutBuilder(
              builder: (context, box) => Stack(alignment: Alignment.center, children: [
                Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: SizedBox(
                      width: 200,
                      height: 200,
                      child: Stack(alignment: Alignment.center, children: [
                        for (final (d, a) in const [(200.0, 38), (150.0, 64)])
                          Container(
                            width: d,
                            height: d,
                            decoration: BoxDecoration(
                                shape: BoxShape.circle, border: Border.all(color: Colors.white.withAlpha(a))),
                          ),
                        Container(
                          width: 92,
                          height: 92,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withAlpha(38)),
                          child: const KovraLogo(size: 64),
                        ),
                      ]),
                    ),
                  ),
                ),
                // Decoration only: sample places on the map of locations.
                Positioned(left: 20, top: box.maxHeight * 0.48, child: const _FloatChip(code: 'JP', label: 'Japan')),
                Positioned(
                    right: 24, top: box.maxHeight * 0.22, child: const _FloatChip(code: 'US', label: 'New York')),
                Positioned(
                    right: 48, top: box.maxHeight * 0.74, child: const _FloatChip(code: 'DE', label: 'Frankfurt')),
              ]),
            ),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(kPageX, 4, kPageX, 8),
          children: [
            Text('Private browsing,\none tap away', style: KovraText.headline.copyWith(color: c.text)),
            const SizedBox(height: 12),
            const FeatureRow(
              icon: PhosphorIconsRegular.handTap,
              title: 'One-tap protection',
              subtitle: 'Connect to a free server in one tap',
            ),
            FeatureRow(
              icon: PhosphorIconsRegular.globeHemisphereWest,
              title: AppConfig.paywallEnabled ? 'Free and Pro locations' : 'Free locations',
              subtitle: AppConfig.paywallEnabled
                  ? 'Free volunteer servers, more with ${AppConfig.proName}'
                  : 'Free volunteer servers from VPN Gate',
            ),
            if (!AppConfig.adsEnabled)
              FeatureRow(
                icon: PhosphorIconsRegular.prohibit,
                title: 'No ads, ever',
                subtitle: AppConfig.paywallEnabled
                    ? '${AppConfig.brand} is paid for by Pro, not ads'
                    : 'Nothing gets in your way',
              ),
          ],
        ),
        bottom: Column(mainAxisSize: MainAxisSize.min, children: [
          KovraButton.primary(label: 'Start free', onPressed: () => _start(context)),
          const SizedBox(height: 12),
          Text('By continuing you agree to our Terms and Privacy Policy',
              textAlign: TextAlign.center, style: KovraText.caption.copyWith(fontSize: 12, color: c.muted)),
        ]),
      ),
    );
  }
}

class _FloatChip extends StatelessWidget {
  final String code, label;
  const _FloatChip({required this.code, required this.label});

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(color: Colors.white.withAlpha(46), borderRadius: BorderRadius.circular(999)),
        child: Text('${FlagCircle.flag(code)}  $label',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
      ),
    );
  }
}
