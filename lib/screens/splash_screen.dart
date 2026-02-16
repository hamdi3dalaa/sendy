// lib/screens/splash_screen.dart
// Fixed version - properly waits for user data

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import '../providers/auth_provider.dart';
import '../models/user_model.dart';
import 'auth/phone_auth_screen.dart';
import 'client/client_home_screen.dart';
import 'delivery/delivery_home_screen.dart';
import 'restaurant/restaurant_home_screen.dart';
import 'admin/admin_panel_screen.dart';
import 'waiting_approval_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();
    print('🟡 [SPLASH] initState');

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    _animationController.forward();

    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    print('🟡 [SPLASH] Checking auth status...');

    // Wait for animation
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUser = FirebaseAuth.instance.currentUser;

    print('🟡 [SPLASH] Firebase user: ${currentUser?.uid}');
    print(
        '🟡 [SPLASH] AuthProvider user: ${authProvider.currentUser?.phoneNumber}');

    if (currentUser == null) {
      print('🟡 [SPLASH] No Firebase user → PhoneAuthScreen');
      _navigateToHome(const PhoneAuthScreen());
      return;
    }

    // User logged in, wait for UserModel to load
    print('🟡 [SPLASH] Waiting for UserModel to load...');

    // Wait up to 5 seconds for user data to load
    for (int i = 0; i < 10; i++) {
      await Future.delayed(const Duration(milliseconds: 500));

      if (!mounted) return;

      final user = authProvider.currentUser;
      print(
          '🟡 [SPLASH] Attempt ${i + 1}: User loaded: ${user != null}, Type: ${user?.userType}');

      if (user != null) {
        print('✅ [SPLASH] User loaded successfully');
        _navigateToHome(_getHomeScreen(user));
        return;
      }
    }

    // Timeout - user data didn't load
    print('❌ [SPLASH] Timeout waiting for user data');
    _navigateToHome(const PhoneAuthScreen());
  }

  void _navigateToHome(Widget screen) {
    if (_hasNavigated) return;
    _hasNavigated = true;

    print('🟡 [SPLASH] Navigating to: ${screen.runtimeType}');

    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  Widget _getHomeScreen(UserModel user) {
    print('🟡 [SPLASH] Getting home screen for user type: ${user.userType}');

    // Check if admin
    if (user.userType == UserType.admin) {
      print('✅ [SPLASH] User is admin → AdminPanelScreen');
      return const AdminPanelScreen();
    }

    // Check if needs approval
    if ((user.userType == UserType.delivery ||
            user.userType == UserType.restaurant) &&
        user.approvalStatus != ApprovalStatus.approved) {
      print('🟡 [SPLASH] User needs approval → WaitingApprovalScreen');
      return WaitingApprovalScreen(
        userType: user.userType,
        isRejected: user.isRejected,
      );
    }

    // Route by user type
    print('🟡 [SPLASH] Routing by user type: ${user.userType}');
    switch (user.userType) {
      case UserType.client:
        return const ClientHomeScreen();
      case UserType.delivery:
        return const DeliveryHomeScreen();
      case UserType.restaurant:
        return const RestaurantHomeScreen();
      case UserType.admin:
        return const AdminPanelScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFF5722),
              Color(0xFFFF7043),
              Color(0xFFFF8A65),
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Animated Logo
              ScaleTransition(
                scale: _scaleAnimation,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.delivery_dining,
                      size: 80,
                      color: Color(0xFFFF5722),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 30),

              // App Name
              FadeTransition(
                opacity: _fadeAnimation,
                child: const Text(
                  'SENDY',
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 4,
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Tagline
              FadeTransition(
                opacity: _fadeAnimation,
                child: const Text(
                  'Livraison rapide et fiable',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                    fontWeight: FontWeight.w300,
                  ),
                ),
              ),
              const SizedBox(height: 50),

              // Loading Indicator
              FadeTransition(
                opacity: _fadeAnimation,
                child: const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}
