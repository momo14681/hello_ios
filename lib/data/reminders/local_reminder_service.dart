import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import 'reminder_service.dart';

/// Rappels par notification locale.
///
/// Aucun serveur, aucun compte payant : c'est le seul canal de notification
/// disponible sur un compte Apple gratuit.
///
/// **Aucune méthode ne lève jamais.** Le rappel est un confort ; s'il échoue,
/// la session doit démarrer quand même.
///
/// Note d'API : depuis la version 22 du greffon, `initialize`, `zonedSchedule`
/// et `cancel` prennent des paramètres **nommés**. Les exemples encore en
/// circulation utilisent l'ancienne forme positionnelle.
class LocalReminderService implements ReminderService {
  LocalReminderService();

  static const _endId = 1;
  static const _runningId = 2;
  static const _testId = 3;

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

      // **Indispensable.** Sans cette ligne, `tz.local` reste UTC et une
      // notification programmée pour 18 h part à 18 h UTC — deux heures trop
      // tard en France l'été. C'est l'erreur classique du paquet `timezone`,
      // et elle est silencieuse : rien n'échoue, la notification n'arrive
      // simplement jamais au bon moment.
      final name = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(name.identifier));

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

  IOSFlutterLocalNotificationsPlugin? get _ios => _plugin
      .resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin
      >();

  AndroidFlutterLocalNotificationsPlugin? get _android => _plugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();

  @override
  Future<bool> requestPermission() async {
    await init();
    if (!_ready) return false;

    try {
      final ios = _ios;
      if (ios != null) {
        return await ios.requestPermissions(alert: true, sound: true) ?? false;
      }
      final android = _android;
      if (android != null) {
        return await android.requestNotificationsPermission() ?? false;
      }
    } catch (error, stack) {
      _fail('demande d\'autorisation', error, stack);
    }
    return false;
  }

  @override
  Future<bool?> hasPermission() async {
    await init();
    if (!_ready) return null;

    try {
      final android = _android;
      if (android != null) return await android.areNotificationsEnabled();
      // iOS ne sait pas répondre sans redemander : `requestPermissions`
      // renvoie l'état accordé sans réafficher la boîte de dialogue une fois
      // la décision prise.
      final ios = _ios;
      if (ios != null) {
        return await ios.requestPermissions(alert: true, sound: true);
      }
    } catch (error, stack) {
      _fail('lecture de l\'autorisation', error, stack);
    }
    return null;
  }

  @override
  Future<void> scheduleSessionEnd(DateTime at, Duration planned) async {
    await init();
    if (!_ready) return;

    try {
      await cancel();
      await _plugin.zonedSchedule(
        id: _endId,
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

  /// La notification permanente à décompte, façon minuteur vivant.
  ///
  /// `usesChronometer` + `chronometerCountDown` + `when` font décompter Android
  /// tout seul, sans qu'on ait à republier la notification chaque seconde.
  @override
  Future<void> showRunning({
    required DateTime endsAt,
    required Duration planned,
    Uint8List? avatar,
  }) async {
    await init();
    if (!_ready) return;
    if (defaultTargetPlatform != TargetPlatform.android) return;

    try {
      await _plugin.show(
        id: _runningId,
        title: 'Pip est en route',
        body: '${planned.inMinutes} minutes de concentration',
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            'cairn_running',
            'Session en cours',
            channelDescription:
                'Affiche le décompte pendant une session de concentration',
            importance: Importance.low,
            priority: Priority.low,
            ongoing: true,
            autoCancel: false,
            onlyAlertOnce: true,
            showWhen: true,
            when: endsAt.millisecondsSinceEpoch,
            usesChronometer: true,
            chronometerCountDown: true,
            playSound: false,
            enableVibration: false,
            largeIcon: avatar == null ? null : ByteArrayAndroidBitmap(avatar),
          ),
        ),
      );
    } catch (error, stack) {
      _fail('notification de session', error, stack);
    }
  }

  @override
  Future<void> clearRunning() async {
    if (!_ready) return;
    try {
      await _plugin.cancel(id: _runningId);
    } catch (error, stack) {
      _fail('retrait de la notification de session', error, stack);
    }
  }

  @override
  Future<void> cancel() async {
    if (!_ready) return;
    try {
      await _plugin.cancel(id: _endId);
    } catch (error, stack) {
      _fail('annulation du rappel', error, stack);
    }
  }

  @override
  Future<void> sendTestNotification() async {
    await init();
    if (!_ready) return;

    try {
      await _plugin.zonedSchedule(
        id: _testId,
        title: 'Cairn — test',
        body: 'Si tu lis ceci, les notifications fonctionnent.',
        scheduledDate: tz.TZDateTime.now(tz.local).add(
          const Duration(seconds: 10),
        ),
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
      _fail('notification de test', error, stack);
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
