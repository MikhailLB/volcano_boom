import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// A collectible / selectable volcano. Each one has a unique look (asset),
/// a matching background, an unlock cost and a permanent earnings multiplier.
class VolcanoDef {
  final int index;
  final String name;
  final String tagline;
  final String description;
  final double unlockCost;
  final double multiplier;
  final Color accent;
  final Color glow;

  const VolcanoDef({
    required this.index,
    required this.name,
    required this.tagline,
    required this.description,
    required this.unlockCost,
    required this.multiplier,
    required this.accent,
    required this.glow,
  });

  String get sprite => Assets.volcano(index);
  String get background => Assets.background(index);
  bool get isStarter => unlockCost <= 0;
}

const List<VolcanoDef> kVolcanoes = [
  VolcanoDef(
    index: 0,
    name: 'Cotton Cosmos',
    tagline: 'Where it all begins',
    description:
        'A gentle dreaming volcano spun from candy-soft clouds. Calm on the surface, but the swirl in its crater hides cosmic power.',
    unlockCost: 0,
    multiplier: 1.0,
    accent: Color(0xFFFF9EC4),
    glow: Color(0xFFB8E1FF),
  ),
  VolcanoDef(
    index: 1,
    name: 'Inferno Peak',
    tagline: 'Pure molten fury',
    description:
        'The classic firestorm. Cracked black rock veined with white-hot magma that blasts embers into the sky with every eruption.',
    unlockCost: 5000,
    multiplier: 1.6,
    accent: Color(0xFFFF7A18),
    glow: Color(0xFFFFC24A),
  ),
  VolcanoDef(
    index: 2,
    name: 'Royal Magma',
    tagline: 'Forged for kings',
    description:
        'An ornate volcano laced with gold filigree and ruby gems. Its eruptions rain riches for those bold enough to claim them.',
    unlockCost: 60000,
    multiplier: 2.4,
    accent: Color(0xFFFFC24A),
    glow: Color(0xFFB14CFF),
  ),
  VolcanoDef(
    index: 3,
    name: 'Aurora Spire',
    tagline: 'Frozen northern lights',
    description:
        'A serene icy cone that breathes shimmering aurora instead of smoke. Cold to the touch, dazzling to behold.',
    unlockCost: 500000,
    multiplier: 3.8,
    accent: Color(0xFF7AE0C8),
    glow: Color(0xFF8FD3FF),
  ),
  VolcanoDef(
    index: 4,
    name: 'Ancient Forge',
    tagline: 'Built by lost giants',
    description:
        'A fortress-mountain carved with runes of an age long gone. Rivers of lava still pour through its forgotten halls.',
    unlockCost: 4000000,
    multiplier: 6.0,
    accent: Color(0xFFB98B4E),
    glow: Color(0xFFFF8A3D),
  ),
  VolcanoDef(
    index: 5,
    name: 'Glitchcore',
    tagline: 'Reality.exe has stopped',
    description:
        'A volcano corrupted into pure data. Pixels shatter and neon lightning crackles where stone should be. Unstable. Unstoppable.',
    unlockCost: 30000000,
    multiplier: 9.5,
    accent: Color(0xFFE6FF3D),
    glow: Color(0xFFB14CFF),
  ),
  VolcanoDef(
    index: 6,
    name: 'Galaxy Maw',
    tagline: 'A star is born',
    description:
        'Its crater is a window into deep space. Eruptions fling nebulae and newborn stars across the void.',
    unlockCost: 250000000,
    multiplier: 16.0,
    accent: Color(0xFFD46CFF),
    glow: Color(0xFFFF7AD9),
  ),
  VolcanoDef(
    index: 7,
    name: 'Runestone',
    tagline: 'Ancient magic awakens',
    description:
        'Mossy and overgrown, its glowing runes channel forgotten spells. The emerald swirl in its heart never sleeps.',
    unlockCost: 1800000000,
    multiplier: 28.0,
    accent: Color(0xFF9CE65A),
    glow: Color(0xFF54E08A),
  ),
  VolcanoDef(
    index: 8,
    name: 'Abyssal Vent',
    tagline: 'Pressure of the deep',
    description:
        'A hydrothermal volcano from the ocean floor, crusted with bioluminescent coral. Its glow lures treasures from the dark.',
    unlockCost: 15000000000,
    multiplier: 48.0,
    accent: Color(0xFF2EE6D6),
    glow: Color(0xFF7AE0FF),
  ),
  VolcanoDef(
    index: 9,
    name: 'Glacier Heart',
    tagline: 'The frozen apex',
    description:
        'The legendary peak of pure crystal ice. Within its frozen core burns a single eternal flame. The ultimate boom.',
    unlockCost: 120000000000,
    multiplier: 85.0,
    accent: Color(0xFF8FD3FF),
    glow: Color(0xFFFFFFFF),
  ),
];
