// lib/screens/admin/pending_image_changes_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:sendy/l10n/app_localizations.dart';
import '../../providers/admin_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/user_model.dart';

class PendingImageChangesScreen extends StatefulWidget {
  const PendingImageChangesScreen({Key? key}) : super(key: key);

  @override
  State<PendingImageChangesScreen> createState() =>
      _PendingImageChangesScreenState();
}

class _PendingImageChangesScreenState extends State<PendingImageChangesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().loadPendingImageChanges();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final adminProvider = Provider.of<AdminProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.pendingImageChanges),
        backgroundColor: const Color(0xFFFF5722),
      ),
      body: adminProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : adminProvider.pendingImageUsers.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.image_not_supported,
                          size: 80, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        l10n.noProfileImage,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () =>
                      adminProvider.loadPendingImageChanges(),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: adminProvider.pendingImageUsers.length,
                    itemBuilder: (context, index) {
                      final user = adminProvider.pendingImageUsers[index];
                      return _buildImageChangeCard(
                          context, user, adminProvider, authProvider, l10n);
                    },
                  ),
                ),
    );
  }

  Widget _buildImageChangeCard(
    BuildContext context,
    UserModel user,
    AdminProvider adminProvider,
    AuthProvider authProvider,
    AppLocalizations l10n,
  ) {
    final isRestaurant = user.userType == UserType.restaurant;
    final typeName = isRestaurant
        ? (user.restaurantName ?? l10n.restaurant)
        : l10n.deliveryPerson;

    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User info
            Row(
              children: [
                Icon(
                  isRestaurant ? Icons.restaurant : Icons.delivery_dining,
                  color: const Color(0xFFFF5722),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        typeName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        user.phoneNumber,
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),

            // Image comparison
            Row(
              children: [
                // Current image
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        l10n.currentImage,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: user.profileImageUrl != null
                            ? CachedNetworkImage(
                                imageUrl: user.profileImageUrl!,
                                height: 120,
                                width: 120,
                                fit: BoxFit.cover,
                                placeholder: (_, __) =>
                                    const CircularProgressIndicator(),
                                errorWidget: (_, __, ___) =>
                                    const Icon(Icons.broken_image, size: 60),
                              )
                            : Container(
                                height: 120,
                                width: 120,
                                color: Colors.grey[200],
                                child: Icon(Icons.person,
                                    size: 60, color: Colors.grey[400]),
                              ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward, color: Colors.grey),
                // New image
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        l10n.newImage,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: user.pendingProfileImageUrl != null
                            ? CachedNetworkImage(
                                imageUrl: user.pendingProfileImageUrl!,
                                height: 120,
                                width: 120,
                                fit: BoxFit.cover,
                                placeholder: (_, __) =>
                                    const CircularProgressIndicator(),
                                errorWidget: (_, __, ___) =>
                                    const Icon(Icons.broken_image, size: 60),
                              )
                            : Container(
                                height: 120,
                                width: 120,
                                color: Colors.grey[200],
                                child: const Icon(Icons.image, size: 60),
                              ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showRejectDialog(
                        context, user, adminProvider, authProvider, l10n),
                    icon: const Icon(Icons.close, color: Colors.red),
                    label: Text(l10n.reject,
                        style: const TextStyle(color: Colors.red)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.red),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final success = await adminProvider.approveImageChange(
                        user.uid,
                        authProvider.currentUser!.uid,
                      );
                      if (mounted && success) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(l10n.imageApproved)),
                        );
                      }
                    },
                    icon: const Icon(Icons.check),
                    label: Text(l10n.approve),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showRejectDialog(
    BuildContext context,
    UserModel user,
    AdminProvider adminProvider,
    AuthProvider authProvider,
    AppLocalizations l10n,
  ) {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.rejectImage),
        content: TextField(
          controller: reasonController,
          decoration: InputDecoration(
            labelText: l10n.rejectionReason,
            hintText: l10n.rejectionReasonHint,
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              if (reasonController.text.isEmpty) return;
              Navigator.pop(context);
              final success = await adminProvider.rejectImageChange(
                user.uid,
                reasonController.text,
                authProvider.currentUser!.uid,
              );
              if (mounted && success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.imageRejected)),
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
