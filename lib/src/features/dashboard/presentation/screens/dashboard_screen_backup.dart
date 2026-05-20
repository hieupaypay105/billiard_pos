import 'dart:async';

import 'package:anholding_app/src/core/theme/app_colors.dart';
import 'package:anholding_app/src/core/utils/jwt_utils.dart';
import 'package:anholding_app/src/features/auth/presentation/provider/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(context.read<UserProvider>().fetchUserInfo());
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: Consumer<UserProvider>(
        builder: (context, userProvider, _) {
          if (userProvider.isFetchingUser) {
            return const Center(child: CircularProgressIndicator());
          }

          if (userProvider.fetchError != null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 48,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      userProvider.fetchError!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => userProvider.fetchUserInfo(),
                      child: const Text('Thử lại'),
                    ),
                  ],
                ),
              ),
            );
          }

          final user = userProvider.currentUser;
          if (user == null) {
            return const Center(child: Text('Chưa đăng nhập'));
          }

          final now = DateTime.now();

          // Access token expiry
          final expires = JwtUtils.getExpiryTime(user.accessToken);
          final isExpired = expires != null && expires.isBefore(now);
          final remaining = expires?.difference(now);

          // Refresh token expiry
          final refreshExpires = JwtUtils.getExpiryTime(user.refreshToken);
          final isRefreshExpired =
              refreshExpires != null && refreshExpires.isBefore(now);
          final refreshRemaining = refreshExpires?.difference(now);

          return RefreshIndicator(
            onRefresh: () => userProvider.fetchUserInfo(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── User Info ─────────────────────────────────
                  _UserInfoSection(
                    avatar: user.avatar,
                    fullname: user.fullname,
                    email: user.email,
                    mobile: user.mobile,
                    username: user.username,
                    userCode: user.userCode,
                    groupPerName: user.groupPerName,
                    dob: user.dob,
                    status: user.status,
                    createdAt: user.createdAt,
                    updatedAt: user.updatedAt,
                    firebaseUid: user.firebaseUid,
                  ),

                  const SizedBox(height: 24),

                  // ── Token Debug ───────────────────────────────
                  _TokenSection(
                    title: 'Access Token',
                    token: user.accessToken,
                  ),
                  const SizedBox(height: 24),
                  _TokenSection(
                    title: 'Refresh Token',
                    token: user.refreshToken,
                  ),
                  const SizedBox(height: 24),
                  _ExpirySection(
                    label: 'Access Token Expiry',
                    expiresAt: expires,
                    isExpired: isExpired,
                    remaining: remaining,
                  ),
                  const SizedBox(height: 24),
                  _ExpirySection(
                    label: 'Refresh Token Expiry',
                    expiresAt: refreshExpires,
                    isExpired: isRefreshExpired,
                    remaining: refreshRemaining,
                    noDecodeMessage: 'Không decode được exp từ refresh token',
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── User Info Section ─────────────────────────────────────────────────────────

class _UserInfoSection extends StatelessWidget {
  const _UserInfoSection({
    required this.avatar,
    required this.fullname,
    required this.email,
    required this.mobile,
    required this.username,
    required this.userCode,
    required this.groupPerName,
    required this.dob,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.firebaseUid,
  });

  final String avatar;
  final String fullname;
  final String email;
  final String mobile;
  final String username;
  final String userCode;
  final String groupPerName;
  final String dob;
  final String status;
  final String createdAt;
  final String updatedAt;
  final String firebaseUid;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Avatar + Name header
        Row(
          children: [
            CircleAvatar(
              radius: 32,
              backgroundColor: AppColors.borderInactive,
              backgroundImage: avatar.isNotEmpty ? NetworkImage(avatar) : null,
              child: avatar.isEmpty ? const Icon(Icons.person, size: 32) : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fullname,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: status == '1'
                          ? Colors.green.shade800
                          : Colors.red.shade800,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      status == '1' ? 'Active' : 'Inactive',
                      style: const TextStyle(fontSize: 12, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Info rows
        _InfoRow(
          icon: Icons.person_outline,
          label: 'Username',
          value: username,
        ),
        _InfoRow(
          icon: Icons.badge_outlined,
          label: 'User Code',
          value: userCode,
        ),
        _InfoRow(icon: Icons.email_outlined, label: 'Email', value: email),
        _InfoRow(icon: Icons.phone_outlined, label: 'Mobile', value: mobile),
        _InfoRow(icon: Icons.cake_outlined, label: 'DOB', value: dob),
        _InfoRow(
          icon: Icons.group_outlined,
          label: 'Group',
          value: groupPerName,
        ),
        _InfoRow(
          icon: Icons.fingerprint,
          label: 'Firebase UID',
          value: firebaseUid,
        ),
        _InfoRow(
          icon: Icons.calendar_today,
          label: 'Created',
          value: createdAt,
        ),
        _InfoRow(icon: Icons.update, label: 'Updated', value: updatedAt),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    if (value.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey),
          const SizedBox(width: 12),
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Token Section ─────────────────────────────────────────────────────────────

class _TokenSection extends StatelessWidget {
  const _TokenSection({required this.title, required this.token});

  final String title;
  final String token;

  @override
  Widget build(BuildContext context) {
    final isEmpty = token.isEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const Spacer(),
            if (!isEmpty)
              IconButton(
                icon: const Icon(Icons.copy, size: 20),
                tooltip: 'Copy',
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: token));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('$title copied!')),
                  );
                },
              ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: SelectableText(
            isEmpty ? '(trống)' : token,
            style: TextStyle(
              fontSize: 13,
              fontFamily: 'monospace',
              color: isEmpty ? Colors.red : Colors.black87,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Expiry Section ────────────────────────────────────────────────────────────

class _ExpirySection extends StatelessWidget {
  const _ExpirySection({
    required this.label,
    required this.expiresAt,
    required this.isExpired,
    required this.remaining,
    this.noDecodeMessage = 'Không decode được exp từ access token',
  });

  final String label;
  final DateTime? expiresAt;
  final bool isExpired;
  final Duration? remaining;
  final String noDecodeMessage;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isExpired ? Colors.red.shade50 : Colors.green.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isExpired ? Colors.red.shade300 : Colors.green.shade300,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (expiresAt != null) ...[
                Text(
                  'Expires: ${expiresAt!.toLocal()}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontFamily: 'monospace',
                  ).copyWith(color: AppColors.textDark),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      isExpired ? Icons.error : Icons.check_circle,
                      color: isExpired ? Colors.red : Colors.green,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        isExpired
                            ? 'ĐÃ HẾT HẠN'
                            : 'Còn lại: ${_formatDuration(remaining!)}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isExpired ? Colors.red : Colors.green.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ] else
                Text(
                  noDecodeMessage,
                  style: const TextStyle(color: Colors.orange, fontSize: 13),
                ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDuration(Duration d) {
    final days = d.inDays;
    final hours = d.inHours.remainder(24);
    final minutes = d.inMinutes.remainder(60);
    final parts = <String>[];
    if (days > 0) parts.add('$days ngày');
    if (hours > 0) parts.add('$hours giờ');
    parts.add('$minutes phút');
    return parts.join(' ');
  }
}
