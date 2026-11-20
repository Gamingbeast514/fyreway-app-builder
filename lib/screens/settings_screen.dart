import 'package:flutter/material.dart';

import '../config.dart';
import '../services/pro_controller.dart';
import '../services/settings_controller.dart';
import '../theme.dart';
import '../widgets/logo.dart';
import '../widgets/signature.dart';
import 'invite_screen.dart';
import 'ip_check_screen.dart';
import 'paywall_screen.dart';
import 'speed_test_screen.dart';

/// "More" menu: short and only things that work.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  void _open(BuildContext context, Widget page) =>
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));

  Future<void> _restore(BuildContext context) async {
    final ok = await pro.restore();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(ok ? '${AppConfig.appName} Pro restored' : 'No active subscription found')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('More', style: TextStyle(fontWeight: FontWeight.w700)),
        actions: [
          IconButton(icon: const Icon(Icons.close_rounded), tooltip: 'Close', onPressed: () => Navigator.pop(context)),
        ],
      ),
      body: ListenableBuilder(
        listenable: Listenable.merge([settings, pro]),
        builder: (context, _) {
          final c = context.kc;
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
            children: [
              if (AppConfig.paywallEnabled) ...[
                _Group(children: [
                  pro.isPro
                      ? ListTile(
                          leading: Icon(Icons.workspace_premium_outlined, color: c.gold),
                          title: Text('${AppConfig.appName} Pro', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: c.text)),
                          trailing: Text('Active', style: TextStyle(fontSize: 14, color: c.gold)),
                        )
                      : _NavTile(
                          icon: Icons.workspace_premium_outlined,
                          iconColor: c.gold,
                          title: 'Upgrade to Pro',
                          onTap: () => _open(context, const PaywallScreen()),
                        ),
                  const _Divider(),
                  _NavTile(icon: Icons.restore_rounded, title: 'Restore purchases', onTap: () => _restore(context)),
                ]),
                const SizedBox(height: 16),
              ],
              _Group(children: [
                SwitchListTile(
                  value: settings.autoConnect,
                  onChanged: settings.setAutoConnect,
                  activeTrackColor: c.accent,
                  secondary: Icon(Icons.autorenew_outlined, color: c.text),
                  title: Text('Auto-connect', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: c.text)),
                ),
                if (AppConfig.enableSpeedTest) ...[
                  const _Divider(),
                  _NavTile(icon: Icons.speed_outlined, title: 'Internet speed test', onTap: () => _open(context, const SpeedTestScreen())),
                ],
                if (AppConfig.enableLocationChecker) ...[
                  const _Divider(),
                  _NavTile(icon: Icons.my_location_outlined, title: 'My IP & location', onTap: () => _open(context, const IpCheckScreen())),
                ],
                if (AppConfig.enableInvite) ...[
                  const _Divider(),
                  _NavTile(icon: Icons.card_giftcard_outlined, title: 'Invite friends', onTap: () => _open(context, const InviteScreen())),
                ],
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
      ),
    );
  }
}

class _Group extends StatelessWidget {
  final List<Widget> children;
  const _Group({required this.children});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.kc.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: Column(children: children),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();
  @override
  Widget build(BuildContext context) => Divider(height: 1, indent: 56, color: context.kc.border);
}

class _NavTile extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final String title;
  final VoidCallback onTap;
  const _NavTile({required this.icon, required this.title, required this.onTap, this.iconColor});

  @override
  Widget build(BuildContext context) {
    final c = context.kc;
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: iconColor ?? c.text),
      title: Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: c.text)),
      trailing: Icon(Icons.chevron_right_rounded, color: c.muted),
    );
  }
}
