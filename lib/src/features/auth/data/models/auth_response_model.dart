import 'package:equatable/equatable.dart';

class AuthResponseModel extends Equatable {
  const AuthResponseModel({
    required this.accessToken,
    required this.refreshToken,
  });

  factory AuthResponseModel.fromJson(Map<String, dynamic> json) {
    return AuthResponseModel(
      accessToken: (json['access_token'] as String?) ?? '',
      refreshToken: (json['refresh_token'] as String?) ?? '',
    );
  }

  final String accessToken;
  final String refreshToken;

  Map<String, dynamic> toJson() {
    return {'access_token': accessToken, 'refresh_token': refreshToken};
  }

  @override
  List<Object?> get props => [accessToken, refreshToken];
}
