import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import 'capture_writer_stub.dart'
    if (dart.library.io) 'capture_writer_io.dart';

/// Capture l'écran réel de l'application dans un PNG, sur **F12**.
///
/// Les tests de rendu montrent ce que produisent les *painters* ; ils ne
/// montrent pas la mise en page, les marges, les polices réelles ni les
/// panneaux. Cette capture-là, si.
///
/// Actif uniquement en `kDebugMode` : en production, le widget se contente de
/// laisser passer son enfant.
class DebugCapture extends StatefulWidget {
  const DebugCapture({super.key, required this.child});

  final Widget child;

  @override
  State<DebugCapture> createState() => _DebugCaptureState();
}

class _DebugCaptureState extends State<DebugCapture> {
  final _boundaryKey = GlobalKey();
  var _index = 0;
  var _busy = false;

  @override
  void initState() {
    super.initState();
    if (kDebugMode) HardwareKeyboard.instance.addHandler(_onKey);
  }

  @override
  void dispose() {
    if (kDebugMode) HardwareKeyboard.instance.removeHandler(_onKey);
    super.dispose();
  }

  bool _onKey(KeyEvent event) {
    if (event is! KeyDownEvent) return false;
    if (event.logicalKey != LogicalKeyboardKey.f12) return false;
    _capture();
    return true;
  }

  Future<void> _capture() async {
    if (_busy) return;
    _busy = true;

    try {
      final object = _boundaryKey.currentContext?.findRenderObject();
      if (object is! RenderRepaintBoundary) return;

      final image = await object.toImage(pixelRatio: 2);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      if (data == null) return;

      final name = 'screen-${_index++}.png';
      final path = await saveCapture(data.buffer.asUint8List(), name);

      debugPrint(
        path == null
            ? 'Capture indisponible sur cette plateforme.'
            : 'Capture écrite : $path',
      );

      if (mounted && path != null) {
        ScaffoldMessenger.maybeOf(context)
          ?..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              duration: const Duration(seconds: 4),
              content: Text('Capture : $path'),
            ),
          );
      }
    } finally {
      _busy = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) return widget.child;
    return RepaintBoundary(key: _boundaryKey, child: widget.child);
  }
}
