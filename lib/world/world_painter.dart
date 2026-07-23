import 'dart:math';

import 'package:flutter/material.dart';

import '../design/tokens.dart';
import '../domain/wardrobe.dart';
import 'cairn/cairn_art.dart';
import 'landscape/decor.dart';
import 'landscape/landscape_spec.dart';
import 'pip/pip_painter.dart';
import 'pip/pip_params.dart';
import 'pip/pip_speech.dart';
import 'sky.dart';
import 'world_clock.dart';

/// Dessine le monde entier : ciel, étoiles, astre, nuages, collines en
/// parallaxe avec leur décor, cairns, herbe, et Pip.
///
/// Un seul painter pour tout, afin que Pip soit garanti posé exactement sur la
/// courbe de la colline de premier plan.
class WorldPainter extends CustomPainter {
  WorldPainter({
    required this.clock,
    required this.sky,
    required this.hour,
    required this.params,
    required this.pose,
    this.spec = LandscapeSpec.standard,
    this.pipXFraction = 0.42,
    this.showCairns = true,
    this.showDecor = true,
    this.outfit = PipOutfit.base,
    this.bottomInset = 0,
    this.autoScalePip = true,
    this.speechSeed = 0,
  }) : super(repaint: clock);

  final WorldClock clock;
  final SkyPalette sky;
  final double hour;
  final PipParams params;
  final PipPose pose;
  final LandscapeSpec spec;
  final double pipXFraction;
  final bool showCairns;
  final bool showDecor;
  final PipOutfit outfit;

  /// Hauteur réservée en bas par l'interface. Le sol se cale au-dessus, sinon
  /// Pip marche derrière le panneau de commandes.
  final double bottomInset;

  /// Fait suivre la taille de Pip à celle de la fenêtre. Une échelle fixe le
  /// rend minuscule sur un écran de bureau.
  final bool autoScalePip;

  /// Fait varier la réplique de Pip d'un incident à l'autre.
  final int speechSeed;

  /// Espacement des cairns déjà posés, en pixels de monde.
  static const _cairnSpacing = 260.0;

  /// Hauteur de référence pour le relief : le sol remonte au-dessus de
  /// l'interface.
  Size _ground(Size size) =>
      Size(size.width, size.height - bottomInset);

  PipParams _scaledParams(Size size) {
    if (!autoScalePip) return params;
    final factor = (size.height / 620).clamp(0.85, 2.8);
    return params.copyWith(scale: params.scale * factor);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final scroll = clock.scroll;
    final night = SkyPalette.nightFactor(hour);

    _paintSky(canvas, size);
    if (showDecor) {
      Decor.stars(canvas, size, night, clock.time);
    }
    _paintCelestialBody(canvas, size, night);
    if (showDecor) Decor.clouds(canvas, size, scroll, night);

    final ground = _ground(size);

    for (var i = 0; i < spec.layers.length; i++) {
      final layer = spec.layers[i];
      final isFront = i == spec.layers.length - 1;

      // Le premier plan descend jusqu'au bas de l'écran : à plat, il forme une
      // dalle unie. Un léger dégradé lui rend sa profondeur.
      final fill = Paint();
      if (isFront) {
        final band = Rect.fromLTRB(
          0,
          layer.baseFraction * ground.height,
          size.width,
          size.height,
        );
        fill.shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            layer.color,
            Color.lerp(layer.color, Colors.black, 0.22)!,
          ],
        ).createShader(band);
      } else {
        fill.color = layer.color;
      }

      canvas.drawPath(layer.pathFor(ground, scroll, fillTo: size.height), fill);

      if (!showDecor) continue;
      final decor = spec.decorFor(i);
      final depth = i / (spec.layers.length - 1);
      Decor.trees(canvas, ground, layer, scroll, decor, i, depth);
      Decor.boulders(canvas, ground, layer, scroll, decor, i, depth);
    }

    if (showCairns) _paintCairns(canvas, ground, scroll);

    final pipX = size.width * pipXFraction;
    final groundY = spec.ground.yAt(pipX, scroll, ground.height);
    PipArt.paint(
      canvas,
      Offset(pipX, groundY + 2),
      _scaledParams(size),
      pose,
      clock.time,
      night: night,
      lanternLit: SkyPalette.lanternFactor(hour),
      outfit: outfit,
    );

    _speech(canvas, size, Offset(pipX, groundY));

    // L'herbe passe devant Pip : c'est ce qui l'ancre dans le paysage au lieu
    // de le laisser flotter dessus.
    if (showDecor) {
      Decor.grass(
        canvas,
        ground,
        spec.ground,
        scroll,
        spec.decorFor(spec.layers.length - 1),
        spec.layers.length,
      );
    }
  }

  /// La bulle de réplique, au-dessus de la tête.
  ///
  /// Dessinée **hors** du repère mis à l'échelle de Pip : le texte doit rester
  /// lisible quelle que soit la taille du personnage.
  void _speech(Canvas canvas, Size size, Offset feet) {
    final line = PipSpeech.lineFor(pose, speechSeed);
    if (line == null) return;

    final label = TextPainter(
      text: TextSpan(
        text: line,
        style: const TextStyle(
          fontSize: 13,
          height: 1.25,
          color: AppColors.ink,
          fontWeight: FontWeight.w500,
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    )..layout(maxWidth: min(220, size.width - 48));

    const padding = 10.0;
    const tail = 7.0;
    final pipHeight = 74 * _scaledParams(size).scale;

    var centre = Offset(feet.dx, feet.dy - pipHeight - 24);
    // La bulle ne doit jamais sortir du cadre.
    final half = label.width / 2 + padding;
    centre = Offset(
      centre.dx.clamp(half + 8, size.width - half - 8),
      max(centre.dy, label.height / 2 + padding + 12),
    );

    final box = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: centre,
        width: label.width + padding * 2,
        height: label.height + padding * 2,
      ),
      const Radius.circular(12),
    );

    final paint = Paint()..color = Colors.white.withValues(alpha: 0.94);
    canvas.drawRRect(box, paint);
    canvas.drawPath(
      Path()
        ..moveTo(feet.dx - tail, box.bottom - 1)
        ..lineTo(feet.dx, box.bottom + tail)
        ..lineTo(feet.dx + tail, box.bottom - 1)
        ..close(),
      paint,
    );

    label.paint(
      canvas,
      Offset(centre.dx - label.width / 2, centre.dy - label.height / 2),
    );
  }

  void _paintSky(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [sky.top, sky.mid, sky.bottom],
          stops: const [0, 0.55, 1],
        ).createShader(rect),
    );
  }

  void _paintCelestialBody(Canvas canvas, Size size, double night) {
    final isNight = SkyPalette.isNight(hour);
    // Le soleil parcourt le ciel de 6 h à 20 h ; la lune prend le relais.
    final t = isNight
        ? ((hour < 6 ? hour + 4 : hour - 20) / 10).clamp(0.0, 1.0)
        : ((hour - 6) / 14).clamp(0.0, 1.0);

    final centre = Offset(
      size.width * (0.14 + 0.72 * t),
      size.height * 0.34 - sin(t * pi) * size.height * 0.2,
    );
    final radius = isNight ? 15.0 : 21.0;

    // Halo diffus, plus marqué la nuit.
    canvas.drawCircle(
      centre,
      radius * 2.6,
      Paint()
        ..shader =
            RadialGradient(
              colors: [
                (isNight
                        ? const Color(0xFFE8E6F5)
                        : const Color(0xFFFFF4DE))
                    .withValues(alpha: 0.26),
                Colors.transparent,
              ],
            ).createShader(
              Rect.fromCircle(center: centre, radius: radius * 2.6),
            ),
    );

    canvas.drawCircle(
      centre,
      radius,
      Paint()
        ..color = isNight
            ? const Color(0xFFE8E6F5).withValues(alpha: 0.92)
            : const Color(0xFFFFF4DE).withValues(alpha: 0.88),
    );

    // Les cratères de la lune : trois ellipses suffisent à la distinguer du
    // soleil au premier coup d'œil.
    if (isNight) {
      final crater = Paint()
        ..color = const Color(0xFFCFCBE4).withValues(alpha: 0.75);
      canvas.drawOval(
        Rect.fromCenter(
          center: centre.translate(-4, -3),
          width: 6,
          height: 5,
        ),
        crater,
      );
      canvas.drawOval(
        Rect.fromCenter(center: centre.translate(4, 2), width: 5, height: 4),
        crater,
      );
      canvas.drawOval(
        Rect.fromCenter(center: centre.translate(-1, 6), width: 4, height: 3),
        crater,
      );
    }
  }

  void _paintCairns(Canvas canvas, Size size, double scroll) {
    final groundScroll = scroll * spec.ground.speed;
    final first = (groundScroll / _cairnSpacing).floor();

    for (var k = first; ; k++) {
      final x = k * _cairnSpacing - groundScroll;
      if (x > size.width + 40) break;
      if (x < -40) continue;
      CairnArt.paint(
        canvas,
        Offset(x, spec.ground.yAt(x, scroll, size.height) + 2),
        2 + (k.abs() % 4),
        seed: k,
        scale: 0.9,
      );
    }
  }

  @override
  bool shouldRepaint(WorldPainter old) =>
      old.pose != pose ||
      old.params != params ||
      old.spec != spec ||
      old.hour != hour ||
      old.showCairns != showCairns ||
      old.showDecor != showDecor ||
      old.outfit != outfit ||
      old.bottomInset != bottomInset ||
      old.autoScalePip != autoScalePip ||
      old.speechSeed != speechSeed ||
      old.pipXFraction != pipXFraction;
}
