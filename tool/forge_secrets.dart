// Run with: dart run tool/forge_secrets.dart
//
// Outputs scrambled byte arrays for every secret listed below. Paste the
// arrays into the matching slots in lib/env/*.dart and
// lib/runtime/wire_client.dart.
//
// NEVER use a PowerShell foreach loop to do this on Windows: PowerShell
// silently overflows 32-bit integers and you get the wrong bytes.
//
// SECURITY: This file lives outside lib/ and is never compiled into the
// shipping APK. Even so, prefer to keep the plaintext placeholders below
// — fill them in only while regenerating arrays, then revert.

// ignore_for_file: avoid_print, avoid_relative_lib_imports

import '../lib/forge/cipher.dart';

void main() {
  final secrets = <String, String>{
    // Relay endpoint, split into host + path
    'relay.host': 'https://example-host.tld',
    'relay.path': '/v1/decide',

    // Attribution credentials
    'tracker.devKey': 'PASTE_APPSFLYER_DEV_KEY',
    'courier.projectId': '000000000000',

    // GCD endpoint (host + path)
    'gcd.host': 'https://gcdsdk.appsflyer.com',
    'gcd.path': '/install_data/v4.0',

    // Browser fragments injected into the User-Agent header.
    'wire.chrome': '129.0.0.0',
    'wire.webkit': '537.36',
  };

  for (final entry in secrets.entries) {
    final bytes = wrap(entry.value);
    final list = bytes
        .map((b) => '0x${b.toRadixString(16).padLeft(2, '0')}')
        .join(', ');
    print('-- ${entry.key} (${entry.value}) --');
    print('const v = <int>[$list];');
    print('');
  }
}
