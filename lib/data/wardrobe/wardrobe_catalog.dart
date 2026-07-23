import 'dart:ui';

import '../../design/tokens.dart';
import '../../domain/wardrobe.dart';
import '../expedition/expedition_catalog.dart';

/// La boutique.
///
/// Les prix sont calibrés sur le barème : une session de 25 minutes rapporte
/// 5 éclats, une étape franchie 15. Un accessoire d'entrée coûte donc environ
/// une semaine de pratique, un itinéraire plusieurs mois — assez pour que le
/// joueur gratuit y arrive, assez pour que Cairn+ garde son intérêt.
abstract final class WardrobeCatalog {
  // ---- Coiffes ----
  static const noHat = ShopItem(
    id: 'hat_none',
    name: 'Tête nue',
    kind: ItemKind.hat,
    price: 0,
    hat: PipHat.none,
    freeByDefault: true,
  );
  static const beanie = ShopItem(
    id: 'hat_beanie',
    name: 'Bonnet',
    kind: ItemKind.hat,
    price: 30,
    hat: PipHat.beanie,
  );
  static const straw = ShopItem(
    id: 'hat_straw',
    name: 'Chapeau de paille',
    kind: ItemKind.hat,
    price: 55,
    hat: PipHat.straw,
  );
  static const explorer = ShopItem(
    id: 'hat_explorer',
    name: 'Casque d\'explorateur',
    kind: ItemKind.hat,
    price: 90,
    hat: PipHat.explorer,
  );
  static const crown = ShopItem(
    id: 'hat_crown',
    name: 'Couronne',
    kind: ItemKind.hat,
    price: 260,
    hat: PipHat.crown,
  );

  // ---- Teintes ----
  static const riverStone = ShopItem(
    id: 'palette_river',
    name: 'Galet de rivière',
    kind: ItemKind.palette,
    price: 0,
    freeByDefault: true,
    palette: PipPalette(
      top: AppColors.pipBodyTop,
      bottom: AppColors.pipBodyBottom,
      detail: AppColors.pipDetail,
      strap: AppColors.pipStrap,
    ),
  );
  static const slate = ShopItem(
    id: 'palette_slate',
    name: 'Ardoise',
    kind: ItemKind.palette,
    price: 70,
    palette: PipPalette(
      top: Color(0xFFC7D0DE),
      bottom: Color(0xFF8D9AAF),
      detail: Color(0xFF4E5A73),
      strap: Color(0xFF3C4659),
    ),
  );
  static const moss = ShopItem(
    id: 'palette_moss',
    name: 'Mousse',
    kind: ItemKind.palette,
    price: 70,
    palette: PipPalette(
      top: Color(0xFFCFE0B4),
      bottom: Color(0xFF95B47C),
      detail: Color(0xFF4F6B4A),
      strap: Color(0xFF3D5539),
    ),
  );
  static const ember = ShopItem(
    id: 'palette_ember',
    name: 'Braise',
    kind: ItemKind.palette,
    price: 110,
    palette: PipPalette(
      top: Color(0xFFFFC49B),
      bottom: Color(0xFFD9705A),
      detail: Color(0xFF7B3B45),
      strap: Color(0xFF5E2C36),
    ),
  );
  static const amethyst = ShopItem(
    id: 'palette_amethyst',
    name: 'Améthyste',
    kind: ItemKind.palette,
    price: 150,
    palette: PipPalette(
      top: Color(0xFFE0CDF5),
      bottom: Color(0xFFA688C8),
      detail: Color(0xFF5B4380),
      strap: Color(0xFF453163),
    ),
  );

  // ---- Fanions ----
  static const pennantCoral = ShopItem(
    id: 'pennant_coral',
    name: 'Corail',
    kind: ItemKind.pennant,
    price: 0,
    freeByDefault: true,
    color: AppColors.pipPennant,
  );
  static const pennantSky = ShopItem(
    id: 'pennant_sky',
    name: 'Azur',
    kind: ItemKind.pennant,
    price: 25,
    color: Color(0xFF6FA8D6),
  );
  static const pennantMint = ShopItem(
    id: 'pennant_mint',
    name: 'Menthe',
    kind: ItemKind.pennant,
    price: 25,
    color: Color(0xFF6CC5A6),
  );
  static const pennantGold = ShopItem(
    id: 'pennant_gold',
    name: 'Or',
    kind: ItemKind.pennant,
    price: 60,
    color: Color(0xFFE8B84B),
  );

  // ---- Lanternes ----
  // Chaque modèle a sa **silhouette**, pas seulement sa teinte : trois
  // pastilles de couleur, c'était trois fois le même objet en boutique.
  static const lanternWarm = ShopItem(
    id: 'lantern_warm',
    name: 'Flamme',
    kind: ItemKind.lantern,
    price: 0,
    freeByDefault: true,
    color: AppColors.lanternGlass,
    lanternStyle: LanternStyle.classic,
  );
  static const lanternBlue = ShopItem(
    id: 'lantern_blue',
    name: 'Feu froid',
    kind: ItemKind.lantern,
    price: 45,
    color: Color(0xFF8FD6F0),
    lanternStyle: LanternStyle.classic,
  );
  static const lanternPaper = ShopItem(
    id: 'lantern_paper',
    name: 'Lampion',
    kind: ItemKind.lantern,
    price: 75,
    color: Color(0xFFF2A65A),
    lanternStyle: LanternStyle.paper,
  );
  // L'identifiant reste `lantern_green` : le renommer ferait perdre l'article
  // à qui l'avait déjà acheté.
  static const lanternFirefly = ShopItem(
    id: 'lantern_green',
    name: 'Bocal à lucioles',
    kind: ItemKind.lantern,
    price: 95,
    color: Color(0xFFA8E06A),
    lanternStyle: LanternStyle.fireflyJar,
  );
  static const lanternCrystal = ShopItem(
    id: 'lantern_crystal',
    name: 'Cristal',
    kind: ItemKind.lantern,
    price: 150,
    color: Color(0xFFC9A8F0),
    lanternStyle: LanternStyle.crystal,
  );

  // ---- Itinéraires ----
  static final desert = ShopItem(
    id: 'expedition_${ExpeditionCatalog.amberDesert.id}',
    name: ExpeditionCatalog.amberDesert.name,
    kind: ItemKind.expedition,
    price: 700,
    expeditionId: ExpeditionCatalog.amberDesert.id,
  );
  static final shelf = ShopItem(
    id: 'expedition_${ExpeditionCatalog.frozenShelf.id}',
    name: ExpeditionCatalog.frozenShelf.name,
    kind: ItemKind.expedition,
    price: 1100,
    expeditionId: ExpeditionCatalog.frozenShelf.id,
  );

  static final all = <ShopItem>[
    noHat, beanie, straw, explorer, crown,
    riverStone, slate, moss, ember, amethyst,
    pennantCoral, pennantSky, pennantMint, pennantGold,
    lanternWarm, lanternBlue, lanternPaper, lanternFirefly, lanternCrystal,
    desert, shelf,
  ];

  /// Un itinéraire est accessible s'il est offert au départ, s'il a été
  /// débloqué aux éclats, ou si l'abonnement Cairn+ est actif.
  static bool ownsExpedition(
    Inventory inventory,
    String expeditionId, {
    bool plus = false,
  }) {
    if (plus) return true;
    if (expeditionId == ExpeditionCatalog.initial.id) return true;
    for (final item in all) {
      if (item.expeditionId == expeditionId) return inventory.has(item.id);
    }
    return false;
  }

  static List<ShopItem> of(ItemKind kind) =>
      all.where((i) => i.kind == kind).toList();

  static ShopItem? byId(String id) {
    for (final item in all) {
      if (item.id == id) return item;
    }
    return null;
  }

  /// Ce qui est acquis dès la première ouverture.
  static Inventory get starter => Inventory(
    owned: {for (final i in all.where((i) => i.freeByDefault)) i.id},
    equipped: {
      for (final i in all.where((i) => i.freeByDefault && i.kind.isEquippable))
        i.kind.name: i.id,
    },
  );

  /// Traduit l'inventaire en tenue portée.
  static PipOutfit outfitOf(Inventory inventory) {
    var outfit = PipOutfit.base;

    for (final entry in inventory.equipped.entries) {
      final item = byId(entry.value);
      if (item == null || !inventory.has(item.id)) continue;

      switch (item.kind) {
        case ItemKind.hat:
          outfit = outfit.copyWith(hat: item.hat);
        case ItemKind.palette:
          final p = item.palette;
          if (p != null) {
            outfit = outfit.copyWith(
              bodyTop: p.top,
              bodyBottom: p.bottom,
              detail: p.detail,
              strap: p.strap,
            );
          }
        case ItemKind.pennant:
          outfit = outfit.copyWith(pennant: item.color);
        case ItemKind.lantern:
          outfit = outfit.copyWith(
            lantern: item.color,
            lanternStyle: item.lanternStyle,
          );
        case ItemKind.expedition:
          break;
      }
    }

    return outfit;
  }
}
