import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/volcanoes.dart';
import '../models/game_state.dart';
import '../theme/app_theme.dart';
import '../util/format.dart';
import '../widgets/common.dart';

class CollectionScreen extends StatefulWidget {
  const CollectionScreen({super.key});

  @override
  State<CollectionScreen> createState() => _CollectionScreenState();
}

class _CollectionScreenState extends State<CollectionScreen> {
  final GameState _game = GameState.instance;

  void _onTapVolcano(VolcanoDef v) {
    if (_game.unlocked.contains(v.index)) {
      _game.selectVolcano(v.index);
      if (_game.hapticsOn) HapticFeedback.selectionClick();
    } else {
      _showDetails(v);
    }
    setState(() {});
  }

  void _showDetails(VolcanoDef v) {
    final bool unlocked = _game.unlocked.contains(v.index);
    final bool afford = _game.canAfford(v.unlockCost);
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: AppColors.bgPanel,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: EdgeInsets.fromLTRB(22, 18, 22, 24 + MediaQuery.of(ctx).padding.bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 46, height: 5, decoration: BoxDecoration(color: AppColors.locked, borderRadius: BorderRadius.circular(3))),
            const SizedBox(height: 14),
            SizedBox(height: 160, child: Image.asset(v.sprite, fit: BoxFit.contain)),
            const SizedBox(height: 8),
            Text(v.name, style: AppText.display(26, color: v.accent)),
            Text(v.tagline, style: AppText.body(14, color: AppColors.textMuted)),
            const SizedBox(height: 12),
            Text(v.description, textAlign: TextAlign.center, style: AppText.body(14, color: AppColors.textPrimary)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.bgPanelLight,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.trending_up_rounded, color: AppColors.success, size: 20),
                  const SizedBox(width: 8),
                  Text('Earnings x${v.multiplier.toStringAsFixed(1)}', style: AppText.display(18, color: AppColors.success)),
                ],
              ),
            ),
            const SizedBox(height: 18),
            if (unlocked)
              GradientButton(
                label: _game.selectedVolcano == v.index ? 'SELECTED' : 'SELECT',
                gradient: AppColors.crystalGradient,
                onTap: _game.selectedVolcano == v.index
                    ? null
                    : () {
                        _game.selectVolcano(v.index);
                        Navigator.pop(ctx);
                        setState(() {});
                      },
              )
            else
              GradientButton(
                label: afford ? 'UNLOCK • ${formatShort(v.unlockCost)}' : 'NEED ${formatShort(v.unlockCost)} LAVA',
                icon: afford ? Icons.lock_open_rounded : Icons.lock_rounded,
                gradient: afford ? AppColors.lavaGradient : const LinearGradient(colors: [AppColors.locked, AppColors.locked]),
                onTap: afford
                    ? () {
                        _game.unlockVolcano(v.index);
                        if (_game.hapticsOn) HapticFeedback.mediumImpact();
                        Navigator.pop(ctx);
                        setState(() {});
                      }
                    : null,
              ),
          ],
        ),
      ),
    );
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
                        Text('Volcanoes', style: AppText.display(26)),
                        const Spacer(),
                        Text('${_game.unlocked.length}/${kVolcanoes.length}',
                            style: AppText.display(18, color: AppColors.lavaBright)),
                      ],
                    ),
                  ),
                  Expanded(
                    child: GridView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 0.82,
                      ),
                      itemCount: kVolcanoes.length,
                      itemBuilder: (context, i) => _volcanoCard(kVolcanoes[i]),
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

  Widget _volcanoCard(VolcanoDef v) {
    final bool unlocked = _game.unlocked.contains(v.index);
    final bool selected = _game.selectedVolcano == v.index;
    return Pressable(
      onTap: () => unlocked ? _showDetails(v) : _onTapVolcano(v),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.bgPanel.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? v.accent : Colors.white.withValues(alpha: 0.08),
            width: selected ? 2.5 : 1.2,
          ),
          boxShadow: selected ? [BoxShadow(color: v.accent.withValues(alpha: 0.5), blurRadius: 16)] : null,
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                children: [
                  Expanded(
                    child: ColorFiltered(
                      colorFilter: unlocked
                          ? const ColorFilter.mode(Colors.transparent, BlendMode.multiply)
                          : const ColorFilter.matrix(<double>[
                              0.2126, 0.7152, 0.0722, 0, 0,
                              0.2126, 0.7152, 0.0722, 0, 0,
                              0.2126, 0.7152, 0.0722, 0, 0,
                              0, 0, 0, 1, 0,
                            ]),
                      child: Opacity(
                        opacity: unlocked ? 1 : 0.45,
                        child: Image.asset(v.sprite, fit: BoxFit.contain),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(unlocked ? v.name : '???',
                      maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.display(15)),
                  const SizedBox(height: 2),
                  if (unlocked)
                    Text('x${v.multiplier.toStringAsFixed(1)}', style: AppText.body(13, color: AppColors.success))
                  else
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.water_drop_rounded, size: 13, color: AppColors.lavaBright),
                        const SizedBox(width: 3),
                        Text(formatShort(v.unlockCost), style: AppText.body(13, color: AppColors.lavaBright)),
                      ],
                    ),
                ],
              ),
            ),
            if (selected)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(color: v.accent, shape: BoxShape.circle),
                  child: const Icon(Icons.check_rounded, size: 14, color: Colors.black),
                ),
              ),
            if (!unlocked)
              const Positioned(
                top: 8,
                right: 8,
                child: Icon(Icons.lock_rounded, color: AppColors.textMuted, size: 20),
              ),
          ],
        ),
      ),
    );
  }
}
