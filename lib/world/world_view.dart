import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../domain/wardrobe.dart';
import 'pip/pip_params.dart';
import 'world_clock.dart';
import 'world_painter.dart';
import 'world_theme.dart';

/// Le monde animé de Cairn.
///
/// Une seule horloge alimente le paysage et Pip. Le monde ne défile que
/// lorsque Pip marche — à l'arrêt, la scène se fige et seule sa respiration
/// continue.
class WorldView extends StatefulWidget {
  const WorldView({
    super.key,
    this.params = PipParams.defaults,
    this.pose = PipPose.walking,
    this.scrollSpeed = 34,
    this.theme = WorldTheme.mountain,
    this.pipXFraction = 0.42,
    this.showCairns = true,
    this.showDecor = true,
    this.outfit = PipOutfit.base,
    this.bottomInset = 0,
    this.autoScalePip = true,
    this.speechSeed = 0,
    this.hourOverride,
  });

  final PipParams params;
  final PipPose pose;

  /// Vitesse de défilement du monde, en pixels par seconde.
  final double scrollSpeed;

  /// L'ambiance de l'itinéraire traversé.
  final WorldTheme theme;

  final double pipXFraction;
  final bool showCairns;

  /// Arbres, rochers, herbe, nuages et étoiles.
  final bool showDecor;

  /// Ce que porte Pip.
  final PipOutfit outfit;

  /// Hauteur occupée en bas par l'interface.
  final double bottomInset;

  /// Fait suivre la taille de Pip à celle de la fenêtre.
  final bool autoScalePip;

  /// Fait varier la réplique de Pip d'un incident à l'autre.
  final int speechSeed;

  /// Force une heure de la journée. `null` suit l'horloge du téléphone.
  final double? hourOverride;

  @override
  State<WorldView> createState() => _WorldViewState();
}

class _WorldViewState extends State<WorldView>
    with SingleTickerProviderStateMixin {
  final _clock = WorldClock();
  late final Ticker _ticker;
  Duration _last = Duration.zero;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick)..start();
  }

  void _onTick(Duration elapsed) {
    final dt = ((elapsed - _last).inMicroseconds / 1e6).clamp(0.0, 0.05);
    _last = elapsed;
    _clock.advance(
      time: elapsed.inMicroseconds / 1e6,
      dt: dt,
      speed: widget.pose == PipPose.walking ? widget.scrollSpeed : 0,
    );
  }

  @override
  void dispose() {
    _ticker.dispose();
    _clock.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final hour = widget.hourOverride ?? (now.hour + now.minute / 60);

    return RepaintBoundary(
      child: SizedBox.expand(
        child: CustomPaint(
          painter: WorldPainter(
            clock: _clock,
            sky: widget.theme.skyFor(hour),
            hour: hour,
            params: widget.params,
            pose: widget.pose,
            spec: widget.theme.landscape,
            pipXFraction: widget.pipXFraction,
            showCairns: widget.showCairns,
            showDecor: widget.showDecor,
            outfit: widget.outfit,
            bottomInset: widget.bottomInset,
            autoScalePip: widget.autoScalePip,
            speechSeed: widget.speechSeed,
          ),
        ),
      ),
    );
  }
}
