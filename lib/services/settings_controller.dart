import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A location the user picked before. Saved by country (VPN Gate servers come
/// and go, so we keep the country and pick its best live server when used).
@immutable
class SavedPlace {
  final String code; // "DE"
  final String country; // "Germany"
  final bool premium; // a Pro location
  const SavedPlace(this.code, this.country, {this.premium = false});

  /// Pro places can share a country code, so they are told apart by name too.
  String get key => premium ? 'pro:$code:$country' : code;

  String encode() => '${premium ? 'pro:$code' : code}|$country';

  static SavedPlace? decode(String s) {
    final i = s.indexOf('|');
    if (i <= 0) return null;
    var key = s.substring(0, i);
    final pro = key.startsWith('pro:');
    if (pro) key = key.substring(4);
    return SavedPlace(key, s.substring(i + 1), premium: pro);
  }

  @override
  bool operator ==(Object other) => other is SavedPlace && other.key == key;

  @override
  int get hashCode => key.hashCode;
}

/// App settings, saved on the device with shared_preferences.
class SettingsController extends ChangeNotifier {
  static const _kAutoConnect = 'auto_connect';
  static const _kOnboarded = 'onboarded';
  static const _kVpnExplained = 'vpn_explained';
  static const _kRecent = 'recent_places';
  static const _kFavorites = 'favorite_places';
  static const maxRecent = 3;

  SharedPreferences? _prefs;
  bool loaded = false;

  /// Connect as soon as Home opens.
  bool autoConnect = false;

  /// Welcome has been seen once.
  bool onboarded = false;

  /// The "Allow a VPN connection" explainer has been answered once.
  bool vpnExplained = false;

  /// Newest first.
  List<SavedPlace> recent = [];
  List<SavedPlace> favorites = [];

  Future<void> load() async {
    if (loaded) return;
    try {
      final p = _prefs = await SharedPreferences.getInstance();
      autoConnect = p.getBool(_kAutoConnect) ?? false;
      onboarded = p.getBool(_kOnboarded) ?? false;
      vpnExplained = p.getBool(_kVpnExplained) ?? false;
      recent = _places(p.getStringList(_kRecent));
      favorites = _places(p.getStringList(_kFavorites));
    } catch (e) {
      debugPrint('settings load failed: $e'); // keep defaults, still usable
    }
    loaded = true;
    notifyListeners();
  }

  static List<SavedPlace> _places(List<String>? raw) =>
      (raw ?? const []).map(SavedPlace.decode).whereType<SavedPlace>().toList();

  void setAutoConnect(bool v) {
    autoConnect = v;
    _prefs?.setBool(_kAutoConnect, v);
    notifyListeners();
  }

  void setOnboarded() {
    onboarded = true;
    _prefs?.setBool(_kOnboarded, true);
    notifyListeners();
  }

  void setVpnExplained() {
    vpnExplained = true;
    _prefs?.setBool(_kVpnExplained, true);
    notifyListeners();
  }

  void addRecent(SavedPlace p) {
    recent = [p, ...recent.where((r) => r != p)].take(maxRecent).toList();
    _prefs?.setStringList(_kRecent, recent.map((r) => r.encode()).toList());
    notifyListeners();
  }

  bool isFavorite(SavedPlace p) => favorites.contains(p);

  void toggleFavorite(SavedPlace p) {
    favorites = isFavorite(p) ? favorites.where((f) => f != p).toList() : [...favorites, p];
    _prefs?.setStringList(_kFavorites, favorites.map((f) => f.encode()).toList());
    notifyListeners();
  }
}

final settings = SettingsController();
