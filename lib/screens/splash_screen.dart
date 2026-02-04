// lib/screens/splash_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import '../providers/auth_provider.dart';
import '../models/user_model.dart';
import 'auth/phone_auth_screen.dart';
import 'client/client_home_screen.dart';
import 'delivery/delivery_home_screen.dart';
import 'restaurant/restaurant_home_screen.dart';
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

  @override
  void initState() {
    super.initState();

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
    await Future.delayed(const Duration(seconds: 3));

    if (!mounted) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      // User not logged in
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const PhoneAuthScreen()),
      );
    } else {
      // User logged in, check their type and approval status
      if (authProvider.currentUser != null) {
        _navigateToHome(authProvider.currentUser!);
      } else {
        // Wait for user data to load
        await Future.delayed(const Duration(milliseconds: 500));
        if (authProvider.currentUser != null) {
          _navigateToHome(authProvider.currentUser!);
        } else {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const PhoneAuthScreen()),
          );
        }
      }
    }
  }

  void _navigateToHome(UserModel user) {
    Widget homeScreen;

    // Check if user needs approval
    if (user.userType == UserType.delivery ||
        user.userType == UserType.restaurant) {
      if (user.approvalStatus == ApprovalStatus.pending) {
        homeScreen = WaitingApprovalScreen(userType: user.userType);
      } else if (user.approvalStatus == ApprovalStatus.rejected) {
        homeScreen = WaitingApprovalScreen(
          userType: user.userType,
          isRejected: true,
        );
      } else {
        homeScreen = _getHomeScreenForUserType(user.userType);
      }
    } else {
      homeScreen = _getHomeScreenForUserType(user.userType);
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => homeScreen),
    );
  }

  Widget _getHomeScreenForUserType(UserType userType) {
    switch (userType) {
      case UserType.client:
        return const ClientHomeScreen();
      case UserType.delivery:
        return const DeliveryHomeScreen();
      case UserType.restaurant:
        return const RestaurantHomeScreen();
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
