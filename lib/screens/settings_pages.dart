import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../config.dart';
import '../services/network_tools.dart';
import '../services/pro_controller.dart';
import '../services/settings_controller.dart';
import '../services/system_actions.dart';
import '../services/vpn_controller.dart';
import '../services/vpngate_service.dart';
import '../theme.dart';
import '../widgets/logo.dart';
import '../widgets/ui.dart';
import '../widgets/kovra_icons.dart';

// Settings sub-pages (4.2 – 4.6). Only real settings and real values.

/// 4.2 Auto-connect: the one trigger Kovra really has.
class AutoConnectPage extends StatelessWidget {
  const AutoConnectPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: settings,
      builder: (context, _) {
        final c = context.kc;
        return SheetPage(title: 'Auto-connect', children: [
          GroupCard(children: [
            GroupRow(
              title: 'Auto-connect',
              subtitle: 'Connect when you open ${AppConfig.brand}',
              chevron: false,
              trailing: KovraToggle(value: settings.autoConnect, onChanged: settings.setAutoConnect),
              onTap: () => settings.setAutoConnect(!settings.autoConnect),
            ),
          ]),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              '${AppConfig.brand} connects to your selected location, or the best free one. '
              'To stay protected when ${AppConfig.brand} is closed, use Android\'s Always-on VPN.',
              style: KovraText.caption.copyWith(color: c.muted),
            ),
          ),
          const SizedBox(height: 16),
          GroupCard(children: [
            GroupRow(
              icon: PhosphorIconsRegular.prohibit,
              title: 'Always-on VPN guide',
              subtitle: 'Android setting',
              onTap: () => Navigator.of(context).push(sheetRoute(const KillSwitchPage())),
            ),
          ]),
        ]);
      },
    );
  }
}

/// 4.3 Protocol: OpenVPN is what Kovra runs.
class ProtocolPage extends StatelessWidget {
  const ProtocolPage({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.kc;
    return SheetPage(title: 'Protocol', children: [
      Text('The protocol is how your traffic travels to the VPN server.',
          style: KovraText.body.copyWith(color: c.muted)),
      const SizedBox(height: 14),
      GroupCard(children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            const KovraRadio(selected: true),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('OpenVPN', style: KovraText.bodyStrong.copyWith(color: c.text)),
                Text('Widely compatible. Used for every location.', style: KovraText.caption.copyWith(color: c.muted)),
              ]),
            ),
          ]),
        ),
      ]),
      const SizedBox(height: 16),
      const InfoCallout(text: 'OpenVPN works on almost every network, including most public Wi-Fi.'),
    ]);
  }
}

/// 4.4 Kill switch: no in-app toggle. A guide to Android's own setting.
class KillSwitchPage extends StatelessWidget {
  const KillSwitchPage({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.kc;
    TextSpan b(String s) => TextSpan(text: s, style: TextStyle(fontWeight: FontWeight.w700, color: c.text));
    return SheetPage(
      title: 'Kill switch',
      bottom: SystemActions.isAndroid
          ? KovraButton.light(
              label: 'Open Android VPN settings',
              icon: PhosphorIconsRegular.arrowSquareOut,
              onPressed: SystemActions.openVpnSettings,
            )
          : null,
      children: [
        const SizedBox(height: 8),
        const Center(child: IconTile(icon: PhosphorIconsRegular.prohibit, size: 88, iconSize: 44)),
        const SizedBox(height: 16),
        Text(
          'A kill switch blocks the internet whenever the VPN is not connected, so nothing is sent '
          'unprotected. ${AppConfig.brand} uses Android\'s built-in one, which works for any VPN app.',
          textAlign: TextAlign.center,
          style: KovraText.body.copyWith(color: c.muted),
        ),
        const SectionLabel('Turn it on in Android'),
        GroupCard(children: [
          NumberedStep(n: 1, text: TextSpan(children: [const TextSpan(text: 'Open '), b('Android VPN settings')])),
          NumberedStep(
              n: 2, text: TextSpan(children: [const TextSpan(text: 'Tap the gear next to '), b(AppConfig.appName)])),
          NumberedStep(
            n: 3,
            text: TextSpan(children: [
              const TextSpan(text: 'Turn on '),
              b('Always-on VPN'),
              const TextSpan(text: ' and '),
              b('Block connections without VPN'),
            ]),
          ),
        ]),
        const SizedBox(height: 16),
        InfoCallout(
          icon: PhosphorIconsRegular.warningCircle,
          text: 'While blocking is on, you have no internet when ${AppConfig.brand} is disconnected.',
        ),
      ],
    );
  }
}

/// 4.5 Plan (Pro users). Free users see the paywall instead.
class PlanPage extends StatelessWidget {
  const PlanPage({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.kc;
    final plan = ProPlan.all.where((p) => p.id == pro.activePlanId).firstOrNull;
    Widget cell(String s, {bool head = false, bool pro = false, TextAlign align = TextAlign.left}) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          child: Text(
            s,
            textAlign: align,
            style: head
                ? KovraText.section.copyWith(color: c.muted)
                : TextStyle(
                    fontSize: 13.5,
                    fontWeight: pro ? FontWeight.w700 : FontWeight.w500,
                    color: pro ? c.primary : c.text),
          ),
        );
    TableRow row(String a, String free, String paid, {bool head = false}) => TableRow(
          decoration: BoxDecoration(border: head ? null : Border(top: BorderSide(color: c.line))),
          children: [
            cell(a, head: head),
            head
                ? cell(free, head: true)
                : Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                    child: Text(free, style: TextStyle(fontSize: 13.5, color: c.muted))),
            cell(paid, head: head, pro: !head),
          ],
        );
    return SheetPage(
      title: 'Your plan',
      bottom: SystemActions.isAndroid
          ? KovraButton.outline(
              label: 'Manage subscription',
              onPressed: () => SystemActions.openUrl(
                'https://play.google.com/store/account/subscriptions?package=com.kovravpn.app',
              ),
            )
          : null,
      children: [
        Container(
          height: 124,
          decoration: BoxDecoration(color: c.primary, borderRadius: BorderRadius.circular(18)),
          clipBehavior: Clip.antiAlias,
          child: Stack(children: [
            const Positioned.fill(child: BrandDecoration()),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration:
                      BoxDecoration(color: Colors.white.withAlpha(38), borderRadius: BorderRadius.circular(999)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(PhosphorIconsFill.crownSimple, size: 13, color: c.onPrimary),
                    const SizedBox(width: 6),
                    Text('Current plan',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: c.onPrimary)),
                  ]),
                ),
                const Spacer(),
                Text(AppConfig.proName, style: KovraText.headline.copyWith(color: c.onPrimary)),
                if (plan != null)
                  Text('${plan.title} · ${plan.price}${plan.period}',
                      style: TextStyle(fontSize: 13.5, color: c.onPrimary.withAlpha(204))),
              ]),
            ),
          ]),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: c.card,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: c.line),
          ),
          child: Table(
            columnWidths: const {0: FlexColumnWidth(1.3), 1: FlexColumnWidth(1), 2: FlexColumnWidth(1)},
            children: [
              row('', 'FREE', 'PRO', head: true),
              row('Free locations', 'Included', 'Included'),
              row('Pro locations', '—', 'Included'),
              row('Streaming & gaming servers', '—', 'Included'),
              if (!AppConfig.adsEnabled) row('Ads', 'None', 'None'),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text('Pro locations run on ${AppConfig.brand}\'s own servers as they go live.',
            style: KovraText.caption.copyWith(color: c.hint)),
      ],
    );
  }
}

/// 4.6 About & diagnostics: real values only.
class AboutPage extends StatefulWidget {
  const AboutPage({super.key});

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  IpInfo? _ip;
  bool _ipLoading = true;

  @override
  void initState() {
    super.initState();
    NetworkTools.ipInfo()
        .then((v) {
          if (mounted) setState(() => _ip = v);
        })
        .catchError((Object _) {})
        .whenComplete(() {
          if (mounted) setState(() => _ipLoading = false);
        });
  }

  String _time(DateTime t) => MaterialLocalizations.of(context).formatTimeOfDay(
        TimeOfDay.fromDateTime(t),
        alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
      );

  String _status() => switch (vpn.status) {
        VpnStatus.connected => 'Connected',
        VpnStatus.connecting => 'Connecting',
        VpnStatus.disconnected => 'Not connected',
      };

  List<(String, String)> _values() {
    final s = vpn.activeServer;
    final since = vpn.connectedAt;
    final loaded = vpnGate.loadedAt;
    return [
      ('VPN status', _status()),
      ('Server', s == null ? '—' : '${s.country} · ${s.host}'),
      ('Server IP', s?.ip ?? '—'),
      ('Connected since', since == null ? '—' : _time(since)),
      ('Public IP', _ipLoading ? 'Checking…' : (_ip?.ip ?? 'Unknown')),
      ('Protocol', 'OpenVPN'),
      if (AppConfig.paywallEnabled) ('Plan', pro.isPro ? AppConfig.proName : 'Free'),
      (
        'Free server list',
        loaded == null
            ? (vpnGate.error ?? 'Not loaded')
            : '${vpnGate.all.length} servers · ${DateTime.now().difference(loaded).inMinutes} min ago'
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([vpn, vpnGate, pro]),
      builder: (context, _) {
        final c = context.kc;
        final vals = _values();
        return SheetPage(title: 'About & diagnostics', children: [
          Row(children: [
            Container(
              width: 56,
              height: 56,
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: c.primarySoft, borderRadius: BorderRadius.circular(16)),
              child: const KovraLogo(size: 44),
            ),
            const SizedBox(width: 14),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(AppConfig.appName, style: KovraText.bodyL.copyWith(color: c.text)),
              Text('Version ${AppConfig.version}', style: KovraText.secondary.copyWith(color: c.muted)),
            ]),
          ]),
          SectionLabel(
            'Diagnostics',
            trailing: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () {
                Clipboard.setData(ClipboardData(
                  text: [
                    '${AppConfig.appName} ${AppConfig.version}',
                    for (final (k, v) in vals) '$k: $v',
                  ].join('\n'),
                ));
                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(const SnackBar(content: Text('Diagnostics copied')));
              },
              child: Padding(
                padding: const EdgeInsets.all(2),
                child: Text('Copy', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: c.primary)),
              ),
            ),
          ),
          GroupCard(children: [
            for (final (k, v) in vals)
              KvRow(
                label: k,
                value: v,
                valueColor: k == 'VPN status' && vpn.status == VpnStatus.connected ? c.success : null,
              ),
          ]),
          const SizedBox(height: 8),
          Text("Share these details with support if something isn't working.",
              style: KovraText.caption.copyWith(color: c.muted)),
          const SectionLabel('Legal'),
          GroupCard(children: [
            GroupRow(
              title: 'Open-source licenses',
              onTap: () => showLicensePage(
                context: context,
                applicationName: AppConfig.appName,
                applicationVersion: AppConfig.version,
              ),
            ),
          ]),
          const SizedBox(height: 12),
          Text(
            'Free locations are VPN Gate volunteer servers (University of Tsukuba research project). '
            'Their operators can keep their own logs.',
            style: KovraText.caption.copyWith(color: c.hint),
          ),
        ]);
      },
    );
  }
}
