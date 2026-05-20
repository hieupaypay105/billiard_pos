import 'package:anholding_app/src/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

/// Full-screen background with image.
///
/// Wraps every auth screen. Pass the screen content as [child].
class AuthBackgroundWidget extends StatelessWidget {
  const AuthBackgroundWidget({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      // Use a Stack without any Positioned, just filling the background
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── App Background Image ──────────────────────────────
          Opacity(
            opacity: 1,
            child: Image.asset(
              'assets/images/bg-texture.png',
              fit: BoxFit.cover,
            ),
          ),

          // ── Actual content ────────────────────────────────
          SafeArea(child: child),
        ],
      ),
    );
  }
}
