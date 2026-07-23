/// Une session de concentration.
///
/// Le minuteur ne tourne jamais : on stocke [startedAt] et on recalcule
/// l'écoulé à la demande. C'est ce qui rend la session immunisée à la
/// suspension de l'app par iOS. Voir CONCEPT.md §8.
class FocusSession {
  const FocusSession({
    required this.startedAt,
    required this.planned,
    this.endedAt,
    this.abandoned = false,
  });

  final DateTime startedAt;
  final Duration planned;

  /// Renseigné quand la session se termine, par achèvement ou abandon.
  final DateTime? endedAt;

  /// L'utilisateur a quitté avant la fin : Pip a monté le camp.
  final bool abandoned;

  bool get isRunning => endedAt == null;

  Duration elapsedAt(DateTime now) {
    final end = endedAt ?? now;
    final raw = end.difference(startedAt);
    return raw > planned ? planned : raw;
  }

  Duration remainingAt(DateTime now) => planned - elapsedAt(now);

  double progressAt(DateTime now) {
    if (planned.inMilliseconds == 0) return 1;
    final p = elapsedAt(now).inMilliseconds / planned.inMilliseconds;
    return p.clamp(0.0, 1.0);
  }

  bool isCompleteAt(DateTime now) => elapsedAt(now) >= planned;

  /// Distance parcourue par Pip, en mètres.
  ///
  /// Une minute de concentration vaut 100 m — un chiffre rond qui rend les
  /// étapes lisibles (25 min = 2,5 km).
  double distanceAt(DateTime now) => elapsedAt(now).inSeconds / 60 * 100;

  FocusSession copyWith({DateTime? endedAt, bool? abandoned}) => FocusSession(
    startedAt: startedAt,
    planned: planned,
    endedAt: endedAt ?? this.endedAt,
    abandoned: abandoned ?? this.abandoned,
  );
}
