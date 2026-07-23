import 'dart:ui';

/// Le ciel de Cairn suit l'heure réelle du téléphone.
///
/// Une session à 7 h et une session à 21 h ne se ressemblent pas. C'est gratuit
/// à implémenter et énorme en perception de soin. Voir CONCEPT.md §5.
class SkyPalette {
  const SkyPalette(this.top, this.mid, this.bottom);

  final Color top;
  final Color mid;
  final Color bottom;

  static SkyPalette lerp(SkyPalette a, SkyPalette b, double t) => SkyPalette(
    Color.lerp(a.top, b.top, t)!,
    Color.lerp(a.mid, b.mid, t)!,
    Color.lerp(a.bottom, b.bottom, t)!,
  );

  /// Cinq moments de la journée, interpolés circulairement.
  static const _keyframes = <(double, SkyPalette)>[
    (
      0,
      SkyPalette(Color(0xFF1B1F3B), Color(0xFF2C3159), Color(0xFF4A4F7A)),
    ),
    (
      6.5,
      SkyPalette(Color(0xFFF7C4A0), Color(0xFFE9A9A9), Color(0xFF9FA9C9)),
    ),
    (
      12,
      SkyPalette(Color(0xFFFFE0B0), Color(0xFFC9D4E4), Color(0xFF9FC3E0)),
    ),
    (
      19,
      SkyPalette(Color(0xFFF5A17A), Color(0xFFB98099), Color(0xFF5E5C8C)),
    ),
    (
      22,
      SkyPalette(Color(0xFF1B1F3B), Color(0xFF2C3159), Color(0xFF4A4F7A)),
    ),
  ];

  /// [hour] est une heure décimale : 13,5 vaut 13 h 30.
  static SkyPalette forHour(double hour) {
    final h = hour % 24;
    for (var i = 0; i < _keyframes.length - 1; i++) {
      final (startH, startSky) = _keyframes[i];
      final (endH, endSky) = _keyframes[i + 1];
      if (h >= startH && h <= endH) {
        final t = (h - startH) / (endH - startH);
        return lerp(startSky, endSky, t);
      }
    }
    // Entre 22 h et minuit : nuit pleine.
    return _keyframes.last.$2;
  }

  static SkyPalette now() {
    final d = DateTime.now();
    return forHour(d.hour + d.minute / 60);
  }

  /// Vrai quand le soleil doit céder la place à la lune.
  static bool isNight(double hour) {
    final h = hour % 24;
    return h < 6 || h > 20;
  }

  /// Obscurité continue, de 0 (plein jour) à 1 (nuit noire).
  ///
  /// Pilote l'apparition des étoiles et l'allumage de la lanterne de Pip.
  /// Contrairement à [isNight], la transition est progressive : c'est ce qui
  /// rend le crépuscule crédible.
  static double nightFactor(double hour) {
    final h = hour % 24;
    if (h >= 8 && h <= 17) return 0;
    if (h > 17 && h < 21) return (h - 17) / 4;
    if (h >= 21 || h < 5) return 1;
    return 1 - (h - 5) / 3;
  }
}
