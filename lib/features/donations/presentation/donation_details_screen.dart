import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/date_formatters.dart';
import '../../../core/widgets/category_chip.dart';
import '../../../core/widgets/donation_timeline.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/loading_view.dart';
import '../../../core/widgets/status_chip.dart';
import '../../../core/widgets/text_info_row.dart';
import '../../../core/widgets/urgency_badge.dart';
import '../../../models/app_user.dart';
import '../../../models/donation.dart';
import '../../../models/notification_item.dart';

class DonationDetailsScreen extends ConsumerStatefulWidget {
  const DonationDetailsScreen({
    required this.donationId,
    this.initialDonation,
    super.key,
  });

  final String donationId;
  final Donation? initialDonation;

  @override
  ConsumerState<DonationDetailsScreen> createState() =>
      _DonationDetailsScreenState();
}

class _DonationDetailsScreenState extends ConsumerState<DonationDetailsScreen> {
  bool _isUpdating = false;

  Future<void> _changeStatus({
    required Donation donation,
    required AppUser user,
    required DonationStatus status,
  }) async {
    setState(() => _isUpdating = true);
    try {
      final charityId = (status == DonationStatus.accepted ||
              status == DonationStatus.requested ||
              status == DonationStatus.pickedUp)
          ? user.id
          : donation.acceptedByCharityId;
      final charityName = (status == DonationStatus.accepted ||
              status == DonationStatus.requested ||
              status == DonationStatus.pickedUp)
          ? user.name
          : donation.acceptedByCharityName;

      await ref.read(donationServiceProvider).updateStatus(
            donationId: donation.id,
            status: status,
            charityId: charityId,
            charityName: charityName,
          );

      final updated = donation.copyWith(
        status: status,
        acceptedByCharityId: charityId,
        acceptedByCharityName: charityName,
      );

      // Notify donor of status progression
      await ref.read(notificationServiceProvider).notifyDonationStatus(
            donation: updated,
            recipientUserId: donation.donorId,
            type: status == DonationStatus.accepted
                ? NotificationType.donationAccepted
                : NotificationType.statusUpdate,
          );

      _showMessage('Donation status updated to ${status.label}.');
    } on AppException catch (error) {
      _showMessage(error.message);
    } catch (_) {
      _showMessage('Unable to update donation status.');
    } finally {
      if (mounted) {
        setState(() => _isUpdating = false);
      }
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final donationAsync = ref.watch(donationDetailsProvider(widget.donationId));
    final authAsync = ref.watch(authStateProvider);

    return Scaffold(
      backgroundColor: AppTheme.creamBackground,
      appBar: AppBar(title: const Text('Donation Details')),
      body: donationAsync.when(
        loading: () => widget.initialDonation == null
            ? const LoadingView(message: 'Loading donation details...')
            : _buildDetails(widget.initialDonation!, authAsync),
        error: (_, __) => widget.initialDonation == null
            ? const EmptyState(
                icon: Icons.error_outline,
                title: 'Could not load donation',
                message:
                    'The donation may have been removed or connection failed.',
              )
            : _buildDetails(widget.initialDonation!, authAsync),
        data: (donation) {
          final currentDonation = donation ?? widget.initialDonation;
          if (currentDonation == null) {
            return const EmptyState(
              icon: Icons.search_off_outlined,
              title: 'Donation not found',
              message: 'Return to the donation list and try again.',
            );
          }

          return _buildDetails(currentDonation, authAsync);
        },
      ),
    );
  }

  Widget _buildDetails(Donation donation, AsyncValue<AppUser?> authAsync) {
    return authAsync.when(
      loading: () => const LoadingView(),
      error: (_, __) => _DetailsBody(donation: donation),
      data: (user) => _DetailsBody(
        donation: donation,
        user: user,
        isUpdating: _isUpdating,
        onStatusChange: user == null
            ? null
            : (status) =>
                _changeStatus(donation: donation, user: user, status: status),
      ),
    );
  }
}

class _DetailsBody extends ConsumerWidget {
  const _DetailsBody({
    required this.donation,
    this.user,
    this.isUpdating = false,
    this.onStatusChange,
  });

  final Donation donation;
  final AppUser? user;
  final bool isUpdating;
  final ValueChanged<DonationStatus>? onStatusChange;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final matchingResult =
        ref.watch(matchingServiceProvider).scoreDonation(donation);

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      children: <Widget>[
        // Status Timeline Widget
        DonationStatusTimeline(status: donation.status),
        const SizedBox(height: 14),

        // Urgent Expiry Warning Alert Box
        if (donation.isExpiringToday && donation.isAvailable) ...<Widget>[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.amberUrgentBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.amberUrgent.withAlpha(80)),
            ),
            child: Row(
              children: <Widget>[
                const Icon(Icons.warning_amber_rounded,
                    color: AppTheme.amberUrgent, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Pickup Reminder: Expires in ${DateFormatters.relativeExpiry(donation.expiryDate)}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF854D0E),
                        ),
                      ),
                      const Text(
                        'Ensure pickup arrangements are confirmed before expiry to maintain food safety.',
                        style: TextStyle(fontSize: 11, color: Color(0xFF713F12)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
        ],

        // Main Donation Info Card
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
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF14291B),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: <Widget>[
                            CategoryChip(category: donation.category),
                            const SizedBox(width: 8),
                            StatusChip(status: donation.status),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  UrgencyBadge(expiryDate: donation.expiryDate),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                donation.description,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.45,
                  color: Color(0xFF2D3748),
                ),
              ),
              const SizedBox(height: 16),
              Divider(height: 1, color: AppTheme.creamBorder),
              const SizedBox(height: 12),

              // Detailed Specifications
              TextInfoRow(
                label: 'Quantity',
                value: '${donation.quantity} ${donation.unit}',
                icon: Icons.scale_outlined,
              ),
              TextInfoRow(
                label: 'Expiry Time',
                value: DateFormatters.dateTime(donation.expiryDate),
                icon: Icons.schedule_outlined,
              ),
              TextInfoRow(
                label: 'City',
                value: donation.city,
                icon: Icons.location_city_outlined,
              ),
              if (donation.pickupAddress != null && donation.pickupAddress!.isNotEmpty)
                TextInfoRow(
                  label: 'Pickup Address',
                  value: donation.pickupAddress!,
                  icon: Icons.pin_drop_outlined,
                ),
              TextInfoRow(
                label: 'Donor',
                value: donation.donorName,
                icon: Icons.person_outline,
              ),
              if (donation.acceptedByCharityName != null)
                TextInfoRow(
                  label: 'Assigned Charity',
                  value: donation.acceptedByCharityName!,
                  icon: Icons.diversity_1_outlined,
                ),
              if (donation.notes != null && donation.notes!.isNotEmpty)
                TextInfoRow(
                  label: 'Instructions',
                  value: donation.notes!,
                  icon: Icons.info_outline,
                ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // Rule-Based Matching Priority Card
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
              Row(
                children: <Widget>[
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGreenContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.auto_awesome,
                        size: 16, color: AppTheme.onPrimaryGreenContainer),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Priority Ranking: ${matchingResult.score}%',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF14291B),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: (matchingResult.score / 100).clamp(0.0, 1.0),
                  minHeight: 8,
                  backgroundColor: AppTheme.creamAccent,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    matchingResult.score > 70
                        ? AppTheme.primaryGreen
                        : (matchingResult.score > 40
                            ? AppTheme.amberUrgent
                            : Colors.grey),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              for (final reason in matchingResult.reasons)
                Padding(
                  padding: const EdgeInsets.only(bottom: 5),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const Text('• ',
                          style: TextStyle(
                              color: AppTheme.primaryGreen,
                              fontWeight: FontWeight.bold)),
                      Expanded(
                        child: Text(
                          reason,
                          style: const TextStyle(fontSize: 12, height: 1.3),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Action Buttons based on User Role and 5-stage timeline
        if (user != null)
          _ActionButtons(
            user: user!,
            donation: donation,
            isUpdating: isUpdating,
            onStatusChange: onStatusChange,
          ),

        const SizedBox(height: 32),
      ],
    );
  }
}

class _ActionButtons extends StatelessWidget {
  const _ActionButtons({
    required this.user,
    required this.donation,
    required this.isUpdating,
    required this.onStatusChange,
  });

  final AppUser user;
  final Donation donation;
  final bool isUpdating;
  final ValueChanged<DonationStatus>? onStatusChange;

  @override
  Widget build(BuildContext context) {
    if (onStatusChange == null) {
      return const SizedBox.shrink();
    }

    // Step 1: Charity accepting an Available donation
    if (user.isCharity && donation.status == DonationStatus.pending) {
      return Row(
        children: <Widget>[
          Expanded(
            child: FilledButton.icon(
              onPressed: isUpdating
                  ? null
                  : () => onStatusChange!(DonationStatus.accepted),
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('Accept & Schedule Pickup'),
            ),
          ),
          const SizedBox(width: 10),
          OutlinedButton.icon(
            onPressed: isUpdating
                ? null
                : () => onStatusChange!(DonationStatus.rejected),
            icon: const Icon(Icons.cancel_outlined),
            label: const Text('Decline'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.redCritical,
              side: const BorderSide(color: AppTheme.redCritical),
            ),
          ),
        ],
      );
    }

    // Step 2: Charity or Donor advancing from Accepted -> Picked Up
    if (donation.status == DonationStatus.accepted &&
        (user.id == donation.donorId ||
            user.id == donation.acceptedByCharityId ||
            user.isAdmin)) {
      return FilledButton.icon(
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFF3730A3),
          foregroundColor: Colors.white,
        ),
        onPressed: isUpdating
            ? null
            : () => onStatusChange!(DonationStatus.pickedUp),
        icon: const Icon(Icons.local_shipping_outlined),
        label: const Text('Confirm Food Picked Up'),
      );
    }

    // Step 3: Advancing from Picked Up -> Completed
    if (donation.status == DonationStatus.pickedUp &&
        (user.id == donation.donorId ||
            user.id == donation.acceptedByCharityId ||
            user.isAdmin)) {
      return FilledButton.icon(
        style: FilledButton.styleFrom(
          backgroundColor: AppTheme.primaryGreen,
          foregroundColor: Colors.white,
        ),
        onPressed: isUpdating
            ? null
            : () => onStatusChange!(DonationStatus.completed),
        icon: const Icon(Icons.done_all_outlined),
        label: const Text('Mark Donation Completed & Delivered'),
      );
    }

    return const SizedBox.shrink();
  }
}
