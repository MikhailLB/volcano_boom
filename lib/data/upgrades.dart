import 'package:flutter/material.dart';

/// Identifiers for each upgradeable stat.
enum UpgradeId { tapPower, pressureCap, autoErupt, combo, crit }

class UpgradeDef {
  final UpgradeId id;
  final String name;
  final String description;
  final IconData icon;
  final double baseCost;
  final double costGrowth;
  final int? maxLevel;

  const UpgradeDef({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.baseCost,
    required this.costGrowth,
    this.maxLevel,
  });

  /// Cost to purchase the level after [currentLevel].
  double costForLevel(int currentLevel) => baseCost * _pow(costGrowth, currentLevel);

  bool isMaxed(int level) => maxLevel != null && level >= maxLevel!;
}

double _pow(double base, int exp) {
  double r = 1;
  for (int i = 0; i < exp; i++) {
    r *= base;
  }
  return r;
}

const Map<UpgradeId, UpgradeDef> kUpgrades = {
  UpgradeId.tapPower: UpgradeDef(
    id: UpgradeId.tapPower,
    name: 'Tap Power',
    description: 'Build more pressure with every tap.',
    icon: Icons.touch_app_rounded,
    baseCost: 25,
    costGrowth: 1.17,
  ),
  UpgradeId.pressureCap: UpgradeDef(
    id: UpgradeId.pressureCap,
    name: 'Magma Chamber',
    description: 'Bigger chamber means bigger, richer eruptions.',
    icon: Icons.expand_rounded,
    baseCost: 60,
    costGrowth: 1.20,
  ),
  UpgradeId.autoErupt: UpgradeDef(
    id: UpgradeId.autoErupt,
    name: 'Auto-Vent',
    description: 'Earns lava automatically, even while you rest.',
    icon: Icons.autorenew_rounded,
    baseCost: 120,
    costGrowth: 1.22,
  ),
  UpgradeId.combo: UpgradeDef(
    id: UpgradeId.combo,
    name: 'Combo Mastery',
    description: 'Raises your max combo multiplier and makes it last longer.',
    icon: Icons.local_fire_department_rounded,
    baseCost: 800,
    costGrowth: 1.55,
    maxLevel: 12,
  ),
  UpgradeId.crit: UpgradeDef(
    id: UpgradeId.crit,
    name: 'Golden Eruption',
    description: 'Chance for a critical eruption that pays out massively.',
    icon: Icons.auto_awesome_rounded,
    baseCost: 1500,
    costGrowth: 1.6,
    maxLevel: 20,
  ),
};
