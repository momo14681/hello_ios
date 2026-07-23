import 'package:flutter/foundation.dart';

/// Horloge du monde : une seule source de temps pour le paysage et Pip.
///
/// Elle est passée en `repaint` aux `CustomPainter`, ce qui redessine le
/// canevas sans reconstruire l'arbre de widgets à chaque image.
class WorldClock extends ChangeNotifier {
  double _time = 0;
  double _scroll = 0;

  /// Secondes écoulées depuis le démarrage de la vue.
  double get time => _time;

  /// Distance de défilement du monde, en pixels.
  double get scroll => _scroll;

  void advance({required double time, required double dt, required double speed}) {
    _time = time;
    _scroll += speed * dt;
    notifyListeners();
  }

  void reset() {
    _time = 0;
    _scroll = 0;
    notifyListeners();
  }
}
