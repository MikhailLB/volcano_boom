import '../forge/cipher.dart';

// Scrambled config endpoint URL. Host and path are stored separately
// so the assembled URL never appears as a single literal in the binary.
//
// To regenerate after changing the cipher ember:
//   1. Update the plain values in tool/forge_secrets.dart
//   2. Run: dart run tool/forge_secrets.dart
//   3. Replace the byte arrays below with the printed output.

String resolveRelayEndpoint() {
  // https://vollcanoboom.com
  const host = <int>[
    0xc9, 0x61, 0x47, 0x7b, 0x1c, 0x60, 0x9b, 0xb5,
    0x15, 0xaf, 0x66, 0x54, 0x47, 0xdc, 0x48, 0xdf,
    0xd0, 0x59, 0x23, 0xb5, 0x61, 0xdd, 0xfe, 0xe0,
  ];
  // /config.php
  const path = <int>[
    0x8e, 0x78, 0x60, 0x69, 0x11, 0x0d, 0xe3, 0xb6,
    0x13, 0xaa, 0x4a,
  ];
  if (host.isEmpty) return '';
  return unwrap(host) + unwrap(path);
}
