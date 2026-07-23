import '../../domain/expedition.dart';

/// Les itinéraires disponibles.
///
/// Une minute de concentration vaut 100 m (voir `FocusSession.distanceAt`).
/// La première traversée fait donc 40 km, soit environ 400 minutes — une
/// quinzaine de sessions de 25 minutes. Le gratuit doit tenir plusieurs
/// semaines sans frustrer : c'est lui qui fait les avis 5★.
abstract final class ExpeditionCatalog {
  static const firstCrossing = Expedition(
    id: 'first_crossing',
    name: 'La première traversée',
    subtitle: 'Des berges au sommet',
    legs: [
      Leg(name: 'Le gué', atMeters: 2000, kind: LegKind.water),
      Leg(name: 'La clairière', atMeters: 6000, kind: LegKind.forest),
      Leg(name: 'Les crêtes', atMeters: 13000, kind: LegKind.ridge),
      Leg(name: 'Le col', atMeters: 22000, kind: LegKind.pass),
      Leg(name: 'Le lac gelé', atMeters: 31000, kind: LegKind.ice),
      Leg(name: 'Le sommet', atMeters: 40000, kind: LegKind.summit),
    ],
  );

  static const amberDesert = Expedition(
    id: 'amber_desert',
    name: 'Le désert d\'ambre',
    subtitle: 'Marcher à la fraîche',
    isPremium: true,
    legs: [
      Leg(name: 'La dernière source', atMeters: 3000, kind: LegKind.water),
      Leg(name: 'Les dunes hautes', atMeters: 9000, kind: LegKind.dunes),
      Leg(name: 'La cité ensablée', atMeters: 18000, kind: LegKind.ruins),
      Leg(name: 'Le plateau de sel', atMeters: 30000, kind: LegKind.ridge),
      Leg(name: 'L\'oasis', atMeters: 45000, kind: LegKind.forest),
    ],
  );

  static const frozenShelf = Expedition(
    id: 'frozen_shelf',
    name: 'La banquise',
    subtitle: 'Six mois de nuit',
    isPremium: true,
    legs: [
      Leg(name: 'La rive gelée', atMeters: 4000, kind: LegKind.water),
      Leg(name: 'Le champ de séracs', atMeters: 12000, kind: LegKind.ice),
      Leg(name: 'La station abandonnée', atMeters: 24000, kind: LegKind.ruins),
      Leg(name: 'L\'aurore', atMeters: 38000, kind: LegKind.ridge),
      Leg(name: 'Le pôle', atMeters: 55000, kind: LegKind.summit),
    ],
  );

  static const all = [firstCrossing, amberDesert, frozenShelf];

  /// L'itinéraire offert, celui sur lequel tout le monde commence.
  static const initial = firstCrossing;

  static Expedition byId(String id) =>
      all.firstWhere((e) => e.id == id, orElse: () => initial);
}
