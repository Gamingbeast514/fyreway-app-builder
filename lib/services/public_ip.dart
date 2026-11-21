import 'package:flutter/foundation.dart';

import 'network_tools.dart';
import 'vpn_controller.dart';

/// The user's real public IP (seen while the VPN is off), cached for Home.
class PublicIp extends ChangeNotifier {
  IpInfo? info;
  bool loading = false;
  DateTime? _at;

  /// Looks up the IP while disconnected. A result that arrives after the VPN
  /// came up is thrown away (it would be the server's IP, not the user's).
  Future<void> refresh({bool force = false}) async {
    if (loading || vpn.status != VpnStatus.disconnected) return;
    final fresh = _at != null && DateTime.now().difference(_at!) < const Duration(minutes: 5);
    if (!force && fresh && info != null) return;
    loading = true;
    notifyListeners();
    try {
      final r = await NetworkTools.ipInfo();
      if (vpn.status == VpnStatus.disconnected) {
        info = r;
        _at = DateTime.now();
      }
    } catch (_) {
      // Unknown: the UI says "Your real IP is visible" instead.
    } finally {
      loading = false;
      notifyListeners();
    }
  }
}

final publicIp = PublicIp();
