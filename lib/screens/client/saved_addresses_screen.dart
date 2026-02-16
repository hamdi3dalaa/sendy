// lib/screens/client/saved_addresses_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sendy/l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../providers/client_provider.dart';

class SavedAddressesScreen extends StatelessWidget {
  const SavedAddressesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.savedAddresses),
        backgroundColor: const Color(0xFFFF5722),
      ),
      body: Consumer2<ClientProvider, AuthProvider>(
        builder: (context, clientProvider, authProvider, _) {
          final addresses = clientProvider.savedAddresses;

          if (addresses.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.location_off, size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(l10n.noSavedAddresses,
                      style: TextStyle(fontSize: 18, color: Colors.grey[600])),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: addresses.length,
            itemBuilder: (context, index) {
              final address = addresses[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF5722).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      address.label.toLowerCase().contains('maison') || address.label.toLowerCase().contains('home')
                          ? Icons.home
                          : address.label.toLowerCase().contains('bureau') || address.label.toLowerCase().contains('work')
                              ? Icons.work
                              : Icons.location_on,
                      color: const Color(0xFFFF5722),
                    ),
                  ),
                  title: Text(address.label,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(address.address,
                        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () => _confirmDelete(context, l10n, authProvider, clientProvider, address),
                  ),
                  isThreeLine: true,
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddAddressDialog(context, l10n),
        backgroundColor: const Color(0xFFFF5722),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _confirmDelete(BuildContext context, AppLocalizations l10n,
      AuthProvider authProvider, ClientProvider clientProvider, SavedAddress address) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteAddress),
        content: Text('${address.label}: ${address.address}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await clientProvider.deleteAddress(authProvider.currentUser!.uid, address.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.addressDeleted), backgroundColor: Colors.green),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${l10n.error}: $e'), backgroundColor: Colors.red),
                  );
                }
              }
            },
            child: Text(l10n.delete, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showAddAddressDialog(BuildContext context, AppLocalizations l10n) {
    final labelController = TextEditingController();
    final addressController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.addNewAddress),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: labelController,
              decoration: InputDecoration(
                labelText: l10n.addressLabel,
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.label),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: addressController,
              decoration: InputDecoration(
                labelText: l10n.deliveryAddress,
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.location_on),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              if (labelController.text.trim().isEmpty || addressController.text.trim().isEmpty) return;

              final authProvider = context.read<AuthProvider>();
              final clientProvider = context.read<ClientProvider>();

              Navigator.pop(dialogContext);
              try {
                await clientProvider.addAddress(
                  authProvider.currentUser!.uid,
                  SavedAddress(
                    id: '',
                    label: labelController.text.trim(),
                    address: addressController.text.trim(),
                    latitude: 0,
                    longitude: 0,
                  ),
                );
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${l10n.error}: $e'), backgroundColor: Colors.red),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF5722)),
            child: Text(l10n.addAddress),
          ),
        ],
      ),
    );
  }
}
