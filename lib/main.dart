import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:provider/provider.dart';
import 'package:sendy/l10n/app_localizations.dart';
import 'providers/auth_provider.dart';
import 'providers/order_provider.dart';
import 'providers/location_provider.dart';
import 'providers/menu_provider.dart';
import 'providers/admin_provider.dart';
import 'models/user_model.dart';
import 'screens/splash_screen.dart';
import 'screens/auth/phone_auth_screen.dart';
import 'screens/client/client_home_screen.dart';
import 'screens/delivery/delivery_home_screen.dart';
import 'screens/restaurant/restaurant_home_screen.dart';
import 'screens/admin/admin_panel_screen.dart';
import 'screens/waiting_approval_screen.dart';
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

  // Add error handling for initialization
  try {
    await Firebase.initializeApp();
    print('✅ Firebase initialized');

    // COMMENT OUT APP CHECK FOR NOW - IT'S CAUSING ISSUES
    await FirebaseAppCheck.instance.activate(
      androidProvider: AndroidProvider.debug,
    );

    // Initialize notifications
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    await NotificationService().initialize();
    print('✅ Notifications initialized');
  } catch (e, stackTrace) {
    print('❌ Error initializing app: $e');
    print('Stack trace: $stackTrace');
  }

  runApp(const MyApp());
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

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isInitialized = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    print('🟢 [AUTH_WRAPPER] initState');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeApp();
    });
  }

  Future<void> _initializeApp() async {
    if (_isInitialized) return;

    try {
      print('🟢 [AUTH_WRAPPER] Initializing...');

      final authProvider = context.read<AuthProvider>();

      print(
          '🟢 [AUTH_WRAPPER] Current user: ${authProvider.currentUser?.phoneNumber}');
      print(
          '🟢 [AUTH_WRAPPER] User type: ${authProvider.currentUser?.userType}');

      setState(() {
        _isInitialized = true;
      });

      // ✅ FIX: Initialize location AFTER UI renders (in background)
      if (authProvider.currentUser?.userType == UserType.delivery) {
        print(
            '🟢 [AUTH_WRAPPER] Scheduling location initialization for delivery user');
        Future.delayed(const Duration(milliseconds: 500), () {
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
    } catch (e, stackTrace) {
      print('❌ [AUTH_WRAPPER] Init error: $e');
      print('Stack: $stackTrace');
      setState(() {
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    print('🟢 [AUTH_WRAPPER] Building...');

    if (_error != null) {
      return _buildErrorScreen(_error!);
    }

    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        try {
          final user = authProvider.currentUser;

          print('🟢 [AUTH_WRAPPER] Build - User: ${user?.phoneNumber}');
          print('🟢 [AUTH_WRAPPER] Build - UserType: ${user?.userType}');
          print('🟢 [AUTH_WRAPPER] Build - IsAdmin: ${user?.isAdmin}');

          if (user == null) {
            print('🟢 [AUTH_WRAPPER] No user');
            final firebaseUser = FirebaseAuth.instance.currentUser;
            if (firebaseUser != null) {
              print('🟢 [AUTH_WRAPPER] Firebase user exists → SplashScreen');
              return const SplashScreen();
            }
            print('🟢 [AUTH_WRAPPER] No Firebase user → PhoneAuthScreen');
            return const PhoneAuthScreen();
          }

          print('🟢 [AUTH_WRAPPER] Checking admin...');
          if (user.userType == UserType.admin) {
            print('✅ [AUTH_WRAPPER] IS ADMIN → AdminPanelScreen');
            return const AdminPanelScreen();
          }

          if ((user.userType == UserType.delivery ||
                  user.userType == UserType.restaurant) &&
              user.approvalStatus != ApprovalStatus.approved) {
            print('🟢 [AUTH_WRAPPER] Needs approval → WaitingApprovalScreen');
            return WaitingApprovalScreen(
              userType: user.userType,
              isRejected: user.isRejected,
            );
          }

          print('🟢 [AUTH_WRAPPER] Routing by type: ${user.userType}');
          switch (user.userType) {
            case UserType.client:
              print('🟢 [AUTH_WRAPPER] → ClientHomeScreen');
              return const ClientHomeScreen();
            case UserType.delivery:
              print('🟢 [AUTH_WRAPPER] → DeliveryHomeScreen');
              return const DeliveryHomeScreen();
            case UserType.restaurant:
              print('🟢 [AUTH_WRAPPER] → RestaurantHomeScreen');
              return const RestaurantHomeScreen();
            case UserType.admin:
              print('🟢 [AUTH_WRAPPER] → AdminPanelScreen (switch)');
              return const AdminPanelScreen();
          }
        } catch (e, stackTrace) {
          print('❌ [AUTH_WRAPPER] Build error: $e');
          print('Stack: $stackTrace');
          return _buildErrorScreen('Erreur de navigation: $e');
        }
      },
    );
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
                      _isInitialized = false;
                    });
                    _initializeApp();
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
