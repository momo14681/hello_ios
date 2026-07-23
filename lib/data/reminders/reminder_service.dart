import 'dart:typed_data';

/// Rappels et notification de session.
///
/// Les **notifications locales** fonctionnent sur un compte Apple gratuit, à la
/// différence des notifications distantes. C'est ce qui permet à Cairn de
/// prévenir l'utilisateur app fermée sans aucun serveur.
abstract interface class ReminderService {
  Future<void> init();

  /// Demande l'autorisation. Renvoie `false` si elle est refusée ou
  /// indisponible sur la plateforme.
  Future<bool> requestPermission();

  /// Autorisation déjà accordée ? `null` si la plateforme ne sait pas répondre.
  Future<bool?> hasPermission();

  /// Programme la notification de fin pour l'instant [at].
  Future<void> scheduleSessionEnd(DateTime at, Duration planned);

  /// Notification permanente affichant le décompte pendant la session.
  ///
  /// **Android uniquement.** iOS n'a pas de notification persistante : son
  /// équivalent est la Live Activity, qui exige une extension SwiftUI.
  /// [avatar] est un PNG de Pip, affiché en grande icône.
  Future<void> showRunning({
    required DateTime endsAt,
    required Duration planned,
    Uint8List? avatar,
  });

  /// Retire la notification permanente.
  Future<void> clearRunning();

  /// Annule le rappel de fin — session abandonnée ou terminée en avance.
  Future<void> cancel();

  /// Envoie une notification dans quelques secondes, pour vérifier que la
  /// chaîne fonctionne de bout en bout sur un appareil réel.
  Future<void> sendTestNotification();
}
