import 'dart:math';

import 'package:flutter/material.dart';

import '../../design/tokens.dart';
import '../../domain/expedition.dart';
import '../../domain/wardrobe.dart';
import '../../world/cairn/cairn_art.dart';
import '../../world/pip/pip_painter.dart';
import '../../world/pip/pip_params.dart';
import 'leg_glyphs.dart';
import 'terrain.dart';

/// La carte de l'expédition : un sentier sinueux qui monte du bas vers le
/// sommet, sur un fond topographique peuplé de relief.
///
/// C'est l'équivalent de la grille GitHub de HabitKit — un historique qui
/// s'accumule et qu'on a envie de regarder. Voir CONCEPT.md §4.
///
/// Tout est procédural et **déterministe** : le relief est tiré de
/// l'identifiant de l'expédition, donc une carte donnée a toujours la même
/// tête d'une ouverture à l'autre.
class TrailPainter extends CustomPainter {
  TrailPainter({
    required this.view,
    required this.time,
    this.outfit = PipOutfit.base,
  });

  final ExpeditionView view;
  final double time;
  final PipOutfit outfit;

  static const _marginTop = 64.0;
  static const _marginBottom = 96.0;
  static const _frequency = 0.017;

  /// Un repère de distance tous les 5 km.
  static const _tickMeters = 5000.0;

  static const _paper = Color(0xFFF3EDE1);
  static const _paperTop = Color(0xFFE7EDF4);
  static const _contour = Color(0xFF6B7C93);

  /// L'amplitude suit la largeur : sur un écran étroit le sentier reste
  /// lisible, sur un large il occupe l'espace au lieu de rester un filet.
  static double _amplitude(Size size) => size.width * 0.155;

  /// Position sur le sentier, [t] allant de 0 (départ, en bas) à 1 (sommet).
  Offset pointAt(Size size, double t) {
    final span = size.height - _marginTop - _marginBottom;
    final y = size.height - _marginBottom - t.clamp(0.0, 1.0) * span;
    return Offset(size.width / 2 + sin(y * _frequency) * _amplitude(size), y);
  }

  Path _segment(Size size, double from, double to) {
    final path = Path();
    const steps = 110;
    for (var i = 0; i <= steps; i++) {
      final t = from + (to - from) * (i / steps);
      final p = pointAt(size, t);
      i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    return path;
  }

  @override
  void paint(Canvas canvas, Size size) {
    _paperBackground(canvas, size);
    _contours(canvas, size);
    _relief(canvas, size);

    // Le sentier restant : pointillé pâle.
    canvas.drawPath(
      _dash(_segment(size, 0, 1)),
      Paint()
        ..color = AppColors.ink.withValues(alpha: 0.26)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round,
    );

    // Le sentier parcouru : trait plein et chaud, souligné d'une ombre claire
    // pour qu'il se détache du relief.
    if (view.fraction > 0) {
      final travelled = _segment(size, 0, view.fraction);
      canvas.drawPath(
        travelled,
        Paint()
          ..color = _paper.withValues(alpha: 0.85)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 7.5
          ..strokeCap = StrokeCap.round,
      );
      canvas.drawPath(
        travelled,
        Paint()
          ..color = AppColors.pipPennant
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4
          ..strokeCap = StrokeCap.round,
      );
    }

    _ticks(canvas, size);

    // Petits, volontairement : après quelques semaines il y en a des dizaines.
    // À taille normale, ils forment une chaîne de blocs au lieu d'un semis.
    for (final cairn in view.cairns) {
      CairnArt.paint(
        canvas,
        pointAt(size, view.fractionOf(cairn.atMeters)),
        cairn.stones,
        seed: cairn.placedAt.millisecondsSinceEpoch,
        scale: 0.32,
      );
    }

    for (final leg in view.expedition.legs) {
      _leg(canvas, size, leg);
    }

    PipArt.paint(
      canvas,
      pointAt(size, view.fraction),
      const PipParams(scale: 0.62, showPennant: false),
      PipPose.idle,
      time,
      outfit: outfit,
    );
  }

  void _paperBackground(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_paperTop, _paper],
        ).createShader(rect),
    );
  }

  /// Courbes de niveau : trois massifs concentriques. C'est ce qui fait lire
  /// « carte topographique » avant même qu'on ait regardé le détail.
  void _contours(Canvas canvas, Size size) {
    final rnd = Random(view.expedition.id.hashCode ^ 0x5f3a71);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.9
      ..color = _contour.withValues(alpha: 0.16);

    for (var massif = 0; massif < 3; massif++) {
      final cx = 30 + rnd.nextDouble() * (size.width - 60);
      final cy = 60 + rnd.nextDouble() * (size.height - 140);
      final wobble = [
        rnd.nextDouble() * 2 * pi,
        rnd.nextDouble() * 2 * pi,
      ];
      final rings = 4 + rnd.nextInt(4);

      for (var ring = 1; ring <= rings; ring++) {
        final base = ring * (16 + rnd.nextDouble() * 8);
        final path = Path();
        for (var i = 0; i <= 72; i++) {
          final a = i / 72 * 2 * pi;
          final r =
              base *
              (1 +
                  0.15 * sin(a * 3 + wobble[0]) +
                  0.09 * sin(a * 5 + wobble[1]));
          final p = Offset(cx + cos(a) * r, cy + sin(a) * r * 0.7);
          i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
        }
        canvas.drawPath(path..close(), paint);
      }
    }
  }

  /// Le biome d'un point du sentier : celui de l'étape vers laquelle on marche.
  ///
  /// On approche donc du gué par des étangs, du lac gelé par des glaces, du
  /// sommet par des cimes — le terrain annonce ce qui vient.
  LegKind _biomeAt(double t) {
    final legs = view.expedition.legs;
    if (legs.isEmpty) return LegKind.forest;
    for (final leg in legs) {
      if (t <= view.fractionOf(leg.atMeters)) return leg.kind;
    }
    return legs.last.kind;
  }

  /// Relief semé de part et d'autre du sentier, plus un repère marquant à
  /// côté de chaque étape.
  void _relief(Canvas canvas, Size size) {
    for (final leg in view.expedition.legs) {
      final onTrail = pointAt(size, view.fractionOf(leg.atMeters));
      // Du côté opposé à l'étiquette, pour ne pas se marcher dessus.
      final side = onTrail.dx > size.width / 2 ? 1.0 : -1.0;
      final at = Offset(onTrail.dx + side * 46, onTrail.dy + 12);
      if (at.dx < 30 || at.dx > size.width - 30) continue;
      Terrain.landmark(canvas, at, leg.kind, leg.name.hashCode);
    }

    final rnd = Random(view.expedition.id.hashCode ^ 0x2b91d4);
    for (var i = 0; i < 26; i++) {
      final t = rnd.nextDouble();
      final onTrail = pointAt(size, t);
      final side = rnd.nextBool() ? 1.0 : -1.0;
      final at = Offset(
        onTrail.dx + side * (56 + rnd.nextDouble() * 92),
        onTrail.dy + (rnd.nextDouble() - 0.5) * 34,
      );

      if (at.dx < 18 || at.dx > size.width - 18) continue;
      if (at.dy < 24 || at.dy > size.height - 30) continue;

      Terrain.feature(canvas, at, _biomeAt(t), rnd);
    }
  }

  /// Graduations de distance le long du sentier.
  void _ticks(Canvas canvas, Size size) {
    if (view.totalMeters <= 0) return;

    final paint = Paint()
      ..color = AppColors.ink.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;

    for (var m = _tickMeters; m < view.totalMeters; m += _tickMeters) {
      final t = view.fractionOf(m);
      final here = pointAt(size, t);
      final ahead = pointAt(size, (t + 0.004).clamp(0.0, 1.0));
      final dir = ahead - here;
      final len = dir.distance;
      if (len == 0) continue;

      // Perpendiculaire à la direction du sentier.
      final n = Offset(-dir.dy / len, dir.dx / len);
      canvas.drawLine(here - n * 5, here + n * 5, paint);
    }
  }

  void _leg(Canvas canvas, Size size, Leg leg) {
    final centre = pointAt(size, view.fractionOf(leg.atMeters));
    final reached = leg.atMeters <= view.travelledMeters;
    final accent = reached ? AppColors.pipPennant : const Color(0xFF9AA6BA);

    canvas.drawCircle(centre, 13, Paint()..color = _paper);
    canvas.drawCircle(
      centre,
      13,
      Paint()
        ..color = accent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4,
    );

    LegGlyphs.paint(canvas, centre, leg.kind, accent);

    // L'étiquette part du côté où le sentier laisse de la place.
    final toLeft = centre.dx > size.width / 2;
    final label = TextPainter(
      text: TextSpan(
        text: leg.name,
        style: TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.w500,
          color: reached
              ? AppColors.ink
              : AppColors.inkSoft.withValues(alpha: 0.75),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: size.width / 2 - 34);

    final origin = Offset(
      toLeft ? centre.dx - 20 - label.width : centre.dx + 20,
      centre.dy - label.height / 2,
    );

    // Un fond papier derrière le texte : sans lui, les étiquettes deviennent
    // illisibles dès qu'elles passent sur du relief.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          origin.dx - 5,
          origin.dy - 2,
          label.width + 10,
          label.height + 4,
        ),
        const Radius.circular(4),
      ),
      Paint()..color = _paper.withValues(alpha: 0.88),
    );
    label.paint(canvas, origin);
  }

  Path _dash(Path source) {
    final out = Path();
    const on = 9.0;
    const off = 7.0;
    for (final metric in source.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final end = min(distance + on, metric.length);
        out.addPath(metric.extractPath(distance, end), Offset.zero);
        distance = end + off;
      }
    }
    return out;
  }

  @override
  bool shouldRepaint(TrailPainter old) =>
      old.time != time ||
      old.view.travelledMeters != view.travelledMeters ||
      old.view.cairns.length != view.cairns.length ||
      old.view.expedition.id != view.expedition.id ||
      old.outfit != outfit;
}
