import 'dart:async';

import 'purchase_service.dart';

/// Implémentation de développement, utilisée sur Windows et tant que le compte
/// Apple est gratuit.
///
/// Elle simule la latence du magasin pour que les états de chargement de
/// l'interface soient réellement exercés pendant le développement.
class FakePurchaseService implements PurchaseService {
  FakePurchaseService({Entitlement initial = Entitlement.free})
    : _current = initial {
    _controller.add(_current);
  }

  final _controller = StreamController<Entitlement>.broadcast();
  Entitlement _current;

  @override
  Stream<Entitlement> get entitlement => _controller.stream;

  @override
  Entitlement get current => _current;

  @override
  Future<PurchaseResult> purchase(SubscriptionPlan plan) async {
    await Future<void>.delayed(const Duration(milliseconds: 900));
    _set(Entitlement.plus);
    return const PurchaseSuccess(Entitlement.plus);
  }

  @override
  Future<void> restore() async {
    await Future<void>.delayed(const Duration(milliseconds: 600));
    _set(_current);
  }

  /// Réservé au banc d'essai : permet de basculer l'état sans passer par un
  /// achat, pour vérifier les deux versions de chaque écran.
  void debugSet(Entitlement value) => _set(value);

  void _set(Entitlement value) {
    _current = value;
    _controller.add(value);
  }

  @override
  void dispose() => _controller.close();
}
