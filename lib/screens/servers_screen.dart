import 'dart:async';

import 'package:flutter/material.dart';

import '../config.dart';
import '../models/server.dart';
import '../services/pro_controller.dart';
import '../services/settings_controller.dart';
import '../services/vpn_controller.dart';
import '../services/vpngate_service.dart';
import '../theme.dart';
import '../widgets/pro_location_sheet.dart';
import '../widgets/ui.dart';
import 'permission_screen.dart';
import 'smart_connect_screen.dart';
import '../widgets/kovra_icons.dart';

/// 3.1 Locations + 3.2 Search: free (live VPN Gate) and Pro sections.
class ServersScreen extends StatefulWidget {
  /// Opened from the Home search field: focus the search right away.
  final bool search;
  const ServersScreen({super.key, this.search = false});

  @override
  State<ServersScreen> createState() => _ServersScreenState();
}

class _ServersScreenState extends State<ServersScreen> {
  final _q = TextEditingController();
  final _focus = FocusNode();
  int _tab = 0; // All / Favorites / Recent

  @override
  void initState() {
    super.initState();
    vpnGate.load();
    _focus.addListener(() => setState(() {}));
    if (widget.search) WidgetsBinding.instance.addPostFrameCallback((_) => _focus.requestFocus());
  }

  @override
  void dispose() {
    _q.dispose();
    _focus.dispose();
    super.dispose();
  }

  bool get _searching => _focus.hasFocus || _q.text.isNotEmpty;

  void _cancelSearch() {
    if (widget.search) {
      Navigator.pop(context);
      return;
    }
    _q.clear();
    _focus.unfocus();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final c = context.kc;
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: ListenableBuilder(
        listenable: Listenable.merge([pro, vpnGate, vpn, settings]),
        builder: (context, _) {
          final h = BrandSheetLayout.fit(context, 150);
          return BrandSheetLayout(
            brandHeight: h,
            brand: MiniStatusHeader(height: h),
            body: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(kPageX, 0, kPageX, 0),
                // One search field in a fixed, keyed spot so it keeps focus
                // when the title and tabs hide during search.
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  if (!_searching) ...[
                    Row(key: const ValueKey('title'), children: [
                      Expanded(child: Text('Choose location', style: KovraText.title.copyWith(color: c.text))),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(foregroundColor: c.primary),
                        child: const Text('Done', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                      ),
                    ]),
                    const SizedBox(key: ValueKey('gap1'), height: 10),
                  ],
                  Row(key: const ValueKey('search'), children: [
                    Expanded(
                      child: KovraSearchField(
                        controller: _q,
                        focusNode: _focus,
                        hint: 'Search country or city',
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    if (_searching)
                      TextButton(
                        onPressed: _cancelSearch,
                        style: TextButton.styleFrom(foregroundColor: c.primary),
                        child: const Text('Cancel', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                      ),
                  ]),
                  if (!_searching) ...[
                    const SizedBox(key: ValueKey('gap2'), height: 12),
                    SegmentedTabs(
                      key: const ValueKey('tabs'),
                      labels: const ['All', 'Favorites', 'Recent'],
                      index: _tab,
                      onChanged: (i) => setState(() => _tab = i),
                    ),
                  ],
                ]),
              ),
              Expanded(
                child: RefreshIndicator(
                  color: c.primary,
                  onRefresh: () => vpnGate.load(force: true),
                  child: ListView(
                    keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: EdgeInsets.fromLTRB(kPageX, 8, kPageX, 24 + MediaQuery.paddingOf(context).bottom),
                    children: _searching
                        ? _results()
                        : switch (_tab) {
                            1 => _saved(settings.favorites, empty: 'Tap the star on any location to save it here.'),
                            2 => _saved(settings.recent, empty: 'Places you connect to show up here.'),
                            _ => _all(),
                          },
                  ),
                ),
              ),
            ]),
          );
        },
      ),
    );
  }

  // ───────── Data helpers ─────────

  List<VpnServer> _serversIn(String code) => vpnGate.all.where((s) => s.code == code).toList();

  bool _isCurrent(VpnServer row) {
    final cur = vpn.activeServer ?? vpn.server;
    if (row.isAuto) return identical(vpn.server, row) && vpn.activeServer == null;
    if (row.premium) return identical(vpn.server, row);
    return cur.isLive && !cur.premium && cur.code == row.code;
  }

  SavedPlace _place(VpnServer s) => SavedPlace(s.code, s.premium ? s.displayName : s.country, premium: s.premium);

  // ───────── Actions ─────────

  void _select(VpnServer s) {
    vpn.clearError();
    vpn.selectServer(s);
    Navigator.pop(context);
  }

  void _tapCountry(VpnServer best) {
    final list = _serversIn(best.code);
    if (list.length > 1) {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => CountryScreen(code: best.code)));
    } else {
      _select(best);
    }
  }

  void _tapPro(VpnServer s) {
    if (!pro.isPro) {
      showProLocationSheet(context, s);
      return;
    }
    _select(s);
  }

  // ───────── Lists ─────────

  List<Widget> _all() {
    final c = context.kc;
    return [
      _SmartCallout(
          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SmartConnectScreen()))),
      SectionLabel('Free', trailing: _refreshButton()),
      ..._freeStatus(),
      _autoRow(autoFreeServer),
      for (final s in vpnGate.byCountry) _countryRow(s),
      if (AppConfig.paywallEnabled) ...[
        SectionLabel(pro.isPro ? 'Pro' : 'Pro · upgrade to unlock'),
        _autoRow(fastestServer),
        for (final s in proServers) _proRow(s),
      ],
      const SizedBox(height: 8),
      Text('Free locations are public VPN Gate volunteer servers.',
          textAlign: TextAlign.center, style: KovraText.caption.copyWith(color: c.hint)),
    ];
  }

  Widget _refreshButton() {
    final c = context.kc;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: vpnGate.loading ? null : () => vpnGate.load(force: true),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: vpnGate.loading
            ? SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: c.muted))
            : Icon(PhosphorIconsRegular.arrowClockwise, size: 16, color: c.muted),
      ),
    );
  }

  List<Widget> _freeStatus() {
    final c = context.kc;
    if (vpnGate.loading && vpnGate.all.isEmpty) {
      return [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(children: [
            SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: c.primary)),
            const SizedBox(width: 12),
            Text('Loading free servers…', style: KovraText.secondary.copyWith(color: c.muted)),
          ]),
        ),
      ];
    }
    if (vpnGate.error != null && vpnGate.all.isEmpty) {
      return [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(vpnGate.error!, style: KovraText.secondary.copyWith(color: c.muted)),
        ),
      ];
    }
    return const [];
  }

  Widget _check() => Icon(PhosphorIconsFill.checkCircle, size: 22, color: context.kc.primary);

  Widget _star(VpnServer s) {
    final c = context.kc;
    final p = _place(s);
    final on = settings.isFavorite(p);
    return IconButton(
      tooltip: on ? 'Remove from favorites' : 'Add to favorites',
      visualDensity: VisualDensity.compact,
      onPressed: () => settings.toggleFavorite(p),
      icon: Icon(on ? PhosphorIconsFill.star : PhosphorIconsRegular.star, size: 20, color: on ? c.star : c.muted),
    );
  }

  Widget _row({required Widget child}) {
    final c = context.kc;
    return DecoratedBox(
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: c.line.withAlpha(160)))),
      child: child,
    );
  }

  Widget _autoRow(VpnServer s) {
    final locked = s.premium && !pro.isPro;
    return _row(
      child: LocationRow(
        code: s.code,
        title: s.country,
        subtitle: s.premium ? 'Pro · picked automatically' : 'Best score right now, with backups',
        trailing: locked ? const LockBadge() : (_isCurrent(s) ? _check() : null),
        onTap: () => s.premium ? _tapPro(s) : _select(s),
      ),
    );
  }

  Widget _countryRow(VpnServer best, {String? query}) {
    final c = context.kc;
    final n = _serversIn(best.code).length;
    final sub = [
      '$n ${n == 1 ? 'server' : 'servers'}',
      if (best.pingMs != null && best.pingMs! > 0) '${best.pingMs} ms'
    ].join(' · ');
    return _row(
      child: _HighlightRow(
        code: best.code,
        title: best.country,
        query: query,
        subtitle: sub,
        onTap: () => _tapCountry(best),
        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
          if (!pro.isPro && AppConfig.paywallEnabled && !_isCurrent(best)) const Tag('FREE'),
          if (_isCurrent(best)) _check(),
          _star(best),
          if (n > 1) Icon(PhosphorIconsRegular.caretRight, size: 16, color: c.muted),
        ]),
      ),
    );
  }

  Widget _proRow(VpnServer s, {String? query}) {
    final locked = !pro.isPro;
    final cat = switch (s.category) { 'streaming' => 'Streaming', 'gaming' => 'Gaming', _ => 'All uses' };
    return _row(
      child: _HighlightRow(
        code: s.code,
        title: s.displayName,
        query: query,
        subtitle: '$cat · Pro',
        onTap: () => _tapPro(s),
        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
          if (_isCurrent(s)) _check(),
          _star(s),
          if (locked) const LockBadge(),
        ]),
      ),
    );
  }

  List<Widget> _saved(List<SavedPlace> places, {required String empty}) {
    final c = context.kc;
    final rows = <Widget>[];
    for (final p in places) {
      if (p.premium) {
        final s = proServers.where((x) => x.code == p.code && x.displayName == p.country).firstOrNull;
        if (s != null) rows.add(_proRow(s));
        continue;
      }
      final live = _serversIn(p.code);
      if (live.isNotEmpty) {
        rows.add(_countryRow(live.first));
      } else {
        rows.add(_row(
          child: LocationRow(
            code: p.code,
            title: p.country,
            subtitle: vpnGate.loading ? 'Checking…' : 'No free server online right now',
            trailing: _tab == 1
                ? IconButton(
                    tooltip: 'Remove from favorites',
                    onPressed: () => settings.toggleFavorite(p),
                    icon: Icon(PhosphorIconsFill.star, size: 20, color: c.star),
                  )
                : null,
          ),
        ));
      }
    }
    return [
      ...rows,
      const SizedBox(height: 16),
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: c.line),
        ),
        child: Row(children: [
          Icon(_tab == 1 ? PhosphorIconsRegular.star : PhosphorIconsRegular.clockCounterClockwise,
              size: 20, color: c.muted),
          const SizedBox(width: 12),
          Expanded(child: Text(empty, style: KovraText.secondary.copyWith(color: c.muted))),
        ]),
      ),
    ];
  }

  List<Widget> _results() {
    final c = context.kc;
    final q = _q.text.trim().toLowerCase();
    if (q.isEmpty) {
      return [
        const SizedBox(height: 8),
        Text(AppConfig.paywallEnabled ? 'Type a country, or a Pro city like London.' : 'Type a country.',
            style: KovraText.secondary.copyWith(color: c.muted)),
      ];
    }
    final free = vpnGate.byCountry.where((s) => s.country.toLowerCase().contains(q)).toList();
    final paid = AppConfig.paywallEnabled
        ? proServers.where((s) => s.displayName.toLowerCase().contains(q)).toList()
        : const <VpnServer>[];
    final n = free.length + paid.length;
    return [
      SectionLabel('$n ${n == 1 ? 'result' : 'results'}', padding: const EdgeInsets.fromLTRB(0, 8, 0, 4)),
      for (final s in free) _countryRow(s, query: q),
      for (final s in paid) _proRow(s, query: q),
      if (n == 0 && vpnGate.loading)
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text('Still loading free servers…', style: KovraText.secondary.copyWith(color: c.muted)),
        ),
    ];
  }
}

/// Location row whose title highlights the search match in `primary`.
class _HighlightRow extends StatelessWidget {
  final String code, title, subtitle;
  final String? query;
  final Widget? trailing;
  final VoidCallback onTap;
  const _HighlightRow({
    required this.code,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.query,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.kc;
    final base = KovraText.bodyL.copyWith(color: c.text);
    final q = query ?? '';
    final i = q.isEmpty ? -1 : title.toLowerCase().indexOf(q);
    final titleW = i < 0
        ? Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: base)
        : Text.rich(
            TextSpan(children: [
              TextSpan(text: title.substring(0, i)),
              TextSpan(text: title.substring(i, i + q.length), style: TextStyle(color: c.primary)),
              TextSpan(text: title.substring(i + q.length)),
            ]),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: base,
          );
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(children: [
          FlagCircle(code: code, size: 44),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              titleW,
              const SizedBox(height: 2),
              Text(subtitle, style: TextStyle(fontSize: 13, color: c.muted, fontFeatures: KovraText.tabular)),
            ]),
          ),
          if (trailing != null) trailing!,
        ]),
      ),
    );
  }
}

class _SmartCallout extends StatelessWidget {
  final VoidCallback onTap;
  const _SmartCallout({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = context.kc;
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Material(
        color: c.primarySoft,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(children: [
              Icon(PhosphorIconsFill.sparkle, size: 22, color: c.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Smart Connect', style: KovraText.bodyStrong.copyWith(color: c.text)),
                  Text('Pick a free server by score, ping or speed', style: KovraText.caption.copyWith(color: c.muted)),
                ]),
              ),
              Icon(PhosphorIconsRegular.caretRight, size: 16, color: c.primary),
            ]),
          ),
        ),
      ),
    );
  }
}

/// 150 pt mini brand header: status + timer (Locations, Country, Search).
class MiniStatusHeader extends StatefulWidget {
  final double height;
  const MiniStatusHeader({super.key, required this.height});

  @override
  State<MiniStatusHeader> createState() => _MiniStatusHeaderState();
}

class _MiniStatusHeaderState extends State<MiniStatusHeader> {
  Timer? _t;

  @override
  void initState() {
    super.initState();
    _t = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && vpn.status == VpnStatus.connected) setState(() {});
    });
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.kc;
    final st = vpn.status;
    final on = st == VpnStatus.connected || st == VpnStatus.connecting;
    final s = vpn.activeServer ?? vpn.server;
    final (IconData icon, String title, String sub) = switch (st) {
      VpnStatus.connected => (
          PhosphorIconsFill.shieldCheck,
          s.isAuto ? 'Connected' : 'Connected · ${s.placeName}',
          vpn.connectedAt == null ? '' : fmtClock(DateTime.now().difference(vpn.connectedAt!)),
        ),
      VpnStatus.connecting => (PhosphorIconsRegular.shield, 'Connecting…', vpn.stage),
      VpnStatus.disconnected => (
          PhosphorIconsRegular.shieldSlash,
          'Not protected',
          pro.isPro ? AppConfig.proName : 'Free plan',
        ),
    };
    final fg = on ? c.onPrimary : c.text;
    return BrandArea(
      height: widget.height,
      protected: on,
      child: Padding(
        padding: EdgeInsets.fromLTRB(kPageX, MediaQuery.paddingOf(context).top + 12, kPageX, kSheetOverlap),
        child: Align(
          alignment: Alignment.topLeft,
          child: Row(children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(shape: BoxShape.circle, color: on ? Colors.white.withAlpha(38) : c.card),
              child: Icon(icon, size: 22, color: on ? c.onPrimary : c.muted),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: fg)),
                if (sub.isNotEmpty)
                  Text(sub,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 13, color: fg.withAlpha(204), fontFeatures: KovraText.tabular)),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

/// 3.3 Country detail: the live VPN Gate servers in one country.
class CountryScreen extends StatelessWidget {
  final String code;
  const CountryScreen({super.key, required this.code});

  Future<void> _connectTo(BuildContext context, VpnServer s) async {
    final nav = Navigator.of(context);
    if (vpn.status == VpnStatus.disconnected && !await ensureVpnExplained(context)) return;
    nav.popUntil((r) => r.settings.name == kHomeRoute.name || r.isFirst);
    vpn.clearError();
    if (vpn.status == VpnStatus.disconnected) {
      await vpn.selectServer(s);
      vpn.connect();
    } else {
      vpn.selectServer(s); // switches on the fly
    }
  }

  void _pick(BuildContext context, VpnServer s) {
    vpn.clearError();
    vpn.selectServer(s);
    popToHome(context);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.kc;
    return Scaffold(
      body: ListenableBuilder(
        listenable: Listenable.merge([vpnGate, vpn]),
        builder: (context, _) {
          final list = vpnGate.all.where((s) => s.code == code).toList();
          final h = BrandSheetLayout.fit(context, 150);
          final name = list.isEmpty ? code : list.first.country;
          final maxSpeed = list.fold<double>(0, (m, s) => (s.speedMbps ?? 0) > m ? s.speedMbps! : m);
          final cur = vpn.activeServer;
          return BrandSheetLayout(
            brandHeight: h,
            brand: MiniStatusHeader(height: h),
            body: ListView(
              padding: EdgeInsets.fromLTRB(kPageX, 0, kPageX, 16),
              children: [
                Row(children: [
                  RoundIconButton(
                    icon: PhosphorIconsRegular.arrowLeft,
                    tooltip: 'Back',
                    background: c.surface,
                    onTap: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('${FlagCircle.flag(code)} $name', style: KovraText.title.copyWith(color: c.text)),
                      Text('${list.length} free ${list.length == 1 ? 'server' : 'servers'} · VPN Gate',
                          style: KovraText.secondary.copyWith(color: c.muted)),
                    ]),
                  ),
                ]),
                const SizedBox(height: 16),
                if (list.isEmpty)
                  Text('No free server in this country is online right now.',
                      style: KovraText.body.copyWith(color: c.muted))
                else
                  Container(
                    decoration: BoxDecoration(
                      color: c.card,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: c.primary, width: 2),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Material(
                      type: MaterialType.transparency,
                      child: Column(children: [
                        for (var i = 0; i < list.length; i++) ...[
                          if (i > 0) Divider(height: 1, color: c.line),
                          _ServerLine(
                            server: list[i],
                            best: i == 0,
                            current: cur != null && cur.ip == list[i].ip,
                            selected: cur == null && identical(vpn.server, list[i]),
                            speed: maxSpeed <= 0 ? 0 : (list[i].speedMbps ?? 0) / maxSpeed,
                            onTap: () => _pick(context, list[i]),
                          ),
                        ],
                      ]),
                    ),
                  ),
                const SizedBox(height: 12),
                Text('Bar shows each server\'s measured speed, relative to the fastest here.',
                    style: KovraText.caption.copyWith(color: c.hint)),
              ],
            ),
            bottom: KovraButton.primary(
              label: 'Connect to best in $name',
              onPressed: list.isEmpty ? null : () => _connectTo(context, list.first),
            ),
          );
        },
      ),
    );
  }
}

class _ServerLine extends StatelessWidget {
  final VpnServer server;
  final bool best, current, selected;
  final double speed;
  final VoidCallback onTap;
  const _ServerLine({
    required this.server,
    required this.best,
    required this.current,
    required this.selected,
    required this.speed,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.kc;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Flexible(
                  child: Text(server.host,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600, color: c.text)),
                ),
                if (current) ...[
                  const SizedBox(width: 8),
                  Tag('CURRENT', color: c.success, background: Colors.transparent)
                ],
                if (selected) ...[
                  const SizedBox(width: 8),
                  Tag('SELECTED', color: c.primary, background: Colors.transparent)
                ],
                if (best && !current && !selected) ...[const SizedBox(width: 8), const Tag('BEST')],
              ]),
              const SizedBox(height: 2),
              Text(server.ip ?? '', style: TextStyle(fontSize: 12.5, color: c.muted, fontFeatures: KovraText.tabular)),
            ]),
          ),
          const SizedBox(width: 12),
          SpeedBar(value: speed),
          const SizedBox(width: 12),
          SizedBox(
            width: 64,
            child: Text(
              server.pingMs != null && server.pingMs! > 0 ? '${server.pingMs} ms' : '—',
              textAlign: TextAlign.right,
              style: TextStyle(fontSize: 13, color: c.muted, fontFeatures: KovraText.tabular),
            ),
          ),
        ]),
      ),
    );
  }
}
