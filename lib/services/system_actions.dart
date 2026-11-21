import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Opens Android system screens through a tiny platform channel in MainActivity
/// (no extra library needed). Android only; callers hide the buttons elsewhere.
class SystemActions {
  static const _ch = MethodChannel('kovra/system');

  static bool get isAndroid => !kIsWeb && Platform.isAndroid;

  /// Android Settings > Network > VPN (Always-on VPN lives here).
  static Future<bool> openVpnSettings() => _call('openVpnSettings');

  /// Opens a web or Play Store link in the right app.
  static Future<bool> openUrl(String url) => _call('openUrl', {'url': url});

  static Future<bool> _call(String method, [Map<String, Object?>? args]) async {
    if (!isAndroid) return false;
    try {
      return await _ch.invokeMethod<bool>(method, args) ?? false;
    } catch (e) {
      debugPrint('SystemActions.$method failed: $e');
      return false;
    }
  }
}
