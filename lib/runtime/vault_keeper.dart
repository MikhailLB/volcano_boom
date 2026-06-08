import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../relay/shell_mode.dart';

/// Persistent storage for gray-flow state. Combines:
///   * SharedPreferences for non-sensitive flags / timestamps.
///   * Secure storage for URLs returned by the backend.
class VaultKeeper {
  // Prefixed with "vb_" so they don't clash with the white game's own keys.
  static const _kShellMode = 'vb_shell_mode';
  static const _kPartnerUrl = 'vb_partner_url';
  static const _kPartnerExpiry = 'vb_partner_expiry';
  static const _kPushUrl = 'vb_push_url';
  static const _kAlertOptIn = 'vb_alert_opt_in';
  static const _kAlertCoolDown = 'vb_alert_cool_down';
  static const _kAlertOsBlocked = 'vb_alert_os_blocked';

  late SharedPreferences _shared;
  final FlutterSecureStorage _secure = const FlutterSecureStorage();

  Future<void> open() async {
    _shared = await SharedPreferences.getInstance();
  }

  // ----- shell mode -----

  ShellMode currentMode() => ShellMode.parse(_shared.getString(_kShellMode));

  Future<void> persistMode(ShellMode mode) =>
      _shared.setString(_kShellMode, mode.persist());

  // ----- partner URL (secure) -----

  Future<String?> readPartnerUrl() => _secure.read(key: _kPartnerUrl);

  Future<void> writePartnerUrl(String url) =>
      _secure.write(key: _kPartnerUrl, value: url);

  int? partnerExpiry() => _shared.getInt(_kPartnerExpiry);

  Future<void> writePartnerExpiry(int ts) =>
      _shared.setInt(_kPartnerExpiry, ts);

  bool partnerUrlExpired() {
    final expiry = partnerExpiry();
    if (expiry == null) return true;
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    return now >= expiry;
  }

  // ----- alert (notification) opt-in flow -----

  bool alertOptedIn() => _shared.getBool(_kAlertOptIn) ?? false;

  Future<void> markAlertOptIn(bool granted) =>
      _shared.setBool(_kAlertOptIn, granted);

  bool osBlockedAlerts() => _shared.getBool(_kAlertOsBlocked) ?? false;

  Future<void> markOsBlockedAlerts() =>
      _shared.setBool(_kAlertOsBlocked, true);

  int? alertCoolDownUntil() => _shared.getInt(_kAlertCoolDown);

  Future<void> writeAlertCoolDown(int ts) =>
      _shared.setInt(_kAlertCoolDown, ts);

  /// Whether the eruption-alert promo should be displayed on this launch.
  bool shouldShowAlertPrompt() {
    if (alertOptedIn()) return false;
    if (osBlockedAlerts()) return false;
    final cd = alertCoolDownUntil();
    if (cd == null) return true;
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    return now >= cd;
  }

  // ----- one-shot push URL -----

  Future<String?> readPushUrl() => _secure.read(key: _kPushUrl);

  Future<void> writePushUrl(String? url) async {
    if (url == null || url.isEmpty) {
      await _secure.delete(key: _kPushUrl);
    } else {
      await _secure.write(key: _kPushUrl, value: url);
    }
  }

  Future<String?> takePushUrl() async {
    final url = await readPushUrl();
    if (url != null) await _secure.delete(key: _kPushUrl);
    return url;
  }
}
