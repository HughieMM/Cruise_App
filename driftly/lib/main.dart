import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'core/router/app_router.dart';
import 'providers/auth_provider.dart';
import 'providers/tribe_provider.dart';
import 'services/notification_service.dart';
import 'theme/app_colors.dart';
import 'theme/app_text_styles.dart';

/// Driftly - A social app for cruise passengers
///
/// Main entry point for the application
void main() {
  runZonedGuarded(() async {
    // Ensure Flutter bindings are initialized
    WidgetsFlutterBinding.ensureInitialized();

    // Route framework-caught errors (widget build errors, etc.) into the
    // same zone handler below instead of only printing to the console.
    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      debugPrint('FlutterError: ${details.exceptionAsString()}\n${details.stack}');
    };

    // Initialize Firebase
    await Firebase.initializeApp();

    // Initialize notification service
    await NotificationService().initialize();

    runApp(const DriftlyApp());
  }, (error, stack) {
    debugPrint('Uncaught error: $error\n$stack');
  });
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
            primary: AppColors.teal,
            secondary: AppColors.coral,
            tertiary: AppColors.amber,
            surface: AppColors.surfaceSolid,
            onPrimary: Colors.black,
            onSecondary: Colors.white,
            onSurface: Colors.white,
          ),
          scaffoldBackgroundColor: AppColors.background,
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
            elevation: 0,
            iconTheme: IconThemeData(color: AppColors.teal),
          ),
          cardTheme: CardThemeData(
            color: AppColors.surfaceSolid,
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          bottomNavigationBarTheme: const BottomNavigationBarThemeData(
            backgroundColor: AppColors.surfaceSolid,
            selectedItemColor: AppColors.teal,
            unselectedItemColor: Colors.grey,
          ),
          dialogTheme: const DialogThemeData(
            backgroundColor: AppColors.surfaceSolid,
            surfaceTintColor: Colors.transparent,
            titleTextStyle: TextStyle(
              fontFamily: AppTextStyles.displayFontFamily,
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
            contentTextStyle: TextStyle(color: Colors.white70),
          ),
          bottomSheetTheme: const BottomSheetThemeData(
            backgroundColor: AppColors.background,
            surfaceTintColor: Colors.transparent,
            modalBackgroundColor: AppColors.background,
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: AppColors.surfaceSolid,
            labelStyle: const TextStyle(color: Colors.grey),
            hintStyle: TextStyle(color: Colors.grey[500]),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(999),
              borderSide: BorderSide(color: Colors.grey[700]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(999),
              borderSide: BorderSide(color: Colors.grey[700]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(999),
              borderSide: const BorderSide(color: AppColors.teal),
            ),
          ),
          listTileTheme: const ListTileThemeData(
            textColor: Colors.white,
            iconColor: Colors.grey,
          ),
          dividerTheme: const DividerThemeData(color: AppColors.divider),
          chipTheme: ChipThemeData(
            backgroundColor: AppColors.surfaceSolid,
            selectedColor: AppColors.tealTint,
            disabledColor: AppColors.surfaceSolid,
            labelStyle: const TextStyle(color: Colors.white),
            secondaryLabelStyle: const TextStyle(color: AppColors.teal),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(999),
              side: BorderSide(color: Colors.grey[700]!),
            ),
            checkmarkColor: AppColors.teal,
          ),
          switchTheme: SwitchThemeData(
            thumbColor: WidgetStateProperty.resolveWith(
              (states) => states.contains(WidgetState.selected)
                  ? Colors.white
                  : Colors.grey[400],
            ),
            trackColor: WidgetStateProperty.resolveWith(
              (states) => states.contains(WidgetState.selected)
                  ? AppColors.teal
                  : Colors.grey[800],
            ),
          ),
          textTheme: const TextTheme(
            displayLarge: AppTextStyles.displayLarge,
            displayMedium: AppTextStyles.displayMedium,
            displaySmall: AppTextStyles.displaySmall,
            bodyLarge: AppTextStyles.body,
            bodyMedium: AppTextStyles.bodySecondary,
            bodySmall: AppTextStyles.bodySmall,
          ),
          useMaterial3: true,
        ),
        routerConfig: AppRouter.router,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
