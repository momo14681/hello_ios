import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'local_reminder_service.dart';
import 'noop_reminder_service.dart';
import 'reminder_service.dart';

/// Le service de rappel adapté à la plateforme.
///
/// Le web n'a pas d'implémentation de `flutter_local_notifications` : on y
/// bascule sur la version inerte pour que la boucle de développement dans
/// Chrome reste utilisable.
final reminderServiceProvider = Provider<ReminderService>((ref) {
  if (kIsWeb) return const NoopReminderService();
  return LocalReminderService();
});
