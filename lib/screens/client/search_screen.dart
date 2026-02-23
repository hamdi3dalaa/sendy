// lib/screens/client/search_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sendy/l10n/app_localizations.dart';
import '../../providers/client_provider.dart';
import '../../models/menu_item_model.dart';
import '../../theme/neumorphic_theme.dart';
import 'restaurant_menu_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({Key? key}) : super(key: key);

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchController = TextEditingController();
  List<MenuItem> _menuResults = [];
  List<RestaurantModel> _restaurantResults = [];
  bool _isSearching = false;
  String _selectedCategory = '';
  List<String> _recentSearches = [];

  final List<Map<String, dynamic>> _categoryFilters = [
    {'key': 'fastFood', 'icon': Icons.fastfood_rounded},
    {'key': 'moroccan', 'icon': Icons.restaurant_rounded},
    {'key': 'pizza', 'icon': Icons.local_pizza_rounded},
    {'key': 'sushi', 'icon': Icons.set_meal_rounded},
    {'key': 'burger', 'icon': Icons.lunch_dining_rounded},
    {'key': 'chicken', 'icon': Icons.restaurant_menu_rounded},
    {'key': 'tacos', 'icon': Icons.food_bank_rounded},
    {'key': 'desserts', 'icon': Icons.cake_rounded},
  ];

  String _getCategoryLabel(AppLocalizations l10n, String key) {
    switch (key) {
      case 'fastFood': return l10n.fastFood;
      case 'moroccan': return l10n.moroccan;
      case 'pizza': return l10n.pizza;
      case 'sushi': return l10n.sushi;
      case 'burger': return l10n.burger;
      case 'chicken': return l10n.chicken;
      case 'tacos': return l10n.tacos;
      case 'desserts': return l10n.desserts;
      default: return key;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty && _selectedCategory.isEmpty) {
      setState(() {
        _menuResults = [];
        _restaurantResults = [];
      });
      return;
    }

    setState(() => _isSearching = true);

    final clientProvider = context.read<ClientProvider>();

    // Search restaurants by name and category
    final allRestaurants = clientProvider.restaurants;
    final lowerQuery = query.toLowerCase();

    _restaurantResults = allRestaurants.where((r) {
      final matchesQuery = query.isEmpty || r.name.toLowerCase().contains(lowerQuery);
      final matchesCategory = _selectedCategory.isEmpty || r.category == _selectedCategory;
      return matchesQuery && matchesCategory;
    }).toList();

    // Search menu items
    if (query.isNotEmpty) {
      _menuResults = await clientProvider.searchMenuItems(query);
    } else {
      _menuResults = [];
    }

    // Save to recent searches
    if (query.isNotEmpty && !_recentSearches.contains(query)) {
      _recentSearches.insert(0, query);
      if (_recentSearches.length > 5) _recentSearches.removeLast();
    }

    setState(() => _isSearching = false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      color: NeuColors.background,
      child: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: NeuTextField(
              controller: _searchController,
              hintText: l10n.searchRestaurantsAndDishes,
              prefixIcon: const Icon(Icons.search_rounded, color: NeuColors.accent),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded, color: NeuColors.textHint),
                      onPressed: () {
                        _searchController.clear();
                        _performSearch('');
                      },
                    )
                  : null,
              onChanged: (value) => _performSearch(value),
            ),
          ),

          // Category Filter Chips
          SizedBox(
            height: 48,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _categoryFilters.length,
              itemBuilder: (context, index) {
                final cat = _categoryFilters[index];
                final key = cat['key'] as String;
                final isSelected = _selectedCategory == key;
                return Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: NeuChip(
                    label: _getCategoryLabel(l10n, key),
                    isSelected: isSelected,
                    avatar: Icon(cat['icon'] as IconData, size: 16,
                        color: isSelected ? Colors.white : NeuColors.accent),
                    onTap: () {
                      setState(() {
                        _selectedCategory = isSelected ? '' : key;
                      });
                      _performSearch(_searchController.text);
                    },
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),

          // Results
          Expanded(
            child: _isSearching
                ? const Center(child: CircularProgressIndicator(color: NeuColors.accent))
                : _buildResults(l10n),
          ),
        ],
      ),
    );
  }

  Widget _buildResults(AppLocalizations l10n) {
    final hasQuery = _searchController.text.isNotEmpty || _selectedCategory.isNotEmpty;

    if (!hasQuery) {
      return _buildRecentSearches(l10n);
    }

    if (_restaurantResults.isEmpty && _menuResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: NeuDecoration.raised(radius: 40),
              child: const Icon(Icons.search_off_rounded, size: 50, color: NeuColors.textHint),
            ),
            const SizedBox(height: 20),
            Text(l10n.noResultsFound, style: const TextStyle(fontSize: 18, color: NeuColors.textSecondary, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text(l10n.tryAnotherSearch, style: const TextStyle(fontSize: 14, color: NeuColors.textHint)),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Restaurant results
        if (_restaurantResults.isNotEmpty) ...[
          Text(l10n.restaurants,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: NeuColors.textPrimary)),
          const SizedBox(height: 12),
          ..._restaurantResults.map((r) => _buildRestaurantTile(r, l10n)),
          const SizedBox(height: 24),
        ],

        // Menu item results
        if (_menuResults.isNotEmpty) ...[
          Text('${l10n.dishes} (${_menuResults.length})',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: NeuColors.textPrimary)),
          const SizedBox(height: 12),
          ..._menuResults.map((item) => _buildMenuItemTile(item, l10n)),
        ],
      ],
    );
  }

  Widget _buildRecentSearches(AppLocalizations l10n) {
    if (_recentSearches.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: NeuDecoration.raised(radius: 40),
              child: const Icon(Icons.search_rounded, size: 50, color: NeuColors.textHint),
            ),
            const SizedBox(height: 20),
            Text(l10n.searchRestaurantsAndDishes,
                style: const TextStyle(fontSize: 16, color: NeuColors.textHint)),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.recentSearches,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: NeuColors.textPrimary)),
          const SizedBox(height: 12),
          ..._recentSearches.map((search) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: NeuDecoration.raised(radius: 12, intensity: 0.5),
                child: ListTile(
                  leading: const Icon(Icons.history_rounded, color: NeuColors.textHint),
                  title: Text(search, style: const TextStyle(color: NeuColors.textPrimary)),
                  onTap: () {
                    _searchController.text = search;
                    _performSearch(search);
                  },
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildRestaurantTile(RestaurantModel restaurant, AppLocalizations l10n) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: NeuDecoration.raised(radius: 14),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: ListTile(
          contentPadding: const EdgeInsets.all(12),
          leading: Container(
            width: 56,
            height: 56,
            decoration: NeuDecoration.pressed(radius: 12),
            child: restaurant.coverImageUrl != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(restaurant.coverImageUrl!, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            const Icon(Icons.restaurant_rounded, color: NeuColors.accent)),
                  )
                : const Icon(Icons.restaurant_rounded, color: NeuColors.accent),
          ),
          title: Text(restaurant.name, style: const TextStyle(fontWeight: FontWeight.bold, color: NeuColors.textPrimary)),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (restaurant.category.isNotEmpty)
                Text(restaurant.category, style: const TextStyle(fontSize: 12, color: NeuColors.textSecondary)),
              if (restaurant.averageRating > 0)
                Row(
                  children: [
                    const Icon(Icons.star_rounded, size: 14, color: Colors.amber),
                    const SizedBox(width: 4),
                    Text('${restaurant.averageRating.toStringAsFixed(1)} (${restaurant.totalReviews})',
                        style: const TextStyle(fontSize: 12, color: NeuColors.textSecondary)),
                  ],
                ),
            ],
          ),
          trailing: Text('${restaurant.approvedItemsCount} ${l10n.dishes}',
              style: const TextStyle(fontSize: 12, color: NeuColors.textHint)),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => RestaurantMenuScreen(restaurant: restaurant)),
            );
          },
        ),
      ),
    );
  }

  Widget _buildMenuItemTile(MenuItem item, AppLocalizations l10n) {
    final clientProvider = context.read<ClientProvider>();
    // Check if there's an active promotion for this menu item
    final promo = clientProvider.dishPromotions
        .where((p) => p.menuItemId == item.id && p.isActive)
        .fold<DishPromotion?>(null, (prev, p) => prev ?? p);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: NeuDecoration.raised(radius: 14),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: ListTile(
          contentPadding: const EdgeInsets.all(10),
          leading: item.imageUrl != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(item.imageUrl!, width: 50, height: 50, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                          width: 50, height: 50,
                          decoration: NeuDecoration.pressed(radius: 10),
                          child: const Icon(Icons.restaurant_rounded, color: NeuColors.textHint))),
                )
              : Container(
                  width: 50, height: 50,
                  decoration: NeuDecoration.pressed(radius: 10),
                  child: const Icon(Icons.restaurant_rounded, color: NeuColors.textHint)),
          title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: NeuColors.textPrimary)),
          subtitle: Text(item.category, style: const TextStyle(fontSize: 12, color: NeuColors.textSecondary)),
          trailing: promo != null
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('${item.price.toStringAsFixed(0)} ${l10n.dhs}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: NeuColors.textHint,
                          decoration: TextDecoration.lineThrough,
                        )),
                    Text('${promo.promoPrice.toStringAsFixed(0)} ${l10n.dhs}',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: NeuColors.accent)),
                  ],
                )
              : Text('${item.price.toStringAsFixed(2)} ${l10n.dhs}',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: NeuColors.accent)),
          onTap: () async {
            // Navigate to the restaurant menu
            final restaurant = await clientProvider.getRestaurantById(item.restaurantId);
            if (restaurant != null && mounted) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => RestaurantMenuScreen(restaurant: restaurant),
                ),
              );
            }
          },
        ),
      ),
    );
  }
}
