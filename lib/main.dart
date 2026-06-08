import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'gateway/ignition_gate.dart';
import 'models/game_state.dart';
import 'runtime/config_relay.dart';
import 'runtime/link_probe.dart';
import 'runtime/signal_courier.dart';
import 'runtime/tracker_beacon.dart';
import 'runtime/vault_keeper.dart';
import 'runtime/wire_client.dart';
import 'theme/app_theme.dart';
import 'util/format.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase + AppCheck — non-fatal: if config is missing the gray flow
  // silently falls back to the native game.
  try {
    await Firebase.initializeApp();
    await FirebaseAppCheck.instance.activate(
      androidProvider:
          kDebugMode ? AndroidProvider.debug : AndroidProvider.playIntegrity,
    );
  } catch (_) {}

  // Gray flow supports both orientations; the white game re-locks portrait
  // on entry via WhiteGameGate.
  await SystemChrome.setPreferredOrientations(const [
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Colors.transparent,
  ));

  await wire.warmUp();

  final vault = VaultKeeper();
  await vault.open();

  final link = LinkProbe();
  final beacon = TrackerBeacon();
  final relay = ConfigRelay(vault);
  final courier = SignalCourier(vault);

  await GameState.instance.load();

  runApp(VolcanoBoomApp(
    vault: vault,
    link: link,
    beacon: beacon,
    relay: relay,
    courier: courier,
  ));
}

class VolcanoBoomApp extends StatelessWidget {
  final VaultKeeper vault;
  final LinkProbe link;
  final TrackerBeacon beacon;
  final ConfigRelay relay;
  final SignalCourier courier;

  const VolcanoBoomApp({
    super.key,
    required this.vault,
    required this.link,
    required this.beacon,
    required this.relay,
    required this.courier,
  });

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
        snackBarTheme:
            const SnackBarThemeData(behavior: SnackBarBehavior.floating),
      ),
      home: IgnitionGate(
        vault: vault,
        link: link,
        beacon: beacon,
        relay: relay,
        courier: courier,
      ),
    );
  }
}

/// Shared utility to display an offline-earnings welcome-back dialog.
/// Kept here so the white game screens can call it without importing the
/// gray-flow tree.
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
            const Icon(Icons.nightlight_round,
                color: AppColors.crystal, size: 54),
            const SizedBox(height: 12),
            Text('Welcome back!', style: AppText.display(26)),
            const SizedBox(height: 8),
            Text(
              'Your Auto-Vent kept working while you were away.',
              textAlign: TextAlign.center,
              style: AppText.body(15, color: AppColors.textMuted),
            ),
            const SizedBox(height: 18),
            Text('+${formatShort(amount)} lava',
                style: AppText.display(30, color: AppColors.lavaBright)),
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
                child: Text('COLLECT',
                    style: AppText.display(18, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
