import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Select Sailing Screen
///
/// Flow:
/// 1. Choose Cruise Line (dropdown)
/// 2. Choose Ship (filtered by cruise line)
/// 3. Choose Sailing Date (date picker)
///
/// After selection → /onboarding/pods
///
/// TODO: Load cruise lines and ships from Firestore
/// TODO: Validate sailing date is within 30 days of departure
class SelectSailingScreen extends StatefulWidget {
  const SelectSailingScreen({super.key});

  @override
  State<SelectSailingScreen> createState() => _SelectSailingScreenState();
}

class _SelectSailingScreenState extends State<SelectSailingScreen> {
  // Mock data - TODO: Replace with Firestore data
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

  void _handleContinue() {
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

    // TODO: Validate 30-day window
    // TODO: Save sailing info to Firestore

    context.go('/onboarding/pods');
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
                onPressed: _handleContinue,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
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
