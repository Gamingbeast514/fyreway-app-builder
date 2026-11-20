import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/server.dart';

enum VpnStatus { disconnected, connecting, connected }

/// What the user sees after disconnecting.
class SessionSummary {
  final VpnServer server;
  final Duration duration;
  const SessionSummary(this.server, this.duration);
}

/// Demo VPN controller: shows servers and simulates a smooth connection
/// without requiring a live VPN backend.
class VpnController extends ChangeNotifier {
  VpnStatus status = VpnStatus.disconnected;
  VpnServer server = defaultFreeServer;
  VpnServer? activeServer;
  DateTime? connectedAt;
  String stage = '';
  String? lastError;
  int successfulConnections = 0;

  bool _cancelled = false;

  Future<void> connect() async {
    if (status != VpnStatus.disconnected) return;
    _cancelled = false;
    lastError = null;
    status = VpnStatus.connecting;
    stage = 'Finding the best route…';
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 550));
    if (_cancelled) return;

    stage = 'Securing connection to ${server.country}…';
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 650));
    if (_cancelled) return;

    activeServer = server;
    status = VpnStatus.connected;
    connectedAt = DateTime.now();
    stage = '';
    successfulConnections++;
    notifyListeners();
  }

  SessionSummary? disconnect() {
    if (status == VpnStatus.disconnected) return null;
    _cancelled = true;
    final start = connectedAt;
    final summary = start == null ? null : SessionSummary(activeServer ?? server, DateTime.now().difference(start));
    status = VpnStatus.disconnected;
    connectedAt = null;
    activeServer = null;
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
      await Future.delayed(const Duration(milliseconds: 400));
      await connect();
    }
  }
}

/// One shared controller for the app.
final vpn = VpnController();
