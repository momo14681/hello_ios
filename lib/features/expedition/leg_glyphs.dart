import 'dart:math';

import 'package:flutter/material.dart';

import '../../domain/expedition.dart';

/// Les pictogrammes d'étape, dessinés dans un cercle de 13 px de rayon.
///
/// Un point ne dit rien. Un gué, une crête, un col et un sommet doivent se
/// distinguer d'un coup d'œil : c'est ce qui transforme une ligne jalonnée en
/// carte.
abstract final class LegGlyphs {
  static void paint(Canvas canvas, Offset centre, LegKind kind, Color color) {
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final fill = Paint()..color = color;

    canvas.save();
    canvas.translate(centre.dx, centre.dy);

    switch (kind) {
      case LegKind.water:
        for (var i = 0; i < 3; i++) {
          final y = -3.5 + i * 3.5;
          canvas.drawPath(
            Path()
              ..moveTo(-5.5, y)
              ..quadraticBezierTo(-2.75, y - 2, 0, y)
              ..quadraticBezierTo(2.75, y + 2, 5.5, y),
            stroke,
          );
        }

      case LegKind.forest:
        for (final dx in const [-3.6, 3.6]) {
          canvas.drawPath(
            Path()
              ..moveTo(dx, -5.5)
              ..lineTo(dx + 3, 3)
              ..lineTo(dx - 3, 3)
              ..close(),
            fill,
          );
        }
        canvas.drawLine(const Offset(0, -1), const Offset(0, 5), stroke);

      case LegKind.ridge:
        canvas.drawPath(
          Path()
            ..moveTo(-6.5, 4)
            ..lineTo(-2.5, -3)
            ..lineTo(0.5, 1.5)
            ..lineTo(3.5, -4.5)
            ..lineTo(6.5, 4),
          stroke,
        );

      case LegKind.pass:
        // Deux sommets et l'échancrure entre eux : c'est le creux qui fait
        // lire « col » plutôt que « montagne ».
        canvas.drawPath(
          Path()
            ..moveTo(-7, 4.5)
            ..lineTo(-3, -4)
            ..lineTo(-0.5, 0.5),
          stroke,
        );
        canvas.drawPath(
          Path()
            ..moveTo(0.5, 0.5)
            ..lineTo(3, -4)
            ..lineTo(7, 4.5),
          stroke,
        );

      case LegKind.ice:
        for (var i = 0; i < 3; i++) {
          final a = i * pi / 3;
          canvas.drawLine(
            Offset(cos(a) * -5.5, sin(a) * -5.5),
            Offset(cos(a) * 5.5, sin(a) * 5.5),
            stroke,
          );
        }

      case LegKind.summit:
        canvas.drawPath(
          Path()
            ..moveTo(-6.5, 4.5)
            ..lineTo(0, -5.5)
            ..lineTo(6.5, 4.5)
            ..close(),
          fill,
        );
        canvas.drawLine(const Offset(0, -5.5), const Offset(0, -9), stroke);
        canvas.drawPath(
          Path()
            ..moveTo(0, -9)
            ..lineTo(4.5, -7.6)
            ..lineTo(0, -6.2)
            ..close(),
          fill,
        );

      case LegKind.ruins:
        canvas.drawRect(const Rect.fromLTWH(-6, -4, 3.4, 9), fill);
        canvas.drawRect(const Rect.fromLTWH(-1, -1.5, 3.4, 6.5), fill);
        canvas.drawRect(const Rect.fromLTWH(4, -6, 3.4, 11), fill);

      case LegKind.dunes:
        canvas.drawPath(
          Path()
            ..moveTo(-7, 3.5)
            ..quadraticBezierTo(-3.5, -4.5, 0.5, 3.5)
            ..quadraticBezierTo(4, -2, 7, 3.5),
          stroke,
        );
    }

    canvas.restore();
  }
}
