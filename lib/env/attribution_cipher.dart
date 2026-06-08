import '../forge/cipher.dart';

// Scrambled attribution credentials.
//
// Fill in tool/forge_secrets.dart, run it, then paste the printed
// byte arrays into the lists below.

/// Decoded AppsFlyer Dev Key.
String resolveTrackerKey() {
  const v = <int>[];
  if (v.isEmpty) return '';
  return unwrap(v);
}

/// Decoded Firebase project number (sender id).
String resolveCourierProject() {
  const v = <int>[];
  if (v.isEmpty) return '';
  return unwrap(v);
}

/// Assemble the GCD (Get Conversion Data) URL.
/// Format: https://gcdsdk.appsflyer.com/install_data/v4.0/{appId}?device_id={deviceId}
String resolveGcdEndpoint(String appId, String deviceId) {
  const host = <int>[];
  const path = <int>[];
  if (host.isEmpty) return '';
  return '${unwrap(host)}${unwrap(path)}?app_id=$appId&device_id=$deviceId';
}
