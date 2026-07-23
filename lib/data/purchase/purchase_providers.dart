import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'fake_purchase_service.dart';
import 'purchase_service.dart';

/// Le service d'achat de l'application.
///
/// Tant que le compte Apple est gratuit, c'est [FakePurchaseService]. Le
/// passage à RevenueCat le jour venu se fait en changeant cette seule ligne.
final purchaseServiceProvider = Provider<PurchaseService>((ref) {
  final service = FakePurchaseService();
  ref.onDispose(service.dispose);
  return service;
});

/// Ce que l'utilisateur a débloqué, en temps réel.
final entitlementProvider = StreamProvider<Entitlement>((ref) {
  final service = ref.watch(purchaseServiceProvider);
  return service.entitlement;
});

/// Raccourci synchrone pour les gardes d'interface.
final isPlusProvider = Provider<bool>((ref) {
  return ref.watch(entitlementProvider).value == Entitlement.plus;
});
