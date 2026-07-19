import 'package:flutter/material.dart';

import '../../models/donation.dart';
import '../theme/app_theme.dart';

class DonationStatusTimeline extends StatelessWidget {
  const DonationStatusTimeline({
    required this.status,
    super.key,
  });

  final DonationStatus status;

  static const List<_TimelineStep> _stages = <_TimelineStep>[
    _TimelineStep(
      status: DonationStatus.pending,
      label: 'Available',
      icon: Icons.storefront_outlined,
    ),
    _TimelineStep(
      status: DonationStatus.requested,
      label: 'Requested',
      icon: Icons.hail_outlined,
    ),
    _TimelineStep(
      status: DonationStatus.accepted,
      label: 'Accepted',
      icon: Icons.assignment_turned_in_outlined,
    ),
    _TimelineStep(
      status: DonationStatus.pickedUp,
      label: 'Picked Up',
      icon: Icons.local_shipping_outlined,
    ),
    _TimelineStep(
      status: DonationStatus.completed,
      label: 'Completed',
      icon: Icons.check_circle_outline,
    ),
  ];

  int _currentIndex() {
    return switch (status) {
      DonationStatus.pending => 0,
      DonationStatus.requested => 1,
      DonationStatus.accepted => 2,
      DonationStatus.pickedUp => 3,
      DonationStatus.completed => 4,
      DonationStatus.rejected => -1,
    };
  }

  @override
  Widget build(BuildContext context) {
    if (status == DonationStatus.rejected) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.redCriticalBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.redCritical.withAlpha(60)),
        ),
        child: const Row(
          children: <Widget>[
            Icon(Icons.cancel_outlined, color: AppTheme.redCritical, size: 22),
            SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Donation Rejected',
                    style: TextStyle(
                      color: AppTheme.redCritical,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    'This request was declined and is no longer active.',
                    style: TextStyle(color: Color(0xFF7F1D1D), fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final currentIndex = _currentIndex();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.creamBorder, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Icon(Icons.linear_scale, color: AppTheme.primaryGreen, size: 20),
              const SizedBox(width: 8),
              Text(
                'Donation Lifecycle',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF14291B),
                    ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreenContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  status.label,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.onPrimaryGreenContainer,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: List.generate(_stages.length * 2 - 1, (index) {
              if (index.isOdd) {
                final lineStageIndex = index ~/ 2;
                final isPassed = lineStageIndex < currentIndex;
                return Expanded(
                  child: Container(
                    margin: const EdgeInsets.only(top: 15),
                    height: 3,
                    color: isPassed ? AppTheme.primaryGreen : AppTheme.creamBorder,
                  ),
                );
              }

              final stepIndex = index ~/ 2;
              final step = _stages[stepIndex];
              final isCompleted = stepIndex < currentIndex;
              final isCurrent = stepIndex == currentIndex;

              final Color circleBg;
              final Color iconColor;
              final Color borderColor;

              if (isCurrent) {
                circleBg = AppTheme.primaryGreen;
                iconColor = Colors.white;
                borderColor = AppTheme.primaryGreen;
              } else if (isCompleted) {
                circleBg = AppTheme.primaryGreenContainer;
                iconColor = AppTheme.onPrimaryGreenContainer;
                borderColor = AppTheme.primaryGreen;
              } else {
                circleBg = AppTheme.creamBackground;
                iconColor = const Color(0xFF9E9E9E);
                borderColor = AppTheme.creamBorder;
              }

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: circleBg,
                      shape: BoxShape.circle,
                      border: Border.all(color: borderColor, width: 1.5),
                    ),
                    child: Icon(
                      isCompleted ? Icons.check : step.icon,
                      size: 16,
                      color: iconColor,
                    ),
                  ),
                  const SizedBox(height: 6),
                  SizedBox(
                    width: 58,
                    child: Text(
                      step.label,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w500,
                        color: isCurrent
                            ? AppTheme.primaryGreenDark
                            : (isCompleted
                                ? const Color(0xFF2E4034)
                                : const Color(0xFF757575)),
                      ),
                    ),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _TimelineStep {
  const _TimelineStep({
    required this.status,
    required this.label,
    required this.icon,
  });

  final DonationStatus status;
  final String label;
  final IconData icon;
}
