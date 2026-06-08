import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/game_state.dart';
import '../theme/app_theme.dart';
import '../util/format.dart';
import '../widgets/common.dart';

class PrestigeScreen extends StatefulWidget {
  const PrestigeScreen({super.key});

  @override
  State<PrestigeScreen> createState() => _PrestigeScreenState();
}

class _PrestigeScreenState extends State<PrestigeScreen> {
  final GameState _game = GameState.instance;

  void _doPrestige() {
    final gained = _game.pendingCores;
    final ok = _game.prestige();
    if (ok) {
      if (_game.hapticsOn) HapticFeedback.heavyImpact();
      showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.bgPanel,
          title: Text('Big Bang!', style: AppText.display(24, color: AppColors.magma)),
          content: Text('You harnessed $gained Magma Core${gained == 1 ? '' : 's'}.\nYour permanent multiplier grew!',
              style: AppText.body(15)),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pop(context);
              },
              child: Text('AWESOME', style: AppText.display(16, color: AppColors.lavaBright)),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final v = _game.currentVolcano;
    return Scaffold(
      body: AppBackground(
        image: v.background,
        darken: 0.72,
        child: SafeArea(
          child: ListenableBuilder(
            listenable: _game,
            builder: (context, _) {
              final bool can = _game.canPrestige;
              final int pending = _game.pendingCores;
              final double progress =
                  (_game.lavaEarnedThisRun / GameState.prestigeThreshold).clamp(0.0, 1.0);
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
                    child: Row(
                      children: [
                        CircleIconButton(icon: Icons.arrow_back_rounded, onTap: () => Navigator.pop(context)),
                        const SizedBox(width: 12),
                        Text('Big Bang', style: AppText.display(26)),
                      ],
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
                      child: Column(
                        children: [
                          const Icon(Icons.flare_rounded, color: AppColors.magma, size: 76),
                          const SizedBox(height: 10),
                          Text('Reset your run for permanent power',
                              textAlign: TextAlign.center, style: AppText.display(20)),
                          const SizedBox(height: 10),
                          Text(
                            'A Big Bang resets your lava and upgrades, but you keep every volcano you unlocked. In return you gain Magma Cores — each one permanently boosts ALL your earnings by 8%.',
                            textAlign: TextAlign.center,
                            style: AppText.body(14, color: AppColors.textMuted),
                          ),
                          const SizedBox(height: 22),
                          GlassPanel(
                            child: Column(
                              children: [
                                _row('Magma Cores owned', formatShort(_game.magmaCores), AppColors.magma),
                                const Divider(color: Colors.white24, height: 22),
                                _row('Current bonus', 'x${_game.prestigeMultiplier.toStringAsFixed(2)}', AppColors.success),
                                const Divider(color: Colors.white24, height: 22),
                                _row('Cores from this run', '+$pending', can ? AppColors.gold : AppColors.textMuted),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          if (!can) ...[
                            Text('Earn ${formatShort(GameState.prestigeThreshold)} lava in a run to unlock your first Big Bang.',
                                textAlign: TextAlign.center, style: AppText.body(13, color: AppColors.textMuted)),
                            const SizedBox(height: 10),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: LinearProgressIndicator(
                                value: progress,
                                minHeight: 10,
                                backgroundColor: Colors.black45,
                                valueColor: const AlwaysStoppedAnimation(AppColors.magma),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text('${formatShort(_game.lavaEarnedThisRun)} / ${formatShort(GameState.prestigeThreshold)}',
                                style: AppText.body(12, color: AppColors.textMuted)),
                          ],
                          const SizedBox(height: 22),
                          GradientButton(
                            label: can ? 'BIG BANG (+$pending CORES)' : 'NOT READY',
                            icon: Icons.flare_rounded,
                            gradient: can
                                ? AppColors.crystalGradient
                                : const LinearGradient(colors: [AppColors.locked, AppColors.locked]),
                            onTap: can ? _doPrestige : null,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _row(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppText.body(15, color: AppColors.textMuted)),
        Text(value, style: AppText.display(18, color: color)),
      ],
    );
  }
}
