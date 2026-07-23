import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/wardrobe.dart';

abstract interface class WardrobeRepository {
  Future<Inventory?> load();
  Future<void> save(Inventory inventory);
}

class PrefsWardrobeRepository implements WardrobeRepository {
  static const _key = 'cairn.inventory';

  @override
  Future<Inventory?> load() async {
    final raw = (await SharedPreferences.getInstance()).getString(_key);
    if (raw == null) return null;
    try {
      return Inventory.fromJson(
        Map<String, Object?>.from(jsonDecode(raw) as Map),
      );
    } on FormatException {
      // Donnée corrompue : on repart de la garde-robe de départ plutôt que de
      // bloquer l'app.
      return null;
    }
  }

  @override
  Future<void> save(Inventory inventory) async =>
      (await SharedPreferences.getInstance()).setString(
        _key,
        jsonEncode(inventory.toJson()),
      );
}

class InMemoryWardrobeRepository implements WardrobeRepository {
  Inventory? _stored;

  @override
  Future<Inventory?> load() async => _stored;

  @override
  Future<void> save(Inventory inventory) async => _stored = inventory;
}
