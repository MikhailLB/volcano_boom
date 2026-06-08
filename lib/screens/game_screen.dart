import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/volcanoes.dart';
import '../models/game_state.dart';
import '../theme/app_theme.dart';
import '../util/format.dart';
import '../widgets/common.dart';
import '../widgets/effects_layer.dart';
import '../widgets/particles.dart';
import 'collection_screen.dart';
import 'prestige_screen.dart';
import 'shop_screen.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with TickerProviderStateMixin {
  final GameState _game = GameState.instance;
  final EffectsController _fx = EffectsController();

  late final AnimationController _punch;
  late final AnimationController _idle;
  late final AnimationController _shake;
  final Random _rng = Random();

  Offset _crater = Offset.zero;

  @override
  void initState() {
    super.initState();
    _punch = AnimationController(vsync: this, duration: const Duration(milliseconds: 140), lowerBound: 0, upperBound: 1);
    _idle = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat(reverse: true);
    _shake = AnimationController(vsync: this, duration: const Duration(milliseconds: 380));
  }

  @override
  void dispose() {
    _punch.dispose();
    _idle.dispose();
    _shake.dispose();
    _game.save();
    super.dispose();
  }

  void _handleTap(Offset localInPlay, Offset playOrigin) {
    final tapPos = localInPlay + playOrigin;
    final v = _game.currentVolcano;

    final erupts = _game.tap();
    _punch.forward(from: 0);
    if (_game.hapticsOn) HapticFeedback.selectionClick();

    // Small spark on the tap point.
    _fx.addParticles(_smallSparks(tapPos, v));

    if (erupts > 0) {
      // Consume eruption events queued by the game state.
      for (final e in _game.pendingErupts) {
        _onErupt(e, v);
      }
      _game.pendingErupts.clear();
    }
  }

  Iterable<Particle> _smallSparks(Offset pos, VolcanoDef v) {
    return List.generate(4, (_) {
      final ang = -pi / 2 + (_rng.nextDouble() - 0.5) * 2.2;
      final sp = 120 + _rng.nextDouble() * 140;
      return Particle(
        pos: pos,
        vel: Offset(cos(ang) * sp, sin(ang) * sp),
        maxLife: 0.4 + _rng.nextDouble() * 0.3,
        size: 3 + _rng.nextDouble() * 3,
        color: _rng.nextBool() ? v.accent : v.glow,
        gravity: 500,
      );
    });
  }

  void _onErupt(EruptEvent e, VolcanoDef v) {
    if (_game.hapticsOn) {
      e.crit ? HapticFeedback.heavyImpact() : HapticFeedback.mediumImpact();
    }
    spawnEruption(
      _fx.particles,
      _crater,
      color: e.crit ? AppColors.gold : v.accent,
      accent: e.crit ? AppColors.lavaBright : v.glow,
      count: e.crit ? 46 : 28,
      power: e.crit ? 1.4 : 1.0,
    );
    _fx.addShock(Shockwave(
      center: _crater,
      color: e.crit ? AppColors.gold : v.glow,
      maxRadius: e.crit ? 320 : 230,
    ));
    _fx.addText(FloatingText(
      pos: _crater - const Offset(0, 30),
      text: '+${formatShort(e.reward)}',
      color: e.crit ? AppColors.gold : AppColors.lavaBright,
      fontSize: e.crit ? 34 : 26,
    ));
    _punch.forward(from: 0);
    _triggerShake(e.crit ? 1.0 : 0.55);
  }

  void _triggerShake(double power) {
    _shake.stop();
    _shakePower = power;
    _shake.forward(from: 0);
  }

  double _shakePower = 0;

  Offset _shakeOffset() {
    if (!_shake.isAnimating) return Offset.zero;
    final double decay = (1 - _shake.value);
    final double mag = 14 * _shakePower * decay;
    return Offset(
      sin(_shake.value * pi * 8) * mag,
      cos(_shake.value * pi * 6) * mag * 0.6,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListenableBuilder(
        listenable: _game,
        builder: (context, _) {
          final v = _game.currentVolcano;
          return Stack(
            children: [
              Positioned.fill(child: Image.asset(v.background, fit: BoxFit.cover, gaplessPlayback: true)),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.35),
                        Colors.black.withValues(alpha: 0.25),
                        Colors.black.withValues(alpha: 0.7),
                      ],
                    ),
                  ),
                ),
              ),
              SafeArea(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final double w = constraints.maxWidth;
                    final double h = constraints.maxHeight;
                    const double topH = 64;
                    const double bottomH = 96;
                    final double playTop = topH;
                    final double playH = h - topH - bottomH;
                    _crater = Offset(w / 2, playTop + playH * 0.34);

                    return Stack(
                      children: [
                        // Volcano + tap area (with screen shake).
                        Positioned(
                          left: 0,
                          top: playTop,
                          width: w,
                          height: playH,
                          child: AnimatedBuilder(
                            animation: Listenable.merge([_punch, _idle, _shake]),
                            builder: (context, child) {
                              return Transform.translate(
                                offset: _shakeOffset(),
                                child: child,
                              );
                            },
                            child: _playArea(v, w, playH, Offset(0, playTop)),
                          ),
                        ),
                        // Particle effects above the volcano.
                        Positioned.fill(child: EffectsLayer(controller: _fx)),
                        // Top bar.
                        Positioned(left: 14, right: 14, top: 6, child: _topBar(v)),
                        // Combo badge.
                        Positioned(
                          top: topH + 6,
                          left: 0,
                          right: 0,
                          child: Center(child: _comboBadge()),
                        ),
                        // Bottom controls.
                        Positioned(left: 14, right: 14, bottom: 8, child: _bottomBar(v)),
                      ],
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _playArea(VolcanoDef v, double w, double playH, Offset playOrigin) {
    final double pulse = 0.5 + 0.5 * sin(_idle.value * pi * 2);
    final double punchScale = 1 + 0.06 * (1 - _punch.value) * _punch.value * 4;
    final double glowStrength = 0.25 + 0.55 * _game.pressureFraction;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (d) => _handleTap(d.localPosition, playOrigin),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Glow behind the volcano, intensifying with pressure.
          IgnorePointer(
            child: Container(
              width: w * 0.9,
              height: w * 0.9,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    v.glow.withValues(alpha: glowStrength * (0.7 + 0.3 * pulse)),
                    v.accent.withValues(alpha: glowStrength * 0.3),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.45, 1.0],
                ),
              ),
            ),
          ),
          // Volcano sprite.
          Transform.scale(
            scale: punchScale * (0.99 + 0.02 * pulse),
            child: Image.asset(
              v.sprite,
              width: w * 0.82,
              fit: BoxFit.contain,
            ),
          ),
          // Pressure gauge + tap hint at the bottom of the play area.
          Positioned(
            bottom: 6,
            left: 24,
            right: 24,
            child: _pressureGauge(v),
          ),
        ],
      ),
    );
  }

  Widget _pressureGauge(VolcanoDef v) {
    final double frac = _game.pressureFraction;
    final bool near = frac > 0.8;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('PRESSURE', style: AppText.display(13, color: AppColors.textMuted)),
            Text(
              'Next boom +${formatShort(_game.eruptionBaseReward * _game.comboValue)}',
              style: AppText.body(12, color: AppColors.lavaBright),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            children: [
              Container(height: 18, color: Colors.black.withValues(alpha: 0.5)),
              FractionallySizedBox(
                widthFactor: frac,
                child: Container(
                  height: 18,
                  decoration: BoxDecoration(
                    gradient: near
                        ? const LinearGradient(colors: [AppColors.lavaBright, AppColors.ember])
                        : AppColors.lavaGradient,
                    boxShadow: near
                        ? [BoxShadow(color: AppColors.ember.withValues(alpha: 0.7), blurRadius: 10)]
                        : null,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _topBar(VolcanoDef v) {
    return Row(
      children: [
        CircleIconButton(icon: Icons.arrow_back_rounded, onTap: () => Navigator.of(context).pop(), size: 42),
        const SizedBox(width: 10),
        Expanded(
          child: Align(
            alignment: Alignment.centerLeft,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              reverse: true,
              child: Row(
                children: [
                  CurrencyPill(icon: Icons.water_drop_rounded, value: formatShort(_game.lava)),
                  const SizedBox(width: 8),
                  if (_game.autoPerSec > 0)
                    CurrencyPill(
                      icon: Icons.autorenew_rounded,
                      value: '${formatShort(_game.autoPerSec)}/s',
                      gradient: const LinearGradient(colors: [AppColors.success, Color(0xFF2E9E5B)]),
                    ),
                  if (_game.magmaCores > 0) ...[
                    const SizedBox(width: 8),
                    CurrencyPill(icon: Icons.flare_rounded, value: formatShort(_game.magmaCores), gradient: AppColors.crystalGradient),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _comboBadge() {
    final double combo = _game.comboValue;
    if (combo <= 1.01) return const SizedBox(height: 36);
    final double frac = ((combo - 1) / (_game.maxCombo - 1)).clamp(0.0, 1.0);
    final Color c = Color.lerp(AppColors.lavaBright, AppColors.ember, frac)!;
    return AnimatedScale(
      scale: 1,
      duration: const Duration(milliseconds: 120),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: c, width: 2),
          boxShadow: [BoxShadow(color: c.withValues(alpha: 0.5), blurRadius: 12)],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.local_fire_department_rounded, color: c, size: 20),
            const SizedBox(width: 6),
            Text('x${combo.toStringAsFixed(1)} COMBO', style: AppText.display(18, color: c)),
          ],
        ),
      ),
    );
  }

  Widget _bottomBar(VolcanoDef v) {
    return Row(
      children: [
        Expanded(
          child: _actionButton(
            Icons.upgrade_rounded,
            'Upgrades',
            AppColors.lavaGradient,
            () async {
              await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ShopScreen()));
              setState(() {});
            },
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _actionButton(
            Icons.collections_rounded,
            'Volcanoes',
            AppColors.crystalGradient,
            () async {
              await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CollectionScreen()));
              setState(() {});
            },
          ),
        ),
        if (_game.canPrestige) ...[
          const SizedBox(width: 10),
          Expanded(
            child: _actionButton(
              Icons.flare_rounded,
              'Big Bang',
              AppColors.goldGradient,
              () async {
                await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PrestigeScreen()));
                setState(() {});
              },
              glow: true,
            ),
          ),
        ],
      ],
    );
  }

  Widget _actionButton(IconData icon, String label, Gradient gradient, VoidCallback onTap, {bool glow = false}) {
    return Pressable(
      onTap: onTap,
      child: Container(
        height: 72,
        decoration: BoxDecoration(
          color: AppColors.bgPanel.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: gradient.colors.first.withValues(alpha: glow ? 0.9 : 0.4), width: glow ? 2 : 1.2),
          boxShadow: glow ? [BoxShadow(color: gradient.colors.first.withValues(alpha: 0.5), blurRadius: 14)] : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ShaderMask(
              shaderCallback: (r) => gradient.createShader(r),
              child: Icon(icon, color: Colors.white, size: 28),
            ),
            const SizedBox(height: 4),
            Text(label, style: AppText.display(14)),
          ],
        ),
      ),
    );
  }
}
