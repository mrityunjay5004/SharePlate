import 'package:flutter/material.dart';

import '../../models/donation.dart';
import '../config/app_constants.dart';
import '../theme/app_theme.dart';

class FoodImpactDashboard extends StatelessWidget {
  const FoodImpactDashboard({
    required this.donations,
    this.title = 'Community Impact',
    this.isPersonal = false,
    super.key,
  });

  final List<Donation> donations;
  final String title;
  final bool isPersonal;

  /// Calculates total estimated meals rescued across all donations
  static double calculateTotalMeals(List<Donation> donations) {
    double totalMeals = 0;
    for (final donation in donations) {
      if (donation.status == DonationStatus.rejected) continue;
      final qty = donation.quantity;
      switch (donation.unit.toLowerCase()) {
        case 'kg':
          totalMeals += qty * AppConstants.mealsPerKg;
          break;
        case 'boxes':
          totalMeals += qty * AppConstants.mealsPerBox;
          break;
        case 'portions':
        case 'meals':
        default:
          totalMeals += qty;
          break;
      }
    }
    return totalMeals;
  }

  /// Calculates total estimated food weight in kg
  static double calculateWeightInKg(List<Donation> donations) {
    double totalKg = 0;
    for (final donation in donations) {
      if (donation.status == DonationStatus.rejected) continue;
      final qty = donation.quantity;
      switch (donation.unit.toLowerCase()) {
        case 'kg':
          totalKg += qty;
          break;
        case 'boxes':
          totalKg += qty * 4.0; // ~4kg per typical surplus box
          break;
        case 'portions':
        case 'meals':
        default:
          totalKg += qty / AppConstants.mealsPerKg; // ~400g per meal
          break;
      }
    }
    return totalKg;
  }

  /// Estimated CO2 emissions avoided in kg CO2e
  static double calculateCo2Saved(List<Donation> donations) {
    return calculateWeightInKg(donations) * AppConstants.co2SavedPerKg;
  }

  void _showCalculationMethodDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Row(
            children: <Widget>[
              Icon(Icons.eco, color: AppTheme.primaryGreen),
              SizedBox(width: 8),
              Text('Impact Methodology'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Text(
                  'All environmental and meal impact figures shown are transparent estimates calculated using international benchmarks from the UNEP Food Waste Index and EPA WARM model:',
                  style: TextStyle(fontSize: 13, height: 1.4),
                ),
                const SizedBox(height: 12),
                _methodologyItem(
                  '1 Meal Unit',
                  'Standardized to 1 nutritious meal portion (~400 grams).',
                ),
                _methodologyItem(
                  '1 Kg of Food',
                  'Converted to 2.5 meals based on standard food redistribution portions.',
                ),
                _methodologyItem(
                  '1 Food Box',
                  'Standardized to 10 assorted meals (~4 kg of assorted groceries).',
                ),
                _methodologyItem(
                  'CO₂ Emissions Avoided',
                  'Preventing 1 kg of food from rotting in landfills avoids approximately 2.5 kg of CO₂ equivalent greenhouse gas emissions.',
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.creamAccent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    children: <Widget>[
                      Icon(Icons.info_outline, size: 16, color: Color(0xFF6B5A33)),
                      SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Figures update dynamically as donations are created and completed.',
                          style: TextStyle(fontSize: 11, color: Color(0xFF6B5A33)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Widget _methodologyItem(String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text('• ', style: TextStyle(fontWeight: FontWeight.bold)),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(color: Colors.black87, fontSize: 12),
                children: [
                  TextSpan(
                    text: '$title: ',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(text: description),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalMeals = calculateTotalMeals(donations);
    final totalKg = calculateWeightInKg(donations);
    final co2Avoided = calculateCo2Saved(donations);
    final completedCount = donations
        .where((d) => d.status == DonationStatus.completed)
        .length;

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1B5E3C), Color(0xFF27734C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1B5E3C).withAlpha(40),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(35),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.eco, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const Spacer(),
              InkWell(
                onTap: () => _showCalculationMethodDialog(context),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(30),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    children: <Widget>[
                      Text(
                        'Estimates',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(Icons.info_outline, color: Colors.white, size: 13),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: <Widget>[
              Expanded(
                child: _MetricTile(
                  icon: Icons.restaurant,
                  value: totalMeals.toStringAsFixed(0),
                  unit: 'Meals',
                  label: isPersonal ? 'Shared' : 'Redistributed',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MetricTile(
                  icon: Icons.scale,
                  value: totalKg.toStringAsFixed(1),
                  unit: 'Kg',
                  label: 'Food Rescued',
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: <Widget>[
              Expanded(
                child: _MetricTile(
                  icon: Icons.cloud_done_outlined,
                  value: co2Avoided.toStringAsFixed(0),
                  unit: 'Kg CO₂e',
                  label: 'Emissions Saved',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MetricTile(
                  icon: Icons.task_alt,
                  value: completedCount.toString(),
                  unit: 'Completed',
                  label: 'Handoffs Done',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.icon,
    required this.value,
    required this.unit,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String unit;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(22),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withAlpha(30), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(icon, size: 14, color: const Color(0xFFD4ECD8)),
              const SizedBox(width: 5),
              Text(
                unit,
                style: const TextStyle(
                  color: Color(0xFFD4ECD8),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withAlpha(200),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}
