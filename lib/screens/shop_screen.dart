import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/upgrades.dart';
import '../models/game_state.dart';
import '../theme/app_theme.dart';
import '../util/format.dart';
import '../widgets/common.dart';

class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  final GameState _game = GameState.instance;

  String _effectLabel(UpgradeId id) {
    switch (id) {
      case UpgradeId.tapPower:
        return '+4 pressure / tap';
      case UpgradeId.pressureCap:
        return '+30 chamber size';
      case UpgradeId.autoErupt:
        return 'auto lava income';
      case UpgradeId.combo:
        return '+0.5x max combo';
      case UpgradeId.crit:
        return '+3% golden chance';
    }
  }

  String _currentValue(UpgradeId id) {
    switch (id) {
      case UpgradeId.tapPower:
        return '${formatShort(_game.tapPower)} / tap';
      case UpgradeId.pressureCap:
        return '${formatShort(_game.pressureCap)} max';
      case UpgradeId.autoErupt:
        return _game.autoPerSec > 0 ? '${formatShort(_game.autoPerSec)} / s' : 'off';
      case UpgradeId.combo:
        return 'x${_game.maxCombo.toStringAsFixed(1)} max';
      case UpgradeId.crit:
        return '${(_game.critChance * 100).toStringAsFixed(0)}% • x${_game.critMultiplier.toStringAsFixed(1)}';
    }
  }

  void _buy(UpgradeId id) {
    final ok = _game.buyUpgrade(id);
    if (ok) {
      if (_game.hapticsOn) HapticFeedback.lightImpact();
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final v = _game.currentVolcano;
    return Scaffold(
      body: AppBackground(
        image: v.background,
        darken: 0.65,
        child: SafeArea(
          child: ListenableBuilder(
            listenable: _game,
            builder: (context, _) {
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
                    child: Row(
                      children: [
                        CircleIconButton(icon: Icons.arrow_back_rounded, onTap: () => Navigator.pop(context)),
                        const SizedBox(width: 12),
                        Text('Upgrades', style: AppText.display(26)),
                        const Spacer(),
                        CurrencyPill(icon: Icons.water_drop_rounded, value: formatShort(_game.lava)),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
                      children: [
                        _multiplierCard(),
                        const SizedBox(height: 14),
                        for (final id in UpgradeId.values) ...[
                          _upgradeCard(id),
                          const SizedBox(height: 12),
                        ],
                      ],
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

  Widget _multiplierCard() {
    return GlassPanel(
      color: AppColors.bgPanelLight.withValues(alpha: 0.7),
      child: Row(
        children: [
          const Icon(Icons.trending_up_rounded, color: AppColors.success, size: 30),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Total multiplier', style: AppText.body(13, color: AppColors.textMuted)),
                Text('x${formatShort(_game.globalMultiplier)}', style: AppText.display(24, color: AppColors.success)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${_game.currentVolcano.name} x${_game.volcanoMultiplier.toStringAsFixed(1)}',
                  style: AppText.body(12, color: AppColors.textMuted)),
              if (_game.magmaCores > 0)
                Text('Cores x${_game.prestigeMultiplier.toStringAsFixed(2)}',
                    style: AppText.body(12, color: AppColors.magma)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _upgradeCard(UpgradeId id) {
    final def = kUpgrades[id]!;
    final int level = _game.levels[id]!;
    final bool maxed = def.isMaxed(level);
    final double cost = _game.upgradeCost(id);
    final bool afford = _game.canAfford(cost) && !maxed;

    return GlassPanel(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              gradient: AppColors.lavaGradient,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(def.icon, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(child: Text(def.name, style: AppText.display(17))),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text('Lv $level', style: AppText.body(12, color: AppColors.lavaBright)),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(_currentValue(id), style: AppText.body(13, color: AppColors.textPrimary)),
                Text(maxed ? 'Maxed out' : _effectLabel(id),
                    style: AppText.body(12, color: maxed ? AppColors.gold : AppColors.textMuted)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _buyButton(id, cost, afford, maxed),
        ],
      ),
    );
  }

  Widget _buyButton(UpgradeId id, double cost, bool afford, bool maxed) {
    if (maxed) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.gold.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.star_rounded, color: AppColors.gold),
      );
    }
    return Pressable(
      onTap: afford ? () => _buy(id) : null,
      child: Container(
        constraints: const BoxConstraints(minWidth: 84),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          gradient: afford ? AppColors.lavaGradient : null,
          color: afford ? null : Colors.black.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: afford ? Colors.transparent : AppColors.locked),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.water_drop_rounded, size: 16, color: Colors.white),
            const SizedBox(height: 2),
            Text(formatShort(cost),
                style: AppText.display(15, color: afford ? Colors.white : AppColors.textMuted)),
          ],
        ),
      ),
    );
  }
}
