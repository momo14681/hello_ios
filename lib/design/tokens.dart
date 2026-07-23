import 'package:flutter/material.dart';

/// Jetons de design de Cairn.
///
/// Toute valeur visuelle réutilisée vit ici. Aucun `Color(0x...)` ni durée
/// codée en dur ailleurs dans l'application.
abstract final class AppColors {
  // Pip
  static const pipBodyTop = Color(0xFFFFDCA8);
  static const pipBodyBottom = Color(0xFFE3A176);
  static const pipDetail = Color(0xFF6B5C9B);
  static const pipStrap = Color(0xFF544679);
  static const pipPennant = Color(0xFFE2806B);
  static const pipSweat = Color(0xFF9FD4EE);
  static const pipImpact = Color(0xFFFFC061);
  static const pipEye = Color(0xFF3A2F4A);
  static const pipHighlight = Color(0xFFFFFFFF);

  /// Les joues. Deux ovales roses, et le personnage bascule d'un coup dans
  /// l'attachant — c'est le meilleur rapport lignes de code / effet.
  static const pipBlush = Color(0xFFF2836F);
  static const pipMouth = Color(0xFF7A4550);

  /// La veine minérale qui traverse le corps : c'est la marque de Pip.
  /// Un galet de rivière, pas un simple ovale.
  static const pipVein = Color(0xFFFFF3DE);

  static const lanternGlass = Color(0xFFFFD98A);
  static const lanternFrame = Color(0xFF4A3F6B);
  static const lanternGlow = Color(0xFFFFC061);

  // Monde
  static const cairnStone = Color(0xFF6E6459);
  static const shadow = Color(0x331E2234);
  static const cloud = Color(0xFFFFFFFF);
  static const star = Color(0xFFFFF6E0);

  // Collines, de la plus lointaine à la plus proche.
  // Déclarées une par une : l'indexation d'une liste n'est pas une expression
  // constante, or les couches du paysage sont construites en `const`.
  static const hillFar = Color(0xFFAEBCD2);
  static const hillMid = Color(0xFF8B9BB8);
  static const hillNear = Color(0xFF68789A);
  static const hillGround = Color(0xFF46516E);

  static const hills = <Color>[hillFar, hillMid, hillNear, hillGround];

  // Décor. Chaque couche assombrit sa propre couleur de colline pour rester
  // cohérente en profondeur — voir `Decor.tint`.
  static const treeDark = Color(0xFF2F3A52);
  static const grassBlade = Color(0xFF35405C);
  static const snowCap = Color(0xFFE9EEF7);

  // Interface
  static const ink = Color(0xFF2E2A3F);
  static const inkSoft = Color(0xFF6B6580);
  static const surface = Color(0xFFFBF7F1);
  static const surfaceRaised = Color(0xFFFFFFFF);
  static const premium = Color(0xFFE8A87C);
}

/// Durées d'animation. Voir CONCEPT.md §5.
abstract final class AppDurations {
  static const fast = Duration(milliseconds: 150);
  static const base = Duration(milliseconds: 250);
  static const slow = Duration(milliseconds: 400);
  static const celebrate = Duration(milliseconds: 900);
}

/// Courbes. `elasticOut` est réservé à Pip et aux pierres du cairn.
abstract final class AppCurves {
  static const standard = Curves.easeOutCubic;
  static const entrance = Curves.easeOutQuart;
  static const bouncy = Curves.elasticOut;
}

abstract final class AppSpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 40.0;
}

abstract final class AppRadii {
  static const control = Radius.circular(12);
  static const card = Radius.circular(20);
}
