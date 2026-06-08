import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'particles.dart';

/// Holds the live effect objects. Shared between the game screen (which spawns
/// effects) and the [EffectsLayer] (which animates & paints them).
class EffectsController {
  final List<Particle> particles = [];
  final List<FloatingText> texts = [];
  final List<Shockwave> shocks = [];
  VoidCallback? _wake;

  void addParticles(Iterable<Particle> p) {
    particles.addAll(p);
    _wake?.call();
  }

  void addText(FloatingText t) {
    texts.add(t);
    _wake?.call();
  }

  void addShock(Shockwave s) {
    shocks.add(s);
    _wake?.call();
  }

  bool get isEmpty => particles.isEmpty && texts.isEmpty && shocks.isEmpty;
}

/// A self-ticking layer that animates and paints all active particles.
/// Sleeps (stops its ticker) when there is nothing to draw to save battery.
class EffectsLayer extends StatefulWidget {
  final EffectsController controller;
  const EffectsLayer({super.key, required this.controller});

  @override
  State<EffectsLayer> createState() => _EffectsLayerState();
}

class _EffectsLayerState extends State<EffectsLayer> with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  Duration _last = Duration.zero;
  final ValueNotifier<int> _repaint = ValueNotifier(0);

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_tick);
    widget.controller._wake = _wake;
  }

  void _wake() {
    if (!_ticker.isActive) {
      _last = Duration.zero;
      _ticker.start();
    }
  }

  void _tick(Duration elapsed) {
    final double dt = _last == Duration.zero ? 0 : (elapsed - _last).inMicroseconds / 1e6;
    _last = elapsed;
    final double clamped = dt > 0.05 ? 0.05 : dt;
    final c = widget.controller;
    for (final p in c.particles) {
      p.update(clamped);
    }
    for (final t in c.texts) {
      t.update(clamped);
    }
    for (final s in c.shocks) {
      s.update(clamped);
    }
    c.particles.removeWhere((p) => p.dead);
    c.texts.removeWhere((t) => t.dead);
    c.shocks.removeWhere((s) => s.dead);
    _repaint.value++;
    if (c.isEmpty) {
      _ticker.stop();
    }
  }

  @override
  void dispose() {
    widget.controller._wake = null;
    _ticker.dispose();
    _repaint.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: RepaintBoundary(
        child: CustomPaint(
          painter: _AnimatedEffectsPainter(widget.controller, _repaint),
          size: Size.infinite,
        ),
      ),
    );
  }
}

class _AnimatedEffectsPainter extends CustomPainter {
  final EffectsController c;
  _AnimatedEffectsPainter(this.c, Listenable repaint) : super(repaint: repaint);

  @override
  void paint(Canvas canvas, Size size) {
    EffectsPainter(particles: c.particles, texts: c.texts, shockwaves: c.shocks).paint(canvas, size);
  }

  @override
  bool shouldRepaint(covariant _AnimatedEffectsPainter oldDelegate) => true;
}
