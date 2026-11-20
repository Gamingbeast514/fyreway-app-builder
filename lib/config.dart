/// Central app settings. Driven by `--dart-define` from the FyreWay White-Label form.
class AppConfig {
  static const appName = String.fromEnvironment('APP_NAME', defaultValue: 'Kovra VPN');
  static const version = '1.0.0';
  static const packageId = String.fromEnvironment('APP_ID', defaultValue: 'com.kovravpn.app');

  static const adsEnabled = bool.fromEnvironment('ADS_ENABLED', defaultValue: false);
  static const paywallEnabled = bool.fromEnvironment('PAYWALL_ENABLED', defaultValue: true);
  static const hasCustomLogo = bool.fromEnvironment('HAS_CUSTOM_LOGO', defaultValue: false);
  static const plansRaw = String.fromEnvironment('PLANS', defaultValue: 'weekly,monthly,yearly');

  static const enableLocationChecker = bool.fromEnvironment('MOD_LOCATION', defaultValue: true);
  static const enableSpeedTest = bool.fromEnvironment('MOD_SPEED', defaultValue: true);
  static const enableInvite = bool.fromEnvironment('MOD_INVITE', defaultValue: true);

  static const freeServersCount = int.fromEnvironment('FREE_SERVERS', defaultValue: 5);
  static const premiumServersCount = int.fromEnvironment('PREM_SERVERS', defaultValue: 10);
  static const gamingServersCount = int.fromEnvironment('GAMING_SERVERS', defaultValue: 4);
  static const streamingServersCount = int.fromEnvironment('STREAMING_SERVERS', defaultValue: 4);

  static const playStoreUrl = 'https://play.google.com/store/apps/details?id=$packageId';

  static const inviteText =
      'I use $appName to stay private on public WiFi. One tap to connect. '
      'Get it here: $playStoreUrl';
}

/// Subscription plans filtered by the form selection.
class ProPlan {
  final String id, title, price, period, note;
  final bool bestValue;
  const ProPlan(this.id, this.title, this.price, this.period, this.note, {this.bestValue = false});

  static List<ProPlan> get all {
    final enabled = AppConfig.plansRaw.split(',').map((e) => e.trim()).toSet();
    final list = <ProPlan>[
      if (enabled.contains('yearly'))
        const ProPlan('pro_yearly', 'Yearly', 'Rs 6,500', '/year', 'Rs 125 per week', bestValue: true),
      if (enabled.contains('monthly'))
        const ProPlan('pro_monthly', 'Monthly', 'Rs 1,100', '/month', 'Rs 255 per week'),
      if (enabled.contains('weekly'))
        const ProPlan('pro_weekly', 'Weekly', 'Rs 450', '/week', 'Flexible, cancel anytime'),
    ];
    return list.isEmpty
        ? [const ProPlan('pro_monthly', 'Monthly', 'Rs 1,100', '/month', 'Full VIP access', bestValue: true)]
        : list;
  }
}
