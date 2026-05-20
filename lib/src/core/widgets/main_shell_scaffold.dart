import 'package:anholding_app/src/core/widgets/floating_bottom_bar.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Shell scaffold that overlays a [FloatingBottomBar] on all child routes.
///
/// Uses a fade animation when switching between tabs without disposing
/// the [StatefulNavigationShell] state.
class MainShellScaffold extends StatefulWidget {
  const MainShellScaffold({
    required this.navigationShell,
    super.key,
  });

  final StatefulNavigationShell navigationShell;

  @override
  State<MainShellScaffold> createState() => _MainShellScaffoldState();
}

class _MainShellScaffoldState extends State<MainShellScaffold>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  int _previousIndex = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
      value: 1, // start fully visible
    );
    _previousIndex = widget.navigationShell.currentIndex;
  }

  @override
  void didUpdateWidget(covariant MainShellScaffold oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.navigationShell.currentIndex != _previousIndex) {
      _previousIndex = widget.navigationShell.currentIndex;
      // Instantly hide, then fade in the new tab content
      _controller.value = 0.0;
      // ignore: discarded_futures, fire-and-forget animation
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Child route content — fades when switching tabs
          FadeTransition(
            opacity: CurvedAnimation(
              parent: _controller,
              curve: Curves.easeInOut,
            ),
            child: widget.navigationShell,
          ),

          // Bottom navigation bar overlay — full width anchored to bottom
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FloatingBottomBar(
                  currentIndex: widget.navigationShell.currentIndex,
                  onTabChanged: (index) => widget.navigationShell.goBranch(
                    index,
                    initialLocation:
                        index == widget.navigationShell.currentIndex,
                  ),
                ),
                // // To support safe area padding safely inside the visual blur:
                // // We'll let bottom nav bar handle its height, but actually we need bottom safe area below or inside it.
                // // The easiest is just a Container with system padding height if safe area is outside
                // Container(
                //   height: bottomPadding,
                //   color: AppColors.topBarBackground,
                // ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
