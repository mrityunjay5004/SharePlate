import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/impact_summary_card.dart';
import '../../../core/widgets/loading_view.dart';
import '../../../core/widgets/status_chip.dart';
import '../../../models/app_user.dart';
import '../../../models/donation.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return Scaffold(
      backgroundColor: AppTheme.creamBackground,
      appBar: AppBar(title: const Text('Admin Platform Overview')),
      body: authState.when(
        loading: () => const LoadingView(message: 'Verifying permissions...'),
        error: (_, __) => const _AdminOnly(),
        data: (user) {
          if (user == null || !user.isAdmin) {
            return const _AdminOnly();
          }
          return const _AdminContent();
        },
      ),
    );
  }
}

class _AdminContent extends ConsumerStatefulWidget {
  const _AdminContent();

  @override
  ConsumerState<_AdminContent> createState() => _AdminContentState();
}

class _AdminContentState extends ConsumerState<_AdminContent> {
  final _searchUserController = TextEditingController();

  @override
  void dispose() {
    _searchUserController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(usersProvider);
    final donationsAsync = ref.watch(allDonationsProvider);

    return RefreshIndicator(
      color: AppTheme.primaryGreen,
      onRefresh: () async {
        ref.invalidate(usersProvider);
        ref.invalidate(allDonationsProvider);
      },
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        children: <Widget>[
          // Overall Food Impact Metrics
          donationsAsync.when(
            loading: () =>
                const LoadingView(message: 'Loading platform impact...'),
            error: (_, __) => const SizedBox.shrink(),
            data: (donations) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                FoodImpactDashboard(
                  donations: donations,
                  title: 'Platform Redistribution Impact',
                ),
                const SizedBox(height: 16),
                _DonationStatusGrid(donations: donations),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // User Management Section
          Row(
            children: <Widget>[
              const Icon(Icons.people_outline, color: AppTheme.primaryGreen, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Registered Accounts',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF14291B),
                ),
              ),
              const Spacer(),
              usersAsync.maybeWhen(
                data: (users) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.creamAccent,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.creamBorder),
                  ),
                  child: Text(
                    '${users.length} Users',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryGreenDark,
                    ),
                  ),
                ),
                orElse: () => const SizedBox.shrink(),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // User Search Bar
          TextField(
            controller: _searchUserController,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Search user name, email, city, or role...',
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: _searchUserController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () => setState(_searchUserController.clear),
                    )
                  : null,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
          ),
          const SizedBox(height: 12),

          usersAsync.when(
            loading: () => const LoadingView(message: 'Loading users...'),
            error: (_, __) => const EmptyState(
              icon: Icons.error_outline,
              title: 'Could not load users',
              message: 'Check Firebase permissions and try again.',
            ),
            data: (users) {
              final query = _searchUserController.text.trim().toLowerCase();
              final filteredUsers = users.where((u) {
                if (query.isEmpty) return true;
                return u.name.toLowerCase().contains(query) ||
                    u.email.toLowerCase().contains(query) ||
                    u.city.toLowerCase().contains(query) ||
                    u.role.label.toLowerCase().contains(query);
              }).toList();

              if (filteredUsers.isEmpty) {
                return const EmptyState(
                  icon: Icons.search_off,
                  title: 'No users found',
                  message: 'Try a different search term.',
                );
              }

              return Column(
                children: filteredUsers.map((user) => _UserCard(user: user)).toList(),
              );
            },
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _DonationStatusGrid extends StatelessWidget {
  const _DonationStatusGrid({required this.donations});

  final List<Donation> donations;

  @override
  Widget build(BuildContext context) {
    final available = donations
        .where((d) => d.status == DonationStatus.pending)
        .length;
    final requested = donations
        .where((d) => d.status == DonationStatus.requested)
        .length;
    final accepted = donations
        .where((d) => d.status == DonationStatus.accepted)
        .length;
    final pickedUp = donations
        .where((d) => d.status == DonationStatus.pickedUp)
        .length;
    final completed = donations
        .where((d) => d.status == DonationStatus.completed)
        .length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.creamBorder, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'Redistribution Status Breakdown',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF14291B),
            ),
          ),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: MediaQuery.sizeOf(context).width > 600 ? 5 : 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 1.3,
            children: <Widget>[
              _StatusStatTile(
                label: 'Available',
                count: available.toString(),
                status: DonationStatus.pending,
              ),
              _StatusStatTile(
                label: 'Requested',
                count: requested.toString(),
                status: DonationStatus.requested,
              ),
              _StatusStatTile(
                label: 'Accepted',
                count: accepted.toString(),
                status: DonationStatus.accepted,
              ),
              _StatusStatTile(
                label: 'In Transit',
                count: pickedUp.toString(),
                status: DonationStatus.pickedUp,
              ),
              _StatusStatTile(
                label: 'Completed',
                count: completed.toString(),
                status: DonationStatus.completed,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusStatTile extends StatelessWidget {
  const _StatusStatTile({
    required this.label,
    required this.count,
    required this.status,
  });

  final String label;
  final String count;
  final DonationStatus status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppTheme.creamBackground,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.creamBorder),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text(
            count,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF14291B),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
          ),
        ],
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  const _UserCard({required this.user});

  final AppUser user;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.creamBorder),
      ),
      child: Row(
        children: <Widget>[
          CircleAvatar(
            radius: 20,
            backgroundColor: AppTheme.creamAccent,
            child: Text(
              user.name.isEmpty ? '?' : user.name[0].toUpperCase(),
              style: const TextStyle(
                color: AppTheme.primaryGreenDark,
                fontWeight: FontWeight.bold,
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
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                Text(
                  '${user.email} • ${user.city}',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: user.isAdmin
                  ? const Color(0xFFFEF3C7)
                  : (user.isCharity
                      ? const Color(0xFFE0F2FE)
                      : AppTheme.primaryGreenContainer),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              user.role.label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: user.isAdmin
                    ? const Color(0xFF92400E)
                    : (user.isCharity
                        ? const Color(0xFF0369A1)
                        : AppTheme.onPrimaryGreenContainer),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminOnly extends StatelessWidget {
  const _AdminOnly();

  @override
  Widget build(BuildContext context) {
    return const EmptyState(
      icon: Icons.admin_panel_settings_outlined,
      title: 'Administrator access only',
      message: 'Sign in with an admin account to view platform metrics and users.',
    );
  }
}
