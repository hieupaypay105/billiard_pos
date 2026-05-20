import 'package:anholding_app/src/features/auth/data/datasources/auth_remote_source.dart';
import 'package:anholding_app/src/features/auth/data/models/auth_response_model.dart';
import 'package:anholding_app/src/features/auth/data/models/user_model.dart';
import 'package:anholding_app/src/features/auth/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({required this.remoteDataSource});
  final AuthRemoteDataSource remoteDataSource;

  @override
  Future<AuthResponseModel> login(String username, String password) async {
    return remoteDataSource.login(username, password);
  }

  @override
  Future<UserModel> loginFirebase(String idToken) async {
    return remoteDataSource.loginFirebase(idToken);
  }

  @override
  Future<AuthResponseModel> refreshToken() async {
    return remoteDataSource.refreshToken();
  }

  @override
  Future<void> logout() async {
    return remoteDataSource.logout();
  }

  @override
  Future<UserModel> getUserInfo() async {
    return remoteDataSource.getUserInfo();
  }
}
