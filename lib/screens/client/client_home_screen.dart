// lib/screens/client/client_home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sendy/l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../providers/client_provider.dart';
import '../../theme/neumorphic_theme.dart';
import 'restaurants_list_screen.dart';
import 'my_orders_screen.dart';
import 'search_screen.dart';
import 'profile_screen.dart';
import 'cart_screen.dart';

class ClientHomeScreen extends StatefulWidget {
  const ClientHomeScreen({Key? key}) : super(key: key);

  @override
  State<ClientHomeScreen> createState() => _ClientHomeScreenState();
}

class _ClientHomeScreenState extends State<ClientHomeScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = context.read<AuthProvider>();
      final clientProvider = context.read<ClientProvider>();
      if (authProvider.currentUser != null) {
        clientProvider.loadFavorites(authProvider.currentUser!.uid);
        clientProvider.loadAddresses(authProvider.currentUser!.uid);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final List<Widget> screens = [
      const RestaurantsListScreen(),
      const SearchScreen(),
      const MyOrdersScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      backgroundColor: NeuColors.background,
      appBar: AppBar(
        title: const Text(
          'SENDY',
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.5),
        ),
        backgroundColor: NeuColors.accent,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart),
                onPressed: () {
                  final clientProvider = context.read<ClientProvider>();
                  if (clientProvider.cart.isNotEmpty) {
                    final restaurantId = clientProvider.cart.values.first.menuItem.restaurantId;
                    clientProvider.getRestaurantById(restaurantId).then((restaurant) {
                      if (restaurant != null && mounted) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CartScreen(restaurant: restaurant),
                          ),
                        );
                      }
                    });
                  }
                },
              ),
              Positioned(
                right: 8,
                top: 8,
                child: Consumer<ClientProvider>(
                  builder: (context, clientProvider, _) {
                    final count = clientProvider.cartItemCount;
                    if (count == 0) return const SizedBox();
                    return Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.red.withOpacity(0.4),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 18,
                        minHeight: 18,
                      ),
                      child: Text(
                        count.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: screens,
      ),
      bottomNavigationBar: Container(
        decoration: neuBottomNavDecoration(),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: NeuColors.background,
          selectedItemColor: NeuColors.accent,
          unselectedItemColor: NeuColors.textHint,
          selectedFontSize: 12,
          unselectedFontSize: 11,
          elevation: 0,
          items: [
            BottomNavigationBarItem(
              icon: const Icon(Icons.home_rounded),
              label: l10n.home,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.search_rounded),
              label: l10n.search,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.receipt_long_rounded),
              label: l10n.myOrders,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.person_rounded),
              label: l10n.profile,
            ),
          ],
        ),
      ),
    );
  }
}
