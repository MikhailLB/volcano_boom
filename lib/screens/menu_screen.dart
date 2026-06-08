import 'package:flutter/material.dart';

import '../main.dart';
import '../models/game_state.dart';
import '../theme/app_theme.dart';
import '../util/format.dart';
import '../widgets/common.dart';
import 'achievements_screen.dart';
import 'collection_screen.dart';
import 'daily_screen.dart';
import 'game_screen.dart';
import 'settings_screen.dart';
import 'webview_screen.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  static const String privacyUrl = 'https://vollcanoboom.com/privacy-policy.html';
  static const String supportUrl = 'https://vollcanoboom.com/support.html';

  final GameState _game = GameState.instance;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) showOfflineDialog(context);
    });
  }

  void _push(Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListenableBuilder(
        listenable: _game,
        builder: (context, _) {
          final v = _game.currentVolcano;
          return AppBackground(
            image: v.background,
            darken: 0.5,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 22),
                child: Column(
                  children: [
                    const SizedBox(height: 8),
                    _topBar(),
                    const Spacer(flex: 2),
                    // Logo.
                    Image.asset(Assets.gameName, height: 150, fit: BoxFit.contain),
                    const SizedBox(height: 6),
                    Text(
                      'Tap. Erupt. Collect the boom.',
                      style: AppText.body(15, color: AppColors.textMuted),
                    ),
                    const Spacer(flex: 3),
                    GradientButton(
                      label: 'PLAY',
                      icon: Icons.play_arrow_rounded,
                      height: 68,
                      fontSize: 26,
                      onTap: () => _push(const GameScreen()),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(child: _menuTile(Icons.collections_rounded, 'Volcanoes', AppColors.magma, () => _push(const CollectionScreen()))),
                        const SizedBox(width: 12),
                        Expanded(child: _menuTile(Icons.emoji_events_rounded, 'Awards', AppColors.gold, () => _push(const AchievementsScreen()))),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: _dailyTile()),
                        const SizedBox(width: 12),
                        Expanded(child: _menuTile(Icons.settings_rounded, 'Settings', AppColors.crystal, () => _push(const SettingsScreen()))),
                      ],
                    ),
                    const Spacer(flex: 2),
                    _footerLinks(),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _topBar() {
    return Row(
      children: [
        CurrencyPill(icon: Icons.water_drop_rounded, value: formatShort(_game.lava)),
        const SizedBox(width: 10),
        if (_game.magmaCores > 0)
          CurrencyPill(
            icon: Icons.flare_rounded,
            value: formatShort(_game.magmaCores),
            gradient: AppColors.crystalGradient,
          ),
      ],
    );
  }

  Widget _menuTile(IconData icon, String label, Color accent, VoidCallback onTap) {
    return Pressable(
      onTap: onTap,
      child: GlassPanel(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          children: [
            Icon(icon, color: accent, size: 30),
            const SizedBox(height: 8),
            Text(label, style: AppText.display(16)),
          ],
        ),
      ),
    );
  }

  Widget _dailyTile() {
    final bool available = _game.dailyAvailable;
    return Pressable(
      onTap: () => _push(const DailyScreen()),
      child: GlassPanel(
        padding: const EdgeInsets.symmetric(vertical: 16),
        border: available ? AppColors.gold : null,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            Column(
              children: [
                Icon(Icons.card_giftcard_rounded, color: available ? AppColors.gold : AppColors.textMuted, size: 30),
                const SizedBox(height: 8),
                Text('Daily', style: AppText.display(16)),
              ],
            ),
            if (available)
              Positioned(
                top: -6,
                right: -2,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: AppColors.ember,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _footerLinks() {
    Widget link(String text, String url) => Pressable(
          onTap: () => _push(WebViewScreen(title: text, url: url)),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            child: Text(
              text,
              style: AppText.body(13, color: AppColors.textMuted).copyWith(
                decoration: TextDecoration.underline,
                decorationColor: AppColors.textMuted,
              ),
            ),
          ),
        );
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        link('Privacy Policy', privacyUrl),
        Text('•', style: AppText.body(13, color: AppColors.textMuted)),
        link('Support', supportUrl),
      ],
    );
  }
}
