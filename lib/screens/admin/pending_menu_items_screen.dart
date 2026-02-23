// lib/screens/admin/pending_menu_items_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/admin_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/menu_item_model.dart';
import '../../theme/neumorphic_theme.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:sendy/l10n/app_localizations.dart';

class PendingMenuItemsScreen extends StatefulWidget {
  const PendingMenuItemsScreen({Key? key}) : super(key: key);

  @override
  State<PendingMenuItemsScreen> createState() => _PendingMenuItemsScreenState();
}

class _PendingMenuItemsScreenState extends State<PendingMenuItemsScreen> {
  final Map<String, String> _restaurantNames = {};

  @override
  void initState() {
    super.initState();
    _loadRestaurantNames();
  }

  Future<void> _loadRestaurantNames() async {
    final adminProvider = context.read<AdminProvider>();
    for (var item in adminProvider.pendingMenuItems) {
      final name = await adminProvider.getRestaurantName(item.restaurantId);
      if (mounted) {
        setState(() {
          _restaurantNames[item.restaurantId] = name;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final adminProvider = Provider.of<AdminProvider>(context);
    final items = adminProvider.pendingMenuItems;

    return Scaffold(
      backgroundColor: NeuColors.background,
      appBar: AppBar(
        title: Text(l10n.pendingDishes),
        backgroundColor: NeuColors.accent,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: items.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.restaurant_menu,
                      size: 80, color: NeuColors.textHint),
                  const SizedBox(height: 16),
                  Text(
                    l10n.noPendingDishes,
                    style: const TextStyle(fontSize: 18, color: NeuColors.textSecondary),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return _MenuItemApprovalCard(
                  menuItem: item,
                  restaurantName:
                      _restaurantNames[item.restaurantId] ?? '...',
                );
              },
            ),
    );
  }
}

class _MenuItemApprovalCard extends StatelessWidget {
  final MenuItem menuItem;
  final String restaurantName;

  const _MenuItemApprovalCard({
    required this.menuItem,
    required this.restaurantName,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: NeuDecoration.raised(),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header with restaurant info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.purple.withOpacity(0.1),
              ),
              child: Row(
                children: [
                  const Icon(Icons.restaurant, color: Colors.purple, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          restaurantName,
                          style: const TextStyle(
                            fontSize: 14,
                            color: NeuColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          menuItem.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: NeuColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      l10n.pendingStatusLabel,
                      style: const TextStyle(
                        color: Colors.orange,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Menu Item Image
            if (menuItem.imageUrl != null) ...[
              const Divider(height: 1),
              GestureDetector(
                onTap: () =>
                    _showFullImage(context, menuItem.imageUrl!, menuItem.name),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: CachedNetworkImage(
                    imageUrl: menuItem.imageUrl!,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: NeuColors.background,
                      child: const Center(child: CircularProgressIndicator()),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: NeuColors.background,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error, size: 50, color: NeuColors.error),
                          const SizedBox(height: 8),
                          Text(l10n.imageLoadError),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.zoom_in, size: 16, color: NeuColors.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      l10n.tapToEnlarge,
                      style: const TextStyle(fontSize: 12, color: NeuColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ] else ...[
              Container(
                height: 200,
                color: NeuColors.background,
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.image_not_supported,
                        size: 60, color: NeuColors.textHint),
                    SizedBox(height: 8),
                    Text(
                      'Pas d\'image',
                      style: TextStyle(color: NeuColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],

            // Item Details
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Description
                  Text(
                    l10n.description,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: NeuColors.textPrimary),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    menuItem.description,
                    style: const TextStyle(color: NeuColors.textSecondary),
                  ),
                  const SizedBox(height: 16),

                  // Info Grid
                  Row(
                    children: [
                      Expanded(
                        child: _buildInfoCard(
                          l10n.price,
                          '${menuItem.price.toStringAsFixed(2)} ${l10n.dhs}',
                          Icons.euro,
                          Colors.green,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildInfoCard(
                          l10n.category,
                          menuItem.category,
                          Icons.category,
                          Colors.blue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow(
                    Icons.calendar_today,
                    l10n.createdOn,
                    _formatDate(menuItem.createdAt),
                  ),
                ],
              ),
            ),

            // Warning if no image
            if (menuItem.imageUrl == null) ...[
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber, color: Colors.orange[700]),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        l10n.noImageWarning,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Action Buttons
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showRejectDialog(context),
                      icon: const Icon(Icons.close),
                      label: Text(l10n.reject),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _approveMenuItem(context),
                      icon: const Icon(Icons.check),
                      label: Text(l10n.approve),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(
      String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: NeuDecoration.raised(radius: 8),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: NeuColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: NeuColors.textSecondary),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: const TextStyle(fontWeight: FontWeight.w500, color: NeuColors.textPrimary),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: NeuColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} a ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  void _showFullImage(BuildContext context, String imageUrl, String title) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              title: Text(title),
              backgroundColor: NeuColors.accent,
              foregroundColor: Colors.white,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            Expanded(
              child: InteractiveViewer(
                panEnabled: true,
                minScale: 0.5,
                maxScale: 4,
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.contain,
                  placeholder: (context, url) => const Center(
                    child: CircularProgressIndicator(),
                  ),
                  errorWidget: (context, url, error) => const Center(
                    child: Icon(Icons.error, size: 50, color: NeuColors.error),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _approveMenuItem(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.confirmApproval),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.confirmApproveDish),
            const SizedBox(height: 12),
            Text(
              menuItem.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text('${l10n.price}: ${menuItem.price.toStringAsFixed(2)} ${l10n.dhs}'),
            Text('${l10n.restaurant}: $restaurantName'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: Text(l10n.approve),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final authProvider = context.read<AuthProvider>();
      final adminUid = authProvider.currentUser?.uid ?? '';

      final success = await context.read<AdminProvider>().approveMenuItem(
            menuItem.id,
            adminUid,
          );

      if (success && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.dishApprovedSuccess),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  void _showRejectDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.rejectDish),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(menuItem.name),
            const SizedBox(height: 4),
            Text(
              restaurantName,
              style: const TextStyle(fontSize: 12, color: NeuColors.textSecondary),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: InputDecoration(
                labelText: l10n.rejectionReason,
                border: const OutlineInputBorder(),
                hintText: l10n.rejectionReasonHint,
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              if (reasonController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(l10n.enterReason),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              Navigator.pop(context);

              final authProvider = context.read<AuthProvider>();
              final adminUid = authProvider.currentUser?.uid ?? '';

              final success =
                  await context.read<AdminProvider>().rejectMenuItem(
                        menuItem.id,
                        reasonController.text.trim(),
                        adminUid,
                      );

              if (success && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(l10n.dishRejected),
                    backgroundColor: Colors.orange,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(l10n.reject),
          ),
        ],
      ),
    );
  }
}
