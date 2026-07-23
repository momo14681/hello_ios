import 'package:flutter/material.dart';

import '../../domain/wardrobe.dart';

/// Les coiffes de Pip, dessinées en code comme le reste.
///
/// Elles se posent sur le haut du corps — Pip n'ayant pas de tête distincte,
/// une coiffe trop enfoncée mange le front et écrase le visage.
abstract final class PipHats {
  static const _wool = Color(0xFFD4685E);
  static const _woolDark = Color(0xFFB4534B);
  static const _straw = Color(0xFFE2C489);
  static const _strawDark = Color(0xFFC7A469);
  static const _khaki = Color(0xFFB9B183);
  static const _khakiDark = Color(0xFF938C63);
  static const _gold = Color(0xFFE8B84B);
  static const _goldDark = Color(0xFFC2952F);

  /// [crown] est le point haut du corps, dans le repère local de Pip.
  static void paint(Canvas canvas, Offset crown, PipHat hat) {
    if (hat == PipHat.none) return;

    canvas.save();
    canvas.translate(crown.dx, crown.dy);

    switch (hat) {
      case PipHat.none:
        break;

      case PipHat.beanie:
        canvas.drawPath(
          Path()
            ..moveTo(-17, 5)
            ..quadraticBezierTo(-15, -13, 0, -13)
            ..quadraticBezierTo(15, -13, 17, 5)
            ..close(),
          Paint()..color = _wool,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: const Offset(0, 4), width: 38, height: 8),
            const Radius.circular(4),
          ),
          Paint()..color = _woolDark,
        );
        canvas.drawCircle(
          const Offset(0, -15),
          4.5,
          Paint()..color = _woolDark,
        );

      case PipHat.straw:
        canvas.drawOval(
          Rect.fromCenter(center: const Offset(1, 3), width: 58, height: 13),
          Paint()..color = _straw,
        );
        canvas.drawPath(
          Path()
            ..moveTo(-15, 3)
            ..quadraticBezierTo(-13, -12, 1, -12)
            ..quadraticBezierTo(15, -12, 16, 3)
            ..close(),
          Paint()..color = _strawDark,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: const Offset(1, 0), width: 31, height: 5),
            const Radius.circular(2.5),
          ),
          Paint()..color = _wool,
        );

      case PipHat.explorer:
        // Une visière avancée : c'est elle qui dit « explorateur ».
        canvas.drawOval(
          Rect.fromCenter(center: const Offset(6, 4), width: 46, height: 11),
          Paint()..color = _khakiDark,
        );
        canvas.drawPath(
          Path()
            ..moveTo(-16, 4)
            ..quadraticBezierTo(-14, -13, 1, -13)
            ..quadraticBezierTo(16, -13, 17, 4)
            ..close(),
          Paint()..color = _khaki,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: const Offset(1, 1), width: 33, height: 5),
            const Radius.circular(2.5),
          ),
          Paint()..color = _khakiDark,
        );

      case PipHat.crown:
        canvas.drawPath(
          Path()
            ..moveTo(-15, 4)
            ..lineTo(-15, -6)
            ..lineTo(-9, -1)
            ..lineTo(-4, -11)
            ..lineTo(1, -1)
            ..lineTo(6, -11)
            ..lineTo(11, -1)
            ..lineTo(16, -7)
            ..lineTo(16, 4)
            ..close(),
          Paint()..color = _gold,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: const Offset(0.5, 3), width: 32, height: 5),
            const Radius.circular(2.5),
          ),
          Paint()..color = _goldDark,
        );
    }

    canvas.restore();
  }
}
