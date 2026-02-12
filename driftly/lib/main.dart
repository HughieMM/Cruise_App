import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'core/router/app_router.dart';
import 'providers/auth_provider.dart';
import 'providers/tribe_provider.dart';
import 'services/notification_service.dart';

/// Driftly - A social app for cruise passengers aged 21-30
///
/// Main entry point for the application
void main() async {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp();

  // Initialize notification service
  await NotificationService().initialize();

  runApp(const DriftlyApp());
}

/// Root application widget
class DriftlyApp extends StatelessWidget {
  const DriftlyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => TribeProvider()),
      ],
      child: MaterialApp.router(
        title: 'Driftly',
        theme: ThemeData(
          brightness: Brightness.dark,
          colorScheme: ColorScheme.dark(
            primary: Colors.blue[400]!,
            secondary: Colors.blue[300]!,
            surface: const Color(0xFF1E1E1E),
            onPrimary: Colors.white,
            onSecondary: Colors.white,
            onSurface: Colors.white,
          ),
          scaffoldBackgroundColor: Colors.black,
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            elevation: 0,
          ),
          cardTheme: CardThemeData(
            color: const Color(0xFF2A2A2A),
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          bottomNavigationBarTheme: const BottomNavigationBarThemeData(
            backgroundColor: Color(0xFF1A1A1A),
            selectedItemColor: Colors.blue,
            unselectedItemColor: Colors.grey,
          ),
          useMaterial3: true,
        ),
        routerConfig: AppRouter.router,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
