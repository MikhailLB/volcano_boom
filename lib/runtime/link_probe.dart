import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';

/// Connectivity helper. We pair the OS-level connectivity report with a
/// short DNS resolve so we don't lie about "online" while we're stuck
/// behind a captive portal.
class LinkProbe {
  final Connectivity _link = Connectivity();

  Stream<List<ConnectivityResult>> get pulses => _link.onConnectivityChanged;

  Future<bool> hasReachableInternet() async {
    final layers = await _link.checkConnectivity();
    final anyLink = layers.any((r) => r != ConnectivityResult.none);
    if (!anyLink) return false;

    try {
      final result = await InternetAddress.lookup('cloudflare.com')
          .timeout(const Duration(seconds: 3));
      return result.isNotEmpty && result.first.rawAddress.isNotEmpty;
    } on SocketException {
      return false;
    } catch (_) {
      return false;
    }
  }
}
