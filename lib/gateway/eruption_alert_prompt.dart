import 'package:flutter/material.dart';

import '../env/runtime_profile.dart';
import '../runtime/link_probe.dart';
import '../runtime/signal_courier.dart';
import '../runtime/vault_keeper.dart';
import 'magma_shell.dart' deferred as shell;

/// Push permission promo. Shown once per cool-down cycle, only when the OS
/// hasn't already permanently denied the permission.
class EruptionAlertPrompt extends StatefulWidget {
  final VaultKeeper vault;
  final SignalCourier courier;
  final LinkProbe link;
  final String shellUrl;

  const EruptionAlertPrompt({
    super.key,
    required this.vault,
    required this.courier,
    required this.link,
    required this.shellUrl,
  });

  @override
  State<EruptionAlertPrompt> createState() => _EruptionAlertPromptState();
}

class _EruptionAlertPromptState extends State<EruptionAlertPrompt> {
  Future<void> _onAccept() async {
    final granted = await widget.courier.askPermission();
    if (!mounted) return;
    if (!granted) {
      final until = DateTime.now().millisecondsSinceEpoch ~/ 1000 +
          RuntimeProfile.notificationCoolDownSeconds;
      await widget.vault.writeAlertCoolDown(until);
    }
    _enterShell();
  }

  Future<void> _onLater() async {
    final until = DateTime.now().millisecondsSinceEpoch ~/ 1000 +
        RuntimeProfile.notificationCoolDownSeconds;
    await widget.vault.writeAlertCoolDown(until);
    if (!mounted) return;
    _enterShell();
  }

  Future<void> _enterShell() async {
    await shell.loadLibrary();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => shell.MagmaShell(
          url: widget.shellUrl,
          vault: widget.vault,
          courier: widget.courier,
          link: widget.link,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final landscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    final bg = landscape
        ? 'assets/Horizontal_Notifications_Screen.webp'
        : 'assets/Vertical_Notifications_Screen.webp';

    return Scaffold(
      backgroundColor: const Color(0xFF080304),
      body: SizedBox(
        width: size.width,
        height: size.height,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              bg,
              fit: BoxFit.cover,
              width: size.width,
              height: size.height,
              filterQuality: FilterQuality.high,
            ),
            // Bottom shading to make buttons readable on bright artwork.
            Align(
              alignment: Alignment.bottomCenter,
              child: FractionallySizedBox(
                heightFactor: landscape ? 0.45 : 0.32,
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
            // Buttons
            Positioned(
              left: landscape ? size.width * 0.28 : size.width * 0.10,
              right: landscape ? size.width * 0.28 : size.width * 0.10,
              bottom: landscape ? size.height * 0.07 : size.height * 0.08,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _EmberAccept(onTap: _onAccept, compact: landscape),
                  SizedBox(height: landscape ? 8 : 14),
                  _AshDecline(onTap: _onLater, compact: landscape),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmberAccept extends StatefulWidget {
  final VoidCallback onTap;
  final bool compact;
  const _EmberAccept({required this.onTap, required this.compact});

  @override
  State<_EmberAccept> createState() => _EmberAcceptState();
}

class _EmberAcceptState extends State<_EmberAccept>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;
  late final Animation<double> _heat;
  bool _down = false;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
    _heat = Tween<double>(begin: 0.25, end: 0.85)
        .animate(CurvedAnimation(parent: _pulse, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _down = true),
      onTapCancel: () => setState(() => _down = false),
      onTapUp: (_) {
        setState(() => _down = false);
        widget.onTap();
      },
      child: AnimatedBuilder(
        animation: _heat,
        builder: (_, _) {
          final t = _heat.value;
          return AnimatedScale(
            scale: _down ? 0.95 : 1.0,
            duration: const Duration(milliseconds: 80),
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: widget.compact ? 12 : 18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: _down
                      ? const [Color(0xFFB23A0F), Color(0xFF6B1606)]
                      : const [Color(0xFFFF6F00), Color(0xFFC62828)],
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(26),
                  topRight: Radius.circular(6),
                  bottomLeft: Radius.circular(6),
                  bottomRight: Radius.circular(26),
                ),
                border: Border.all(
                  color: const Color(0xFFFFD180).withValues(alpha: 0.6),
                  width: 1.4,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF7043).withValues(alpha: t),
                    blurRadius: 16 + t * 18,
                    spreadRadius: t * 3,
                    offset: const Offset(0, 5),
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.4),
                    blurRadius: 7,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Text(
                'IGNITE ALERTS',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: const Color(0xFFFFF8E1),
                  fontSize: widget.compact ? 15 : 19,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.8,
                  shadows: const [
                    Shadow(
                      color: Color(0xFF3E0A00),
                      blurRadius: 5,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _AshDecline extends StatefulWidget {
  final VoidCallback onTap;
  final bool compact;
  const _AshDecline({required this.onTap, required this.compact});

  @override
  State<_AshDecline> createState() => _AshDeclineState();
}

class _AshDeclineState extends State<_AshDecline> {
  bool _down = false;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _down = true),
      onTapCancel: () => setState(() => _down = false),
      onTapUp: (_) {
        setState(() => _down = false);
        widget.onTap();
      },
      child: AnimatedOpacity(
        opacity: _down ? 0.45 : 0.82,
        duration: const Duration(milliseconds: 90),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: widget.compact ? 4 : 6),
          child: Text(
            'Maybe later',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: const Color(0xFFE0D2C2),
              fontSize: widget.compact ? 14 : 16,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.6,
              decoration: TextDecoration.underline,
              decorationColor: const Color(0xFFE0D2C2).withValues(alpha: 0.5),
              decorationThickness: 1.2,
              shadows: const [
                Shadow(
                  color: Colors.black87,
                  blurRadius: 5,
                  offset: Offset(0, 2),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
