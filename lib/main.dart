import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:provider/provider.dart';
import 'package:lottie/lottie.dart';
import 'package:sendy/l10n/app_localizations.dart';
import 'providers/auth_provider.dart';
import 'providers/order_provider.dart';
import 'providers/location_provider.dart';
import 'providers/menu_provider.dart';
import 'providers/admin_provider.dart';
import 'models/user_model.dart';
import 'screens/auth/phone_auth_screen.dart';
import 'screens/auth/registration_screen.dart';
import 'screens/client/client_home_screen.dart';
import 'screens/delivery/delivery_main_screen.dart';
import 'screens/restaurant/restaurant_main_screen.dart';
import 'screens/admin/admin_main_screen.dart';
import 'screens/waiting_approval_screen.dart';
import 'screens/restaurant/incoming_orders_screen.dart';
import 'screens/delivery/available_orders_screen.dart';
import 'services/notification_service.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'providers/client_provider.dart';

// Background message handler
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('Handling background message: ${message.messageId}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp();
    print('✅ Firebase initialized');

    // Register background handler (must be before runApp)
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  } catch (e, stackTrace) {
    print('❌ Error initializing Firebase: $e');
    print('Stack trace: $stackTrace');
  }

  // Run app immediately - defer heavy init to after first frame
  runApp(const MyApp());

  // Defer non-critical initialization to after the first frame renders
  // This prevents the freeze/black screen on startup
  WidgetsBinding.instance.addPostFrameCallback((_) async {
    try {
      await FirebaseAppCheck.instance.activate(
        androidProvider: AndroidProvider.playIntegrity,
        appleProvider: AppleProvider.deviceCheck,
      );

      await NotificationService().initialize();
      print('✅ Notifications initialized');
    } catch (e) {
      print('❌ Error initializing services: $e');
    }
  });
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => OrderProvider()),
        ChangeNotifierProvider(create: (_) => LocationProvider()),
        ChangeNotifierProvider(create: (_) => MenuProvider()),
        ChangeNotifierProvider(create: (_) => AdminProvider()),
        ChangeNotifierProvider(create: (_) => ClientProvider()),
      ],
      child: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          return MaterialApp(
            title: 'Sendy',
            debugShowCheckedModeBanner: false,
            navigatorKey: navigatorKey,
            locale: authProvider.locale,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('fr', ''),
              Locale('ar', ''),
            ],
            theme: ThemeData(
              primarySwatch: Colors.orange,
              fontFamily: 'Roboto',
            ),
            routes: {
              '/incoming-orders': (context) => const IncomingOrdersScreen(),
              '/available-orders': (context) => const AvailableOrdersScreen(),
            },
            home: const AuthWrapper(),
          );
        },
      ),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper>
    with TickerProviderStateMixin {
  String? _error;
  late AnimationController _lottieController;

  @override
  void initState() {
    super.initState();
    print('🟢 [AUTH_WRAPPER] initState');

    // Initialize Lottie animation controller
    _lottieController = AnimationController(vsync: this);
  }

  @override
  void dispose() {
    _lottieController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        print(
            '🟢 [AUTH_WRAPPER] Building... authReady=${authProvider.isAuthReady}');

        if (_error != null) {
          return _buildErrorScreen(_error!);
        }

        // Show branded loading screen with Lottie animation until AuthProvider has completed
        // its first auth state check (prevents black screen / freeze)
        if (!authProvider.isAuthReady) {
          return Scaffold(
            body: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFFF5722), Color(0xFFFF7043)],
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Delivery icon above animation
                    const Icon(
                      Icons.delivery_dining,
                      size: 60,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 24),

                    // 🎬 Lottie SENDY Animation
                    Lottie.asset(
                      'assets/lottie/animation.json',
                      controller: _lottieController,
                      width: 300,
                      height: 120,
                      fit: BoxFit.contain,
                      onLoaded: (composition) {
                        _lottieController
                          ..duration = composition.duration
                          ..repeat(); // Loop the animation
                      },
                    ),

                    const SizedBox(height: 32),

                    // Loading indicator
                    const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        try {
          final user = authProvider.currentUser;

          print(
              '🟢 [AUTH_WRAPPER] User: ${user?.phoneNumber}, Type: ${user?.userType}');

          if (user == null) {
            // New user signed in via OTP but no Firestore doc yet → show registration
            if (authProvider.isNewUserRegistering) {
              print(
                  '🟢 [AUTH_WRAPPER] New user registering → RegistrationScreen');
              return const RegistrationScreen();
            }
            print('🟢 [AUTH_WRAPPER] No user → PhoneAuthScreen');
            return const PhoneAuthScreen();
          }

          // Initialize location for delivery users (deferred)
          if (user.userType == UserType.delivery) {
            _initLocationIfNeeded();
          }

          if (user.userType == UserType.admin) {
            print('✅ [AUTH_WRAPPER] → AdminMainScreen');
            return const AdminMainScreen();
          }

          if ((user.userType == UserType.delivery ||
                  user.userType == UserType.restaurant) &&
              user.approvalStatus != ApprovalStatus.approved) {
            print('🟢 [AUTH_WRAPPER] → WaitingApprovalScreen');
            return WaitingApprovalScreen(
              userType: user.userType,
              isRejected: user.isRejected,
            );
          }

          print('🟢 [AUTH_WRAPPER] Routing by type: ${user.userType}');
          switch (user.userType) {
            case UserType.client:
              return const ClientHomeScreen();
            case UserType.delivery:
              return const DeliveryMainScreen();
            case UserType.restaurant:
              return const RestaurantMainScreen();
            case UserType.admin:
              return const AdminMainScreen();
          }
        } catch (e, stackTrace) {
          print('❌ [AUTH_WRAPPER] Build error: $e');
          print('Stack: $stackTrace');
          return _buildErrorScreen('Erreur de navigation: $e');
        }
      },
    );
  }

  bool _locationInitStarted = false;
  void _initLocationIfNeeded() {
    if (_locationInitStarted) return;
    _locationInitStarted = true;
    // Defer location init to avoid blocking the UI
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        context
            .read<LocationProvider>()
            .initializeLocation()
            .catchError((error) {
          print('❌ Location error: $error');
        });
      }
    });
  }

  Widget _buildErrorScreen(String error) {
    return Scaffold(
      backgroundColor: Colors.red.shade50,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 80, color: Colors.red),
                const SizedBox(height: 24),
                const Text(
                  'Erreur',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Text(
                  error,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: () {
                    try {
                      context.read<AuthProvider>().signOut();
                    } catch (e) {
                      print('Error signing out: $e');
                    }
                  },
                  icon: const Icon(Icons.logout),
                  label: const Text('Déconnexion'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF5722),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 16),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _error = null;
                    });
                  },
                  child: const Text('Réessayer'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
