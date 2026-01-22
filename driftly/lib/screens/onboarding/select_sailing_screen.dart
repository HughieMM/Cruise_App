import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';

/// Select Sailing Screen
///
/// Flow:
/// 1. Choose Cruise Line (dropdown)
/// 2. Choose Ship (filtered by cruise line)
/// 3. Choose Sailing Date (date picker)
/// 4. Create/find sailing in Firestore
/// 5. Save currentSailingId to user document
///
/// After selection → /onboarding/pods
class SelectSailingScreen extends StatefulWidget {
  const SelectSailingScreen({super.key});

  @override
  State<SelectSailingScreen> createState() => _SelectSailingScreenState();
}

class _SelectSailingScreenState extends State<SelectSailingScreen> {
  final _firestoreService = FirestoreService();

  // Hard-coded cruise data for testing
  // In production, this would be loaded from Firestore
  final Map<String, List<String>> _cruiseData = {
    'Royal Caribbean': [
      'Harmony of the Seas',
      'Symphony of the Seas',
      'Oasis of the Seas',
    ],
    'Carnival': [
      'Carnival Vista',
      'Carnival Horizon',
      'Carnival Panorama',
    ],
    'Norwegian': [
      'Norwegian Escape',
      'Norwegian Bliss',
      'Norwegian Encore',
    ],
  };

  String? _selectedCruiseLine;
  String? _selectedShip;
  DateTime? _selectedDate;
  bool _isLoading = false;

  List<String> get _availableShips {
    if (_selectedCruiseLine == null) return [];
    return _cruiseData[_selectedCruiseLine] ?? [];
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: 'Select your sailing date',
    );

    if (picked != null) {
      // TODO: Add 30-day validation
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _handleContinue() async {
    // Validation
    if (_selectedCruiseLine == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a cruise line')),
      );
      return;
    }

    if (_selectedShip == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a ship')),
      );
      return;
    }

    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a sailing date')),
      );
      return;
    }

    // Check 30-day window
    final daysUntilDeparture = _selectedDate!.difference(DateTime.now()).inDays;
    if (daysUntilDeparture > 30) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'You can only access sailings within 30 days of departure. '
            'Your sailing is $daysUntilDeparture days away.',
          ),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 4),
        ),
      );
      return;
    }

    if (daysUntilDeparture < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a future sailing date'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      // Create simple IDs from the selected values
      // In production, these would be actual Firestore IDs
      final cruiseLineId = _selectedCruiseLine!.toLowerCase().replaceAll(' ', '_');
      final shipId = _selectedShip!.toLowerCase().replaceAll(' ', '_');

      // Find or create the sailing
      final sailingId = await _firestoreService.findOrCreateSailing(
        cruiseLineId: cruiseLineId,
        shipId: shipId,
        departureDate: _selectedDate!,
      );

      // Update user's current sailing
      await _firestoreService.updateCurrentSailing(
        authProvider.firebaseUser!.uid,
        sailingId,
      );

      // Refresh user data in provider
      await authProvider.refreshUserData();

      if (!mounted) return;

      // Navigate to pod selection
      context.go('/onboarding/pods');
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save sailing: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Choose Your Cruise'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Progress Indicator
              LinearProgressIndicator(
                value: 2 / 3, // Step 2 of 3
                backgroundColor: Colors.grey[200],
              ),
              const SizedBox(height: 32),

              // Header
              const Text(
                'Select your sailing',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Find cruisers on your specific voyage',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 32),

              // Cruise Line Dropdown
              DropdownButtonFormField<String>(
                value: _selectedCruiseLine,
                decoration: const InputDecoration(
                  labelText: 'Cruise Line',
                  prefixIcon: Icon(Icons.directions_boat),
                  border: OutlineInputBorder(),
                ),
                items: _cruiseData.keys.map((cruiseLine) {
                  return DropdownMenuItem(
                    value: cruiseLine,
                    child: Text(cruiseLine),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCruiseLine = value;
                    _selectedShip = null; // Reset ship selection
                  });
                },
              ),
              const SizedBox(height: 24),

              // Ship Dropdown (enabled only after cruise line is selected)
              DropdownButtonFormField<String>(
                value: _selectedShip,
                decoration: const InputDecoration(
                  labelText: 'Ship',
                  prefixIcon: Icon(Icons.sailing),
                  border: OutlineInputBorder(),
                ),
                items: _availableShips.map((ship) {
                  return DropdownMenuItem(
                    value: ship,
                    child: Text(ship),
                  );
                }).toList(),
                onChanged: _selectedCruiseLine == null
                    ? null
                    : (value) {
                        setState(() {
                          _selectedShip = value;
                        });
                      },
              ),
              const SizedBox(height: 24),

              // Date Picker
              Card(
                child: ListTile(
                  leading: const Icon(Icons.calendar_today),
                  title: const Text('Sailing Date'),
                  subtitle: Text(
                    _selectedDate == null
                        ? 'Tap to select date'
                        : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: _selectDate,
                ),
              ),
              const SizedBox(height: 16),

              // 30-Day Info Card
              Card(
                color: Colors.blue[50],
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue[700]),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'You can access the app 30 days before your sailing date',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.blue[900],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Continue Button
              ElevatedButton(
                onPressed: _isLoading ? null : _handleContinue,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text(
                        'Continue',
                        style: TextStyle(fontSize: 16),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
