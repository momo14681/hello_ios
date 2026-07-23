import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/expedition/expedition_catalog.dart';
import '../../data/wardrobe/wardrobe_catalog.dart';
import '../../design/content_width.dart';
import '../../design/tokens.dart';
import '../../domain/expedition.dart';
import '../../domain/wardrobe.dart';
import '../wardrobe/wardrobe_controller.dart';
import 'expedition_controller.dart';
import 'trail_painter.dart';

/// La carte de l'expédition.
///
/// C'est ici que vit l'arc long : on voit d'un coup d'œil le chemin parcouru,
/// les cairns accumulés, et surtout **ce qui reste avant la prochaine étape**.
class MapScreen extends ConsumerWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(expeditionControllerProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F1E6),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(async.value?.expedition.name ?? 'Expédition'),
        actions: [
          IconButton(
            tooltip: 'Changer d\'itinéraire',
            onPressed: () => showModalBottomSheet<void>(
              context: context,
              showDragHandle: true,
              backgroundColor: AppColors.surfaceRaised,
              builder: (_) => const _ExpeditionPicker(),
            ),
            icon: const Icon(Icons.swap_horiz_rounded),
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
      ),
      body: switch (async) {
        AsyncData(:final value) => _Loaded(
          view: value,
          outfit: ref.watch(pipOutfitProvider),
        ),
        AsyncError(:final error) => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Text('Carte indisponible : $error'),
          ),
        ),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}

/// Le choix de l'itinéraire.
///
/// Il vit sur la carte, pas dans la boutique : c'est là qu'on regarde son
/// chemin, donc là qu'on a envie d'en changer. La boutique ne fait que
/// débloquer.
class _ExpeditionPicker extends ConsumerWidget {
  const _ExpeditionPicker();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inventory = ref.watch(wardrobeControllerProvider).value;
    final activeId = ref
        .watch(expeditionControllerProvider)
        .value
        ?.expedition
        .id;

    return SafeArea(
      child: ContentWidth(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final expedition in ExpeditionCatalog.all)
              _ExpeditionTile(
                expedition: expedition,
                active: expedition.id == activeId,
                unlocked: inventory == null
                    ? expedition.id == ExpeditionCatalog.initial.id
                    : WardrobeCatalog.ownsExpedition(inventory, expedition.id),
                onPick: () async {
                  await ref
                      .read(expeditionControllerProvider.notifier)
                      .selectExpedition(expedition.id);
                  if (context.mounted) Navigator.of(context).pop();
                },
              ),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );
  }
}

class _ExpeditionTile extends StatelessWidget {
  const _ExpeditionTile({
    required this.expedition,
    required this.active,
    required this.unlocked,
    required this.onPick,
  });

  final Expedition expedition;
  final bool active;
  final bool unlocked;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) => ListTile(
    enabled: unlocked,
    leading: Icon(
      unlocked ? Icons.terrain_rounded : Icons.lock_outline_rounded,
      color: active ? AppColors.premium : AppColors.inkSoft,
    ),
    title: Text(
      expedition.name,
      style: TextStyle(fontWeight: active ? FontWeight.w500 : FontWeight.w400),
    ),
    subtitle: Text(
      unlocked
          ? '${expedition.subtitle} · ${(expedition.totalMeters / 1000).round()} km'
          : 'À débloquer dans la garde-robe',
    ),
    trailing: active
        ? const Icon(Icons.check_rounded, color: AppColors.premium)
        : null,
    onTap: unlocked && !active ? onPick : null,
  );
}

class _Loaded extends StatefulWidget {
  const _Loaded({required this.view, required this.outfit});

  final ExpeditionView view;
  final PipOutfit outfit;

  @override
  State<_Loaded> createState() => _LoadedState();
}

class _LoadedState extends State<_Loaded> with SingleTickerProviderStateMixin {
  late final Ticker _ticker = createTicker((elapsed) {
    setState(() => _time = elapsed.inMicroseconds / 1e6);
  })..start();

  double _time = 0;

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final v = widget.view;

    return Column(
      children: [
        Expanded(
          child: RepaintBoundary(
            child: CustomPaint(
              size: Size.infinite,
              painter: TrailPainter(
                view: v,
                time: _time,
                outfit: widget.outfit,
              ),
            ),
          ),
        ),
        _Summary(view: v),
      ],
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.view});

  final ExpeditionView view;

  @override
  Widget build(BuildContext context) {
    final next = view.nextLeg;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      decoration: const BoxDecoration(color: AppColors.surfaceRaised),
      child: SafeArea(
        top: false,
        child: ContentWidth(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                next == null
                    ? 'Expédition terminée'
                    : '${_km(view.metersToNextLeg)} avant ${next.name}',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                '${_km(view.travelledMeters)} sur ${_km(view.totalMeters)} · '
                '${view.cairns.length} cairn${view.cairns.length > 1 ? 's' : ''}',
                style: const TextStyle(color: AppColors.inkSoft),
              ),
              const SizedBox(height: AppSpacing.md),
              ClipRRect(
                borderRadius: const BorderRadius.all(Radius.circular(6)),
                child: LinearProgressIndicator(
                  value: view.fraction,
                  minHeight: 7,
                  backgroundColor: AppColors.ink.withValues(alpha: 0.1),
                  valueColor: const AlwaysStoppedAnimation(
                    AppColors.pipPennant,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: AppDurations.base);
  }

  static String _km(double meters) => meters >= 1000
      ? '${(meters / 1000).toStringAsFixed(1)} km'
      : '${meters.round()} m';
}
