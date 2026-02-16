// lib/screens/restaurant/restaurant_home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sendy/l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../providers/menu_provider.dart';
import 'menu_management_screen.dart';

class RestaurantHomeScreen extends StatefulWidget {
  const RestaurantHomeScreen({Key? key}) : super(key: key);

  @override
  State<RestaurantHomeScreen> createState() => _RestaurantHomeScreenState();
}

class _RestaurantHomeScreenState extends State<RestaurantHomeScreen> {
  bool _isInitialized = false;
  bool _isLoggingOut = false;

  @override
  void initState() {
    super.initState();
    // Load menu data after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeMenu();
    });
  }

  Future<void> _initializeMenu() async {
    if (_isInitialized || !mounted) return;

    final authProvider = context.read<AuthProvider>();
    final menuProvider = context.read<MenuProvider>();

    if (authProvider.currentUser?.uid != null) {
      // Load menu in background without blocking UI
      menuProvider.loadMenuItems(authProvider.currentUser!.uid).then((_) {
        if (mounted) {
          setState(() {
            _isInitialized = true;
          });
        }
      }).catchError((error) {
        print('Error loading menu: $error');
        if (mounted) {
          setState(() {
            _isInitialized = true;
          });
        }
      });
    }
  }

  Future<void> _refreshMenu() async {
    final authProvider = context.read<AuthProvider>();
    final menuProvider = context.read<MenuProvider>();

    if (authProvider.currentUser?.uid != null) {
      await menuProvider.loadMenuItems(authProvider.currentUser!.uid);
    }
  }

  void _handleLogout() async {
    if (_isLoggingOut) return;

    // Show confirmation dialog first (non-blocking)
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Déconnexion'),
        content: const Text('Voulez-vous vraiment vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Déconnexion',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() {
      _isLoggingOut = true;
    });

    // Perform logout in background
    try {
      await context.read<AuthProvider>().signOut();
    } catch (e) {
      print('Error during logout: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la déconnexion: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoggingOut = false;
        });
      }
    }
  }

  void _navigateToMenuManagement() {
    // Use async navigation without blocking
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const MenuManagementScreen(),
      ),
    ).then((result) {
      // Refresh menu after returning (non-blocking)
      if (mounted && result == true) {
        _refreshMenu();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final authProvider = Provider.of<AuthProvider>(context);
    final menuProvider = Provider.of<MenuProvider>(context);
    final restaurantName =
        authProvider.currentUser?.restaurantName ?? 'Restaurant';

    return Scaffold(
      appBar: AppBar(
        title: Text(restaurantName),
        backgroundColor: const Color(0xFFFF5722),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshMenu,
            tooltip: l10n.refresh,
          ),
          if (_isLoggingOut)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: _handleLogout,
              tooltip: l10n.logout,
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshMenu,
        child: menuProvider.isLoading && !_isInitialized
            ? const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF5722)),
                ),
              )
            : _buildContent(context, l10n, restaurantName, menuProvider),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToMenuManagement,
        backgroundColor: const Color(0xFFFF5722),
        icon: const Icon(Icons.menu_book),
        label: Text(l10n.manageMenu),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    AppLocalizations l10n,
    String restaurantName,
    MenuProvider menuProvider,
  ) {
    final totalItems = menuProvider.menuItems.length;
    final approvedCount = menuProvider.approvedItems.length;
    final pendingCount = menuProvider.pendingItems.length;
    final rejectedCount = menuProvider.rejectedItems.length;
    final availableCount =
        menuProvider.approvedItems.where((item) => item.isAvailable).length;

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Restaurant Header
          Center(
            child: Column(
              children: [
                const Icon(
                  Icons.restaurant,
                  size: 100,
                  color: Color(0xFFFF5722),
                ),
                const SizedBox(height: 20),
                Text(
                  restaurantName,
                  style: Theme.of(context).textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Text(
                  l10n.restaurantSpace,
                  style: const TextStyle(fontSize: 18, color: Colors.grey),
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),

          // Menu Statistics Card
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.menu_book,
                        color: Color(0xFFFF5722),
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        l10n.myMenu,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const Spacer(),
                      if (totalItems > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF5722).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '$totalItems plat${totalItems > 1 ? 's' : ''}',
                            style: const TextStyle(
                              color: Color(0xFFFF5722),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const Divider(height: 24),

                  // Status Stats
                  if (totalItems > 0) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatColumn(
                          label: l10n.approvedItems,
                          count: approvedCount,
                          color: Colors.green,
                          icon: Icons.check_circle,
                        ),
                        _buildStatColumn(
                          label: l10n.pendingItems,
                          count: pendingCount,
                          color: Colors.orange,
                          icon: Icons.pending,
                        ),
                        _buildStatColumn(
                          label: l10n.rejectedItems,
                          count: rejectedCount,
                          color: Colors.red,
                          icon: Icons.cancel,
                        ),
                      ],
                    ),

                    // Available items indicator
                    if (approvedCount > 0) ...[
                      const Divider(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.visibility,
                            size: 20,
                            color: Colors.green[700],
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '$availableCount/$approvedCount plat${approvedCount > 1 ? 's' : ''} disponible${availableCount > 1 ? 's' : ''}',
                            style: TextStyle(
                              color: Colors.green[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],

                    const SizedBox(height: 16),
                  ] else ...[
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: Column(
                          children: [
                            Icon(
                              Icons.restaurant_menu,
                              size: 60,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              l10n.noMenuItems,
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              l10n.startAddingDishes,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],

                  // Manage button
                  ElevatedButton.icon(
                    onPressed: _navigateToMenuManagement,
                    icon: const Icon(Icons.edit),
                    label: Text(
                      totalItems > 0 ? l10n.manageMyMenu : l10n.createMenu,
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF5722),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),

                  // Pending items warning
                  if (pendingCount > 0) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange[200]!),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.orange[700]),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Vous avez $pendingCount plat${pendingCount > 1 ? 's' : ''} en attente d\'approbation',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.orange[900],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Rejected items warning
                  if (rejectedCount > 0) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red[200]!),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.warning_outlined, color: Colors.red[700]),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              '$rejectedCount plat${rejectedCount > 1 ? 's' : ''} rejeté${rejectedCount > 1 ? 's' : ''} - Vérifiez les raisons',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.red[900],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Orders Section (placeholder)
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.shopping_bag,
                        color: Color(0xFFFF5722),
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        l10n.ordersSection,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildStatColumn(
                        icon: Icons.pending,
                        label: 'En attente',
                        count: 0,
                        color: Colors.orange,
                      ),
                      _buildStatColumn(
                        icon: Icons.check_circle,
                        label: 'Acceptées',
                        count: 0,
                        color: Colors.green,
                      ),
                      _buildStatColumn(
                        icon: Icons.local_shipping,
                        label: 'En livraison',
                        count: 0,
                        color: Colors.blue,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: Text(
                      'Aucune commande active',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatColumn({
    required String label,
    required int count,
    required Color color,
    required IconData icon,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 8),
        Text(
          count.toString(),
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
