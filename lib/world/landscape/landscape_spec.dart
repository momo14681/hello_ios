import 'dart:math';
import 'dart:ui';

import '../../design/tokens.dart';

/// Une couche de collines.
///
/// La silhouette est une somme de trois sinusoïdes. Trois suffisent à ne jamais
/// paraître périodique à l'œil, et le coût de calcul est négligeable.
class LandscapeLayer {
  const LandscapeLayer({
    required this.baseFraction,
    required this.amplitudes,
    required this.frequencies,
    required this.phases,
    required this.speed,
    required this.color,
  });

  /// Hauteur de repos, en fraction de la hauteur du canevas.
  final double baseFraction;
  final List<double> amplitudes;
  final List<double> frequencies;
  final List<double> phases;

  /// Vitesse de parallaxe : 1 pour la couche de premier plan.
  final double speed;
  final Color color;

  /// Altitude du sol à l'abscisse [x] pour un défilement [scroll].
  double yAt(double x, double scroll, double height) {
    final wx = x + scroll * speed;
    var y = baseFraction * height;
    for (var i = 0; i < amplitudes.length; i++) {
      y += amplitudes[i] * sin(wx * frequencies[i] + phases[i]);
    }
    return y;
  }

  /// La silhouette remplie de la couche.
  ///
  /// [size] fixe le repère du relief ; [fillTo] indique jusqu'où descendre le
  /// remplissage. Les deux diffèrent quand l'interface occupe le bas de
  /// l'écran : le sol remonte, mais la couleur doit continuer jusqu'en bas.
  Path pathFor(Size size, double scroll, {double? fillTo}) {
    final bottom = fillTo ?? size.height;
    final path = Path()..moveTo(0, bottom);
    path.lineTo(0, yAt(0, scroll, size.height));
    for (var x = 0.0; x <= size.width; x += 3) {
      path.lineTo(x, yAt(x, scroll, size.height));
    }
    return path
      ..lineTo(size.width, bottom)
      ..close();
  }
}

/// Ce qui peuple une couche de collines.
///
/// Une valeur à 0 désactive l'élément. Les espacements sont exprimés en pixels
/// de monde, pas d'écran : le décor défile donc à la vitesse de sa couche.
enum DecorStyle {
  /// Conifères : le paysage de montagne d'origine.
  conifer,

  /// Aiguilles rocheuses, pour le désert.
  spire,

  /// Éclats de glace dressés, pour la banquise.
  shard,
}

class LayerDecor {
  const LayerDecor({
    this.treeSpacing = 0,
    this.treeHeight = 0,
    this.boulderSpacing = 0,
    this.grassSpacing = 0,
    this.style = DecorStyle.conifer,
  });

  final double treeSpacing;
  final double treeHeight;
  final double boulderSpacing;
  final double grassSpacing;

  /// La forme des éléments dressés le long de la couche.
  final DecorStyle style;

  static const none = LayerDecor();
}

/// L'ensemble des couches d'un paysage et de leur décor.
class LandscapeSpec {
  const LandscapeSpec(this.layers, this.decors);

  final List<LandscapeLayer> layers;

  /// Décor par couche, indexé comme [layers].
  final List<LayerDecor> decors;

  /// La couche sur laquelle Pip marche.
  LandscapeLayer get ground => layers.last;

  LayerDecor decorFor(int index) =>
      index < decors.length ? decors[index] : LayerDecor.none;

  /// Paysage par défaut. Les valeurs sortent du banc d'essai — elles n'ont
  /// pas d'autre justification que « ça se regarde bien ».
  static const standard = LandscapeSpec(
    [
    LandscapeLayer(
      baseFraction: 0.56,
      amplitudes: [14, 9, 5],
      frequencies: [0.0052, 0.0117, 0.0231],
      phases: [0.4, 2.1, 4.4],
      speed: 0.10,
      color: AppColors.hillFar,
    ),
    LandscapeLayer(
      baseFraction: 0.66,
      amplitudes: [17, 11, 6],
      frequencies: [0.0043, 0.0098, 0.0195],
      phases: [1.9, 3.6, 0.8],
      speed: 0.24,
      color: AppColors.hillMid,
    ),
    LandscapeLayer(
      baseFraction: 0.76,
      amplitudes: [15, 10, 6],
      frequencies: [0.0061, 0.0134, 0.0252],
      phases: [3.1, 1.2, 5.2],
      speed: 0.52,
      color: AppColors.hillNear,
    ),
    LandscapeLayer(
      baseFraction: 0.86,
      amplitudes: [11, 7, 4],
      frequencies: [0.0074, 0.0163, 0.0301],
      phases: [2.4, 4.8, 1.6],
      speed: 1.0,
      color: AppColors.hillGround,
    ),
    ],
    [
      // La couche la plus lointaine reste nue : c'est ce qui donne la
      // sensation de distance.
      LayerDecor.none,
      LayerDecor(treeSpacing: 88, treeHeight: 21),
      LayerDecor(treeSpacing: 74, treeHeight: 34, boulderSpacing: 240),
      LayerDecor(
        treeSpacing: 150,
        treeHeight: 54,
        boulderSpacing: 190,
        grassSpacing: 44,
      ),
    ],
  );
}
