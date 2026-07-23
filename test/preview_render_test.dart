import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hello_ios/data/expedition/expedition_catalog.dart';
import 'package:hello_ios/data/wardrobe/wardrobe_catalog.dart';
import 'package:hello_ios/domain/expedition.dart';
import 'package:hello_ios/domain/wardrobe.dart';
import 'package:hello_ios/features/expedition/trail_painter.dart';
import 'package:hello_ios/world/pip/pip_painter.dart';
import 'package:hello_ios/world/pip/pip_params.dart';
import 'package:hello_ios/world/sky.dart';
import 'package:hello_ios/world/world_theme.dart';
import 'package:hello_ios/world/world_clock.dart';
import 'package:hello_ios/world/world_painter.dart';

/// Rend le monde dans des PNG, pour inspecter le dessin sans lancer l'app.
///
/// Utile parce que le paysage et Pip sont entièrement procéduraux : c'est le
/// seul moyen de relire visuellement une modification de painter sans passer
/// par un appareil. Défini `CAIRN_PREVIEW_DIR` pour choisir la destination.
void main() {
  final outDir = Platform.environment['CAIRN_PREVIEW_DIR'];

  Future<void> render(
    String name,
    Size size,
    void Function(Canvas canvas, Size size) draw,
  ) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, Offset.zero & size);
    draw(canvas, size);
    final picture = recorder.endRecording();
    final image = await picture.toImage(
      size.width.toInt(),
      size.height.toInt(),
    );
    final data = await image.toByteData(format: ui.ImageByteFormat.png);

    expect(data, isNotNull, reason: 'le rendu doit produire des pixels');
    expect(data!.lengthInBytes, greaterThan(1000));

    if (outDir != null) {
      Directory(outDir).createSync(recursive: true);
      File('$outDir/$name.png').writeAsBytesSync(data.buffer.asUint8List());
    }
  }

  WorldPainter painterAt(double hour, {double scroll = 420, PipParams? params}) {
    final clock = WorldClock()
      ..advance(time: 1.35, dt: 1, speed: scroll);
    return WorldPainter(
      clock: clock,
      sky: SkyPalette.forHour(hour),
      hour: hour,
      params: params ?? const PipParams(scale: 1.5),
      pose: PipPose.walking,
    );
  }

  test('le monde se rend de jour', () async {
    await render(
      'world_day',
      const Size(900, 420),
      (c, s) => painterAt(12).paint(c, s),
    );
  });

  test('le monde se rend de nuit, lanterne allumée', () async {
    await render(
      'world_night',
      const Size(900, 420),
      (c, s) => painterAt(22).paint(c, s),
    );
  });

  test('le monde se rend au crépuscule', () async {
    await render(
      'world_dusk',
      const Size(900, 420),
      (c, s) => painterAt(19).paint(c, s),
    );
  });

  test('la carte de l\'expédition se rend', () async {
    // Une quinzaine de sessions déjà faites : deux étapes franchies, la
    // troisième en vue.
    final cairns = [
      for (var i = 1; i <= 14; i++)
        Cairn(
          atMeters: i * 1150.0,
          placedAt: DateTime.utc(2026, 7, i),
          stones: 2 + (i % 4),
        ),
    ];

    final view = ExpeditionView(
      expedition: ExpeditionCatalog.firstCrossing,
      progress: ExpeditionProgress(
        expeditionId: ExpeditionCatalog.firstCrossing.id,
        travelledMeters: 16100,
        cairns: cairns,
      ),
    );

    await render(
      'expedition_map',
      const Size(420, 720),
      (canvas, size) => TrailPainter(view: view, time: 1.2).paint(canvas, size),
    );
  });

  test('chaque itinéraire a son propre monde', () async {
    for (final theme in WorldTheme.all) {
      await render(
        'world_${theme.id}',
        const Size(900, 380),
        (c, s) => WorldPainter(
          clock: WorldClock()..advance(time: 1.35, dt: 1, speed: 420),
          sky: theme.skyFor(13),
          hour: 13,
          params: const PipParams(scale: 1.5),
          pose: PipPose.walking,
          spec: theme.landscape,
        ).paint(c, s),
      );
    }
  });

  test('la planche des tenues se rend', () async {
    // Rangée 1 : les coiffes. Rangée 2 : les teintes.
    final outfits = <PipOutfit>[
      PipOutfit.base,
      PipOutfit.base.copyWith(hat: PipHat.beanie),
      PipOutfit.base.copyWith(hat: PipHat.straw),
      PipOutfit.base.copyWith(hat: PipHat.explorer),
      PipOutfit.base.copyWith(hat: PipHat.crown),
      for (final item in [
        WardrobeCatalog.slate,
        WardrobeCatalog.moss,
        WardrobeCatalog.ember,
        WardrobeCatalog.amethyst,
      ])
        PipOutfit.base.copyWith(
          hat: PipHat.beanie,
          bodyTop: item.palette!.top,
          bodyBottom: item.palette!.bottom,
          detail: item.palette!.detail,
          strap: item.palette!.strap,
        ),
    ];

    await render('pip_outfits', const Size(900, 560), (canvas, size) {
      canvas.drawRect(
        Offset.zero & size,
        Paint()..color = const Color(0xFFE7EDF4),
      );
      for (var i = 0; i < outfits.length; i++) {
        PipArt.paint(
          canvas,
          Offset(100 + (i % 5) * 175.0, 230 + (i ~/ 5) * 275.0),
          const PipParams(scale: 1.9),
          PipPose.idle,
          1.35,
          outfit: outfits[i],
        );
      }
    });
  });

  test('la planche des objets portés se rend', () async {
    // Rangée du haut : la gourde de jour, puis les quatre lanternes.
    final carried = <(double, LanternStyle, Color)>[
      (0, LanternStyle.classic, WardrobeCatalog.lanternWarm.color!),
      (1, LanternStyle.classic, WardrobeCatalog.lanternWarm.color!),
      (1, LanternStyle.classic, WardrobeCatalog.lanternBlue.color!),
      (1, LanternStyle.paper, WardrobeCatalog.lanternPaper.color!),
      (1, LanternStyle.fireflyJar, WardrobeCatalog.lanternFirefly.color!),
      (1, LanternStyle.crystal, WardrobeCatalog.lanternCrystal.color!),
    ];

    await render('pip_carried', const Size(900, 320), (canvas, size) {
      canvas.drawRect(
        Offset.zero & size,
        Paint()..color = const Color(0xFF2E2A44),
      );
      for (var i = 0; i < carried.length; i++) {
        final (lit, style, glass) = carried[i];
        PipArt.paint(
          canvas,
          Offset(90 + i * 145.0, 250),
          const PipParams(scale: 1.9),
          PipPose.idle,
          1.35,
          lanternLit: lit,
          outfit: PipOutfit.base.copyWith(
            lantern: glass,
            lanternStyle: style,
          ),
        );
      }
    });
  });

  test('les répliques de Pip se rendent', () async {
    // Fatigue, choc, douleur, étonnement, joie.
    const poses = [
      PipPose.tired,
      PipPose.bumped,
      PipPose.hurt,
      PipPose.surprised,
      PipPose.cheering,
    ];

    await render('pip_speech', const Size(900, 460), (canvas, size) {
      for (var i = 0; i < poses.length; i++) {
        final clock = WorldClock()..advance(time: 1.35, dt: 1, speed: 200);
        WorldPainter(
          clock: clock,
          sky: SkyPalette.forHour(14),
          hour: 14,
          params: const PipParams(scale: 1.1),
          pose: poses[i],
          pipXFraction: 0.5,
          showDecor: false,
          showCairns: false,
          autoScalePip: false,
        ).paint(
          canvas,
          const Size(180, 230),
        );
        canvas.translate(180, 0);
      }
    });
  });

  test('la planche des réactions se rend', () async {
    // Ordre de lecture : arrêt, marche, camp, cairn, étonné,
    // puis choc, douleur, fatigue, joie.
    await render('pip_reactions', const Size(900, 540), (canvas, size) {
      canvas.drawRect(
        Offset.zero & size,
        Paint()..color = const Color(0xFFCBD6E6),
      );
      final poses = PipPose.values;
      for (var i = 0; i < poses.length; i++) {
        PipArt.paint(
          canvas,
          Offset(95 + (i % 5) * 180.0, 210 + (i ~/ 5) * 265.0),
          const PipParams(scale: 1.9),
          poses[i],
          1.35,
        );
      }
    });
  });

  test('Pip se rend en gros plan', () async {
    await render(
      'pip_closeup',
      const Size(460, 380),
      (c, s) => painterAt(
        18.5,
        scroll: 120,
        params: const PipParams(scale: 4.2),
      ).paint(c, s),
    );
  });
}
