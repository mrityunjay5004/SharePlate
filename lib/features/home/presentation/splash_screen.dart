import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_constants.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/services/firebase_bootstrap.dart';
import '../../../core/theme/app_theme.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _openNextScreen();
  }

  Future<void> _openNextScreen() async {
    await Future<void>.delayed(const Duration(milliseconds: 1000));
    final user = await ref.read(authServiceProvider).getCurrentUser();
    if (user != null) {
      try {
        await ref
            .read(notificationServiceProvider)
            .initializeForUser(user.id)
            .timeout(const Duration(seconds: 5));
      } catch (_) {
        // Notification setup should not block signed-in users from opening the app.
      }
    }

    if (!mounted) {
      return;
    }
    Navigator.of(
      context,
    ).pushReplacementNamed(user == null ? AppRoutes.login : AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    final startup = ref.watch(startupResultProvider);

    return Scaffold(
      backgroundColor: AppTheme.creamBackground,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                // Plate & Leaf SharePlate Logo Motif
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryGreen.withAlpha(60),
                        blurRadius: 18,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.restaurant,
                      size: 46,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  AppConstants.appName,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                    color: AppTheme.primaryGreenDark,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.creamAccent,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.creamBorder),
                  ),
                  child: Text(
                    AppConstants.appTagline,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF324D3C),
                    ),
                  ),
                ),
                const SizedBox(height: 36),
                const SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.8,
                    valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryGreen),
                  ),
                ),
                if (startup.mode == FirebaseMode.demo) ...<Widget>[
                  const SizedBox(height: 28),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.creamAccent,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.creamBorder),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Icon(Icons.flash_on, size: 14, color: AppTheme.amberUrgent),
                        SizedBox(width: 6),
                        Text(
                          'Demo mode - Local in-memory testing',
                          style: TextStyle(fontSize: 11, color: Color(0xFF6B5A33)),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
