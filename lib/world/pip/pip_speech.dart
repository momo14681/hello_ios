import 'pip_params.dart';

/// Ce que dit Pip quand il réagit.
///
/// Les répliques ne sortent que sur les **réactions**, jamais pendant la marche
/// ordinaire : une app de concentration ne doit pas bavarder. Et aucune ne
/// culpabilise — c'est la règle d'or du personnage.
abstract final class PipSpeech {
  static const _tired = [
    'Juste une petite pause et je repars !',
    'Ouf… j\'ai les cailloux qui fatiguent.',
    'Encore un peu, on y est presque.',
    'Je souffle deux secondes.',
  ];

  static const _bumped = [
    'Aïe ! Je n\'avais pas vu ce caillou.',
    'Oups… rien de cassé !',
    'Qui a mis ça là ?',
    'Je me relève, je me relève.',
  ];

  static const _hurt = [
    'Ouille.',
    'Ça, ça pique un peu.',
    'Bon. Ça ira.',
  ];

  static const _surprised = [
    'Oh ! Tu as vu ça ?',
    'Tiens, c\'est nouveau.',
    'Oh là !',
    'Qu\'est-ce que c\'est que ça ?',
  ];

  static const _cheering = [
    'On y est !',
    'Quelle vue d\'ici !',
    'Une pierre de plus au cairn.',
    'On avance, toi et moi.',
  ];

  static const _resting = [
    'Je t\'attends ici.',
    'Bon bivouac.',
    'On repart quand tu veux.',
  ];

  /// La réplique associée à [pose], ou `null` s'il n'y a rien à dire.
  ///
  /// [seed] fait varier le choix d'un incident à l'autre tout en restant
  /// **déterministe** : la même réaction affiche toujours la même phrase, y
  /// compris après un passage en arrière-plan.
  static String? lineFor(PipPose pose, int seed) {
    final lines = switch (pose) {
      PipPose.tired => _tired,
      PipPose.bumped => _bumped,
      PipPose.hurt => _hurt,
      PipPose.surprised => _surprised,
      PipPose.cheering => _cheering,
      PipPose.resting => _resting,
      _ => const <String>[],
    };
    if (lines.isEmpty) return null;
    return lines[seed.abs() % lines.length];
  }
}
