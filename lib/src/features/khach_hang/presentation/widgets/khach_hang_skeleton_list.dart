import 'package:anholding_app/src/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

class KhachHangSkeletonList extends StatelessWidget {
  const KhachHangSkeletonList({super.key, this.itemCount = 5});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        return const _ShimmerAnimator(
          child: KhachHangSkeletonItem(),
        );
      },
    );
  }
}

class _ShimmerAnimator extends StatefulWidget {
  const _ShimmerAnimator({required this.child});
  final Widget child;

  @override
  State<_ShimmerAnimator> createState() => _ShimmerAnimatorState();
}

class _ShimmerAnimatorState extends State<_ShimmerAnimator>
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

class KhachHangSkeletonItem extends StatelessWidget {
  const KhachHangSkeletonItem({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(21, 21, 21, 0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.dashboardCardBorder,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000), // 5% black
            blurRadius: 2,
            offset: Offset(0, 1),
          ),
        ],
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: [0.0606, 0.9648],
          transform: GradientRotation(117.868 * 3.1415927 / 180),
          colors: [
            AppColors.cardGradientStart,
            AppColors.cardGradientEnd,
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Container(
                  height: 20,
                  margin: const EdgeInsets.only(right: 32),
                  decoration: BoxDecoration(
                    color: const Color(0xFF645E5A),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 80,
                height: 16,
                decoration: BoxDecoration(
                  color: const Color(0xFF645E5A),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // ── Divider ──
          Container(
            height: 1,
            color: AppColors.authInputBorder,
          ),
          const SizedBox(height: 8),

          // ── Phone & Contact ──
          Row(
            children: [
              Container(
                width: 140, // Phone + Icon equivalent
                height: 14,
                decoration: BoxDecoration(
                  color: const Color(0xFF645E5A),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  height: 16, // Contact tag equivalent
                  decoration: BoxDecoration(
                    color: const Color(0xFF645E5A),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // ── Divider ──
          Container(
            height: 1,
            color: AppColors.authInputBorder,
          ),
          const SizedBox(height: 6),

          // ── Details ──
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 12,
                  decoration: BoxDecoration(
                    color: const Color(0xFF645E5A),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  height: 12,
                  decoration: BoxDecoration(
                    color: const Color(0xFF645E5A),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: Container(
                  height: 12,
                  decoration: BoxDecoration(
                    color: const Color(0xFF645E5A),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ── Actions Footer ──
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: AppColors.authInputBorder),
              ),
            ),
            child: Row(
              children: [
                // _ActionButton skeleton
                Container(
                  width: 60,
                  height: 24,
                  decoration: BoxDecoration(
                    color: const Color(0xFF645E5A),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(width: 8),
                // _ActionButton skeleton
                Container(
                  width: 80,
                  height: 24,
                  decoration: BoxDecoration(
                    color: const Color(0xFF645E5A),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const Spacer(),
                // _IconActionButton
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: const Color(0xFF645E5A),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(width: 4),
                // _IconActionButton
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: const Color(0xFF645E5A),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
