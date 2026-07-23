import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/wardrobe/wardrobe_catalog.dart';
import '../../data/wardrobe/wardrobe_repository.dart';
import '../../domain/wardrobe.dart';

final wardrobeRepositoryProvider = Provider<WardrobeRepository>(
  (ref) => PrefsWardrobeRepository(),
);

/// Résultat d'un achat, pour que l'interface sache quoi dire.
enum PurchaseOutcome { bought, alreadyOwned, tooExpensive }

/// La bourse et la garde-robe.
class WardrobeController extends AsyncNotifier<Inventory> {
  @override
  Future<Inventory> build() async {
    final stored = await ref.watch(wardrobeRepositoryProvider).load();
    return stored ?? WardrobeCatalog.starter;
  }

  /// Crédite les éclats gagnés par une session menée à terme.
  Future<int> reward({
    required Duration planned,
    required int legsReached,
  }) async {
    final current = state.value;
    if (current == null) return 0;

    final gain = Rewards.total(planned: planned, legsReached: legsReached);
    if (gain <= 0) return 0;

    await _commit(current.copyWith(shards: current.shards + gain));
    return gain;
  }

  Future<PurchaseOutcome> buy(ShopItem item) async {
    final current = state.value;
    if (current == null) return PurchaseOutcome.tooExpensive;
    if (current.has(item.id)) return PurchaseOutcome.alreadyOwned;
    if (!current.canAfford(item)) return PurchaseOutcome.tooExpensive;

    var next = current.copyWith(
      shards: current.shards - item.price,
      owned: {...current.owned, item.id},
    );

    // Un cosmétique acheté se porte tout de suite : personne n'achète un
    // chapeau pour le laisser dans un tiroir.
    if (item.kind.isEquippable) {
      next = next.copyWith(
        equipped: {...next.equipped, item.kind.name: item.id},
      );
    }

    await _commit(next);
    return PurchaseOutcome.bought;
  }

  Future<void> equip(ShopItem item) async {
    final current = state.value;
    if (current == null || !current.has(item.id)) return;
    if (!item.kind.isEquippable) return;

    await _commit(
      current.copyWith(
        equipped: {...current.equipped, item.kind.name: item.id},
      ),
    );
  }

  /// Réservé au développement : permet d'essayer la boutique sans attendre
  /// des heures de concentration.
  Future<void> debugGrant(int shards) async {
    final current = state.value;
    if (current == null) return;
    await _commit(current.copyWith(shards: current.shards + shards));
  }

  Future<void> _commit(Inventory next) async {
    await ref.read(wardrobeRepositoryProvider).save(next);
    state = AsyncData(next);
  }
}

final wardrobeControllerProvider =
    AsyncNotifierProvider<WardrobeController, Inventory>(
      WardrobeController.new,
    );

/// La tenue portée par Pip, prête pour le painter.
final pipOutfitProvider = Provider<PipOutfit>((ref) {
  final inventory = ref.watch(wardrobeControllerProvider).value;
  return inventory == null
      ? PipOutfit.base
      : WardrobeCatalog.outfitOf(inventory);
});
