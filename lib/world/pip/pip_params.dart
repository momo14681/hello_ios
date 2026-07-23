/// Les états de Pip. Voir CONCEPT.md §2.
enum PipPose {
  /// À l'arrêt : respire, cligne des yeux.
  idle('Arrêt'),

  /// En marche pendant une session de concentration.
  walking('Marche'),

  /// Le camp, quand l'utilisateur a quitté l'app. Jamais punitif.
  resting('Camp'),

  /// Empile un cairn à la fin d'une session.
  stacking('Cairn'),

  /// Étonné : quelque chose vient d'apparaître sur le chemin.
  surprised('Étonné'),

  /// Vient de heurter un obstacle. Sonné, pas blessé.
  bumped('Choc'),

  /// Douleur brève.
  hurt('Douleur'),

  /// Fatigue de fin de longue session.
  tired('Fatigue'),

  /// Célébration : étape franchie.
  cheering('Joie');

  const PipPose(this.label);

  /// Libellé court, pour le banc d'essai.
  final String label;
}

/// Forme des yeux. C'est le principal porteur d'émotion.
enum EyeStyle { normal, wide, happy, squeezed, swirl, droopy }

/// Forme de la bouche.
enum MouthStyle { closedSmile, open, flat, grimace, round }

/// Effet transitoire dessiné autour de Pip.
enum PipEffect { none, sweat, dizzy, impact }

/// Tous les réglages de Pip, en un seul objet immuable.
///
/// Chaque champ correspond à un curseur du banc d'essai. C'est le
/// remplacement de Rive : on règle des nombres au hot-reload plutôt que des
/// courbes dans un éditeur. Voir CONCEPT.md §3.
class PipParams {
  const PipParams({
    this.scale = 1.0,
    this.walkSpeed = 1.6,
    this.bobAmplitude = 2.9,
    this.squash = 0.010,
    this.legSwing = 5.0,
    this.armSwing = 4.0,
    this.eyeRadius = 4.7,
    this.eyeSpacing = 9.6,
    this.browLift = 0.4,
    this.blushOpacity = 0.4,
    this.veinOpacity = 0.42,
    this.pennantWave = 5.0,
    this.blinkPeriod = 3.4,
    this.showPennant = true,
    this.showLantern = true,
    this.showBackpack = true,
  });

  /// Taille globale. 1 correspond à un Pip d'environ 48 px de haut.
  final double scale;

  /// Cycles de jambes par seconde.
  final double walkSpeed;

  /// Amplitude du rebond vertical du corps, en pixels.
  final double bobAmplitude;

  /// Écrasement/étirement, de 0 à 0,2. Au-delà, Pip devient élastique.
  final double squash;

  /// Débattement des jambes, en pixels.
  final double legSwing;

  /// Débattement des bras. Ils balancent en opposition aux jambes.
  final double armSwing;

  final double eyeRadius;
  final double eyeSpacing;

  /// Hauteur des sourcils : 0 neutre, 1 très expressif. Volontairement bas par
  /// défaut — des sourcils marqués annulent l'effet kawaii.
  final double browLift;

  /// Intensité des joues rosées.
  final double blushOpacity;

  /// Intensité de la marque minérale.
  final double veinOpacity;

  /// Amplitude de l'ondulation du fanion.
  final double pennantWave;

  /// Secondes entre deux clignements.
  final double blinkPeriod;

  final bool showPennant;
  final bool showLantern;
  final bool showBackpack;

  static const defaults = PipParams();

  PipParams copyWith({
    double? scale,
    double? walkSpeed,
    double? bobAmplitude,
    double? squash,
    double? legSwing,
    double? armSwing,
    double? eyeRadius,
    double? eyeSpacing,
    double? browLift,
    double? blushOpacity,
    double? veinOpacity,
    double? pennantWave,
    double? blinkPeriod,
    bool? showPennant,
    bool? showLantern,
    bool? showBackpack,
  }) => PipParams(
    scale: scale ?? this.scale,
    walkSpeed: walkSpeed ?? this.walkSpeed,
    bobAmplitude: bobAmplitude ?? this.bobAmplitude,
    squash: squash ?? this.squash,
    legSwing: legSwing ?? this.legSwing,
    armSwing: armSwing ?? this.armSwing,
    eyeRadius: eyeRadius ?? this.eyeRadius,
    eyeSpacing: eyeSpacing ?? this.eyeSpacing,
    browLift: browLift ?? this.browLift,
    blushOpacity: blushOpacity ?? this.blushOpacity,
    veinOpacity: veinOpacity ?? this.veinOpacity,
    pennantWave: pennantWave ?? this.pennantWave,
    blinkPeriod: blinkPeriod ?? this.blinkPeriod,
    showPennant: showPennant ?? this.showPennant,
    showLantern: showLantern ?? this.showLantern,
    showBackpack: showBackpack ?? this.showBackpack,
  );
}

/// Coefficients dérivés de la pose, appliqués aux paramètres.
///
/// Ajouter une réaction, c'est ajouter une ligne à [of] — jamais toucher au
/// painter. C'est ce qui rend les émotions bon marché.
class PipPoseTraits {
  const PipPoseTraits({
    required this.bobScale,
    required this.swingScale,
    required this.rateScale,
    this.squashScale = 1,
    this.sit = 0,
    this.lean = 0,
    this.brow = 0,
    this.eyeOpen = 1,
    this.eyeStyle = EyeStyle.normal,
    this.mouth = MouthStyle.closedSmile,
    this.mouthOpen = 0.15,
    this.armsUp = 0,
    this.stretch = 0,
    this.shake = 0,
    this.effect = PipEffect.none,
  });

  final double bobScale;
  final double swingScale;
  final double rateScale;

  /// Multiplicateur d'écrasement, appliqué à `PipParams.squash`.
  ///
  /// Chaque émotion se règle indépendamment : une réaction peut vouloir moins
  /// de rebond mais plus d'écrasement, ou l'inverse.
  final double squashScale;

  /// 0 = debout, 1 = assis au camp.
  final double sit;

  /// Inclinaison du corps, en radians.
  final double lean;

  /// Expression : -1 sourcils tombants, 0 neutre, 1 relevés.
  final double brow;

  /// Ouverture des paupières. En dessous de 1, Pip a l'air ensommeillé.
  final double eyeOpen;

  final EyeStyle eyeStyle;
  final MouthStyle mouth;

  /// Ouverture de la bouche quand [mouth] vaut [MouthStyle.open].
  final double mouthOpen;

  /// 0 = bras le long du corps, 1 = bras levés.
  final double armsUp;

  /// Étirement vertical : -1 écrasé, +1 étiré.
  final double stretch;

  /// Amplitude du tremblement horizontal, en pixels.
  final double shake;

  final PipEffect effect;

  static PipPoseTraits of(PipPose pose) => switch (pose) {
    PipPose.idle => const PipPoseTraits(
      bobScale: 0.35,
      swingScale: 0,
      rateScale: 0.55,
      brow: 0.1,
      mouthOpen: 0.12,
    ),
    PipPose.walking => const PipPoseTraits(
      bobScale: 1,
      swingScale: 1,
      rateScale: 1,
      lean: 0.05,
      brow: 0.35,
      mouth: MouthStyle.open,
      mouthOpen: 0.75,
    ),
    PipPose.resting => const PipPoseTraits(
      bobScale: 0.22,
      swingScale: 0,
      rateScale: 0.4,
      sit: 1,
      lean: -0.04,
      brow: -0.5,
      eyeOpen: 0.42,
      eyeStyle: EyeStyle.droopy,
      mouthOpen: 0,
    ),
    PipPose.stacking => const PipPoseTraits(
      bobScale: 0.3,
      swingScale: 0.25,
      rateScale: 0.7,
      lean: 0.14,
      brow: 0.2,
      mouth: MouthStyle.open,
      mouthOpen: 0.4,
    ),

    // ---- Réactions ----
    PipPose.surprised => const PipPoseTraits(
      bobScale: 0.12,
      swingScale: 0,
      rateScale: 0.3,
      lean: -0.06,
      brow: 1,
      eyeStyle: EyeStyle.wide,
      mouth: MouthStyle.round,
      armsUp: 0.4,
      stretch: 0.5,
    ),
    PipPose.bumped => const PipPoseTraits(
      bobScale: 0.1,
      swingScale: 0,
      rateScale: 0.25,
      lean: -0.26,
      brow: 0.7,
      eyeStyle: EyeStyle.swirl,
      mouth: MouthStyle.grimace,
      armsUp: 0.25,
      stretch: -0.55,
      shake: 1.7,
      effect: PipEffect.dizzy,
    ),
    PipPose.hurt => const PipPoseTraits(
      bobScale: 0.14,
      swingScale: 0,
      rateScale: 0.3,
      lean: 0.1,
      brow: -0.3,
      eyeStyle: EyeStyle.squeezed,
      mouth: MouthStyle.grimace,
      armsUp: 0.15,
      stretch: -0.32,
      shake: 0.9,
      effect: PipEffect.impact,
    ),
    PipPose.tired => const PipPoseTraits(
      bobScale: 0.3,
      swingScale: 0.25,
      rateScale: 0.32,
      lean: 0.14,
      brow: -0.8,
      eyeOpen: 0.5,
      eyeStyle: EyeStyle.droopy,
      mouth: MouthStyle.flat,
      stretch: -0.12,
      effect: PipEffect.sweat,
    ),
    PipPose.cheering => const PipPoseTraits(
      bobScale: 1.4,
      swingScale: 0,
      rateScale: 1.3,
      brow: 0.8,
      eyeStyle: EyeStyle.happy,
      mouth: MouthStyle.open,
      mouthOpen: 1,
      armsUp: 1,
      stretch: 0.3,
    ),
  };
}
