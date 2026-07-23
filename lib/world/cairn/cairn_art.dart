import 'dart:math';

import 'package:flutter/material.dart';

import '../../design/tokens.dart';

/// L'empilement de pierres qui marque une session achevée.
///
/// Les décalages sont dérivés d'une graine, donc un cairn donné a toujours
/// exactement la même forme d'une session à l'autre.
abstract final class CairnArt {
  static void paint(
    Canvas canvas,
    Offset base,
    int stones, {
    int seed = 0,
    double scale = 1,
    Color color = AppColors.cairnStone,
  }) {
    final rnd = Random(seed);
    final paint = Paint()..color = color;

    canvas.save();
    canvas.translate(base.dx, base.dy);
    canvas.scale(scale);

    var y = 0.0;
    var width = 15.0;

    for (var i = 0; i < stones; i++) {
      final height = width * 0.46;
      final wobble = (rnd.nextDouble() - 0.5) * 2.4;
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(wobble, y - height / 2),
          width: width,
          height: height,
        ),
        paint,
      );
      y -= height * 0.88;
      width *= 0.82;
    }

    canvas.restore();
  }

}
