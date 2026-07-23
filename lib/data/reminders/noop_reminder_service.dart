import 'reminder_service.dart';

/// Implémentation inerte, pour le web et les tests.
///
/// `flutter_local_notifications` n'a pas d'implémentation web : appeler le
/// greffon depuis Chrome lèverait une `MissingPluginException`. Comme le web
/// est la cible de développement principale tant que la chaîne C++ de Visual
/// Studio n'est pas installée, cette version évite de casser la boucle de
/// travail.
class NoopReminderService implements ReminderService {
  const NoopReminderService();

  @override
  Future<void> init() async {}

  @override
  Future<bool> requestPermission() async => false;

  @override
  Future<void> scheduleSessionEnd(DateTime at, Duration planned) async {}

  @override
  Future<void> cancel() async {}
}
