import 'package:go_router/go_router.dart';

import '../features/devbench/dev_bench_screen.dart';
import '../features/expedition/map_screen.dart';
import '../features/session/session_screen.dart';
import '../features/wardrobe/shop_screen.dart';

/// Routes de l'application.
///
/// `/bench` est un outil de développement : il sera retiré du routeur avant
/// la première soumission à l'App Store. Le bouton qui y mène n'apparaît déjà
/// qu'en `kDebugMode`.
final appRouter = GoRouter(
  routes: [
    GoRoute(path: '/', builder: (context, state) => const SessionScreen()),
    GoRoute(path: '/map', builder: (context, state) => const MapScreen()),
    GoRoute(path: '/shop', builder: (context, state) => const ShopScreen()),
    GoRoute(path: '/bench', builder: (context, state) => const DevBenchScreen()),
  ],
);
