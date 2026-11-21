import 'package:flutter/material.dart';

import '../config.dart';
import '../services/pro_controller.dart';
import '../services/settings_controller.dart';
import '../theme.dart';
import '../widgets/logo.dart';
import '../widgets/signature.dart';
import '../widgets/ui.dart';
import 'invite_screen.dart';
import 'ip_check_screen.dart';
import 'paywall_screen.dart';
import 'settings_pages.dart';
import 'speed_test_screen.dart';
import '../widgets/kovra_icons.dart';

/// 4.1 Settings ("More"): every existing item, regrouped. Only things that work.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  void _open(BuildContext context, Widget page) => Navigator.of(context).push(sheetRoute(page));

  Future<void> _restore(BuildContext context) async {
    final ok = await pro.restore();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(ok ? '${AppConfig.proName} restored' : 'No active subscription found')));
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([settings, pro]),
      builder: (context, _) {
        final c = context.kc;
        final plan = ProPlan.all.where((p) => p.id == pro.activePlanId).firstOrNull;
        return SheetPage(
          title: 'Settings',
          closeIcon: true,
          children: [
            if (AppConfig.paywallEnabled) ...[
              SectionLabel(AppConfig.proName, padding: const EdgeInsets.fromLTRB(0, 4, 0, 8)),
              GroupCard(children: [
                if (pro.isPro)
                  GroupRow(
                    icon: PhosphorIconsFill.crownSimple,
                    iconColor: c.gold,
                    title: AppConfig.proName,
                    subtitle: plan == null ? null : '${plan.title} plan',
                    value: 'Active',
                    valueColor: c.success,
                    onTap: () => _open(context, const PlanPage()),
                  )
                else
                  GroupRow(
                    icon: PhosphorIconsRegular.crownSimple,
                    title: 'Upgrade to Pro',
                    subtitle: AppConfig.adsEnabled ? 'Unlock every Pro location' : 'Pro locations, no ads in any plan',
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PaywallScreen())),
                  ),
                GroupRow(
                  icon: PhosphorIconsRegular.arrowClockwise,
                  title: 'Restore purchases',
                  chevron: false,
                  onTap: () => _restore(context),
                ),
              ]),
            ],
            SectionLabel('Connection', padding: EdgeInsets.fromLTRB(0, AppConfig.paywallEnabled ? 20 : 4, 0, 8)),
            GroupCard(children: [
              GroupRow(
                icon: PhosphorIconsRegular.lightning,
                title: 'Auto-connect',
                subtitle: 'Connect when you open ${AppConfig.brand}',
                value: settings.autoConnect ? 'On' : 'Off',
                onTap: () => _open(context, const AutoConnectPage()),
              ),
              GroupRow(
                icon: PhosphorIconsRegular.path,
                title: 'Protocol',
                value: 'OpenVPN',
                onTap: () => _open(context, const ProtocolPage()),
              ),
              GroupRow(
                icon: PhosphorIconsRegular.prohibit,
                title: 'Kill switch',
                subtitle: 'Set up with Android Always-on VPN',
                onTap: () => _open(context, const KillSwitchPage()),
              ),
            ]),
            if (AppConfig.enableSpeedTest || AppConfig.enableLocationChecker || AppConfig.enableInvite) ...[
              const SectionLabel('Tools'),
              GroupCard(children: [
                if (AppConfig.enableSpeedTest)
                  GroupRow(
                    icon: PhosphorIconsRegular.gauge,
                    title: 'Internet speed test',
                    onTap: () => _open(context, const SpeedTestScreen()),
                  ),
                if (AppConfig.enableLocationChecker)
                  GroupRow(
                    icon: PhosphorIconsRegular.mapPin,
                    title: 'My IP & location',
                    onTap: () => _open(context, const IpCheckScreen()),
                  ),
                if (AppConfig.enableInvite)
                  GroupRow(
                    icon: PhosphorIconsRegular.gift,
                    title: 'Invite friends',
                    onTap: () => _open(context, const InviteScreen()),
                  ),
              ]),
            ],
            const SectionLabel('About'),
            GroupCard(children: [
              GroupRow(
                icon: PhosphorIconsRegular.info,
                title: 'About & diagnostics',
                value: 'v${AppConfig.version}',
                onTap: () => _open(context, const AboutPage()),
              ),
            ]),
            const SizedBox(height: 36),
            // Tap the logo/version 6 times: reveals the hidden six-star mark.
            SecretTapTarget(
              child: Column(children: [
                const Center(child: KovraLogo(size: 34)),
                const SizedBox(height: 8),
                Text('${AppConfig.appName} ${AppConfig.version}${AppConfig.adsEnabled ? '' : ' · No ads'}',
                    textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: c.hint)),
              ]),
            ),
          ],
        );
      },
    );
  }
}
