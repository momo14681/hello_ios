import 'package:flutter/material.dart';

import '../debug/debug_capture.dart';
import '../design/theme.dart';
import 'router.dart';

class CairnApp extends StatelessWidget {
  const CairnApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Cairn',
      theme: buildAppTheme(),
      routerConfig: appRouter,
      debugShowCheckedModeBanner: false,
      // F12 écrit une capture de l'écran réel sur le disque. Inerte hors
      // `kDebugMode`.
      builder: (context, child) =>
          DebugCapture(child: child ?? const SizedBox.shrink()),
    );
  }
}
