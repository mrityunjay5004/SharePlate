import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_constants.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/date_formatters.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/category_chip.dart';
import '../../../core/widgets/urgency_badge.dart';
import '../../../models/donation.dart';

class AddDonationScreen extends ConsumerStatefulWidget {
  const AddDonationScreen({super.key});

  @override
  ConsumerState<AddDonationScreen> createState() => _AddDonationScreenState();
}

class _AddDonationScreenState extends ConsumerState<AddDonationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _quantityController = TextEditingController();
  final _cityController = TextEditingController(text: AppConstants.defaultCity);
  final _pickupAddressController = TextEditingController();
  final _notesController = TextEditingController();
  String _category = AppConstants.foodCategories.first;
  String _unit = AppConstants.donationUnits.first;
  DateTime _expiryDate = DateTime.now().add(const Duration(hours: 12));
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _quantityController.dispose();
    _cityController.dispose();
    _pickupAddressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickExpiryDate() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _expiryDate,
      firstDate: now,
      lastDate: now.add(const Duration(days: 30)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: AppTheme.primaryGreen,
                ),
          ),
          child: child!,
        );
      },
    );
    if (date == null || !mounted) {
      return;
    }

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_expiryDate),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: AppTheme.primaryGreen,
                ),
          ),
          child: child!,
        );
      },
    );
    if (time == null || !mounted) {
      return;
    }

    final selected = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
    if (selected.isBefore(DateTime.now())) {
      _showMessage('Expiry date and time must be in the future.');
      return;
    }
    setState(() => _expiryDate = selected);
  }

  String _calculateEstimatedImpact() {
    final qty = double.tryParse(_quantityController.text.trim()) ?? 0;
    if (qty <= 0) return '';
    double meals = 0;
    switch (_unit.toLowerCase()) {
      case 'kg':
        meals = qty * AppConstants.mealsPerKg;
        break;
      case 'boxes':
        meals = qty * AppConstants.mealsPerBox;
        break;
      default:
        meals = qty;
        break;
    }
    return '≈ ${meals.toStringAsFixed(0)} meals shared & ${(meals * 0.4 * AppConstants.co2SavedPerKg).toStringAsFixed(1)} kg CO₂e saved!';
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final user = await ref.read(authServiceProvider).getCurrentUser();
    if (user == null) {
      _showMessage('Please sign in again to create a donation.');
      return;
    }
    if (!user.isDonor && !user.isAdmin) {
      _showMessage('Only donors can share food donations.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final donation = Donation(
        id: '',
        donorId: user.id,
        donorName: user.name,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        quantity: double.parse(_quantityController.text.trim()),
        unit: _unit,
        category: _category,
        pickupAddress: _pickupAddressController.text.trim().isEmpty
            ? null
            : _pickupAddressController.text.trim(),
        expiryDate: _expiryDate,
        city: _cityController.text.trim(),
        status: DonationStatus.pending,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final created = await ref
          .read(donationServiceProvider)
          .createDonation(donation);

      await ref
          .read(notificationServiceProvider)
          .notifyNewDonation(created);

      if (!mounted) return;

      // Show beautiful success dialog
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const SizedBox(height: 12),
                Container(
                  width: 64,
                  height: 64,
                  decoration: const BoxDecoration(
                    color: AppTheme.primaryGreenContainer,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, size: 36, color: AppTheme.primaryGreen),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Donation Published!',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF14291B),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${created.title} (${created.quantity} ${created.unit}) is now visible to nearby charities in ${created.city}.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 13, color: Color(0xFF4A5568)),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).pop();
                  },
                  child: const Text('Back to Home'),
                ),
              ],
            ),
          );
        },
      );
    } on AppException catch (error) {
      _showMessage(error.message);
    } catch (_) {
      _showMessage('Unable to create donation. Please verify your connection.');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.creamBackground,
      appBar: AppBar(title: const Text('Share Surplus Food')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 580),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    // Card 1: Food Details
                    _FormCard(
                      title: 'Food Information',
                      icon: Icons.restaurant_outlined,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          TextFormField(
                            controller: _titleController,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              labelText: 'Donation Title *',
                              hintText: 'e.g. Fresh bread loaves, Cooked pasta batches',
                              prefixIcon: Icon(Icons.edit_outlined),
                            ),
                            validator: (value) => Validators.requiredText(
                              value,
                              fieldName: 'Title',
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Category Picker
                          DropdownButtonFormField<String>(
                            value: _category,
                            decoration: const InputDecoration(
                              labelText: 'Food Category *',
                              prefixIcon: Icon(Icons.category_outlined),
                            ),
                            items: AppConstants.foodCategories.map((cat) {
                              return DropdownMenuItem<String>(
                                value: cat,
                                child: Row(
                                  children: <Widget>[
                                    Icon(
                                      CategoryChip.getIconForCategory(cat),
                                      size: 16,
                                      color: AppTheme.primaryGreenDark,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(cat),
                                  ],
                                ),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) setState(() => _category = val);
                            },
                          ),
                          const SizedBox(height: 14),

                          TextFormField(
                            controller: _descriptionController,
                            maxLines: 3,
                            decoration: const InputDecoration(
                              labelText: 'Description & Contents *',
                              hintText: 'Describe portion sizes, preparation details, packaging, and handling notes.',
                              prefixIcon: Icon(Icons.notes_outlined),
                            ),
                            validator: (value) => Validators.requiredText(
                              value,
                              fieldName: 'Description',
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Card 2: Quantity & Expiry Urgency
                    _FormCard(
                      title: 'Quantity & Urgency',
                      icon: Icons.scale_outlined,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Row(
                            children: <Widget>[
                              Expanded(
                                flex: 3,
                                child: TextFormField(
                                  controller: _quantityController,
                                  keyboardType: const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                                  onChanged: (_) => setState(() {}),
                                  decoration: const InputDecoration(
                                    labelText: 'Quantity *',
                                    hintText: 'e.g. 25',
                                    prefixIcon: Icon(Icons.pin_outlined),
                                  ),
                                  validator: Validators.positiveNumber,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                flex: 2,
                                child: DropdownButtonFormField<String>(
                                  value: _unit,
                                  decoration: const InputDecoration(
                                    labelText: 'Unit',
                                  ),
                                  items: AppConstants.donationUnits.map((unit) {
                                    return DropdownMenuItem<String>(
                                      value: unit,
                                      child: Text(unit),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    if (value != null) setState(() => _unit = value);
                                  },
                                ),
                              ),
                            ],
                          ),

                          // Live Impact Preview
                          if (_calculateEstimatedImpact().isNotEmpty) ...<Widget>[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppTheme.creamAccent,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: <Widget>[
                                  const Icon(Icons.eco, size: 14, color: AppTheme.primaryGreen),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      _calculateEstimatedImpact(),
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
                          ],

                          const SizedBox(height: 16),

                          // Expiry Date & Urgency Indicator
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppTheme.creamAccent,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.calendar_month, color: AppTheme.primaryGreen),
                            ),
                            title: const Text('Best Before / Expiry Time', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                            subtitle: Text(DateFormatters.dateTime(_expiryDate)),
                            trailing: OutlinedButton(
                              onPressed: _pickExpiryDate,
                              style: OutlinedButton.styleFrom(
                                visualDensity: VisualDensity.compact,
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                              ),
                              child: const Text('Change'),
                            ),
                          ),

                          // Real-time urgency warning box
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppTheme.creamBackground,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppTheme.creamBorder),
                            ),
                            child: Row(
                              children: <Widget>[
                                const Text('Urgency level: ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                                UrgencyBadge(expiryDate: _expiryDate, compact: true),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Card 3: Pickup Location & Instructions
                    _FormCard(
                      title: 'Pickup Location',
                      icon: Icons.location_on_outlined,
                      child: Column(
                        children: <Widget>[
                          TextFormField(
                            controller: _cityController,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              labelText: 'City *',
                              prefixIcon: Icon(Icons.location_city_outlined),
                            ),
                            validator: (value) => Validators.requiredText(
                              value,
                              fieldName: 'City',
                            ),
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _pickupAddressController,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              labelText: 'Pickup Address / Street / Venue',
                              hintText: 'e.g. 14 El Tahrir Square, Back Entrance',
                              prefixIcon: Icon(Icons.pin_drop_outlined),
                            ),
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _notesController,
                            decoration: const InputDecoration(
                              labelText: 'Special Pickup Instructions / Contact',
                              hintText: 'e.g. Call upon arrival; Bring insulated carriers',
                              prefixIcon: Icon(Icons.info_outline),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    FilledButton.icon(
                      onPressed: _isLoading ? null : _submit,
                      icon: _isLoading
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Icon(Icons.volunteer_activism_outlined),
                      label: const Text('Post Food Donation'),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FormCard extends StatelessWidget {
  const _FormCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
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
              Icon(icon, size: 18, color: AppTheme.primaryGreen),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF14291B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}
