import 'package:flutter/foundation.dart';

import '../models/card_type.dart';
import '../models/stored_card.dart';
import '../services/storage_service.dart';

/// Owns the in-memory wallet and keeps it persisted.
class WalletProvider extends ChangeNotifier {
  WalletProvider(this._storage);

  final StorageService _storage;

  final List<StoredCard> _cards = [];
  bool _loading = true;

  String _query = '';
  CardType? _typeFilter;

  bool get isLoading => _loading;
  String get query => _query;
  CardType? get typeFilter => _typeFilter;
  bool get isEmpty => _cards.isEmpty;
  int get totalCount => _cards.length;

  Future<void> load() async {
    final loaded = await _storage.loadCards();
    _cards
      ..clear()
      ..addAll(loaded);
    _loading = false;
    notifyListeners();
  }

  /// Cards after the active search + type filter, newest first.
  List<StoredCard> get visibleCards {
    Iterable<StoredCard> result = _cards;
    if (_typeFilter != null) {
      result = result.where((c) => c.type == _typeFilter);
    }
    if (_query.trim().isNotEmpty) {
      final q = _query.trim().toLowerCase();
      result = result.where((c) =>
          c.name.toLowerCase().contains(q) ||
          (c.uid?.toLowerCase().contains(q) ?? false) ||
          c.type.label.toLowerCase().contains(q));
    }
    final list = result.toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return list;
  }

  /// Types that actually have at least one card, for filter chips.
  List<CardType> get usedTypes {
    final present = _cards.map((c) => c.type).toSet();
    return CardType.values.where(present.contains).toList();
  }

  int countOf(CardType type) => _cards.where((c) => c.type == type).length;

  StoredCard? byId(String id) {
    for (final c in _cards) {
      if (c.id == id) return c;
    }
    return null;
  }

  void setQuery(String value) {
    _query = value;
    notifyListeners();
  }

  void setTypeFilter(CardType? type) {
    _typeFilter = type;
    notifyListeners();
  }

  Future<void> add(StoredCard card) async {
    _cards.add(card);
    notifyListeners();
    await _storage.saveCards(_cards);
  }

  Future<void> update(StoredCard card) async {
    final i = _cards.indexWhere((c) => c.id == card.id);
    if (i == -1) return;
    _cards[i] = card;
    notifyListeners();
    await _storage.saveCards(_cards);
  }

  Future<void> delete(String id) async {
    _cards.removeWhere((c) => c.id == id);
    notifyListeners();
    await _storage.saveCards(_cards);
  }
}
