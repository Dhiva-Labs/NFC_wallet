import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/storage_service.dart';

/// App-wide preferences: theme, app-lock and the fallback PIN.
class SettingsProvider extends ChangeNotifier {
  SettingsProvider(this._storage, this._auth);

  final StorageService _storage;
  final AuthService _auth;

  ThemeMode _themeMode = ThemeMode.dark;
  bool _appLockEnabled = false;
  bool _hasPin = false;
  bool _canBiometric = false;

  ThemeMode get themeMode => _themeMode;
  bool get appLockEnabled => _appLockEnabled;
  bool get hasPin => _hasPin;
  bool get canBiometric => _canBiometric;
  AuthService get auth => _auth;

  Future<void> load() async {
    _themeMode = await _storage.loadThemeMode();
    _appLockEnabled = await _storage.isAppLockEnabled();
    _hasPin = (await _storage.loadPinHash()) != null;
    _canBiometric = await _auth.canAuthenticate();
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    await _storage.setThemeMode(mode);
  }

  Future<void> setAppLock(bool value) async {
    _appLockEnabled = value;
    notifyListeners();
    await _storage.setAppLock(value);
  }

  Future<void> setPin(String? pin) async {
    if (pin == null || pin.isEmpty) {
      await _storage.setPinHash(null);
      _hasPin = false;
    } else {
      await _storage.setPinHash(AuthService.hashPin(pin));
      _hasPin = true;
    }
    notifyListeners();
  }

  Future<bool> verifyPin(String pin) async {
    final stored = await _storage.loadPinHash();
    return stored != null && stored == AuthService.hashPin(pin);
  }
}
