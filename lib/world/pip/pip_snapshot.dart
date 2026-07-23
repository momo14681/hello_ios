import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../domain/wardrobe.dart';
import 'pip_painter.dart';
import 'pip_params.dart';

/// Rend Pip dans une image PNG, hors de tout arbre de widgets.
///
/// Sert à le glisser dans la notification permanente d'Android — et, le jour
/// venu, dans une Live Activity iOS. **C'est ce qui évite de redessiner Pip en
/// natif** : la notification n'affiche qu'une image, produite par le même code
/// que le reste de l'app.
abstract final class PipSnapshot {
  /// Hauteur approximative de Pip à l'échelle 1, coiffe comprise.
  static const _naturalHeight = 72.0;

  /// [side] est le côté de l'image carrée produite, en pixels.
  static Future<Uint8List?> render({
    required PipOutfit outfit,
    double side = 192,
    PipPose pose = PipPose.walking,
    double lanternLit = 0,
  }) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, side, side));

    // Le fanion est masqué : il pousse la silhouette très haut, or une icône
    // de notification est rognée en carré ou en cercle.
    PipArt.paint(
      canvas,
      Offset(side / 2, side * 0.88),
      PipParams(
        scale: side / (_naturalHeight * 1.25),
        showPennant: false,
      ),
      pose,
      0.25,
      lanternLit: lanternLit,
      outfit: outfit,
    );

    final picture = recorder.endRecording();
    final image = await picture.toImage(side.toInt(), side.toInt());
    picture.dispose();

    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    return data?.buffer.asUint8List();
  }
}
