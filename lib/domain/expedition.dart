/// Un cairn posé sur le chemin : la trace d'une session achevée.
class Cairn {
  const Cairn({
    required this.atMeters,
    required this.placedAt,
    required this.stones,
  });

  /// Position sur l'itinéraire de l'expédition.
  final double atMeters;
  final DateTime placedAt;

  /// Nombre de pierres empilées — dérivé de la durée de la session.
  final int stones;

  /// Une pierre par tranche de 10 minutes, entre 2 et 6.
  static int stonesFor(Duration session) =>
      (2 + session.inMinutes ~/ 10).clamp(2, 6);

  Map<String, Object?> toJson() => {
    'atMeters': atMeters,
    'placedAt': placedAt.toIso8601String(),
    'stones': stones,
  };

  static Cairn fromJson(Map<String, Object?> json) => Cairn(
    atMeters: (json['atMeters'] as num).toDouble(),
    placedAt: DateTime.parse(json['placedAt'] as String),
    stones: json['stones'] as int,
  );
}

/// La nature d'une étape, qui détermine son pictogramme sur la carte.
///
/// Un simple point ne dit rien : le pictogramme donne à chaque jalon une
/// identité, et à la carte son air de carte.
enum LegKind { water, forest, ridge, pass, ice, summit, ruins, dunes }

/// Une étape jalonnant une expédition : un col, un lac, un sommet.
class Leg {
  const Leg({
    required this.name,
    required this.atMeters,
    required this.kind,
  });

  final String name;
  final double atMeters;
  final LegKind kind;
}

/// La **définition** d'un itinéraire. Donnée statique, jamais persistée :
/// elle vit dans le catalogue.
class Expedition {
  const Expedition({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.legs,
    this.isPremium = false,
  });

  final String id;
  final String name;
  final String subtitle;
  final List<Leg> legs;
  final bool isPremium;

  double get totalMeters => legs.isEmpty ? 0 : legs.last.atMeters;
}

/// L'**avancement** sur un itinéraire. C'est la seule partie persistée.
class ExpeditionProgress {
  const ExpeditionProgress({
    required this.expeditionId,
    this.travelledMeters = 0,
    this.cairns = const [],
  });

  final String expeditionId;
  final double travelledMeters;
  final List<Cairn> cairns;

  ExpeditionProgress copyWith({
    double? travelledMeters,
    List<Cairn>? cairns,
  }) => ExpeditionProgress(
    expeditionId: expeditionId,
    travelledMeters: travelledMeters ?? this.travelledMeters,
    cairns: cairns ?? this.cairns,
  );

  Map<String, Object?> toJson() => {
    'expeditionId': expeditionId,
    'travelledMeters': travelledMeters,
    'cairns': [for (final c in cairns) c.toJson()],
  };

  static ExpeditionProgress fromJson(Map<String, Object?> json) =>
      ExpeditionProgress(
        expeditionId: json['expeditionId'] as String,
        travelledMeters: (json['travelledMeters'] as num).toDouble(),
        cairns: [
          for (final c in (json['cairns'] as List? ?? const []))
            Cairn.fromJson(Map<String, Object?>.from(c as Map)),
        ],
      );
}

/// Définition et avancement réunis — ce que consomme l'interface.
class ExpeditionView {
  const ExpeditionView({required this.expedition, required this.progress});

  final Expedition expedition;
  final ExpeditionProgress progress;

  double get travelledMeters => progress.travelledMeters;
  List<Cairn> get cairns => progress.cairns;
  double get totalMeters => expedition.totalMeters;

  /// Prochaine étape non franchie, ou `null` si l'expédition est terminée.
  Leg? get nextLeg {
    for (final leg in expedition.legs) {
      if (leg.atMeters > travelledMeters) return leg;
    }
    return null;
  }

  List<Leg> get reachedLegs => [
    for (final leg in expedition.legs)
      if (leg.atMeters <= travelledMeters) leg,
  ];

  double get metersToNextLeg {
    final leg = nextLeg;
    return leg == null ? 0 : leg.atMeters - travelledMeters;
  }

  double get fraction => totalMeters == 0
      ? 0
      : (travelledMeters / totalMeters).clamp(0.0, 1.0);

  bool get isComplete => nextLeg == null;

  /// Position d'un jalon sur l'itinéraire, entre 0 et 1.
  double fractionOf(double meters) =>
      totalMeters == 0 ? 0 : (meters / totalMeters).clamp(0.0, 1.0);

  ExpeditionView withProgress(ExpeditionProgress next) =>
      ExpeditionView(expedition: expedition, progress: next);
}
