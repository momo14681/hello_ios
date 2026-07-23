import 'dart:typed_data';

/// Sur le web, il n'y a pas de système de fichiers accessible.
Future<String?> saveCapture(Uint8List bytes, String name) async => null;
