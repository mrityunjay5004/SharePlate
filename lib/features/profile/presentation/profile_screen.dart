import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_constants.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/services/firebase_bootstrap.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/impact_summary_card.dart';
import '../../../core/widgets/loading_view.dart';
import '../../../core/widgets/text_info_row.dart';
import '../../../models/donation.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final startup = ref.watch(startupResultProvider);

    return Scaffold(
      backgroundColor: AppTheme.creamBackground,
      appBar: AppBar(title: const Text('Profile & Personal Dashboard')),
      body: authState.when(
        loading: () => const LoadingView(message: 'Loading profile...'),
        error: (_, __) => const _NoProfile(),
        data: (user) {
          if (user == null) {
            return const _NoProfile();
          }

          final userDonationsAsync = ref.watch(userDonationsProvider(user.id));

          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            children: <Widget>[
              // Profile Header Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.creamBorder, width: 1.2),
                ),
                child: Column(
                  children: <Widget>[
                    CircleAvatar(
                      radius: 36,
                      backgroundColor: AppTheme.primaryGreenContainer,
                      child: Text(
                        user.name.isEmpty ? '?' : user.name[0].toUpperCase(),
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.onPrimaryGreenContainer,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      user.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF14291B),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppTheme.creamAccent,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.creamBorder),
                      ),
                      child: Text(
                        '${user.role.label} Account',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryGreenDark,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Personal Food Impact Card
              userDonationsAsync.maybeWhen(
                data: (donations) {
                  return Column(
                    children: <Widget>[
                      FoodImpactDashboard(
                        donations: donations,
                        title: 'My Personal Food Sharing Impact',
                        isPersonal: true,
                      ),
                      const SizedBox(height: 16),
                    ],
                  );
                },
                orElse: () => const SizedBox.shrink(),
              ),

              // Account Information Card
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.creamBorder, width: 1.2),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Row(
                      children: <Widget>[
                        Icon(Icons.badge_outlined, size: 16, color: AppTheme.primaryGreen),
                        SizedBox(width: 8),
                        Text(
                          'Account Details',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1B2E21),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextInfoRow(
                      label: 'Email',
                      value: user.email,
                      icon: Icons.email_outlined,
                    ),
                    TextInfoRow(
                      label: 'City',
                      value: user.city,
                      icon: Icons.location_city_outlined,
                    ),
                    TextInfoRow(
                      label: 'Phone',
                      value: user.phone?.isNotEmpty == true
                          ? user.phone!
                          : 'Not provided',
                      icon: Icons.phone_outlined,
                    ),
                    TextInfoRow(
                      label: 'Backend Engine',
                      value: startup.mode == FirebaseMode.firebase
                          ? 'Firebase Production Cloud'
                          : 'Demo Local Service',
                      icon: Icons.cloud_outlined,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Sign Out Button
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.redCritical,
                  side: const BorderSide(color: AppTheme.redCritical, width: 1.2),
                  minimumSize: const Size.fromHeight(48),
                ),
                onPressed: () async {
                  await ref.read(authServiceProvider).signOut();
                  if (context.mounted) {
                    Navigator.of(context).pushNamedAndRemoveUntil(
                      AppRoutes.login,
                      (route) => false,
                    );
                  }
                },
                icon: const Icon(Icons.logout),
                label: const Text('Sign Out from SharePlate'),
              ),
              const SizedBox(height: 32),
            ],
          );
        },
      ),
    );
  }
}

class _NoProfile extends StatelessWidget {
  const _NoProfile();

  @override
  Widget build(BuildContext context) {
    return const EmptyState(
      icon: Icons.person_off_outlined,
      title: 'Profile unavailable',
      message: 'Please sign in to view your profile and personal activity.',
    );
  }
}
