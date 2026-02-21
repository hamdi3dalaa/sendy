import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sendy/l10n/app_localizations.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../providers/auth_provider.dart';
import '../../providers/menu_provider.dart';
import '../../models/user_model.dart';
import 'menu_management_screen.dart';
import 'invoice_history_screen.dart';
import '../../models/order_model.dart';
import '../../providers/order_provider.dart';

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
    final orderProvider = context.read<OrderProvider>();

    if (authProvider.currentUser?.uid != null) {
      // Load menu and orders in parallel
      await Future.wait([
        menuProvider.loadMenuItems(authProvider.currentUser!.uid),
        // ✅ Load restaurant orders
        _loadRestaurantOrders(orderProvider, authProvider.currentUser!.uid),
      ]).then((_) {
        if (mounted) {
          setState(() {
            _isInitialized = true;
          });
        }
      }).catchError((error) {
        print('Error loading data: $error');
        if (mounted) {
          setState(() {
            _isInitialized = true;
          });
        }
      });
    }
  }

  Future<void> _loadRestaurantOrders(
      OrderProvider orderProvider, String restaurantId) async {
    try {
      // You can implement this in OrderProvider or use the stream
      print('Loading orders for restaurant: $restaurantId');
    } catch (e) {
      print('Error loading orders: $e');
    }
  }

  Future<void> _refreshData() async {
    final authProvider = context.read<AuthProvider>();
    final menuProvider = context.read<MenuProvider>();
    final orderProvider = context.read<OrderProvider>();

    if (authProvider.currentUser?.uid != null) {
      await Future.wait([
        menuProvider.loadMenuItems(authProvider.currentUser!.uid),
        _loadRestaurantOrders(orderProvider, authProvider.currentUser!.uid),
      ]);
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
    final authProvider = Provider.of<AuthProvider>(context);
    final restaurantUser = authProvider.currentUser != null
        ? RestaurantUser.fromUserModel(authProvider.currentUser!)
        : null;
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
          // Restaurant Header with Logo
          Center(
            child: Column(
              children: [
                GestureDetector(
                  onTap: () => _uploadLogo(context, l10n),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(50),
                        child: authProvider.currentUser?.profileImageUrl != null
                            ? CachedNetworkImage(
                                imageUrl:
                                    authProvider.currentUser!.profileImageUrl!,
                                width: 100,
                                height: 100,
                                fit: BoxFit.cover,
                                placeholder: (_, __) => Container(
                                  width: 100,
                                  height: 100,
                                  color: Colors.grey[200],
                                  child: const CircularProgressIndicator(),
                                ),
                                errorWidget: (_, __, ___) => Container(
                                  width: 100,
                                  height: 100,
                                  color: Colors.grey[200],
                                  child: const Icon(Icons.restaurant,
                                      size: 50, color: Color(0xFFFF5722)),
                                ),
                              )
                            : Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  color:
                                      const Color(0xFFFF5722).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(50),
                                ),
                                child: const Icon(Icons.restaurant,
                                    size: 50, color: Color(0xFFFF5722)),
                              ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: Color(0xFFFF5722),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.camera_alt,
                              size: 16, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
                if (authProvider.currentUser?.hasPendingImageChange == true)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.orange[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.orange[200]!),
                      ),
                      child: Text(
                        l10n.pendingImageApproval,
                        style:
                            TextStyle(fontSize: 12, color: Colors.orange[800]),
                      ),
                    ),
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

          // Invoice History Card
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.receipt_long, color: Colors.green),
              ),
              title: Text(
                l10n.invoiceHistory,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(l10n.ordersSummary),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const InvoiceHistoryScreen(),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 20),
          _buildOrdersSection(context, l10n, authProvider.currentUser!.uid),

          // Orders Section (placeholder)
          // Card(
          //   elevation: 4,
          //   shape: RoundedRectangleBorder(
          //     borderRadius: BorderRadius.circular(12),
          //   ),
          //   child: Padding(
          //     padding: const EdgeInsets.all(20),
          //     child: Column(
          //       crossAxisAlignment: CrossAxisAlignment.start,
          //       children: [
          //         Row(
          //           children: [
          //             const Icon(
          //               Icons.shopping_bag,
          //               color: Color(0xFFFF5722),
          //               size: 28,
          //             ),
          //             const SizedBox(width: 12),
          //             Text(
          //               l10n.ordersSection,
          //               style: Theme.of(context).textTheme.titleLarge?.copyWith(
          //                     fontWeight: FontWeight.bold,
          //                   ),
          //             ),
          //           ],
          //         ),
          //         const Divider(height: 24),
          //         Row(
          //           mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          //           children: [
          //             _buildStatColumn(
          //               icon: Icons.pending,
          //               label: 'En attente',
          //               count: 0,
          //               color: Colors.orange,
          //             ),
          //             _buildStatColumn(
          //               icon: Icons.check_circle,
          //               label: 'Acceptées',
          //               count: 0,
          //               color: Colors.green,
          //             ),
          //             _buildStatColumn(
          //               icon: Icons.local_shipping,
          //               label: 'En livraison',
          //               count: 0,
          //               color: Colors.blue,
          //             ),
          //           ],
          //         ),
          //         const SizedBox(height: 16),
          //         Center(
          //           child: Text(
          //             'Aucune commande active',
          //             style: TextStyle(
          //               fontSize: 14,
          //               color: Colors.grey[600],
          //             ),
          //           ),
          //         ),
          //       ],
          //     ),
          //   ),
          // ),
        ],
      ),
    );
  }

  Widget _buildOrdersSection(
      BuildContext context, AppLocalizations l10n, String restaurantId) {
    return Card(
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

            // ✅ Use StreamBuilder to get real-time order counts
            StreamBuilder<List<OrderModel>>(
              stream: context.read<OrderProvider>().getOrdersForUser(
                    restaurantId,
                    UserType.restaurant,
                  ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20.0),
                      child: CircularProgressIndicator(
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Color(0xFFFF5722)),
                      ),
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Text(
                        'Erreur: ${snapshot.error}',
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  );
                }

                final orders = snapshot.data ?? [];

                // Calculate order counts by status
                final pendingCount =
                    orders.where((o) => o.status == OrderStatus.pending).length;
                final acceptedCount = orders
                    .where((o) => o.status == OrderStatus.accepted)
                    .length;
                final inProgressCount = orders
                    .where((o) => o.status == OrderStatus.inProgress)
                    .length;

                return Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildStatColumn(
                          icon: Icons.pending,
                          label: 'En attente',
                          count: pendingCount,
                          color: Colors.orange,
                        ),
                        _buildStatColumn(
                          icon: Icons.check_circle,
                          label: 'Acceptées',
                          count: acceptedCount,
                          color: Colors.green,
                        ),
                        _buildStatColumn(
                          icon: Icons.local_shipping,
                          label: 'En livraison',
                          count: inProgressCount,
                          color: Colors.blue,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (orders.isEmpty)
                      Center(
                        child: Text(
                          'Aucune commande active',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      )
                    else
                      Center(
                        child: Text(
                          '${orders.length} commande${orders.length > 1 ? 's' : ''} au total',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _uploadLogo(BuildContext context, AppLocalizations l10n) async {
    final picker = ImagePicker();
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: Text(l10n.takePhoto),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: Text(l10n.chooseFromGallery),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    final pickedFile = await picker.pickImage(
      source: source,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );

    if (pickedFile == null || !mounted) return;

    final authProvider = context.read<AuthProvider>();
    final success =
        await authProvider.uploadProfileImage(File(pickedFile.path));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text(success ? l10n.imageUploadSuccess : l10n.imageUploadError),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
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
