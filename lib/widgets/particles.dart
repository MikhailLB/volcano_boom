import 'dart:math';
import 'package:flutter/material.dart';

enum ParticleShape { circle, shard }

/// A single physics particle used for eruption sparks and lava chunks.
class Particle {
  Offset pos;
  Offset vel;
  double life;
  final double maxLife;
  final double size;
  final Color color;
  final ParticleShape shape;
  double rotation;
  final double spin;
  final double gravity;

  Particle({
    required this.pos,
    required this.vel,
    required this.maxLife,
    required this.size,
    required this.color,
    this.shape = ParticleShape.circle,
    this.gravity = 900,
    double? rotation,
    double? spin,
  })  : life = maxLife,
        rotation = rotation ?? 0,
        spin = spin ?? 0;

  bool get dead => life <= 0;

  void update(double dt) {
    vel = Offset(vel.dx * (1 - dt * 0.6), vel.dy + gravity * dt);
    pos += vel * dt;
    rotation += spin * dt;
    life -= dt;
  }

  double get t => (life / maxLife).clamp(0.0, 1.0);
}

/// Floating "+value" text that drifts upward and fades.
class FloatingText {
  Offset pos;
  final String text;
  final Color color;
  final double fontSize;
  double life;
  final double maxLife;
  FloatingText({
    required this.pos,
    required this.text,
    required this.color,
    this.fontSize = 22,
    this.maxLife = 1.1,
  }) : life = maxLife;

  bool get dead => life <= 0;
  void update(double dt) {
    pos = Offset(pos.dx, pos.dy - 60 * dt);
    life -= dt;
  }

  double get t => (life / maxLife).clamp(0.0, 1.0);
}

/// Expanding shockwave ring drawn on eruption.
class Shockwave {
  final Offset center;
  final Color color;
  double life;
  final double maxLife;
  final double maxRadius;
  Shockwave({required this.center, required this.color, this.maxLife = 0.5, this.maxRadius = 220}) : life = maxLife;
  bool get dead => life <= 0;
  void update(double dt) => life -= dt;
  double get t => (life / maxLife).clamp(0.0, 1.0);
}

class EffectsPainter extends CustomPainter {
  final List<Particle> particles;
  final List<FloatingText> texts;
  final List<Shockwave> shockwaves;
  EffectsPainter({required this.particles, required this.texts, required this.shockwaves})
      : super(repaint: null);

  @override
  void paint(Canvas canvas, Size size) {
    // Shockwaves first (behind particles).
    for (final s in shockwaves) {
      final double progress = 1 - s.t;
      final double r = s.maxRadius * Curves.easeOut.transform(progress);
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6 * s.t + 1
        ..color = s.color.withValues(alpha: 0.5 * s.t)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      canvas.drawCircle(s.center, r, paint);
    }

    for (final p in particles) {
      final paint = Paint()
        ..color = p.color.withValues(alpha: p.t)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5);
      if (p.shape == ParticleShape.circle) {
        canvas.drawCircle(p.pos, p.size * (0.4 + 0.6 * p.t), paint);
      } else {
        canvas.save();
        canvas.translate(p.pos.dx, p.pos.dy);
        canvas.rotate(p.rotation);
        final double s = p.size * (0.5 + 0.5 * p.t);
        final path = Path()
          ..moveTo(0, -s)
          ..lineTo(s * 0.7, 0)
          ..lineTo(0, s)
          ..lineTo(-s * 0.7, 0)
          ..close();
        canvas.drawPath(path, paint..maskFilter = null);
        canvas.restore();
      }
    }

    for (final ft in texts) {
      final tp = TextPainter(
        text: TextSpan(
          text: ft.text,
          style: TextStyle(
            fontSize: ft.fontSize,
            fontWeight: FontWeight.w900,
            color: ft.color.withValues(alpha: ft.t),
            shadows: const [Shadow(color: Colors.black, blurRadius: 4, offset: Offset(0, 2))],
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, ft.pos - Offset(tp.width / 2, tp.height / 2));
    }
  }

  @override
  bool shouldRepaint(covariant EffectsPainter oldDelegate) => true;
}

/// Helper to spawn a burst of eruption particles at [origin].
void spawnEruption(
  List<Particle> out,
  Offset origin, {
  required Color color,
  required Color accent,
  int count = 26,
  double power = 1.0,
}) {
  final rng = Random();
  for (int i = 0; i < count; i++) {
    final double angle = -pi / 2 + (rng.nextDouble() - 0.5) * 1.7;
    final double speed = (260 + rng.nextDouble() * 360) * power;
    final bool shard = rng.nextBool();
    out.add(Particle(
      pos: origin,
      vel: Offset(cos(angle) * speed, sin(angle) * speed),
      maxLife: 0.7 + rng.nextDouble() * 0.7,
      size: shard ? 5 + rng.nextDouble() * 7 : 3 + rng.nextDouble() * 5,
      color: rng.nextBool() ? color : accent,
      shape: shard ? ParticleShape.shard : ParticleShape.circle,
      rotation: rng.nextDouble() * pi,
      spin: (rng.nextDouble() - 0.5) * 12,
      gravity: 700 + rng.nextDouble() * 400,
    ));
  }
}
