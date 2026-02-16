// lib/screens/restaurant/menu_management_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/menu_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/menu_item_model.dart';
import 'add_menu_item_screen.dart';
import 'edit_menu_item_screen.dart';

class MenuManagementScreen extends StatefulWidget {
  const MenuManagementScreen({Key? key}) : super(key: key);

  @override
  State<MenuManagementScreen> createState() => _MenuManagementScreenState();
}

class _MenuManagementScreenState extends State<MenuManagementScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadMenu();
    });
  }

  Future<void> _loadMenu() async {
    final authProvider = context.read<AuthProvider>();
    final menuProvider = context.read<MenuProvider>();

    if (authProvider.currentUser?.uid != null) {
      await menuProvider.loadMenuItems(authProvider.currentUser!.uid);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final menuProvider = Provider.of<MenuProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion du Menu'),
        backgroundColor: const Color(0xFFFF5722),
      ),
      body: menuProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadMenu,
              child: _buildMenuList(menuProvider, authProvider),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddMenuItemScreen(),
            ),
          );
          if (result == true) {
            _loadMenu();
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('Ajouter un plat'),
        backgroundColor: const Color(0xFFFF5722),
      ),
    );
  }

  Widget _buildMenuList(MenuProvider menuProvider, AuthProvider authProvider) {
    if (menuProvider.menuItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.restaurant_menu, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            const Text(
              'Aucun plat dans le menu',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            const Text(
              'Ajoutez votre premier plat',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          const TabBar(
            labelColor: Color(0xFFFF5722),
            unselectedLabelColor: Colors.grey,
            indicatorColor: Color(0xFFFF5722),
            tabs: [
              Tab(text: 'Approuvés'),
              Tab(text: 'En attente'),
              Tab(text: 'Rejetés'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildItemsList(menuProvider.approvedItems, authProvider),
                _buildItemsList(menuProvider.pendingItems, authProvider),
                _buildItemsList(menuProvider.rejectedItems, authProvider),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemsList(List<MenuItem> items, AuthProvider authProvider) {
    if (items.isEmpty) {
      return const Center(
        child: Text(
          'Aucun plat dans cette catégorie',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return _buildMenuItem(item, authProvider);
      },
    );
  }

  Widget _buildMenuItem(MenuItem item, AuthProvider authProvider) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      elevation: 2,
      child: Column(
        children: [
          ListTile(
            leading: item.imageUrl != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      item.imageUrl!,
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 60,
                          height: 60,
                          color: Colors.grey[300],
                          child: const Icon(Icons.restaurant),
                        );
                      },
                    ),
                  )
                : Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.restaurant, size: 30),
                  ),
            title: Text(
              item.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '${item.price.toStringAsFixed(2)} €',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFF5722),
                  ),
                ),
                if (item.status == MenuItemStatus.rejected &&
                    item.rejectionReason != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'Raison: ${item.rejectionReason}',
                      style: const TextStyle(
                        color: Colors.red,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
            trailing: _buildStatusBadge(item.status),
          ),
          if (item.status == MenuItemStatus.approved)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Text('Disponible'),
                      Switch(
                        value: item.isAvailable,
                        activeColor: const Color(0xFFFF5722),
                        onChanged: (value) {
                          context.read<MenuProvider>().toggleAvailability(
                                item.id,
                                authProvider.currentUser!.uid,
                                item.isAvailable,
                              );
                        },
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  EditMenuItemScreen(menuItem: item),
                            ),
                          );
                          if (result == true) {
                            _loadMenu();
                          }
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _confirmDelete(item, authProvider),
                      ),
                    ],
                  ),
                ],
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _confirmDelete(item, authProvider),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(MenuItemStatus status) {
    Color color;
    String text;
    IconData icon;

    switch (status) {
      case MenuItemStatus.approved:
        color = Colors.green;
        text = 'Approuvé';
        icon = Icons.check_circle;
        break;
      case MenuItemStatus.pending:
        color = Colors.orange;
        text = 'En attente';
        icon = Icons.pending;
        break;
      case MenuItemStatus.rejected:
        color = Colors.red;
        text = 'Rejeté';
        icon = Icons.cancel;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(MenuItem item, AuthProvider authProvider) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: Text('Voulez-vous vraiment supprimer "${item.name}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Supprimer',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await context.read<MenuProvider>().deleteMenuItem(
            item.id,
            authProvider.currentUser!.uid,
          );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Plat supprimé avec succès')),
        );
      }
    }
  }
}
