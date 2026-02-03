import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';
import '../../widgets/app_background.dart';

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

  // Cruise line and ship data
  final Map<String, List<String>> _cruiseData = {
    'Royal Caribbean': [
      // Icon Class
      'Icon of the Seas',
      'Star of the Seas',
      'Legend of the Seas',
      // Oasis Class
      'Oasis of the Seas',
      'Allure of the Seas',
      'Harmony of the Seas',
      'Symphony of the Seas',
      'Wonder of the Seas',
      'Utopia of the Seas',
      // Quantum Class
      'Quantum of the Seas',
      'Anthem of the Seas',
      'Ovation of the Seas',
      'Spectrum of the Seas',
      'Odyssey of the Seas',
      // Freedom Class
      'Freedom of the Seas',
      'Liberty of the Seas',
      'Independence of the Seas',
      // Voyager Class
      'Voyager of the Seas',
      'Explorer of the Seas',
      'Adventure of the Seas',
      'Navigator of the Seas',
      'Mariner of the Seas',
      // Radiance Class
      'Radiance of the Seas',
      'Brilliance of the Seas',
      'Serenade of the Seas',
      'Jewel of the Seas',
      // Vision Class
      'Grandeur of the Seas',
      'Rhapsody of the Seas',
      'Enchantment of the Seas',
      'Vision of the Seas',
    ],
    'Norwegian Cruise Line': [
      'Norwegian Aqua',
      'Norwegian Viva',
      'Norwegian Prima',
      'Norwegian Encore',
      'Norwegian Bliss',
      'Norwegian Joy',
      'Norwegian Escape',
      'Norwegian Getaway',
      'Norwegian Breakaway',
      'Norwegian Epic',
      'Norwegian Gem',
      'Norwegian Pearl',
      'Norwegian Jade',
      'Norwegian Jewel',
      'Norwegian Star',
      'Norwegian Dawn',
      'Pride of America',
      'Norwegian Sun',
      'Norwegian Sky',
      'Norwegian Spirit',
    ],
    'Carnival Cruise Line': [
      // Excel Class
      'Mardi Gras',
      'Carnival Celebration',
      'Carnival Jubilee',
      // Upcoming
      'Carnival Adventure',
      'Carnival Encounter',
      // Vista Class
      'Carnival Vista',
      'Carnival Horizon',
      'Carnival Panorama',
      'Carnival Venezia',
      'Carnival Firenze',
      // Dream Class
      'Carnival Dream',
      'Carnival Magic',
      'Carnival Breeze',
      // Sunshine/Sunrise
      'Carnival Sunshine',
      'Carnival Sunrise',
      'Carnival Radiance',
      // Conquest Class
      'Carnival Conquest',
      'Carnival Glory',
      'Carnival Valor',
      'Carnival Liberty',
      'Carnival Freedom',
      // Splendor
      'Carnival Splendor',
      'Carnival Luminosa',
      // Spirit Class
      'Carnival Spirit',
      'Carnival Pride',
      'Carnival Legend',
      'Carnival Miracle',
      // Fantasy Class
      'Carnival Elation',
      'Carnival Paradise',
    ],
  };

  String? _selectedCruiseLine;
  String? _selectedShip;
  DateTime? _selectedDate;
  int? _selectedDuration;
  bool _isLoading = false;

  // Common cruise durations (nights)
  final List<int> _durations = [3, 4, 5, 6, 7, 8, 10, 12, 14];

  DateTime? get _returnDate {
    if (_selectedDate == null || _selectedDuration == null) return null;
    return _selectedDate!.add(Duration(days: _selectedDuration!));
  }

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

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

  void _showShipSelector() {
    String searchQuery = '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          final filteredShips = _availableShips
              .where((ship) => ship.toLowerCase().contains(searchQuery.toLowerCase()))
              .toList();

          return DraggableScrollableSheet(
            initialChildSize: 0.7,
            minChildSize: 0.5,
            maxChildSize: 0.9,
            expand: false,
            builder: (context, scrollController) => Column(
              children: [
                // Handle bar
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // Title
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Select Ship',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                // Search bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search ships...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    onChanged: (value) {
                      setModalState(() {
                        searchQuery = value;
                      });
                    },
                  ),
                ),
                const SizedBox(height: 8),
                // Ship count
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    '${filteredShips.length} ships available',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ),
                const SizedBox(height: 8),
                // Ship list
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: filteredShips.length,
                    itemBuilder: (context, index) {
                      final ship = filteredShips[index];
                      final isSelected = ship == _selectedShip;
                      return ListTile(
                        leading: Icon(
                          Icons.sailing,
                          color: isSelected ? Theme.of(context).primaryColor : Colors.grey,
                        ),
                        title: Text(
                          ship,
                          style: TextStyle(
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        trailing: isSelected
                            ? Icon(Icons.check, color: Theme.of(context).primaryColor)
                            : null,
                        onTap: () {
                          setState(() {
                            _selectedShip = ship;
                          });
                          Navigator.pop(context);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
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
        const SnackBar(content: Text('Please select a departure date')),
      );
      return;
    }

    if (_selectedDuration == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select your cruise duration')),
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
        durationNights: _selectedDuration!,
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
    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
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

              // Ship Selector (tap to open searchable list)
              InkWell(
                onTap: _selectedCruiseLine == null
                    ? null
                    : () => _showShipSelector(),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Ship',
                    prefixIcon: const Icon(Icons.sailing),
                    border: const OutlineInputBorder(),
                    enabled: _selectedCruiseLine != null,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _selectedShip ?? 'Select a ship',
                        style: TextStyle(
                          color: _selectedShip == null ? Colors.grey[600] : null,
                        ),
                      ),
                      Icon(Icons.arrow_drop_down, color: Colors.grey[600]),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Departure Date Picker
              Card(
                child: ListTile(
                  leading: const Icon(Icons.flight_takeoff),
                  title: const Text('Departure Date'),
                  subtitle: Text(
                    _selectedDate == null
                        ? 'Tap to select date'
                        : _formatDate(_selectedDate!),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: _selectDate,
                ),
              ),
              const SizedBox(height: 16),

              // Duration Selector
              const Text(
                'Cruise Duration',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _durations.map((nights) {
                  final isSelected = _selectedDuration == nights;
                  return ChoiceChip(
                    label: Text('$nights nights'),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedDuration = selected ? nights : null;
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // Return Date Display (calculated)
              if (_returnDate != null)
                Card(
                  color: Colors.green[50],
                  child: ListTile(
                    leading: Icon(Icons.flight_land, color: Colors.green[700]),
                    title: const Text('Return Date'),
                    subtitle: Text(
                      _formatDate(_returnDate!),
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.green[700],
                      ),
                    ),
                  ),
                ),
              if (_returnDate != null) const SizedBox(height: 16),

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
      ),
    );
  }
}
