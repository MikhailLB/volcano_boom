import '../forge/cipher.dart';

// Scrambled config endpoint URL. Host and path are stored separately
// so the assembled URL never appears as a single literal in the binary.
//
// To regenerate after changing the cipher ember:
//   1. Fill the plain URL in tool/forge_secrets.dart
//   2. Run: dart run tool/forge_secrets.dart
//   3. Copy the printed arrays into the lists below.

String resolveRelayEndpoint() {
  // Scrambled host bytes (e.g. https://api.example.com)
  const host = <int>[];
  // Scrambled path bytes (e.g. /v1/config)
  const path = <int>[];
  if (host.isEmpty) return '';
  return unwrap(host) + unwrap(path);
}
