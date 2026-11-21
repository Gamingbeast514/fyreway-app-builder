import 'dart:async';

import 'package:flutter/material.dart';

import '../config.dart';
import '../models/server.dart';
import '../services/pro_controller.dart';
import '../services/public_ip.dart';
import '../services/settings_controller.dart';
import '../services/system_actions.dart';
import '../services/vpn_controller.dart';
import '../services/vpngate_service.dart';
import '../theme.dart';
import '../widgets/logo.dart';
import '../widgets/pro_location_sheet.dart';
import '../widgets/session_summary_sheet.dart';
import '../widgets/ui.dart';
import 'details_screen.dart';
import 'paywall_screen.dart';
import 'permission_screen.dart';
import 'servers_screen.dart';
import 'settings_screen.dart';
import 'smart_connect_screen.dart';
import '../widgets/kovra_icons.dart';

enum _View { off, connecting, on, error, permission }

/// Home: one screen whose brand area and sheet follow `vpn.status`.
class HomeScreen extends StatefulWidget {
  /// Came from "Allow VPN connection": connect right away.
  final bool connectNow;

  /// Came from "Not now" on the permission explainer.
  final bool askedLater;

  const HomeScreen({super.key, this.connectNow = false, this.askedLater = false});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Timer? _ticker;
  late bool _askedLater = widget.askedLater;
  VpnStatus _prev = vpn.status;

  @override
  void initState() {
    super.initState();
    vpnGate.load();
    publicIp.refresh();
    vpn.addListener(_onVpn);
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (vpn.status == VpnStatus.connected && mounted) setState(() {});
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || vpn.status != VpnStatus.disconnected) return;
      if (widget.connectNow || (settings.autoConnect && !_askedLater)) _connect();
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    vpn.removeListener(_onVpn);
    super.dispose();
  }

  void _onVpn() {
    final now = vpn.status;
    // A connect started elsewhere (Smart Connect, country detail) answers "Not now".
    if (now != VpnStatus.disconnected) _askedLater = false;
    if (_prev != VpnStatus.disconnected && now == VpnStatus.disconnected) {
      // The tunnel just went down: look up the real IP again once routes settle.
      Future.delayed(const Duration(seconds: 2), () => publicIp.refresh(force: true));
    }
    _prev = now;
  }

  Future<void> _open(Widget page, {bool sheet = false}) =>
      Navigator.of(context).push(sheet ? sheetRoute(page) : MaterialPageRoute(builder: (_) => page));

  /// Shows the explainer once, then starts the real connect.
  Future<void> _connect() async {
    final ok = await ensureVpnExplained(context);
    if (!mounted) return;
    if (!ok) {
      setState(() => _askedLater = true);
      return;
    }
    setState(() => _askedLater = false);
    await vpn.connect();
  }

  Future<void> _disconnect() async {
    final ok = await showKovraConfirm(
      context,
      title: 'Turn off protection?',
      message: 'Your traffic will no longer be encrypted.',
      cancel: 'Stay protected',
      confirm: 'Disconnect',
    );
    if (!ok || !mounted) return;
    final summary = vpn.disconnect();
    if (summary != null && mounted) await showSessionSummary(context, summary);
  }

  Future<void> _useRecent(SavedPlace p) async {
    if (p.premium) {
      final s = proServers.where((x) => x.code == p.code && x.displayName == p.country).firstOrNull;
      if (s == null) return;
      if (!pro.isPro) {
        showProLocationSheet(context, s);
        return;
      }
      vpn.clearError();
      vpn.selectServer(s);
      return;
    }
    await vpnGate.load();
    if (!mounted) return;
    final s = vpnGate.candidates(p.code).firstOrNull;
    if (s == null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text('No free server in ${p.country} is online right now')));
      return;
    }
    vpn.clearError();
    vpn.selectServer(s);
  }

  /// Next server to suggest after a failure.
  VpnServer? _nextBest() {
    final s = vpn.server;
    if (s.isPlaceholder || (s.premium && s.isAuto)) return autoFreeServer;
    final all = vpnGate.all;
    if (all.isEmpty) return null;
    if (s.isAuto) return all.length > 3 ? all[3] : null; // the top 3 were just tried
    return all.where((x) => x.code != s.code).firstOrNull; // that country's servers were tried
  }

  _View get _view => switch (vpn.status) {
        VpnStatus.connecting => _View.connecting,
        VpnStatus.connected => _View.on,
        VpnStatus.disconnected when vpn.permissionDenied || _askedLater => _View.permission,
        VpnStatus.disconnected when vpn.lastError != null => _View.error,
        _ => _View.off,
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListenableBuilder(
        listenable: Listenable.merge([vpn, pro, settings, publicIp, vpnGate]),
        builder: (context, _) {
          final v = _view;
          final protected = v == _View.on || v == _View.connecting;
          final design = (!pro.isPro && AppConfig.paywallEnabled && (v == _View.on || v == _View.off))
              ? 390.0
              : 410.0; // free plan: room for the banner
          final h = BrandSheetLayout.fit(context, design);
          return BrandSheetLayout(
            brandHeight: h,
            brand: BrandArea(
              height: h,
              protected: protected,
              child: Padding(
                padding: EdgeInsets.only(top: MediaQuery.paddingOf(context).top + 56, bottom: kSheetOverlap + 8),
                child: Center(child: FittedBox(fit: BoxFit.scaleDown, child: _status(v))),
              ),
            ),
            overlayTop: _TopBar(
              onPrimary: protected,
              onMenu: () => _open(const SettingsScreen(), sheet: true),
              onDetails: () => _open(const DetailsScreen()),
            ),
            body: ListView(
              padding: const EdgeInsets.fromLTRB(kPageX, 4, kPageX, 8),
              children: _sheet(v),
            ),
            bottom: _bottom(v),
          );
        },
      ),
    );
  }

  // ───────── Brand area ─────────

  Widget _status(_View v) {
    final c = context.kc;
    switch (v) {
      case _View.off:
        final ip = publicIp.info?.ip;
        return StatusCenter(
          onPrimary: false,
          icon: PhosphorIconsRegular.shieldSlash,
          title: 'Not protected',
          subtitle: ip == null || ip.isEmpty ? 'Your real IP is visible' : 'Your IP $ip is visible',
        );
      case _View.connecting:
        return StatusCenter(
          icon: PhosphorIconsRegular.shield,
          spinning: true,
          title: 'Connecting…',
          subtitle: 'Securing your connection to ${vpn.server.placeName}',
        );
      case _View.on:
        final start = vpn.connectedAt;
        final ip = vpn.activeServer?.ip;
        final time = start == null ? '00:00:00' : fmtClock(DateTime.now().difference(start));
        return StatusCenter(
          icon: PhosphorIconsFill.shieldCheck,
          title: 'Connected',
          subtitle: ip == null ? time : '$time · IP $ip',
        );
      case _View.error:
        return StatusCenter(
          onPrimary: false,
          icon: PhosphorIconsRegular.warningCircle,
          circleColor: c.dangerSoft,
          iconColor: c.danger,
          title: "Couldn't connect",
          subtitle: vpn.server.isPlaceholder
              ? '${vpn.server.placeName} is not live yet'
              : (vpnGate.all.isEmpty
                  ? 'Free servers are unreachable'
                  : '${_capital(vpn.server.placeName)} did not answer'),
        );
      case _View.permission:
        return StatusCenter(
          onPrimary: false,
          icon: PhosphorIconsRegular.handPalm,
          title: 'VPN permission needed',
          subtitle: vpn.permissionDenied
              ? "Android didn't allow the connection"
              : '${AppConfig.brand} needs your OK to connect',
        );
    }
  }

  static String _capital(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  // ───────── Sheet ─────────

  List<Widget> _sheet(_View v) {
    switch (v) {
      case _View.off:
      case _View.on:
        return [
          SearchFieldButton(
              hint: 'Where do you want to connect?', onTap: () => _open(const ServersScreen(search: true))),
          const SizedBox(height: 10),
          _locationRow(trailing: SmartChip(onTap: () => _open(const SmartConnectScreen()))),
          if (settings.recent.isNotEmpty) ...[
            const SectionLabel('Recent', padding: EdgeInsets.fromLTRB(0, 14, 0, 8)),
            SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: settings.recent.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final p = settings.recent[i];
                  return PlaceChip(code: p.code, label: p.country, onTap: () => _useRecent(p));
                },
              ),
            ),
          ],
          if (!pro.isPro && AppConfig.paywallEnabled) ...[
            const SizedBox(height: 18),
            _ProBanner(onTap: () => _open(const PaywallScreen()))
          ],
        ];
      case _View.connecting:
        return [
          _locationRow(),
          const SizedBox(height: 12),
          _StepsCard(stage: vpn.stage),
        ];
      case _View.error:
        return _errorSheet();
      case _View.permission:
        return _permissionSheet();
    }
  }

  Widget _locationRow({Widget? trailing}) {
    final s = vpn.activeServer ?? vpn.server;
    return LocationRow(
      code: s.code,
      title: s.displayName,
      subtitle: s.rowSubtitle,
      trailing: trailing,
      onTap: vpn.status == VpnStatus.connecting ? null : () => _open(const ServersScreen()),
    );
  }

  List<Widget> _errorSheet() {
    final c = context.kc;
    final next = _nextBest();
    final offline = vpnGate.all.isEmpty && !vpn.server.isPlaceholder;
    final reason = vpn.lastError ?? 'The server did not answer.';
    final tip = vpn.server.isPlaceholder
        ? '' // the reason already says to use a free location
        : offline
            ? (reason.contains('internet') ? '' : 'Check that Wi-Fi or mobile data is on.')
            : 'Free servers are run by volunteers and some go offline. Try again, or use the next best one.';
    return [
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(18)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('What you can do', style: KovraText.bodyStrong.copyWith(color: c.text)),
          const SizedBox(height: 6),
          Text(tip.isEmpty ? reason : '$reason $tip', style: KovraText.secondary.copyWith(color: c.muted)),
        ]),
      ),
      if (next != null) ...[
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(18), border: Border.all(color: c.line)),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          child: LocationRow(
            code: next.code,
            title: next.isAuto ? 'Best free location' : 'Connect to ${next.displayName}',
            subtitle:
                next.isAuto ? 'Picked automatically' : ['Next best', if (next.stats.isNotEmpty) next.stats].join(' · '),
            trailing: Icon(PhosphorIconsRegular.arrowRight, size: 20, color: c.primary),
            onTap: () async {
              vpn.clearError();
              await vpn.selectServer(next);
              if (mounted) _connect();
            },
          ),
        ),
      ],
    ];
  }

  List<Widget> _permissionSheet() {
    final c = context.kc;
    return [
      Text(
        "${AppConfig.brand} can't protect this phone until Android allows the VPN connection.",
        style: KovraText.body.copyWith(color: c.muted),
      ),
      const SizedBox(height: 16),
      Container(
        decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(18)),
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(children: [
          NumberedStep(
            n: 1,
            text: TextSpan(children: [
              const TextSpan(text: 'Tap '),
              TextSpan(text: 'Try again', style: TextStyle(fontWeight: FontWeight.w700, color: c.text)),
              const TextSpan(text: ', then '),
              TextSpan(text: 'OK', style: TextStyle(fontWeight: FontWeight.w700, color: c.text)),
              const TextSpan(text: ' on the Android prompt.'),
            ]),
          ),
          const NumberedStep(
            n: 2,
            text: TextSpan(text: 'If another VPN app is set as Always-on, turn it off in Android settings first.'),
          ),
        ]),
      ),
    ];
  }

  // ───────── Pinned action ─────────

  Widget _bottom(_View v) {
    switch (v) {
      case _View.off:
        return KovraButton.primary(label: 'Connect', icon: PhosphorIconsBold.power, onPressed: _connect);
      case _View.connecting:
        return KovraButton.outline(label: 'Cancel', onPressed: vpn.disconnect);
      case _View.on:
        return KovraButton.light(label: 'Disconnect', onPressed: _disconnect);
      case _View.error:
        return Column(mainAxisSize: MainAxisSize.min, children: [
          KovraButton.primary(label: 'Try again', icon: PhosphorIconsRegular.arrowClockwise, onPressed: _connect),
          const SizedBox(height: 4),
          KovraButton.ghost(
            label: 'Choose another location',
            onPressed: () {
              vpn.clearError();
              _open(const ServersScreen());
            },
          ),
        ]);
      case _View.permission:
        return Column(mainAxisSize: MainAxisSize.min, children: [
          KovraButton.primary(
            label: 'Try again',
            onPressed: () {
              settings.setVpnExplained();
              _connect();
            },
          ),
          if (SystemActions.isAndroid) ...[
            const SizedBox(height: 4),
            KovraButton.ghost(label: 'Open Android VPN settings', onPressed: SystemActions.openVpnSettings),
          ],
        ]);
    }
  }
}

class _TopBar extends StatelessWidget {
  final bool onPrimary;
  final VoidCallback onMenu, onDetails;
  const _TopBar({required this.onPrimary, required this.onMenu, required this.onDetails});

  @override
  Widget build(BuildContext context) {
    final c = context.kc;
    final btnBg = onPrimary ? Colors.white.withAlpha(38) : c.card;
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        child: Row(children: [
          RoundIconButton(icon: PhosphorIconsRegular.list, tooltip: 'Settings', background: btnBg, onTap: onMenu),
          Expanded(
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Container(
                width: 32,
                height: 32,
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: onPrimary ? Colors.white.withAlpha(38) : c.primarySoft,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const KovraLogo(size: 26),
              ),
              const SizedBox(width: 8),
              Text(AppConfig.appName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, letterSpacing: -0.3, color: c.text)),
              ListenableBuilder(
                listenable: pro,
                builder: (_, __) => pro.isPro
                    ? Padding(
                        padding: const EdgeInsets.only(left: 6),
                        child: Icon(PhosphorIconsFill.crownSimple, size: 16, color: c.gold),
                      )
                    : const SizedBox.shrink(),
              ),
            ]),
          ),
          RoundIconButton(
              icon: PhosphorIconsRegular.chartBar, tooltip: 'Session details', background: btnBg, onTap: onDetails),
        ]),
      ),
    );
  }
}

class _ProBanner extends StatelessWidget {
  final VoidCallback onTap;
  const _ProBanner({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = context.kc;
    return Material(
      color: c.primarySoft,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            IconTile(
                icon: PhosphorIconsFill.crownSimple,
                size: 44,
                background: c.primary,
                foreground: c.onPrimary,
                iconSize: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text("You're on Free", style: KovraText.bodyStrong.copyWith(color: c.text)),
                const SizedBox(height: 2),
                Text('Free locations · Pro unlocks every country',
                    style: KovraText.caption.copyWith(color: c.muted), maxLines: 2),
              ]),
            ),
            const SizedBox(width: 8),
            PillButton(label: 'Upgrade', onTap: onTap),
          ]),
        ),
      ),
    );
  }
}

/// Connecting steps, driven by `vpn.stage` (see VpnController._friendly).
class _StepsCard extends StatelessWidget {
  final String stage;
  const _StepsCard({required this.stage});

  static const _steps = ['Preparing', 'Reaching the server', 'Securing your connection', 'Almost there'];

  static int indexFor(String stage) => switch (stage) {
        'Reaching the server…' => 1,
        'Securing your connection…' => 2,
        'Almost there…' => 3,
        _ => 0, // Finding the best route / Connecting to X / Preparing
      };

  @override
  Widget build(BuildContext context) {
    final c = context.kc;
    final at = indexFor(stage);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(18)),
      child: Column(children: [
        for (var i = 0; i < _steps.length; i++)
          _StepRow(
            title: _steps[i],
            subtitle: i == at && !stage.startsWith(_steps[i]) ? stage : null,
            state: i < at ? 0 : (i == at ? 1 : 2),
          ),
      ]),
    );
  }
}

class _StepRow extends StatelessWidget {
  final String title;
  final String? subtitle;
  final int state; // 0 done, 1 doing, 2 todo
  const _StepRow({required this.title, this.subtitle, required this.state});

  @override
  Widget build(BuildContext context) {
    final c = context.kc;
    final Widget mark = switch (state) {
      0 => Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(color: c.success, shape: BoxShape.circle),
          child: Icon(PhosphorIconsBold.check, size: 15, color: c.successSoft),
        ),
      1 => SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(strokeWidth: 2.5, color: c.primary, strokeCap: StrokeCap.round),
        ),
      _ => Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: c.line, width: 2)),
        ),
    };
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 54),
      child: Row(children: [
        mark,
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            Text(title,
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: state == 2 ? c.muted : c.text)),
            if (subtitle != null)
              Text(subtitle!,
                  maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12.5, color: c.muted)),
          ]),
        ),
      ]),
    );
  }
}
