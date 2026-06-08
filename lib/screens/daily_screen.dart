import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/game_state.dart';
import '../theme/app_theme.dart';
import '../util/format.dart';
import '../widgets/common.dart';

class DailyScreen extends StatefulWidget {
  const DailyScreen({super.key});

  @override
  State<DailyScreen> createState() => _DailyScreenState();
}

class _DailyScreenState extends State<DailyScreen> {
  final GameState _game = GameState.instance;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _claim() {
    final reward = _game.claimDaily();
    if (reward > 0) {
      if (_game.hapticsOn) HapticFeedback.mediumImpact();
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.bgPanelLight,
          content: Text('Claimed +${formatShort(reward)} lava!', style: AppText.display(16)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final v = _game.currentVolcano;
    final bool available = _game.dailyAvailable;
    // Day index in the 7-day cycle that the next claim will give.
    final int nextDay = available
        ? ((_game.lastDailyClaimMs != 0 &&
                    DateTime.now().millisecondsSinceEpoch - _game.lastDailyClaimMs <= 44 * 3600 * 1000)
                ? (_game.dailyStreak % 7) + 1
                : 1)
        : _game.dailyStreak;

    return Scaffold(
      body: AppBackground(
        image: v.background,
        darken: 0.7,
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
                child: Row(
                  children: [
                    CircleIconButton(icon: Icons.arrow_back_rounded, onTap: () => Navigator.pop(context)),
                    const SizedBox(width: 12),
                    Text('Daily Reward', style: AppText.display(26)),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: Column(
                    children: [
                      const Icon(Icons.card_giftcard_rounded, color: AppColors.gold, size: 64),
                      const SizedBox(height: 8),
                      Text('Streak: day ${_game.dailyStreak} / 7',
                          style: AppText.display(18, color: AppColors.lavaBright)),
                      const SizedBox(height: 16),
                      GridView.count(
                        crossAxisCount: 4,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 0.85,
                        children: List.generate(7, (i) {
                          final int day = i + 1;
                          final bool claimedDay = day < nextDay || (!available && day <= _game.dailyStreak);
                          final bool isNext = available && day == nextDay;
                          return _dayCard(day, claimedDay, isNext);
                        }),
                      ),
                      const SizedBox(height: 24),
                      if (available)
                        GradientButton(
                          label: 'CLAIM +${formatShort(_game.dailyReward(nextDay))}',
                          icon: Icons.water_drop_rounded,
                          gradient: AppColors.goldGradient,
                          onTap: _claim,
                        )
                      else
                        GlassPanel(
                          child: Column(
                            children: [
                              Text('Next reward in', style: AppText.body(14, color: AppColors.textMuted)),
                              const SizedBox(height: 4),
                              Text(formatDuration(_game.dailyCooldown),
                                  style: AppText.display(26, color: AppColors.crystal)),
                            ],
                          ),
                        ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dayCard(int day, bool claimed, bool isNext) {
    return Container(
      decoration: BoxDecoration(
        color: claimed ? AppColors.success.withValues(alpha: 0.18) : AppColors.bgPanel.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isNext ? AppColors.gold : (claimed ? AppColors.success : Colors.white.withValues(alpha: 0.08)),
          width: isNext ? 2 : 1,
        ),
        boxShadow: isNext ? [BoxShadow(color: AppColors.gold.withValues(alpha: 0.5), blurRadius: 12)] : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Day $day', style: AppText.body(11, color: AppColors.textMuted)),
          const SizedBox(height: 4),
          Icon(
            claimed ? Icons.check_circle_rounded : Icons.water_drop_rounded,
            color: claimed ? AppColors.success : AppColors.lavaBright,
            size: 24,
          ),
          const SizedBox(height: 2),
          Text('x${(1 + day * 0.5).toStringAsFixed(1)}', style: AppText.display(13)),
        ],
      ),
    );
  }
}
