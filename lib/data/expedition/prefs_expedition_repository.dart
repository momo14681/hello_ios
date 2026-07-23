import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/expedition.dart';
import 'expedition_repository.dart';

/// Avancement stocké en JSON dans les préférences.
///
/// Le volume est minuscule — un itinéraire actif et une liste de cairns — et
/// aucune requête n'est nécessaire : tout est chargé d'un bloc au démarrage.
/// Drift viendra quand les statistiques exigeront des agrégats, pas avant.
/// Voir docs/DEV.md.
class PrefsExpeditionRepository implements ExpeditionRepository {
  PrefsExpeditionRepository();

  static const _activeKey = 'cairn.active_expedition';
  static const _progressPrefix = 'cairn.progress.';

  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  @override
  Future<String?> activeExpeditionId() async =>
      (await _prefs).getString(_activeKey);

  @override
  Future<void> setActiveExpedition(String id) async =>
      (await _prefs).setString(_activeKey, id);

  @override
  Future<ExpeditionProgress?> load(String expeditionId) async {
    final raw = (await _prefs).getString('$_progressPrefix$expeditionId');
    if (raw == null) return null;
    try {
      return ExpeditionProgress.fromJson(
        Map<String, Object?>.from(jsonDecode(raw) as Map),
      );
    } on FormatException {
      // Donnée corrompue : on repart de zéro plutôt que de bloquer l'app.
      return null;
    }
  }

  @override
  Future<void> save(ExpeditionProgress progress) async => (await _prefs)
      .setString(
        '$_progressPrefix${progress.expeditionId}',
        jsonEncode(progress.toJson()),
      );
}

/// Dépôt en mémoire, pour les tests.
class InMemoryExpeditionRepository implements ExpeditionRepository {
  InMemoryExpeditionRepository({String? active}) : _active = active;

  String? _active;
  final _store = <String, ExpeditionProgress>{};

  @override
  Future<String?> activeExpeditionId() async => _active;

  @override
  Future<void> setActiveExpedition(String id) async => _active = id;

  @override
  Future<ExpeditionProgress?> load(String expeditionId) async =>
      _store[expeditionId];

  @override
  Future<void> save(ExpeditionProgress progress) async =>
      _store[progress.expeditionId] = progress;
}
