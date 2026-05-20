import 'package:anholding_app/src/core/paths/route_paths.dart';
import 'package:anholding_app/src/core/theme/app_colors.dart';
import 'package:anholding_app/src/core/widgets/an_feature_app_bar.dart';
import 'package:anholding_app/src/features/khach_hang/domain/entities/khach_hang_item.dart';
import 'package:anholding_app/src/features/khach_hang/presentation/provider/khach_hang_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class KhachHangTraoDoiScreen extends StatefulWidget {
  const KhachHangTraoDoiScreen({required this.item, super.key});

  final KhachHangItem item;

  @override
  State<KhachHangTraoDoiScreen> createState() => _KhachHangTraoDoiScreenState();
}

class _KhachHangTraoDoiScreenState extends State<KhachHangTraoDoiScreen> {
  final _exchangeController = TextEditingController();
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<KhachHangProvider>().loadContacts(widget.item.id);
    });
  }

  @override
  void dispose() {
    _exchangeController.dispose();
    super.dispose();
  }

  // ═══════════════════════════════════════════════════════════
  //  CONTACT HELPERS
  // ═══════════════════════════════════════════════════════════

  String _buildInitials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  Color _avatarColorFromId(String userId) {
    const palette = [
      Color(0xFF4A88FF),
      Color(0xFFFF4920),
      Color(0xFF00B894),
      Color(0xFFE17055),
      Color(0xFF6C5CE7),
      Color(0xFFFD79A8),
      Color(0xFF00CEC9),
      Color(0xFFFF7675),
    ];
    final hash = userId.hashCode.abs();
    return palette[hash % palette.length];
  }

  String _formatContactDate(String raw) {
    try {
      final dt = DateTime.parse(raw);
      return DateFormat('dd/MM/yyyy  HH:mm').format(dt);
    } catch (_) {
      return raw;
    }
  }

  // ═══════════════════════════════════════════════════════════
  //  ACTIONS
  // ═══════════════════════════════════════════════════════════

  Future<void> _onSend() async {
    final text = _exchangeController.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() => _isSending = true);

    final provider = context.read<KhachHangProvider>();
    final success = await provider.createContact(
      customerId: widget.item.id,
      comment: text,
    );

    if (!mounted) return;
    setState(() => _isSending = false);

    if (success) {
      _exchangeController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gửi thành công'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.contactsError ?? 'Gửi thất bại'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _confirmDeleteContact({required String contactId}) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.darkBackground2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Xác nhận',
          style: TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w700,
            fontSize: 16,
            color: AppColors.authButtonText,
          ),
        ),
        content: const Text(
          'Bạn có chắc muốn xoá trao đổi này?',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            color: AppColors.authButtonText,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text(
              'Huỷ',
              style: TextStyle(color: AppColors.textHint),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Xoá', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final provider = context.read<KhachHangProvider>();
    final msg = await provider.deleteContact(
      contactId: contactId,
      customerId: widget.item.id,
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg ?? (provider.contactsError ?? 'Xoá thất bại')),
        backgroundColor: msg != null ? Colors.green : Colors.red,
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  //  BUILD
  // ═══════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final bottomSafe = MediaQuery.viewPaddingOf(context).bottom;

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AnFeatureAppBar(
        onBackTap: () {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go(RoutePaths.khachHang);
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Top content + timeline ────────────────────────
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Title (customer name) ─────────
                      _buildTitleSection(),
                      const SizedBox(height: 20),

                      // ── Timeline card ─────────────────
                      Expanded(child: _buildTimelineCard()),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Title Section ───────────────────────────────────────────────────────

  Widget _buildTitleSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (bounds) => const LinearGradient(
            colors: [
              AppColors.titleGradientStart,
              AppColors.titleGradientMiddle,
              AppColors.titleGradientStart,
            ],
            stops: [0.0885, 0.5097, 0.9559],
            transform: GradientRotation(125.609 * 3.1415927 / 180),
          ).createShader(bounds),
          child: Text(
            widget.item.name.toUpperCase(),
            style: const TextStyle(
              fontFamily: 'Inter',
              fontWeight: FontWeight.w300,
              fontSize: 24,
              letterSpacing: -0.75,
              height: 36 / 24,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: 64,
          height: 1,
          color: AppColors.titleUnderline,
        ),
      ],
    );
  }

  // ─── Timeline Card ────────────────────────────────────────────────────────

  Widget _buildTimelineCard() {
    return Container(
      decoration: _timelineCardDecoration(),
      child: Column(
        children: [
          Expanded(
            child: Consumer<KhachHangProvider>(
              builder: (context, provider, _) {
                if (provider.isLoadingContacts) {
                  return const Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primaryGold,
                    ),
                  );
                }

                if (provider.contacts.isEmpty) {
                  return const Center(
                    child: Text(
                      'Chưa có trao đổi nào',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        color: AppColors.textHint,
                      ),
                    ),
                  );
                }

                return ShaderMask(
                  shaderCallback: (bounds) {
                    return const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white,
                        Colors.white,
                        Colors.transparent,
                      ],
                      stops: [0.0, 0.85, 1.0],
                    ).createShader(bounds);
                  },
                  blendMode: BlendMode.dstIn,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
                    itemCount: provider.contacts.length,
                    itemBuilder: (context, index) {
                      final contact = provider.contacts[index];
                      final initials = _buildInitials(contact.name);
                      final avatarColor = _avatarColorFromId(contact.userId);
                      final formattedDate = _formatContactDate(
                        contact.createdAt,
                      );
                      final isLast = index == provider.contacts.length - 1;

                      return _TimelineItem(
                        initials: initials,
                        avatarColor: avatarColor,
                        name: contact.name,
                        date: formattedDate,
                        content: contact.comment,
                        showLine: !isLast,
                        onDelete: () =>
                            _confirmDeleteContact(contactId: contact.id),
                      );
                    },
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 36),
          _buildInputArea(),
        ],
      ),
    );
  }

  BoxDecoration _timelineCardDecoration() {
    return BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF242426), Color(0xFF3B3537)],
        transform: GradientRotation(95.5122 * 3.1415927 / 180),
      ),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFF3F3F3F)),
    );
  }

  // ─── Input Area ───────────────────────────────────────────────────────────

  Widget _buildInputArea() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      decoration: BoxDecoration(
        color: const Color(0xFFEDEDED),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0x1AB9B0AC)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Textarea
          FormBuilderTextField(
            name: 'exchange_input',
            controller: _exchangeController,
            maxLines: 4,
            minLines: 3,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              color: Color(0xFF37312E),
            ),
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.fromLTRB(21, 20, 21, 0),
              hintText: 'NHẬP NỘI DUNG TRAO ĐỔI...',
              hintStyle: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                color: Color(0x4D645E5A),
              ),
            ),
          ),

          // Divider + actions
          Container(
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: Color(0x1AB9B0AC)),
              ),
            ),
            padding: const EdgeInsets.fromLTRB(21, 16, 21, 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // GỬI button
                GestureDetector(
                  onTap: _isSending ? null : _onSend,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF302D33),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: _isSending
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.authButtonText,
                            ),
                          )
                        : const Text(
                            'GỬI',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w700,
                              fontSize: 9,
                              color: Colors.white,
                              letterSpacing: 2.7,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── XONG Button ─────────────────────────────────────────────────────────

  Widget _buildXongButton(double bottomSafe) {
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 12, 24, 16 + bottomSafe),
      child: GestureDetector(
        onTap: () {
          if (context.canPop()) context.pop();
        },
        child: Container(
          width: double.infinity,
          height: 42,
          decoration: BoxDecoration(
            color: const Color(0xFF302D33),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.buttonBorder),
          ),
          child: const Center(
            child: Text(
              'XONG',
              style: TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: AppColors.authButtonText,
                letterSpacing: 2.8,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  PRIVATE WIDGETS
// ═══════════════════════════════════════════════════════════

class _TimelineItem extends StatelessWidget {
  const _TimelineItem({
    required this.initials,
    required this.avatarColor,
    required this.name,
    required this.date,
    required this.content,
    required this.showLine,
    this.onDelete,
  });

  final String initials;
  final Color avatarColor;
  final String name;
  final String date;
  final String content;
  final bool showLine;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    // NOTE: Do NOT use IntrinsicHeight here — Stack does not implement
    // computeDryBaseline and will always crash inside IntrinsicHeight.
    // Instead, Stack is the root widget so Positioned children (dot, line)
    // can freely anchor to the measured content height.
    return Stack(
      children: [
        // ── Content (defines item height) ─────────────────
        Padding(
          padding: const EdgeInsets.only(left: 24, bottom: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Name + date row
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Expanded(
                    child: Text(
                      name.toUpperCase(),
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                        color: AppColors.authButtonText,
                        letterSpacing: 1.1,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    date,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w500,
                      fontSize: 9,
                      color: Color(0xFF645E5A),
                      letterSpacing: -0.45,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Content bubble
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 21,
                  vertical: 20,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xB3FFFFFF),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0x1AB9B0AC)),
                ),
                child: Text(
                  content,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w400,
                    fontSize: 13,
                    color: Color(0xFF37312E),
                    height: 1.625,
                  ),
                ),
              ),
            ],
          ),
        ),

        // ── Timeline dot ───────────────────────────────────
        Positioned(
          left: 0,
          top: 6,
          child: Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              color: const Color(0xFF635A55),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),

        // ── Timeline vertical connector line ───────────────
        if (showLine)
          Positioned(
            left: 2,
            top: 12,
            bottom: 0,
            child: Container(
              width: 1,
              color: const Color(0x80635A55),
            ),
          ),
      ],
    );
  }
}
