// lib/screens/client/search_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sendy/l10n/app_localizations.dart';
import '../../providers/client_provider.dart';
import '../../models/menu_item_model.dart';
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
    {'key': 'fastFood', 'icon': Icons.fastfood},
    {'key': 'moroccan', 'icon': Icons.restaurant},
    {'key': 'pizza', 'icon': Icons.local_pizza},
    {'key': 'sushi', 'icon': Icons.set_meal},
    {'key': 'burger', 'icon': Icons.lunch_dining},
    {'key': 'chicken', 'icon': Icons.restaurant_menu},
    {'key': 'tacos', 'icon': Icons.food_bank},
    {'key': 'desserts', 'icon': Icons.cake},
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

    return Column(
      children: [
        // Search Bar
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: l10n.searchRestaurantsAndDishes,
              prefixIcon: const Icon(Icons.search, color: Color(0xFFFF5722)),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        _performSearch('');
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.grey[100],
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            ),
            onChanged: (value) => _performSearch(value),
          ),
        ),

        // Category Filter Chips
        SizedBox(
          height: 45,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _categoryFilters.length,
            itemBuilder: (context, index) {
              final cat = _categoryFilters[index];
              final key = cat['key'] as String;
              final isSelected = _selectedCategory == key;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  avatar: Icon(cat['icon'] as IconData, size: 18,
                      color: isSelected ? Colors.white : const Color(0xFFFF5722)),
                  label: Text(_getCategoryLabel(l10n, key)),
                  selected: isSelected,
                  selectedColor: const Color(0xFFFF5722),
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : Colors.black87,
                    fontSize: 13,
                  ),
                  onSelected: (selected) {
                    setState(() {
                      _selectedCategory = selected ? key : '';
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
              ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF5722)))
              : _buildResults(l10n),
        ),
      ],
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
            Icon(Icons.search_off, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(l10n.noResultsFound, style: TextStyle(fontSize: 18, color: Colors.grey[600])),
            const SizedBox(height: 8),
            Text(l10n.tryAnotherSearch, style: TextStyle(fontSize: 14, color: Colors.grey[500])),
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
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          ..._restaurantResults.map((r) => _buildRestaurantTile(r, l10n)),
          const SizedBox(height: 24),
        ],

        // Menu item results
        if (_menuResults.isNotEmpty) ...[
          Text('${l10n.dishes} (${_menuResults.length})',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
            Icon(Icons.search, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(l10n.searchRestaurantsAndDishes,
                style: TextStyle(fontSize: 16, color: Colors.grey[500])),
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
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          ..._recentSearches.map((search) => ListTile(
                leading: const Icon(Icons.history, color: Colors.grey),
                title: Text(search),
                onTap: () {
                  _searchController.text = search;
                  _performSearch(search);
                },
                contentPadding: EdgeInsets.zero,
              )),
        ],
      ),
    );
  }

  Widget _buildRestaurantTile(RestaurantModel restaurant, AppLocalizations l10n) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: const Color(0xFFFF5722).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: restaurant.coverImageUrl != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(restaurant.coverImageUrl!, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          const Icon(Icons.restaurant, color: Color(0xFFFF5722))),
                )
              : const Icon(Icons.restaurant, color: Color(0xFFFF5722)),
        ),
        title: Text(restaurant.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (restaurant.category.isNotEmpty)
              Text(restaurant.category, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            if (restaurant.averageRating > 0)
              Row(
                children: [
                  const Icon(Icons.star, size: 14, color: Colors.amber),
                  const SizedBox(width: 4),
                  Text('${restaurant.averageRating.toStringAsFixed(1)} (${restaurant.totalReviews})',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                ],
              ),
          ],
        ),
        trailing: Text('${restaurant.approvedItemsCount} ${l10n.dishes}',
            style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => RestaurantMenuScreen(restaurant: restaurant)),
          );
        },
      ),
    );
  }

  Widget _buildMenuItemTile(MenuItem item, AppLocalizations l10n) {
    final clientProvider = context.read<ClientProvider>();
    // Check if there's an active promotion for this menu item
    final promo = clientProvider.dishPromotions
        .where((p) => p.menuItemId == item.id && p.isActive)
        .fold<DishPromotion?>(null, (prev, p) => prev ?? p);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.all(8),
        leading: item.imageUrl != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(item.imageUrl!, width: 50, height: 50, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                        width: 50, height: 50, color: Colors.grey[200],
                        child: const Icon(Icons.restaurant))),
              )
            : Container(
                width: 50, height: 50,
                decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.restaurant)),
        title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: Text(item.category, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        trailing: promo != null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('${item.price.toStringAsFixed(0)} ${l10n.dhs}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                        decoration: TextDecoration.lineThrough,
                      )),
                  Text('${promo.promoPrice.toStringAsFixed(0)} ${l10n.dhs}',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFFF5722))),
                ],
              )
            : Text('${item.price.toStringAsFixed(2)} ${l10n.dhs}',
                style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFFF5722))),
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
    );
  }
}
