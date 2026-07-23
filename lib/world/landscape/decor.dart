import 'dart:math';

import 'package:flutter/material.dart';

import '../../design/tokens.dart';
import 'landscape_spec.dart';

/// Le décor procédural du paysage.
///
/// Tout est déterministe : un arbre à une position donnée du monde a toujours
/// la même forme. Rien n'est stocké, tout est recalculé à partir d'une graine.
abstract final class Decor {
  /// Assombrit une couleur de colline pour que le décor reste cohérent avec
  /// sa profondeur : les arbres lointains sont pâles, les proches sont noirs.
  static Color tint(Color hill, double amount) =>
      Color.lerp(hill, AppColors.treeDark, amount)!;

  /// Parcourt les positions visibles d'un semis régulier avec jitter.
  static void _scatter(
    Size size,
    LandscapeLayer layer,
    double scroll,
    double spacing,
    int seedBase,
    void Function(double x, double groundY, Random rnd) draw,
  ) {
    if (spacing <= 0) return;
    final layerScroll = scroll * layer.speed;
    final first = (layerScroll / spacing).floor() - 1;

    for (var k = first; ; k++) {
      final anchor = k * spacing - layerScroll;
      if (anchor > size.width + 140) break;

      final rnd = Random(seedBase * 7919 + k * 104729);
      final x = anchor + (rnd.nextDouble() - 0.5) * spacing * 0.7;
      if (x < -80 || x > size.width + 80) continue;

      draw(x, layer.yAt(x, scroll, size.height), rnd);
    }
  }

  static void trees(
    Canvas canvas,
    Size size,
    LandscapeLayer layer,
    double scroll,
    LayerDecor decor,
    int seedBase,
    double depth,
  ) {
    final color = tint(layer.color, 0.35 + depth * 0.4);
    _scatter(size, layer, scroll, decor.treeSpacing, seedBase, (x, y, rnd) {
      final h = decor.treeHeight * (0.75 + rnd.nextDouble() * 0.5);
      switch (decor.style) {
        case DecorStyle.conifer:
          _conifer(canvas, x, y + 1, h, color);
        case DecorStyle.spire:
          _spire(canvas, x, y + 1, h, color);
        case DecorStyle.shard:
          _shard(canvas, x, y + 1, h, color, rnd);
      }
    });
  }

  static void boulders(
    Canvas canvas,
    Size size,
    LandscapeLayer layer,
    double scroll,
    LayerDecor decor,
    int seedBase,
    double depth,
  ) {
    final paint = Paint()..color = tint(layer.color, 0.28 + depth * 0.3);
    _scatter(size, layer, scroll, decor.boulderSpacing, seedBase + 41, (
      x,
      y,
      rnd,
    ) {
      final w = 9 + rnd.nextDouble() * 11;
      canvas.drawOval(
        Rect.fromCenter(center: Offset(x, y - w * 0.22), width: w, height: w * 0.62),
        paint,
      );
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(x + w * 0.4, y - w * 0.12),
          width: w * 0.6,
          height: w * 0.4,
        ),
        paint,
      );
    });
  }

  static void grass(
    Canvas canvas,
    Size size,
    LandscapeLayer layer,
    double scroll,
    LayerDecor decor,
    int seedBase,
  ) {
    final paint = Paint()
      ..color = AppColors.grassBlade.withValues(alpha: 0.75)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;

    _scatter(size, layer, scroll, decor.grassSpacing, seedBase + 77, (
      x,
      y,
      rnd,
    ) {
      final blades = 2 + rnd.nextInt(3);
      for (var i = 0; i < blades; i++) {
        final dx = (i - blades / 2) * 2.6;
        final h = 4 + rnd.nextDouble() * 4;
        final bend = (rnd.nextDouble() - 0.5) * 4;
        canvas.drawPath(
          Path()
            ..moveTo(x + dx, y + 1)
            ..quadraticBezierTo(x + dx + bend * 0.4, y - h * 0.6, x + dx + bend, y - h),
          paint,
        );
      }
    });
  }

  static void _conifer(
    Canvas canvas,
    double x,
    double groundY,
    double h,
    Color color,
  ) {
    final paint = Paint()..color = color;

    canvas.drawRect(
      Rect.fromLTWH(x - h * 0.035, groundY - h * 0.22, h * 0.07, h * 0.24),
      paint,
    );

    for (var i = 0; i < 3; i++) {
      final tierW = h * 0.46 * (1 - i * 0.22);
      final baseY = groundY - h * (0.16 + i * 0.23);
      canvas.drawPath(
        Path()
          ..moveTo(x, baseY - h * 0.38)
          ..lineTo(x + tierW / 2, baseY)
          ..lineTo(x - tierW / 2, baseY)
          ..close(),
        paint,
      );
    }
  }

  /// Une aiguille rocheuse : haute, étroite, à sommet cassé.
  static void _spire(
    Canvas canvas,
    double x,
    double groundY,
    double h,
    Color color,
  ) {
    final w = h * 0.3;
    canvas.drawPath(
      Path()
        ..moveTo(x - w / 2, groundY)
        ..lineTo(x - w * 0.28, groundY - h * 0.82)
        ..lineTo(x + w * 0.1, groundY - h)
        ..lineTo(x + w * 0.34, groundY - h * 0.6)
        ..lineTo(x + w / 2, groundY)
        ..close(),
      Paint()..color = color,
    );
  }

  /// Un éclat de glace dressé, incliné au hasard.
  static void _shard(
    Canvas canvas,
    double x,
    double groundY,
    double h,
    Color color,
    Random rnd,
  ) {
    final lean = (rnd.nextDouble() - 0.5) * h * 0.34;
    final w = h * 0.36;
    canvas.drawPath(
      Path()
        ..moveTo(x - w / 2, groundY)
        ..lineTo(x + lean, groundY - h)
        ..lineTo(x + w / 2, groundY)
        ..close(),
      Paint()..color = color.withValues(alpha: 0.85),
    );
  }

  /// Nuages, dérivant lentement derrière les collines.
  static void clouds(Canvas canvas, Size size, double scroll, double night) {
    const spacing = 340.0;
    final drift = scroll * 0.05;
    final alpha = (0.55 - night * 0.4).clamp(0.0, 1.0);
    if (alpha <= 0.02) return;

    final paint = Paint()..color = AppColors.cloud.withValues(alpha: alpha);
    final first = (drift / spacing).floor() - 1;

    for (var k = first; ; k++) {
      final anchor = k * spacing - drift;
      if (anchor > size.width + 200) break;

      final rnd = Random(k * 15485863);
      final x = anchor + (rnd.nextDouble() - 0.5) * spacing * 0.6;
      final y = size.height * (0.10 + rnd.nextDouble() * 0.24);
      final w = 46 + rnd.nextDouble() * 54;
      if (x < -140 || x > size.width + 140) continue;

      canvas.drawOval(
        Rect.fromCenter(center: Offset(x, y), width: w, height: w * 0.34),
        paint,
      );
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(x - w * 0.22, y + w * 0.05),
          width: w * 0.62,
          height: w * 0.26,
        ),
        paint,
      );
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(x + w * 0.26, y + w * 0.04),
          width: w * 0.52,
          height: w * 0.24,
        ),
        paint,
      );
    }
  }

  /// Étoiles fixes, révélées par l'obscurité.
  static void stars(Canvas canvas, Size size, double night, double time) {
    if (night <= 0.05) return;

    final rnd = Random(20260722);
    for (var i = 0; i < 70; i++) {
      final x = rnd.nextDouble() * size.width;
      final y = rnd.nextDouble() * size.height * 0.6;
      final r = 0.5 + rnd.nextDouble() * 1.1;
      // Scintillement lent et déphasé, pour que le ciel ne clignote pas
      // en bloc.
      final twinkle = 0.65 + 0.35 * sin(time * 0.8 + i * 1.7);
      canvas.drawCircle(
        Offset(x, y),
        r,
        Paint()
          ..color = AppColors.star.withValues(alpha: night * twinkle * 0.9),
      );
    }
  }
}
