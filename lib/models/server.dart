import '../config.dart';

/// One VPN location shown in the demo list.
class VpnServer {
  final String code; // country code ("DE") or "AUTO"
  final String country;
  final String city;
  final String category; // 'all', 'streaming' or 'gaming'
  final bool premium; // Pro only
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
}

const autoFreeServer = VpnServer(code: 'AUTO', country: 'Best free location', city: 'Picked automatically');
const fastestServer = VpnServer(code: 'AUTO', country: 'Fastest location', city: 'Picked automatically', premium: true);

const _freePool = <VpnServer>[
  VpnServer(code: 'US', country: 'United States', city: 'New York', pingMs: 42),
  VpnServer(code: 'DE', country: 'Germany', city: 'Frankfurt', pingMs: 28),
  VpnServer(code: 'SG', country: 'Singapore', city: 'Marina Bay', pingMs: 55),
  VpnServer(code: 'GB', country: 'United Kingdom', city: 'London', pingMs: 36),
  VpnServer(code: 'NL', country: 'Netherlands', city: 'Amsterdam', pingMs: 31),
  VpnServer(code: 'CA', country: 'Canada', city: 'Toronto', pingMs: 64),
  VpnServer(code: 'FR', country: 'France', city: 'Paris', pingMs: 39),
  VpnServer(code: 'JP', country: 'Japan', city: 'Tokyo', pingMs: 88),
];

const _gamingPool = <VpnServer>[
  VpnServer(code: 'AE', country: 'UAE', city: 'Dubai · Gaming', category: 'gaming', premium: true, pingMs: 18),
  VpnServer(code: 'DE', country: 'Germany', city: 'Frankfurt · Gaming', category: 'gaming', premium: true, pingMs: 22),
  VpnServer(code: 'SG', country: 'Singapore', city: 'Gaming Node', category: 'gaming', premium: true, pingMs: 26),
  VpnServer(code: 'JP', country: 'Japan', city: 'Tokyo · Gaming', category: 'gaming', premium: true, pingMs: 34),
  VpnServer(code: 'US', country: 'United States', city: 'Dallas · Gaming', category: 'gaming', premium: true, pingMs: 45),
  VpnServer(code: 'KR', country: 'South Korea', city: 'Seoul · Gaming', category: 'gaming', premium: true, pingMs: 31),
];

const _streamingPool = <VpnServer>[
  VpnServer(code: 'US', country: 'United States', city: 'Los Angeles · Stream', category: 'streaming', premium: true, pingMs: 48),
  VpnServer(code: 'GB', country: 'United Kingdom', city: 'London · Stream', category: 'streaming', premium: true, pingMs: 34),
  VpnServer(code: 'CA', country: 'Canada', city: 'Toronto · Stream', category: 'streaming', premium: true, pingMs: 52),
  VpnServer(code: 'AU', country: 'Australia', city: 'Sydney · Stream', category: 'streaming', premium: true, pingMs: 92),
  VpnServer(code: 'JP', country: 'Japan', city: 'Osaka · Stream', category: 'streaming', premium: true, pingMs: 76),
  VpnServer(code: 'IT', country: 'Italy', city: 'Milan · Stream', category: 'streaming', premium: true, pingMs: 41),
];

const _vipPool = <VpnServer>[
  VpnServer(code: 'CH', country: 'Switzerland', city: 'Zurich', premium: true, pingMs: 29),
  VpnServer(code: 'SE', country: 'Sweden', city: 'Stockholm', premium: true, pingMs: 33),
  VpnServer(code: 'NO', country: 'Norway', city: 'Oslo', premium: true, pingMs: 37),
  VpnServer(code: 'ES', country: 'Spain', city: 'Madrid', premium: true, pingMs: 44),
  VpnServer(code: 'TR', country: 'Turkey', city: 'Istanbul', premium: true, pingMs: 39),
  VpnServer(code: 'IN', country: 'India', city: 'Mumbai', premium: true, pingMs: 27),
  VpnServer(code: 'BR', country: 'Brazil', city: 'Sao Paulo', premium: true, pingMs: 112),
  VpnServer(code: 'PL', country: 'Poland', city: 'Warsaw', premium: true, pingMs: 35),
];

List<VpnServer> _take(List<VpnServer> pool, int count, {String? suffix}) {
  if (count <= 0) return const [];
  return List.generate(count, (i) {
    final base = pool[i % pool.length];
    if (i < pool.length) return base;
    final n = (i ~/ pool.length) + 1;
    return VpnServer(
      code: base.code,
      country: base.country,
      city: '${base.city} #$n${suffix ?? ''}',
      category: base.category,
      premium: base.premium,
      pingMs: (base.pingMs ?? 40) + n * 3,
    );
  });
}

List<VpnServer> get demoFreeServers => _take(_freePool, AppConfig.freeServersCount);

List<VpnServer> get demoPremiumServers => [
      ..._take(_gamingPool, AppConfig.gamingServersCount),
      ..._take(_streamingPool, AppConfig.streamingServersCount),
      ..._take(_vipPool, AppConfig.premiumServersCount),
    ];

VpnServer get defaultFreeServer => demoFreeServers.isNotEmpty ? demoFreeServers.first : autoFreeServer;
