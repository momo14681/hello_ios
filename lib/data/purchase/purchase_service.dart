/// Ce que l'utilisateur a débloqué.
enum Entitlement { free, plus }

/// Formules d'abonnement Cairn+. Voir CONCEPT.md §7.
enum SubscriptionPlan {
  monthly(id: 'cairn_plus_monthly', label: 'Mensuel', price: '3,99 €'),
  yearly(id: 'cairn_plus_yearly', label: 'Annuel', price: '24,99 €');

  const SubscriptionPlan({
    required this.id,
    required this.label,
    required this.price,
  });

  final String id;
  final String label;
  final String price;
}

sealed class PurchaseResult {
  const PurchaseResult();
}

class PurchaseSuccess extends PurchaseResult {
  const PurchaseSuccess(this.entitlement);
  final Entitlement entitlement;
}

class PurchaseCancelled extends PurchaseResult {
  const PurchaseCancelled();
}

class PurchaseFailed extends PurchaseResult {
  const PurchaseFailed(this.message);
  final String message;
}

/// Frontière avec le magasin d'applications.
///
/// Aucune ligne de logique métier ne connaît RevenueCat. L'In-App Purchase
/// n'étant pas testable sur un compte Apple gratuit, on développe contre
/// [FakePurchaseService] et on bascule sur l'implémentation réelle le jour du
/// passage au compte payant. Voir CONCEPT.md §8.
abstract interface class PurchaseService {
  Stream<Entitlement> get entitlement;
  Entitlement get current;
  Future<void> restore();
  Future<PurchaseResult> purchase(SubscriptionPlan plan);
  void dispose();
}
