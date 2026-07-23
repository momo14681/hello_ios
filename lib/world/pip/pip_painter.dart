import 'dart:math';

import 'package:flutter/material.dart';

import '../../design/tokens.dart';
import '../../domain/wardrobe.dart';
import 'pip_carried.dart';
import 'pip_hats.dart';
import 'pip_params.dart';

double _lerp(double a, double b, double t) => a + (b - a) * t;

/// Le dessin de Pip, entièrement procédural.
///
/// Aucune image, aucun fichier d'animation : des capsules, des ellipses, un
/// dégradé et de la trigonométrie. Voir CONCEPT.md §3.
///
/// **Proportions kawaii.** L'attachement tient à la néoténie — des proportions
/// de bébé : yeux **gros** et placés **au-dessous** du centre du corps, membres
/// **courts et épais**, joues rosées, petite bouche, sourcils très discrets.
///
/// **Découpage du corps.** Pip n'a pas de cou : sans zones franches, le visage
/// et l'équipement se marchent dessus. Le visage occupe tout le centre, la
/// marque minérale est une strie d'angle, et la lanterne pend **hors** de la
/// silhouette.
///
/// **Pas d'écharpe.** Une écharpe s'enroule autour d'un cou. Sur un corps rond
/// et sans cou, deux pans flottants ne se lisent jamais comme du tissu porté :
/// ils lisent comme un bras, une queue, ou rien. Le fanion planté sur le sac
/// règle le problème à la racine — il n'a besoin d'aucune anatomie, il ondule
/// donc conserve le mouvement secondaire, et il grandit la silhouette.
///
/// Pip regarde vers les x positifs.
abstract final class PipArt {
  // Membres courts et épais : c'est une proportion, pas un détail.
  static const _legW = 8.0;
  static const _legH = 13.0;
  static const _armW = 6.5;
  static const _armH = 11.5;

  static const _bodyW = 44.0;
  static const _bodyH = 38.0;
  static const _bodyBottom = -8.0;
  static const _bodyCenterY = _bodyBottom - _bodyH / 2;

  /// Les yeux vivent **sous** le centre du corps. C'est le levier kawaii le
  /// plus puissant, et le plus contre-intuitif.
  static const _eyeOffsetY = 1.0;

  /// Décalage du visage vers l'avant : suggère la direction du regard.
  static const _gaze = 2.5;

  /// Facteur d'ouverture des yeux : 1 ouvert, ~0 fermé.
  static double blinkFactor(double time, double period) {
    if (period <= 0) return 1;
    const closeDuration = 0.12;
    final phase = time % period;
    if (phase > period - closeDuration) {
      final k = (phase - (period - closeDuration)) / closeDuration;
      return (1 - sin(k * pi)).clamp(0.08, 1.0);
    }
    return 1;
  }

  /// Dessine Pip, pieds posés en [feet], dans le repère courant du canevas.
  ///
  /// [night] va de 0 (plein jour) à 1 (nuit noire) et pilote la lanterne.
  static void paint(
    Canvas canvas,
    Offset feet,
    PipParams p,
    PipPose pose,
    double time, {
    double night = 0,
    double lanternLit = 0,
    PipOutfit outfit = PipOutfit.base,
  }) {
    final traits = PipPoseTraits.of(pose);
    final phase = time * p.walkSpeed * traits.rateScale * 2 * pi;

    final bobUp = sin(phase * 2) * p.bobAmplitude * traits.bobScale;
    final squashK =
        1 +
        sin(phase * 2) * p.squash * traits.squashScale -
        traits.stretch * 0.16;
    final bodyY = _bodyCenterY - bobUp + traits.sit * 9;
    final shakeX = traits.shake == 0 ? 0.0 : sin(time * 46) * traits.shake;

    canvas.save();
    canvas.translate(feet.dx + shakeX, feet.dy);
    canvas.scale(p.scale);

    _shadow(canvas, bobUp, traits.sit);
    _arm(canvas, p, traits, phase, bodyY, outfit, back: true);
    if (p.showPennant) _pennant(canvas, p, bodyY, phase, outfit);
    if (p.showBackpack) _backpack(canvas, bodyY, outfit);
    _legs(canvas, p, traits, phase, bodyY, outfit);

    canvas.save();
    canvas.translate(0, bodyY);
    canvas.rotate(traits.lean);
    canvas.translate(0, -bodyY);

    _body(canvas, p, bodyY, squashK, outfit);
    if (p.showBackpack) _shoulderStrap(canvas, bodyY, outfit);
    _face(canvas, p, traits, bodyY, time);
    PipHats.paint(canvas, Offset(0, bodyY - _bodyH / 2 + 2), outfit.hat);

    canvas.restore();

    _arm(canvas, p, traits, phase, bodyY, outfit, back: false);
    if (p.showLantern) {
      _carried(canvas, p, traits, phase, bodyY, lanternLit, outfit);
    }
    _effect(canvas, traits, bodyY, time);

    canvas.restore();
  }

  static void _shadow(Canvas canvas, double bobUp, double sit) {
    canvas.drawOval(
      Rect.fromCenter(
        center: const Offset(2, 1),
        width: (33 - bobUp * 0.7) + sit * 6,
        height: 8.6,
      ),
      Paint()..color = AppColors.shadow,
    );
  }

  static void _legs(
    Canvas canvas,
    PipParams p,
    PipPoseTraits traits,
    double phase,
    double bodyY,
    PipOutfit outfit,
  ) {
    final paint = Paint()..color = outfit.detail;
    // La hanche est haute et les jambes longues : seules les extrémités
    // dépassent du corps, ce qui donne les petits pieds ronds voulus.
    final hipY = bodyY + _bodyH / 2 - 6;
    final sitAngle = -traits.sit * pi / 2 * 0.85;

    for (final side in const [-1.0, 1.0]) {
      final swing =
          traits.swingScale *
          p.legSwing *
          sin(phase + (side > 0 ? pi : 0)) *
          0.55;

      canvas.save();
      canvas.translate(side * 6.5 + swing, hipY);
      canvas.rotate(sitAngle);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(-_legW / 2, 0, _legW, _legH),
          const Radius.circular(_legW / 2),
        ),
        paint,
      );
      canvas.restore();
    }
  }

  /// Un bras. Ils balancent en opposition aux jambes — c'est ce qui donne à la
  /// marche sa lisibilité.
  static void _arm(
    Canvas canvas,
    PipParams p,
    PipPoseTraits traits,
    double phase,
    double bodyY,
    PipOutfit outfit, {
    required bool back,
  }) {
    final origin = _shoulder(bodyY, back: back);

    canvas.save();
    canvas.translate(origin.dx, origin.dy);
    canvas.rotate(_armAngle(p, traits, phase, back: back));
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(-_armW / 2, 0, _armW, _armH),
        const Radius.circular(_armW / 2),
      ),
      Paint()
        ..color = back
            ? Color.lerp(outfit.detail, Colors.black, 0.24)!
            : outfit.detail,
    );
    canvas.restore();
  }

  /// L'épaule arrière est posée bas et en dehors, sinon le sac à dos la
  /// recouvre entièrement et Pip semble n'avoir qu'un bras.
  static Offset _shoulder(double bodyY, {required bool back}) =>
      back ? Offset(-20, bodyY + 7) : Offset(19.5, bodyY + 6);

  static double _armAngle(
    PipParams p,
    PipPoseTraits traits,
    double phase, {
    required bool back,
  }) {
    final resting =
        traits.swingScale * p.armSwing * sin(phase + (back ? pi : 0)) * 0.055 +
        traits.sit * 0.5 +
        (back ? 0.58 : -0.42);
    return _lerp(resting, back ? 2.6 : -2.6, traits.armsUp);
  }

  /// Le fanion, planté sur le sac. Il remplace l'écharpe : aucune anatomie
  /// requise, et il ondule donc conserve le mouvement secondaire.
  static void _pennant(
    Canvas canvas,
    PipParams p,
    double bodyY,
    double phase,
    PipOutfit outfit,
  ) {
    const poleX = -24.0;
    const topY = -32.0;
    final wave = p.pennantWave;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(poleX - 0.9, bodyY + topY, 1.8, 24),
        const Radius.circular(1),
      ),
      Paint()..color = Color.lerp(outfit.strap, Colors.black, 0.25)!,
    );

    final tipX = poleX - 15 + sin(phase * 1.1) * wave * 0.35;
    final tipY = bodyY + topY + 4 + sin(phase * 1.1 + 0.9) * wave * 0.9;

    canvas.drawPath(
      Path()
        ..moveTo(poleX, bodyY + topY)
        ..quadraticBezierTo(
          poleX - 8,
          bodyY + topY - 1 + sin(phase * 1.1) * wave * 0.55,
          tipX,
          tipY,
        )
        ..quadraticBezierTo(
          poleX - 8,
          bodyY + topY + 8 + sin(phase * 1.1 + 0.5) * wave * 0.55,
          poleX,
          bodyY + topY + 10,
        )
        ..close(),
      Paint()..color = outfit.pennant,
    );
  }

  static void _backpack(Canvas canvas, double bodyY, PipOutfit outfit) {
    final paint = Paint()..color = outfit.strap;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(-24, bodyY - 2), width: 15, height: 21),
        const Radius.circular(6),
      ),
      paint,
    );
    // Le rabat : c'est lui qui casse la lecture « rectangle qui dépasse ».
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(-24, bodyY - 9), width: 17, height: 8.5),
        const Radius.circular(4),
      ),
      Paint()..color = Color.lerp(outfit.strap, Colors.white, 0.2)!,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(-24, bodyY - 4), width: 5, height: 4.2),
        const Radius.circular(1.4),
      ),
      Paint()..color = outfit.lantern,
    );
  }

  /// Une seule bretelle, qui épouse le bord gauche du corps et s'arrête sous
  /// le visage. Deux bretelles au centre traversaient la figure : c'est ce qui
  /// donnait l'impression que Pip pleurait.
  static void _shoulderStrap(Canvas canvas, double bodyY, PipOutfit outfit) {
    canvas.drawPath(
      Path()
        ..moveTo(-19, bodyY - 1)
        ..quadraticBezierTo(-20, bodyY + 5, -16, bodyY + 11),
      Paint()
        ..color = outfit.strap
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.2
        ..strokeCap = StrokeCap.round,
    );
  }

  static void _body(
    Canvas canvas,
    PipParams p,
    double bodyY,
    double squashK,
    PipOutfit outfit,
  ) {
    final rect = Rect.fromCenter(
      center: Offset(0, bodyY),
      width: _bodyW * squashK,
      height: _bodyH / squashK,
    );
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(19));

    canvas.drawRRect(
      rrect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [outfit.bodyTop, outfit.bodyBottom],
        ).createShader(rect),
    );

    _vein(canvas, p, bodyY, rrect);
  }

  /// Deux courtes stries en haut à gauche, décentrées et loin du visage.
  ///
  /// Toute bande traversant le corps se lit comme un bavoir clair sous le
  /// menton : avec un visage qui occupe tout le centre, la marque doit rester
  /// une texture d'angle, jamais un motif.
  static void _vein(Canvas canvas, PipParams p, double bodyY, RRect body) {
    if (p.veinOpacity <= 0) return;

    canvas.save();
    canvas.clipRRect(body);

    final paint = Paint()
      ..color = AppColors.pipVein.withValues(alpha: p.veinOpacity)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(
      Path()
        ..moveTo(-21, bodyY - 4)
        ..quadraticBezierTo(-18, bodyY - 12, -9, bodyY - 16),
      paint..strokeWidth = 3.4,
    );
    canvas.drawPath(
      Path()
        ..moveTo(-16, bodyY - 1)
        ..quadraticBezierTo(-14, bodyY - 7, -8, bodyY - 10),
      paint..strokeWidth = 1.8,
    );

    canvas.restore();
  }

  static void _face(
    Canvas canvas,
    PipParams p,
    PipPoseTraits traits,
    double bodyY,
    double time,
  ) {
    final open = blinkFactor(time, p.blinkPeriod) * traits.eyeOpen;
    final eyeY = bodyY + _eyeOffsetY;

    _blush(canvas, p, eyeY);

    for (final side in const [-1.0, 1.0]) {
      final cx = side * p.eyeSpacing + _gaze;
      _eye(canvas, p, traits, cx, eyeY, open, side);
      _brow(canvas, p, traits, cx, eyeY, side);
    }

    _mouth(canvas, p, traits, eyeY);
  }

  static void _blush(Canvas canvas, PipParams p, double eyeY) {
    if (p.blushOpacity <= 0) return;
    final paint = Paint()
      ..color = AppColors.pipBlush.withValues(alpha: p.blushOpacity);

    for (final side in const [-1.0, 1.0]) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(
            side * (p.eyeSpacing + p.eyeRadius * 1.3) + _gaze,
            eyeY + p.eyeRadius * 0.8,
          ),
          width: p.eyeRadius * 1.95,
          height: p.eyeRadius * 1.15,
        ),
        paint,
      );
    }
  }

  /// Un œil. Sa forme est le principal porteur d'émotion — bien avant la
  /// bouche ou les sourcils.
  static void _eye(
    Canvas canvas,
    PipParams p,
    PipPoseTraits traits,
    double cx,
    double eyeY,
    double open,
    double side,
  ) {
    final r = p.eyeRadius;
    final line = Paint()
      ..color = AppColors.pipEye
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    switch (traits.eyeStyle) {
      case EyeStyle.happy:
        // Les arcs « ^^ » : la joie kawaii par excellence.
        canvas.drawPath(
          Path()
            ..moveTo(cx - r * 0.9, eyeY + r * 0.45)
            ..quadraticBezierTo(cx, eyeY - r * 0.85, cx + r * 0.9, eyeY + r * 0.45),
          line,
        );
        return;

      case EyeStyle.squeezed:
        // « >< » : les yeux serrés de la douleur.
        final innerX = cx - side * r * 0.85;
        final outerX = cx + side * r * 0.85;
        canvas.drawPath(
          Path()
            ..moveTo(outerX, eyeY - r * 0.8)
            ..lineTo(innerX, eyeY)
            ..lineTo(outerX, eyeY + r * 0.8),
          line,
        );
        return;

      case EyeStyle.swirl:
        // La spirale de l'étourdissement.
        final path = Path();
        for (var i = 0; i <= 34; i++) {
          final t = i / 34;
          final a = t * 2.6 * 2 * pi;
          final rad = t * r * 1.05;
          final pt = Offset(cx + cos(a) * rad, eyeY + sin(a) * rad);
          i == 0 ? path.moveTo(pt.dx, pt.dy) : path.lineTo(pt.dx, pt.dy);
        }
        canvas.drawPath(path, line..strokeWidth = 1.5);
        return;

      case EyeStyle.normal:
      case EyeStyle.wide:
      case EyeStyle.droopy:
        break;
    }

    final grow = traits.eyeStyle == EyeStyle.wide ? 1.24 : 1.0;

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx, eyeY),
        width: r * 2 * grow,
        height: r * 2.5 * grow * open,
      ),
      Paint()..color = AppColors.pipEye,
    );

    if (traits.eyeStyle == EyeStyle.droopy) {
      // La paupière tombante : un arc au-dessus de l'œil, incliné vers
      // l'extérieur.
      canvas.drawPath(
        Path()
          ..moveTo(cx - r, eyeY - r * 0.5 - side * 0.8)
          ..quadraticBezierTo(cx, eyeY - r * 1.15, cx + r, eyeY - r * 0.5 + side * 0.8),
        Paint()
          ..color = AppColors.pipEye.withValues(alpha: 0.6)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6
          ..strokeCap = StrokeCap.round,
      );
    }

    if (open <= 0.45) return;

    // Deux reflets : c'est cette paire qui transforme un point noir en regard.
    canvas.drawCircle(
      Offset(cx - r * 0.3, eyeY - r * 0.55),
      r * 0.4 * grow,
      Paint()..color = AppColors.pipHighlight.withValues(alpha: 0.95),
    );
    canvas.drawCircle(
      Offset(cx + r * 0.42, eyeY + r * 0.5),
      r * 0.19 * grow,
      Paint()..color = AppColors.pipHighlight.withValues(alpha: 0.7),
    );
  }

  /// Sourcils volontairement fins, courts et haut placés : ils portent
  /// l'expression sans casser la douceur. L'inclinaison est **miroir** de part
  /// et d'autre — appliquée à l'identique, elle donnait un air de travers.
  static void _brow(
    Canvas canvas,
    PipParams p,
    PipPoseTraits traits,
    double cx,
    double eyeY,
    double side,
  ) {
    if (p.browLift <= 0) return;

    final browY = eyeY - p.eyeRadius * 2.15 - traits.brow * p.browLift * 1.6;
    final innerX = cx - side * p.eyeRadius * 0.85;
    final outerX = cx + side * p.eyeRadius * 0.85;

    canvas.drawPath(
      Path()
        ..moveTo(innerX, browY + traits.brow * 0.9)
        ..quadraticBezierTo(cx, browY - 1.5, outerX, browY - traits.brow * 0.2),
      Paint()
        ..color = AppColors.pipEye.withValues(alpha: 0.55)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..strokeCap = StrokeCap.round,
    );
  }

  /// Une petite bouche, sous les yeux. Jamais large : une grande bouche fait
  /// basculer du mignon vers le comique.
  static void _mouth(
    Canvas canvas,
    PipParams p,
    PipPoseTraits traits,
    double eyeY,
  ) {
    final my = eyeY + p.eyeRadius * 1.8;
    final half = p.eyeRadius * 0.44;
    final stroke = Paint()
      ..color = AppColors.pipMouth
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    switch (traits.mouth) {
      case MouthStyle.open:
        final depth = p.eyeRadius * 0.85 * traits.mouthOpen;
        canvas.drawPath(
          Path()
            ..moveTo(_gaze - half, my)
            ..quadraticBezierTo(_gaze, my + depth, _gaze + half, my)
            ..close(),
          Paint()..color = AppColors.pipMouth,
        );

      case MouthStyle.round:
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(_gaze, my + 1),
            width: half * 1.5,
            height: half * 2,
          ),
          Paint()..color = AppColors.pipMouth,
        );

      case MouthStyle.flat:
        canvas.drawLine(
          Offset(_gaze - half, my),
          Offset(_gaze + half, my),
          stroke,
        );

      case MouthStyle.grimace:
        // La ligne en zigzag : la grimace universelle.
        final path = Path()..moveTo(_gaze - half * 1.3, my);
        for (var i = 1; i <= 4; i++) {
          final t = i / 4;
          path.lineTo(
            _gaze - half * 1.3 + half * 2.6 * t,
            my + (i.isOdd ? 1.9 : -1.9),
          );
        }
        canvas.drawPath(path, stroke);

      case MouthStyle.closedSmile:
        canvas.drawPath(
          Path()
            ..moveTo(_gaze - half * 0.9, my - 0.6)
            ..quadraticBezierTo(_gaze, my + 1.9, _gaze + half * 0.9, my - 0.6),
          stroke,
        );
    }
  }

  /// Les effets transitoires : goutte de sueur, étoiles d'étourdissement,
  /// éclats d'impact. Dessinés en dernier, donc toujours au-dessus.
  static void _effect(
    Canvas canvas,
    PipPoseTraits traits,
    double bodyY,
    double time,
  ) {
    switch (traits.effect) {
      case PipEffect.none:
        return;

      case PipEffect.sweat:
        final slide = (time % 1.8) / 1.8;
        final y = bodyY - 15 + slide * 8;
        final paint = Paint()
          ..color = AppColors.pipSweat.withValues(
            alpha: (1 - slide * 0.7).clamp(0.0, 1.0),
          );
        canvas.drawPath(
          Path()
            ..moveTo(17, y - 4)
            ..quadraticBezierTo(21, y, 17, y + 3)
            ..quadraticBezierTo(13, y, 17, y - 4)
            ..close(),
          paint,
        );

      case PipEffect.dizzy:
        for (var i = 0; i < 3; i++) {
          final a = time * 2.4 + i * 2 * pi / 3;
          _sparkle(
            canvas,
            Offset(2 + cos(a) * 14, bodyY - 26 + sin(a) * 4.5),
            3.4,
            AppColors.star,
          );
        }

      case PipEffect.impact:
        final pulse = 0.6 + 0.4 * sin(time * 14);
        final paint = Paint()
          ..color = AppColors.pipImpact.withValues(alpha: pulse)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.round;
        for (var i = 0; i < 4; i++) {
          final a = -0.9 + i * 0.6;
          final from = Offset(24 + cos(a) * 3, bodyY - 4 + sin(a) * 3);
          final to = Offset(24 + cos(a) * 9, bodyY - 4 + sin(a) * 9);
          canvas.drawLine(from, to, paint);
        }
    }
  }

  /// Une étincelle à quatre branches, dessinée en losange concave.
  static void _sparkle(Canvas canvas, Offset c, double r, Color color) {
    final path = Path()..moveTo(c.dx, c.dy - r);
    path.quadraticBezierTo(c.dx + r * 0.22, c.dy - r * 0.22, c.dx + r, c.dy);
    path.quadraticBezierTo(c.dx + r * 0.22, c.dy + r * 0.22, c.dx, c.dy + r);
    path.quadraticBezierTo(c.dx - r * 0.22, c.dy + r * 0.22, c.dx - r, c.dy);
    path.quadraticBezierTo(c.dx - r * 0.22, c.dy - r * 0.22, c.dx, c.dy - r);
    canvas.drawPath(path, Paint()..color = color);
  }

  /// L'objet porté par la main avant, **hors** de la silhouette : posé sur le
  /// corps, il se lit comme une excroissance.
  ///
  /// Gourde le jour, lanterne la nuit — voir [PipCarried].
  static void _carried(
    Canvas canvas,
    PipParams p,
    PipPoseTraits traits,
    double phase,
    double bodyY,
    double lit,
    PipOutfit outfit,
  ) {
    final origin = _shoulder(bodyY, back: false);

    canvas.save();
    canvas.translate(origin.dx, origin.dy);
    canvas.rotate(_armAngle(p, traits, phase, back: false));
    canvas.translate(0, _armH + 1);

    PipCarried.paint(
      canvas,
      lit: lit,
      style: outfit.lanternStyle,
      glass: outfit.lantern,
    );

    canvas.restore();
  }
}

/// Enveloppe [PipArt] pour un usage autonome, hors du monde complet.
class PipPainter extends CustomPainter {
  const PipPainter({
    required this.time,
    required this.pose,
    required this.params,
    this.night = 0,
    this.lanternLit = 0,
    this.outfit = PipOutfit.base,
  });

  final double time;
  final PipPose pose;
  final PipParams params;
  final double night;
  final double lanternLit;
  final PipOutfit outfit;

  @override
  void paint(Canvas canvas, Size size) {
    PipArt.paint(
      canvas,
      Offset(size.width / 2, size.height - 12),
      params,
      pose,
      time,
      night: night,
      lanternLit: lanternLit,
      outfit: outfit,
    );
  }

  @override
  bool shouldRepaint(PipPainter old) =>
      old.time != time ||
      old.pose != pose ||
      old.params != params ||
      old.night != night ||
      old.lanternLit != lanternLit ||
      old.outfit != outfit;
}
