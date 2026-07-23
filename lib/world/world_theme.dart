import 'dart:ui';

import '../data/expedition/expedition_catalog.dart';
import 'landscape/landscape_spec.dart';
import 'sky.dart';

/// L'ambiance du monde traversé pendant une session.
///
/// Chaque itinéraire a la sienne : marcher vers le désert d'ambre et vers la
/// banquise ne doit pas se ressembler. Le thème pilote les couleurs des
/// collines, la forme du décor dressé et la teinte du ciel.
class WorldTheme {
  const WorldTheme({
    required this.id,
    required this.landscape,
    required this.skyTint,
    required this.skyTintAmount,
  });

  final String id;
  final LandscapeSpec landscape;

  /// Teinte mêlée au ciel de l'heure courante.
  final Color skyTint;

  /// Force du mélange, de 0 (ciel neutre) à 1.
  final double skyTintAmount;

  SkyPalette skyFor(double hour) {
    final base = SkyPalette.forHour(hour);
    if (skyTintAmount <= 0) return base;
    return SkyPalette(
      Color.lerp(base.top, skyTint, skyTintAmount)!,
      Color.lerp(base.mid, skyTint, skyTintAmount * 0.7)!,
      Color.lerp(base.bottom, skyTint, skyTintAmount * 0.5)!,
    );
  }

  // ---- Montagne (première traversée) ----
  static const mountain = WorldTheme(
    id: 'first_crossing',
    landscape: LandscapeSpec.standard,
    skyTint: Color(0xFFFFFFFF),
    skyTintAmount: 0,
  );

  // ---- Désert d'ambre ----
  static const _desertLandscape = LandscapeSpec(
    [
      LandscapeLayer(
        baseFraction: 0.56,
        amplitudes: [12, 8, 4],
        frequencies: [0.0048, 0.0110, 0.0221],
        phases: [0.7, 2.4, 4.1],
        speed: 0.10,
        color: Color(0xFFE9D2A8),
      ),
      LandscapeLayer(
        baseFraction: 0.66,
        amplitudes: [16, 10, 5],
        frequencies: [0.0041, 0.0093, 0.0186],
        phases: [2.2, 3.9, 1.1],
        speed: 0.24,
        color: Color(0xFFD8B885),
      ),
      LandscapeLayer(
        baseFraction: 0.76,
        amplitudes: [14, 9, 5],
        frequencies: [0.0058, 0.0128, 0.0240],
        phases: [3.4, 1.5, 5.5],
        speed: 0.52,
        color: Color(0xFFBE9A66),
      ),
      LandscapeLayer(
        baseFraction: 0.86,
        amplitudes: [10, 6, 3],
        frequencies: [0.0070, 0.0155, 0.0287],
        phases: [2.7, 5.1, 1.9],
        speed: 1.0,
        color: Color(0xFF8E6E45),
      ),
    ],
    [
      LayerDecor.none,
      LayerDecor(treeSpacing: 150, treeHeight: 18, style: DecorStyle.spire),
      LayerDecor(
        treeSpacing: 130,
        treeHeight: 28,
        boulderSpacing: 190,
        style: DecorStyle.spire,
      ),
      LayerDecor(
        treeSpacing: 210,
        treeHeight: 44,
        boulderSpacing: 150,
        grassSpacing: 90,
        style: DecorStyle.spire,
      ),
    ],
  );

  static const desert = WorldTheme(
    id: 'amber_desert',
    landscape: _desertLandscape,
    skyTint: Color(0xFFFFC98A),
    skyTintAmount: 0.34,
  );

  // ---- Banquise ----
  static const _iceLandscape = LandscapeSpec(
    [
      LandscapeLayer(
        baseFraction: 0.56,
        amplitudes: [15, 9, 5],
        frequencies: [0.0055, 0.0120, 0.0235],
        phases: [0.2, 1.9, 4.6],
        speed: 0.10,
        color: Color(0xFFDCE9F2),
      ),
      LandscapeLayer(
        baseFraction: 0.66,
        amplitudes: [18, 11, 6],
        frequencies: [0.0045, 0.0100, 0.0198],
        phases: [1.7, 3.4, 0.6],
        speed: 0.24,
        color: Color(0xFFBBD0E2),
      ),
      LandscapeLayer(
        baseFraction: 0.76,
        amplitudes: [16, 10, 6],
        frequencies: [0.0063, 0.0136, 0.0255],
        phases: [3.3, 1.0, 5.0],
        speed: 0.52,
        color: Color(0xFF8FAAC4),
      ),
      LandscapeLayer(
        baseFraction: 0.86,
        amplitudes: [12, 7, 4],
        frequencies: [0.0076, 0.0166, 0.0305],
        phases: [2.1, 4.6, 1.4],
        speed: 1.0,
        color: Color(0xFF5C748F),
      ),
    ],
    [
      LayerDecor.none,
      LayerDecor(treeSpacing: 110, treeHeight: 16, style: DecorStyle.shard),
      LayerDecor(
        treeSpacing: 95,
        treeHeight: 26,
        boulderSpacing: 260,
        style: DecorStyle.shard,
      ),
      LayerDecor(
        treeSpacing: 170,
        treeHeight: 40,
        boulderSpacing: 200,
        style: DecorStyle.shard,
      ),
    ],
  );

  static const ice = WorldTheme(
    id: 'frozen_shelf',
    landscape: _iceLandscape,
    skyTint: Color(0xFF9FC6E6),
    skyTintAmount: 0.52,
  );

  static const all = [mountain, desert, ice];

  /// Le thème d'un itinéraire. Retombe sur la montagne si l'identifiant est
  /// inconnu, ce qui garde l'app fonctionnelle si un itinéraire disparaît du
  /// catalogue.
  static WorldTheme forExpedition(String expeditionId) {
    for (final theme in all) {
      if (theme.id == expeditionId) return theme;
    }
    return mountain;
  }

  static WorldTheme get initial =>
      forExpedition(ExpeditionCatalog.initial.id);
}
