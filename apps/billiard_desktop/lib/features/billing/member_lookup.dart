import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/providers/providers.dart';
import '../tables/tables_provider.dart';

class MemberLookupDialog extends ConsumerStatefulWidget {
  final String tableId;
  const MemberLookupDialog({super.key, required this.tableId});

  @override
  ConsumerState<MemberLookupDialog> createState() =>
      _MemberLookupDialogState();
}

class _MemberLookupDialogState extends ConsumerState<MemberLookupDialog> {
  final _phoneCtrl = TextEditingController();
  bool _isSearching = false;
  Map<String, dynamic>? _foundMember;
  String? _notFoundMsg;

  @override
  void dispose() {
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final phone = _phoneCtrl.text.trim();
    if (phone.isEmpty) return;
    setState(() {
      _isSearching = true;
      _foundMember = null;
      _notFoundMsg = null;
    });

    try {
      final syncService = ref.read(syncServiceProvider);
      final apiClient = ref.read(apiClientProvider);
      final localDb = ref.read(localDbServiceProvider);

      Map<String, dynamic>? rawMember;
      if (syncService.isOnline) {
        try {
          rawMember = await apiClient.getMemberByPhone(phone);
        } catch (_) {
          // If online request fails, fall back to offline DB search
          rawMember = await localDb.getMemberByPhone(phone);
        }
      } else {
        rawMember = await localDb.getMemberByPhone(phone);
      }

      if (rawMember != null) {
        final id = rawMember['id']?.toString() ?? '';
        final fullName = rawMember['full_name']?.toString() ?? '';
        final phoneNumber = rawMember['phone_number']?.toString() ?? '';
        final tier = rawMember['tier_name']?.toString() ?? rawMember['tier']?.toString() ?? 'Normal';
        final discount = double.tryParse(rawMember['discount_percentage']?.toString() ?? '') ?? 
                         double.tryParse(rawMember['discount']?.toString() ?? '') ?? 0.0;
        final totalPoints = int.tryParse(rawMember['total_points']?.toString() ?? '') ?? 0;

        setState(() {
          _foundMember = {
            'id': id,
            'full_name': fullName,
            'phone_number': phoneNumber,
            'tier': tier,
            'total_points': totalPoints,
            'discount': discount,
          };
        });
      } else {
        setState(() => _notFoundMsg = 'Không tìm thấy thành viên');
      }
    } catch (e) {
      setState(() => _notFoundMsg = 'Lỗi tra cứu: $e');
    } finally {
      setState(() => _isSearching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: SizedBox(
          width: 380,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                const Icon(Icons.person_search,
                    color: AppColors.primary, size: 22),
                const SizedBox(width: 8),
                Text('Tìm thành viên', style: AppTextStyles.headlineSmall),
                const Spacer(),
                IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, size: 20)),
              ]),
              const SizedBox(height: 20),
              // Search row
              Row(children: [
                Expanded(
                  child: TextField(
                    controller: _phoneCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      hintText: 'Nhập số điện thoại...',
                      prefixIcon: const Icon(Icons.phone_outlined, size: 18),
                      filled: true,
                      fillColor: AppColors.surfaceVariant,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none),
                    ),
                    onSubmitted: (_) => _search(),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _isSearching ? null : _search,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                  ),
                  child: _isSearching
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.search, size: 20),
                ),
              ]),
              const SizedBox(height: 16),
              // Results
              if (_foundMember != null) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.successLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.success.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        CircleAvatar(
                          backgroundColor: AppColors.primary,
                          radius: 20,
                          child: Text(
                            (_foundMember!['full_name'] as String)[0],
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_foundMember!['full_name'] as String,
                                style: AppTextStyles.titleLarge),
                            Text(_foundMember!['phone_number'] as String,
                                style: AppTextStyles.bodySmall),
                          ],
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.accent,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _foundMember!['tier'] as String,
                            style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Colors.white),
                          ),
                        ),
                      ]),
                      const SizedBox(height: 12),
                      Row(children: [
                        _MemberStat('Điểm tích lũy',
                            '${_foundMember!['total_points']}'),
                        const SizedBox(width: 16),
                        _MemberStat('Chiết khấu',
                            '${_foundMember!['discount']}%'),
                      ]),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Đã áp dụng thành viên: ${_foundMember!['full_name']}'),
                                backgroundColor: AppColors.success,
                              ),
                            );
                            ref.read(tablesProvider.notifier).applyMember(widget.tableId, _foundMember!);
                            Navigator.of(context).pop();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.success,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                            elevation: 0,
                          ),
                          child: const Text('Áp dụng thành viên'),
                        ),
                      ),
                    ],
                  ),
                ),
              ] else if (_notFoundMsg != null) ...[
                Center(
                  child: Column(children: [
                    const Icon(Icons.person_off_outlined,
                        color: AppColors.textMuted, size: 36),
                    const SizedBox(height: 8),
                    Text(_notFoundMsg!, style: AppTextStyles.bodySmall),
                  ]),
                ),
              ] else ...[
                Center(
                  child: Text(
                    'Nhập số điện thoại để tra cứu thành viên.\nVí dụ: 0901234567',
                    style: AppTextStyles.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _MemberStat extends StatelessWidget {
  final String label;
  final String value;
  const _MemberStat(this.label, this.value);

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.labelSmall),
          Text(value,
              style: AppTextStyles.titleMedium
                  .copyWith(color: AppColors.primary)),
        ],
      );
}
