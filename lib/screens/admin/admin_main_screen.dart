// lib/screens/admin/admin_main_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sendy/l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../providers/client_provider.dart';
import '../client/restaurants_list_screen.dart';
import '../client/search_screen.dart';
import '../client/my_orders_screen.dart';
import '../client/cart_screen.dart';
import 'admin_panel_screen.dart';

class AdminMainScreen extends StatefulWidget {
  const AdminMainScreen({Key? key}) : super(key: key);

  @override
  State<AdminMainScreen> createState() => _AdminMainScreenState();
}

class _AdminMainScreenState extends State<AdminMainScreen> {
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
      const AdminPanelScreen(),
      const _ClientOrderingView(),
      const MyOrdersScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFFFF5722),
        unselectedItemColor: Colors.grey,
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.admin_panel_settings),
            label: l10n.administration,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.shopping_bag),
            label: l10n.orderFood,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.receipt_long),
            label: l10n.myOrders,
          ),
        ],
      ),
    );
  }
}

/// Client ordering view for admin users
class _ClientOrderingView extends StatefulWidget {
  const _ClientOrderingView({Key? key}) : super(key: key);

  @override
  State<_ClientOrderingView> createState() => _ClientOrderingViewState();
}

class _ClientOrderingViewState extends State<_ClientOrderingView> {
  int _tabIndex = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final tabs = [
      const RestaurantsListScreen(),
      const SearchScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('SENDY'),
        backgroundColor: const Color(0xFFFF5722),
        foregroundColor: Colors.white,
        actions: [
          _buildCartIcon(context),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _tabIndex = 0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: _tabIndex == 0
                                ? const Color(0xFFFF5722)
                                : Colors.transparent,
                            width: 3,
                          ),
                        ),
                      ),
                      child: Text(
                        l10n.restaurants,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _tabIndex == 0
                              ? const Color(0xFFFF5722)
                              : Colors.grey,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _tabIndex = 1),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: _tabIndex == 1
                                ? const Color(0xFFFF5722)
                                : Colors.transparent,
                            width: 3,
                          ),
                        ),
                      ),
                      child: Text(
                        l10n.search,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _tabIndex == 1
                              ? const Color(0xFFFF5722)
                              : Colors.grey,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: IndexedStack(
              index: _tabIndex,
              children: tabs,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartIcon(BuildContext context) {
    return Stack(
      children: [
        IconButton(
          icon: const Icon(Icons.shopping_cart),
          onPressed: () {
            final clientProvider = context.read<ClientProvider>();
            if (clientProvider.cart.isNotEmpty) {
              final restaurantId =
                  clientProvider.cart.values.first.menuItem.restaurantId;
              clientProvider
                  .getRestaurantById(restaurantId)
                  .then((restaurant) {
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
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                constraints: const BoxConstraints(
                  minWidth: 16,
                  minHeight: 16,
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
    );
  }
}
