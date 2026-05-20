import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Handles secure storage and verification of the user's PIN.
///
/// PINs are stored as SHA-256 hashes — the raw PIN is never persisted.
class PinStorage {
  PinStorage({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static const _pinKey = 'user_pin_hash';
  static const _phoneKey = 'user_phone';
  static const _nameKey = 'user_name';

  // ─── Hashing ─────────────────────────────────────────────

  String _hashPin(String pin) {
    final bytes = utf8.encode(pin);
    return sha256.convert(bytes).toString();
  }

  // ─── PIN ─────────────────────────────────────────────────

  /// Save PIN (hashed) to secure storage.
  Future<void> savePin(String pin) async {
    await _storage.write(key: _pinKey, value: _hashPin(pin));
  }

  /// Verify an input PIN against the stored hash.
  Future<bool> verifyPin(String pin) async {
    final stored = await _storage.read(key: _pinKey);
    if (stored == null) return false;
    return stored == _hashPin(pin);
  }

  /// Check if a PIN has been set.
  Future<bool> hasPin() async {
    final stored = await _storage.read(key: _pinKey);
    return stored != null && stored.isNotEmpty;
  }

  /// Delete the stored PIN (e.g. on logout or account switch).
  Future<void> deletePin() async {
    await _storage.delete(key: _pinKey);
  }

  // ─── User Info (for PinLoginView) ────────────────────────

  Future<void> saveUserInfo({
    required String phone,
    String? name,
  }) async {
    await _storage.write(key: _phoneKey, value: phone);
    if (name != null) {
      await _storage.write(key: _nameKey, value: name);
    }
  }

  Future<String?> getSavedPhone() => _storage.read(key: _phoneKey);
  Future<String?> getSavedName() => _storage.read(key: _nameKey);

  /// Clear all auth-related data.
  Future<void> clearAll() async {
    await _storage.delete(key: _pinKey);
    await _storage.delete(key: _phoneKey);
    await _storage.delete(key: _nameKey);
  }
}
