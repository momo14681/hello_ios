import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/purchase/fake_purchase_service.dart';
import '../../data/purchase/purchase_providers.dart';
import '../../data/purchase/purchase_service.dart';
import '../../data/reminders/reminder_providers.dart';
import '../../data/wardrobe/wardrobe_catalog.dart';
import '../../design/content_width.dart';
import '../../design/tokens.dart';
import '../../domain/wardrobe.dart';
import '../../world/pip/pip_painter.dart';
import '../../world/pip/pip_params.dart';
import '../expedition/expedition_controller.dart';
import 'wardrobe_controller.dart';

/// La boutique et la garde-robe.
///
/// Les éclats se gagnent en menant des sessions à terme. Rien ne s'achète avec
/// de l'argent réel ici : l'abonnement Cairn+ ouvre les itinéraires
/// immédiatement, les éclats permettent d'y arriver en jouant.
class ShopScreen extends ConsumerWidget {
  const ShopScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(wardrobeControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Garde-robe'),
        actions: [
          if (async.value != null) _Purse(shards: async.value!.shards),
          if (kDebugMode) const _DebugActions(),
          const SizedBox(width: AppSpacing.sm),
        ],
      ),
      body: switch (async) {
        AsyncData(:final value) => _Loaded(inventory: value),
        AsyncError(:final error) => Center(
          child: Text('Indisponible : $error'),
        ),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}

/// Raccourcis de développement : bourse, abonnement, notification de test.
///
/// Sans eux, éprouver la boutique demanderait des heures de concentration
/// réelles, et vérifier une notification, d'attendre la fin d'une session.
class _DebugActions extends ConsumerWidget {
  const _DebugActions();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plus = ref.watch(isPlusProvider);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextButton.icon(
          onPressed: () {
            final service = ref.read(purchaseServiceProvider);
            if (service is FakePurchaseService) {
              service.debugSet(plus ? Entitlement.free : Entitlement.plus);
            }
          },
          icon: Icon(
            plus ? Icons.workspace_premium : Icons.workspace_premium_outlined,
            size: 18,
          ),
          label: Text(plus ? 'Cairn+ actif' : 'Cairn+'),
          style: TextButton.styleFrom(
            foregroundColor: plus ? AppColors.premium : AppColors.inkSoft,
          ),
        ),
        IconButton(
          tooltip: 'Notification de test dans 10 s',
          onPressed: () async {
            await ref.read(reminderServiceProvider).requestPermission();
            await ref.read(reminderServiceProvider).sendTestNotification();
            if (!context.mounted) return;
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                const SnackBar(
                  content: Text('Notification de test dans 10 secondes'),
                ),
              );
          },
          icon: const Icon(Icons.notifications_active_outlined),
        ),
        IconButton(
          tooltip: 'Créditer 250 éclats',
          onPressed: () =>
              ref.read(wardrobeControllerProvider.notifier).debugGrant(250),
          icon: const Icon(Icons.add_circle_outline),
        ),
      ],
    );
  }
}

class _Purse extends StatelessWidget {
  const _Purse({required this.shards});

  final int shards;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: AppColors.premium.withValues(alpha: 0.18),
      borderRadius: const BorderRadius.all(AppRadii.control),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.diamond_outlined, size: 16, color: AppColors.ink),
        const SizedBox(width: 6),
        Text(
          '$shards',
          style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
        ),
      ],
    ),
  );
}

class _Loaded extends ConsumerStatefulWidget {
  const _Loaded({required this.inventory});

  final Inventory inventory;

  @override
  ConsumerState<_Loaded> createState() => _LoadedState();
}

class _LoadedState extends ConsumerState<_Loaded>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker = createTicker((elapsed) {
    setState(() => _time = elapsed.inMicroseconds / 1e6);
  })..start();

  double _time = 0;

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  Future<void> _tap(ShopItem item) async {
    final controller = ref.read(wardrobeControllerProvider.notifier);
    final inventory = widget.inventory;

    if (!inventory.has(item.id)) {
      final outcome = await controller.buy(item);
      if (!mounted) return;
      if (outcome == PurchaseOutcome.tooExpensive) {
        _say('Il te manque ${item.price - inventory.shards} éclats.');
      }
      return;
    }

    if (item.kind == ItemKind.expedition) {
      final id = item.expeditionId;
      if (id == null) return;
      await ref
          .read(expeditionControllerProvider.notifier)
          .selectExpedition(id);
      if (!mounted) return;
      _say('${item.name} : itinéraire en cours.');
      return;
    }

    await controller.equip(item);
  }

  void _say(String message) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));

  @override
  Widget build(BuildContext context) {
    final outfit = WardrobeCatalog.outfitOf(widget.inventory);
    final plus = ref.watch(isPlusProvider);

    return ContentWidth(
      max: 620,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          0,
          AppSpacing.md,
          AppSpacing.xl,
        ),
        children: [
          _Preview(outfit: outfit, time: _time),
          for (final kind in ItemKind.values) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xs,
                AppSpacing.lg,
                0,
                AppSpacing.sm,
              ),
              child: Text(
                kind.label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.inkSoft,
                  letterSpacing: 0.4,
                ),
              ),
            ),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final item in WardrobeCatalog.of(kind))
                  _ItemCard(
                    item: item,
                    inventory: widget.inventory,
                    plus: plus,
                    onTap: () => _tap(item),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _Preview extends StatelessWidget {
  const _Preview({required this.outfit, required this.time});

  final PipOutfit outfit;
  final double time;

  @override
  Widget build(BuildContext context) => Container(
    height: 210,
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFE7EDF4), Color(0xFFF7F1E6)],
      ),
      borderRadius: const BorderRadius.all(AppRadii.card),
    ),
    child: CustomPaint(
      size: Size.infinite,
      painter: PipPainter(
        time: time,
        pose: PipPose.idle,
        params: const PipParams(scale: 2.2),
        // Lanterne allumée dans l'aperçu : on n'achète pas un objet qu'on ne
        // voit pas.
        lanternLit: 1,
        outfit: outfit,
      ),
    ),
  );
}

class _ItemCard extends StatelessWidget {
  const _ItemCard({
    required this.item,
    required this.inventory,
    required this.plus,
    required this.onTap,
  });

  final ShopItem item;
  final Inventory inventory;
  final bool plus;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // Cairn+ ouvre tous les itinéraires sans les acheter.
    final owned =
        inventory.has(item.id) ||
        (plus && item.kind == ItemKind.expedition);
    final equipped = inventory.isEquipped(item);
    final affordable = inventory.canAfford(item);

    return SizedBox(
      width: 178,
      // Hauteur fixe : sans elle, un titre sur deux lignes décale toute la
      // rangée.
      height: item.kind == ItemKind.palette || item.color != null ? 104 : 78,
      child: Material(
        color: equipped
            ? AppColors.premium.withValues(alpha: 0.16)
            : AppColors.surfaceRaised,
        borderRadius: const BorderRadius.all(AppRadii.control),
        child: InkWell(
          onTap: onTap,
          borderRadius: const BorderRadius.all(AppRadii.control),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.sm + 2),
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.all(AppRadii.control),
              border: Border.all(
                color: equipped
                    ? AppColors.premium
                    : AppColors.ink.withValues(alpha: 0.1),
                width: equipped ? 1.6 : 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (item.color != null || item.palette != null)
                  _Swatch(item: item),
                Text(
                  item.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _status(owned, equipped),
                  style: TextStyle(
                    fontSize: 12.5,
                    color: !owned && !affordable
                        ? AppColors.inkSoft.withValues(alpha: 0.6)
                        : AppColors.inkSoft,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _status(bool owned, bool equipped) {
    if (item.kind == ItemKind.expedition && plus && !inventory.has(item.id)) {
      return 'Inclus dans Cairn+';
    }
    if (equipped) return 'Porté';
    if (owned) {
      return item.kind == ItemKind.expedition ? 'Débloqué' : 'Possédé';
    }
    return '${item.price} éclats';
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({required this.item});

  final ShopItem item;

  @override
  Widget build(BuildContext context) {
    final palette = item.palette;
    final colors = palette != null
        ? [palette.top, palette.bottom, palette.detail]
        : [item.color!];

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          for (final c in colors)
            Container(
              width: 18,
              height: 18,
              margin: const EdgeInsets.only(right: 4),
              decoration: BoxDecoration(
                color: c,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.ink.withValues(alpha: 0.12),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
