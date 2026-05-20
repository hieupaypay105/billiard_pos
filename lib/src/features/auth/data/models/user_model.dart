import 'package:anholding_app/src/features/auth/domain/entities/user.dart';

class UserModel extends User {
  const UserModel({
    required super.id,
    required super.username,
    required super.email,
    required super.fullname,
    required super.status,
    required super.userCode,
    required super.mobile,
    required super.dob,
    required super.parentId,
    required super.accessToken,
    required super.refreshToken,
    required super.expires,
    required super.createdAt,
    required super.updatedAt,
    required super.groupPerName,
    required super.firebaseUid,
    required super.avatar,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String? ?? '',
      username: json['username'] as String? ?? '',
      email: json['email'] as String? ?? '',
      fullname: json['fullname'] as String? ?? '',
      status: json['status'] as String? ?? '',
      userCode: json['user_code'] as String? ?? '',
      mobile: json['mobile'] as String? ?? '',
      dob: json['dob'] as String? ?? '',
      parentId: json['parent_id'] as String? ?? '',
      accessToken: json['access_token'] as String? ?? '',
      refreshToken: json['refresh_token'] as String? ?? '',
      expires: json['expires'] as String? ?? '',
      createdAt: json['created_at'] as String? ?? '',
      updatedAt: json['updated_at'] as String? ?? '',
      groupPerName: json['group_per_name'] as String? ?? '',
      firebaseUid: json['firebase_uid'] as String? ?? '',
      avatar: json['avatar'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'fullname': fullname,
      'status': status,
      'user_code': userCode,
      'mobile': mobile,
      'dob': dob,
      'parent_id': parentId,
      'access_token': accessToken,
      'refresh_token': refreshToken,
      'expires': expires,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'group_per_name': groupPerName,
      'firebase_uid': firebaseUid,
      'avatar': avatar,
    };
  }

  UserModel copyWith({
    String? id,
    String? username,
    String? email,
    String? fullname,
    String? status,
    String? userCode,
    String? mobile,
    String? dob,
    String? parentId,
    String? accessToken,
    String? refreshToken,
    String? expires,
    String? createdAt,
    String? updatedAt,
    String? groupPerName,
    String? firebaseUid,
    String? avatar,
  }) {
    return UserModel(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      fullname: fullname ?? this.fullname,
      status: status ?? this.status,
      userCode: userCode ?? this.userCode,
      mobile: mobile ?? this.mobile,
      dob: dob ?? this.dob,
      parentId: parentId ?? this.parentId,
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
      expires: expires ?? this.expires,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      groupPerName: groupPerName ?? this.groupPerName,
      firebaseUid: firebaseUid ?? this.firebaseUid,
      avatar: avatar ?? this.avatar,
    );
  }
}
