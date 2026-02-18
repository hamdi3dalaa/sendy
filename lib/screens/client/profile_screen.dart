// lib/screens/client/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sendy/l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../providers/client_provider.dart';
import 'saved_addresses_screen.dart';
import 'restaurant_menu_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final authProvider = Provider.of<AuthProvider>(context);
    final clientProvider = Provider.of<ClientProvider>(context);
    final user = authProvider.currentUser;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // User Info Card
          Card(
            elevation: 3,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 45,
                    backgroundColor: const Color(0xFFFF5722).withOpacity(0.1),
                    child: const Icon(Icons.person,
                        size: 50, color: Color(0xFFFF5722)),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    user?.displayName ?? l10n.client,
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user?.phoneNumber ?? '',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Language Switcher
          Card(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading: const Icon(Icons.language, color: Color(0xFFFF5722)),
              title: Text(l10n.language),
              subtitle: Text(authProvider.locale.languageCode == 'fr'
                  ? l10n.french
                  : l10n.arabic),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => _showLanguageDialog(context, l10n, authProvider),
            ),
          ),
          const SizedBox(height: 12),

          // Saved Addresses
          Card(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading: const Icon(Icons.location_on, color: Color(0xFFFF5722)),
              title: Text(l10n.savedAddresses),
              subtitle: Text('${clientProvider.savedAddresses.length}'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const SavedAddressesScreen()),
                );
              },
            ),
          ),
          const SizedBox(height: 12),

          // Favorites
          Card(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading: const Icon(Icons.favorite, color: Color(0xFFFF5722)),
              title: Text(l10n.favorites),
              subtitle: Text('${clientProvider.favoriteRestaurantIds.length}'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => _showFavorites(context, l10n, clientProvider),
            ),
          ),
          const SizedBox(height: 12),

          // Settings
          Card(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading: const Icon(Icons.settings, color: Color(0xFFFF5722)),
              title: Text(l10n.settings),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {},
            ),
          ),
          const SizedBox(height: 24),

          // Logout Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _confirmLogout(context, l10n, authProvider),
              icon: const Icon(Icons.logout),
              label: Text(l10n.logout),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  void _showLanguageDialog(
      BuildContext context, AppLocalizations l10n, AuthProvider authProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.switchLanguage),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Text('🇫🇷', style: TextStyle(fontSize: 24)),
              title: Text(l10n.french),
              trailing: authProvider.locale.languageCode == 'fr'
                  ? const Icon(Icons.check, color: Color(0xFFFF5722))
                  : null,
              onTap: () {
                authProvider.changeLanguage('fr');
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Text('🇲🇦', style: TextStyle(fontSize: 24)),
              title: Text(l10n.arabic),
              trailing: authProvider.locale.languageCode == 'ar'
                  ? const Icon(Icons.check, color: Color(0xFFFF5722))
                  : null,
              onTap: () {
                authProvider.changeLanguage('fr');
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showFavorites(BuildContext context, AppLocalizations l10n,
      ClientProvider clientProvider) {
    final favoriteIds = clientProvider.favoriteRestaurantIds;
    final favoriteRestaurants = clientProvider.restaurants
        .where((r) => favoriteIds.contains(r.uid))
        .toList();

    if (favoriteRestaurants.isEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l10n.favorites),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.favorite_border, size: 60, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(l10n.noFavorites, style: TextStyle(color: Colors.grey[600])),
              const SizedBox(height: 8),
              Text(l10n.favoritesWillAppear,
                  style: TextStyle(fontSize: 13, color: Colors.grey[500])),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: Text(l10n.favorites),
            backgroundColor: const Color(0xFFFF5722),
          ),
          body: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: favoriteRestaurants.length,
            itemBuilder: (context, index) {
              final restaurant = favoriteRestaurants[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(12),
                  leading: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF5722).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child:
                        const Icon(Icons.restaurant, color: Color(0xFFFF5722)),
                  ),
                  title: Text(restaurant.name,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: restaurant.averageRating > 0
                      ? Row(
                          children: [
                            const Icon(Icons.star,
                                size: 14, color: Colors.amber),
                            const SizedBox(width: 4),
                            Text(
                                '${restaurant.averageRating.toStringAsFixed(1)}'),
                          ],
                        )
                      : null,
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            RestaurantMenuScreen(restaurant: restaurant),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  void _confirmLogout(
      BuildContext context, AppLocalizations l10n, AuthProvider authProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.logout),
        content: Text(l10n.logoutConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              authProvider.signOut();
            },
            child: Text(l10n.logout, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
