import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/constants.dart';

/// Onboarding Profile Screen
///
/// Collects:
/// - Name (first & last)
/// - Age band (21-23, 24-27, 28-30)
/// - Interests (3-5 selections required)
/// - Selfie verified flag (placeholder for image picker)
///
/// Flow: After completion → /onboarding/sailing
///
/// TODO: Add image picker for selfie verification
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
  int? _verifiedAge;
  bool _ageVerified = false;
  final List<String> _ageBands = AppConstants.ageBands;

  final List<String> _availableInterests = AppConstants.availableInterests;

  final Set<String> _selectedInterests = {};
  bool _selfieVerified = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  /// Shows age verification dialog when user selects an age band
  void _showAgeVerificationDialog(String ageBand) {
    final ageController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Verify Your Age'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'You selected the $ageBand age group.',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            const Text(
              'Please enter your age to confirm:',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: ageController,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Your Age',
                hintText: 'e.g. 25',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.cake),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final ageText = ageController.text.trim();
              final age = int.tryParse(ageText);

              if (age == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a valid age')),
                );
                return;
              }

              // Verify age matches the selected band
              if (!_isAgeInBand(age, ageBand)) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Age $age doesn\'t match the $ageBand group. Please select the correct age band.'),
                    backgroundColor: Colors.red,
                  ),
                );
                Navigator.pop(context);
                return;
              }

              // Age verified!
              Navigator.pop(context);
              setState(() {
                _selectedAgeBand = ageBand;
                _verifiedAge = age;
                _ageVerified = true;
              });

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.white),
                      const SizedBox(width: 8),
                      Text('Age verified! You\'re in the $ageBand group.'),
                    ],
                  ),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Verify'),
          ),
        ],
      ),
    );
  }

  /// Check if the entered age falls within the selected age band
  bool _isAgeInBand(int age, String ageBand) {
    switch (ageBand) {
      case '14-17':
        return age >= 14 && age <= 17;
      case '18-20':
        return age >= 18 && age <= 20;
      case '21-30':
        return age >= 21 && age <= 30;
      case '31-40':
        return age >= 31 && age <= 40;
      case '40+':
        return age > 40;
      default:
        return false;
    }
  }

  Future<void> _handleContinue() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedAgeBand == null || !_ageVerified) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select and verify your age band')),
      );
      return;
    }

    // Validate 3-5 interests
    if (_selectedInterests.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least 3 interests')),
      );
      return;
    }

    if (_selectedInterests.length > 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select no more than 5 interests')),
      );
      return;
    }

    // Save profile to Firestore
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.createUserProfile(
      name: _nameController.text.trim(),
      ageBand: _selectedAgeBand!,
      interests: _selectedInterests.toList(),
      selfieVerified: _selfieVerified,
    );

    if (!mounted) return;

    if (success) {
      // Navigate to sailing selection
      context.go('/onboarding/sailing');
    } else {
      // Show error
      final error = authProvider.errorMessage ?? 'Failed to save profile';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: Colors.red,
        ),
      );
    }
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Age Band',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (_ageVerified)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.verified, color: Colors.green, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              'Age $_verifiedAge verified',
                              style: const TextStyle(
                                color: Colors.green,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
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
                        if (selected) {
                          // Show verification dialog
                          _showAgeVerificationDialog(ageBand);
                        } else {
                          // Deselecting clears verification
                          setState(() {
                            _selectedAgeBand = null;
                            _verifiedAge = null;
                            _ageVerified = false;
                          });
                        }
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),

                // Interests Selection
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Interests (select 3-5)',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${_selectedInterests.length}/5 selected',
                      style: TextStyle(
                        fontSize: 14,
                        color: _selectedInterests.length >= 3 && _selectedInterests.length <= 5
                            ? Colors.green
                            : Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
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
                Consumer<AuthProvider>(
                  builder: (context, authProvider, child) {
                    return ElevatedButton(
                      onPressed: authProvider.isLoading ? null : _handleContinue,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: authProvider.isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text(
                              'Continue',
                              style: TextStyle(fontSize: 16),
                            ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
