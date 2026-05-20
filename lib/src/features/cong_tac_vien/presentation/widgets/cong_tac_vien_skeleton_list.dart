import 'package:anholding_app/src/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

class CongTacVienSkeletonList extends StatelessWidget {
  const CongTacVienSkeletonList({super.key, this.itemCount = 5});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        return const _ShimmerAnimator(
          child: CongTacVienSkeletonItem(),
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

class CongTacVienSkeletonItem extends StatelessWidget {
  const CongTacVienSkeletonItem({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.only(left: 21, right: 21, top: 21),
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
          colors: [
            AppColors.dashboardCardStart,
            AppColors.dashboardCardEnd,
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Name & Status ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Container(
                  height: 18,
                  margin: const EdgeInsets.only(right: 32),
                  decoration: BoxDecoration(
                    color: const Color(0xFF645E5A),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 60,
                height: 16,
                decoration: BoxDecoration(
                  color: const Color(0xFF645E5A),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ── Details ──
          ...List.generate(
            3,
            (index) => Container(
              height: 12,
              margin: EdgeInsets.only(
                bottom: index == 2 ? 16 : 8,
                right: index == 0 ? 120 : (index == 1 ? 160 : 180),
              ),
              decoration: BoxDecoration(
                color: const Color(0xFF645E5A),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),

          // ── Footer: Date & Actions ──
          Container(
            padding: const EdgeInsets.only(top: 7, bottom: 6),
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: AppColors.authInputBorder,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 12,
                      height: 13,
                      decoration: BoxDecoration(
                        color: const Color(0xFF645E5A),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 80,
                      height: 10,
                      decoration: BoxDecoration(
                        color: const Color(0xFF645E5A),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Container(
                        width: 15,
                        height: 15,
                        decoration: BoxDecoration(
                          color: const Color(0xFF645E5A),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Container(
                        width: 13,
                        height: 15,
                        decoration: BoxDecoration(
                          color: const Color(0xFF645E5A),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
