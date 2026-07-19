import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../utils/date_formatters.dart';

enum UrgencyLevel {
  expired,
  urgent,
  expiringToday,
  normal;

  static UrgencyLevel fromDateTime(DateTime expiryDate) {
    final now = DateTime.now();
    if (expiryDate.isBefore(now)) {
      return UrgencyLevel.expired;
    }
    final difference = expiryDate.difference(now);
    if (difference.inHours < 6) {
      return UrgencyLevel.urgent;
    }
    if (difference.inHours < 24) {
      return UrgencyLevel.expiringToday;
    }
    return UrgencyLevel.normal;
  }
}

class UrgencyBadge extends StatelessWidget {
  const UrgencyBadge({
    required this.expiryDate,
    this.compact = false,
    super.key,
  });

  final DateTime expiryDate;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final level = UrgencyLevel.fromDateTime(expiryDate);
    final relativeTime = DateFormatters.relativeExpiry(expiryDate);

    final (Color bg, Color fg, IconData icon, String text) = switch (level) {
      UrgencyLevel.expired => (
        const Color(0xFFEEEEEE),
        const Color(0xFF616161),
        Icons.timer_off_outlined,
        'Expired',
      ),
      UrgencyLevel.urgent => (
        AppTheme.redCriticalBg,
        AppTheme.redCritical,
        Icons.local_fire_department_outlined,
        compact ? relativeTime : 'Urgent: $relativeTime',
      ),
      UrgencyLevel.expiringToday => (
        AppTheme.amberUrgentBg,
        AppTheme.amberUrgent,
        Icons.hourglass_bottom_rounded,
        compact ? relativeTime : 'Expiring: $relativeTime',
      ),
      UrgencyLevel.normal => (
        AppTheme.primaryGreenContainer,
        AppTheme.onPrimaryGreenContainer,
        Icons.schedule_outlined,
        compact ? relativeTime : 'Fresh: $relativeTime',
      ),
    };

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: fg.withAlpha(50), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: compact ? 13 : 15, color: fg),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: fg,
              fontSize: compact ? 11 : 12,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
    );
  }
}
