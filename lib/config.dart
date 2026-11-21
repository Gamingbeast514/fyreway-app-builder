/// Central app settings. Every value can be set at build time with
/// `--dart-define` (the FyreWay white-label form does this). Without any
/// defines the app builds as Kovra VPN.
class AppConfig {
  static const appName = String.fromEnvironment('APP_NAME', defaultValue: 'Kovra VPN');
  static const version = '1.0.0';
  static const packageId = String.fromEnvironment('APP_ID', defaultValue: 'com.kovravpn.app');

  /// Short brand for sentences: "Kovra VPN" -> "Kovra". Names without a
  /// trailing "VPN" are used as they are.
  static String get brand {
    final b = appName.replaceFirst(RegExp(r'\s+VPN$', caseSensitive: false), '').trim();
    return b.isEmpty ? appName : b;
  }

  /// The subscription's name: "Kovra Pro".
  static String get proName => '$brand Pro';

  /// Ads: there is no ad SDK yet, so this only decides whether the app may
  /// promise "no ads". Nothing fake is shown either way.
  static const adsEnabled = bool.fromEnvironment('ADS_ENABLED', defaultValue: false);

  /// Subscriptions (paywall, Pro locations, upgrade prompts).
  static const paywallEnabled = bool.fromEnvironment('PAYWALL_ENABLED', defaultValue: true);

  /// A customer logo was copied to assets/brand/custom_logo.png by the build.
  static const hasCustomLogo = bool.fromEnvironment('HAS_CUSTOM_LOGO', defaultValue: false);

  static const plansRaw = String.fromEnvironment('PLANS', defaultValue: 'weekly,monthly,yearly');

  // Optional tools.
  static const enableLocationChecker = bool.fromEnvironment('MOD_LOCATION', defaultValue: true);
  static const enableSpeedTest = bool.fromEnvironment('MOD_SPEED', defaultValue: true);
  static const enableInvite = bool.fromEnvironment('MOD_INVITE', defaultValue: true);

  /// White-label builds set these; they size the Pro placeholder list.
  /// Free locations always come live from VPN Gate.
  static const isWhiteLabel = bool.hasEnvironment('APP_NAME');
  static const premiumServersCount = int.fromEnvironment('PREM_SERVERS', defaultValue: 0);
  static const gamingServersCount = int.fromEnvironment('GAMING_SERVERS', defaultValue: 0);
  static const streamingServersCount = int.fromEnvironment('STREAMING_SERVERS', defaultValue: 0);

  static const playStoreUrl = 'https://play.google.com/store/apps/details?id=$packageId';

  static String get inviteText =>
      'I use $appName to stay private on public WiFi. ${adsEnabled ? '' : 'No ads, '}one tap to connect. '
      'Get it here: $playStoreUrl';
}

/// Subscription plans. Product IDs must match Google Play Console / App Store Connect.
/// PRICES BELOW ARE PLACEHOLDERS - real prices come from the store once billing is connected.
class ProPlan {
  final String id, title, price, period, note;
  final bool bestValue;
  const ProPlan(this.id, this.title, this.price, this.period, this.note, {this.bestValue = false});

  static const _yearly = ProPlan('kovra_pro_yearly', 'Yearly', 'Rs 6,500', '/year', 'Rs 125 per week', bestValue: true);
  static const _monthly = ProPlan('kovra_pro_monthly', 'Monthly', 'Rs 1,100', '/month', 'Rs 255 per week');
  static const _weekly = ProPlan('kovra_pro_weekly', 'Weekly', 'Rs 450', '/week', 'Flexible, cancel anytime');

  /// The plans picked in the form (all three by default). The best value is
  /// the longest plan offered.
  static final List<ProPlan> all = () {
    final on = AppConfig.plansRaw.split(',').map((e) => e.trim().toLowerCase()).toSet();
    final list = [
      if (on.contains('yearly')) _yearly,
      if (on.contains('monthly')) _monthly,
      if (on.contains('weekly')) _weekly,
    ];
    if (list.isEmpty) return const [_monthly];
    return [
      for (var i = 0; i < list.length; i++)
        ProPlan(list[i].id, list[i].title, list[i].price, list[i].period, list[i].note, bestValue: i == 0),
    ];
  }();
}
