import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Onboarding Profile Screen
///
/// Collects:
/// - Name (first & last)
/// - Age band (21-25, 26-30, later: teens)
/// - Interests (multi-select chips)
/// - Selfie verified flag (placeholder for image picker)
///
/// Flow: After completion → /onboarding/sailing
///
/// TODO: Add image picker for selfie verification
/// TODO: Save profile data to Firestore
class OnboardingProfileScreen extends StatefulWidget {
  const OnboardingProfileScreen({super.key});

  @override
  State<OnboardingProfileScreen> createState() =>
      _OnboardingProfileScreenState();
}

class _OnboardingProfileScreenState extends State<OnboardingProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  String? _selectedAgeBand;
  final List<String> _ageBands = ['21-25', '26-30'];

  final List<String> _availableInterests = [
    'Nightlife',
    'Fitness',
    'Excursions',
    'Relaxation',
    'Food & Dining',
    'Sports',
    'Photography',
    'Music',
  ];

  final Set<String> _selectedInterests = {};
  bool _selfieVerified = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _handleContinue() {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedAgeBand == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select your age band')),
      );
      return;
    }

    if (_selectedInterests.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one interest')),
      );
      return;
    }

    // TODO: Save profile data to Firestore
    // Navigate to sailing selection
    context.go('/onboarding/sailing');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Complete Your Profile'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Progress Indicator
                LinearProgressIndicator(
                  value: 1 / 3, // Step 1 of 3
                  backgroundColor: Colors.grey[200],
                ),
                const SizedBox(height: 32),

                // Header
                const Text(
                  'Tell us about yourself',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Help us connect you with the right people',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 32),

                // Name Field
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    prefixIcon: Icon(Icons.person),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Age Band Selection
                const Text(
                  'Age Band',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  children: _ageBands.map((ageBand) {
                    final isSelected = _selectedAgeBand == ageBand;
                    return ChoiceChip(
                      label: Text(ageBand),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          _selectedAgeBand = selected ? ageBand : null;
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),

                // Interests Selection
                const Text(
                  'Interests (select at least one)',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _availableInterests.map((interest) {
                    final isSelected = _selectedInterests.contains(interest);
                    return FilterChip(
                      label: Text(interest),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedInterests.add(interest);
                          } else {
                            _selectedInterests.remove(interest);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),

                // Selfie Verification (Placeholder)
                Card(
                  child: ListTile(
                    leading: Icon(
                      _selfieVerified ? Icons.check_circle : Icons.camera_alt,
                      color: _selfieVerified ? Colors.green : null,
                    ),
                    title: const Text('Selfie Verification'),
                    subtitle: Text(_selfieVerified
                        ? 'Verified ✓'
                        : 'Upload a selfie (optional for now)'),
                    trailing: ElevatedButton(
                      onPressed: () {
                        // TODO: Implement image picker
                        setState(() {
                          _selfieVerified = true;
                        });
                      },
                      child: const Text('Upload'),
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
      ),
    );
  }
}
