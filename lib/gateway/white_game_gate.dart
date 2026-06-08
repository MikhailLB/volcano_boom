import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../game_loop_host.dart';
import '../screens/loading_screen.dart';

/// Entry into the native Volcano Boom game (the "white part").
///
/// The native game is portrait-only by design — locking orientation here
/// ensures we don't carry over the landscape that some gray-flow screens
/// allowed.
class WhiteGameGate extends StatefulWidget {
  const WhiteGameGate({super.key});

  @override
  State<WhiteGameGate> createState() => _WhiteGameGateState();
}

class _WhiteGameGateState extends State<WhiteGameGate> {
  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }

  @override
  Widget build(BuildContext context) {
    return const GameLoopHost(child: LoadingScreen());
  }
}
