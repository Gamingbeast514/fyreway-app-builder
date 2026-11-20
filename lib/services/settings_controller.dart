import 'package:flutter/foundation.dart';

/// App settings. Day 1: kept in memory (reset when the app restarts).
class SettingsController extends ChangeNotifier {
  bool autoConnect = false;

  void setAutoConnect(bool v) {
    autoConnect = v;
    notifyListeners();
  }
}

final settings = SettingsController();
