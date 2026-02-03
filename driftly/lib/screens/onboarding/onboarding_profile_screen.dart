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
  final List<String> _ageBands = AppConstants.ageBands;

  final List<String> _availableInterests = AppConstants.availableInterests;

  final Set<String> _selectedInterests = {};
  bool _selfieVerified = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _handleContinue() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedAgeBand == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select your age band')),
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
