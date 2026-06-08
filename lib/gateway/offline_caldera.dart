import 'dart:async';

import 'package:flutter/material.dart';

import '../runtime/link_probe.dart';

/// Offline screen. Two orientation-aware static backgrounds + a stone/lava
/// retry button anchored at the bottom.
class OfflineCalderaScreen extends StatefulWidget {
  final WidgetBuilder retryBuilder;
  final LinkProbe? link;
  const OfflineCalderaScreen({
    super.key,
    required this.retryBuilder,
    this.link,
  });

  @override
  State<OfflineCalderaScreen> createState() => _OfflineCalderaScreenState();
}

class _OfflineCalderaScreenState extends State<OfflineCalderaScreen>
    with TickerProviderStateMixin {
  bool _busy = false;
  late final AnimationController _emberCtrl;
  late final Animation<double> _emberAnim;

  String? _topBanner;
  Timer? _bannerTimer;

  @override
  void initState() {
    super.initState();
    _emberCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);
    _emberAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _emberCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _bannerTimer?.cancel();
    _emberCtrl.dispose();
    super.dispose();
  }

  void _showBanner(String message) {
    _bannerTimer?.cancel();
    setState(() => _topBanner = message);
    _bannerTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _topBanner = null);
    });
  }

  Future<void> _retry() async {
    if (_busy) return;
    setState(() => _busy = true);

    // If we have a LinkProbe, verify connectivity before navigating away.
    // Without this, tapping Retry while still offline immediately rebuilds
    // the WebView screen which then hangs on a black "loading" frame.
    if (widget.link != null) {
      final online = await widget.link!.hasReachableInternet();
      if (!online) {
        if (!mounted) return;
        setState(() => _busy = false);
        _showBanner('Still no connection. Check Wi-Fi or mobile data.');
        return;
      }
    } else {
      await Future.delayed(const Duration(milliseconds: 600));
    }

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: widget.retryBuilder),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final landscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    final bg = landscape
        ? 'assets/Horizontal_Nowifi_Screen.webp'
        : 'assets/Vertical_Nowifi_Screen.webp';

    return Scaffold(
      backgroundColor: const Color(0xFF080304),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            bg,
            fit: BoxFit.cover,
            width: size.width,
            height: size.height,
            filterQuality: FilterQuality.high,
          ),
          // Soft bottom darken for button legibility on bright backgrounds.
          Align(
            alignment: Alignment.bottomCenter,
            child: FractionallySizedBox(
              heightFactor: landscape ? 0.5 : 0.35,
              child: const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Color(0xCC000000)],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: landscape ? size.width * 0.25 : size.width * 0.10,
            right: landscape ? size.width * 0.25 : size.width * 0.10,
            bottom: landscape ? size.height * 0.08 : size.height * 0.10,
            child: AnimatedBuilder(
              animation: _emberAnim,
              builder: (_, _) => _LavaButton(
                label: _busy ? 'CONNECTING…' : 'TRY AGAIN',
                ember: _emberAnim.value,
                busy: _busy,
                compact: landscape,
                onTap: _retry,
              ),
            ),
          ),
          // Inline status banner — pinned to the very top so it never hides
          // the retry button (landscape layouts had the SnackBar overlapping).
          Positioned(
            top: MediaQuery.of(context).viewPadding.top + 12,
            left: 16,
            right: 16,
            child: IgnorePointer(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                child: _topBanner == null
                    ? const SizedBox.shrink()
                    : Container(
                        key: ValueKey(_topBanner),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2B0B05).withValues(alpha: 0.92),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: const Color(0xFFFF8A50).withValues(alpha: 0.4),
                            width: 1.2,
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black54,
                              blurRadius: 12,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.wifi_off_rounded,
                              size: 18,
                              color: Color(0xFFFFE0B2),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _topBanner!,
                                style: const TextStyle(
                                  color: Color(0xFFFFE0B2),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LavaButton extends StatefulWidget {
  final String label;
  final double ember;
  final bool busy;
  final bool compact;
  final VoidCallback onTap;

  const _LavaButton({
    required this.label,
    required this.ember,
    required this.busy,
    required this.compact,
    required this.onTap,
  });

  @override
  State<_LavaButton> createState() => _LavaButtonState();
}

class _LavaButtonState extends State<_LavaButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final radius = 12.0;
    return GestureDetector(
      onTapDown: (_) => setState(() => _down = true),
      onTapCancel: () => setState(() => _down = false),
      onTapUp: (_) {
        setState(() => _down = false);
        if (!widget.busy) widget.onTap();
      },
      child: AnimatedScale(
        scale: _down ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 90),
        child: Container(
          height: widget.compact ? 50 : 58,
          decoration: BoxDecoration(
            // Asymmetric chiselled border-radius — bigger on left, sharper on right.
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(radius * 2),
              bottomLeft: Radius.circular(radius * 2),
              topRight: Radius.circular(radius / 2),
              bottomRight: Radius.circular(radius * 2.5),
            ),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: widget.busy
                  ? const [Color(0xFF3A1208), Color(0xFF1F0805)]
                  : const [Color(0xFFFF5722), Color(0xFFB71C1C)],
            ),
            border: Border.all(
              color: const Color(0xFFFFD180).withValues(alpha: 0.55),
              width: 1.4,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF8A50).withValues(
                  alpha: widget.busy ? 0.15 : (0.35 + widget.ember * 0.35),
                ),
                blurRadius: 12 + widget.ember * 14,
                spreadRadius: widget.ember * 2,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: widget.busy
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.6,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Color(0xFFFFE0B2)),
                    ),
                  )
                : Text(
                    widget.label,
                    style: TextStyle(
                      color: const Color(0xFFFFF3E0),
                      fontSize: widget.compact ? 15 : 18,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.6,
                      shadows: const [
                        Shadow(
                          color: Color(0xFF3E0A00),
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
