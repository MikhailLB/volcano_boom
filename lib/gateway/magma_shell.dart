import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';

import '../runtime/link_probe.dart';
import '../runtime/signal_courier.dart';
import '../runtime/vault_keeper.dart';
import '../runtime/wire_client.dart';
import 'offline_caldera.dart';

/// Pre-warm hook used by deferred-loading clients.
Future<void> primeShell() async {}

/// Magma Shell — full-screen WebView the gray flow renders for partner users.
///
/// Supports both portrait and landscape, immersive system UI, push deep-links,
/// file uploads, third-party cookies, and recovers from typical mobile
/// WebView pitfalls (redirect loops, keyboard covering inputs, safe-area gaps).
class MagmaShell extends StatefulWidget {
  final String url;
  final VaultKeeper vault;
  final SignalCourier courier;
  final LinkProbe link;

  const MagmaShell({
    super.key,
    required this.url,
    required this.vault,
    required this.courier,
    required this.link,
  });

  @override
  State<MagmaShell> createState() => _MagmaShellState();
}

class _MagmaShellState extends State<MagmaShell>
    with WidgetsBindingObserver {
  late final WebViewController _view;
  bool _busy = true;
  bool _routedAway = false;
  String? _lastMainFrame;
  String? _lastGoodUrl;
  int _redirectRetries = 0;
  StreamSubscription<List<ConnectivityResult>>? _linkSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Magma Shell freely rotates.
    SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    _applyImmersive();

    _view = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setUserAgent(wire.userAgent)
      ..setBackgroundColor(Colors.black)
      ..enableZoom(false)
      ..setNavigationDelegate(NavigationDelegate(
        onPageStarted: (_) {
          if (mounted) setState(() => _busy = true);
        },
        onPageFinished: (url) {
          if (mounted) setState(() => _busy = false);
          _redirectRetries = 0;
          if (url.isNotEmpty &&
              !url.startsWith('about:') &&
              !url.startsWith('chrome-error:') &&
              !url.startsWith('data:')) {
            _lastGoodUrl = url;
          }
          _injectSafeAreaReset();
          _injectKeyboardScroll();
        },
        onWebResourceError: (err) {
          if (err.isForMainFrame != true) return;
          final desc = err.description.toLowerCase();
          final redirectLoop = desc.contains('too_many_redirects') ||
              desc.contains('too many redirects') ||
              err.errorCode == -1007 ||
              err.errorCode == -9;
          if (redirectLoop &&
              _lastMainFrame != null &&
              _redirectRetries < 3) {
            _redirectRetries++;
            _view.loadRequest(Uri.parse(_lastMainFrame!));
            return;
          }
          _maybeOffline();
        },
        onNavigationRequest: (req) {
          final u = Uri.tryParse(req.url);
          if (u == null) return NavigationDecision.prevent;
          const inline = {'http', 'https', 'about', 'data', 'blob'};
          if (inline.contains(u.scheme)) {
            if (req.isMainFrame) _lastMainFrame = req.url;
            return NavigationDecision.navigate;
          }
          _kick(u);
          return NavigationDecision.prevent;
        },
      ));

    _configurePlatform();
    _view.loadRequest(Uri.parse(widget.url));

    widget.courier.onWarmUrl = (url) {
      if (mounted) _view.loadRequest(Uri.parse(url));
    };

    _linkSub = widget.link.pulses.listen((states) {
      if (states.every((s) => s == ConnectivityResult.none)) {
        _maybeOffline();
      }
    });
  }

  void _applyImmersive() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _applyImmersive();
  }

  void _configurePlatform() {
    if (Platform.isAndroid &&
        _view.platform is AndroidWebViewController) {
      final ctrl = _view.platform as AndroidWebViewController;
      ctrl.setMediaPlaybackRequiresUserGesture(false);
      ctrl.setOnShowFileSelector(_filePick);
      final mgr = AndroidWebViewCookieManager(
        AndroidWebViewCookieManagerCreationParams
            .fromPlatformWebViewCookieManagerCreationParams(
          const PlatformWebViewCookieManagerCreationParams(),
        ),
      );
      mgr.setAcceptThirdPartyCookies(ctrl, true);
    }
  }

  Future<List<String>> _filePick(FileSelectorParams params) async {
    try {
      final res = await FilePicker.pickFiles(
        allowMultiple: params.mode == FileSelectorMode.openMultiple,
        type: FileType.any,
      );
      if (res != null && res.files.isNotEmpty) {
        return res.files
            .where((f) => f.path != null)
            .map((f) => Uri.file(f.path!).toString())
            .toList();
      }
    } catch (_) {}
    return [];
  }

  Future<void> _kick(Uri uri) async {
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  Future<void> _maybeOffline() async {
    if (_routedAway) return;
    final reachable = await widget.link.hasReachableInternet();
    if (reachable || !mounted) return;
    _routedAway = true;

    // Prefer the last fully-loaded URL; only fall back to the original
    // partner URL. Never use currentUrl() blindly — when an error page is
    // displayed it returns `chrome-error://` which would hang the next load.
    final resume = _lastGoodUrl ?? widget.url;
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => OfflineCalderaScreen(
          link: widget.link,
          retryBuilder: (_) => MagmaShell(
            url: resume,
            vault: widget.vault,
            courier: widget.courier,
            link: widget.link,
          ),
        ),
      ),
    );
  }

  void _injectKeyboardScroll() {
    _view.runJavaScript(r'''
(function () {
  if (window.__vbKbBound) return;
  window.__vbKbBound = true;

  function isTextEntry(el) {
    if (!el) return false;
    var tag = el.tagName;
    return tag === 'INPUT' || tag === 'TEXTAREA' || el.isContentEditable;
  }

  function scrollIntoVisible() {
    var el = document.activeElement;
    if (!isTextEntry(el)) return;
    var vp = window.visualViewport;
    if (vp) {
      var r = el.getBoundingClientRect();
      var lower = vp.offsetTop + vp.height;
      if (r.bottom > lower - 24 || r.top < vp.offsetTop + 4) {
        el.scrollIntoView({ behavior: 'auto', block: 'nearest' });
      }
    } else {
      el.scrollIntoView({ behavior: 'auto', block: 'nearest' });
    }
  }

  document.addEventListener('focusin', function (e) {
    if (isTextEntry(e.target)) setTimeout(scrollIntoVisible, 320);
  });

  if (window.visualViewport) {
    var prev = window.visualViewport.height;
    window.visualViewport.addEventListener('resize', function () {
      var h = window.visualViewport.height;
      if (h < prev) setTimeout(scrollIntoVisible, 140);
      prev = h;
    });
  }
})();
''');
  }

  void _injectSafeAreaReset() {
    _view.runJavaScript(r'''
(function () {
  if (window.__vbSafeAreaKill) return;
  window.__vbSafeAreaKill = true;

  var STYLE_ID = '__vb_sa_kill';
  var CSS =
    ':root{' +
      '--safe-area-inset-top:0px!important;' +
      '--safe-area-inset-right:0px!important;' +
      '--safe-area-inset-bottom:0px!important;' +
      '--safe-area-inset-left:0px!important;' +
      '--sat:0px!important;--sar:0px!important;' +
      '--sab:0px!important;--sal:0px!important;' +
    '}' +
    'html,body,#__nuxt,#__layout,#app,#root{' +
      'padding-top:0!important;padding-left:0!important;' +
      'padding-right:0!important;margin-top:0!important;' +
    '}';

  function kbOpen() {
    if (!window.visualViewport) return false;
    return window.visualViewport.height < window.innerHeight * 0.75;
  }

  function apply() {
    if (kbOpen()) return; // do not relayout while keyboard is animating
    var head = document.head || document.documentElement;
    if (!head) return;
    var meta = document.querySelector('meta[name="viewport"]');
    if (meta) {
      var content = (meta.getAttribute('content') || '')
        .replace(/,?\s*viewport-fit\s*=\s*\w+/ig, '')
        .trim();
      if (!/viewport-fit/.test(content)) {
        meta.setAttribute(
          'content',
          content + (content ? ', ' : '') + 'viewport-fit=contain'
        );
      }
    }
    var node = document.getElementById(STYLE_ID);
    if (!node) {
      node = document.createElement('style');
      node.id = STYLE_ID;
      head.appendChild(node);
    }
    if (node.textContent !== CSS) node.textContent = CSS;
  }

  apply();
  ['pushState', 'replaceState'].forEach(function (fn) {
    var orig = history[fn];
    history[fn] = function () {
      var r = orig.apply(this, arguments);
      setTimeout(apply, 90);
      setTimeout(apply, 420);
      return r;
    };
  });
  window.addEventListener('popstate', function () {
    setTimeout(apply, 90);
  });
  setInterval(apply, 2500);
})();
''');
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _linkSub?.cancel();
    widget.courier.onWarmUrl = null;
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );
    super.dispose();
  }

  Future<bool> _onBack() async {
    if (await _view.canGoBack()) {
      await _view.goBack();
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final landscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (!didPop) await _onBack();
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        resizeToAvoidBottomInset: false,
        body: Stack(
          fit: StackFit.expand,
          children: [
            Padding(
              padding: landscape
                  ? EdgeInsets.only(
                      left: MediaQuery.of(context).viewPadding.left,
                      right: MediaQuery.of(context).viewPadding.right,
                    )
                  : EdgeInsets.only(
                      top: MediaQuery.of(context).viewPadding.top,
                    ),
              child: WebViewWidget(controller: _view),
            ),
            if (_busy)
              const ColoredBox(
                color: Color(0x88000000),
                child: Center(
                  child: SizedBox(
                    width: 36,
                    height: 36,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Color(0xFFFF7043)),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
