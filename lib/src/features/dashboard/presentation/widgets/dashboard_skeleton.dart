import 'dart:ui';

import 'package:anholding_app/src/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

/// Skeleton loading layout for the dashboard screen.
class DashboardSkeleton extends StatelessWidget {
  const DashboardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const Stack(
      children: [
        SingleChildScrollView(
          physics: NeverScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(0, 88, 0, 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: 40),
              _GreetingSectionSkeleton(),
              SizedBox(height: 32),
              _NotificationSectionSkeleton(),
            ],
          ),
        ),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: _TopBarSkeleton(),
        ),
      ],
    );
  }
}

class DashboardShimmer extends StatefulWidget {
  const DashboardShimmer({required this.child, super.key});
  final Widget child;

  @override
  State<DashboardShimmer> createState() => _DashboardShimmerState();
}

class _DashboardShimmerState extends State<DashboardShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final x = -1.0 + (_controller.value * 3.0);
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              colors: const [
                Color(0xFF3B3537),
                Color(0xFF4B4547),
                Color(0xFF3B3537),
              ],
              stops: const [0.1, 0.5, 0.9],
              begin: Alignment(x - 1.0, -0.3),
              end: Alignment(x + 1.0, 0.3),
            ).createShader(bounds);
          },
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

class SkeletonBox extends StatelessWidget {
  const SkeletonBox({
    required this.width,
    required this.height,
    this.radius = 12,
    super.key,
  });

  final double width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Container(
        width: width,
        height: height,
        color: const Color(0xFF645E5A),
      ),
    );
  }
}

class NotificationItemSkeleton extends StatelessWidget {
  const NotificationItemSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.dashboardCardStart,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.dashboardCardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: Color(0xFF645E5A),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              const SkeletonBox(width: 100, height: 10, radius: 4),
            ],
          ),
          const SizedBox(height: 16),
          const SkeletonBox(width: double.infinity, height: 14, radius: 4),
          const SizedBox(height: 8),
          const SkeletonBox(width: 200, height: 14, radius: 4),
        ],
      ),
    );
  }
}

class _TopBarSkeleton extends StatelessWidget {
  const _TopBarSkeleton();

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
        child: Container(
          decoration: const BoxDecoration(
            color: AppColors.topBarBlurBackground,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 72,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                child: const DashboardShimmer(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          SkeletonBox(width: 40, height: 40),
                          SizedBox(width: 16),
                          SkeletonBox(width: 120, height: 20, radius: 6),
                        ],
                      ),
                      SkeletonBox(width: 24, height: 24),
                    ],
                  ),
                ),
              ),
              Container(
                height: 1,
                width: double.infinity,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    stops: [0.0885, 0.5097, 0.9559],
                    colors: [
                      Color(0xFFFFDBB0),
                      Color(0xFF9C531B),
                      Color(0xFFFFDBB0),
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
}

class _GreetingSectionSkeleton extends StatelessWidget {
  const _GreetingSectionSkeleton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const DashboardShimmer(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonBox(width: 140, height: 12, radius: 4),
                SizedBox(height: 12),
                SkeletonBox(width: 100, height: 20, radius: 4),
                SizedBox(height: 8),
                SkeletonBox(width: 180, height: 24, radius: 6),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            height: 80,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.dashboardCardBorder),
              gradient: const LinearGradient(
                colors: [
                  AppColors.dashboardCardStart,
                  AppColors.dashboardCardEnd,
                ],
                transform: GradientRotation(138.654 * 3.14159 / 180),
              ),
            ),
            child: DashboardShimmer(
              child: Row(
                children: [
                  const Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        SkeletonBox(width: 80, height: 8, radius: 4),
                        SizedBox(height: 8),
                        SkeletonBox(width: 100, height: 12, radius: 4),
                      ],
                    ),
                  ),
                  const SizedBox(width: 24),
                  Container(
                    width: 1,
                    height: 32,
                    color: Colors.white.withOpacity(0.3),
                  ),
                  const SizedBox(width: 24),
                  const Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        SkeletonBox(width: 80, height: 8, radius: 4),
                        SizedBox(height: 8),
                        SkeletonBox(width: 60, height: 12, radius: 4),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationSectionSkeleton extends StatelessWidget {
  const _NotificationSectionSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 24),
          child: DashboardShimmer(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SkeletonBox(width: 100, height: 16, radius: 4),
                SkeletonBox(width: 80, height: 14, radius: 4),
              ],
            ),
          ),
        ),
        SizedBox(height: 16),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 24),
          child: DashboardShimmer(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: NotificationItemSkeleton(),
                ),
                Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: NotificationItemSkeleton(),
                ),
                Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: NotificationItemSkeleton(),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
