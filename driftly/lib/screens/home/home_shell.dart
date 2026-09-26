import 'package:flutter/material.dart';
import 'tabs/home_tab.dart';
import 'tabs/pods_tab.dart';
import 'tabs/first_mates_tab.dart';
import 'tabs/tribe_tab.dart';
import 'tabs/hangouts_tab.dart';
import 'tabs/hot_zones_tab.dart';
import 'tabs/profile_tab.dart';
import '../../theme/app_colors.dart';

/// Home Shell
///
/// Main app container with bottom navigation bar
///
/// Tabs:
/// - Home: Feed/Dashboard
/// - Pods: Pod chats and activity
/// - First Mates: Pod-only 1:1 connect requests + private messaging
/// - Tribe: Randomly matched small groups
/// - Vibes: Hot Zones location crowd/vibe voting
/// - Profile: User settings and profile
class HomeShell extends StatefulWidget {
  final String initialTab;

  const HomeShell({
    super.key,
    this.initialTab = 'home',
  });

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _currentIndex = 0;

  final List<Widget> _tabs = const [
    HomeTab(),
    PodsTab(),
    FirstMatesTab(),
    TribeTab(),
    HangoutsTab(),
    ProfileTab(),
  ];

  @override
  void initState() {
    super.initState();
    // Set initial tab based on query parameter
    _currentIndex = _getIndexFromTab(widget.initialTab);
  }

  int _getIndexFromTab(String tab) {
    switch (tab) {
      case 'home':
        return 0;
      case 'pods':
        return 1;
      case 'first_mates':
        return 2;
      case 'tribe':
        return 3;
      case 'hangouts':
      case 'vibes':
      case 'hot_zones':
        return 4;
      case 'profile':
        return 5;
      default:
        return 0;
    }
  }

  static const List<_NavItem> _navItems = [
    _NavItem(icon: Icons.home_outlined, selectedIcon: Icons.home, label: 'Home'),
    _NavItem(icon: Icons.groups_outlined, selectedIcon: Icons.groups, label: 'Pods'),
    _NavItem(icon: Icons.forum_outlined, selectedIcon: Icons.forum, label: 'Mates'),
    _NavItem(
      icon: Icons.diversity_3_outlined,
      selectedIcon: Icons.diversity_3,
      label: 'Tribe',
    ),
    _NavItem(
      icon: Icons.location_on_outlined,
      selectedIcon: Icons.location_on,
      label: 'Vibes',
    ),
    _NavItem(icon: Icons.person_outline, selectedIcon: Icons.person, label: 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(
        index: _currentIndex,
        children: _tabs,
      ),
      bottomNavigationBar: _DriftlyNavBar(
        items: _navItems,
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData selectedIcon;
  final String label;

  const _NavItem({required this.icon, required this.selectedIcon, required this.label});
}

/// Custom bottom nav bar — the active tab gets a teal icon/label plus a
/// rounded-rect outline box around just that item, which stock
/// BottomNavigationBar/NavigationBar can't express per-item.
class _DriftlyNavBar extends StatelessWidget {
  final List<_NavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _DriftlyNavBar({
    required this.items,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: const BoxDecoration(
          color: AppColors.surfaceSolid,
          border: Border(top: BorderSide(color: AppColors.divider)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(items.length, (index) {
            final item = items[index];
            final isSelected = index == currentIndex;
            return GestureDetector(
              onTap: () => onTap(index),
              behavior: HitTestBehavior.opaque,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: isSelected
                      ? Border.all(color: AppColors.tealBorder)
                      : null,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isSelected ? item.selectedIcon : item.icon,
                      color: isSelected ? AppColors.teal : Colors.grey,
                      size: 24,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.label,
                      style: TextStyle(
                        fontSize: 11,
                        color: isSelected ? AppColors.teal : Colors.grey,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
