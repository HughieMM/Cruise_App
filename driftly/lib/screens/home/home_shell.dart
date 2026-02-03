import 'package:flutter/material.dart';
import 'tabs/home_tab.dart';
import 'tabs/pods_tab.dart';
import 'tabs/hangouts_tab.dart';
import 'tabs/hot_zones_tab.dart';
import 'tabs/profile_tab.dart';
import '../../widgets/app_background.dart';

/// Home Shell
///
/// Main app container with bottom navigation bar
///
/// Tabs:
/// - Home: Feed/Dashboard
/// - Pods: Pod chats and activity
/// - Hangouts: Micro hangouts (45-minute check-ins)
/// - Hot Zones: Location crowd/vibe voting
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
    HangoutsTab(),
    HotZonesTab(),
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
      case 'hangouts':
        return 2;
      case 'hot_zones':
        return 3;
      case 'profile':
        return 4;
      default:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: IndexedStack(
          index: _currentIndex,
          children: _tabs,
        ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.groups_outlined),
            selectedIcon: Icon(Icons.groups),
            label: 'Pods',
          ),
          NavigationDestination(
            icon: Icon(Icons.location_on_outlined),
            selectedIcon: Icon(Icons.location_on),
            label: 'Hangouts',
          ),
          NavigationDestination(
            icon: Icon(Icons.whatshot_outlined),
            selectedIcon: Icon(Icons.whatshot),
            label: 'Hot Zones',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
      ),
    );
  }
}
