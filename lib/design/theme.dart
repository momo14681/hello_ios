import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'tokens.dart';

/// Thème unique de l'application.
///
/// Cairn n'a pas de mode sombre : le ciel du monde change avec l'heure réelle,
/// c'est lui qui porte l'ambiance. Voir CONCEPT.md §5.
ThemeData buildAppTheme() {
  const scheme = ColorScheme.light(
    primary: AppColors.pipDetail,
    onPrimary: Colors.white,
    secondary: AppColors.premium,
    onSecondary: AppColors.ink,
    surface: AppColors.surface,
    onSurface: AppColors.ink,
  );

  final base = ThemeData(colorScheme: scheme, useMaterial3: true);
  final display = GoogleFonts.outfitTextTheme(base.textTheme);

  return base.copyWith(
    scaffoldBackgroundColor: AppColors.surface,
    textTheme: display.apply(
      bodyColor: AppColors.ink,
      displayColor: AppColors.ink,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: GoogleFonts.outfit(
        fontSize: 20,
        fontWeight: FontWeight.w500,
        color: AppColors.ink,
      ),
    ),
    sliderTheme: base.sliderTheme.copyWith(
      activeTrackColor: AppColors.pipDetail,
      inactiveTrackColor: AppColors.pipDetail.withValues(alpha: 0.18),
      thumbColor: AppColors.pipDetail,
      overlayColor: AppColors.pipDetail.withValues(alpha: 0.12),
      trackHeight: 3,
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        textStyle: WidgetStatePropertyAll(
          GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w500),
        ),
      ),
    ),
  );
}

/// Style monospace pour le minuteur : les chiffres ne doivent pas danser.
TextStyle timerTextStyle(double size) => GoogleFonts.robotoMono(
  fontSize: size,
  fontWeight: FontWeight.w500,
  color: AppColors.ink,
  height: 1,
);
