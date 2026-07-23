import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hello_ios/data/expedition/expedition_catalog.dart';
import 'package:hello_ios/data/expedition/prefs_expedition_repository.dart';
import 'package:hello_ios/data/reminders/noop_reminder_service.dart';
import 'package:hello_ios/data/wardrobe/wardrobe_repository.dart';
import 'package:hello_ios/data/reminders/reminder_providers.dart';
import 'package:hello_ios/features/expedition/expedition_controller.dart';
import 'package:hello_ios/features/session/session_controller.dart';
import 'package:hello_ios/features/wardrobe/wardrobe_controller.dart';
import 'package:hello_ios/world/pip/pip_params.dart';
import 'package:hello_ios/world/pip/reaction_director.dart';

/// Un conteneur dont l'expédition est déjà chargée, avec un dépôt en mémoire.
Future<ProviderContainer> _ready({
  InMemoryExpeditionRepository? repository,
}) async {
  final c = ProviderContainer(
    overrides: [
      reminderServiceProvider.overrideWith(
        (ref) => const NoopReminderService(),
      ),
      expeditionRepositoryProvider.overrideWith(
        (ref) => repository ?? InMemoryExpeditionRepository(),
      ),
      wardrobeRepositoryProvider.overrideWith(
        (ref) => InMemoryWardrobeRepository(),
      ),
    ],
  );
  addTearDown(c.dispose);
  await c.read(expeditionControllerProvider.future);
  await c.read(wardrobeControllerProvider.future);
  return c;
}

void main() {
  group('ReactionDirector', () {
    const planned = Duration(minutes: 25);

    test('le plan est déterministe pour une graine donnée', () {
      final a = ReactionDirector(seed: 1234, planned: planned).events;
      final b = ReactionDirector(seed: 1234, planned: planned).events;

      expect(a.length, b.length);
      for (var i = 0; i < a.length; i++) {
        expect(a[i].at, b[i].at);
        expect(a[i].pose, b[i].pose);
      }
    });

    test('deux graines différentes donnent des plans différents', () {
      final a = ReactionDirector(seed: 1, planned: planned).events;
      final b = ReactionDirector(seed: 999, planned: planned).events;
      expect(a.map((e) => e.at).toList(), isNot(b.map((e) => e.at).toList()));
    });

    test('aucun incident au démarrage ni juste avant l\'arrivée', () {
      for (var seed = 0; seed < 40; seed++) {
        for (final e in ReactionDirector(seed: seed, planned: planned).events) {
          expect(e.at, greaterThanOrEqualTo(const Duration(seconds: 40)));
          expect(e.end, lessThan(planned));
        }
      }
    });

    test('les incidents ne se chevauchent jamais', () {
      for (var seed = 0; seed < 40; seed++) {
        final events = ReactionDirector(seed: seed, planned: planned).events;
        for (var i = 1; i < events.length; i++) {
          expect(events[i].at, greaterThanOrEqualTo(events[i - 1].end));
        }
      }
    });

    test('la pose vaut celle de l\'incident pendant sa fenêtre', () {
      final d = ReactionDirector(seed: 7, planned: planned);
      final first = d.events.first;

      expect(d.poseAt(first.at), first.pose);
      expect(d.poseAt(first.at + const Duration(milliseconds: 800)), first.pose);
      expect(d.poseAt(first.end), isNot(first.pose));
    });

    test('Pip fatigue en fin de session longue', () {
      final long = ReactionDirector(
        seed: 3,
        planned: const Duration(minutes: 45),
      );
      // À l'échéance exacte, aucun incident n'est actif : les événements
      // s'arrêtent 12 s avant la fin.
      expect(long.poseAt(const Duration(minutes: 45)), PipPose.tired);
      expect(long.poseAt(const Duration(minutes: 5)), PipPose.walking);
    });

    test('une session courte ne fatigue pas', () {
      final short = ReactionDirector(
        seed: 3,
        planned: const Duration(minutes: 10),
      );
      expect(short.poseAt(const Duration(minutes: 10)), PipPose.walking);
    });
  });

  group('ExpeditionController', () {
    test('démarre sur l\'itinéraire offert, à zéro', () async {
      final c = await _ready();
      final v = c.read(expeditionControllerProvider).value!;

      expect(v.expedition.id, ExpeditionCatalog.initial.id);
      expect(v.travelledMeters, 0);
      expect(v.cairns, isEmpty);
      expect(v.nextLeg?.name, 'Le gué');
    });

    test('une session achevée avance et pose un cairn', () async {
      final c = await _ready();
      final n = c.read(expeditionControllerProvider.notifier);

      final reached = await n.recordSession(
        meters: 2500,
        stones: 4,
        at: DateTime.utc(2026, 7, 23),
      );

      final v = c.read(expeditionControllerProvider).value!;
      expect(v.travelledMeters, 2500);
      expect(v.cairns.single.stones, 4);
      expect(reached.map((l) => l.name), ['Le gué']);
    });

    test('un abandon avance sans poser de cairn', () async {
      final c = await _ready();
      final n = c.read(expeditionControllerProvider.notifier);

      await n.recordAbandoned(900);

      final v = c.read(expeditionControllerProvider).value!;
      expect(v.travelledMeters, 900);
      expect(v.cairns, isEmpty);
    });

    test('franchir plusieurs étapes d\'un coup les renvoie toutes', () async {
      final c = await _ready();
      final n = c.read(expeditionControllerProvider.notifier);

      final reached = await n.recordSession(
        meters: 7000,
        stones: 6,
        at: DateTime.utc(2026, 7, 23),
      );

      expect(reached.map((l) => l.name), ['Le gué', 'La clairière']);
    });

    test('une session sans franchissement ne renvoie aucune étape', () async {
      final c = await _ready();
      final n = c.read(expeditionControllerProvider.notifier);

      final reached = await n.recordSession(
        meters: 500,
        stones: 2,
        at: DateTime.utc(2026, 7, 23),
      );

      expect(reached, isEmpty);
    });

    test('l\'avancement est relu au redémarrage', () async {
      final repo = InMemoryExpeditionRepository();

      final first = await _ready(repository: repo);
      await first
          .read(expeditionControllerProvider.notifier)
          .recordSession(meters: 3200, stones: 4, at: DateTime.utc(2026, 7, 23));

      final second = await _ready(repository: repo);
      final v = second.read(expeditionControllerProvider).value!;

      expect(v.travelledMeters, 3200);
      expect(v.cairns, hasLength(1));
    });
  });

  group('SessionController', () {
    test('démarre à vide', () async {
      final c = await _ready();
      final s = c.read(sessionControllerProvider);

      expect(s.phase, SessionPhase.idle);
      expect(s.selected, const Duration(minutes: 25));
    });

    test('start met la session en marche', () async {
      final c = await _ready();
      c.read(sessionControllerProvider.notifier).start();

      final s = c.read(sessionControllerProvider);
      expect(s.phase, SessionPhase.running);
      expect(s.session!.isRunning, isTrue);
      expect(s.director, isNotNull);
    });

    test('quitter l\'app fait camper Pip, sans cairn', () async {
      final c = await _ready();
      final n = c.read(sessionControllerProvider.notifier);
      n.start();
      await n.leaveApp();

      expect(c.read(sessionControllerProvider).phase, SessionPhase.camped);
      expect(c.read(sessionControllerProvider).session!.abandoned, isTrue);
      expect(
        c.read(expeditionControllerProvider).value!.cairns,
        isEmpty,
        reason: 'abandonner ne pose pas de cairn',
      );
    });

    test('aller au bout pose un cairn', () async {
      final c = await _ready();
      final n = c.read(sessionControllerProvider.notifier);
      n.start();
      await n.complete();

      expect(c.read(sessionControllerProvider).phase, SessionPhase.finished);
      expect(c.read(sessionControllerProvider).session!.abandoned, isFalse);
      expect(c.read(expeditionControllerProvider).value!.cairns, hasLength(1));
    });

    test('completeIfDue ne termine pas une session en cours', () async {
      final c = await _ready();
      final n = c.read(sessionControllerProvider.notifier);
      n.start();
      n.completeIfDue();

      expect(c.read(sessionControllerProvider).phase, SessionPhase.running);
    });

    test('terminer deux fois ne pose qu\'un seul cairn', () async {
      final c = await _ready();
      final n = c.read(sessionControllerProvider.notifier);
      n.start();
      await n.complete();
      await n.complete();

      expect(
        c.read(expeditionControllerProvider).value!.cairns,
        hasLength(1),
        reason: 'appelé à 5 Hz, completeIfDue ne doit pas doubler',
      );
    });

    test('la durée ne change pas pendant une session', () async {
      final c = await _ready();
      final n = c.read(sessionControllerProvider.notifier);
      n.selectDuration(const Duration(minutes: 45));
      n.start();
      n.selectDuration(const Duration(minutes: 15));

      expect(
        c.read(sessionControllerProvider).selected,
        const Duration(minutes: 45),
      );
    });

    test('dismiss rend la main sans effacer la progression', () async {
      final c = await _ready();
      final n = c.read(sessionControllerProvider.notifier);
      n.start();
      await n.complete();
      n.dismiss();

      expect(c.read(sessionControllerProvider).phase, SessionPhase.idle);
      expect(
        c.read(expeditionControllerProvider).value!.cairns,
        hasLength(1),
        reason: 'la progression survit au bilan',
      );
    });
  });
}
