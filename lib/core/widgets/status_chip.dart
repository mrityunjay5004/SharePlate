import 'package:flutter/material.dart';

import '../../models/donation.dart';

class StatusChip extends StatelessWidget {
  const StatusChip({required this.status, super.key});

  final DonationStatus status;

  @override
  Widget build(BuildContext context) {
    final (Color bg, Color fg, IconData icon) = switch (status) {
      DonationStatus.pending => (
        const Color(0xFFD4ECD8),
        const Color(0xFF0D4722),
        Icons.storefront_outlined,
      ),
      DonationStatus.requested => (
        const Color(0xFFFEF3C7),
        const Color(0xFF92400E),
        Icons.hail_outlined,
      ),
      DonationStatus.accepted => (
        const Color(0xFFCCEBD7),
        const Color(0xFF0F5132),
        Icons.check_circle_outline,
      ),
      DonationStatus.pickedUp => (
        const Color(0xFFE0E7FF),
        const Color(0xFF3730A3),
        Icons.local_shipping_outlined,
      ),
      DonationStatus.completed => (
        const Color(0xFFE2E8F0),
        const Color(0xFF1E293B),
        Icons.done_all_outlined,
      ),
      DonationStatus.rejected => (
        const Color(0xFFFEE2E2),
        const Color(0xFF991B1B),
        Icons.cancel_outlined,
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: fg.withAlpha(45), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 13, color: fg),
          const SizedBox(width: 4),
          Text(
            status.label,
            style: TextStyle(
              color: fg,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
    );
  }
}
