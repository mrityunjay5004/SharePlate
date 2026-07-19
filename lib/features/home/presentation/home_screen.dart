import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_constants.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/date_formatters.dart';
import '../../../core/widgets/category_chip.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/impact_summary_card.dart';
import '../../../core/widgets/loading_view.dart';
import '../../../core/widgets/status_chip.dart';
import '../../../core/widgets/urgency_badge.dart';
import '../../../models/app_user.dart';
import '../../../models/donation.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return authState.when(
      loading: () =>
          const Scaffold(body: LoadingView(message: 'Opening SharePlate...')),
      error: (_, __) => const _SignedOutView(),
      data: (user) {
        if (user == null) {
          return const _SignedOutView();
        }
        return _Dashboard(user: user);
      },
    );
  }
}

class _Dashboard extends ConsumerWidget {
  const _Dashboard({required this.user});

  final AppUser user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final donationsAsync = ref.watch(allDonationsProvider);
    final userDonationsAsync = ref.watch(userDonationsProvider(user.id));
    final notificationsAsync = ref.watch(userNotificationsProvider(user.id));

    return Scaffold(
      backgroundColor: AppTheme.creamBackground,
      appBar: AppBar(
        title: Row(
          children: <Widget>[
            Container(
              padding: const EdgeInsets.all(5),
              decoration: const BoxDecoration(
                color: AppTheme.primaryGreen,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.restaurant, color: Colors.white, size: 16),
            ),
            const SizedBox(width: 8),
            const Text(AppConstants.appName),
          ],
        ),
        actions: <Widget>[
          IconButton(
            tooltip: 'Notifications',
            onPressed: () =>
                Navigator.of(context).pushNamed(AppRoutes.notifications),
            icon: const Icon(Icons.notifications_outlined),
          ),
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 12),
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => Navigator.of(context).pushNamed(AppRoutes.profile),
              child: CircleAvatar(
                radius: 17,
                backgroundColor: AppTheme.primaryGreen,
                child: Text(
                  _initialFor(user.name),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      drawer: _AppDrawer(user: user),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppTheme.primaryGreen,
          onRefresh: () async {
            ref.invalidate(allDonationsProvider);
            ref.invalidate(userDonationsProvider(user.id));
            ref.invalidate(userNotificationsProvider(user.id));
          },
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            children: <Widget>[
              _WelcomeHeader(user: user),
              const SizedBox(height: 16),

              // Urgent Expiry Warning Banner
              donationsAsync.maybeWhen(
                data: (donations) {
                  final urgentDonations = donations
                      .where((d) => d.isAvailable && d.isExpiringToday)
                      .toList();
                  if (urgentDonations.isEmpty) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _UrgentRescueBanner(urgentCount: urgentDonations.length),
                  );
                },
                orElse: () => const SizedBox.shrink(),
              ),

              // Food Impact Dashboard
              donationsAsync.when(
                loading: () =>
                    const LoadingView(message: 'Calculating food impact...'),
                error: (_, __) => const SizedBox.shrink(),
                data: (donations) => FoodImpactDashboard(
                  donations: donations,
                  title: user.isDonor ? 'Community Food Impact' : 'Redistribution Impact',
                ),
              ),

              const SizedBox(height: 18),

              // Personal Activity Stats for Donors / Charities
              if (user.isDonor)
                userDonationsAsync.maybeWhen(
                  data: (userDonations) => _PersonalActivitySummary(
                    donations: userDonations,
                    user: user,
                  ),
                  orElse: () => const SizedBox.shrink(),
                )
              else if (user.isCharity)
                donationsAsync.maybeWhen(
                  data: (allDonations) {
                    final charityAccepted = allDonations
                        .where((d) => d.acceptedByCharityId == user.id)
                        .toList();
                    return _CharityActivitySummary(
                      acceptedDonations: charityAccepted,
                      allDonations: allDonations,
                    );
                  },
                  orElse: () => const SizedBox.shrink(),
                ),

              const SizedBox(height: 16),

              // Donor Primary Call to Action
              if (user.isDonor) ...<Widget>[
                const _PrimaryDonationCta(),
                const SizedBox(height: 16),
              ],

              // Quick Actions Grid
              _ActionGrid(user: user),

              const SizedBox(height: 24),

              // Role-Specific Section
              if (user.isCharity)
                _CharityPriorityList(user: user)
              else if (user.isDonor)
                _DonorRecentList(user: user)
              else
                _AdminQuickSummary(user: user),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _WelcomeHeader extends StatelessWidget {
  const _WelcomeHeader({required this.user});

  final AppUser user;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.creamBorder, width: 1.2),
      ),
      child: Row(
        children: <Widget>[
          CircleAvatar(
            radius: 26,
            backgroundColor: AppTheme.primaryGreenContainer,
            child: Text(
              _initialFor(user.name),
              style: const TextStyle(
                color: AppTheme.onPrimaryGreenContainer,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Hello, ${user.name}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1B2E21),
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: <Widget>[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.creamAccent,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        user.role.label,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryGreenDark,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(Icons.location_on, size: 13, color: Colors.grey.shade600),
                    Text(
                      user.city,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w500,
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

class _UrgentRescueBanner extends StatelessWidget {
  const _UrgentRescueBanner({required this.urgentCount});

  final int urgentCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.amberUrgentBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.amberUrgent.withAlpha(80), width: 1.2),
      ),
      child: Row(
        children: <Widget>[
          const Icon(Icons.alarm_on, color: AppTheme.amberUrgent, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  '$urgentCount food donation${urgentCount > 1 ? 's' : ''} expiring today!',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF854D0E),
                  ),
                ),
                const Text(
                  'Redistribute quickly to prevent edible food from going to waste.',
                  style: TextStyle(fontSize: 11, color: Color(0xFF713F12)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: () => Navigator.of(context).pushNamed(AppRoutes.donations),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF854D0E),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              visualDensity: VisualDensity.compact,
            ),
            child: const Text('View', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

class _PersonalActivitySummary extends StatelessWidget {
  const _PersonalActivitySummary({
    required this.donations,
    required this.user,
  });

  final List<Donation> donations;
  final AppUser user;

  @override
  Widget build(BuildContext context) {
    final available = donations
        .where((d) => d.status == DonationStatus.pending || d.status == DonationStatus.requested)
        .length;
    final accepted = donations
        .where((d) => d.status == DonationStatus.accepted || d.status == DonationStatus.pickedUp)
        .length;
    final completed = donations
        .where((d) => d.status == DonationStatus.completed)
        .length;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.creamBorder, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Row(
            children: <Widget>[
              Icon(Icons.dashboard_outlined, size: 16, color: AppTheme.primaryGreen),
              SizedBox(width: 6),
              Text(
                'My Food Sharing Dashboard',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1B2E21),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              Expanded(
                child: _PersonalStatCard(
                  title: 'Created',
                  count: donations.length.toString(),
                  icon: Icons.inventory_2_outlined,
                  color: const Color(0xFF1B5E3C),
                  bg: AppTheme.primaryGreenContainer,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _PersonalStatCard(
                  title: 'Active',
                  count: (available + accepted).toString(),
                  icon: Icons.hourglass_top,
                  color: AppTheme.amberUrgent,
                  bg: AppTheme.amberUrgentBg,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _PersonalStatCard(
                  title: 'Completed',
                  count: completed.toString(),
                  icon: Icons.task_alt,
                  color: const Color(0xFF0369A1),
                  bg: const Color(0xFFE0F2FE),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CharityActivitySummary extends StatelessWidget {
  const _CharityActivitySummary({
    required this.acceptedDonations,
    required this.allDonations,
  });

  final List<Donation> acceptedDonations;
  final List<Donation> allDonations;

  @override
  Widget build(BuildContext context) {
    final pendingPickup = acceptedDonations
        .where((d) => d.status == DonationStatus.accepted || d.status == DonationStatus.pickedUp)
        .length;
    final completed = acceptedDonations
        .where((d) => d.status == DonationStatus.completed)
        .length;
    final availableNearby = allDonations
        .where((d) => d.isAvailable)
        .length;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.creamBorder, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Row(
            children: <Widget>[
              Icon(Icons.diversity_1_outlined, size: 16, color: AppTheme.primaryGreen),
              SizedBox(width: 6),
              Text(
                'Charity Rescue Overview',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1B2E21),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              Expanded(
                child: _PersonalStatCard(
                  title: 'Available',
                  count: availableNearby.toString(),
                  icon: Icons.storefront_outlined,
                  color: AppTheme.primaryGreen,
                  bg: AppTheme.primaryGreenContainer,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _PersonalStatCard(
                  title: 'In Progress',
                  count: pendingPickup.toString(),
                  icon: Icons.local_shipping_outlined,
                  color: AppTheme.amberUrgent,
                  bg: AppTheme.amberUrgentBg,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _PersonalStatCard(
                  title: 'Rescued',
                  count: completed.toString(),
                  icon: Icons.verified_outlined,
                  color: const Color(0xFF0369A1),
                  bg: const Color(0xFFE0F2FE),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PersonalStatCard extends StatelessWidget {
  const _PersonalStatCard({
    required this.title,
    required this.count,
    required this.icon,
    required this.color,
    required this.bg,
  });

  final String title;
  final String count;
  final IconData icon;
  final Color color;
  final Color bg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: bg.withAlpha(120),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withAlpha(40)),
      ),
      child: Column(
        children: <Widget>[
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 4),
          Text(
            count,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color.withAlpha(220),
            ),
          ),
        ],
      ),
    );
  }
}

class _PrimaryDonationCta extends StatelessWidget {
  const _PrimaryDonationCta();

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        elevation: 1,
      ),
      onPressed: () => Navigator.of(context).pushNamed(AppRoutes.addDonation),
      icon: const Icon(Icons.add_circle_outline, size: 20),
      label: const Text(
        'Share Surplus Food',
        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _ActionGrid extends StatelessWidget {
  const _ActionGrid({required this.user});

  final AppUser user;

  @override
  Widget build(BuildContext context) {
    final actions = <_DashboardAction>[
      const _DashboardAction(
        'Browse Food',
        Icons.search,
        AppRoutes.donations,
        'Discover surplus',
      ),
      const _DashboardAction(
        'FAQ Bot',
        Icons.chat_bubble_outline,
        AppRoutes.chatbot,
        'Ask questions',
      ),
      const _DashboardAction(
        'Map View',
        Icons.map_outlined,
        AppRoutes.map,
        'Nearby pins',
      ),
      const _DashboardAction(
        'Profile',
        Icons.person_outline,
        AppRoutes.profile,
        'Settings & info',
      ),
      if (user.isAdmin)
        const _DashboardAction(
          'Admin Panel',
          Icons.admin_panel_settings_outlined,
          AppRoutes.admin,
          'Platform stats',
        ),
    ];

    return GridView.builder(
      itemCount: actions.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: MediaQuery.sizeOf(context).width > 600 ? 4 : 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 2.3,
      ),
      itemBuilder: (context, index) {
        final action = actions[index];
        return Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => Navigator.of(context).pushNamed(action.route),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.creamBorder, width: 1.2),
              ),
              child: Row(
                children: <Widget>[
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: AppTheme.creamAccent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(action.icon, color: AppTheme.primaryGreenDark, size: 18),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          action.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: Color(0xFF1B2E21),
                          ),
                        ),
                        Text(
                          action.subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CharityPriorityList extends ConsumerWidget {
  const _CharityPriorityList({required this.user});

  final AppUser user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final donationsAsync = ref.watch(allDonationsProvider);
    final matchingService = ref.watch(matchingServiceProvider);

    return donationsAsync.when(
      loading: () => const LoadingView(message: 'Prioritizing donations...'),
      error: (_, __) => const SizedBox.shrink(),
      data: (donations) {
        final nearby = donations
            .where(
              (donation) =>
                  donation.city.toLowerCase().contains(user.city.toLowerCase()),
            )
            .toList();
        final ranked = matchingService.rankDonations(nearby).take(3).toList();
        if (ranked.isEmpty) {
          return const EmptyState(
            icon: Icons.search_off_outlined,
            title: 'No pending donations nearby',
            message: 'Check all cities or check back soon as donors add food.',
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                const Icon(Icons.flash_on, color: AppTheme.primaryGreen, size: 18),
                const SizedBox(width: 6),
                Text(
                  'Highest Urgency Near ${user.city}',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1B2E21),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            for (final result in ranked) ...<Widget>[
              _DonationCardPreview(
                donation: result.donation,
                score: result.score,
              ),
              const SizedBox(height: 10),
            ],
          ],
        );
      },
    );
  }
}

class _DonorRecentList extends ConsumerWidget {
  const _DonorRecentList({required this.user});

  final AppUser user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final donationsAsync = ref.watch(userDonationsProvider(user.id));

    return donationsAsync.when(
      loading: () => const LoadingView(message: 'Loading recent donations...'),
      error: (_, __) => const SizedBox.shrink(),
      data: (donations) {
        if (donations.isEmpty) {
          return const EmptyState(
            icon: Icons.add_box_outlined,
            title: 'No donations posted yet',
            message: 'Tap "Share Surplus Food" above to post your first donation.',
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Row(
              children: <Widget>[
                Icon(Icons.history_outlined, color: AppTheme.primaryGreen, size: 18),
                SizedBox(width: 6),
                Text(
                  'Your Recent Food Donations',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1B2E21),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            for (final donation in donations.take(3)) ...<Widget>[
              _DonationCardPreview(donation: donation),
              const SizedBox(height: 10),
            ],
          ],
        );
      },
    );
  }
}

class _AdminQuickSummary extends StatelessWidget {
  const _AdminQuickSummary({required this.user});

  final AppUser user;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.creamBorder, width: 1.2),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.creamAccent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.admin_panel_settings_outlined, color: AppTheme.primaryGreen),
        ),
        title: const Text('Admin Operations', style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: const Text('Review users, monitor redistribution metrics, and system logs.'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.of(context).pushNamed(AppRoutes.admin),
      ),
    );
  }
}

class _DonationCardPreview extends StatelessWidget {
  const _DonationCardPreview({required this.donation, this.score});

  final Donation donation;
  final int? score;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => Navigator.of(context).pushNamed(
          AppRoutes.donationDetails,
          arguments: donation,
        ),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.creamBorder, width: 1.2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          donation.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1B2E21),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: <Widget>[
                            CategoryChip(category: donation.category),
                            const SizedBox(width: 6),
                            StatusChip(status: donation.status),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  UrgencyBadge(expiryDate: donation.expiryDate, compact: true),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                donation.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade700, height: 1.3),
              ),
              const SizedBox(height: 10),
              Divider(height: 1, color: AppTheme.creamBorder.withAlpha(140)),
              const SizedBox(height: 8),
              Row(
                children: <Widget>[
                  Icon(Icons.scale, size: 14, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(
                    '${donation.quantity} ${donation.unit}',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(width: 14),
                  Icon(Icons.location_on_outlined, size: 14, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(
                    donation.city,
                    style: const TextStyle(fontSize: 12),
                  ),
                  if (score != null) ...<Widget>[
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryGreenContainer,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Priority $score%',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.onPrimaryGreenContainer,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AppDrawer extends ConsumerWidget {
  const _AppDrawer({required this.user});

  final AppUser user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Drawer(
      backgroundColor: Colors.white,
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            Container(
              padding: const EdgeInsets.all(18),
              decoration: const BoxDecoration(
                color: AppTheme.primaryGreen,
              ),
              child: Row(
                children: <Widget>[
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: Colors.white,
                    child: Text(
                      _initialFor(user.name),
                      style: const TextStyle(
                        color: AppTheme.primaryGreen,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          user.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          '${user.role.label} • ${user.city}',
                          style: TextStyle(
                            color: Colors.white.withAlpha(210),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            _DrawerItem(
              label: 'Home Dashboard',
              icon: Icons.dashboard_outlined,
              route: AppRoutes.home,
            ),
            if (user.isDonor)
              _DrawerItem(
                label: 'Share Food (New Donation)',
                icon: Icons.add_circle_outline,
                route: AppRoutes.addDonation,
              ),
            _DrawerItem(
              label: 'Browse Surplus Donations',
              icon: Icons.format_list_bulleted,
              route: AppRoutes.donations,
            ),
            _DrawerItem(
              label: 'Notifications',
              icon: Icons.notifications_outlined,
              route: AppRoutes.notifications,
            ),
            _DrawerItem(
              label: 'Smart Assistant',
              icon: Icons.chat_bubble_outline,
              route: AppRoutes.chatbot,
            ),
            _DrawerItem(
              label: 'Map Explorer',
              icon: Icons.map_outlined,
              route: AppRoutes.map,
            ),
            _DrawerItem(
              label: 'Profile & Activity',
              icon: Icons.person_outline,
              route: AppRoutes.profile,
            ),
            if (user.isAdmin)
              _DrawerItem(
                label: 'Admin Operations',
                icon: Icons.admin_panel_settings_outlined,
                route: AppRoutes.admin,
              ),
          ],
        ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  const _DrawerItem({
    required this.label,
    required this.icon,
    required this.route,
  });

  final String label;
  final IconData icon;
  final String route;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.primaryGreenDark),
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
      onTap: () {
        Navigator.of(context).pop();
        Navigator.of(context).pushNamed(route);
      },
    );
  }
}

class _SignedOutView extends StatelessWidget {
  const _SignedOutView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.creamBackground,
      body: const EmptyState(
        icon: Icons.lock_outline,
        title: 'Sign in to SharePlate',
        message: 'Please sign in to manage surplus food donations and connect with local charities.',
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(20),
        child: FilledButton.icon(
          onPressed: () =>
              Navigator.of(context).pushReplacementNamed(AppRoutes.login),
          icon: const Icon(Icons.login),
          label: const Text('Go to Login'),
        ),
      ),
    );
  }
}

class _DashboardAction {
  const _DashboardAction(this.label, this.icon, this.route, this.subtitle);

  final String label;
  final IconData icon;
  final String route;
  final String subtitle;
}

String _initialFor(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) {
    return '?';
  }
  return trimmed.substring(0, 1).toUpperCase();
}
