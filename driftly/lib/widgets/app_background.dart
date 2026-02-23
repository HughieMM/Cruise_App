import 'package:flutter/material.dart';

/// Reusable ocean-themed background for the entire app
class AppBackground extends StatelessWidget {
  final Widget child;
  final bool showOverlay;
  final double overlayOpacity;

  const AppBackground({
    super.key,
    required this.child,
    this.showOverlay = true,
    this.overlayOpacity = 0.3,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/images/background.png'),
          fit: BoxFit.cover,
        ),
      ),
      child: showOverlay
          ? Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(overlayOpacity),
              ),
              child: child,
            )
          : child,
    );
  }
}

/// Scaffold with the app background built-in
class AppScaffold extends StatelessWidget {
  final Widget body;
  final PreferredSizeWidget? appBar;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;
  final bool showOverlay;
  final double overlayOpacity;
  final bool extendBodyBehindAppBar;

  const AppScaffold({
    super.key,
    required this.body,
    this.appBar,
    this.floatingActionButton,
    this.bottomNavigationBar,
    this.showOverlay = true,
    this.overlayOpacity = 0.3,
    this.extendBodyBehindAppBar = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: extendBodyBehindAppBar,
      appBar: appBar,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar,
      body: AppBackground(
        showOverlay: showOverlay,
        overlayOpacity: overlayOpacity,
        child: body,
      ),
    );
  }
}
