import '../config.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

/// Public IP + location of the current connection.
class IpInfo {
  final String ip, city, region, country, isp, timezone;
  const IpInfo({
    required this.ip,
    required this.city,
    required this.region,
    required this.country,
    required this.isp,
    required this.timezone,
  });

  String get place => [city, country].where((s) => s.isNotEmpty).join(', ');
}

/// Real network tools built on dart:io (no extra libraries).
/// Speed test uses Cloudflare's public speed endpoints.
class NetworkTools {
  static final HttpClient _client = HttpClient()..connectionTimeout = const Duration(seconds: 10);

  static Future<Map<String, dynamic>> _getJson(String url) async {
    final req = await _client.getUrl(Uri.parse(url));
    req.headers.set(HttpHeaders.userAgentHeader, '${AppConfig.appName}/1.0');
    final res = await req.close().timeout(const Duration(seconds: 12));
    final body = await res.transform(utf8.decoder).join();
    if (res.statusCode != 200) throw HttpException('HTTP ${res.statusCode}');
    return jsonDecode(body) as Map<String, dynamic>;
  }

  static String _s(Object? v) => v == null ? '' : '$v';

  static Future<IpInfo> ipInfo() async {
    try {
      final j = await _getJson('https://ipwho.is/');
      if (j['success'] == false) throw const FormatException('lookup failed');
      return IpInfo(
        ip: _s(j['ip']),
        city: _s(j['city']),
        region: _s(j['region']),
        country: _s(j['country']),
        isp: _s((j['connection'] as Map?)?['isp']),
        timezone: _s((j['timezone'] as Map?)?['id']),
      );
    } catch (_) {
      final j = await _getJson('https://ipapi.co/json/'); // backup service
      return IpInfo(
        ip: _s(j['ip']),
        city: _s(j['city']),
        region: _s(j['region']),
        country: _s(j['country_name']),
        isp: _s(j['org']),
        timezone: _s(j['timezone']),
      );
    }
  }

  /// Median round-trip time in milliseconds.
  static Future<int> pingMs() async {
    final times = <int>[];
    for (var i = 0; i < 5; i++) {
      final sw = Stopwatch()..start();
      final req = await _client.getUrl(Uri.parse('https://speed.cloudflare.com/__down?bytes=0'));
      final res = await req.close().timeout(const Duration(seconds: 10));
      await res.drain<void>();
      sw.stop();
      if (i > 0) times.add(sw.elapsedMilliseconds); // first one includes connection setup
    }
    times.sort();
    return times[times.length ~/ 2];
  }

  /// Downloads for up to [maxTime] and returns Mbps. [onProgress] gets live Mbps.
  static Future<double> downloadMbps({
    void Function(double mbps)? onProgress,
    Duration maxTime = const Duration(seconds: 8),
  }) async {
    final req = await _client.getUrl(Uri.parse('https://speed.cloudflare.com/__down?bytes=200000000'));
    final res = await req.close().timeout(const Duration(seconds: 10));
    final sw = Stopwatch()..start();
    var bytes = 0;
    final done = Completer<double>();
    double mbps() => sw.elapsedMicroseconds == 0 ? 0 : bytes * 8 / sw.elapsedMicroseconds; // bits/µs = Mbps
    late StreamSubscription<List<int>> sub;
    sub = res.listen(
      (chunk) {
        bytes += chunk.length;
        onProgress?.call(mbps());
        if (sw.elapsed >= maxTime && !done.isCompleted) {
          sub.cancel();
          done.complete(mbps());
        }
      },
      onDone: () {
        if (!done.isCompleted) done.complete(mbps());
      },
      onError: (Object e) {
        if (!done.isCompleted) done.completeError(e);
      },
      cancelOnError: true,
    );
    return done.future;
  }

  /// Uploads [totalBytes] and returns Mbps.
  static Future<double> uploadMbps({
    void Function(double mbps)? onProgress,
    int totalBytes = 10 * 1024 * 1024,
  }) async {
    final req = await _client.postUrl(Uri.parse('https://speed.cloudflare.com/__up'));
    req.contentLength = totalBytes;
    req.headers.contentType = ContentType.binary;
    final block = Uint8List(64 * 1024);
    final sw = Stopwatch()..start();
    var sent = 0;
    while (sent < totalBytes) {
      final n = min(block.length, totalBytes - sent);
      req.add(n == block.length ? block : block.sublist(0, n));
      await req.flush();
      sent += n;
      if (sw.elapsedMicroseconds > 0) onProgress?.call(sent * 8 / sw.elapsedMicroseconds);
    }
    final res = await req.close().timeout(const Duration(seconds: 20));
    await res.drain<void>();
    sw.stop();
    return totalBytes * 8 / sw.elapsedMicroseconds;
  }
}
