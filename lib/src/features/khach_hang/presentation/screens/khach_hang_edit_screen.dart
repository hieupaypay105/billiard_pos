import 'package:anholding_app/src/core/paths/route_paths.dart';
import 'package:anholding_app/src/core/theme/app_colors.dart';
import 'package:anholding_app/src/core/widgets/an_feature_app_bar.dart';
import 'package:anholding_app/src/core/widgets/an_gradient_border.dart';
import 'package:anholding_app/src/features/khach_hang/domain/entities/khach_hang_item.dart';
import 'package:anholding_app/src/features/khach_hang/presentation/provider/khach_hang_provider.dart';
import 'package:anholding_app/src/features/khach_hang/presentation/widgets/khach_hang_form_helpers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class KhachHangEditScreen extends StatefulWidget {
  const KhachHangEditScreen({required this.item, super.key});

  final KhachHangItem item;

  @override
  State<KhachHangEditScreen> createState() => _KhachHangEditScreenState();
}

class _KhachHangEditScreenState extends State<KhachHangEditScreen> {
  final _formKey = GlobalKey<FormBuilderState>();

  // ─── API-supported field keys ─────────────────────────────
  static const _fName = 'name';
  static const _fPhone = 'phone';
  static const _fProjectId = 'project_id';
  static const _fTypeId = 'type';
  static const _fAreaId = 'area';
  static const _fSourceId = 'source_id';
  static const _fStatus = 'status';
  static const _fNote = 'note';

  // ─── UI-only field keys (not submitted to API) ────────────
  static const _fEmail = 'email';
  static const _fRegionId = 'region_id';

  static const _fFinancialRange = 'financial_range';
  static const _fScheduleContact = 'schedule_contact';

  int? _initProjectId;
  String? _initTypeId;
  String? _initAreaId;
  int? _initSourceId;
  int? _initRegionId;
  List<int> _initStatus = [];
  String? _initScheduleContact;
  List<int> _selectedSaleIds = [];

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();

    _initProjectId = int.tryParse(widget.item.projectId ?? '');
    _initTypeId = widget.item.type;
    _initAreaId = widget.item.area;
    _initSourceId = int.tryParse(widget.item.sourceId ?? '');
    _initRegionId = int.tryParse(widget.item.regionId ?? '');

    // Normalize status to List<int>
    final oldStatusStr = widget.item.status;
    if (oldStatusStr.startsWith('[') && oldStatusStr.endsWith(']')) {
      final content = oldStatusStr.substring(1, oldStatusStr.length - 1);
      _initStatus = content
          .split(',')
          .map((e) => int.tryParse(e.trim()))
          .whereType<int>()
          .toList();
    } else if (oldStatusStr.contains(',')) {
      _initStatus = oldStatusStr
          .split(',')
          .map((e) => int.tryParse(e.trim()))
          .whereType<int>()
          .toList();
    } else {
      final intStatus = int.tryParse(oldStatusStr);
      if (intStatus != null) {
        _initStatus = [intStatus];
      } else {
        _initStatus = []; // Or parse list if API changes later
      }
    }

    _initScheduleContact = widget.item.scheduleContact;

    _selectedSaleIds = [];

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await context.read<KhachHangProvider>().loadOptions();
      if (!mounted) return;

      final options = context.read<KhachHangProvider>().options;
      if (options == null) return;

      // Reverse-lookup: sale names → sale IDs from options map
      final saleNames = widget.item.saleId;
      _selectedSaleIds = options.sale.entries
          .where((e) => saleNames.contains(e.value))
          .map((e) => e.key)
          .toList();

      // Reverse-lookup: status labels → status IDs from options list
      final statusLabels = widget.item.statusLabel;
      if (statusLabels.isNotEmpty) {
        final matchedIds = <int>[];
        for (var i = 0; i < options.status.length; i++) {
          if (statusLabels.contains(options.status[i])) {
            matchedIds.add(i);
          }
        }
        if (matchedIds.isNotEmpty) {
          // Merge with any IDs we managed to parse statically from `item.status`
          final mergedStatus = <int>{..._initStatus, ...matchedIds}.toList();
          _initStatus = mergedStatus;
          _formKey.currentState?.fields[_fStatus]?.didChange(_initStatus);
        }
      }

      setState(() {});

      // Pre-load project-specific options if project was previously selected
      if (_initProjectId != null && mounted) {
        context.read<KhachHangProvider>().setSelectedProject(_initProjectId!);
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _onDone() async {
    _formKey.currentState?.save();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);

    final provider = context.read<KhachHangProvider>();
    final formData = _formKey.currentState!.value;

    final data = <String, dynamic>{
      'id': int.tryParse(widget.item.id) ?? widget.item.id,
      'name': (formData[_fName] as String?)?.trim() ?? '',
      'phone': (formData[_fPhone] as String?)?.trim() ?? '',
      'email': (formData[_fEmail] as String?)?.trim() ?? '',
      'project_id': formData[_fProjectId] ?? 0,
      'area': (formData[_fAreaId] as String?)?.trim() ?? '',
      'type': (formData[_fTypeId] as String?)?.trim() ?? '',
      'financial_range': (formData[_fFinancialRange] as String?)?.trim() ?? '',
      'source_id': formData[_fSourceId] ?? 0,
      'sales': _selectedSaleIds,
      'status': formData[_fStatus] ?? const <int>[],
      'region_id': formData[_fRegionId] ?? 0,
      'schedule_contact': formData[_fScheduleContact] != null
          ? DateFormat(
              'yyyy-MM-dd HH:mm:ss',
            ).format(formData[_fScheduleContact] as DateTime)
          : '',
      'dob': '',
      'note': (formData[_fNote] as String?)?.trim() ?? '',
    };

    final success = await provider.updateCustomer(data: data);

    if (!mounted) return;

    if (success) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cập nhật thành công'),
          backgroundColor: Colors.green,
        ),
      );
      context.pop();
    } else {
      final fieldErrors = provider.submitFieldErrors;
      if (fieldErrors != null && fieldErrors.isNotEmpty) {
        final firstErrorField = fieldErrors.entries.first;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(firstErrorField.value.first),
            backgroundColor: Colors.red,
          ),
        );
      } else if (provider.submitError != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.submitError!),
            backgroundColor: Colors.red,
          ),
        );
      }
      setState(() => _isSubmitting = false);
    }
  }

  // ═══════════════════════════════════════════════════════════

  // ═══════════════════════════════════════════════════════════
  //  BUILD
  // ═══════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<KhachHangProvider>();

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AnFeatureAppBar(
        featureTitle: 'CẬP NHẬT',
        onBackTap: () {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go(RoutePaths.dashboard);
          }
        },
        onNotificationTap: () async {
          await context.push(RoutePaths.notification);
        },
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: AppColors.appBackgroundGradient,
        ),
        child: SafeArea(
          top: false,
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: MediaQuery.paddingOf(context).top + 72 + 30),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _buildFormContent(provider),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormContent(KhachHangProvider provider) {
    if (provider.isLoadingOptions && provider.options == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (provider.options == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              provider.optionsError ?? 'Không thể tải dữ liệu cho biểu mẫu',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: Colors.red),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => provider.loadOptions(force: true),
              child: const Text(
                'Tải lại',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      );
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 40),
      child: FormBuilder(
        key: _formKey,
        initialValue: {
          _fName: widget.item.name,
          _fPhone: widget.item.phone,
          _fEmail: widget.item.email,
          _fStatus: _initStatus,
          _fProjectId: _initProjectId,
          _fTypeId: _initTypeId,
          _fAreaId: _initAreaId,
          _fSourceId: _initSourceId,
          _fScheduleContact:
              _initScheduleContact != null && _initScheduleContact!.isNotEmpty
              ? DateTime.tryParse(_initScheduleContact!)
              : null,
          _fRegionId:
              provider.options?.region.containsKey(_initRegionId) ?? false
              ? _initRegionId
              : null,
          _fNote: widget.item.note,
          _fFinancialRange: widget.item.financialRange,
        },
        child: Column(
          children: [
            // Card 1
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF3F3F3F)),
                gradient: const LinearGradient(
                  colors: [Color(0xFF242426), Color(0xFF3b3537)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  khHangFieldColumn(
                    label: 'Họ và tên',
                    required: true,
                    child: khHangFormTextField(
                      name: _fName,
                      hint: 'Nhập họ và tên',
                      validators: [
                        FormBuilderValidators.required(
                          errorText: 'Vui lòng nhập họ tên',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  khHangFieldColumn(
                    label: 'Số điện thoại',
                    required: true,
                    child: khHangFormTextField(
                      name: _fPhone,
                      hint: 'Nhập SĐT',
                      keyboardType: TextInputType.phone,
                      validators: [
                        FormBuilderValidators.required(
                          errorText: 'Vui lòng nhập số điện thoại',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  khHangFieldColumn(
                    label: 'Email',
                    child: khHangFormTextField(
                      name: _fEmail,
                      hint: 'Nhập email',
                      keyboardType: TextInputType.emailAddress,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Card 2
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF3F3F3F)),
                gradient: const LinearGradient(
                  colors: [Color(0xFF242426), Color(0xFF3b3537)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  khHangFieldRow(
                    left: khHangFieldColumn(
                      label: 'Tỉnh/ Thành phố',
                      child: khHangFormDropdown<int>(
                        name: _fRegionId,
                        placeholder: 'Chọn tỉnh/thành',
                        items: [
                          ...provider.options!.region.entries.map(
                            (e) => DropdownMenuItem(
                              value: e.key,
                              child: Text(e.value),
                            ),
                          ),
                        ],
                      ),
                    ),
                    right: khHangFieldColumn(
                      label: 'Sale phụ trách',
                      child: _buildMultiSelectSale(provider.options!.sale),
                    ),
                  ),

                  khHangFieldColumn(
                    label: 'Dự án',
                    child: khHangFormDropdown<int>(
                      name: _fProjectId,
                      placeholder: 'Chọn dự án',
                      items: [
                        ...provider.options!.project.entries.map(
                          (e) => DropdownMenuItem(
                            value: e.key,
                            child: Text(e.value),
                          ),
                        ),
                        if (_initProjectId != null &&
                            !provider.options!.project.containsKey(
                              _initProjectId,
                            ))
                          DropdownMenuItem(
                            value: _initProjectId,
                            child: Text('Dự án ẩn ID: $_initProjectId'),
                          ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          provider.setSelectedProject(value);
                          _formKey.currentState?.fields[_fAreaId]?.didChange(
                            null,
                          );
                          _formKey.currentState?.fields[_fTypeId]?.didChange(
                            null,
                          );
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 20),

                  khHangFieldRow(
                    left: khHangFieldColumn(
                      label: 'Phân khu',
                      child: khHangFormDropdown<String>(
                        name: _fAreaId,
                        placeholder: 'Chọn phân khu',
                        items: [
                          ...provider
                              .getProjectOptions('area')
                              .map(
                                (e) =>
                                    DropdownMenuItem(value: e, child: Text(e)),
                              ),
                          if (_initAreaId != null &&
                              _initAreaId!.isNotEmpty &&
                              !provider
                                  .getProjectOptions('area')
                                  .contains(_initAreaId))
                            DropdownMenuItem(
                              value: _initAreaId,
                              child: Text(_initAreaId!),
                            ),
                        ],
                      ),
                    ),
                    right: khHangFieldColumn(
                      label: 'Loại hình',
                      child: khHangFormDropdown<String>(
                        name: _fTypeId,
                        placeholder: 'Chọn loại hình',
                        items: [
                          ...provider
                              .getProjectOptions('type')
                              .map(
                                (e) =>
                                    DropdownMenuItem(value: e, child: Text(e)),
                              ),
                          if (_initTypeId != null &&
                              _initTypeId!.isNotEmpty &&
                              !provider
                                  .getProjectOptions('type')
                                  .contains(_initTypeId))
                            DropdownMenuItem(
                              value: _initTypeId,
                              child: Text(_initTypeId!),
                            ),
                        ],
                      ),
                    ),
                  ),

                  khHangFieldRow(
                    left: khHangFieldColumn(
                      label: 'Khoảng tài chính',
                      child: khHangFormDropdown<String>(
                        name: _fFinancialRange,
                        placeholder: 'Chọn giá',
                        items: [
                          ...provider.options!.financialRange.entries.map(
                            (e) => DropdownMenuItem(
                              value: e.key,
                              child: Text(e.value),
                            ),
                          ),
                          if (widget.item.financialRange != null &&
                              widget.item.financialRange!.isNotEmpty &&
                              !provider.options!.financialRange.containsKey(
                                widget.item.financialRange,
                              ))
                            DropdownMenuItem(
                              value: widget.item.financialRange,
                              child: Text(widget.item.financialRange!),
                            ),
                        ],
                      ),
                    ),
                    right: khHangFieldColumn(
                      label: 'Tình trạng',
                      child: Builder(
                        builder: (ctx) {
                          final statusOptions = <int, String>{
                            for (
                              var i = 0;
                              i < provider.options!.status.length;
                              i++
                            )
                              i: provider.options!.status[i],
                          };

                          // Merge old status values if they are not in options
                          for (final s in _initStatus) {
                            if (!statusOptions.containsKey(s)) {
                              statusOptions[s] = 'Tình trạng $s';
                            }
                          }

                          return khHangFormMultiSelectSheet<int>(
                            name: _fStatus,
                            hintText: 'Chọn tình trạng',
                            context: context,
                            options: statusOptions,
                          );
                        },
                      ),
                    ),
                  ),

                  khHangFieldRow(
                    left: khHangFieldColumn(
                      label: 'Lịch tương tác',
                      child: khHangFormDateField(
                        name: _fScheduleContact,
                        hint: 'Chọn ngày',
                        context: context,
                      ),
                    ),
                    right: khHangFieldColumn(
                      label: 'Nguồn',
                      child: khHangFormDropdown<int>(
                        name: _fSourceId,
                        placeholder: 'Chọn nguồn',
                        items: [
                          ...provider.options!.source.entries.map(
                            (e) => DropdownMenuItem(
                              value: e.key,
                              child: Text(e.value),
                            ),
                          ),
                          if (_initSourceId != null &&
                              !provider.options!.source.containsKey(
                                _initSourceId,
                              ))
                            DropdownMenuItem(
                              value: _initSourceId,
                              child: Text('Nguồn ẩn ID: $_initSourceId'),
                            ),
                        ],
                      ),
                    ),
                  ),

                  khHangFieldColumn(
                    label: 'Ghi chú',
                    child: khHangFormTextField(
                      name: _fNote,
                      hint: 'Nhập ghi chú',
                      maxLines: null,
                      height: 132,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),
            // submit button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: AnGradientBorder(
                backgroundColor: const Color(0xFF302D33),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _isSubmitting ? null : _onDone,
                    borderRadius: BorderRadius.circular(8),
                    child: Center(
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Color(0xFFFEDBAF),
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'XONG',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFFEDBAF),
                                letterSpacing: 2.8,
                              ),
                            ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMultiSelectSale(Map<int, String> saleOptions) {
    final displayText = _selectedSaleIds
        .where((id) => saleOptions.containsKey(id))
        .map((id) => saleOptions[id]!)
        .join(', ');

    return GestureDetector(
      onTap: () async {
        final result = await khHangShowMultiSelectSheet<int>(
          context: context,
          title: 'Chọn sale phụ trách',
          options: saleOptions,
          selected: _selectedSaleIds,
        );
        if (result != null) {
          setState(() {
            _selectedSaleIds.clear();
            _selectedSaleIds.addAll(result);
          });
        }
      },
      child: Container(
        height: 42,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: const Color(0x33FAF2EF), // rgba(250,242,239,0.2)
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.centerLeft,
        child: Row(
          children: [
            Expanded(
              child: Text(
                displayText.isEmpty ? 'Chọn sale' : displayText,
                style: TextStyle(
                  fontSize: 16,
                  color: displayText.isEmpty
                      ? const Color(0x80B9B0AC)
                      : Colors.white,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: Color(0x80B9B0AC),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
