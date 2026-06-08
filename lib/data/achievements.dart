import 'package:flutter/material.dart';

enum AchMetric { taps, eruptions, lavaEarned, volcanoes, prestige, bestCombo, autoLevel }

class AchievementDef {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final AchMetric metric;
  final double target;
  final double reward; // lava reward

  const AchievementDef({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.metric,
    required this.target,
    required this.reward,
  });
}

const List<AchievementDef> kAchievements = [
  AchievementDef(id: 'tap_100', name: 'Warming Up', description: 'Tap the volcano 100 times.', icon: Icons.touch_app_rounded, metric: AchMetric.taps, target: 100, reward: 250),
  AchievementDef(id: 'tap_1k', name: 'Restless Fingers', description: 'Tap 1,000 times.', icon: Icons.touch_app_rounded, metric: AchMetric.taps, target: 1000, reward: 2500),
  AchievementDef(id: 'tap_10k', name: 'Tap Machine', description: 'Tap 10,000 times.', icon: Icons.touch_app_rounded, metric: AchMetric.taps, target: 10000, reward: 50000),
  AchievementDef(id: 'tap_50k', name: 'Unstoppable Thumb', description: 'Tap 50,000 times.', icon: Icons.touch_app_rounded, metric: AchMetric.taps, target: 50000, reward: 400000),

  AchievementDef(id: 'erupt_10', name: 'First Boom', description: 'Trigger 10 eruptions.', icon: Icons.volcano_rounded, metric: AchMetric.eruptions, target: 10, reward: 500),
  AchievementDef(id: 'erupt_100', name: 'Boom Enthusiast', description: 'Trigger 100 eruptions.', icon: Icons.volcano_rounded, metric: AchMetric.eruptions, target: 100, reward: 5000),
  AchievementDef(id: 'erupt_1k', name: 'Boom Master', description: 'Trigger 1,000 eruptions.', icon: Icons.volcano_rounded, metric: AchMetric.eruptions, target: 1000, reward: 80000),
  AchievementDef(id: 'erupt_5k', name: 'Eruption Legend', description: 'Trigger 5,000 eruptions.', icon: Icons.volcano_rounded, metric: AchMetric.eruptions, target: 5000, reward: 750000),

  AchievementDef(id: 'lava_10k', name: 'Pocket Lava', description: 'Earn 10K lava in total.', icon: Icons.water_drop_rounded, metric: AchMetric.lavaEarned, target: 10000, reward: 1500),
  AchievementDef(id: 'lava_1m', name: 'Lava Millionaire', description: 'Earn 1M lava in total.', icon: Icons.water_drop_rounded, metric: AchMetric.lavaEarned, target: 1000000, reward: 60000),
  AchievementDef(id: 'lava_1b', name: 'Lava Tycoon', description: 'Earn 1B lava in total.', icon: Icons.water_drop_rounded, metric: AchMetric.lavaEarned, target: 1000000000, reward: 5000000),
  AchievementDef(id: 'lava_1t', name: 'Molten Mogul', description: 'Earn 1T lava in total.', icon: Icons.water_drop_rounded, metric: AchMetric.lavaEarned, target: 1000000000000, reward: 2000000000),

  AchievementDef(id: 'volc_3', name: 'Collector', description: 'Unlock 3 volcanoes.', icon: Icons.collections_rounded, metric: AchMetric.volcanoes, target: 3, reward: 20000),
  AchievementDef(id: 'volc_6', name: 'Curator', description: 'Unlock 6 volcanoes.', icon: Icons.collections_rounded, metric: AchMetric.volcanoes, target: 6, reward: 2000000),
  AchievementDef(id: 'volc_10', name: 'The Whole Set', description: 'Unlock all 10 volcanoes.', icon: Icons.collections_rounded, metric: AchMetric.volcanoes, target: 10, reward: 500000000),

  AchievementDef(id: 'prestige_1', name: 'Big Bang', description: 'Perform your first Big Bang.', icon: Icons.flare_rounded, metric: AchMetric.prestige, target: 1, reward: 100000),
  AchievementDef(id: 'prestige_5', name: 'Cycle of Fire', description: 'Perform 5 Big Bangs.', icon: Icons.flare_rounded, metric: AchMetric.prestige, target: 5, reward: 10000000),

  AchievementDef(id: 'combo_10', name: 'On Fire', description: 'Reach a 10x combo.', icon: Icons.bolt_rounded, metric: AchMetric.bestCombo, target: 10, reward: 30000),
  AchievementDef(id: 'combo_25', name: 'Combo King', description: 'Reach a 25x combo.', icon: Icons.bolt_rounded, metric: AchMetric.bestCombo, target: 25, reward: 1500000),

  AchievementDef(id: 'auto_10', name: 'Self-Sufficient', description: 'Reach Auto-Vent level 10.', icon: Icons.autorenew_rounded, metric: AchMetric.autoLevel, target: 10, reward: 75000),
  AchievementDef(id: 'auto_25', name: 'Hands Free', description: 'Reach Auto-Vent level 25.', icon: Icons.autorenew_rounded, metric: AchMetric.autoLevel, target: 25, reward: 8000000),
];
