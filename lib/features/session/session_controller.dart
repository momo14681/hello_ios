import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/reminders/reminder_providers.dart';
import '../../data/reminders/reminder_service.dart';
import '../../domain/expedition.dart';
import '../../domain/session.dart';
import '../../world/pip/reaction_director.dart';
import '../expedition/expedition_controller.dart';
import '../wardrobe/wardrobe_controller.dart';

enum SessionPhase {
  /// Aucune session : Pip attend.
  idle,

  /// Session en cours, Pip marche.
  running,

  /// L'utilisateur a quitté l'app : Pip a monté le camp. Jamais punitif.
  camped,

  /// Session menée à son terme : le cairn est posé.
  finished,
}

class SessionState {
  const SessionState({
    this.session,
    this.selected = const Duration(minutes: 25),
    this.seed = 0,
    this.lastDistance = 0,
    this.lastReward = 0,
    this.reachedLegs = const [],
  });

  final FocusSession? session;
  final Duration selected;
  final int seed;

  /// Distance de la dernière session close, pour le bilan.
  final double lastDistance;

  /// Éclats gagnés par la dernière session achevée.
  final int lastReward;

  /// Étapes franchies par la dernière session — la matière de la célébration.
  final List<Leg> reachedLegs;

  SessionPhase get phase {
    final s = session;
    if (s == null) return SessionPhase.idle;
    if (s.isRunning) return SessionPhase.running;
    return s.abandoned ? SessionPhase.camped : SessionPhase.finished;
  }

  ReactionDirector? get director => session == null
      ? null
      : ReactionDirector(seed: seed, planned: session!.planned);

  SessionState copyWith({
    FocusSession? session,
    bool clearSession = false,
    Duration? selected,
    int? seed,
    double? lastDistance,
    int? lastReward,
    List<Leg>? reachedLegs,
  }) => SessionState(
    session: clearSession ? null : (session ?? this.session),
    selected: selected ?? this.selected,
    seed: seed ?? this.seed,
    lastDistance: lastDistance ?? this.lastDistance,
    lastReward: lastReward ?? this.lastReward,
    reachedLegs: reachedLegs ?? this.reachedLegs,
  );
}

/// Pilote une session de concentration.
///
/// **Aucun compteur ne tourne ici.** L'instant de départ est stocké et l'écoulé
/// se recalcule à la demande, ce qui rend la session insensible à la suspension
/// de l'app par iOS. Voir CONCEPT.md §8.
///
/// La progression n'est pas stockée ici non plus : elle appartient à
/// [ExpeditionController], seul responsable de la persistance.
class SessionController extends Notifier<SessionState> {
  @override
  SessionState build() => const SessionState();

  void selectDuration(Duration value) {
    if (state.phase == SessionPhase.running) return;
    state = state.copyWith(selected: value);
  }

  void start() {
    final now = DateTime.now();
    state = state.copyWith(
      session: FocusSession(startedAt: now, planned: state.selected),
      seed: now.millisecondsSinceEpoch & 0x7fffffff,
      reachedLegs: const [],
      lastDistance: 0,
      lastReward: 0,
    );

    // Le rappel permet d'être prévenu app fermée. Il est inerte sur le web.
    _reminder(
      (s) => s.scheduleSessionEnd(now.add(state.selected), state.selected),
    );
  }

  /// Appelle le service de rappel sans jamais laisser son échec remonter.
  ///
  /// Le rappel est un confort : une notification indisponible ne doit ni
  /// interrompre une session, ni empêcher d'en démarrer une.
  void _reminder(Future<void> Function(ReminderService service) action) {
    unawaited(
      Future<void>.sync(
        () => action(ref.read(reminderServiceProvider)),
      ).catchError((Object _) {}),
    );
  }

  /// L'utilisateur a quitté l'application. Pip monte le camp là où il est :
  /// la distance reste acquise, mais aucun cairn n'est posé.
  Future<void> leaveApp() async {
    final s = state.session;
    if (s == null || !s.isRunning) return;

    final now = DateTime.now();
    if (s.isCompleteAt(now)) return complete();

    final distance = s.distanceAt(now);
    state = state.copyWith(
      session: s.copyWith(endedAt: now, abandoned: true),
      lastDistance: distance,
    );
    _reminder((s) => s.cancel());

    final legs = await ref
        .read(expeditionControllerProvider.notifier)
        .recordAbandoned(distance);
    state = state.copyWith(reachedLegs: legs);
  }

  /// Termine la session si la durée prévue est atteinte. Sans effet sinon.
  void completeIfDue() {
    final s = state.session;
    if (s == null || !s.isRunning) return;
    if (s.isCompleteAt(DateTime.now())) complete();
  }

  Future<void> complete() async {
    final s = state.session;
    if (s == null || !s.isRunning) return;

    final now = DateTime.now();
    final distance = s.distanceAt(now);

    // L'état bascule d'abord : appelé à 5 Hz, `completeIfDue` ne doit pas
    // pouvoir déclencher deux enregistrements.
    state = state.copyWith(
      session: s.copyWith(endedAt: now),
      lastDistance: distance,
    );
    _reminder((s) => s.cancel());

    final legs = await ref
        .read(expeditionControllerProvider.notifier)
        .recordSession(
          meters: distance,
          stones: Cairn.stonesFor(s.planned),
          at: now,
        );

    // Les éclats récompensent l'achèvement, comme le cairn : un abandon n'en
    // rapporte pas.
    final gained = await ref
        .read(wardrobeControllerProvider.notifier)
        .reward(planned: s.planned, legsReached: legs.length);

    state = state.copyWith(reachedLegs: legs, lastReward: gained);
  }

  /// Abandon volontaire depuis l'interface. Même traitement qu'une sortie
  /// d'app : Pip campe, sans reproche.
  Future<void> camp() => leaveApp();

  /// Rend la main après le bilan.
  void dismiss() =>
      state = state.copyWith(clearSession: true, reachedLegs: const []);
}

final sessionControllerProvider =
    NotifierProvider<SessionController, SessionState>(SessionController.new);
