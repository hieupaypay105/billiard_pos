import 'dart:async' show unawaited;

import 'package:anholding_app/src/core/constants/app_icons.dart';
import 'package:anholding_app/src/core/paths/route_paths.dart';
import 'package:anholding_app/src/core/theme/app_colors.dart';
import 'package:anholding_app/src/core/theme/app_text_styles.dart';
import 'package:anholding_app/src/core/widgets/an_feature_app_bar.dart';
import 'package:anholding_app/src/features/ai_assistant/presentation/provider/ai_assistant_provider.dart';
import 'package:anholding_app/src/features/ai_assistant/presentation/widgets/ai_chat_tab.dart';
import 'package:anholding_app/src/features/ai_assistant/presentation/widgets/ai_table_tab.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class AiAssistantScreen extends StatefulWidget {
  const AiAssistantScreen({super.key});

  @override
  State<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends State<AiAssistantScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {});
    });
    // Gọi /ai/quota ngay khi vào màn hình lần đầu
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        unawaited(context.read<AiAssistantProvider>().fetchInitialQuota());
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.dashboardBgStart,
      appBar: AnFeatureAppBar(
        featureTitle: 'TRỢ LÝ AI',
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
        child: Padding(
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              _buildTabBar(),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: const [
                    AiTableTab(),
                    AiChatTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        dividerColor: Colors.transparent,
        indicatorColor: Colors.transparent,
        tabAlignment: TabAlignment.start,
        labelPadding: EdgeInsets.zero,
        overlayColor: WidgetStateProperty.all(Colors.transparent),
        tabs: [
          _buildCustomTab(
            text: 'TÌM KIẾM BẢNG HÀNG',
            iconPath: AppIcons.bdsSearchTab,
            isActive: _tabController.index == 0,
            showDivider: true,
          ),
          _buildCustomTab(
            text: 'CHATBOT HỖ TRỢ',
            iconPath: AppIcons.chatbotTab,
            isActive: _tabController.index == 1,
            showDivider: false,
          ),
        ],
      ),
    );
  }

  Widget _buildCustomTab({
    required String text,
    required String iconPath,
    required bool isActive,
    required bool showDivider,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Opacity(
          opacity: isActive ? 1.0 : 0.3,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                SvgPicture.asset(
                  iconPath,
                  width: 24,
                  height: 24,
                  colorFilter: const ColorFilter.mode(
                    AppColors.authButtonText,
                    BlendMode.srcIn,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  text,
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.authButtonText,
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                    letterSpacing: -0.75,
                    decoration: isActive
                        ? TextDecoration.underline
                        : TextDecoration.none,
                    decorationColor: AppColors.authButtonText,
                    decorationStyle: TextDecorationStyle.solid,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (showDivider)
          Container(
            height: 13,
            width: 1,
            color: const Color(0xFF665D58),
            margin: const EdgeInsets.symmetric(horizontal: 24),
          ),
      ],
    );
  }
}
