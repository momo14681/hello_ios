import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/reminders/reminder_providers.dart';
import '../../design/content_width.dart';
import '../../design/theme.dart';
import '../../design/tokens.dart';
import '../../domain/expedition.dart';
import '../../world/pip/pip_params.dart';
import '../../world/world_theme.dart';
import '../../world/world_view.dart';
import '../expedition/expedition_controller.dart';
import '../wardrobe/wardrobe_controller.dart';
import 'session_controller.dart';

/// L'écran principal : le monde en plein cadre, une bande de commandes en bas.
///
/// Pendant une session, **rien ne bouge à l'écran sauf Pip et le paysage**.
/// C'est une app de concentration : l'interface doit être ennuyeuse à regarder.
class SessionScreen extends ConsumerStatefulWidget {
  const SessionScreen({super.key});

  @override
  ConsumerState<SessionScreen> createState() => _SessionScreenState();
}

class _SessionScreenState extends ConsumerState<SessionScreen>
    with WidgetsBindingObserver {
  static const _durations = [
    Duration(minutes: 15),
    Duration(minutes: 25),
    Duration(minutes: 45),
    Duration(minutes: 60),
  ];

  /// Hauteur réservée en bas par le panneau de commandes : le sol se cale
  /// au-dessus, sinon Pip marche derrière.
  static const _panelInset = 130.0;

  /// Durée de l'empilement du cairn avant l'affichage du bilan.
  static const _stacking = Duration(milliseconds: 2400);
  static const _cheering = Duration(milliseconds: 1800);

  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Ce battement ne rafraîchit **rien** : il ne fait que clore la session à
    // l'échéance. L'affichage qui dépend du temps se rafraîchit tout seul,
    // dans `_Ticking`.
    _ticker = Timer.periodic(const Duration(milliseconds: 200), (_) {
      if (!mounted) return;
      ref.read(sessionControllerProvider.notifier).completeIfDue();
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      ref.read(sessionControllerProvider.notifier).leaveApp();
    }
  }

  /// Démarre la session **immédiatement**, puis demande l'autorisation de
  /// notifier en tâche de fond.
  ///
  /// L'ordre inverse — attendre l'autorisation avant de démarrer — rendait le
  /// bouton inerte dès que le greffon échouait à s'initialiser. Le rappel est
  /// un confort : il ne doit jamais conditionner le départ.
  void _start() {
    ref.read(sessionControllerProvider.notifier).start();
    if (kIsWeb) return;

    // `unawaited` seul ne suffit pas : sans `catchError`, l'échec remonte en
    // erreur asynchrone non traitée.
    unawaited(
      Future<void>.sync(() async {
        await ref.read(reminderServiceProvider).requestPermission();
      }).catchError((Object _) {}),
    );
  }

  /// La pose de Pip, dérivée de l'état de session et du temps écoulé.
  PipPose _pose(SessionState s, DateTime now) {
    switch (s.phase) {
      case SessionPhase.idle:
        return PipPose.idle;
      case SessionPhase.camped:
        return PipPose.resting;
      case SessionPhase.running:
        return s.director?.poseAt(s.session!.elapsedAt(now)) ?? PipPose.walking;
      case SessionPhase.finished:
        final since = now.difference(s.session!.endedAt!);
        if (since < _stacking) return PipPose.stacking;
        if (since < _stacking + _cheering) return PipPose.cheering;
        return PipPose.idle;
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(sessionControllerProvider);
    final expedition = ref.watch(expeditionControllerProvider).value;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Seuls le monde et l'horloge dépendent du temps qui passe. Les
          // reconstruire séparément évite de relancer l'animation d'entrée du
          // panneau à chaque battement — elle n'atteignait alors jamais sa
          // position finale, et le bouton restait décalé sous le doigt.
          _Ticking(
            builder: (_, now) => WorldView(
              pose: _pose(s, now),
              params: const PipParams(scale: 1.5),
              outfit: ref.watch(pipOutfitProvider),
              theme: WorldTheme.forExpedition(expedition?.expedition.id ?? ''),
              bottomInset: _panelInset,
            ),
          ),
          // Un Stack plutôt qu'une Column avec Spacer : la Column débordait
          // d'un pixel sur un écran court, et Flutter rogne ce qui déborde —
          // le panneau devenait alors insensible au clic.
          SafeArea(
            child: Align(
              alignment: Alignment.topLeft,
              child: _Ticking(
                builder: (_, now) => _TopBar(state: s, now: now),
              ),
            ),
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: ContentWidth(child: _panel(s, expedition)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _panel(
    SessionState s,
    ExpeditionView? expedition,
  ) => switch (s.phase) {
    SessionPhase.idle => _IdlePanel(
      selected: s.selected,
      durations: _durations,
      onSelect: ref.read(sessionControllerProvider.notifier).selectDuration,
      onStart: _start,
    ),
    SessionPhase.running => _RunningPanel(
      onCamp: ref.read(sessionControllerProvider.notifier).camp,
    ),
    SessionPhase.camped => _OutcomePanel(
      title: 'Pip a monté le camp',
      body:
          'Tu es sorti de l\'app, alors il s\'est arrêté là où il était. '
          '${_km(s.lastDistance)} restent acquis — mais pas de cairn cette fois.',
      action: 'Repartir',
      onAction: ref.read(sessionControllerProvider.notifier).dismiss,
    ),
    SessionPhase.finished => _OutcomePanel(
      // Franchir une étape est le moment fort de l'expédition : il prend le
      // dessus sur le simple bilan de session.
      title: s.reachedLegs.isEmpty
          ? 'Cairn posé'
          : '${s.reachedLegs.last.name}, atteint',
      body: _outcomeBody(s, expedition),
      action: 'Continuer',
      onAction: ref.read(sessionControllerProvider.notifier).dismiss,
    ),
  };

  String _outcomeBody(SessionState s, ExpeditionView? e) {
    final reward = s.lastReward > 0 ? ' +${s.lastReward} éclats.' : '';
    final travelled = '${_km(s.lastDistance)} parcourus.$reward';
    if (e == null) return travelled;

    final next = e.nextLeg;
    final remaining = next == null
        ? 'Le bout du chemin.'
        : '${_km(e.metersToNextLeg)} avant ${next.name}.';

    return '$travelled $remaining';
  }

  static String _km(double meters) => meters >= 1000
      ? '${(meters / 1000).toStringAsFixed(1)} km'
      : '${meters.round()} m';
}

/// Reconstruit son sous-arbre cinq fois par seconde, avec l'heure courante.
///
/// La source de vérité reste l'horodatage de la session ; ce battement ne sert
/// qu'à rafraîchir ce qui se lit du temps écoulé.
class _Ticking extends StatefulWidget {
  const _Ticking({required this.builder});

  final Widget Function(BuildContext context, DateTime now) builder;

  @override
  State<_Ticking> createState() => _TickingState();
}

class _TickingState extends State<_Ticking> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 200), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, DateTime.now());
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.state, required this.now});

  final SessionState state;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final running = state.phase == SessionPhase.running;
    final label = running ? _clock(state.session!.remainingAt(now)) : 'Cairn';

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.sm,
        0,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: timerTextStyle(
                running ? 46 : 30,
              ).copyWith(color: Colors.white, letterSpacing: running ? 1 : 2),
            ),
          ),
          if (!running) ...[
            IconButton(
              onPressed: () => context.push('/map'),
              icon: const Icon(Icons.map_rounded, color: Colors.white),
              tooltip: 'Carte de l\'expédition',
            ),
            IconButton(
              onPressed: () => context.push('/shop'),
              icon: const Icon(Icons.checkroom_rounded, color: Colors.white),
              tooltip: 'Garde-robe',
            ),
          ],
          if (kDebugMode)
            IconButton(
              onPressed: () => context.push('/bench'),
              icon: const Icon(Icons.tune_rounded, color: Colors.white70),
              tooltip: 'Banc d\'essai',
            ),
        ],
      ),
    );
  }

  static String _clock(Duration d) {
    final total = d.isNegative ? Duration.zero : d;
    final m = total.inMinutes.toString().padLeft(2, '0');
    final s = (total.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}

/// Le panneau de commandes.
///
/// **Sans animation d'entrée, délibérément.** Sur un écran de concentration,
/// rien ne doit bouger sauf Pip et le paysage. Et techniquement, un `slideY`
/// laissait la carte décalée de 45 px vers le bas : le bouton restait visible
/// mais le doigt tombait à côté.
class _Card extends StatelessWidget {
  const _Card({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(AppSpacing.md),
    decoration: BoxDecoration(
      color: AppColors.surfaceRaised.withValues(alpha: 0.94),
      borderRadius: const BorderRadius.all(AppRadii.card),
    ),
    child: child,
  );
}

class _IdlePanel extends StatelessWidget {
  const _IdlePanel({
    required this.selected,
    required this.durations,
    required this.onSelect,
    required this.onStart,
  });

  final Duration selected;
  final List<Duration> durations;
  final ValueChanged<Duration> onSelect;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) => _Card(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: AppSpacing.sm,
          alignment: WrapAlignment.center,
          children: [
            for (final d in durations)
              ChoiceChip(
                label: Text('${d.inMinutes} min'),
                selected: d == selected,
                onSelected: (_) => onSelect(d),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        FilledButton.icon(
          onPressed: onStart,
          icon: const Icon(Icons.hiking_rounded),
          label: const Text('Partir'),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          ),
        ),
      ],
    ),
  );
}

class _RunningPanel extends StatelessWidget {
  const _RunningPanel({required this.onCamp});

  final VoidCallback onCamp;

  @override
  // Une `Row` et non un `Align` : `Align` s'étire verticalement dès que les
  // contraintes sont lâches, et le bouton se retrouvait centré au milieu de
  // l'écran au lieu de rester en bas.
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.end,
    children: [
      TextButton.icon(
        onPressed: onCamp,
        icon: const Icon(Icons.local_fire_department_rounded),
        label: const Text('Camper'),
        style: TextButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: Colors.black.withValues(alpha: 0.22),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
        ),
      ),
    ],
  );
}

class _OutcomePanel extends StatelessWidget {
  const _OutcomePanel({
    required this.title,
    required this.body,
    required this.action,
    required this.onAction,
  });

  final String title;
  final String body;
  final String action;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) => _Card(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          body,
          style: const TextStyle(color: AppColors.inkSoft, height: 1.5),
        ),
        const SizedBox(height: AppSpacing.md),
        FilledButton(onPressed: onAction, child: Text(action)),
      ],
    ),
  );
}
