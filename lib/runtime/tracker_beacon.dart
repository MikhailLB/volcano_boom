import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:appsflyer_sdk/appsflyer_sdk.dart';
import 'package:flutter/foundation.dart';

import '../env/attribution_cipher.dart';
import '../env/runtime_profile.dart';
import 'wire_client.dart';

/// AppsFlyer wrapper. Three responsibilities:
///   1. Spin up the SDK on first launch.
///   2. Collect install attribution + deep link payloads.
///   3. Assemble the body posted to the backend relay.
///
/// Organic false-positive: AppsFlyer occasionally reports af_status="Organic"
/// for paid installs on the very first callback. We compensate by re-fetching
/// via the GCD endpoint after a short delay.
class TrackerBeacon {
  AppsflyerSdk? _sdk;

  Map<String, dynamic>? _conversion;
  Map<String, dynamic>? _deepLink;
  Map<String, dynamic>? _appOpen;

  final Completer<Map<String, dynamic>> _conversionReady = Completer();
  final Completer<void> _deepLinkReady = Completer();

  bool _booted = false;

  Future<void> boot() async {
    if (_booted) return;
    _booted = true;

    final cfg = AppsFlyerOptions(
      afDevKey: RuntimeProfile.trackerKey,
      appId: RuntimeProfile.storeNumericId,
      showDebug: kDebugMode,
      timeToWaitForATTUserAuthorization: 10,
    );

    _sdk = AppsflyerSdk(cfg);

    _sdk!.onInstallConversionData((data) async {
      final payload = _flatten(data);
      if (payload['af_status'] == 'Organic') {
        await Future.delayed(
          Duration(seconds: RuntimeProfile.organicRecheckSeconds),
        );
        final retry = await _gcdReprobe();
        _conversion = retry ?? payload;
      } else {
        _conversion = payload;
      }
      if (!_conversionReady.isCompleted) {
        _conversionReady.complete(_conversion ?? {});
      }
    });

    _sdk!.onAppOpenAttribution((data) {
      _appOpen = _flatten(data);
    });

    _sdk!.onDeepLinking((result) {
      try {
        final ev = result.deepLink?.clickEvent;
        if (ev != null) {
          _deepLink = Map<String, dynamic>.from(ev);
        }
      } catch (_) {}
      if (!_deepLinkReady.isCompleted) _deepLinkReady.complete();
    });

    try {
      _sdk!.initSdk(
        registerConversionDataCallback: true,
        registerOnAppOpenAttributionCallback: true,
        registerOnDeepLinkingCallback: true,
      );
    } catch (_) {}
  }

  Map<String, dynamic> _flatten(dynamic data) {
    try {
      if (data is Map && data['payload'] is Map) {
        return Map<String, dynamic>.from(data['payload'] as Map);
      }
      if (data is Map) {
        return Map<String, dynamic>.from(data);
      }
    } catch (_) {}
    return <String, dynamic>{};
  }

  Future<Map<String, dynamic>?> _gcdReprobe() async {
    final uid = await beaconUid();
    if (uid == null || uid.isEmpty) return null;
    final appId =
        Platform.isIOS ? RuntimeProfile.storeNumericId : RuntimeProfile.bundleId;
    final url = resolveGcdEndpoint(appId, uid);
    if (url.isEmpty) return null;
    try {
      final res = await wire.get(
        Uri.parse(url),
        headers: {'authorization': 'Bearer ${RuntimeProfile.trackerKey}'},
      ).timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        return jsonDecode(res.body) as Map<String, dynamic>;
      }
    } catch (_) {}
    return null;
  }

  Future<Map<String, dynamic>> awaitConversion({Duration? budget}) {
    return _conversionReady.future.timeout(
      budget ?? RuntimeProfile.attributionWaitFirst,
      onTimeout: () => <String, dynamic>{},
    );
  }

  Future<void> awaitDeepLink() async {
    await _deepLinkReady.future
        .timeout(RuntimeProfile.deepLinkWait, onTimeout: () {});
  }

  Future<String?> beaconUid() async {
    if (_sdk == null) return null;
    try {
      return await _sdk!.getAppsFlyerUID();
    } catch (_) {
      return null;
    }
  }

  /// Build the JSON body posted to the relay endpoint.
  Future<Map<String, dynamic>> composeRelayBody({
    required String locale,
    String? pushToken,
  }) async {
    final body = <String, dynamic>{};
    body.addAll(_conversion ?? const {});
    _deepLink?.forEach((k, v) => body.putIfAbsent(k, () => v));
    _appOpen?.forEach((k, v) => body.putIfAbsent(k, () => v));

    final uid = await beaconUid();
    body['af_id'] = uid ?? '';
    body['bundle_id'] = RuntimeProfile.bundleId;
    body['os'] = Platform.isAndroid ? 'Android' : 'iOS';
    body['store_id'] = RuntimeProfile.storeId;
    body['locale'] = locale;
    if (pushToken != null && pushToken.isNotEmpty) {
      body['push_token'] = pushToken;
    }
    if (RuntimeProfile.courierProjectId.isNotEmpty) {
      body['firebase_project_id'] = RuntimeProfile.courierProjectId;
    }

    if (kDebugMode) {
      debugPrint('[TrackerBeacon] relay body=${jsonEncode(body)}');
    }
    return body;
  }
}
