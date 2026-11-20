import 'dart:async';

import 'package:flutter/material.dart';

import '../config.dart';
import '../services/pro_controller.dart';
import '../services/settings_controller.dart';
import '../services/vpn_controller.dart';
import '../theme.dart';
import '../widgets/code_badge.dart';
import '../widgets/glow_background.dart';
import 'paywall_screen.dart';
import 'servers_screen.dart';
import 'settings_screen.dart';

/// Home: status at the top, control panel at the bottom. No ads.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    if (settings.autoConnect && vpn.status == VpnStatus.disconnected) vpn.connect();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (vpn.status == VpnStatus.connected && mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _open(Widget page) => Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));

  Future<void> _onMainButton() async {
    switch (vpn.status) {
      case VpnStatus.disconnected:
        await vpn.connect();
        final err = vpn.lastError;
        if (err != null && mounted && vpn.status == VpnStatus.disconnected) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(err)));
        }
      case VpnStatus.connecting:
        vpn.disconnect(); // cancel
      case VpnStatus.connected:
        final ok = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: context.kc.cardDeep,
            title: const Text('Turn off protection?'),
            content: const Text('Your traffic will no longer be encrypted.'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Stay protected')),
              TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Disconnect')),
            ],
          ),
        );
        if (ok != true || !mounted) return;
        final summary = vpn.disconnect();
        if (summary != null && mounted) {
          final m = summary.duration.inMinutes;
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text('Disconnected · protected for ${m < 1 ? 'under a minute' : '$m min'}')));
        }
    }
  }

  String _elapsed() {
    final start = vpn.connectedAt;
    if (start == null) return '00:00:00';
    final d = DateTime.now().difference(start);
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.inHours)}:${two(d.inMinutes % 60)}:${two(d.inSeconds % 60)}';
  }

  @override
  Widget build(BuildContext context) {
    final c = context.kc;
    return Scaffold(
      body: ListenableBuilder(
        listenable: Listenable.merge([vpn, pro]),
        builder: (context, _) {
          final st = vpn.status;
          final glow = st == VpnStatus.connected ? c.green : c.accent;
          return GlowBackground(
            color: glow,
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  _topBar(context),
                  Expanded(
                    child: Center(
                      child: FittedBox(fit: BoxFit.scaleDown, child: _hero(context, st)),
                    ),
                  ),
                  _panel(context, st),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _topBar(BuildContext context) {
    final c = context.kc;
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Menu',
            icon: Icon(Icons.menu_rounded, color: c.text, size: 26),
            onPressed: () => _open(const SettingsScreen()),
          ),
          const SizedBox(width: 4),
          Text(AppConfig.appName, style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700, color: c.text)),
          const Spacer(),
          if (pro.isPro)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Text('PRO', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: 1, color: c.gold)),
            )
          else if (AppConfig.paywallEnabled)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () => _open(const PaywallScreen()),
                child: Ink(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: LinearGradient(colors: [c.cyan, c.deepBlue]),
                  ),
                  child: const Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.workspace_premium_outlined, size: 16, color: Colors.white),
                    SizedBox(width: 6),
                    Text('PRO', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: 1, color: Colors.white)),
                  ]),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _hero(BuildContext context, VpnStatus st) {
    final c = context.kc;
    switch (st) {
      case VpnStatus.disconnected:
        return const SizedBox.shrink(); // clean: only the glow
      case VpnStatus.connecting:
        return Column(mainAxisSize: MainAxisSize.min, children: [
          Text('Connecting…', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: c.text)),
          const SizedBox(height: 8),
          Text(vpn.stage, style: TextStyle(fontSize: 14, color: c.muted)),
        ]);
      case VpnStatus.connected:
        return Column(mainAxisSize: MainAxisSize.min, children: [
          Text('Protected', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: c.text)),
          const SizedBox(height: 6),
          Text(_elapsed(),
              style: TextStyle(fontSize: 46, fontWeight: FontWeight.w300, letterSpacing: 1.5, color: c.green)),
          const SizedBox(height: 6),
          Text('Encrypted · WireGuard', style: TextStyle(fontSize: 13, color: c.muted)),
        ]);
    }
  }

  Widget _panel(BuildContext context, VpnStatus st) {
    final c = context.kc;
    final bottom = MediaQuery.of(context).padding.bottom;
    final label = switch (st) {
      VpnStatus.disconnected => 'TAP TO PROTECT',
      VpnStatus.connecting => 'TAP TO CANCEL',
      VpnStatus.connected => 'TAP TO DISCONNECT',
    };
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(20, 20, 20, 24 + bottom),
      decoration: BoxDecoration(
        color: c.panel,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _locationPill(context),
          const SizedBox(height: 26),
          _ConnectButton(status: st, onTap: _onMainButton),
          const SizedBox(height: 16),
          Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1.2, color: c.muted)),
        ],
      ),
    );
  }

  Widget _locationPill(BuildContext context) {
    final c = context.kc;
    final s = vpn.activeServer ?? vpn.server;
    return Material(
      color: c.cardDeep,
      shape: const StadiumBorder(),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: () => _open(const ServersScreen()),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 14, 8),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            CodeBadge(code: s.code, size: 28),
            const SizedBox(width: 10),
            Text(s.code == 'AUTO' || s.isLive ? s.country : '${s.country} · ${s.city}',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: c.text)),
            const SizedBox(width: 6),
            Icon(Icons.keyboard_arrow_right_rounded, color: c.muted),
          ]),
        ),
      ),
    );
  }
}

/// Big round gradient button with a soft halo.
class _ConnectButton extends StatelessWidget {
  final VpnStatus status;
  final VoidCallback onTap;
  const _ConnectButton({required this.status, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = context.kc;
    final connected = status == VpnStatus.connected;
    final connecting = status == VpnStatus.connecting;
    final colors = connected ? [c.green, c.accent] : [c.cyan, c.deepBlue];
    final ring = connected ? c.green : c.accent;

    return Semantics(
      button: true,
      label: connected ? 'Disconnect' : (connecting ? 'Cancel' : 'Connect'),
      child: SizedBox(
        width: 148,
        height: 148,
        child: Stack(
          alignment: Alignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              width: 148,
              height: 148,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: ring.withAlpha(110), width: 1.5),
              ),
            ),
            if (connecting)
              SizedBox(
                width: 148,
                height: 148,
                child: CircularProgressIndicator(strokeWidth: 2, color: c.cyan),
              ),
            Material(
              shape: const CircleBorder(),
              clipBehavior: Clip.antiAlias,
              elevation: 0,
              child: Ink(
                width: 124,
                height: 124,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: connecting ? colors.map((x) => x.withAlpha(140)).toList() : colors,
                  ),
                ),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: onTap,
                  child: Icon(
                    connecting ? Icons.close_rounded : Icons.power_settings_new_rounded,
                    size: 50,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
