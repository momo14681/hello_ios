import 'package:flutter/material.dart';

import '../../design/tokens.dart';
import '../../domain/wardrobe.dart';

/// Ce que Pip tient dans la main avant.
///
/// **Le jour, une gourde ; la nuit, une lanterne.** Une lanterne éteinte
/// balancée en plein soleil n'a aucun sens — l'objet change avec l'heure au
/// lieu de rester là, inerte.
///
/// L'origine du repère est la main : tout pend en dessous.
abstract final class PipCarried {
  static const _flaskBody = Color(0xFF7FA8C4);
  static const _flaskDark = Color(0xFF5A7E99);
  static const _flaskCap = Color(0xFF4A3F6B);

  /// Au-delà de ce seuil, Pip porte la lanterne plutôt que la gourde.
  static const _swap = 0.5;

  /// [lit] va de 0 (plein jour) à 1 (lanterne à pleine intensité).
  static void paint(
    Canvas canvas, {
    required double lit,
    required LanternStyle style,
    required Color glass,
  }) {
    if (lit < _swap) {
      _flask(canvas);
      return;
    }
    _glow(canvas, lit, glass);
    _handle(canvas);

    switch (style) {
      case LanternStyle.classic:
        _classic(canvas, lit, glass);
      case LanternStyle.paper:
        _paper(canvas, lit, glass);
      case LanternStyle.fireflyJar:
        _fireflyJar(canvas, lit, glass);
      case LanternStyle.crystal:
        _crystal(canvas, lit, glass);
    }
  }

  /// La gourde de jour : même encombrement que la lanterne, silhouette de
  /// randonnée sans ambiguïté.
  static void _flask(Canvas canvas) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: const Offset(0, 1.5), width: 4, height: 4),
        const Radius.circular(1.2),
      ),
      Paint()..color = _flaskCap,
    );

    final body = Rect.fromCenter(
      center: const Offset(0, 8.5),
      width: 10.5,
      height: 13,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(body, const Radius.circular(4.5)),
      Paint()..color = _flaskBody,
    );

    // Une bande plus sombre : sans elle, la gourde se lit comme un galet.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: const Offset(0, 9), width: 10.5, height: 3.4),
        const Radius.circular(1.2),
      ),
      Paint()..color = _flaskDark,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: const Offset(-3, 6), width: 2, height: 5),
        const Radius.circular(1),
      ),
      Paint()..color = Colors.white.withValues(alpha: 0.35),
    );
  }

  static void _glow(Canvas canvas, double lit, Color glass) {
    final radius = 20 * lit;
    const centre = Offset(0, 6);
    canvas.drawCircle(
      centre,
      radius,
      Paint()
        ..shader =
            RadialGradient(
              colors: [
                glass.withValues(alpha: 0.5 * lit),
                glass.withValues(alpha: 0),
              ],
            ).createShader(Rect.fromCircle(center: centre, radius: radius)),
    );
  }

  static void _handle(Canvas canvas) {
    canvas.drawPath(
      Path()
        ..moveTo(-3.2, 1)
        ..quadraticBezierTo(0, -3.5, 3.2, 1),
      Paint()
        ..color = AppColors.lanternFrame
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..strokeCap = StrokeCap.round,
    );
  }

  static Paint _glassPaint(double lit, Color glass) => Paint()
    ..color = Color.lerp(glass.withValues(alpha: 0.45), glass, lit)!;

  static void _classic(Canvas canvas, double lit, Color glass) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: const Offset(0, 6), width: 9.5, height: 11),
        const Radius.circular(3),
      ),
      Paint()..color = AppColors.lanternFrame,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: const Offset(0, 6), width: 6, height: 7),
        const Radius.circular(1.8),
      ),
      _glassPaint(lit, glass),
    );
  }

  /// Un lampion : corps bombé, nervures horizontales, coiffes plates.
  static void _paper(Canvas canvas, double lit, Color glass) {
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(0, 6.5), width: 12, height: 13),
      _glassPaint(lit, glass),
    );

    final rib = Paint()
      ..color = AppColors.lanternFrame.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.9;
    for (final dy in const [3.0, 6.5, 10.0]) {
      final halfWidth = dy == 6.5 ? 5.8 : 4.6;
      canvas.drawLine(
        Offset(-halfWidth, dy),
        Offset(halfWidth, dy),
        rib,
      );
    }

    final cap = Paint()..color = AppColors.lanternFrame;
    for (final dy in const [1.0, 12.0]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(0, dy), width: 6, height: 2.4),
          const Radius.circular(1),
        ),
        cap,
      );
    }
  }

  /// Un bocal à lucioles : col étranglé, couvercle, points lumineux.
  static void _fireflyJar(Canvas canvas, double lit, Color glass) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: const Offset(0, 7.5), width: 10, height: 11),
        const Radius.circular(3.5),
      ),
      _glassPaint(lit * 0.7, glass),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: const Offset(0, 2.2), width: 6.5, height: 3),
        const Radius.circular(1),
      ),
      Paint()..color = AppColors.lanternFrame,
    );

    // Les lucioles : trois points vifs, placés en dur pour rester stables.
    final firefly = Paint()..color = Colors.white.withValues(alpha: 0.9 * lit);
    for (final p in const [Offset(-2.4, 5.5), Offset(2, 8), Offset(-1, 10)]) {
      canvas.drawCircle(p, 1.1, firefly);
    }
  }

  /// Un éclat de cristal facetté, suspendu à un anneau.
  static void _crystal(Canvas canvas, double lit, Color glass) {
    canvas.drawPath(
      Path()
        ..moveTo(0, 0.5)
        ..lineTo(4.6, 5)
        ..lineTo(3, 12.5)
        ..lineTo(-3, 12.5)
        ..lineTo(-4.6, 5)
        ..close(),
      _glassPaint(lit, glass),
    );

    final facet = Paint()
      ..color = Colors.white.withValues(alpha: 0.4 * lit)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.9;
    canvas.drawLine(const Offset(0, 0.5), const Offset(0, 12.5), facet);
    canvas.drawLine(const Offset(-4.6, 5), const Offset(4.6, 5), facet);
  }
}
