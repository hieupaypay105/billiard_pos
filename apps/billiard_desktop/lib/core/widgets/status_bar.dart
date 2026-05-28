import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core_shared/core_shared.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../../features/sync/sync_provider.dart';
import '../../features/tables/shift_provider.dart';

class StatusBar extends ConsumerWidget {
  final UserModel? user;
  final SyncState syncState;
  const StatusBar({super.key, this.user, required this.syncState});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shiftState = ref.watch(shiftProvider);
    final hasShift = shiftState.hasActiveShift;
    final shift = shiftState.activeShift;

    return Container(
      height: 36,
      decoration: const BoxDecoration(
        color: AppColors.navRailBg,
        border: Border(
            top: BorderSide(color: Color(0xFF0D2020), width: 1)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          // User info
          Icon(Icons.person_pin, size: 14,
              color: Colors.white.withOpacity(0.5)),
          const SizedBox(width: 6),
          Text(
            user?.displayName ?? '—',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              color: Colors.white.withOpacity(0.7),
            ),
          ),
          if (user != null) ...[
            _separator(),
            _chip(_roleLabel(user!.role),
                color: _roleColor(user!.role)),
          ],
          _separator(),
          
          // Shift Manager UI
          Icon(
            hasShift ? Icons.play_circle_fill : Icons.pause_circle_filled,
            size: 14,
            color: hasShift ? AppColors.success : AppColors.error,
          ),
          const SizedBox(width: 6),
          Text(
            hasShift
                ? 'Ca đang mở: ${shift?.id} (${_fmtCurrency(shift?.initialCash ?? 0)})'
                : 'Chưa mở ca làm việc',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              color: hasShift
                  ? Colors.white.withOpacity(0.8)
                  : AppColors.error,
              fontWeight: hasShift ? FontWeight.normal : FontWeight.bold,
            ),
          ),
          const SizedBox(width: 10),
          if (hasShift)
            TextButton(
              onPressed: () => _showCloseShiftDialog(context, ref, shift!.id),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                'Đóng ca',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  color: AppColors.error,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          else
            TextButton(
              onPressed: () => _showOpenShiftDialog(context, ref, user?.id ?? 'cashier'),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                'Mở ca ngay',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  color: AppColors.accent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

          const Spacer(),
          // Pending sync count
          if (syncState.pendingCount > 0) ...[
            Icon(Icons.upload_outlined, size: 14,
                color: AppColors.warning),
            const SizedBox(width: 4),
            Text(
              '${syncState.pendingCount} bản ghi chờ sync',
              style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  color: AppColors.warning),
            ),
            _separator(),
          ],
          // Version
          Text(
            'v1.0.0',
            style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                color: Colors.white.withOpacity(0.4)),
          ),
        ],
      ),
    );
  }

  void _showOpenShiftDialog(BuildContext context, WidgetRef ref, String userId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => OpenShiftDialog(userId: userId),
    );
  }

  void _showCloseShiftDialog(BuildContext context, WidgetRef ref, String shiftId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => CloseShiftDialog(shiftId: shiftId),
    );
  }

  Widget _separator() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      width: 1,
      height: 14,
      color: Colors.white.withOpacity(0.15),
    );
  }

  Widget _chip(String label, {required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: color),
      ),
    );
  }

  String _roleLabel(String role) {
    return switch (role) {
      'admin' => 'Admin',
      'manager' => 'Manager',
      'cashier' => 'Thu ngân',
      'waiter' => 'Phục vụ',
      _ => role,
    };
  }

  Color _roleColor(String role) {
    return switch (role) {
      'admin' => AppColors.error,
      'manager' => AppColors.accent,
      'cashier' => AppColors.success,
      'waiter' => AppColors.info,
      _ => AppColors.textMuted,
    };
  }

  String _fmtCurrency(double v) {
    final s = v.toStringAsFixed(0);
    final buf = StringBuffer();
    int count = 0;
    for (int i = s.length - 1; i >= 0; i--) {
      if (count > 0 && count % 3 == 0) buf.write('.');
      buf.write(s[i]);
      count++;
    }
    return '${buf.toString().split('').reversed.join()} đ';
  }
}

// ─── Open/Close Shift Dialogs ──────────────────────────────────────────────────

class OpenShiftDialog extends StatefulWidget {
  final String userId;
  const OpenShiftDialog({required this.userId});

  @override
  State<OpenShiftDialog> createState() => OpenShiftDialogState();
}

class OpenShiftDialogState extends State<OpenShiftDialog> {
  final _cashController = TextEditingController(text: '0');
  final _noteController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _submitting = false;

  @override
  void dispose() {
    _cashController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        return AlertDialog(
          backgroundColor: AppColors.dialogBg,
          title: Text(
            'Mở ca làm việc',
            style: AppTextStyles.titleMedium.copyWith(color: AppColors.accent),
          ),
          content: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bắt đầu ca làm việc mới. Nhập số tiền mặt đầu ca bàn giao.',
                    style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _cashController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Số tiền mặt đầu ca (VND)',
                      labelStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
                      enabledBorder: const OutlineInputBorder(
                        borderSide: BorderSide(color: const Color(0xFF0D2020)),
                      ),
                      focusedBorder: const OutlineInputBorder(
                        borderSide: BorderSide(color: AppColors.accent),
                      ),
                    ),
                    style: const TextStyle(color: Colors.white),
                    validator: (val) {
                      if (val == null || val.isEmpty) return 'Vui lòng nhập tiền đầu ca';
                      final n = double.tryParse(val);
                      if (n == null || n < 0) return 'Số tiền không hợp lệ';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _noteController,
                    decoration: InputDecoration(
                      labelText: 'Ghi chú mở ca',
                      labelStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
                      enabledBorder: const OutlineInputBorder(
                        borderSide: BorderSide(color: const Color(0xFF0D2020)),
                      ),
                      focusedBorder: const OutlineInputBorder(
                        borderSide: BorderSide(color: AppColors.accent),
                      ),
                    ),
                    style: const TextStyle(color: Colors.white),
                    maxLines: 2,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: _submitting
                  ? null
                  : () => Navigator.of(context).pop(false),
              child: const Text('Hủy', style: TextStyle(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              onPressed: _submitting
                  ? null
                  : () async {
                      if (!_formKey.currentState!.validate()) return;
                      setState(() {
                        _submitting = true;
                      });
                      final cash = double.parse(_cashController.text);
                      final note = _noteController.text;

                      final success = await ref
                          .read(shiftProvider.notifier)
                          .openShift(
                            userId: widget.userId,
                            initialCash: cash,
                            note: note,
                          );

                      if (mounted) {
                        Navigator.of(context).pop(success);
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: _submitting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Mở ca'),
            ),
          ],
        );
      },
    );
  }
}

class CloseShiftDialog extends StatefulWidget {
  final String shiftId;
  const CloseShiftDialog({required this.shiftId});

  @override
  State<CloseShiftDialog> createState() => CloseShiftDialogState();
}

class CloseShiftDialogState extends State<CloseShiftDialog> {
  final _cashController = TextEditingController(text: '0');
  final _noteController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _submitting = false;

  @override
  void dispose() {
    _cashController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        return AlertDialog(
          backgroundColor: AppColors.dialogBg,
          title: Text(
            'Đóng ca làm việc',
            style: AppTextStyles.titleMedium.copyWith(color: AppColors.accent),
          ),
          content: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Đóng ca ID: ${widget.shiftId}\n'
                    'Nhập số tiền mặt thực tế kiểm đếm cuối ca để đối soát.',
                    style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _cashController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Số tiền mặt thực tế cuối ca (VND)',
                      labelStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
                      enabledBorder: const OutlineInputBorder(
                        borderSide: BorderSide(color: const Color(0xFF0D2020)),
                      ),
                      focusedBorder: const OutlineInputBorder(
                        borderSide: BorderSide(color: AppColors.accent),
                      ),
                    ),
                    style: const TextStyle(color: Colors.white),
                    validator: (val) {
                      if (val == null || val.isEmpty) return 'Vui lòng nhập tiền cuối ca';
                      final n = double.tryParse(val);
                      if (n == null || n < 0) return 'Số tiền không hợp lệ';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _noteController,
                    decoration: InputDecoration(
                      labelText: 'Ghi chú bàn giao',
                      labelStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
                      enabledBorder: const OutlineInputBorder(
                        borderSide: BorderSide(color: const Color(0xFF0D2020)),
                      ),
                      focusedBorder: const OutlineInputBorder(
                        borderSide: BorderSide(color: AppColors.accent),
                      ),
                    ),
                    style: const TextStyle(color: Colors.white),
                    maxLines: 2,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: _submitting
                  ? null
                  : () => Navigator.of(context).pop(false),
              child: const Text('Hủy', style: TextStyle(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              onPressed: _submitting
                  ? null
                  : () async {
                      if (!_formKey.currentState!.validate()) return;
                      setState(() {
                        _submitting = true;
                      });
                      final cash = double.parse(_cashController.text);
                      final note = _noteController.text;

                      final success = await ref
                          .read(shiftProvider.notifier)
                          .closeShift(
                            actualCash: cash,
                            note: note,
                          );

                      if (mounted) {
                        Navigator.of(context).pop(success);
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
              ),
              child: _submitting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Đóng ca'),
            ),
          ],
        );
      },
    );
  }
}
