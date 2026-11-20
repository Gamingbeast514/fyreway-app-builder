import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../models/server.dart';

/// FREE TEST SERVERS from VPN Gate (vpngate.net) - a public network of volunteer
/// OpenVPN servers run as a research project by the University of Tsukuba, Japan.
///
/// Good for testing a real tunnel today. Before launch, free + Pro move to our
/// own servers (volunteer servers can be slow, go offline, and keep their own logs).
class VpnGateService extends ChangeNotifier {
  static const _urls = [
    'https://www.vpngate.net/api/iphone/',
    'http://www.vpngate.net/api/iphone/',
  ];

  /// Every working server, best score first.
  List<VpnServer> all = [];
  bool loading = false;
  String? error;
  DateTime? loadedAt;

  /// One entry per country (its best server), for the list screen.
  List<VpnServer> get byCountry {
    final seen = <String>{};
    final out = <VpnServer>[];
    for (final s in all) {
      if (seen.add(s.code)) out.add(s);
    }
    return out;
  }

  /// Backups for a country, best first.
  List<VpnServer> candidates(String code) => all.where((s) => s.code == code).take(3).toList();

  Future<void> load({bool force = false}) async {
    if (loading) return;
    final fresh = loadedAt != null && DateTime.now().difference(loadedAt!) < const Duration(minutes: 20);
    if (!force && fresh && all.isNotEmpty) return;
    loading = true;
    error = null;
    notifyListeners();
    try {
      String? body;
      for (final u in _urls) {
        try {
          body = await _get(u);
          if (body.contains('*vpn_servers')) break;
        } catch (_) {
          body = null;
        }
      }
      if (body == null) throw Exception('Server list unavailable');
      all = parse(body);
      loadedAt = DateTime.now();
      if (all.isEmpty) error = 'No free servers online right now';
    } catch (e) {
      error = 'Could not load free servers. Check your internet.';
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<String> _get(String url) async {
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 10);
    try {
      final req = await client.getUrl(Uri.parse(url));
      final res = await req.close().timeout(const Duration(seconds: 20));
      return await res.transform(utf8.decoder).join().timeout(const Duration(seconds: 30));
    } finally {
      client.close(force: true);
    }
  }

  /// CSV: HostName,IP,Score,Ping,Speed,CountryLong,CountryShort,NumVpnSessions,
  /// Uptime,TotalUsers,TotalTraffic,LogType,Operator,Message,OpenVPN_ConfigData_Base64
  static List<VpnServer> parse(String body) {
    final out = <VpnServer>[];
    for (final line in const LineSplitter().convert(body)) {
      if (line.isEmpty || line.startsWith('*') || line.startsWith('#')) continue;
      final f = line.split(',');
      if (f.length < 15) continue;
      final b64 = f.last.trim();
      if (b64.isEmpty) continue;
      String config;
      try {
        config = utf8.decode(base64.decode(b64), allowMalformed: true);
      } catch (_) {
        continue;
      }
      if (!config.contains('remote ')) continue;
      final code = f[6].trim().toUpperCase();
      if (code.length != 2) continue;
      out.add(VpnServer(
        code: code,
        country: _niceCountry(f[5].trim()),
        city: 'Free server ${f[0].trim()}',
        ip: f[1].trim(),
        score: int.tryParse(f[2].trim()) ?? 0,
        pingMs: int.tryParse(f[3].trim()),
        speedMbps: (int.tryParse(f[4].trim()) ?? 0) / 1e6,
        ovpnConfig: _patch(config),
      ));
    }
    out.sort((a, b) => b.score.compareTo(a.score));
    return out;
  }

  /// Older VPN Gate servers only speak AES-128-CBC; newer OpenVPN needs it allowed.
  static String _patch(String c) {
    if (c.contains('data-ciphers')) return c;
    return '$c\ndata-ciphers AES-256-GCM:AES-128-GCM:CHACHA20-POLY1305:AES-128-CBC\n'
        'data-ciphers-fallback AES-128-CBC\n';
  }

  static String _niceCountry(String s) => switch (s) {
        'Korea Republic of' => 'South Korea',
        'Russian Federation' => 'Russia',
        'Viet Nam' => 'Vietnam',
        _ => s,
      };
}

final vpnGate = VpnGateService();
