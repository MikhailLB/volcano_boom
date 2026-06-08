import 'package:flutter/material.dart';

import '../data/achievements.dart';
import '../models/game_state.dart';
import '../theme/app_theme.dart';
import '../util/format.dart';
import '../widgets/common.dart';

class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final game = GameState.instance;
    final v = game.currentVolcano;
    final int done = kAchievements.where((a) => game.isAchievementClaimed(a.id)).length;
    return Scaffold(
      body: AppBackground(
        image: v.background,
        darken: 0.7,
        child: SafeArea(
          child: ListenableBuilder(
            listenable: game,
            builder: (context, _) {
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
                    child: Row(
                      children: [
                        CircleIconButton(icon: Icons.arrow_back_rounded, onTap: () => Navigator.pop(context)),
                        const SizedBox(width: 12),
                        Text('Awards', style: AppText.display(26)),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            gradient: AppColors.goldGradient,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text('$done / ${kAchievements.length}',
                              style: AppText.display(16, color: Colors.black)),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
                      itemCount: kAchievements.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, i) => _tile(game, kAchievements[i]),
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

  Widget _tile(GameState game, AchievementDef a) {
    final bool done = game.isAchievementClaimed(a.id);
    final double progress = game.achievementProgress(a);
    return GlassPanel(
      padding: const EdgeInsets.all(14),
      border: done ? AppColors.gold.withValues(alpha: 0.5) : null,
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              gradient: done ? AppColors.goldGradient : null,
              color: done ? null : AppColors.bgPanelLight,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(a.icon, color: done ? Colors.black : AppColors.textMuted, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(a.name, style: AppText.display(16)),
                Text(a.description, style: AppText.body(12, color: AppColors.textMuted)),
                const SizedBox(height: 6),
                if (!done)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 6,
                      backgroundColor: Colors.black.withValues(alpha: 0.4),
                      valueColor: const AlwaysStoppedAnimation(AppColors.lava),
                    ),
                  )
                else
                  Row(
                    children: [
                      const Icon(Icons.check_circle_rounded, color: AppColors.gold, size: 16),
                      const SizedBox(width: 4),
                      Text('Reward: ${formatShort(a.reward)} lava',
                          style: AppText.body(12, color: AppColors.gold)),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
