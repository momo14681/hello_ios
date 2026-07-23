import 'dart:io';
import 'dart:typed_data';

/// Écrit une capture sur le disque et renvoie son chemin absolu.
///
/// La destination est `CAIRN_CAPTURE_DIR` si la variable existe, sinon
/// `build/preview` sous le répertoire courant.
Future<String?> saveCapture(Uint8List bytes, String name) async {
  final base =
      Platform.environment['CAIRN_CAPTURE_DIR'] ??
      '${Directory.current.path}${Platform.pathSeparator}build'
          '${Platform.pathSeparator}preview';

  final dir = Directory(base);
  await dir.create(recursive: true);

  final file = File('${dir.path}${Platform.pathSeparator}$name');
  await file.writeAsBytes(bytes, flush: true);
  return file.absolute.path;
}
