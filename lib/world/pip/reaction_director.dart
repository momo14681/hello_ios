import 'dart:math';

import 'pip_params.dart';

/// Une réaction ponctuelle survenant pendant une session.
class ReactionEvent {
  const ReactionEvent({
    required this.at,
    required this.pose,
    required this.duration,
  });

  final Duration at;
  final PipPose pose;
  final Duration duration;

  Duration get end => at + duration;
}

/// Décide de ce que fait Pip à chaque instant d'une session.
///
/// Le plan des événements est **tiré une fois** à partir d'une graine, puis
/// [poseAt] devient une fonction pure du temps écoulé. Deux conséquences :
/// la scène est identique après une mise en arrière-plan et un retour, et tout
/// se teste sans horloge ni aléatoire.
class ReactionDirector {
  ReactionDirector({required this.seed, required this.planned});

  final int seed;
  final Duration planned;

  /// Un incident ne survient jamais avant ce délai : les premières secondes
  /// doivent être calmes, on vient de se mettre au travail.
  static const _firstWindow = Duration(seconds: 40);
  static const _minGap = Duration(seconds: 55);
  static const _extraGapRange = 80;
  static const _eventDuration = Duration(milliseconds: 1600);

  /// Au-delà de cette fraction, Pip fatigue — seulement sur les sessions assez
  /// longues pour que ce soit crédible.
  static const _fatigueFrom = 0.72;
  static const _fatigueMinPlanned = Duration(minutes: 15);

  static const _kinds = [
    PipPose.bumped,
    PipPose.surprised,
    PipPose.hurt,
    PipPose.surprised,
  ];

  late final List<ReactionEvent> events = _plan();

  List<ReactionEvent> _plan() {
    final rnd = Random(seed);
    final out = <ReactionEvent>[];
    // On garde la toute fin libre : l'arrivée doit être nette.
    final last = planned - const Duration(seconds: 12);

    var t = _firstWindow + Duration(seconds: rnd.nextInt(40));
    while (t < last) {
      out.add(
        ReactionEvent(
          at: t,
          pose: _kinds[rnd.nextInt(_kinds.length)],
          duration: _eventDuration,
        ),
      );
      t += _minGap + Duration(seconds: rnd.nextInt(_extraGapRange));
    }
    return out;
  }

  /// La pose de Pip après [elapsed] de session en cours.
  PipPose poseAt(Duration elapsed) {
    for (final event in events) {
      if (elapsed >= event.at && elapsed < event.end) return event.pose;
    }

    if (planned >= _fatigueMinPlanned && planned.inMilliseconds > 0) {
      final ratio = elapsed.inMilliseconds / planned.inMilliseconds;
      if (ratio >= _fatigueFrom) return PipPose.tired;
    }

    return PipPose.walking;
  }
}
