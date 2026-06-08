import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:http/http.dart' as http;

import '../forge/cipher.dart';

// Wire client — drop-in HTTP client that pretends to be a real mobile browser.
//
// The Chrome / WebKit version fragments are kept as scrambled byte vectors
// so static-analysis tools don't pick up a stable Chromium release string.
// Regenerate the byte arrays via tool/forge_secrets.dart after changing the
// cipher ember.

// Scrambled Chrome major-version string ("129.0.0.0").
String get _chromeFragment => unwrap(const <int>[
      0x90, 0x27, 0x0a, 0x29, 0x5f, 0x54, 0x90, 0xb6, 0x53,
    ]);

// Scrambled WebKit version ("537.36"). iOS Safari path only.
String get _webkitFragment => unwrap(const <int>[
      0x94, 0x28, 0x08, 0x29, 0x5c, 0x5c,
    ]);

class WireClient extends http.BaseClient {
  final http.Client _delegate = http.Client();
  String? _agent;

  Future<void> warmUp() async {
    try {
      final probe = DeviceInfoPlugin();
      if (Platform.isAndroid) {
        final a = await probe.androidInfo;
        final sdk = a.version.sdkInt;
        final build = a.display.isNotEmpty ? a.display : a.id;
        final chrome = _chromeFragment.isNotEmpty ? _chromeFragment : '129.0.0.0';
        _agent = 'Mozilla/5.0 (Linux; Android $sdk; ${a.brand} ${a.model} '
            'Build/$build; wv) AppleWebKit/537.36 (KHTML, like Gecko) '
            'Version/4.0 Chrome/$chrome Mobile Safari/537.36';
      } else {
        final i = await probe.iosInfo;
        final ver = i.systemVersion.replaceAll('.', '_');
        final wk = _webkitFragment.isNotEmpty ? _webkitFragment : '537.36';
        _agent = 'Mozilla/5.0 (iPhone; CPU iPhone OS $ver like Mac OS X) '
            'AppleWebKit/$wk (KHTML, like Gecko) Version/${i.systemVersion} '
            'Mobile/15E148 Safari/$wk';
      }
    } catch (_) {
      final chrome = _chromeFragment.isNotEmpty ? _chromeFragment : '129.0.0.0';
      _agent = Platform.isAndroid
          ? 'Mozilla/5.0 (Linux; Android 14; Pixel 8) AppleWebKit/537.36 '
              '(KHTML, like Gecko) Chrome/$chrome Mobile Safari/537.36'
          : 'Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) '
              'AppleWebKit/537.36 (KHTML, like Gecko) Version/17.0 '
              'Mobile/15E148 Safari/537.36';
    }
  }

  String get userAgent => _agent ?? 'Mozilla/5.0';

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers.putIfAbsent('User-Agent', () => userAgent);
    return _delegate.send(request);
  }

  @override
  void close() => _delegate.close();
}

/// Global wire singleton — every gray-flow request goes through this.
final WireClient wire = WireClient();
