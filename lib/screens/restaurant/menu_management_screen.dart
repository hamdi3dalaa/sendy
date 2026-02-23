// lib/screens/restaurant/menu_management_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sendy/l10n/app_localizations.dart';
import '../../providers/menu_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/menu_item_model.dart';
import 'add_menu_item_screen.dart';
import 'edit_menu_item_screen.dart';
import '../../theme/neumorphic_theme.dart';

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
    final l10n = AppLocalizations.of(context)!;
    final authProvider = Provider.of<AuthProvider>(context);
    final menuProvider = Provider.of<MenuProvider>(context);

    return Scaffold(
      backgroundColor: NeuColors.background,
      appBar: AppBar(
        title: Text(l10n.menuManagement),
        backgroundColor: NeuColors.accent,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: menuProvider.isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(NeuColors.accent),
              ),
            )
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
        label: Text(l10n.addDish),
        backgroundColor: NeuColors.accent,
      ),
    );
  }

  Widget _buildMenuList(MenuProvider menuProvider, AuthProvider authProvider) {
    final l10n = AppLocalizations.of(context)!;
    if (menuProvider.menuItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.restaurant_menu,
                size: 80, color: NeuColors.textHint),
            const SizedBox(height: 16),
            Text(
              l10n.noDishesInMenu,
              style:
                  const TextStyle(fontSize: 18, color: NeuColors.textSecondary),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.addFirstDish,
              style: const TextStyle(color: NeuColors.textHint),
            ),
          ],
        ),
      );
    }

    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          TabBar(
            labelColor: NeuColors.accent,
            unselectedLabelColor: NeuColors.textHint,
            indicatorColor: NeuColors.accent,
            tabs: [
              Tab(text: l10n.approvedItems),
              Tab(text: l10n.pendingItems),
              Tab(text: l10n.rejectedItems),
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
    final l10n = AppLocalizations.of(context)!;
    if (items.isEmpty) {
      return Center(
        child: Text(
          l10n.noDishesInCategory,
          style: const TextStyle(color: NeuColors.textHint),
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
    final l10n = AppLocalizations.of(context)!;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      decoration: NeuDecoration.raised(radius: 12),
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
                          color: NeuColors.background,
                          child: const Icon(Icons.restaurant,
                              color: NeuColors.textHint),
                        );
                      },
                    ),
                  )
                : Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: NeuColors.background,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.restaurant,
                        size: 30, color: NeuColors.textHint),
                  ),
            title: Text(
              item.name,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: NeuColors.textPrimary),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: NeuColors.textSecondary),
                ),
                const SizedBox(height: 4),
                Text(
                  '${item.price.toStringAsFixed(2)} ${l10n.dhs}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: NeuColors.accent,
                  ),
                ),
                if (item.status == MenuItemStatus.rejected &&
                    item.rejectionReason != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '${l10n.reason}: ${item.rejectionReason}',
                      style: const TextStyle(
                        color: NeuColors.error,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
            trailing: _buildStatusBadge(item.status, l10n),
          ),
          if (item.status == MenuItemStatus.approved)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(l10n.available,
                          style:
                              const TextStyle(color: NeuColors.textSecondary)),
                      Switch(
                        value: item.isAvailable,
                        activeColor: NeuColors.accent,
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
                        icon: const Icon(Icons.delete, color: NeuColors.error),
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
                    icon: const Icon(Icons.delete, color: NeuColors.error),
                    onPressed: () => _confirmDelete(item, authProvider),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(MenuItemStatus status, AppLocalizations l10n) {
    Color color;
    String text;
    IconData icon;

    switch (status) {
      case MenuItemStatus.approved:
        color = NeuColors.success;
        text = l10n.approved;
        icon = Icons.check_circle;
        break;
      case MenuItemStatus.pending:
        color = Colors.orange;
        text = l10n.pending;
        icon = Icons.pending;
        break;
      case MenuItemStatus.rejected:
        color = NeuColors.error;
        text = l10n.rejected;
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
              style: TextStyle(color: NeuColors.error),
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
