import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hello_ios/data/expedition/prefs_expedition_repository.dart';
import 'package:hello_ios/data/reminders/noop_reminder_service.dart';
import 'package:hello_ios/data/reminders/reminder_providers.dart';
import 'package:hello_ios/data/reminders/reminder_service.dart';
import 'package:hello_ios/design/theme.dart';
import 'package:hello_ios/data/wardrobe/wardrobe_repository.dart';
import 'package:hello_ios/features/expedition/expedition_controller.dart';
import 'package:hello_ios/features/wardrobe/wardrobe_controller.dart';
import 'package:hello_ios/features/session/session_screen.dart';

/// Reproduit une plateforme où le greffon de notification refuse de
/// s'initialiser — le cas Windows qui rendait le bouton « Partir » inerte.
class _BrokenReminderService implements ReminderService {
  const _BrokenReminderService();

  Never _boom() => throw StateError('notifications indisponibles');

  @override
  Future<void> init() async => _boom();

  @override
  Future<bool> requestPermission() async => _boom();

  @override
  Future<void> scheduleSessionEnd(DateTime at, Duration planned) async =>
      _boom();

  @override
  Future<void> cancel() async => _boom();
}

Widget _app({ReminderService reminders = const NoopReminderService()}) =>
    ProviderScope(
  overrides: [
    reminderServiceProvider.overrideWith((ref) => reminders),
    expeditionRepositoryProvider.overrideWith(
      (ref) => InMemoryExpeditionRepository(),
    ),
    wardrobeRepositoryProvider.overrideWith(
      (ref) => InMemoryWardrobeRepository(),
    ),
  ],
  child: MaterialApp(theme: buildAppTheme(), home: const SessionScreen()),
);

/// Cadre le test sur un portrait de téléphone.
///
/// Le gabarit de test par défaut est un 800×600 paysage, où le panneau de
/// session n'a pas la place de tenir.
void _phone(WidgetTester tester) {
  tester.view.physicalSize = const Size(400, 880);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

void main() {
  setUpAll(() {
    // Sans ça, google_fonts tente d'aller chercher les polices sur le réseau
    // pendant les tests.
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('le parcours abandon enchaîne partir → camper → repartir', (
    tester,
  ) async {
    _phone(tester);
    await tester.pumpWidget(_app());
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Partir'), findsOneWidget);
    expect(find.text('25 min'), findsOneWidget);

    await tester.tap(find.text('Partir'));
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Camper'), findsOneWidget);
    expect(find.text('Partir'), findsNothing);

    await tester.tap(find.text('Camper'));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Pip a monté le camp'), findsOneWidget);

    await tester.tap(find.text('Repartir'));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Partir'), findsOneWidget);

    await _teardown(tester);
  });

  testWidgets('la session démarre même si les notifications échouent', (
    tester,
  ) async {
    _phone(tester);
    await tester.pumpWidget(_app(reminders: const _BrokenReminderService()));
    await tester.pump(const Duration(milliseconds: 400));

    await tester.tap(find.text('Partir'));
    await tester.pump(const Duration(milliseconds: 400));

    expect(
      find.text('Camper'),
      findsOneWidget,
      reason: 'un rappel indisponible ne doit jamais bloquer le départ',
    );

    await _teardown(tester);
  });

  testWidgets('le panneau reste en bas et ne mange pas l\'écran', (
    tester,
  ) async {
    _phone(tester);
    await tester.pumpWidget(_app());
    await tester.pump(const Duration(milliseconds: 400));

    final height = tester.view.physicalSize.height / tester.view.devicePixelRatio;

    // Sans borne de hauteur, `Center` s'étirait et le panneau devenait un
    // rectangle plein écran, les commandes remontant tout en haut.
    expect(
      tester.getTopLeft(find.text('15 min')).dy,
      greaterThan(height * 0.55),
      reason: 'les commandes doivent rester dans la moitié basse',
    );

    // Même piège pendant la session : `Align` s'étirait et « Camper » se
    // retrouvait centré au milieu de l'écran.
    await tester.tap(find.text('Partir'));
    await tester.pump(const Duration(milliseconds: 400));

    expect(
      tester.getTopLeft(find.text('Camper')).dy,
      greaterThan(height * 0.8),
      reason: 'le bouton Camper doit rester en bas',
    );

    await _teardown(tester);
  });

  testWidgets('choisir une autre durée met à jour la sélection', (
    tester,
  ) async {
    _phone(tester);
    await tester.pumpWidget(_app());
    await tester.pump(const Duration(milliseconds: 400));

    await tester.tap(find.text('45 min'));
    await tester.pump(const Duration(milliseconds: 300));

    final chip = tester.widget<ChoiceChip>(
      find.widgetWithText(ChoiceChip, '45 min'),
    );
    expect(chip.selected, isTrue);

    await _teardown(tester);
  });
}

/// Démonte l'arbre avant la fin du test.
///
/// `SessionScreen` entretient un `Timer.periodic` pour rafraîchir l'affichage ;
/// sans démontage explicite, le framework de test signale un timer encore en
/// attente.
Future<void> _teardown(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump(const Duration(milliseconds: 300));
}
