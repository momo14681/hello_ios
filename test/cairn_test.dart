import 'package:flutter_test/flutter_test.dart';
import 'package:hello_ios/domain/expedition.dart';
import 'package:hello_ios/domain/session.dart';
import 'package:hello_ios/world/landscape/landscape_spec.dart';
import 'package:hello_ios/world/pip/pip_painter.dart';
import 'package:hello_ios/world/sky.dart';

void main() {
  group('FocusSession', () {
    final start = DateTime(2026, 7, 22, 9);
    const planned = Duration(minutes: 25);

    test('progression et distance suivent l\'horloge, pas un compteur', () {
      final s = FocusSession(startedAt: start, planned: planned);
      final at10 = start.add(const Duration(minutes: 10));

      expect(s.elapsedAt(at10), const Duration(minutes: 10));
      expect(s.remainingAt(at10), const Duration(minutes: 15));
      expect(s.progressAt(at10), closeTo(0.4, 1e-9));
      expect(s.distanceAt(at10), closeTo(1000, 1e-9));
    });

    test('l\'écoulé sature à la durée prévue', () {
      final s = FocusSession(startedAt: start, planned: planned);
      final wayLater = start.add(const Duration(hours: 3));

      expect(s.elapsedAt(wayLater), planned);
      expect(s.progressAt(wayLater), 1.0);
      expect(s.isCompleteAt(wayLater), isTrue);
    });

    test('une session terminée fige son écoulé', () {
      final s = FocusSession(
        startedAt: start,
        planned: planned,
        endedAt: start.add(const Duration(minutes: 4)),
        abandoned: true,
      );

      expect(s.isRunning, isFalse);
      expect(
        s.elapsedAt(start.add(const Duration(hours: 2))),
        const Duration(minutes: 4),
      );
    });
  });

  group('ExpeditionView', () {
    const expedition = Expedition(
      id: 'a',
      name: 'Première traversée',
      subtitle: 'Des berges au sommet',
      legs: [
        Leg(name: 'Le gué', atMeters: 1500, kind: LegKind.water),
        Leg(name: 'Le col', atMeters: 6000, kind: LegKind.pass),
        Leg(name: 'Le sommet', atMeters: 12000, kind: LegKind.summit),
      ],
    );

    ExpeditionView viewAt(double metres, {List<Cairn> cairns = const []}) =>
        ExpeditionView(
          expedition: expedition,
          progress: ExpeditionProgress(
            expeditionId: 'a',
            travelledMeters: metres,
            cairns: cairns,
          ),
        );

    test('la prochaine étape est la première non franchie', () {
      final v = viewAt(2000);

      expect(v.nextLeg?.name, 'Le col');
      expect(v.metersToNextLeg, 4000);
      expect(v.fraction, closeTo(2000 / 12000, 1e-9));
      expect(v.isComplete, isFalse);
      expect(v.reachedLegs.map((l) => l.name), ['Le gué']);
    });

    test('une expédition parcourue en entier est terminée', () {
      final v = viewAt(12000);

      expect(v.nextLeg, isNull);
      expect(v.isComplete, isTrue);
      expect(v.fraction, 1.0);
      expect(v.reachedLegs.length, 3);
    });

    test('l\'avancement survit à un aller-retour JSON', () {
      final progress = ExpeditionProgress(
        expeditionId: 'a',
        travelledMeters: 7250.5,
        cairns: [
          Cairn(
            atMeters: 2500,
            placedAt: DateTime.utc(2026, 7, 23, 9, 30),
            stones: 4,
          ),
        ],
      );

      final restored = ExpeditionProgress.fromJson(progress.toJson());

      expect(restored.expeditionId, 'a');
      expect(restored.travelledMeters, 7250.5);
      expect(restored.cairns.single.stones, 4);
      expect(restored.cairns.single.atMeters, 2500);
      expect(restored.cairns.single.placedAt, DateTime.utc(2026, 7, 23, 9, 30));
    });
  });

  group('Monde', () {
    test('le clignement ferme puis rouvre les yeux', () {
      const period = 3.0;

      expect(PipArt.blinkFactor(0.5, period), 1.0);
      expect(PipArt.blinkFactor(period - 0.06, period), lessThan(0.3));
      expect(PipArt.blinkFactor(period - 0.001, period), greaterThan(0.9));
    });

    test('le nombre de pierres suit la durée, borné à 6', () {
      expect(Cairn.stonesFor(const Duration(minutes: 5)), 2);
      expect(Cairn.stonesFor(const Duration(minutes: 25)), 4);
      expect(Cairn.stonesFor(const Duration(minutes: 300)), 6);
    });

    test('le ciel change entre le jour et la nuit', () {
      expect(SkyPalette.forHour(12).top, isNot(SkyPalette.forHour(0).top));
      expect(SkyPalette.isNight(2), isTrue);
      expect(SkyPalette.isNight(13), isFalse);
    });

    test('le sol est déterministe et continu', () {
      final ground = LandscapeSpec.standard.ground;
      final a = ground.yAt(100, 0, 400);
      final b = ground.yAt(100, 0, 400);
      final c = ground.yAt(103, 0, 400);

      expect(a, b, reason: 'même entrée, même sortie');
      expect((a - c).abs(), lessThan(6), reason: 'pas de discontinuité');
    });

    test('le défilement déplace le sol', () {
      final ground = LandscapeSpec.standard.ground;
      expect(ground.yAt(100, 0, 400), isNot(ground.yAt(100, 200, 400)));
    });
  });
}
