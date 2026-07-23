import 'dart:math';

import 'package:flutter/material.dart';

import '../../domain/expedition.dart';

/// Le relief de la carte, dessiné selon le **biome** de l'étape la plus proche.
///
/// Semer des sommets au hasard autour d'un « lac gelé » ne raconte rien. Ici,
/// le terrain traversé annonce l'étape vers laquelle on marche : on approche
/// du gué par des étangs, du lac gelé par des glaces, du sommet par des cimes.
abstract final class Terrain {
  static const forest = Color(0xFF7E9A86);
  static const rock = Color(0xFF9AA6BA);
  static const snow = Color(0xFFF2F5FA);
  static const lake = Color(0xFFA8C4DC);
  static const ice = Color(0xFFCFE4EF);
  static const sand = Color(0xFFDCC79E);
  static const stone = Color(0xFFB1AFA4);

  /// Dessine un élément de décor adapté à [biome].
  static void feature(
    Canvas canvas,
    Offset at,
    LegKind biome,
    Random rnd, {
    double scale = 1,
  }) {
    final roll = rnd.nextDouble();

    switch (biome) {
      case LegKind.water:
        roll < 0.6
            ? water(canvas, at, rnd, scale: scale)
            : forestPatch(canvas, at, rnd, scale: scale);

      case LegKind.forest:
        roll < 0.78
            ? forestPatch(canvas, at, rnd, scale: scale)
            : water(canvas, at, rnd, scale: scale);

      case LegKind.ridge:
      case LegKind.pass:
        roll < 0.72
            ? peak(canvas, at, rnd, scale: scale)
            : forestPatch(canvas, at, rnd, scale: scale);

      case LegKind.summit:
        roll < 0.86
            ? peak(canvas, at, rnd, scale: scale, snowy: true)
            : forestPatch(canvas, at, rnd, scale: scale);

      case LegKind.ice:
        roll < 0.55
            ? frozenWater(canvas, at, rnd, scale: scale)
            : peak(canvas, at, rnd, scale: scale, snowy: true);

      case LegKind.ruins:
        roll < 0.55
            ? ruin(canvas, at, rnd, scale: scale)
            : peak(canvas, at, rnd, scale: scale);

      case LegKind.dunes:
        roll < 0.8
            ? dune(canvas, at, rnd, scale: scale)
            : ruin(canvas, at, rnd, scale: scale);
    }
  }

  /// Le repère de l'étape elle-même : la même chose, en plus grand.
  static void landmark(Canvas canvas, Offset at, LegKind kind, int seed) {
    final rnd = Random(seed);
    switch (kind) {
      case LegKind.water:
        water(canvas, at, rnd, scale: 2.1);
      case LegKind.ice:
        frozenWater(canvas, at, rnd, scale: 2.1);
      case LegKind.forest:
        forestPatch(canvas, at, rnd, scale: 1.7);
      case LegKind.summit:
        peak(canvas, at, rnd, scale: 1.75, snowy: true);
      case LegKind.ridge:
      case LegKind.pass:
        peak(canvas, at, rnd, scale: 1.45);
      case LegKind.ruins:
        ruin(canvas, at, rnd, scale: 1.8);
      case LegKind.dunes:
        dune(canvas, at, rnd, scale: 1.9);
    }
  }

  static void forestPatch(
    Canvas canvas,
    Offset at,
    Random rnd, {
    double scale = 1,
  }) {
    final paint = Paint()..color = forest.withValues(alpha: 0.55);
    final count = 3 + rnd.nextInt(4);
    for (var i = 0; i < count; i++) {
      final o = Offset(
        at.dx + (rnd.nextDouble() - 0.5) * 26 * scale,
        at.dy + (rnd.nextDouble() - 0.5) * 16 * scale,
      );
      final h = (8 + rnd.nextDouble() * 6) * scale;
      canvas.drawPath(
        Path()
          ..moveTo(o.dx, o.dy - h)
          ..lineTo(o.dx + h * 0.36, o.dy)
          ..lineTo(o.dx - h * 0.36, o.dy)
          ..close(),
        paint,
      );
    }
  }

  static void peak(
    Canvas canvas,
    Offset at,
    Random rnd, {
    double scale = 1,
    bool snowy = false,
  }) {
    final h = (16 + rnd.nextDouble() * 22) * scale;
    final w = h * (0.85 + rnd.nextDouble() * 0.4);

    canvas.drawPath(
      Path()
        ..moveTo(at.dx, at.dy - h)
        ..lineTo(at.dx + w, at.dy)
        ..lineTo(at.dx - w, at.dy)
        ..close(),
      Paint()..color = rock.withValues(alpha: snowy ? 0.5 : 0.42),
    );

    // La calotte, qui rend le relief lisible même en petit.
    canvas.drawPath(
      Path()
        ..moveTo(at.dx, at.dy - h)
        ..lineTo(at.dx + w * 0.33, at.dy - h * (snowy ? 0.5 : 0.62))
        ..lineTo(at.dx + w * 0.13, at.dy - h * 0.7)
        ..lineTo(at.dx - w * 0.1, at.dy - h * (snowy ? 0.48 : 0.6))
        ..lineTo(at.dx - w * 0.33, at.dy - h * (snowy ? 0.52 : 0.62))
        ..close(),
      Paint()..color = snow.withValues(alpha: 0.88),
    );
  }

  static void water(Canvas canvas, Offset at, Random rnd, {double scale = 1}) {
    final w = (20 + rnd.nextDouble() * 22) * scale;
    canvas.drawOval(
      Rect.fromCenter(center: at, width: w, height: w * 0.5),
      Paint()..color = lake.withValues(alpha: 0.58),
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: at.translate(w * 0.18, -w * 0.05),
        width: w * 0.5,
        height: w * 0.22,
      ),
      Paint()..color = lake.withValues(alpha: 0.45),
    );
  }

  /// Un lac pris par les glaces : plus pâle, fendu de craquelures.
  static void frozenWater(
    Canvas canvas,
    Offset at,
    Random rnd, {
    double scale = 1,
  }) {
    final w = (22 + rnd.nextDouble() * 20) * scale;
    final rect = Rect.fromCenter(center: at, width: w, height: w * 0.52);

    canvas.drawOval(rect, Paint()..color = ice.withValues(alpha: 0.85));
    canvas.drawOval(
      rect,
      Paint()
        ..color = lake.withValues(alpha: 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );

    final crack = Paint()
      ..color = lake.withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.9
      ..strokeCap = StrokeCap.round;

    for (var i = 0; i < 3; i++) {
      final a = rnd.nextDouble() * 2 * pi;
      canvas.drawLine(
        at,
        Offset(at.dx + cos(a) * w * 0.36, at.dy + sin(a) * w * 0.19),
        crack,
      );
    }
  }

  static void dune(Canvas canvas, Offset at, Random rnd, {double scale = 1}) {
    final w = (26 + rnd.nextDouble() * 22) * scale;
    final h = w * 0.34;
    canvas.drawPath(
      Path()
        ..moveTo(at.dx - w / 2, at.dy)
        ..quadraticBezierTo(at.dx - w * 0.2, at.dy - h, at.dx + w * 0.08, at.dy)
        ..close(),
      Paint()..color = sand.withValues(alpha: 0.65),
    );
    canvas.drawPath(
      Path()
        ..moveTo(at.dx - w * 0.05, at.dy)
        ..quadraticBezierTo(
          at.dx + w * 0.22,
          at.dy - h * 1.25,
          at.dx + w / 2,
          at.dy,
        )
        ..close(),
      Paint()..color = sand.withValues(alpha: 0.5),
    );
  }

  static void ruin(Canvas canvas, Offset at, Random rnd, {double scale = 1}) {
    final paint = Paint()..color = stone.withValues(alpha: 0.62);
    final base = (7 + rnd.nextDouble() * 4) * scale;

    for (var i = 0; i < 3; i++) {
      final h = base * (0.6 + rnd.nextDouble() * 1.1);
      canvas.drawRect(
        Rect.fromLTWH(
          at.dx - base * 1.4 + i * base * 1.1,
          at.dy - h,
          base * 0.55,
          h,
        ),
        paint,
      );
    }
    canvas.drawRect(
      Rect.fromLTWH(at.dx - base * 1.6, at.dy - base * 0.2, base * 3.4, base * 0.24),
      paint,
    );
  }
}
