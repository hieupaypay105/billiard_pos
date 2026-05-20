import 'dart:async';

import 'package:flutter/material.dart';

class NotificationSkeletonList extends StatelessWidget {
  const NotificationSkeletonList({
    super.key,
    this.itemCount = 5,
  });

  /// Số lượng skeleton item muốn hiển thị
  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: itemCount,
      itemBuilder: (context, index) {
        return const _ShimmerAnimator(
          child: NotificationSkeletonItem(),
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
    );
    unawaited(_controller.repeat());
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
        // Animate the gradient from left to right (-1.0 to 2.0 covers the sweeping path)
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

class NotificationSkeletonItem extends StatelessWidget {
  const NotificationSkeletonItem({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.transparent,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar Skeleton
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              color: Color(0xFF645E5A),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Title skeleton
                    Container(
                      width: 140,
                      height: 14,
                      decoration: BoxDecoration(
                        color: const Color(0xFF645E5A),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    // Time skeleton
                    Container(
                      width: 60,
                      height: 10,
                      decoration: BoxDecoration(
                        color: const Color(0xFF645E5A),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Content line 1 skeleton
                Container(
                  width: double.infinity,
                  height: 12,
                  decoration: BoxDecoration(
                    color: const Color(0xFF645E5A),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 4),
                // Content line 2 skeleton
                Container(
                  width: 200,
                  height: 12,
                  decoration: BoxDecoration(
                    color: const Color(0xFF645E5A),
                    borderRadius: BorderRadius.circular(4),
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
