import 'package:anholding_app/src/core/paths/route_paths.dart';
import 'package:anholding_app/src/core/theme/app_colors.dart';
import 'package:anholding_app/src/core/widgets/an_feature_app_bar.dart';
import 'package:anholding_app/src/features/bang_hang/presentation/provider/bang_hang_provider.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

const Color _kBgTop = AppColors.dashboardBgStart;
const Color _kBgBottom = AppColors.dashboardBgEnd;

const Color _kInputBg = Color(0x33FAF2EF);
const Color _kInputBorder = Color(0x4DB9B0AC);
const double _kInputHeight = 49;
const TextStyle _kLabelStyle = TextStyle(
  fontSize: 10,
  color: Color(0xFF645E5A),
  fontFamily: 'Inter',
  letterSpacing: 1,
  fontWeight: FontWeight.normal,
);
const TextStyle _kInputTextStyle = TextStyle(
  fontSize: 16,
  color: Color(0xFFB9B0AC),
  fontFamily: 'Inter',
  fontWeight: FontWeight.normal,
);

class BangHangFilterScreen extends StatefulWidget {
  const BangHangFilterScreen({required this.initialFilter, super.key});

  final BangHangFilter initialFilter;

  @override
  State<BangHangFilterScreen> createState() => _BangHangFilterScreenState();
}

class _BangHangFilterScreenState extends State<BangHangFilterScreen> {
  int? _selectedProjectId;
  late List<String> _area;
  late List<String> _type;
  late List<String> _direction;
  late List<String> _handoverStatus;
  late TextEditingController _codeController;
  late TextEditingController _priceMinController;
  late TextEditingController _priceMaxController;
  late TextEditingController _ttsMinController;
  late TextEditingController _ttsMaxController;
  late TextEditingController _acreageMinController;
  late TextEditingController _acreageMaxController;

  @override
  void initState() {
    super.initState();
    final filter = widget.initialFilter;
    final activeProjectId = context.read<BangHangProvider>().selectedProjectId;
    _selectedProjectId = activeProjectId;
    final isSameProject = filter.projectId == activeProjectId;
    _area = isSameProject ? List.from(filter.area) : <String>[];
    _type = isSameProject ? List.from(filter.type) : <String>[];
    _direction = isSameProject ? List.from(filter.direction) : <String>[];
    _handoverStatus = isSameProject
        ? List.from(filter.handoverStatus)
        : <String>[];
    _codeController = TextEditingController(text: filter.code ?? '');
    _priceMinController = TextEditingController(
      text: filter.price.min?.toStringAsFixed(0) ?? '',
    );
    _priceMaxController = TextEditingController(
      text: filter.price.max?.toStringAsFixed(0) ?? '',
    );
    _ttsMinController = TextEditingController(
      text: filter.tts.min?.toStringAsFixed(0) ?? '',
    );
    _ttsMaxController = TextEditingController(
      text: filter.tts.max?.toStringAsFixed(0) ?? '',
    );
    _acreageMinController = TextEditingController(
      text: filter.acreage.min?.toStringAsFixed(0) ?? '',
    );
    _acreageMaxController = TextEditingController(
      text: filter.acreage.max?.toStringAsFixed(0) ?? '',
    );
  }

  @override
  void dispose() {
    _codeController.dispose();
    _priceMinController.dispose();
    _priceMaxController.dispose();
    _ttsMinController.dispose();
    _ttsMaxController.dispose();
    _acreageMinController.dispose();
    _acreageMaxController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reconcileProjectContext(
      context.read<BangHangProvider>().selectedProjectId,
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BangHangProvider>();
    final isProjectContextReady = _selectedProjectId != null;
    final areDependentFiltersEnabled =
        isProjectContextReady && !provider.isLoadingOptions;

    return Scaffold(
      backgroundColor: _kBgTop,
      appBar: AnFeatureAppBar(
        featureTitle: 'TÌM KIẾM',
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
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_kBgTop, _kBgBottom],
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 37),


              // ── Filter Form ─────────────────────────────
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. Phân khu/Block
                      _DropdownMultiSelect(
                        label: 'Phân khu/Block',
                        placeholder: 'Chọn phân khu',
                        options: provider.getOptions('area'),
                        selected: _area,
                        onChanged: (v) => setState(() => _area = v),
                        enabled: areDependentFiltersEnabled,
                        isLoading: provider.isLoadingOptions,
                      ),
                      const SizedBox(height: 16),

                      // // 2. Mã căn
                      // _SearchTextField(
                      //   label: 'Mã căn',
                      //   controller: _codeController,
                      //   hintText: 'Nhập từ khóa',
                      // ),
                      // const SizedBox(height: 16),

                      // 3. Loại hình
                      _DropdownMultiSelect(
                        label: 'Loại hình',
                        placeholder: 'Loại hình',
                        options: provider.getOptions('type'),
                        selected: _type,
                        onChanged: (v) => setState(() => _type = v),
                        enabled: areDependentFiltersEnabled,
                        isLoading: provider.isLoadingOptions,
                      ),
                      const SizedBox(height: 16),

                      // 4. Hướng
                      _DropdownMultiSelect(
                        label: 'Hướng',
                        placeholder: 'Chọn hướng',
                        options: provider.getOptions('direction'),
                        selected: _direction,
                        onChanged: (v) => setState(() => _direction = v),
                        enabled: areDependentFiltersEnabled,
                        isLoading: provider.isLoadingOptions,
                      ),
                      const SizedBox(height: 16),

                      // 5. Tiêu chuẩn bàn giao
                      _DropdownMultiSelect(
                        label: 'Tiêu chuẩn bàn giao',
                        placeholder: 'Tiêu chuẩn bàn giao',
                        options: provider.getOptions('handover_status'),
                        selected: _handoverStatus,
                        onChanged: (v) => setState(() => _handoverStatus = v),
                        enabled: areDependentFiltersEnabled,
                        isLoading: provider.isLoadingOptions,
                      ),
                      const SizedBox(height: 16),

                      // 6. Khoảng giá Full(tỷ)
                      _DropdownRangeField(
                        label: 'Khoảng giá Full(tỷ)',
                        placeholder: 'Khoảng giá',
                        minController: _priceMinController,
                        maxController: _priceMaxController,
                      ),
                      const SizedBox(height: 16),

                      // 7. Khoảng diện tích đất(m2)
                      _DropdownRangeField(
                        label: 'Khoảng diện tích đất',
                        placeholder: 'Khoảng diện tích',
                        minController: _acreageMinController,
                        maxController: _acreageMaxController,
                      ),
                      const SizedBox(height: 16),

                      // 8. Khoảng giá TTS(tỷ)
                      _DropdownRangeField(
                        label: 'Khoảng giá TTS(tỷ)',
                        placeholder: 'Khoảng giá',
                        minController: _ttsMinController,
                        maxController: _ttsMaxController,
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),

              // ── Submit Button ─────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 24,
                  horizontal: 24,
                ),
                child: Align(
                  child: GestureDetector(
                    onTap: _onDone,
                    child: Container(
                      width: 196,
                      height: 52,
                      decoration: BoxDecoration(
                        color: const Color(0xFF38312E),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: const Color(0xFFFFDBB0),
                        ),
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        'XONG',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFFEDBAF),
                          letterSpacing: 2.8,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _reconcileProjectContext(int activeProjectId) {
    if (_selectedProjectId == activeProjectId) return;
    _selectedProjectId = activeProjectId;
    _area = <String>[];
    _type = <String>[];
    _direction = <String>[];
    _handoverStatus = <String>[];
  }

  void _onDone() {
    context.pop(
      BangHangFilter(
        projectId:
            _selectedProjectId ??
            context.read<BangHangProvider>().selectedProjectId,
        area: _area,
        type: _type,
        direction: _direction,
        handoverStatus: _handoverStatus,
        code: _codeController.text.trim().isEmpty
            ? null
            : _codeController.text.trim(),
        price: RangeFilter(
          min: double.tryParse(_priceMinController.text),
          max: double.tryParse(_priceMaxController.text),
        ),
        tts: RangeFilter(
          min: double.tryParse(_ttsMinController.text),
          max: double.tryParse(_ttsMaxController.text),
        ),
        acreage: RangeFilter(
          min: double.tryParse(_acreageMinController.text),
          max: double.tryParse(_acreageMaxController.text),
        ),
      ),
    );
  }
}

// ── Dropdown Multi-Select Field ─────────────────────────

class _DropdownMultiSelect extends StatelessWidget {
  const _DropdownMultiSelect({
    required this.label,
    required this.placeholder,
    required this.options,
    required this.selected,
    required this.onChanged,
    this.enabled = true,
    this.isLoading = false,
  });

  final String label;
  final String placeholder;
  final List<String> options;
  final List<String> selected;
  final ValueChanged<List<String>> onChanged;
  final bool enabled;
  final bool isLoading;

  String get _displayText {
    if (selected.isEmpty) return placeholder;
    return selected.join(', ');
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: _kLabelStyle),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: !enabled || isLoading
              ? null
              : () => _showOptionsSheet(context),
          child: Container(
            height: _kInputHeight,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: enabled ? _kInputBg : const Color(0x1AFAF2EF),
              border: const Border(bottom: BorderSide(color: _kInputBorder)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _displayText,
                    style: _kInputTextStyle.copyWith(
                      color: enabled && selected.isNotEmpty
                          ? Colors.white
                          : AppColors.textHint,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
                if (isLoading)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.5,
                      color: AppColors.textHint,
                    ),
                  )
                else
                  const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 24,
                    color: AppColors.textHint,
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _showOptionsSheet(BuildContext context) async {
    final tempSelected = List<String>.from(selected);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.filterDropdownPanel,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            label,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.authTextSecondary,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            onChanged(tempSelected);
                            Navigator.of(ctx).pop();
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              gradient: const LinearGradient(
                                colors: [
                                  AppColors.buttonGradientStart,
                                  AppColors.buttonGradientEnd,
                                ],
                              ),
                            ),
                            child: const Text(
                              'Xong',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.buttonText,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Divider(height: 1, color: AppColors.inputBorderLight),

                    // Scrollable options list
                    Flexible(
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: options.map((option) {
                            final isChecked = tempSelected.contains(option);
                            return InkWell(
                              onTap: () {
                                setSheetState(() {
                                  if (isChecked) {
                                    tempSelected.remove(option);
                                  } else {
                                    tempSelected.add(option);
                                  }
                                });
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                ),
                                child: Row(
                                  children: [
                                    SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: Checkbox(
                                        value: isChecked,
                                        onChanged: (_) {
                                          setSheetState(() {
                                            if (isChecked) {
                                              tempSelected.remove(option);
                                            } else {
                                              tempSelected.add(option);
                                            }
                                          });
                                        },
                                        activeColor: AppColors.primaryGold,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                        side: const BorderSide(
                                          color: AppColors.inputBorderLight,
                                        ),
                                        materialTapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                        visualDensity: VisualDensity.compact,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        option,
                                        style: _kInputTextStyle.copyWith(
                                          fontWeight: isChecked
                                              ? FontWeight.w600
                                              : FontWeight.normal,
                                          color: isChecked
                                              ? AppColors.primaryGold
                                              : AppColors.authTextSecondary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// ── Search Text Field ───────────────────────────────────

class _SearchTextField extends StatelessWidget {
  const _SearchTextField({
    required this.label,
    required this.controller,
    required this.hintText,
  });

  final String label;
  final TextEditingController controller;
  final String hintText;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: _kLabelStyle),
        const SizedBox(height: 8),
        Container(
          height: _kInputHeight,
          decoration: const BoxDecoration(
            color: _kInputBg,
            border: Border(bottom: BorderSide(color: _kInputBorder)),
          ),
          child: TextField(
            controller: controller,
            style: _kInputTextStyle.copyWith(color: Colors.white),
            decoration: InputDecoration(
              isDense: true,
              hintText: hintText,
              hintStyle: _kInputTextStyle,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 14,
              ),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              fillColor: Colors.transparent,
              filled: true,
              suffixIcon: const Icon(
                Icons.search,
                size: 24,
                color: AppColors.textHint,
              ),
              suffixIconConstraints: const BoxConstraints(
                minWidth: 40,
                minHeight: 24,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Dropdown Range Field ────────────────────────────────

class _DropdownRangeField extends StatefulWidget {
  const _DropdownRangeField({
    required this.label,
    required this.placeholder,
    required this.minController,
    required this.maxController,
  });

  final String label;
  final String placeholder;
  final TextEditingController minController;
  final TextEditingController maxController;

  @override
  State<_DropdownRangeField> createState() => _DropdownRangeFieldState();
}

class _DropdownRangeFieldState extends State<_DropdownRangeField> {
  bool _expanded = false;

  String get _displayText {
    final min = widget.minController.text;
    final max = widget.maxController.text;
    if (min.isNotEmpty && max.isNotEmpty) return '$min - $max';
    if (min.isNotEmpty) return 'Từ $min';
    if (max.isNotEmpty) return 'Đến $max';
    return widget.placeholder;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label.toUpperCase(), style: _kLabelStyle),
        const SizedBox(height: 8),

        // Dropdown trigger
        GestureDetector(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Container(
            height: _kInputHeight,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: const BoxDecoration(
              color: _kInputBg,
              border: Border(bottom: BorderSide(color: _kInputBorder)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _displayText,
                    style: _kInputTextStyle.copyWith(
                      color: _displayText == widget.placeholder
                          ? AppColors.textHint
                          : Colors.white,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
                AnimatedRotation(
                  turns: _expanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 24,
                    color: AppColors.textHint,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Expandable range inputs
        AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              children: [
                Expanded(
                  child: _RangeInput(
                    controller: widget.minController,
                    hintText: 'Từ',
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text('—', style: TextStyle(color: AppColors.textHint)),
                ),
                Expanded(
                  child: _RangeInput(
                    controller: widget.maxController,
                    hintText: 'Đến',
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ],
            ),
          ),
          crossFadeState: _expanded
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 200),
        ),
      ],
    );
  }
}

// ── Range Number Input ──────────────────────────────────

class _RangeInput extends StatelessWidget {
  const _RangeInput({
    required this.controller,
    required this.hintText,
    this.onChanged,
  });

  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: _kInputHeight,
      decoration: const BoxDecoration(
        color: _kInputBg,
        border: Border(bottom: BorderSide(color: _kInputBorder)),
      ),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        style: _kInputTextStyle.copyWith(color: Colors.white),
        onChanged: onChanged,
        decoration: InputDecoration(
          isDense: true,
          hintText: hintText,
          hintStyle: _kInputTextStyle,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 14,
          ),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          fillColor: Colors.transparent,
          filled: true,
        ),
      ),
    );
  }
}
