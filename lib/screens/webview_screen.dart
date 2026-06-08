import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../theme/app_theme.dart';
import '../widgets/common.dart';

class WebViewScreen extends StatefulWidget {
  final String title;
  final String url;
  const WebViewScreen({super.key, required this.title, required this.url});

  @override
  State<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  WebViewController? _controller;
  bool _loading = true;
  bool _online = true;
  bool _checking = true;

  @override
  void initState() {
    super.initState();
    _checkAndLoad();
  }

  Future<void> _checkAndLoad() async {
    setState(() {
      _checking = true;
      _loading = true;
    });
    final results = await Connectivity().checkConnectivity();
    final bool online = results.any((r) => r != ConnectivityResult.none);
    if (!mounted) return;
    if (!online) {
      setState(() {
        _online = false;
        _checking = false;
      });
      return;
    }
    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(AppColors.bgDark)
      ..setNavigationDelegate(NavigationDelegate(
        onPageFinished: (_) {
          if (mounted) setState(() => _loading = false);
        },
        onWebResourceError: (err) {
          if (mounted && err.isForMainFrame == true) {
            setState(() {
              _online = false;
              _loading = false;
            });
          }
        },
      ))
      ..loadRequest(Uri.parse(widget.url));
    setState(() {
      _controller = controller;
      _online = true;
      _checking = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
              child: Row(
                children: [
                  CircleIconButton(icon: Icons.arrow_back_rounded, onTap: () => Navigator.of(context).pop()),
                  const SizedBox(width: 14),
                  Expanded(child: Text(widget.title, style: AppText.display(20))),
                  if (_online && !_checking)
                    CircleIconButton(icon: Icons.refresh_rounded, onTap: () => _controller?.reload()),
                ],
              ),
            ),
            Expanded(child: _body()),
          ],
        ),
      ),
    );
  }

  Widget _body() {
    if (_checking) {
      return const Center(child: CircularProgressIndicator(color: AppColors.lava));
    }
    if (!_online) {
      return _noConnection();
    }
    return Stack(
      children: [
        if (_controller != null) WebViewWidget(controller: _controller!),
        if (_loading) const Center(child: CircularProgressIndicator(color: AppColors.lava)),
      ],
    );
  }

  Widget _noConnection() {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.wifi_off_rounded, color: AppColors.lavaBright, size: 64),
          const SizedBox(height: 16),
          Text('No internet connection', textAlign: TextAlign.center, style: AppText.display(24)),
          const SizedBox(height: 8),
          Text(
            'Check your connection and try again.',
            textAlign: TextAlign.center,
            style: AppText.body(15, color: AppColors.textMuted),
          ),
          const SizedBox(height: 26),
          GradientButton(
            label: 'TRY AGAIN',
            icon: Icons.refresh_rounded,
            onTap: _checkAndLoad,
          ),
        ],
      ),
    );
  }
}
