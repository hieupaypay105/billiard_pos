import 'dart:async';

import 'package:anholding_app/src/core/constants/app_icons.dart';
import 'package:anholding_app/src/core/theme/app_colors.dart';
import 'package:anholding_app/src/core/theme/app_text_styles.dart';
import 'package:anholding_app/src/core/widgets/an_gradient_border.dart';
import 'package:anholding_app/src/features/ai_assistant/domain/entities/ai_quota_request_info.dart';
import 'package:anholding_app/src/features/ai_assistant/presentation/provider/ai_assistant_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:provider/provider.dart';

class AiChatTab extends StatefulWidget {
  const AiChatTab({super.key});

  @override
  State<AiChatTab> createState() => _AiChatTabState();
}

class _AiChatTabState extends State<AiChatTab>
    with SingleTickerProviderStateMixin {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // Typing indicator animation
  late AnimationController _dotAnimController;
  late Animation<int> _dotCountAnimation;

  @override
  void initState() {
    super.initState();
    _dotAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat().ignore();
    _dotCountAnimation = IntTween(begin: 1, end: 3).animate(
      CurvedAnimation(parent: _dotAnimController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _dotAnimController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _textController.text.trim();
    if (text.isEmpty || text.length > 1000) return;

    unawaited(context.read<AiAssistantProvider>().sendMessage(text));
    _textController.clear();
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        unawaited(
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewPadding.bottom + 80,
      ),
      child: Consumer<AiAssistantProvider>(
        builder: (context, provider, child) {
          // Auto-scroll whenever messages list or loading state changes
          if (!provider.isLoading) {
            _scrollToBottom();
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                child: _buildRequestsProgress(provider.quotaRequestInfo),
              ),
              Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF242426),
                        Color(0xFF3B3537),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.dashboardCardBorder),
                  ),
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(20),
                    itemCount:
                        provider.messages.length + (provider.isLoading ? 1 : 0),
                    itemBuilder: (context, index) {
                      // Last item is typing indicator while loading
                      if (provider.isLoading &&
                          index == provider.messages.length) {
                        return _buildTypingIndicator();
                      }
                      final msg = provider.messages[index];
                      return _buildChatBubble(msg.text, msg.isUser);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (provider.error != null)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 4,
                  ),
                  child: Text(
                    provider.error!,
                    style: AppTextStyles.body.copyWith(
                      color: Colors.redAccent,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              _buildInputBox(provider),
            ],
          );
        },
      ),
    );
  }

  Widget _buildRequestsProgress(AiQuotaRequestInfo? info) {
    final used = info?.used ?? '0';
    final quota = info?.quota ?? 0;
    final percent = info?.percent ?? 0.0;
    final monthRequests = info?.monthRequests ?? '0';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            SvgPicture.asset(
              AppIcons.thunder,
              width: 24,
              height: 24,
            ),
            const SizedBox(width: 8),
            Text(
              'Requests hôm nay',
              style: AppTextStyles.body.copyWith(
                color: const Color(0xFF909090),
                fontSize: 12,
                fontWeight: FontWeight.w400,
                letterSpacing: -0.75,
              ),
            ),
            const Spacer(),
            Text(
              '$used /$quota',
              style: AppTextStyles.body.copyWith(
                color: const Color(0xFF10B981),
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.75,
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        Container(
          height: 6,
          width: double.infinity,
          clipBehavior: Clip.hardEdge,
          decoration: BoxDecoration(
            color: const Color(0xFFD9D9D9).withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Stack(
            children: [
              FractionallySizedBox(
                widthFactor: percent / 100,
                alignment: Alignment.centerLeft,
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Tháng: $monthRequests requests',
          style: AppTextStyles.body.copyWith(
            color: const Color(0xFF909090),
            fontSize: 12,
            fontWeight: FontWeight.w400,
            letterSpacing: -0.75,
          ),
        ),
      ],
    );
  }

  Widget _buildChatBubble(String text, bool isUser) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Row(
        mainAxisAlignment: isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: Color(0xFF474546),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: SvgPicture.asset(
                  AppIcons.chatbotTab,
                  width: 18,
                  height: 18,
                  colorFilter: const ColorFilter.mode(
                    AppColors.authButtonText,
                    BlendMode.srcIn,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
          ],
          Flexible(
            child: Container(
              padding: isUser
                  ? const EdgeInsets.symmetric(horizontal: 22, vertical: 11)
                  : const EdgeInsets.fromLTRB(21, 20, 21, 21),
              decoration: BoxDecoration(
                color: isUser
                    ? AppColors.badgeBlue
                    : Colors.white.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.authTextSecondary.withValues(alpha: 0.1),
                ),
              ),
              child: isUser
                  ? Text(
                      text,
                      style: AppTextStyles.body.copyWith(
                        color: const Color(0xFF37312E),
                        fontSize: 13,
                        height: 21.13 / 13,
                      ),
                    )
                  : HtmlWidget(
                      text,
                      textStyle: AppTextStyles.body.copyWith(
                        color: const Color(0xFF37312E),
                        fontSize: 13,
                        height: 21.13 / 13,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  /// Typing indicator — hiển thị khi AI đang xử lý (3 chấm nhấp nhô).
  Widget _buildTypingIndicator() {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              color: Color(0xFF474546),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: SvgPicture.asset(
                AppIcons.chatbotTab,
                width: 18,
                height: 18,
                colorFilter: const ColorFilter.mode(
                  AppColors.authButtonText,
                  BlendMode.srcIn,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppColors.authTextSecondary.withValues(alpha: 0.1),
              ),
            ),
            child: AnimatedBuilder(
              animation: _dotCountAnimation,
              builder: (context, _) {
                final dots = '.' * _dotCountAnimation.value;
                return Text(
                  'AI đang trả lời$dots',
                  style: AppTextStyles.body.copyWith(
                    color: const Color(0xFF909090),
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBox(AiAssistantProvider provider) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.searchBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: TextField(
                controller: _textController,
                style: AppTextStyles.body.copyWith(
                  fontSize: 14,
                  color: AppColors.authTextLight,
                ),
                enabled: !provider.isLoading,
                onSubmitted: (_) => _sendMessage(),
                decoration: InputDecoration(
                  hintText: 'Hỏi AI bất cứ điều gì...',
                  hintStyle: AppTextStyles.body.copyWith(
                    fontSize: 14,
                    color: AppColors.authTextSecondary,
                  ),
                  suffixIcon: IconButton(
                    icon: const Icon(
                      Icons.close,
                      color: AppColors.authTextSecondary,
                      size: 20,
                    ),
                    onPressed: _textController.clear,
                  ),
                  contentPadding: const EdgeInsets.only(
                    left: 16,
                    right: 8,
                    top: 12,
                    bottom: 12,
                  ),
                  border: InputBorder.none,
                  isDense: true,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Clear chat history button
          AnGradientBorder(
            width: 44,
            height: 44,
            backgroundColor: AppColors.buttonBgDark,
            child: InkWell(
              onTap: provider.isLoading ? null : () => provider.clearChat(),
              borderRadius: BorderRadius.circular(8),
              child: Center(
                child: SvgPicture.string(
                  '''
<svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none">
  <path d="M3 12C3 7.02944 7.02944 3 12 3C16.9706 3 21 7.02944 21 12C21 16.9706 16.9706 21 12 21C9.3345 21 6.9523 19.8398 5.33377 18" stroke="#FEDBAF" stroke-width="1.5" stroke-linecap="round"/>
  <path d="M3 7V12H8" stroke="#FEDBAF" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"/>
</svg>''',
                  width: 20,
                  height: 20,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Send button
          AnGradientBorder(
            width: 44,
            height: 44,
            backgroundColor: AppColors.buttonBgDark,
            child: InkWell(
              onTap: provider.isLoading ? null : _sendMessage,
              borderRadius: BorderRadius.circular(8),
              child: Center(
                child: SvgPicture.string(
                  '''
<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none">
  <path d="M18 6L11 13" stroke="#FEDBAF" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"/>
  <path d="M18 6L13.8 18L11.4 12.6L6 10.2L18 6Z" stroke="#FEDBAF" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"/>
</svg>''',
                  width: 24,
                  height: 24,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
