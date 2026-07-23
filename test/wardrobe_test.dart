import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hello_ios/data/wardrobe/wardrobe_catalog.dart';
import 'package:hello_ios/data/wardrobe/wardrobe_repository.dart';
import 'package:hello_ios/domain/wardrobe.dart';
import 'package:hello_ios/features/wardrobe/wardrobe_controller.dart';

Future<ProviderContainer> _ready({InMemoryWardrobeRepository? repo}) async {
  final c = ProviderContainer(
    overrides: [
      wardrobeRepositoryProvider.overrideWith(
        (ref) => repo ?? InMemoryWardrobeRepository(),
      ),
    ],
  );
  addTearDown(c.dispose);
  await c.read(wardrobeControllerProvider.future);
  return c;
}

void main() {
  group('Rewards', () {
    test('un éclat par tranche de 5 minutes achevées', () {
      expect(Rewards.forSession(const Duration(minutes: 25)), 5);
      expect(Rewards.forSession(const Duration(minutes: 15)), 3);
      expect(Rewards.forSession(const Duration(minutes: 60)), 12);
      expect(Rewards.forSession(const Duration(minutes: 4)), 0);
    });

    test('chaque étape franchie ajoute une prime', () {
      expect(
        Rewards.total(planned: const Duration(minutes: 25), legsReached: 2),
        5 + 2 * Rewards.perLeg,
      );
    });
  });

  group('Inventaire', () {
    test('la garde-robe de départ porte les articles offerts', () async {
      final c = await _ready();
      final inv = c.read(wardrobeControllerProvider).value!;

      expect(inv.shards, 0);
      expect(inv.has(WardrobeCatalog.noHat.id), isTrue);
      expect(inv.has(WardrobeCatalog.riverStone.id), isTrue);
      expect(inv.has(WardrobeCatalog.beanie.id), isFalse);
      expect(inv.isEquipped(WardrobeCatalog.riverStone), isTrue);
    });

    test('acheter sans éclats échoue', () async {
      final c = await _ready();
      final outcome = await c
          .read(wardrobeControllerProvider.notifier)
          .buy(WardrobeCatalog.beanie);

      expect(outcome, PurchaseOutcome.tooExpensive);
      expect(
        c.read(wardrobeControllerProvider).value!.has(WardrobeCatalog.beanie.id),
        isFalse,
      );
    });

    test('un achat débite et équipe aussitôt', () async {
      final c = await _ready();
      final n = c.read(wardrobeControllerProvider.notifier);
      await n.debugGrant(100);

      final outcome = await n.buy(WardrobeCatalog.beanie);
      final inv = c.read(wardrobeControllerProvider).value!;

      expect(outcome, PurchaseOutcome.bought);
      expect(inv.shards, 100 - WardrobeCatalog.beanie.price);
      expect(inv.has(WardrobeCatalog.beanie.id), isTrue);
      expect(inv.isEquipped(WardrobeCatalog.beanie), isTrue);
    });

    test('racheter un article déjà possédé ne débite pas', () async {
      final c = await _ready();
      final n = c.read(wardrobeControllerProvider.notifier);
      await n.debugGrant(100);
      await n.buy(WardrobeCatalog.beanie);

      final before = c.read(wardrobeControllerProvider).value!.shards;
      final outcome = await n.buy(WardrobeCatalog.beanie);

      expect(outcome, PurchaseOutcome.alreadyOwned);
      expect(c.read(wardrobeControllerProvider).value!.shards, before);
    });

    test('on ne peut pas équiper ce qu\'on ne possède pas', () async {
      final c = await _ready();
      await c.read(wardrobeControllerProvider.notifier).equip(
        WardrobeCatalog.crown,
      );

      expect(
        c.read(wardrobeControllerProvider).value!.isEquipped(
          WardrobeCatalog.crown,
        ),
        isFalse,
      );
    });

    test('un itinéraire s\'achète mais ne s\'équipe pas', () async {
      final c = await _ready();
      final n = c.read(wardrobeControllerProvider.notifier);
      await n.debugGrant(2000);
      await n.buy(WardrobeCatalog.desert);

      final inv = c.read(wardrobeControllerProvider).value!;
      expect(inv.has(WardrobeCatalog.desert.id), isTrue);
      expect(inv.equipped.containsKey(ItemKind.expedition.name), isFalse);
    });

    test('la garde-robe est relue au redémarrage', () async {
      final repo = InMemoryWardrobeRepository();

      final first = await _ready(repo: repo);
      final n = first.read(wardrobeControllerProvider.notifier);
      await n.debugGrant(200);
      await n.buy(WardrobeCatalog.straw);

      final second = await _ready(repo: repo);
      final inv = second.read(wardrobeControllerProvider).value!;

      expect(inv.has(WardrobeCatalog.straw.id), isTrue);
      expect(inv.shards, 200 - WardrobeCatalog.straw.price);
    });
  });

  group('Tenue', () {
    test('la tenue de départ est celle de base', () {
      final outfit = WardrobeCatalog.outfitOf(WardrobeCatalog.starter);
      expect(outfit.hat, PipHat.none);
      expect(outfit.bodyTop, PipOutfit.base.bodyTop);
    });

    test('les articles équipés se reflètent dans la tenue', () async {
      final c = await _ready();
      final n = c.read(wardrobeControllerProvider.notifier);
      await n.debugGrant(400);
      await n.buy(WardrobeCatalog.explorer);
      await n.buy(WardrobeCatalog.moss);
      await n.buy(WardrobeCatalog.pennantGold);

      final outfit = c.read(pipOutfitProvider);

      expect(outfit.hat, PipHat.explorer);
      expect(outfit.bodyTop, WardrobeCatalog.moss.palette!.top);
      expect(outfit.pennant, WardrobeCatalog.pennantGold.color);
    });

    test('un article possédé mais non équipé n\'est pas porté', () async {
      final c = await _ready();
      final n = c.read(wardrobeControllerProvider.notifier);
      await n.debugGrant(400);
      await n.buy(WardrobeCatalog.beanie);
      await n.buy(WardrobeCatalog.straw);
      await n.equip(WardrobeCatalog.beanie);

      expect(c.read(pipOutfitProvider).hat, PipHat.beanie);
    });
  });
}
