import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/expedition/expedition_catalog.dart';
import '../../data/expedition/expedition_repository.dart';
import '../../data/expedition/prefs_expedition_repository.dart';
import '../../domain/expedition.dart';

final expeditionRepositoryProvider = Provider<ExpeditionRepository>(
  (ref) => PrefsExpeditionRepository(),
);

/// L'expédition en cours et son avancement.
///
/// C'est **l'arc long** de Cairn — ce qui donne une raison de rouvrir l'app
/// demain, et ce qui manque structurellement à une app où chaque session est
/// un objet isolé. Voir CONCEPT.md §4.
class ExpeditionController extends AsyncNotifier<ExpeditionView> {
  @override
  Future<ExpeditionView> build() async {
    final repo = ref.watch(expeditionRepositoryProvider);
    final id = await repo.activeExpeditionId() ?? ExpeditionCatalog.initial.id;
    final progress =
        await repo.load(id) ?? ExpeditionProgress(expeditionId: id);

    return ExpeditionView(
      expedition: ExpeditionCatalog.byId(id),
      progress: progress,
    );
  }

  /// Enregistre une session menée à terme : la distance avance et un cairn est
  /// posé. Renvoie les étapes **nouvellement** franchies, pour que l'interface
  /// puisse les célébrer.
  Future<List<Leg>> recordSession({
    required double meters,
    required int stones,
    required DateTime at,
  }) async {
    final current = state.value;
    if (current == null) return const [];

    final reachedBefore = current.reachedLegs.length;
    final travelled = current.travelledMeters + meters;

    final next = current.progress.copyWith(
      travelledMeters: travelled,
      cairns: [
        ...current.cairns,
        Cairn(atMeters: travelled, placedAt: at, stones: stones),
      ],
    );

    return _commit(current.withProgress(next), reachedBefore);
  }

  /// Session abandonnée : la distance parcourue reste acquise, mais aucun
  /// cairn n'est posé. Jamais punitif — voir CONCEPT.md §2.
  Future<List<Leg>> recordAbandoned(double meters) async {
    final current = state.value;
    if (current == null) return const [];

    final reachedBefore = current.reachedLegs.length;
    final next = current.progress.copyWith(
      travelledMeters: current.travelledMeters + meters,
    );

    return _commit(current.withProgress(next), reachedBefore);
  }

  Future<void> selectExpedition(String id) async {
    final repo = ref.read(expeditionRepositoryProvider);
    await repo.setActiveExpedition(id);
    final progress =
        await repo.load(id) ?? ExpeditionProgress(expeditionId: id);

    state = AsyncData(
      ExpeditionView(
        expedition: ExpeditionCatalog.byId(id),
        progress: progress,
      ),
    );
  }

  Future<List<Leg>> _commit(ExpeditionView updated, int reachedBefore) async {
    await ref.read(expeditionRepositoryProvider).save(updated.progress);
    state = AsyncData(updated);
    return updated.reachedLegs.sublist(reachedBefore);
  }
}

final expeditionControllerProvider =
    AsyncNotifierProvider<ExpeditionController, ExpeditionView>(
      ExpeditionController.new,
    );
