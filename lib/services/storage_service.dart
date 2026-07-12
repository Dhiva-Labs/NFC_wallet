import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/stored_card.dart';

/// Local persistence for the wallet and app settings, backed by
/// `shared_preferences`. Card data never leaves the device.
class StorageService {
  static const _kCards = 'wallet_cards_v1';
  static const _kAppLock = 'app_lock_enabled';
  static const _kThemeMode = 'theme_mode';
  static const _kPinHash = 'app_pin_hash';

  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  Future<List<StoredCard>> loadCards() async {
    final prefs = await _prefs;
    final raw = prefs.getString(_kCards);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list
          .map((e) => StoredCard.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveCards(List<StoredCard> cards) async {
    final prefs = await _prefs;
    await prefs.setString(
      _kCards,
      jsonEncode(cards.map((c) => c.toJson()).toList()),
    );
  }

  Future<bool> isAppLockEnabled() async =>
      (await _prefs).getBool(_kAppLock) ?? false;

  Future<void> setAppLock(bool value) async =>
      (await _prefs).setBool(_kAppLock, value);

  Future<ThemeMode> loadThemeMode() async {
    final v = (await _prefs).getString(_kThemeMode);
    return switch (v) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  Future<void> setThemeMode(ThemeMode mode) async =>
      (await _prefs).setString(_kThemeMode, mode.name);

  Future<String?> loadPinHash() async => (await _prefs).getString(_kPinHash);

  Future<void> setPinHash(String? hash) async {
    final prefs = await _prefs;
    if (hash == null) {
      await prefs.remove(_kPinHash);
    } else {
      await prefs.setString(_kPinHash, hash);
    }
  }
}
