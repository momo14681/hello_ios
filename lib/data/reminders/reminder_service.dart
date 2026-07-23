/// Rappels de fin de session.
///
/// Les **notifications locales** fonctionnent sur un compte Apple gratuit, à la
/// différence des notifications distantes. C'est ce qui permet à Cairn de
/// prévenir l'utilisateur app fermée sans aucun serveur.
abstract interface class ReminderService {
  Future<void> init();

  /// Demande l'autorisation. Renvoie `false` si elle est refusée ou
  /// indisponible sur la plateforme.
  Future<bool> requestPermission();

  /// Programme la notification de fin pour l'instant [at].
  Future<void> scheduleSessionEnd(DateTime at, Duration planned);

  /// Annule le rappel en cours — session abandonnée ou terminée en avance.
  Future<void> cancel();
}
