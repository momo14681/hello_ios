import '../../domain/expedition.dart';

/// Persistance de l'avancement.
///
/// Seul l'avancement est stocké : la définition des itinéraires est du code,
/// dans `ExpeditionCatalog`.
abstract interface class ExpeditionRepository {
  Future<String?> activeExpeditionId();
  Future<void> setActiveExpedition(String id);
  Future<ExpeditionProgress?> load(String expeditionId);
  Future<void> save(ExpeditionProgress progress);
}
