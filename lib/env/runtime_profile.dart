import 'attribution_cipher.dart';
import 'legal_urls.dart';
import 'relay_cipher.dart';

/// Single facade exposing every runtime-level constant the gray flow needs.
/// All sensitive values resolve lazily through the cipher.
class RuntimeProfile {
  // Bundle / store identifiers.
  static const String bundleId = 'com.rdgames.volcanoboom';
  static const String storeId = 'com.rdgames.volcanoboom';

  // Human-facing name (used in notification titles, channel description).
  static const String displayName = 'Volcano Boom';

  // iOS only — App Store numeric id. Empty for Android-first builds.
  static const String storeNumericId = '';

  /// Backend config endpoint (decoded).
  static String get relayEndpoint => resolveRelayEndpoint();

  /// AppsFlyer Dev Key (decoded).
  static String get trackerKey => resolveTrackerKey();

  /// Firebase project number / sender id (decoded).
  static String get courierProjectId => resolveCourierProject();

  /// Public legal pages — used inside the native game settings.
  static String get privacyUrl => privacyHubUrl;
  static String get termsUrl => termsHubUrl;
  static String get supportUrl => supportHubUrl;

  /// Three-day cool-down for the notification opt-in promo.
  /// If the user taps Skip we re-show this screen no sooner than 3 days later.
  static const int notificationCoolDownSeconds = 3 * 24 * 60 * 60;

  /// Delay before retrying GCD when AppsFlyer reports Organic on first callback.
  static const int organicRecheckSeconds = 5;

  /// Maximum time we wait for AppsFlyer attribution on first launch.
  static const Duration attributionWaitFirst = Duration(seconds: 30);

  /// Same wait on subsequent launches (shorter — the backend is forgiving).
  static const Duration attributionWaitReturning = Duration(seconds: 10);

  /// Deep link wait window.
  static const Duration deepLinkWait = Duration(seconds: 5);

  /// Relay request budget.
  static const Duration relayTimeout = Duration(seconds: 15);
}
