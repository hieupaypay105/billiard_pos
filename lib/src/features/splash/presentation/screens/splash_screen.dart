import 'dart:async';

import 'package:anholding_app/src/core/paths/route_paths.dart';
import 'package:anholding_app/src/core/storage/pin_storage.dart';
import 'package:anholding_app/src/features/auth/presentation/provider/user_provider.dart';
import 'package:anholding_app/src/features/auth/presentation/widgets/auth_background_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    unawaited(_navigateAfterSplash());
  }

  Future<void> _navigateAfterSplash() async {
    // Show splash for at least 2 seconds
    await Future<void>.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    final pinStorage = context.read<PinStorage>();
    final hasPin = await pinStorage.hasPin();

    if (!mounted) return;

    final userProvider = context.read<UserProvider>();
    await userProvider.loadUser();

    if (!mounted) return;

    if (hasPin && userProvider.isLoggedIn) {
      context.go(RoutePaths.pinLogin);
    } else {
      context.go(RoutePaths.phoneLogin);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthBackgroundWidget(
      child: Center(
        child: SvgPicture.asset(
          'assets/images/logo.svg',
          width: 203,
          height: 72,
        ),
      ),
    );
  }
}
