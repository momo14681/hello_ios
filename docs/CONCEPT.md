# Cairn — Document de conception

> Chaque session de concentration te fait avancer. Pip traverse un monde, et tu laisses une trace.

**Statut :** concept validé, avant Phase 0
**Plateforme :** iOS d'abord (Flutter), Android sans réécriture plus tard
**Modèle :** freemium + abonnement
**Contrainte fondatrice :** aucun outil de design. Tout le visuel est écrit en Dart.

---

## 1. Le pitch

Le minuteur de concentration est une catégorie prouvée — des millions d'utilisateurs —
mais **personne ne la possède** : les quatre acteurs mesurés plafonnent à 31k, 14k, 10k
et 7k avis. Aucun leader écrasant, contrairement au suivi d'habitudes (144k pour le
premier).

Et la fonction sous-jacente est un compte à rebours de 25 minutes. Il n'y a rien à
construire techniquement : **100 % de la différenciation est l'expérience**.

**La faiblesse structurelle de Forest**, le géant du secteur : l'arbre est *ponctuel*.
Une session = un arbre. Tu ne reviens pas demain pour ta forêt, tu l'oublies.

**Cairn est cumulatif.** Tu n'as pas « fait 4 sessions aujourd'hui » — tu es à 12 km du
col. Chaque session dépose un cairn sur ton chemin. Ton historique devient un paysage.

---

## 2. Identité

### Nom
**Cairn** — l'empilement de pierres qui marque un sentier de montagne pour ceux qui
suivent. Se prononce identiquement en français et en anglais, le visuel est déjà dans
le mot, et l'icône (trois pierres empilées) se dessine en vingt lignes de code.

### La mascotte : Pip
Un petit galet vivant. Rond, chaud, deux yeux immenses, un sac à dos surmonté d'un
fanion, et une lanterne qui s'allume à la tombée du jour. Il marche, campe — et empile
des cairns derrière lui.

**Pourquoi un galet :** l'identité est bouclée (une pierre qui empile des pierres), et
surtout **il se dessine intégralement à partir de primitives géométriques** — cercles,
capsules, courbes de Bézier. Aucun logiciel de dessin nécessaire.

#### Les règles de proportion

L'attachement tient à la **néoténie** : des proportions de bébé. Trois leviers, dans
l'ordre d'importance :

1. **Les yeux sont gros et placés sous le centre du corps.** C'est le levier le plus
   puissant et le plus contre-intuitif — hauts et petits, ils donnent immédiatement un
   air adulte et sévère.
2. **Les membres sont courts et épais.** Jamais fins. Seules les extrémités des jambes
   dépassent du corps, ce qui donne de petits pieds ronds.
3. **Joues rosées, petite bouche, sourcils très discrets.** Des sourcils marqués
   annulent tout le reste ; ils ne servent qu'à nuancer l'expression.

Deux reflets par œil — un grand en haut à gauche, un petit en bas à droite. C'est cette
paire qui transforme un point noir en regard.

#### Le découpage du corps

Pip n'a pas de cou. Sans zones franches, le visage et l'équipement se marchent dessus —
trois erreurs successives l'ont prouvé : un col d'écharpe en travers de la figure, des
bretelles qui descendaient au milieu du visage comme des larmes, une veine minérale qui
se lisait comme un bavoir.

Les règles qui en découlent :

- le **visage occupe tout le centre** du corps, et rien d'autre n'y passe
- la **marque minérale** est une courte strie d'angle, en haut à gauche, jamais un motif
  traversant
- la **bretelle** épouse le bord gauche et s'arrête sous le visage
- la **lanterne** pend **hors** de la silhouette — posée dessus, elle se lit comme une
  excroissance

#### Pourquoi un fanion, et pas une écharpe

Une écharpe s'enroule autour d'un **cou**. Pip n'en a pas, et aucun réglage ne rattrape
ça : deux pans flottant derrière un corps rond se lisent comme un bras, une queue, ou
rien du tout. Le problème était anatomique, pas graphique.

Le **fanion planté sur le sac** le règle à la racine : il n'exige aucune anatomie, il
ondule donc conserve le mouvement secondaire qu'apportait l'écharpe, il grandit la
silhouette — ce qui aide énormément la reconnaissance en petit — et il colle au propos :
un fanion marque un sommet comme un cairn marque un sentier.

#### Les réactions

Neuf poses, définies chacune par une ligne de coefficients dans `PipPoseTraits.of` :
`idle`, `walking`, `resting`, `stacking`, puis les réactions `surprised`, `bumped`,
`hurt`, `tired`, `cheering`.

**La forme des yeux porte l'émotion**, bien avant la bouche ou les sourcils :
`normal`, `wide` (étonnement), `happy` (les arcs `^^` de la joie), `squeezed` (les
`><` de la douleur), `swirl` (spirales d'étourdissement), `droopy` (fatigue).

S'y ajoutent trois effets — goutte de sueur, étoiles d'étourdissement, éclats
d'impact — plus un tremblement horizontal et un étirement vertical.

**Ajouter une émotion coûte une ligne**, jamais une modification du painter. C'est la
propriété qui rend l'expressivité bon marché ici.

### Règle d'or : jamais punitif
Forest tue ton arbre si tu quittes l'app. **Cairn ne punit pas.** Si tu sors, Pip
s'assoit et monte le camp là où il est. Tu ne perds rien — tu ne gagnes simplement pas
de cairn. La récompense est l'achèvement, pas la peur de l'échec.

---

## 3. La stratégie visuelle sans aucun outil

C'est la section la plus importante du document. Tu n'as ni Rive, ni Lottie, ni After
Effects — et tu n'en auras pas besoin.

### Ce qu'on écrit en Dart (100 % du visuel identitaire)

| Élément | Technique | Pourquoi c'est faisable |
|---|---|---|
| **Pip** | `CustomPainter` + primitives | Un corps = une capsule à coins arrondis. Deux yeux = deux ovales. Le clignement = un `scaleY` vers 0. |
| **Cycle de marche** | sinusoïdes déphasées | Corps en `sin(t)`, jambes en `sin(t + π)`, ombre qui s'écrase. C'est de la trigonométrie, pas de l'animation. |
| **Le paysage** | 5 couches de `Path` en parallaxe | Chaque colline = une somme de sinusoïdes. Défilement à vitesses différentes. Monde infini, zéro image. |
| **Ciel & heure du jour** | `LinearGradient` interpolé | Les couleurs glissent selon l'heure réelle et l'altitude atteinte. |
| **Le cairn** | pierres empilées + ressort | Chaque pierre tombe avec `elasticOut`. Le moment de récompense. |
| **Transitions** | `flutter_animate` | Trois lignes par effet, enchaînables. |

**Conséquence majeure : le monde entier est procédural.** Aucun fichier image, aucune
animation exportée. L'app pèse quelques mégaoctets, tourne à 60 fps, et chaque paramètre
visuel est un nombre que tu peux ajuster dans le code.

### Preuve que Pip tient en code

```dart
class PipPainter extends CustomPainter {
  final double t;          // temps continu, 0→1 en boucle
  final bool walking;
  final double blink;      // 1 = ouvert, 0 = fermé

  @override
  void paint(Canvas canvas, Size size) {
    final bob    = walking ? sin(t * 2 * pi) * 3 : sin(t * 2 * pi) * 1.2;
    final squash = 1 + sin(t * 2 * pi) * 0.04;   // squash & stretch

    // Ombre — s'écrase quand Pip est haut
    canvas.drawOval(
      Rect.fromCenter(center: Offset(0, 34), width: 30 - bob, height: 7),
      Paint()..color = Colors.black.withOpacity(0.18),
    );

    // Jambes — deux capsules déphasées
    for (final side in [-1.0, 1.0]) {
      final swing = walking ? sin(t * 2 * pi + (side > 0 ? pi : 0)) * 6 : 0.0;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(side * 7 + swing, 26), width: 7, height: 12),
          const Radius.circular(4),
        ),
        Paint()..color = const Color(0xFF6B5B95),
      );
    }

    // Corps — un galet, dégradé chaud
    final body = Rect.fromCenter(
      center: Offset(0, bob), width: 44 * squash, height: 40 / squash);
    canvas.drawRRect(
      RRect.fromRectAndRadius(body, const Radius.circular(20)),
      Paint()..shader = const LinearGradient(
        colors: [Color(0xFFFFD9A0), Color(0xFFE8A87C)],
        begin: Alignment.topCenter, end: Alignment.bottomCenter,
      ).createShader(body),
    );

    // Yeux — le clignement écrase la hauteur
    for (final side in [-1.0, 1.0]) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(side * 9, bob - 3), width: 7, height: 9 * blink),
        Paint()..color = const Color(0xFF2E2A3F),
      );
    }
  }

  @override
  bool shouldRepaint(PipPainter old) =>
      old.t != t || old.walking != walking || old.blink != blink;
}
```

Une centaine de lignes suffisent pour un personnage vivant, expressif, et réglable au
pixel près. **Aucun outil externe.**

### Preuve que le paysage tient en code

```dart
/// Une couche de collines : somme de sinusoïdes, déterministe par `seed`.
Path hillLayer(Size size, double scroll, int seed, double amp, double baseY) {
  final rnd = Random(seed);
  final a = List.generate(3, (_) => rnd.nextDouble() * amp);
  final f = List.generate(3, (_) => 0.002 + rnd.nextDouble() * 0.006);
  final p = List.generate(3, (_) => rnd.nextDouble() * 2 * pi);

  final path = Path()..moveTo(0, size.height);
  for (double x = 0; x <= size.width; x += 3) {
    final wx = x + scroll;
    final y = baseY
        + a[0] * sin(wx * f[0] + p[0])
        + a[1] * sin(wx * f[1] + p[1])
        + a[2] * sin(wx * f[2] + p[2]);
    path.lineTo(x, y);
  }
  return path..lineTo(size.width, size.height)..close();
}
```

Cinq appels avec des `seed`, `amp` et vitesses de défilement différentes → un monde en
parallaxe, infini, jamais deux fois le même, et qui pèse zéro octet.

### Ce qu'on peut récupérer sur internet (et ce qu'on ne récupère jamais)

| ✅ À récupérer | Source | Licence |
|---|---|---|
| Polices | `google_fonts` | Open Font License |
| Icônes d'interface | `lucide_icons` / `phosphor_flutter` | MIT / libre |
| Sons courts (pas / cairn / fin de session) | freesound.org | Creative Commons — **vérifier chaque fichier** |
| Effets génériques ponctuels (confettis) | lottiefiles.com, section gratuite | variable — **vérifier** |

| ❌ À ne jamais récupérer | Raison |
|---|---|
| **Pip** | Une identité visuelle ne se télécharge pas. Des fichiers glanés donnent un personnage incohérent d'un écran à l'autre — exactement le contraire d'une vraie identité. |
| Le paysage | Procédural = infini et gratuit. Des images = finies et lourdes. |

---

## 4. Les boucles

### Boucle de session (25 min par défaut)
1. Tu choisis une durée, tu appuies sur **Partir**
2. Pip se met en marche. Le paysage défile lentement — **calme, pas agité**
3. La distance parcourue = le temps de concentration
4. À la fin : Pip s'arrête et **empile un cairn**, pierre après pierre, en ressort
5. La distance s'ajoute à l'expédition en cours

**Mettre le téléphone en veille ne change rien.** La session tourne sur horodatage et
continue. C'était initialement un abandon automatique — une erreur : iOS envoie le même
`AppLifecycleState.paused` quand on verrouille l'écran et quand on bascule vers une
autre app, et **poser son téléphone est exactement ce qu'on attend d'une app de
concentration**. Le mécanisme punissait le bon geste.

**Camper reste volontaire :** le bouton arrête la session. La distance parcourue reste
acquise, mais aucun cairn n'est posé.

### Boucle d'expédition (l'arc long — ce que Forest n'a pas)
Une expédition est un itinéraire thématique jalonné d'**étapes** placées à des distances
croissantes : un col, un lac, une forêt, un sommet. Tu vois toujours la prochaine étape
et ce qui t'en sépare.

C'est le mécanisme de rétention : *« plus que 12 km avant le col »* est une raison
concrète de rouvrir l'app demain. Un arbre planté hier n'en est pas une.

### La carte
Vue dézoomée : ton itinéraire complet, tous les cairns que tu as posés, les étapes
franchies et celles à venir. **C'est l'équivalent de la grille GitHub de HabitKit** —
un historique qui s'accumule et qu'on a envie de regarder.

---

## 5. Direction artistique

**Principe :** un monde chaud et calme, lisible d'un coup d'œil, qui ne distrait jamais
pendant une session. Le mouvement est lent. Rien ne clignote.

### Palette

| Rôle | Couleur | Usage |
|---|---|---|
| Ciel (jour) | `#FFD9A0` → `#8FB8DE` | dégradé haut/bas |
| Ciel (soir) | `#F5A17A` → `#4A3D6B` | selon l'heure réelle |
| Collines lointaines | `#9BA8C4` | opacité faible, parallaxe lente |
| Collines proches | `#4A5568` | parallaxe rapide |
| Pip | `#FFD9A0` → `#E8A87C` | dégradé du corps |
| Détail Pip | `#6B5B95` | jambes, sac, écharpe |
| Cairn | `#8B7E6D` | pierres |
| Accent premium | `#E8A87C` | Cairn+ |

Le ciel évolue avec **l'heure réelle du téléphone** : une session à 7 h et une à 21 h ne
se ressemblent pas. Gratuit à implémenter, énorme en perception de soin.

### Typographie
- **Titres :** une géométrique chaleureuse (Nunito ou Outfit, via `google_fonts`)
- **Chiffres du minuteur :** une police à chasse fixe pour que les chiffres ne dansent pas

### Mouvement
- Durées : `fast 150ms` / `base 250ms` / `slow 400ms` / `celebrate 900ms`
- Courbes : `easeOutCubic` par défaut, `elasticOut` réservé à Pip et aux pierres
- **Règle : pendant une session, rien ne bouge sauf Pip et le paysage.** Aucune interface
  animée, aucune notification visuelle. L'app doit être ennuyeuse à regarder — c'est le
  but d'une app de concentration.

---

## 6. Onboarding

Règle absolue : **partir avant de s'inscrire.**

| # | Écran | Contenu |
|---|---|---|
| 0 | Éveil | Un paysage vide au lever du jour. Pip arrive en marchant depuis le bord. ~3 s, aucun texte |
| 1 | Présentation | « Voici Pip. Il aimerait traverser le monde. » |
| 2 | **Première session immédiate** | Un essai de **60 secondes**, tout de suite. Pip marche, tu regardes. À la fin, il empile son premier cairn. ← le moment qui décide de tout |
| 3 | La promesse | La carte se dézoome : le premier cairn est minuscule face à l'itinéraire. « Chaque session compte. » |
| 4 | Rendez-vous | « À quelle heure travailles-tu le mieux ? » → notification locale |
| 5 | Départ | Choix de la première expédition |

Le paywall **n'apparaît pas avant le jour 3**.

---

## 7. Monétisation

### Gratuit
- Une expédition complète (longue — plusieurs semaines de sessions)
- Durées de session libres
- Carte, cairns, historique
- Pip dans son apparence d'origine

### Cairn+ — ~3,99 €/mois · 24,99 €/an · essai 7 jours
- Toutes les expéditions + une nouvelle chaque saison
- Statistiques détaillées (heures de pointe, régularité)
- Ambiances sonores pendant les sessions
- Garde-robe de Pip (écharpes, sacs, chapeaux) — purement cosmétique
- Thèmes de paysage (désert, banquise, nuit étoilée)

**Principe :** le gratuit doit tenir des semaines sans frustrer. On monétise la
**variété et la personnalisation**, jamais le temps de concentration lui-même.
Faire payer pour se concentrer serait indéfendable.

---

## 8. Architecture

```
lib/
  main.dart
  app/            # bootstrap, routing (go_router), thème
  design/         # tokens : couleurs, typo, durées, courbes
  core/           # utils, extensions, Result
  domain/         # Session, Expedition, Leg, Cairn, Progress
  data/           # persistance locale (Drift), repositories
  features/
    onboarding/
    session/      # le minuteur et son écran
    map/          # la carte de l'expédition
    stats/
    paywall/
    settings/
  world/          # ⭐ le cœur visuel
    pip/          #    personnage : painter, états, cycle de marche
    landscape/    #    collines procédurales, parallaxe, ciel
    cairn/        #    empilement des pierres
  audio/          # sons courts, ambiances
```

### Packages

| Besoin | Package | Note |
|---|---|---|
| Polish UI | `flutter_animate` | meilleur rapport effort/résultat |
| Polices | `google_fonts` | |
| Persistance | `drift` | SQLite, robuste, fonctionne sur Windows en dev |
| Rappels | `flutter_local_notifications` | **fonctionne sur compte Apple gratuit** |
| État | `riverpod` | testable, sans BuildContext |
| Navigation | `go_router` | |
| Audio | `just_audio` | sons courts + ambiances |
| Achats | `purchases_flutter` (RevenueCat) | **plus tard**, derrière l'interface |

**Aucun package d'animation externe.** Ni `rive`, ni `lottie` pour l'identité.

### Le minuteur doit survivre à l'arrière-plan

Piège classique : les `Timer` Dart s'arrêtent quand iOS suspend l'app. La solution ne
demande aucun plugin natif :

```dart
// On ne fait jamais tourner un compteur. On stocke l'instant de départ
// et on recalcule l'écoulé à chaque reprise.
final startedAt = DateTime.now();
final elapsed   = DateTime.now().difference(startedAt);
```

Une notification locale est programmée pour l'heure de fin, donc l'utilisateur est
prévenu même app fermée. 100 % Dart.

### Isolation des achats

L'In-App Purchase n'est pas testable sur compte Apple gratuit :

```dart
abstract class PurchaseService {
  Stream<Entitlement> get entitlement;
  Future<void> restore();
  Future<PurchaseResult> purchase(SubscriptionPlan plan);
}
// FakePurchaseService       → dev sur Windows, basculable en debug
// RevenueCatPurchaseService → le jour du passage au compte payant
```

---

## 9. Contraintes du pipeline

Développement sur **Windows sans Mac**, builds via GitHub Actions macOS, sideload avec
compte Apple gratuit :

- **100 % Dart, zéro plugin natif critique** → hot-reload sur Windows, build iOS environ
  une fois par semaine pour valider sur appareil réel
- **Offline-first** → aucun serveur, aucun coût fixe
- **Notifications locales uniquement** → les push exigent un compte payant
- **Interdits :** HealthKit, ScreenTime, ARKit, Live Activities, widgets, CloudKit
- Certificat gratuit **expirant tous les 7 jours** → réinstallation hebdomadaire en dev

Le caractère procédural du visuel sert directement ce pipeline : tout se prévisualise
sur Windows à 60 fps, sans jamais attendre un build iOS.

---

## 10. Feuille de route

L'ordre est inversé par rapport à un projet classique : ici **le visuel *est* le produit**,
donc il vient en premier.

| Phase | Durée | Contenu |
|---|---|---|
| ~~**0**~~ ✅ | 3 j | Fondations : archi, design tokens, thème, routing, `PurchaseService` factice |
| ~~**1**~~ ✅ | 1 sem. | **Pip** : painter, cycle de marche, clignement, états (marche / assis / campe / empile) + un banc d'essai avec curseurs pour régler chaque paramètre |
| ~~**2**~~ ✅ | 1 sem. | **Le paysage** : collines procédurales, parallaxe, ciel selon l'heure |
| ~~**3**~~ ✅ | 4 j | **La session** : minuteur résistant à l'arrière-plan, cycle de vie, notification locale, empilement du cairn, réactions de Pip |
| ~~**4**~~ ✅ | 1 sem. | **L'expédition** : carte, étapes, cairns persistés, progression |
| **5** | 4 j | Onboarding animé |
| **6** | 4 j | Statistiques, réglages, ambiances sonores |
| **7** | — | Paywall (Fake), polish, puis compte Apple Developer + RevenueCat + soumission |

### Le banc d'essai de la Phase 1
Un écran de développement, jamais livré, avec un curseur par paramètre de Pip : vitesse
de marche, amplitude du rebond, squash, fréquence de clignement, taille des yeux.
**C'est ton After Effects** — sauf qu'il est en Dart, et que tu le pilotes au hot-reload.

### Quand payer les 99 $/an
Le jour où tu utilises l'app quotidiennement pendant deux semaines sans que ça t'agace.
Pas avant.

---

## 11. Ce qui reste risqué

- **La rétention en focus timer est difficile.** L'expédition est ma réponse à ce
  problème, mais c'est une hypothèse à vérifier sur toi-même dès la Phase 4.
- **Forest a une notoriété immense.** On ne l'attaque pas frontalement : on vise le
  mot-clé « pomodoro », que ses chiffres montrent qu'il ne domine pas.
- **Le calme est un pari.** Une app volontairement peu spectaculaire pendant l'usage,
  c'est juste — mais ça rend la fiche App Store plus difficile à vendre. Les captures
  d'écran devront porter la carte et les cairns, pas la session elle-même.
