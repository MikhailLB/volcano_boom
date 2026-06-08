import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import 'models/game_state.dart';
import 'screens/loading_screen.dart';
import 'theme/app_theme.dart';
import 'util/format.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Colors.transparent,
  ));
  await GameState.instance.load();
  runApp(const VolcanoBoomApp());
}

class VolcanoBoomApp extends StatelessWidget {
  const VolcanoBoomApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Volcano Boom',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.bgDark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.lava,
          brightness: Brightness.dark,
        ),
        snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
      ),
      home: const GameLoopHost(child: LoadingScreen()),
    );
  }
}

/// Wraps the whole app to drive the passive game loop (auto income, combo
/// decay), periodic autosave, lifecycle save and floating achievement toasts.
class GameLoopHost extends StatefulWidget {
  final Widget child;
  const GameLoopHost({super.key, required this.child});

  @override
  State<GameLoopHost> createState() => _GameLoopHostState();
}

class _GameLoopHostState extends State<GameLoopHost> with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final Ticker _ticker;
  Duration _last = Duration.zero;
  double _saveAccum = 0;
  final GameState _game = GameState.instance;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _ticker = createTicker(_onTick)..start();
    _game.addListener(_onGameChanged);
  }

  void _onTick(Duration elapsed) {
    final double dt = _last == Duration.zero ? 0 : (elapsed - _last).inMicroseconds / 1e6;
    _last = elapsed;
    if (dt <= 0) return;
    final double clamped = dt > 0.1 ? 0.1 : dt;
    _game.tick(clamped);
    _saveAccum += clamped;
    if (_saveAccum >= 15) {
      _saveAccum = 0;
      _game.save();
    }
  }

  void _onGameChanged() {
    if (_game.pendingAchievementToasts.isNotEmpty) {
      final toasts = List<String>.from(_game.pendingAchievementToasts);
      _game.pendingAchievementToasts.clear();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        for (final t in toasts) {
          _showAchievementToast(t);
        }
      });
    }
  }

  void _showAchievementToast(String name) {
    if (!mounted) return;
    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger?.showSnackBar(
      SnackBar(
        backgroundColor: AppColors.bgPanelLight,
        duration: const Duration(seconds: 3),
        content: Row(
          children: [
            const Icon(Icons.emoji_events_rounded, color: AppColors.gold),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Achievement unlocked!', style: AppText.body(12, color: AppColors.textMuted)),
                  Text(name, style: AppText.display(16)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _game.save();
    }
  }

  @override
  void dispose() {
    _game.removeListener(_onGameChanged);
    WidgetsBinding.instance.removeObserver(this);
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// Shared utility to display an offline-earnings welcome-back dialog.
Future<void> showOfflineDialog(BuildContext context) async {
  final game = GameState.instance;
  if (game.pendingOfflineEarnings <= 0) return;
  final double amount = game.pendingOfflineEarnings;
  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => Dialog(
      backgroundColor: AppColors.bgPanel,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.nightlight_round, color: AppColors.crystal, size: 54),
            const SizedBox(height: 12),
            Text('Welcome back!', style: AppText.display(26)),
            const SizedBox(height: 8),
            Text(
              'Your Auto-Vent kept working while you were away.',
              textAlign: TextAlign.center,
              style: AppText.body(15, color: AppColors.textMuted),
            ),
            const SizedBox(height: 18),
            Text('+${formatShort(amount)} lava', style: AppText.display(30, color: AppColors.lavaBright)),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.lava,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () {
                  game.claimOfflineEarnings();
                  Navigator.of(ctx).pop();
                },
                child: Text('COLLECT', style: AppText.display(18, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
