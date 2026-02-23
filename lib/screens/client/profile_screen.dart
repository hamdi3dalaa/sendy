// lib/screens/client/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sendy/l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../providers/client_provider.dart';
import '../../theme/neumorphic_theme.dart';
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

    return Container(
      color: NeuColors.background,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // User Info Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: NeuDecoration.raised(radius: 20),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: NeuDecoration.pressed(radius: 50),
                    child: const Icon(Icons.person_rounded,
                        size: 50, color: NeuColors.accent),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    user?.displayName ?? l10n.client,
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.bold, color: NeuColors.textPrimary),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user?.phoneNumber ?? '',
                    style: const TextStyle(fontSize: 16, color: NeuColors.textSecondary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Language Switcher
            _buildNeuMenuTile(
              icon: Icons.language_rounded,
              title: l10n.language,
              subtitle: authProvider.locale.languageCode == 'fr'
                  ? l10n.french
                  : l10n.arabic,
              onTap: () => _showLanguageDialog(context, l10n, authProvider),
            ),
            const SizedBox(height: 12),

            // Saved Addresses
            _buildNeuMenuTile(
              icon: Icons.location_on_rounded,
              title: l10n.savedAddresses,
              subtitle: '${clientProvider.savedAddresses.length}',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const SavedAddressesScreen()),
                );
              },
            ),
            const SizedBox(height: 12),

            // Favorites
            _buildNeuMenuTile(
              icon: Icons.favorite_rounded,
              title: l10n.favorites,
              subtitle: '${clientProvider.favoriteRestaurantIds.length}',
              onTap: () => _showFavorites(context, l10n, clientProvider),
            ),
            const SizedBox(height: 12),

            // Settings
            _buildNeuMenuTile(
              icon: Icons.settings_rounded,
              title: l10n.settings,
              onTap: () {},
            ),
            const SizedBox(height: 24),

            // Logout Button
            GestureDetector(
              onTap: () => _confirmLogout(context, l10n, authProvider),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: NeuColors.background,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: NeuColors.lightShadow.withOpacity(0.8),
                      offset: const Offset(-4, -4),
                      blurRadius: 8,
                    ),
                    BoxShadow(
                      color: Colors.red.withOpacity(0.15),
                      offset: const Offset(4, 4),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.logout_rounded, color: NeuColors.error),
                    const SizedBox(width: 8),
                    Text(l10n.logout, style: const TextStyle(
                      color: NeuColors.error,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    )),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildNeuMenuTile({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: NeuDecoration.raised(radius: 14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: NeuDecoration.pressed(radius: 12),
              child: Icon(icon, color: NeuColors.accent, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: NeuColors.textPrimary,
                  )),
                  if (subtitle != null)
                    Text(subtitle, style: const TextStyle(
                      fontSize: 13,
                      color: NeuColors.textSecondary,
                    )),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: NeuColors.textHint),
          ],
        ),
      ),
    );
  }

  void _showLanguageDialog(
      BuildContext context, AppLocalizations l10n, AuthProvider authProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: NeuColors.background,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(l10n.switchLanguage, style: const TextStyle(color: NeuColors.textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildLanguageOption(
              context, authProvider,
              flag: '🇫🇷', label: l10n.french, code: 'fr',
              isSelected: authProvider.locale.languageCode == 'fr',
            ),
            const SizedBox(height: 8),
            _buildLanguageOption(
              context, authProvider,
              flag: '🇲🇦', label: l10n.arabic, code: 'ar',
              isSelected: authProvider.locale.languageCode == 'ar',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageOption(
    BuildContext context, AuthProvider authProvider, {
    required String flag,
    required String label,
    required String code,
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: () {
        authProvider.changeLanguage(code);
        Navigator.pop(context);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: isSelected
            ? NeuDecoration.pressed(radius: 12)
            : NeuDecoration.raised(radius: 12),
        child: Row(
          children: [
            Text(flag, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 12),
            Expanded(child: Text(label, style: const TextStyle(fontSize: 16, color: NeuColors.textPrimary))),
            if (isSelected)
              const Icon(Icons.check_circle_rounded, color: NeuColors.accent),
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
          backgroundColor: NeuColors.background,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(l10n.favorites, style: const TextStyle(color: NeuColors.textPrimary)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: NeuDecoration.raised(radius: 40),
                child: const Icon(Icons.favorite_border_rounded, size: 40, color: NeuColors.textHint),
              ),
              const SizedBox(height: 16),
              Text(l10n.noFavorites, style: const TextStyle(color: NeuColors.textSecondary)),
              const SizedBox(height: 8),
              Text(l10n.favoritesWillAppear,
                  style: const TextStyle(fontSize: 13, color: NeuColors.textHint)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK', style: TextStyle(color: NeuColors.accent)),
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
          backgroundColor: NeuColors.background,
          appBar: AppBar(
            title: Text(l10n.favorites),
            backgroundColor: NeuColors.accent,
            foregroundColor: Colors.white,
            elevation: 0,
          ),
          body: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: favoriteRestaurants.length,
            itemBuilder: (context, index) {
              final restaurant = favoriteRestaurants[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: NeuDecoration.raised(radius: 14),
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(12),
                    leading: Container(
                      width: 50,
                      height: 50,
                      decoration: NeuDecoration.pressed(radius: 12),
                      child: const Icon(Icons.restaurant_rounded, color: NeuColors.accent),
                    ),
                    title: Text(restaurant.name,
                        style: const TextStyle(fontWeight: FontWeight.bold, color: NeuColors.textPrimary)),
                    subtitle: restaurant.averageRating > 0
                        ? Row(
                            children: [
                              const Icon(Icons.star_rounded, size: 14, color: Colors.amber),
                              const SizedBox(width: 4),
                              Text('${restaurant.averageRating.toStringAsFixed(1)}',
                                  style: const TextStyle(color: NeuColors.textSecondary)),
                            ],
                          )
                        : null,
                    trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: NeuColors.textHint),
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
        backgroundColor: NeuColors.background,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(l10n.logout, style: const TextStyle(color: NeuColors.textPrimary)),
        content: Text(l10n.logoutConfirm, style: const TextStyle(color: NeuColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel, style: const TextStyle(color: NeuColors.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              authProvider.signOut();
            },
            child: Text(l10n.logout, style: const TextStyle(color: NeuColors.error, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
