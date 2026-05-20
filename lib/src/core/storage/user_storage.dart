import 'dart:convert';

import 'package:anholding_app/src/features/auth/data/models/user_model.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Handles secure storage and verification of the user's data (UserModel).
class UserStorage {
  UserStorage({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;
  static const _userKey = 'user_model_data';

  /// Save UserModel as JSON to secure storage.
  Future<void> saveUser(UserModel user) async {
    final jsonString = jsonEncode(user.toJson());
    await _storage.write(key: _userKey, value: jsonString);
  }

  /// Load UserModel from secure storage.
  Future<UserModel?> getUser() async {
    final jsonString = await _storage.read(key: _userKey);
    if (jsonString == null || jsonString.isEmpty) return null;

    try {
      final jsonMap = jsonDecode(jsonString) as Map<String, dynamic>;
      return UserModel.fromJson(jsonMap);
    } catch (e) {
      // In case of parsing error or schema change
      return null;
    }
  }

  /// Delete the stored UserModel (e.g. on logout or account switch).
  Future<void> deleteUser() async {
    await _storage.delete(key: _userKey);
  }
}
