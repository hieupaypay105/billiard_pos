import 'dart:async';

import 'package:anholding_app/src/core/constants/app_icons.dart';
import 'package:anholding_app/src/core/theme/app_colors.dart';
import 'package:anholding_app/src/features/khach_hang/domain/entities/khach_hang_item.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class KhachHangCard extends StatelessWidget {
  const KhachHangCard({
    required this.item,
    required this.saleName,
    super.key,
    this.isTeam = false,
    this.onCallTap,
    this.onChatTap,
    this.onZaloTap,
    this.onEditTap,
    this.onDeleteTap,
  });

  final KhachHangItem item;
  final String saleName;
  final bool isTeam;
  final VoidCallback? onCallTap;
  final VoidCallback? onChatTap;
  final VoidCallback? onZaloTap;
  final VoidCallback? onEditTap;
  final VoidCallback? onDeleteTap;

  void _handleCallTap(BuildContext context) {
    final onCall = onCallTap;
    if (onCall == null) return;

    final isAndroid =
        !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
    if (!isAndroid) {
      onCall();
      return;
    }

    final phone = item.phone?.trim() ?? '';
    final displayPhone = phone.isNotEmpty ? phone : 'số này';
    unawaited(
      showCupertinoModalPopup<bool>(
        context: context,
        builder: (sheetContext) => CupertinoActionSheet(
          actions: [
            CupertinoActionSheetAction(
              onPressed: () => Navigator.of(sheetContext).pop(true),
              child: Text('Gọi $displayPhone'),
            ),
          ],
          cancelButton: CupertinoActionSheetAction(
            onPressed: () => Navigator.of(sheetContext).pop(false),
            child: const Text('Hủy'),
          ),
        ),
      ).then((confirmed) {
        if (confirmed ?? false) {
          onCall();
        }
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final statusLabels = item.statusLabel
        .map((label) => label.trim())
        .where((label) => label.isNotEmpty)
        .toList(growable: false);
    final statusValues = item.status
        .split(',')
        .map((status) => status.trim())
        .where((status) => status.isNotEmpty)
        .toList(growable: false);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(21, 21, 21, 0),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            AppColors.cardGradientStart,
            AppColors.cardGradientEnd,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          transform: GradientRotation(117.868 * 3.1415927 / 180),
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.dashboardCardBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 2,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header (Name + Status) ─────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  item.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    height: 20 / 16,
                    color: AppColors.authButtonText,
                    letterSpacing: -0.4,
                  ),
                ),
              ),
              if (statusLabels.isNotEmpty) ...[
                const SizedBox(width: 8),
                _StatusBadge(
                  label: statusLabels.first,
                  color: _getStatusColor(
                    statusValues.isNotEmpty ? statusValues.first : item.status,
                  ),
                  maxWidth: 120,
                ),
                if (statusLabels.length > 1) ...[
                  const SizedBox(width: 6),
                  Builder(
                    builder: (iconContext) => GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () async {
                        final scrollController = ScrollController();
                        final overlayState = Overlay.of(iconContext);
                        final overlayObject = overlayState.context
                            .findRenderObject();
                        final iconObject = iconContext.findRenderObject();
                        if (overlayObject is! RenderBox ||
                            iconObject is! RenderBox) {
                          return;
                        }

                        final overlay = overlayObject;
                        final renderBox = iconObject;
                        final position = RelativeRect.fromRect(
                          Rect.fromPoints(
                            renderBox.localToGlobal(
                              renderBox.size.bottomLeft(const Offset(0, 8)),
                              ancestor: overlay,
                            ),
                            renderBox.localToGlobal(
                              renderBox.size.bottomRight(const Offset(0, 8)),
                              ancestor: overlay,
                            ),
                          ),
                          Offset.zero & overlay.size,
                        );

                        await showMenu<String>(
                          context: iconContext,
                          position: position,
                          color: AppColors.darkBackground2,
                          elevation: 8,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          items: [
                            PopupMenuItem<String>(
                              enabled: false,
                              padding: const EdgeInsets.all(12),
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxWidth: 220,
                                ),
                                child: Scrollbar(
                                  controller: scrollController,
                                  thumbVisibility: true,
                                  child: SingleChildScrollView(
                                    controller: scrollController,
                                    scrollDirection: Axis.horizontal,
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: List.generate(
                                        statusLabels.length,
                                        (index) => Padding(
                                          padding: EdgeInsets.only(
                                            right:
                                                index < statusLabels.length - 1
                                                ? 8
                                                : 0,
                                          ),
                                          child: _StatusBadge(
                                            label: statusLabels[index],
                                            color: _getStatusColor(
                                              index < statusValues.length
                                                  ? statusValues[index]
                                                  : item.status,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                      child: SvgPicture.asset(
                        AppIcons.khCardChevronRight,
                        width: 24,
                        height: 24,
                      ),
                    ),
                  ),
                ],
              ],
            ],
          ),
          const SizedBox(height: 8),

          // ── Divider ──────────────────────────────────────────
          Container(
            height: 1,
            color: AppColors.authInputBorder, // Matches imgLine10/11
          ),
          const SizedBox(height: 8),

          // ── Phone & Last Contact ────────────────────────────
          Row(
            children: [
              if ((item.phone ?? '').isNotEmpty) ...[
                SvgPicture.asset(
                  AppIcons.khCardPhone,
                  width: 12,
                  height: 12,
                ),
                const SizedBox(width: 8),
                Text(
                  item.phone!,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w400,
                    fontSize: 12,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 8),
              ],

              if ((item.lastContact ?? '').isNotEmpty)
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.darkBackground,
                      border: Border.all(color: AppColors.cardTagBorder),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Liên hệ cuối: ${item.lastContact!}',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w400,
                        fontSize: 12,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),

          Container(
            height: 1,
            color: AppColors.authInputBorder,
          ),
          const SizedBox(height: 6),

          // ── Details (Project, Region/Range, Sale) ─────────────
          Row(
            children: [
              Expanded(
                flex: 2,
                child: Text(
                  (item.projectLabel ?? '').isNotEmpty
                      ? item.projectLabel!
                      : '--',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w400,
                    fontSize: 12,
                    color: AppColors.textHint, // #909090
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              const SizedBox(width: 8),

              Expanded(
                flex: 2,
                child: Row(
                  children: [
                    SvgPicture.asset(
                      AppIcons.khCardFinance,
                      width: 12,
                      height: 12,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        (item.financialRangeLabel ?? '').isNotEmpty
                            ? item.financialRangeLabel!
                            : '--',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w400,
                          fontSize: 12,
                          color: AppColors.textHint,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              if (saleName.isNotEmpty) const SizedBox(width: 8),

              Expanded(
                flex: 4,
                child: Row(
                  children: [
                    SvgPicture.asset(
                      AppIcons.khCardPerson,
                      width: 12,
                      height: 12,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        saleName.isNotEmpty ? saleName : '--',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w400,
                          fontSize: 12,
                          color: AppColors.textHint,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ── Actions Footer ───────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: AppColors.authInputBorder),
              ),
            ),
            child: Row(
              children: [
                if (item.canUpdate == 1) ...[
                  _ActionButton(
                    svgAsset: AppIcons.khCardPhone,
                    label: 'GỌI',
                    onTap: () => _handleCallTap(context),
                  ),
                  const SizedBox(width: 8),
                ],
                _ActionButton(
                  svgAsset: AppIcons.khCardActionChat,
                  label: 'TRAO ĐỔI',
                  onTap: onChatTap,
                ),
                if (item.canUpdate == 1) ...[
                  const SizedBox(width: 8),
                  _ZaloActionButton(
                    onTap: onZaloTap,
                  ),
                ],
                const Spacer(),
                if (onEditTap != null && item.canUpdate == 1) ...[
                  _IconActionButton(
                    svgAsset: AppIcons.khCardActionEdit,
                    onTap: onEditTap,
                  ),
                  const SizedBox(width: 4),
                ],

                if (onDeleteTap != null && item.canDelete == 1) ...[
                  _IconActionButton(
                    svgAsset: AppIcons.khCardActionDelete,
                    onTap: onDeleteTap,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Color _getStatusColor(String statusStr) {
    final idx = int.tryParse(statusStr.trim());
    if (idx != null && idx >= 0 && idx < AppColors.khStatusColors.length) {
      return AppColors.khStatusColors[idx];
    }
    return Colors.grey;
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({
    required this.label,
    required this.color,
    this.maxWidth,
  });

  final String label;
  final Color color;
  final double? maxWidth;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: maxWidth ?? double.infinity,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 8,
          vertical: 2,
        ),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label.toUpperCase(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          softWrap: false,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w700,
            fontSize: 9,
            color: Colors.white,
            letterSpacing: 0.45,
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.svgAsset,
    required this.label,
    this.onTap,
  });

  final String svgAsset;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.cardActionBg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.authButtonBorder),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(
              svgAsset,
              width: 14,
              height: 14,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.w500,
                fontSize: 10,
                color: AppColors.textHint,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ZaloActionButton extends StatelessWidget {
  const _ZaloActionButton({this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 36,
        height: 24,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: SizedBox(
          width: 24,
          height: 24,
          child: Center(
            child: SvgPicture.asset(
              AppIcons.khCardActionZalo,
              width: 24,
              height: 9,
            ),
          ),
        ),
      ),
    );
  }
}

class _IconActionButton extends StatelessWidget {
  const _IconActionButton({
    required this.svgAsset,
    this.onTap,
  });

  final String svgAsset;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(8),
        child: SvgPicture.asset(
          svgAsset,
          width: 16,
          height: 16,
        ),
      ),
    );
  }
}
