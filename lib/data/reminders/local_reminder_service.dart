import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import 'reminder_service.dart';

/// Rappel de fin de session par notification locale.
///
/// Aucun serveur, aucun compte payant : c'est le seul canal de notification
/// disponible sur un compte Apple gratuit.
///
/// **Aucune méthode ne lève jamais.** Le rappel est un confort ; s'il échoue,
/// la session doit démarrer quand même. C'est exactement ce qui s'est produit
/// sur Windows : `initialize` exigeait des réglages `windows` absents, levait
/// une `ArgumentError`, et le bouton « Partir » restait sans effet.
///
/// Note d'API : depuis la version 22 du greffon, `initialize`, `zonedSchedule`
/// et `cancel` prennent des paramètres **nommés**. Les exemples encore en
/// circulation utilisent l'ancienne forme positionnelle.
class LocalReminderService implements ReminderService {
  LocalReminderService();

  static const _id = 1;

  /// Identifiant d'activation Windows. Doit rester stable entre les versions.
  static const _windowsGuid = '4f4d8a1c-9d4e-4f77-9c2b-8a1d3f6e5b20';

  final _plugin = FlutterLocalNotificationsPlugin();
  var _ready = false;
  var _broken = false;

  @override
  Future<void> init() async {
    if (_ready || _broken) return;

    try {
      tzdata.initializeTimeZones();

      await _plugin.initialize(
        settings: const InitializationSettings(
          iOS: DarwinInitializationSettings(
            requestAlertPermission: false,
            requestBadgePermission: false,
            requestSoundPermission: false,
          ),
          macOS: DarwinInitializationSettings(
            requestAlertPermission: false,
            requestBadgePermission: false,
            requestSoundPermission: false,
          ),
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          linux: LinuxInitializationSettings(defaultActionName: 'Ouvrir Cairn'),
          windows: WindowsInitializationSettings(
            appName: 'Cairn',
            appUserModelId: 'Cairn.Focus.Expedition',
            guid: _windowsGuid,
          ),
        ),
      );

      _ready = true;
    } catch (error, stack) {
      _fail('initialisation', error, stack);
    }
  }

  @override
  Future<bool> requestPermission() async {
    await init();
    if (!_ready) return false;

    try {
      final ios = _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();
      if (ios != null) {
        return await ios.requestPermissions(alert: true, sound: true) ?? false;
      }

      final android = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      if (android != null) {
        return await android.requestNotificationsPermission() ?? false;
      }
    } catch (error, stack) {
      _fail('demande d\'autorisation', error, stack);
    }

    return false;
  }

  @override
  Future<void> scheduleSessionEnd(DateTime at, Duration planned) async {
    await init();
    if (!_ready) return;

    try {
      await cancel();
      await _plugin.zonedSchedule(
        id: _id,
        title: 'Pip est arrivé',
        body:
            '${planned.inMinutes} minutes de concentration. '
            'Le cairn t\'attend.',
        scheduledDate: tz.TZDateTime.from(at, tz.local),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        notificationDetails: const NotificationDetails(
          iOS: DarwinNotificationDetails(presentAlert: true, presentSound: true),
          macOS: DarwinNotificationDetails(
            presentAlert: true,
            presentSound: true,
          ),
          android: AndroidNotificationDetails(
            'cairn_session',
            'Fin de session',
            channelDescription:
                'Prévient quand la session de concentration est terminée',
            importance: Importance.high,
          ),
        ),
      );
    } catch (error, stack) {
      _fail('programmation du rappel', error, stack);
    }
  }

  @override
  Future<void> cancel() async {
    if (!_ready) return;
    try {
      await _plugin.cancel(id: _id);
    } catch (error, stack) {
      _fail('annulation du rappel', error, stack);
    }
  }

  /// Désactive le service pour la suite : inutile de retenter à chaque session
  /// si la plateforme ne veut pas de nous.
  void _fail(String step, Object error, StackTrace stack) {
    _broken = true;
    if (kDebugMode) {
      debugPrint('Cairn — rappel indisponible ($step) : $error');
    }
  }
}
