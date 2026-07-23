import 'dart:ui';

import '../design/tokens.dart';

/// Les coiffes disponibles pour Pip. Toutes dessinées en code.
enum PipHat { none, beanie, straw, explorer, crown }

/// Ce que porte Pip. Résolu depuis l'inventaire, consommé par le painter.
class PipOutfit {
  const PipOutfit({
    this.hat = PipHat.none,
    this.bodyTop = AppColors.pipBodyTop,
    this.bodyBottom = AppColors.pipBodyBottom,
    this.detail = AppColors.pipDetail,
    this.strap = AppColors.pipStrap,
    this.pennant = AppColors.pipPennant,
    this.lantern = AppColors.lanternGlass,
  });

  final PipHat hat;
  final Color bodyTop;
  final Color bodyBottom;
  final Color detail;
  final Color strap;
  final Color pennant;
  final Color lantern;

  static const base = PipOutfit();

  PipOutfit copyWith({
    PipHat? hat,
    Color? bodyTop,
    Color? bodyBottom,
    Color? detail,
    Color? strap,
    Color? pennant,
    Color? lantern,
  }) => PipOutfit(
    hat: hat ?? this.hat,
    bodyTop: bodyTop ?? this.bodyTop,
    bodyBottom: bodyBottom ?? this.bodyBottom,
    detail: detail ?? this.detail,
    strap: strap ?? this.strap,
    pennant: pennant ?? this.pennant,
    lantern: lantern ?? this.lantern,
  );
}

/// Ce qu'un article modifie.
enum ItemKind {
  hat('Coiffes'),
  palette('Teintes de Pip'),
  pennant('Fanions'),
  lantern('Lanternes'),
  expedition('Itinéraires');

  const ItemKind(this.label);
  final String label;

  /// Les itinéraires s'achètent mais ne s'équipent pas : on les choisit sur
  /// la carte.
  bool get isEquippable => this != ItemKind.expedition;
}

/// Un jeu de teintes pour le corps de Pip.
class PipPalette {
  const PipPalette({
    required this.top,
    required this.bottom,
    required this.detail,
    required this.strap,
  });

  final Color top;
  final Color bottom;
  final Color detail;
  final Color strap;
}

class ShopItem {
  const ShopItem({
    required this.id,
    required this.name,
    required this.kind,
    required this.price,
    this.hat,
    this.palette,
    this.color,
    this.expeditionId,
    this.freeByDefault = false,
  });

  final String id;
  final String name;
  final ItemKind kind;

  /// Prix en éclats. Zéro pour les articles offerts au départ.
  final int price;

  final PipHat? hat;
  final PipPalette? palette;
  final Color? color;
  final String? expeditionId;

  /// Possédé dès la première ouverture, sans achat.
  final bool freeByDefault;
}

/// La bourse et la garde-robe.
class Inventory {
  const Inventory({
    this.shards = 0,
    this.owned = const {},
    this.equipped = const {},
  });

  /// Les éclats : des fragments de pierre ramassés en chemin.
  final int shards;

  final Set<String> owned;

  /// Article équipé par catégorie.
  final Map<String, String> equipped;

  bool has(String itemId) => owned.contains(itemId);

  bool isEquipped(ShopItem item) => equipped[item.kind.name] == item.id;

  bool canAfford(ShopItem item) => shards >= item.price;

  Inventory copyWith({
    int? shards,
    Set<String>? owned,
    Map<String, String>? equipped,
  }) => Inventory(
    shards: shards ?? this.shards,
    owned: owned ?? this.owned,
    equipped: equipped ?? this.equipped,
  );

  Map<String, Object?> toJson() => {
    'shards': shards,
    'owned': owned.toList(),
    'equipped': equipped,
  };

  static Inventory fromJson(Map<String, Object?> json) => Inventory(
    shards: json['shards'] as int? ?? 0,
    owned: {
      for (final id in (json['owned'] as List? ?? const [])) id as String,
    },
    equipped: {
      for (final e in (json['equipped'] as Map? ?? const {}).entries)
        e.key as String: e.value as String,
    },
  );
}

/// Le barème de récompense.
///
/// Une session abandonnée ne rapporte rien — non pas pour punir, mais parce
/// que l'éclat récompense l'achèvement, comme le cairn. Voir CONCEPT.md §2.
abstract final class Rewards {
  /// Un éclat par tranche de 5 minutes menées à terme.
  static int forSession(Duration planned) => planned.inMinutes ~/ 5;

  /// Prime de franchissement d'étape.
  static const perLeg = 15;

  static int total({required Duration planned, required int legsReached}) =>
      forSession(planned) + legsReached * perLeg;
}
