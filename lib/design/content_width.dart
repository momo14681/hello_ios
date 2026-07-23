import 'package:flutter/material.dart';

/// Borne la largeur du contenu et le centre.
///
/// Cairn est dessiné pour un téléphone. Sans cette borne, une fenêtre de bureau
/// étire les panneaux en bandeaux de 2500 px : le bouton « Partir » devient une
/// barre pleine largeur, et les cartes de la boutique se tassent à gauche d'un
/// vide immense.
class ContentWidth extends StatelessWidget {
  const ContentWidth({super.key, required this.child, this.max = 560});

  final Widget child;
  final double max;

  @override
  Widget build(BuildContext context) => Center(
    // `heightFactor: 1` fait épouser la hauteur de l'enfant. Sans lui, `Center`
    // s'étire verticalement dès que les contraintes sont lâches — et un
    // panneau de quelques lignes devient un rectangle plein écran.
    heightFactor: 1,
    child: ConstrainedBox(
      constraints: BoxConstraints(maxWidth: max),
      child: child,
    ),
  );
}
