import 'package:flutter/material.dart';

import '../config.dart';
import '../services/settings_controller.dart';
import '../theme.dart';
import '../widgets/ui.dart';
import 'home_screen.dart';
import '../widgets/kovra_icons.dart';

/// Shows the explainer the first time; true when the user chose to allow.
Future<bool> ensureVpnExplained(BuildContext context) async {
  if (settings.vpnExplained) return true;
  final ok = await Navigator.of(context).push<bool>(fadeRoute(const PermissionScreen(returnResult: true)));
  return ok == true;
}

/// 1.3 VPN permission explainer, shown once before Android's own VPN dialog.
class PermissionScreen extends StatelessWidget {
  /// true: pop with a bool (opened from a Connect button).
  /// false: onboarding step that hands off to Home.
  final bool returnResult;
  const PermissionScreen({super.key, this.returnResult = false});

  void _answer(BuildContext context, bool allow) {
    settings.setVpnExplained();
    if (returnResult) {
      Navigator.of(context).pop(allow);
      return;
    }
    Navigator.of(context).pushAndRemoveUntil(
      fadeRoute(HomeScreen(connectNow: allow, askedLater: !allow), settings: kHomeRoute),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.kc;
    final h = BrandSheetLayout.fit(context, 360);
    return PopScope(
      canPop: returnResult,
      child: Scaffold(
        body: BrandSheetLayout(
          brandHeight: h,
          brand: BrandArea(
            height: h,
            protected: true,
            child: Padding(
              padding: EdgeInsets.only(top: MediaQuery.paddingOf(context).top, bottom: kSheetOverlap),
              child: Center(
                child: IconTile(
                  icon: PhosphorIconsFill.key,
                  size: 96,
                  radius: 30,
                  background: Colors.white.withAlpha(38),
                  foreground: c.onPrimary,
                  iconSize: 46,
                ),
              ),
            ),
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(kPageX, 4, kPageX, 8),
            children: [
              Text('Before you connect', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: c.primary)),
              const SizedBox(height: 6),
              Text('Allow a VPN connection', style: KovraText.headline.copyWith(color: c.text)),
              const SizedBox(height: 8),
              Text('Android needs your OK before ${AppConfig.brand} can protect this phone.',
                  style: KovraText.body.copyWith(color: c.muted)),
              const SizedBox(height: 14),
              const PerkLine(icon: PhosphorIconsRegular.shieldCheck, text: 'Encrypts your traffic with OpenVPN'),
              const PerkLine(icon: PhosphorIconsRegular.toggleRight, text: 'You can turn it off at any time'),
              const SizedBox(height: 10),
              Text('Android will show a confirmation next. Tap OK to finish.',
                  style: KovraText.caption.copyWith(color: c.muted)),
            ],
          ),
          bottom: Column(mainAxisSize: MainAxisSize.min, children: [
            KovraButton.primary(label: 'Allow VPN connection', onPressed: () => _answer(context, true)),
            const SizedBox(height: 4),
            KovraButton.ghost(label: 'Not now', onPressed: () => _answer(context, false)),
          ]),
        ),
      ),
    );
  }
}
