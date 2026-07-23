# Cairn — mise en route

## Lancer l'app

**Web (recommandé pour l'instant)** — hot reload, aucun outil natif requis :

```bash
flutter run -d chrome
```

**Windows desktop** — actuellement bloqué. Visual Studio Community 2026 est installé
mais il manque le module **« Développement Desktop en C++ »**. Pour le débloquer :
ouvrir Visual Studio Installer → Modifier → cocher *Desktop development with C++* →
Installer (~7 Go). Ensuite :

```bash
flutter run -d windows
```

Windows desktop donne une image plus fidèle des performances réelles que le web.
Ça vaut le coup une fois que le paysage sera plus chargé, mais rien ne presse.

**iOS** — via GitHub Actions, environ une fois par semaine pour valider sur appareil.
Voir `.github/workflows/ios-build.yml`.

## Vérifier

```bash
flutter analyze && flutter test
```

## Capturer l'écran réel — touche F12

Les tests de rendu montrent ce que produisent les *painters*. Ils ne montrent **pas** la
mise en page, les marges, les polices réelles ni les panneaux.

En `kDebugMode`, **F12 écrit une capture de l'écran courant** dans `build/preview`
(ou dans `CAIRN_CAPTURE_DIR` si la variable est définie). Le chemin absolu s'affiche
dans une bannière et dans la console.

```bash
flutter run -d windows
```

Puis F12 sur l'écran à examiner. C'est le moyen le plus fiable de faire relire une mise
en page : le PNG contient exactement ce que l'app affiche.

Indisponible sur le web, faute de système de fichiers accessible — `DebugCapture` y
laisse simplement passer son enfant.

## Trois pièges de mise en page, tous trouvés par capture

Aucun n'était visible autrement : l'app compilait, les tests passaient, et rien
n'avertissait.

**1. Rien ne bornait la largeur.** Cairn est dessiné pour un téléphone ; dans une fenêtre
de 2500 px, le bouton « Partir » devenait une barre pleine largeur et les cartes de la
boutique se tassaient à gauche d'un vide immense. `ContentWidth` borne et centre.

**2. `Center` s'étire verticalement** dès que ses contraintes sont lâches. Le panneau de
session, de quelques lignes, devenait un rectangle blanc plein écran. D'où le
`heightFactor: 1` dans `ContentWidth`, et `mainAxisSize.min` sur les colonnes de panneau.

**2 bis. Le même piège se répète.** `Align` s'étire exactement comme `Center` : le bouton
« Camper » d'une session en cours se retrouvait centré au milieu de l'écran. Règle à
retenir — **pour pousser un enfant dans un coin, utiliser une `Row` ou une `Column` avec
`mainAxisAlignment`**, jamais un `Align` nu, sauf à borner explicitement sa hauteur.

**3. Ce qui déborde n'est plus cliquable.** Une `Column` avec `Spacer` débordait d'un
pixel sur écran court ; Flutter rogne, et la zone rognée cesse de répondre au doigt. Le
bouton restait parfaitement visible et parfaitement mort. Remplacé par un `Stack` aligné
en bas, qui ne peut structurellement pas déborder.

### Et le corollaire : ne pas reconstruire tout l'écran sur un battement

`SessionScreen` se reconstruisait cinq fois par seconde. L'animation d'entrée du panneau
repartait donc à chaque battement et n'atteignait jamais sa position finale : la carte
restait décalée de 45 px, bouton visible mais intouchable.

Deux corrections, à conserver :

- `_Ticking` isole le sous-arbre qui dépend du temps (le monde, l'horloge). Le reste ne
  se reconstruit que sur changement d'état.
- Le panneau **n'a plus d'animation d'entrée**. Sur un écran de concentration, rien ne
  doit bouger sauf Pip et le paysage — la règle du concept était déjà la bonne.

Le test `le panneau reste en bas et ne mange pas l'écran` verrouille le cas.

## Le monde change avec l'itinéraire

`WorldTheme` associe à chaque expédition ses couleurs de collines, la forme de son décor
dressé (`DecorStyle` : conifères, aiguilles rocheuses, éclats de glace) et une teinte de
ciel mêlée à l'heure courante. Trois thèmes pour l'instant : montagne, désert, banquise.

Le choix d'itinéraire vit sur **la carte**, pas dans la boutique : c'est là qu'on regarde
son chemin, donc là qu'on a envie d'en changer. La boutique ne fait que débloquer.

## Relire le dessin sans lancer l'app

`test/preview_render_test.dart` rend le monde dans des PNG. Comme tout est
procédural, c'est le moyen le plus rapide de juger une modification de painter —
pas besoin d'appareil, ni même de navigateur.

```bash
CAIRN_PREVIEW_DIR=build/preview flutter test test/preview_render_test.dart
```

Quatre images sont produites dans `build/preview` : `world_day`, `world_dusk`,
`world_night` et `pip_closeup`. Sans la variable d'environnement, le test vérifie
seulement que le rendu produit bien des pixels et n'écrit rien.

## Carte du code

| Chemin | Rôle |
|---|---|
| `lib/design/` | Jetons (couleurs, durées, courbes) et thème. Aucune valeur visuelle ailleurs. |
| `lib/domain/` | Modèles purs, sans dépendance Flutter. `FocusSession`, `Expedition`, `Cairn`. |
| `lib/data/purchase/` | Frontière avec le magasin. `FakePurchaseService` tant que le compte Apple est gratuit. |
| `lib/world/` | **Le cœur visuel.** Tout est procédural, aucun asset. |
| `lib/world/pip/` | Pip : paramètres, poses, painter. |
| `lib/world/landscape/` | Collines en sommes de sinusoïdes, parallaxe. |
| `lib/world/cairn/` | Empilement des pierres. |
| `lib/features/devbench/` | Le banc d'essai. **Jamais livré en production.** |

## Le banc d'essai

Accueil → bouton **Banc d'essai**, ou directement la route `/bench`.

Un curseur par paramètre de Pip, plus la pose, la vitesse de défilement et l'heure du
jour. C'est le remplacement de Rive : on règle des nombres au hot-reload.

Quand un réglage est bon, on le reporte dans les valeurs par défaut de
`PipParams` (`lib/world/pip/pip_params.dart`).

**Avant la première soumission App Store :** retirer la route `/bench` de
`lib/app/router.dart` et le bouton correspondant de l'accueil.

## Le minuteur et l'arrière-plan

`FocusSession` ne fait jamais tourner de `Timer` : il stocke `startedAt` et recalcule
l'écoulé à la demande. C'est ce qui le rend immunisé à la suspension de l'app par iOS.
Ne pas introduire de compteur qui s'incrémente — ça casserait la session dès que le
téléphone se verrouille.

## État d'avancement

- [x] **Phase 0** — architecture, jetons, thème, routeur, `PurchaseService` factice
- [x] **Phase 1** — Pip procédural, poses, banc d'essai
- [x] **Phase 2** — paysage procédural, parallaxe, ciel selon l'heure (livrée en avance :
      Pip avait besoin d'un sol pour que le banc d'essai ait du sens)
- [x] **Phase 3** — boucle de session, réactions, notification locale, cairn posé
- [x] **Phase 4** — expédition persistée, carte, étapes franchies
- [ ] **Phase 5** — onboarding animé
- [ ] **Phase 6** — statistiques, réglages, ambiances sonores
- [ ] **Phase 7** — paywall, compte Apple Developer, soumission

## L'expédition

`ExpeditionCatalog` contient la **définition** des itinéraires — donnée statique, jamais
persistée. `ExpeditionProgress` contient l'**avancement** — c'est la seule chose stockée.
`ExpeditionView` réunit les deux pour l'interface.

Une minute de concentration vaut 100 m. La première traversée fait 40 km, soit environ
quinze sessions de 25 minutes : le gratuit tient plusieurs semaines, ce qui est la
condition des avis 5★.

`ExpeditionController.recordSession` renvoie les étapes **nouvellement** franchies, ce qui
permet à l'écran de session de célébrer le franchissement plutôt que d'afficher un bilan
générique.

## Pourquoi pas Drift, pour l'instant

Le volume est minuscule — un itinéraire actif et une liste de cairns — et aucune requête
n'est nécessaire : tout est chargé d'un bloc au démarrage. En face, Drift coûterait
`build_runner` sur chaque modification de schéma, plus `sqlite3.wasm` et `drift_worker.js`
à installer dans `web/` — ce qui casserait la cible de développement actuelle.

`ExpeditionRepository` isole la décision. Drift viendra quand les statistiques exigeront
de vrais agrégats, pas avant.

## La garde-robe et les éclats

Les **éclats** se gagnent en menant une session à terme : un par tranche de 5 minutes,
plus 15 par étape franchie. Un abandon n'en rapporte pas — pas pour punir, mais parce
que l'éclat récompense l'achèvement, exactement comme le cairn.

`WardrobeCatalog` liste les articles, `Inventory` détient la bourse, ce qui est possédé
et ce qui est porté, `WardrobeCatalog.outfitOf` traduit tout ça en `PipOutfit` que le
painter consomme. Ajouter un accessoire ne demande donc qu'une entrée de catalogue — et
une branche dans `PipHats` s'il s'agit d'une coiffe.

**Les itinéraires premium s'obtiennent de deux façons** : Cairn+ les ouvre immédiatement,
les éclats permettent d'y arriver en jouant (700 et 1100). C'est délibéré : le joueur
gratuit a un horizon, l'abonné paie l'immédiateté. À surveiller quand le paywall
arrivera — si l'abonnement ne se vend pas, c'est le premier levier à rééquilibrer.

En debug, un bouton de la boutique crédite 250 éclats : sans lui, tester la boutique
demanderait des heures de concentration réelles.

## Relire la carte

Le test de rendu produit aussi `expedition_map.png`. Attention : dans `flutter test`, la
police par défaut est **Ahem**, qui dessine des rectangles pleins à la place du texte.
Les étiquettes d'étapes apparaissent donc comme des blocs sombres sur l'image — c'est
normal, elles s'affichent correctement dans l'app.

## La boucle de session

`SessionController` (Riverpod) pilote quatre phases : `idle`, `running`, `camped`,
`finished`. Quitter l'app pendant une session fait camper Pip — rien n'est perdu, mais
aucun cairn n'est posé. Aller au bout pose le cairn.

`ReactionDirector` décide de ce que fait Pip à chaque instant. Le plan des incidents est
**tiré une fois** à partir d'une graine, puis `poseAt(elapsed)` devient une fonction pure
du temps écoulé. Deux conséquences : la scène est identique après un passage en
arrière-plan, et tout se teste sans horloge ni aléatoire.

Un incident survient toutes les 55 à 135 secondes (choc, étonnement, douleur), jamais
dans les 40 premières secondes ni dans les 12 dernières. Au-delà de 72 % d'une session
d'au moins 15 minutes, Pip fatigue.

## Notifications

`ReminderService` a deux implémentations : `LocalReminderService` sur mobile et desktop,
`NoopReminderService` sur le web. Le greffon expose bien une implémentation web depuis
la v22, mais une notification planifiée n'y part pas de façon fiable quand l'onglet
passe en arrière-plan — mieux vaut ne rien promettre.

Attention en reprenant des exemples trouvés en ligne : depuis la **v22**, `initialize`,
`zonedSchedule` et `cancel` prennent des paramètres **nommés**. La quasi-totalité des
extraits en circulation utilise encore l'ancienne forme positionnelle.

`InitializationSettings` exige un bloc **par plateforme ciblée**. Il en manquait un pour
Windows, et `initialize` levait `ArgumentError('Windows settings must be set...')`.

### La règle : un rappel ne bloque jamais une session

C'est ce qui rendait le bouton « Partir » inerte sur Windows. Trois protections
désormais, à conserver :

1. `LocalReminderService` ne lève **jamais** — chaque méthode avale ses erreurs et le
   service se désactive après un premier échec.
2. `SessionScreen._start` démarre la session **avant** de demander l'autorisation, au lieu
   de l'attendre.
3. Tout appel en tâche de fond porte un `catchError`. `unawaited` seul ne suffit pas :
   sans gestionnaire, l'échec remonte en erreur asynchrone non traitée.

Le test `la session démarre même si les notifications échouent` verrouille l'invariant
avec un service qui lève à chaque appel.

## La carte

`TrailPainter` dessine un fond topographique — courbes de niveau concentriques, sommets
enneigés, forêts, lacs — semé de façon **déterministe** à partir de l'identifiant de
l'expédition : une carte donnée a toujours la même tête.

Chaque étape porte un pictogramme selon son `LegKind` (gué, forêt, crête, col, glace,
sommet, ruines, dunes), dessiné par `LegGlyphs`. Un point ne dit rien ; le pictogramme
donne son identité à chaque jalon.

Les étiquettes sont posées sur un fond papier : sans lui, elles deviennent illisibles dès
qu'elles passent sur du relief.

## Choix assumés à ce stade

**Pas encore de Drift.** La persistance n'a rien à stocker avant la Phase 4. Ajouter
`build_runner` maintenant, c'est de la friction de compilation sans contrepartie. Les
modèles du domaine sont déjà écrits pour être sérialisables le jour venu.

**Pas de `flutter_local_notifications` non plus.** Même raison : le plugin arrive en
Phase 3, quand il y aura une session à notifier.
