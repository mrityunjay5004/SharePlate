import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_constants.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/category_chip.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/loading_view.dart';
import '../../../core/widgets/status_chip.dart';
import '../../../core/widgets/urgency_badge.dart';
import '../../../models/app_user.dart';
import '../../../models/donation.dart';

class DonationListScreen extends ConsumerStatefulWidget {
  const DonationListScreen({super.key});

  @override
  ConsumerState<DonationListScreen> createState() => _DonationListScreenState();
}

class _DonationListScreenState extends ConsumerState<DonationListScreen> {
  final _searchController = TextEditingController();
  final _cityController = TextEditingController();
  String? _selectedCategory;
  UrgencyFilter _selectedUrgency = UrgencyFilter.all;
  DonationStatus? _selectedStatus;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => setState(() {}));
    _cityController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _cityController.clear();
      _selectedCategory = null;
      _selectedUrgency = UrgencyFilter.all;
      _selectedStatus = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);

    return Scaffold(
      backgroundColor: AppTheme.creamBackground,
      appBar: AppBar(
        title: const Text('Surplus Food Donations'),
        actions: <Widget>[
          if (_hasActiveFilters)
            IconButton(
              tooltip: 'Reset Filters',
              icon: const Icon(Icons.filter_alt_off_outlined),
              onPressed: _clearFilters,
            ),
        ],
      ),
      floatingActionButton: authState.maybeWhen(
        data: (user) => user != null && user.isDonor
            ? FloatingActionButton.extended(
                backgroundColor: AppTheme.primaryGreen,
                foregroundColor: Colors.white,
                onPressed: () =>
                    Navigator.of(context).pushNamed(AppRoutes.addDonation),
                icon: const Icon(Icons.add),
                label: const Text('Donate Food'),
              )
            : null,
        orElse: () => null,
      ),
      body: authState.when(
        loading: () => const LoadingView(message: 'Loading session...'),
        error: (_, __) => const EmptyState(
          icon: Icons.error_outline,
          title: 'Unable to load session',
          message: 'Please sign in again.',
        ),
        data: (user) {
          if (user == null) {
            return const EmptyState(
              icon: Icons.lock_outline,
              title: 'Sign in required',
              message: 'Please sign in to view and discover donations.',
            );
          }
          return _DonationListBody(
            user: user,
            searchQuery: _searchController.text.trim(),
            cityFilter: _cityController.text.trim().isEmpty ? null : _cityController.text.trim(),
            selectedCategory: _selectedCategory,
            selectedUrgency: _selectedUrgency,
            selectedStatus: _selectedStatus,
            searchController: _searchController,
            cityController: _cityController,
            onCategoryChanged: (cat) => setState(() => _selectedCategory = cat),
            onUrgencyChanged: (urg) => setState(() => _selectedUrgency = urg),
            onStatusChanged: (st) => setState(() => _selectedStatus = st),
            onResetFilters: _clearFilters,
          );
        },
      ),
    );
  }

  bool get _hasActiveFilters =>
      _searchController.text.isNotEmpty ||
      _cityController.text.isNotEmpty ||
      _selectedCategory != null ||
      _selectedUrgency != UrgencyFilter.all ||
      _selectedStatus != null;
}

enum UrgencyFilter {
  all('All Urgency'),
  urgent('Urgent (< 6h)'),
  today('Expiring Today (< 24h)'),
  fresh('Fresh (> 24h)');

  const UrgencyFilter(this.label);
  final String label;
}

class _DonationListBody extends ConsumerWidget {
  const _DonationListBody({
    required this.user,
    required this.searchQuery,
    required this.cityFilter,
    required this.selectedCategory,
    required this.selectedUrgency,
    required this.selectedStatus,
    required this.searchController,
    required this.cityController,
    required this.onCategoryChanged,
    required this.onUrgencyChanged,
    required this.onStatusChanged,
    required this.onResetFilters,
  });

  final AppUser user;
  final String searchQuery;
  final String? cityFilter;
  final String? selectedCategory;
  final UrgencyFilter selectedUrgency;
  final DonationStatus? selectedStatus;
  final TextEditingController searchController;
  final TextEditingController cityController;
  final ValueChanged<String?> onCategoryChanged;
  final ValueChanged<UrgencyFilter> onUrgencyChanged;
  final ValueChanged<DonationStatus?> onStatusChanged;
  final VoidCallback onResetFilters;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final donationService = ref.watch(donationServiceProvider);
    final stream = user.isDonor
        ? donationService.watchDonationsForUser(user.id)
        : donationService.watchDonations(
            city: cityFilter,
            status: selectedStatus,
          );

    return Column(
      children: <Widget>[
        // Filter and Search Header
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // Search input
              Row(
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      controller: searchController,
                      decoration: InputDecoration(
                        hintText: 'Search food type, title, donor...',
                        prefixIcon: const Icon(Icons.search, size: 20),
                        suffixIcon: searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 18),
                                onPressed: searchController.clear,
                              )
                            : null,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 130,
                    child: TextField(
                      controller: cityController,
                      decoration: InputDecoration(
                        hintText: 'City...',
                        prefixIcon: const Icon(Icons.location_city, size: 18),
                        suffixIcon: cityController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 18),
                                onPressed: cityController.clear,
                              )
                            : null,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Category Filter Row
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: <Widget>[
                    FilterChip(
                      selected: selectedCategory == null,
                      onSelected: (_) => onCategoryChanged(null),
                      label: const Text('All Foods'),
                      labelStyle: TextStyle(
                        fontSize: 11,
                        fontWeight: selectedCategory == null ? FontWeight.bold : FontWeight.w600,
                        color: selectedCategory == null ? Colors.white : const Color(0xFF1B2E21),
                      ),
                      backgroundColor: Colors.white,
                      selectedColor: AppTheme.primaryGreen,
                      showCheckmark: false,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: selectedCategory == null ? AppTheme.primaryGreen : AppTheme.creamBorder,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    ...AppConstants.foodCategories.map((category) {
                      final isSelected = selectedCategory == category;
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: FilterChip(
                          selected: isSelected,
                          onSelected: (_) => onCategoryChanged(isSelected ? null : category),
                          avatar: Icon(
                            CategoryChip.getIconForCategory(category),
                            size: 14,
                            color: isSelected ? Colors.white : AppTheme.primaryGreenDark,
                          ),
                          label: Text(category),
                          labelStyle: TextStyle(
                            fontSize: 11,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                            color: isSelected ? Colors.white : const Color(0xFF1B2E21),
                          ),
                          backgroundColor: Colors.white,
                          selectedColor: AppTheme.primaryGreen,
                          showCheckmark: false,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(
                              color: isSelected ? AppTheme.primaryGreen : AppTheme.creamBorder,
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // Urgency and Status Filter Chips Row
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: <Widget>[
                    ...UrgencyFilter.values.map((filter) {
                      final isSelected = selectedUrgency == filter;
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ChoiceChip(
                          label: Text(filter.label),
                          labelStyle: TextStyle(
                            fontSize: 11,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            color: isSelected ? const Color(0xFF92400E) : Colors.grey.shade700,
                          ),
                          selected: isSelected,
                          selectedColor: AppTheme.amberUrgentBg,
                          backgroundColor: Colors.white,
                          side: BorderSide(
                            color: isSelected ? AppTheme.amberUrgent : AppTheme.creamBorder,
                          ),
                          onSelected: (_) => onUrgencyChanged(filter),
                        ),
                      );
                    }),
                    if (!user.isCharity) ...<Widget>[
                      const SizedBox(width: 4),
                      DropdownButtonHideUnderline(
                        child: Container(
                          height: 32,
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppTheme.creamBorder),
                          ),
                          child: DropdownButton<DonationStatus?>(
                            value: selectedStatus,
                            hint: const Text('All Statuses', style: TextStyle(fontSize: 11)),
                            icon: const Icon(Icons.arrow_drop_down, size: 16),
                            style: const TextStyle(fontSize: 11, color: Color(0xFF1B2E21)),
                            items: [
                              const DropdownMenuItem<DonationStatus?>(
                                value: null,
                                child: Text('All Statuses'),
                              ),
                              ...DonationStatus.values.map(
                                (s) => DropdownMenuItem<DonationStatus?>(
                                  value: s,
                                  child: Text(s.label),
                                ),
                              ),
                            ],
                            onChanged: onStatusChanged,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),

        // Donation List Stream
        Expanded(
          child: StreamBuilder<List<Donation>>(
            stream: stream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                return const LoadingView(message: 'Loading donations...');
              }
              if (snapshot.hasError) {
                return const EmptyState(
                  icon: Icons.error_outline,
                  title: 'Could not load donations',
                  message: 'Check connection or Firebase configuration and try again.',
                );
              }

              final rawDonations = snapshot.data ?? <Donation>[];

              // Filter in memory for search query, category, and urgency
              final filtered = rawDonations.where((d) {
                // Search query match
                if (searchQuery.isNotEmpty) {
                  final q = searchQuery.toLowerCase();
                  final titleMatch = d.title.toLowerCase().contains(q);
                  final descMatch = d.description.toLowerCase().contains(q);
                  final donorMatch = d.donorName.toLowerCase().contains(q);
                  final categoryMatch = d.category.toLowerCase().contains(q);
                  if (!titleMatch && !descMatch && !donorMatch && !categoryMatch) {
                    return false;
                  }
                }

                // Category filter match
                if (selectedCategory != null && d.category != selectedCategory) {
                  return false;
                }

                // Urgency filter match
                switch (selectedUrgency) {
                  case UrgencyFilter.urgent:
                    if (!d.isUrgent) return false;
                    break;
                  case UrgencyFilter.today:
                    if (!d.isExpiringToday) return false;
                    break;
                  case UrgencyFilter.fresh:
                    if (d.isExpiringToday || d.isExpired) return false;
                    break;
                  case UrgencyFilter.all:
                    break;
                }

                // Status match (for user query)
                if (selectedStatus != null && d.status != selectedStatus) {
                  return false;
                }

                return true;
              }).toList();

              if (filtered.isEmpty) {
                return EmptyState(
                  icon: Icons.search_off_outlined,
                  title: 'No donations match your criteria',
                  message: 'Try clearing some filters or searching for a different food type or city.',
                  actionLabel: 'Reset Filters',
                  onAction: onResetFilters,
                );
              }

              final matchingService = ref.watch(matchingServiceProvider);
              final scoreById = <String, int>{};
              final visibleDonations = user.isCharity
                  ? matchingService.rankDonations(filtered).map((result) {
                      scoreById[result.donation.id] = result.score;
                      return result.donation;
                    }).toList()
                  : filtered;

              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                itemCount: visibleDonations.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final donation = visibleDonations[index];
                  return _SharePlateDonationCard(
                    donation: donation,
                    score: scoreById[donation.id],
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _SharePlateDonationCard extends StatelessWidget {
  const _SharePlateDonationCard({
    required this.donation,
    this.score,
  });

  final Donation donation;
  final int? score;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.of(context).pushNamed(
          AppRoutes.donationDetails,
          arguments: donation,
        ),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.creamBorder, width: 1.2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // Header: Title & Urgency Badge
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          donation.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF14291B),
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
                  UrgencyBadge(expiryDate: donation.expiryDate),
                ],
              ),

              const SizedBox(height: 10),

              // Description
              Text(
                donation.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade700,
                  height: 1.35,
                ),
              ),

              const SizedBox(height: 12),
              Divider(height: 1, color: AppTheme.creamBorder.withAlpha(140)),
              const SizedBox(height: 10),

              // Metadata Row: Quantity, Location, Donor, Score
              Row(
                children: <Widget>[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppTheme.creamAccent,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      children: <Widget>[
                        const Icon(Icons.scale, size: 13, color: AppTheme.primaryGreenDark),
                        const SizedBox(width: 4),
                        Text(
                          '${donation.quantity} ${donation.unit}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryGreenDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.location_on_outlined, size: 15, color: Colors.grey.shade600),
                  const SizedBox(width: 2),
                  Text(
                    donation.city,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade800),
                  ),
                  const Spacer(),
                  if (score != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryGreenContainer,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Match: $score%',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.onPrimaryGreenContainer,
                        ),
                      ),
                    )
                  else
                    Text(
                      'by ${donation.donorName}',
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
