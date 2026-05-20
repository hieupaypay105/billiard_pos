import 'package:anholding_app/src/features/auth/data/models/auth_response_model.dart';
import 'package:anholding_app/src/features/auth/data/models/user_model.dart';

abstract class AuthRepository {
  Future<AuthResponseModel> login(String username, String password);
  Future<UserModel> loginFirebase(String idToken);
  Future<AuthResponseModel> refreshToken();
  Future<void> logout();
  Future<UserModel> getUserInfo();
}
