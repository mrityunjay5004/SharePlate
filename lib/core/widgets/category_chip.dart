import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class CategoryChip extends StatelessWidget {
  const CategoryChip({
    required this.category,
    this.isSelected = false,
    this.onTap,
    this.isFilter = false,
    super.key,
  });

  final String category;
  final bool isSelected;
  final VoidCallback? onTap;
  final bool isFilter;

  static IconData getIconForCategory(String category) {
    final lower = category.toLowerCase();
    if (lower.contains('cooked') || lower.contains('meal')) {
      return Icons.restaurant;
    }
    if (lower.contains('bake') || lower.contains('bread')) {
      return Icons.bakery_dining_outlined;
    }
    if (lower.contains('produce') || lower.contains('fresh') || lower.contains('veg') || lower.contains('fruit')) {
      return Icons.eco_outlined;
    }
    if (lower.contains('dairy') || lower.contains('egg') || lower.contains('milk')) {
      return Icons.egg_outlined;
    }
    if (lower.contains('pantry') || lower.contains('canned') || lower.contains('box')) {
      return Icons.inventory_2_outlined;
    }
    if (lower.contains('beverage') || lower.contains('drink') || lower.contains('water')) {
      return Icons.local_cafe_outlined;
    }
    return Icons.fastfood_outlined;
  }

  @override
  Widget build(BuildContext context) {
    final icon = getIconForCategory(category);

    if (isFilter) {
      return FilterChip(
        selected: isSelected,
        onSelected: onTap != null ? (_) => onTap!() : null,
        avatar: Icon(
          icon,
          size: 16,
          color: isSelected ? Colors.white : AppTheme.primaryGreen,
        ),
        label: Text(category),
        labelStyle: TextStyle(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
          color: isSelected ? Colors.white : const Color(0xFF23362B),
        ),
        backgroundColor: Colors.white,
        selectedColor: AppTheme.primaryGreen,
        checkmarkColor: Colors.white,
        showCheckmark: false,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: isSelected ? AppTheme.primaryGreen : AppTheme.creamBorder,
            width: 1.2,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.creamAccent,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.creamBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 13, color: AppTheme.primaryGreenDark),
          const SizedBox(width: 4),
          Text(
            category,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryGreenDark,
            ),
          ),
        ],
      ),
    );
  }
}
