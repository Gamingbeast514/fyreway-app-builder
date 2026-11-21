import 'package:flutter/material.dart';

import '../config.dart';
import '../models/server.dart';
import '../screens/paywall_screen.dart';
import '../theme.dart';
import 'ui.dart';
import 'kovra_icons.dart';

/// 5.2 Premium location: overlay shown when a free user taps a Pro location.
Future<void> showProLocationSheet(BuildContext context, VpnServer s) {
  return showOverlaySheet<void>(
    context,
    builder: (ctx) {
      final c = ctx.kc;
      final name = s.isAuto ? s.country : s.displayName;
      return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const SizedBox(height: 8),
        Center(
          child: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(color: c.primarySoft, borderRadius: BorderRadius.circular(18)),
            alignment: Alignment.center,
            child: s.isAuto
                ? Icon(PhosphorIconsFill.lightning, size: 30, color: c.primary)
                : Text(FlagCircle.flag(s.code), style: const TextStyle(fontSize: 30)),
          ),
        ),
        const SizedBox(height: 16),
        Text('$name is a Pro location',
            textAlign: TextAlign.center, style: KovraText.headline.copyWith(fontSize: 22, color: c.text)),
        const SizedBox(height: 6),
        Text('Upgrade to ${AppConfig.proName} to use it.',
            textAlign: TextAlign.center, style: KovraText.body.copyWith(color: c.muted)),
        const SizedBox(height: 14),
        const PerkLine(icon: PhosphorIconsRegular.globeHemisphereWest, text: 'Every Pro location unlocked'),
        const PerkLine(icon: PhosphorIconsRegular.televisionSimple, text: 'Streaming & gaming servers'),
        if (!AppConfig.adsEnabled) const PerkLine(icon: PhosphorIconsRegular.prohibit, text: 'No ads in any plan'),
        const SizedBox(height: 16),
        KovraButton.primary(
          label: 'Upgrade to Pro',
          icon: PhosphorIconsFill.crownSimple,
          onPressed: () {
            Navigator.pop(ctx);
            Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PaywallScreen()));
          },
        ),
        const SizedBox(height: 4),
        KovraButton.ghost(label: 'Not now', onPressed: () => Navigator.pop(ctx)),
      ]);
    },
  );
}
