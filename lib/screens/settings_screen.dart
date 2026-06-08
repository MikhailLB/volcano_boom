import 'package:flutter/material.dart';

import '../data/volcanoes.dart';
import '../models/game_state.dart';
import '../theme/app_theme.dart';
import '../util/format.dart';
import '../widgets/common.dart';
import 'webview_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const String privacyUrl = 'https://vollcanoboom.com/privacy-policy.html';
  static const String supportUrl = 'https://vollcanoboom.com/support.html';

  final GameState _game = GameState.instance;

  void _confirmReset() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgPanel,
        title: Text('Reset all progress?', style: AppText.display(20)),
        content: Text(
          'This permanently deletes your lava, upgrades, volcanoes, cores and achievements. This cannot be undone.',
          style: AppText.body(14, color: AppColors.textMuted),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('CANCEL', style: AppText.body(15, color: AppColors.textMuted))),
          TextButton(
            onPressed: () async {
              await _game.hardReset();
              if (ctx.mounted) Navigator.pop(ctx);
              if (mounted) setState(() {});
            },
            child: Text('RESET', style: AppText.display(15, color: AppColors.ember)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final v = _game.currentVolcano;
    final playTime = Duration(
        milliseconds: DateTime.now().millisecondsSinceEpoch - _game.sessionStart);
    return Scaffold(
      body: AppBackground(
        image: v.background,
        darken: 0.72,
        child: SafeArea(
          child: ListenableBuilder(
            listenable: _game,
            builder: (context, _) {
              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: [
                  Row(
                    children: [
                      CircleIconButton(icon: Icons.arrow_back_rounded, onTap: () => Navigator.pop(context)),
                      const SizedBox(width: 12),
                      Text('Settings', style: AppText.display(26)),
                    ],
                  ),
                  const SizedBox(height: 18),
                  const SectionTitle('Audio & Feedback'),
                  const SizedBox(height: 10),
                  _toggle('Sound effects', Icons.volume_up_rounded, _game.soundOn, _game.setSound),
                  const SizedBox(height: 10),
                  _toggle('Vibration', Icons.vibration_rounded, _game.hapticsOn, _game.setHaptics),
                  const SizedBox(height: 22),
                  const SectionTitle('Your Stats', accent: AppColors.crystal),
                  const SizedBox(height: 10),
                  _statsPanel(playTime),
                  const SizedBox(height: 22),
                  const SectionTitle('About', accent: AppColors.magma),
                  const SizedBox(height: 10),
                  _linkTile('Privacy Policy', Icons.privacy_tip_rounded, privacyUrl),
                  const SizedBox(height: 10),
                  _linkTile('Support', Icons.support_agent_rounded, supportUrl),
                  const SizedBox(height: 22),
                  Pressable(
                    onTap: _confirmReset,
                    child: GlassPanel(
                      border: AppColors.ember.withValues(alpha: 0.5),
                      child: Row(
                        children: [
                          const Icon(Icons.delete_forever_rounded, color: AppColors.ember),
                          const SizedBox(width: 12),
                          Text('Reset progress', style: AppText.display(16, color: AppColors.ember)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Center(child: Text('Volcano Boom • v1.0.0', style: AppText.body(12, color: AppColors.textMuted))),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _toggle(String label, IconData icon, bool value, ValueChanged<bool> onChanged) {
    return GlassPanel(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: AppColors.lavaBright),
          const SizedBox(width: 14),
          Expanded(child: Text(label, style: AppText.display(16))),
          Switch(
            value: value,
            activeThumbColor: AppColors.lava,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _statsPanel(Duration playTime) {
    Widget stat(String label, String value) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: AppText.body(14, color: AppColors.textMuted)),
              Text(value, style: AppText.display(15)),
            ],
          ),
        );
    return GlassPanel(
      child: Column(
        children: [
          stat('Total taps', formatInt(_game.totalTaps)),
          stat('Total eruptions', formatInt(_game.totalEruptions)),
          stat('Lava earned (all time)', formatShort(_game.totalLavaEarned)),
          stat('Best combo', 'x${_game.bestCombo.toStringAsFixed(1)}'),
          stat('Volcanoes unlocked', '${_game.unlocked.length} / ${kVolcanoes.length}'),
          stat('Magma cores', formatShort(_game.magmaCores)),
          stat('Big Bangs', formatInt(_game.prestigeCount)),
          stat('This session', formatDuration(playTime)),
        ],
      ),
    );
  }

  Widget _linkTile(String label, IconData icon, String url) {
    return Pressable(
      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => WebViewScreen(title: label, url: url))),
      child: GlassPanel(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Icon(icon, color: AppColors.crystal),
            const SizedBox(width: 14),
            Expanded(child: Text(label, style: AppText.display(16))),
            const Icon(Icons.open_in_new_rounded, color: AppColors.textMuted, size: 20),
          ],
        ),
      ),
    );
  }
}
