import 'dart:typed_data';

import 'reminder_service.dart';

/// Implémentation inerte, pour le web et les tests.
///
/// `flutter_local_notifications` expose bien une implémentation web depuis la
/// v22, mais une notification planifiée n'y part pas de façon fiable quand
/// l'onglet passe en arrière-plan — mieux vaut ne rien promettre.
class NoopReminderService implements ReminderService {
  const NoopReminderService();

  @override
  Future<void> init() async {}

  @override
  Future<bool> requestPermission() async => false;

  @override
  Future<bool?> hasPermission() async => null;

  @override
  Future<void> scheduleSessionEnd(DateTime at, Duration planned) async {}

  @override
  Future<void> showRunning({
    required DateTime endsAt,
    required Duration planned,
    Uint8List? avatar,
  }) async {}

  @override
  Future<void> clearRunning() async {}

  @override
  Future<void> cancel() async {}

  @override
  Future<void> sendTestNotification() async {}
}
