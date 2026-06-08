import 'dart:typed_data';

// Magma cipher — symmetric stream deobfuscator for embedded secrets.
//
// Sensitive constants (relay host, attribution key, messaging project id)
// are stored as scrambled byte vectors. At runtime they are reconstituted
// via [unwrap]. Plain UTF-8 strings never appear in the compiled binary.
//
// Algorithm:
//   1. A short ASCII passphrase (the "ember") drives an FNV-1a 32-bit hash.
//   2. That hash bootstraps an xorshift32 PRNG.
//   3. PRNG produces a 24-byte rolling key. We rotate through it.
//   4. unwrap(bytes) XORs each byte against key[i % 24] and additionally
//      subtracts the position-dependent low byte to prevent simple XOR
//      key-recovery from known-plaintext leaks.

// Reseed the ember per project. Re-run tool/forge_secrets.dart after change.
const List<int> _ember = <int>[
  0x6C, 0x61, 0x76, 0x61, 0x66, 0x6F, 0x72, 0x67, 0x65, 0x32, 0x36, // "lavaforge26"
];

Uint8List _bake() {
  if (_ember.isEmpty) return Uint8List(24);
  var h = 0x811C9DC5;
  for (final b in _ember) {
    h = (h ^ b) & 0xFFFFFFFF;
    h = (h * 0x01000193) & 0xFFFFFFFF;
  }
  if (h == 0) h = 0xDEADBEEF;
  var state = h;
  final out = Uint8List(24);
  for (var i = 0; i < out.length; i++) {
    state ^= (state << 13) & 0xFFFFFFFF;
    state &= 0xFFFFFFFF;
    state ^= state >> 17;
    state ^= (state << 5) & 0xFFFFFFFF;
    state &= 0xFFFFFFFF;
    out[i] = state & 0xFF;
  }
  return out;
}

final Uint8List _wave = _bake();

/// Restore a UTF-8 string from a scrambled byte array.
String unwrap(List<int> scrambled) {
  if (scrambled.isEmpty) return '';
  final out = Uint8List(scrambled.length);
  for (var i = 0; i < scrambled.length; i++) {
    final keyByte = _wave[i % _wave.length];
    final pos = i & 0xFF;
    final raw = (scrambled[i] - pos) & 0xFF;
    out[i] = raw ^ keyByte;
  }
  return String.fromCharCodes(out);
}

/// Produce a scrambled byte vector for a plain UTF-8 string.
/// Used only by the offline encoder tool (tool/forge_secrets.dart).
List<int> wrap(String plain) {
  final bytes = plain.codeUnits;
  final out = List<int>.filled(bytes.length, 0);
  for (var i = 0; i < bytes.length; i++) {
    final keyByte = _wave[i % _wave.length];
    final pos = i & 0xFF;
    final x = bytes[i] ^ keyByte;
    out[i] = (x + pos) & 0xFF;
  }
  return out;
}
