import 'package:equatable/equatable.dart';

class User extends Equatable {
  const User({
    required this.id,
    required this.username,
    required this.email,
    required this.fullname,
    required this.status,
    required this.userCode,
    required this.mobile,
    required this.dob,
    required this.parentId,
    required this.accessToken,
    required this.refreshToken,
    required this.expires,
    required this.createdAt,
    required this.updatedAt,
    required this.groupPerName,
    required this.firebaseUid,
    required this.avatar,
  });

  final String id;
  final String username;
  final String email;
  final String fullname;
  final String status;
  final String userCode;
  final String mobile;
  final String dob;
  final String parentId;
  final String accessToken;
  final String refreshToken;
  final String expires;
  final String createdAt;
  final String updatedAt;
  final String groupPerName;
  final String firebaseUid;
  final String avatar;

  @override
  List<Object?> get props => [
    id,
    username,
    email,
    fullname,
    status,
    userCode,
    mobile,
    dob,
    parentId,
    accessToken,
    refreshToken,
    expires,
    createdAt,
    updatedAt,
    groupPerName,
    firebaseUid,
    avatar,
  ];
}
