import '../config.dart';

/// One VPN location shown in the list.
class VpnServer {
  final String code; // country code ("DE") or "AUTO"
  final String country;
  final String city;
  final String category; // 'all', 'streaming' or 'gaming'
  final bool premium; // Pro only

  /// Live data (free servers from VPN Gate). Null for placeholders.
  final String? ovpnConfig;
  final String? ip;
  final int? pingMs;
  final double? speedMbps;
  final int score;

  const VpnServer({
    required this.code,
    required this.country,
    required this.city,
    this.category = 'all',
    this.premium = false,
    this.ovpnConfig,
    this.ip,
    this.pingMs,
    this.speedMbps,
    this.score = 0,
  });

  bool get isLive => ovpnConfig != null;

  bool get isAuto => code == 'AUTO';

  /// A Pro location without its own servers yet.
  bool get isPlaceholder => !isLive && !isAuto;

  /// VPN Gate host name ("public-vpn-123"), from the "Free server <host>" label.
  String get host => city.startsWith('Free server ') ? city.substring(12) : city;

  /// Name for the UI: "Germany", "London, United Kingdom", "Best free location".
  String get displayName => isPlaceholder ? '$city, $country' : country;

  /// Short place for sentences: "Germany", "London", "the best free location".
  String get placeName => isAuto ? 'the ${country.toLowerCase()}' : (isPlaceholder ? city : country);

  /// "18 ms · 42 Mbps" when known.
  String get stats {
    final p = pingMs, sp = speedMbps;
    return [
      if (p != null && p > 0) '$p ms',
      if (sp != null && sp > 0) '${sp.toStringAsFixed(sp >= 10 ? 0 : 1)} Mbps',
    ].join(' · ');
  }

  /// Subtitle for location rows.
  String get rowSubtitle {
    if (isAuto) return premium ? 'Pro · picked automatically' : 'Picked automatically';
    if (isPlaceholder) return 'Pro location';
    return ['Free server', if (stats.isNotEmpty) stats].join(' · ');
  }
}

/// Free: connects to the best free server right now.
const autoFreeServer = VpnServer(code: 'AUTO', country: 'Best free location', city: 'Picked automatically');

/// Pro: picks the fastest server automatically.
const fastestServer = VpnServer(code: 'AUTO', country: 'Fastest location', city: 'Picked automatically', premium: true);

/// Pro locations: placeholders until our own servers are live (backend docs pending).
/// White-label builds size this list from the form's server counts.
final List<VpnServer> proServers = AppConfig.isWhiteLabel &&
        AppConfig.premiumServersCount + AppConfig.gamingServersCount + AppConfig.streamingServersCount > 0
    ? [
        ..._take(_streamingPool, AppConfig.streamingServersCount),
        ..._take(_gamingPool, AppConfig.gamingServersCount),
        ..._take(_generalPool, AppConfig.premiumServersCount),
      ]
    : const [
        VpnServer(code: 'US', country: 'United States', city: 'New York', category: 'streaming', premium: true),
        VpnServer(code: 'GB', country: 'United Kingdom', city: 'London', category: 'streaming', premium: true),
        VpnServer(code: 'DE', country: 'Germany', city: 'Frankfurt', category: 'gaming', premium: true),
        VpnServer(code: 'AE', country: 'UAE', city: 'Dubai', category: 'gaming', premium: true),
        VpnServer(code: 'JP', country: 'Japan', city: 'Tokyo', category: 'gaming', premium: true),
        VpnServer(code: 'CA', country: 'Canada', city: 'Toronto', category: 'streaming', premium: true),
      ];

const _streamingPool = [
  VpnServer(code: 'US', country: 'United States', city: 'Los Angeles', category: 'streaming', premium: true),
  VpnServer(code: 'GB', country: 'United Kingdom', city: 'London', category: 'streaming', premium: true),
  VpnServer(code: 'CA', country: 'Canada', city: 'Toronto', category: 'streaming', premium: true),
  VpnServer(code: 'AU', country: 'Australia', city: 'Sydney', category: 'streaming', premium: true),
  VpnServer(code: 'JP', country: 'Japan', city: 'Osaka', category: 'streaming', premium: true),
  VpnServer(code: 'IT', country: 'Italy', city: 'Milan', category: 'streaming', premium: true),
];

const _gamingPool = [
  VpnServer(code: 'AE', country: 'UAE', city: 'Dubai', category: 'gaming', premium: true),
  VpnServer(code: 'DE', country: 'Germany', city: 'Frankfurt', category: 'gaming', premium: true),
  VpnServer(code: 'SG', country: 'Singapore', city: 'Singapore', category: 'gaming', premium: true),
  VpnServer(code: 'JP', country: 'Japan', city: 'Tokyo', category: 'gaming', premium: true),
  VpnServer(code: 'US', country: 'United States', city: 'Dallas', category: 'gaming', premium: true),
  VpnServer(code: 'KR', country: 'South Korea', city: 'Seoul', category: 'gaming', premium: true),
];

const _generalPool = [
  VpnServer(code: 'CH', country: 'Switzerland', city: 'Zurich', premium: true),
  VpnServer(code: 'SE', country: 'Sweden', city: 'Stockholm', premium: true),
  VpnServer(code: 'NL', country: 'Netherlands', city: 'Amsterdam', premium: true),
  VpnServer(code: 'FR', country: 'France', city: 'Paris', premium: true),
  VpnServer(code: 'ES', country: 'Spain', city: 'Madrid', premium: true),
  VpnServer(code: 'TR', country: 'Turkey', city: 'Istanbul', premium: true),
  VpnServer(code: 'IN', country: 'India', city: 'Mumbai', premium: true),
  VpnServer(code: 'BR', country: 'Brazil', city: 'Sao Paulo', premium: true),
  VpnServer(code: 'PL', country: 'Poland', city: 'Warsaw', premium: true),
  VpnServer(code: 'NO', country: 'Norway', city: 'Oslo', premium: true),
];

/// [count] entries from [pool]; repeats get a number ("London 2").
List<VpnServer> _take(List<VpnServer> pool, int count) => List.generate(count.clamp(0, 60), (i) {
      final b = pool[i % pool.length];
      final n = i ~/ pool.length;
      return n == 0
          ? b
          : VpnServer(
              code: b.code, country: b.country, city: '${b.city} ${n + 1}', category: b.category, premium: true);
    });

VpnServer get defaultFreeServer => autoFreeServer;
