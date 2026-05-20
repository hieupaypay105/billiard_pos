import 'package:anholding_app/src/core/constants/env.dart';
import 'package:anholding_app/src/core/network/token_storage.dart';
import 'package:anholding_app/src/core/paths/api_paths.dart';
import 'package:anholding_app/src/features/auth/data/models/auth_response_model.dart';
import 'package:anholding_app/src/features/auth/data/models/user_model.dart';
import 'package:dio/dio.dart';

abstract class AuthRemoteDataSource {
  Future<AuthResponseModel> login(String username, String password);
  Future<UserModel> loginFirebase(String idToken);
  Future<AuthResponseModel> refreshToken();
  Future<void> logout();
  Future<UserModel> getUserInfo();
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  AuthRemoteDataSourceImpl({required this.dio, required this.tokenStorage});

  final Dio dio;
  final TokenStorage tokenStorage;

  @override
  Future<AuthResponseModel> login(String username, String password) async {
    try {
      // API nhận form-data (giống Postman), không phải JSON
      final formData = FormData.fromMap({
        'username': username,
        'password': password,
      });
      final response = await dio.post<Map<String, dynamic>>(
        Env.authLoginEndpoint,
        data: formData,
      );

      if (response.data == null) {
        throw Exception('Invalid response from server');
      }

      final data = response.data!;

      // API trả status: 0 khi đăng nhập sai; status: 1 và token nằm trong data.data
      final status = data['status'];
      if (status == 0) {
        final errors = data['errors'];
        final loginError = (errors is Map && errors['login'] != null)
            ? errors['login'].toString()
            : null;
        final message = loginError ?? data['message']?.toString();
        throw Exception(message ?? 'Đăng nhập không thành công');
      }

      // access_token và refresh_token nằm trong data
      final inner = data['data'];
      final payload = (inner is Map && inner.isNotEmpty)
          ? Map<String, dynamic>.from(inner)
          : data;
      final authResponse = AuthResponseModel.fromJson(payload);

      await tokenStorage.saveTokens(
        accessToken: authResponse.accessToken,
        refreshToken: authResponse.refreshToken,
      );

      return authResponse;
    } on DioException catch (e) {
      final data = e.response?.data;
      final message = (data is Map<String, dynamic>)
          ? data['message'] as String?
          : null;

      if (e.response?.statusCode != null && e.response!.statusCode! >= 500) {
        throw Exception(
          'Hệ thống máy chủ đang gặp sự cố (Lỗi ${e.response?.statusCode}). Vui lòng thử lại sau.',
        );
      }

      throw Exception(message ?? 'Đăng nhập không thành công');
    }
  }

  @override
  Future<UserModel> loginFirebase(String idToken) async {
    try {
      final formData = FormData.fromMap({'idToken': idToken});
      final response = await dio.post<Map<String, dynamic>>(
        Env.authLoginFirebaseEndpoint,
        data: formData,
      );

      if (response.data == null) {
        throw Exception('Invalid response from server');
      }

      final data = response.data!;
      final status = data['status'];
      if (status == 0) {
        final message = data['message']?.toString();
        throw Exception(message ?? 'Đăng nhập Firebase không thành công');
      }

      final inner = data['data'];
      if (inner == null || inner is! Map) {
        throw Exception('Invalid user data from server');
      }

      final userModel = UserModel.fromJson(Map<String, dynamic>.from(inner));

      await tokenStorage.saveTokens(
        accessToken: userModel.accessToken,
        refreshToken: userModel.refreshToken,
      );

      return userModel;
    } on DioException catch (e) {
      final data = e.response?.data;
      final message = (data is Map<String, dynamic>)
          ? data['message'] as String?
          : null;

      if (e.response?.statusCode != null && e.response!.statusCode! >= 500) {
        throw Exception(
          'Hệ thống máy chủ đang gặp sự cố (Lỗi ${e.response?.statusCode}). Vui lòng thử lại sau.',
        );
      }

      throw Exception(message ?? 'Đăng nhập Firebase không thành công');
    }
  }

  @override
  Future<AuthResponseModel> refreshToken() async {
    try {
      final currentRefreshToken = await tokenStorage.getRefreshToken();
      if (currentRefreshToken == null) {
        throw Exception('No refresh token available');
      }

      final formData = FormData.fromMap({
        'refresh_token': currentRefreshToken,
      });
      final response = await dio.post<Map<String, dynamic>>(
        Env.authRefreshTokenEndpoint,
        data: formData,
      );

      if (response.data == null) {
        throw Exception('Invalid response from server');
      }

      final authResponse = AuthResponseModel.fromJson(response.data!);

      await tokenStorage.saveTokens(
        accessToken: authResponse.accessToken,
        refreshToken: authResponse.refreshToken,
      );

      return authResponse;
    } on DioException catch (e) {
      final data = e.response?.data;
      final message = (data is Map<String, dynamic>)
          ? data['message'] as String?
          : null;

      if (e.response?.statusCode != null && e.response!.statusCode! >= 500) {
        throw Exception(
          'Hệ thống máy chủ đang gặp sự cố (Lỗi ${e.response?.statusCode}). Vui lòng thử lại sau.',
        );
      }

      throw Exception(message ?? 'Làm mới token không thành công');
    }
  }

  @override
  Future<void> logout() async {
    await tokenStorage.clearTokens();
  }

  @override
  Future<UserModel> getUserInfo() async {
    try {
      final response = await dio.get<Map<String, dynamic>>(ApiPaths.userInfo);

      if (response.data == null) {
        throw Exception('Invalid response from server');
      }

      final data = response.data!;
      final status = data['status'];
      if (status == 0) {
        final message = data['message']?.toString();
        throw Exception(message ?? 'Không thể lấy thông tin người dùng');
      }

      final inner = data['data'];
      if (inner == null || inner is! Map) {
        throw Exception('Invalid user data from server');
      }

      return UserModel.fromJson(Map<String, dynamic>.from(inner));
    } on DioException catch (e) {
      if (e.error == 'Token expired and refresh failed') {
        throw Exception('Token expired and refresh failed');
      }
      final data = e.response?.data;
      final message = (data is Map<String, dynamic>)
          ? data['message'] as String?
          : null;

      if (e.response?.statusCode != null && e.response!.statusCode! >= 500) {
        throw Exception(
          'Hệ thống máy chủ đang gặp sự cố (Lỗi ${e.response?.statusCode}). Vui lòng thử lại sau.',
        );
      }

      throw Exception(message ?? 'Không thể lấy thông tin người dùng');
    }
  }
}
