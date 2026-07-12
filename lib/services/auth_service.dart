import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

/// Wraps biometric / device-credential authentication used to "safe" cards
/// and (optionally) lock the whole app. Falls back to an app PIN when no
/// hardware biometrics are available.
class AuthService {
  final LocalAuthentication _auth = LocalAuthentication();

  /// True if the device can prompt for biometrics or a device PIN/pattern.
  Future<bool> canAuthenticate() async {
    try {
      final supported = await _auth.isDeviceSupported();
      final canBio = await _auth.canCheckBiometrics;
      return supported || canBio;
    } catch (_) {
      return false;
    }
  }

  Future<bool> hasBiometrics() async {
    try {
      final list = await _auth.getAvailableBiometrics();
      return list.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// Prompt the user. Allows the device credential (PIN/pattern) as a fallback
  /// so it still works on phones without fingerprint/face hardware.
  Future<bool> authenticate(String reason) async {
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
          useErrorDialogs: true,
        ),
      );
    } on PlatformException {
      return false;
    }
  }

  /// One-way hash for the fallback app PIN.
  static String hashPin(String pin) =>
      sha256.convert(utf8.encode('nfcwallet::$pin')).toString();
}
