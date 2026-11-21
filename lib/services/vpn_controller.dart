import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:openvpn_flutter/openvpn_flutter.dart' as ovpn;
import 'package:permission_handler/permission_handler.dart';

import '../config.dart';
import '../models/server.dart';
import 'settings_controller.dart';
import 'vpngate_service.dart';

enum VpnStatus { disconnected, connecting, connected }

/// What the user sees after disconnecting.
class SessionSummary {
  final VpnServer server;
  final Duration duration;
  final int? bytesIn, bytesOut;
  const SessionSummary(this.server, this.duration, {this.bytesIn, this.bytesOut});
}

/// Holds the VPN state for the whole app and drives the REAL tunnel (OpenVPN).
class VpnController extends ChangeNotifier {
  VpnStatus status = VpnStatus.disconnected;
  VpnServer server = defaultFreeServer;

  /// The actual server we are tunnelled through (for AUTO picks).
  VpnServer? activeServer;
  DateTime? connectedAt;
  String stage = '';
  String? lastError;
  int successfulConnections = 0;

  /// Android refused the VPN (the user said no, or another app owns Always-on).
  bool permissionDenied = false;

  /// Traffic through the tunnel this session, as reported by the engine.
  int? bytesIn, bytesOut;

  ovpn.OpenVPN? _engine;
  Completer<bool>? _attempt;
  bool _cancelled = false;

  void _ensureEngine() {
    if (_engine != null) return;
    _engine = ovpn.OpenVPN(
      onVpnStageChanged: (s, raw) => _onStage(s.name),
      onVpnStatusChanged: _onTraffic,
    );
    _engine!.initialize(
      // iOS needs a Network Extension target + paid Apple account (later).
      groupIdentifier: 'group.com.kovravpn.app',
      providerBundleIdentifier: 'com.kovravpn.app.VPNExtension',
      localizedDescription: AppConfig.appName,
      lastStage: (s) => _onStage(s.name),
    );
  }

  void _onStage(String name) {
    switch (name) {
      case 'connected':
        _settle(true);
        if (status != VpnStatus.connected) {
          status = VpnStatus.connected;
          connectedAt ??= DateTime.now();
          stage = '';
          successfulConnections++;
          notifyListeners();
        }
      case 'denied':
      case 'error':
        _settle(false);
      case 'disconnected':
        _settle(false);
        if (status == VpnStatus.connected) {
          status = VpnStatus.disconnected;
          connectedAt = null;
          activeServer = null;
          notifyListeners();
        }
      default:
        if (status == VpnStatus.connecting) {
          stage = _friendly(name);
          notifyListeners();
        }
    }
  }

  void _onTraffic(ovpn.VpnStatus? s) {
    if (s == null || status != VpnStatus.connected) return;
    final i = int.tryParse(s.byteIn?.trim() ?? '');
    final o = int.tryParse(s.byteOut?.trim() ?? '');
    if (i == bytesIn && o == bytesOut) return;
    bytesIn = i;
    bytesOut = o;
    notifyListeners();
  }

  /// Hides the last error (the user picked another location or dismissed it).
  void clearError() {
    if (lastError == null && !permissionDenied) return;
    lastError = null;
    permissionDenied = false;
    notifyListeners();
  }

  void _settle(bool ok) {
    final a = _attempt;
    if (a != null && !a.isCompleted) a.complete(ok);
    _attempt = null;
  }

  static String _friendly(String raw) => switch (raw) {
        'prepare' || 'vpn_generate_config' || 'get_config' => 'Preparing…',
        'wait_connection' || 'tcp_connect' || 'udp_connect' || 'resolve' => 'Reaching the server…',
        'authenticating' || 'authentication' => 'Securing your connection…',
        'assign_ip' => 'Almost there…',
        _ => 'Connecting…',
      };

  Future<void> connect() async {
    if (status != VpnStatus.disconnected) return;
    _ensureEngine();
    _cancelled = false;
    lastError = null;
    permissionDenied = false;
    bytesIn = bytesOut = null;
    status = VpnStatus.connecting;
    stage = 'Finding the best route…';
    notifyListeners();

    await vpnGate.load();
    if (_cancelled) return;

    final list = _candidatesFor(server);
    if (list.isEmpty) {
      _fail(server.premium
          ? 'Pro locations go live with our own servers soon. Try a free location.'
          : (vpnGate.error ?? 'No free servers online right now. Try again.'));
      return;
    }

    if (defaultTargetPlatform == TargetPlatform.android) {
      await Permission.notification.request(); // shows the VPN notification on Android 13+
    }

    for (final s in list) {
      if (_cancelled) return;
      stage = 'Connecting to ${s.country}…';
      notifyListeners();
      final ok = await _tryOne(s);
      if (_cancelled) return;
      if (ok) {
        activeServer = s;
        settings.addRecent(SavedPlace(s.code, s.country));
        notifyListeners();
        return;
      }
      _engine?.disconnect();
    }
    _fail('That server did not answer. Tap again to try another one.');
  }

  List<VpnServer> _candidatesFor(VpnServer target) {
    if (target.isLive) {
      final more = vpnGate.candidates(target.code).where((s) => !identical(s, target));
      return [target, ...more].take(3).toList();
    }
    if (target.code == 'AUTO') return vpnGate.all.take(3).toList();
    // A Pro placeholder: no own servers yet.
    return const [];
  }

  Future<bool> _tryOne(VpnServer s) async {
    final done = Completer<bool>();
    _attempt = done;
    try {
      final started = await _engine!.connect(
        s.ovpnConfig!,
        '${AppConfig.brand} · ${s.country}',
        username: 'vpn', // VPN Gate's public login
        password: 'vpn',
        certIsRequired: false,
      );
      if (!started) {
        lastError = 'VPN permission is needed to protect you.';
        permissionDenied = true;
        return false;
      }
    } catch (e) {
      debugPrint('openvpn connect error: $e');
      return false;
    }
    return done.future.timeout(const Duration(seconds: 25), onTimeout: () => false);
  }

  void _fail(String msg) {
    lastError ??= msg;
    status = VpnStatus.disconnected;
    stage = '';
    notifyListeners();
  }

  /// Stops the tunnel and returns a summary of the session (if one was running).
  SessionSummary? disconnect() {
    if (status == VpnStatus.disconnected) return null;
    _cancelled = true;
    final start = connectedAt;
    final summary = start == null
        ? null
        : SessionSummary(activeServer ?? server, DateTime.now().difference(start),
            bytesIn: bytesIn, bytesOut: bytesOut);
    _engine?.disconnect();
    _settle(false);
    status = VpnStatus.disconnected;
    connectedAt = null;
    activeServer = null;
    bytesIn = bytesOut = null;
    stage = '';
    notifyListeners();
    return summary;
  }

  Future<void> selectServer(VpnServer s) async {
    final wasOn = status != VpnStatus.disconnected;
    server = s;
    notifyListeners();
    if (wasOn) {
      disconnect();
      await Future.delayed(const Duration(milliseconds: 600));
      await connect(); // switch location on the fly
    }
  }
}

/// One shared controller for the app.
final vpn = VpnController();
