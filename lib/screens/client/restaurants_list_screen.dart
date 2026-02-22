// lib/screens/client/restaurants_list_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:sendy/l10n/app_localizations.dart';
import '../../providers/client_provider.dart';
import '../../providers/auth_provider.dart';
import 'restaurant_menu_screen.dart';

class RestaurantsListScreen extends StatefulWidget {
  const RestaurantsListScreen({Key? key}) : super(key: key);

  @override
  State<RestaurantsListScreen> createState() => _RestaurantsListScreenState();
}

class _RestaurantsListScreenState extends State<RestaurantsListScreen> {
  String _searchQuery = '';
  String _selectedCategory = '';
  bool _hasLoaded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadRestaurants();
    });
  }

  static const List<String> _categoryKeys = [
    '',
    'fastFood',
    'moroccan',
    'pizza',
    'sushi',
    'burger',
    'chicken',
    'tacos',
    'desserts',
  ];

  String? _getCustomerCity() {
    final authProvider = context.read<AuthProvider>();
    return authProvider.currentUser?.city;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final categoryLabels = {
      '': l10n.all,
      'fastFood': l10n.fastFood,
      'moroccan': l10n.moroccan,
      'pizza': l10n.pizza,
      'sushi': l10n.sushi,
      'burger': l10n.burger,
      'chicken': l10n.chicken,
      'tacos': l10n.tacos,
      'desserts': l10n.desserts,
    };

    return Column(
      children: [
        // Search Bar
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            onChanged: (value) {
              setState(() {
                _searchQuery = value.toLowerCase();
              });
            },
            decoration: InputDecoration(
              hintText: l10n.searchRestaurants,
              prefixIcon: const Icon(Icons.search, color: Color(0xFFFF5722)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.grey[100],
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
            ),
          ),
        ),

        // Category Chips
        SizedBox(
          height: 50,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: _categoryKeys.length,
            itemBuilder: (context, index) {
              final key = _categoryKeys[index];
              final isSelected = key == _selectedCategory;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                child: ChoiceChip(
                  label: Text(categoryLabels[key] ?? key),
                  selected: isSelected,
                  onSelected: (_) {
                    setState(() {
                      _selectedCategory = key;
                    });
                  },
                  selectedColor: const Color(0xFFFF5722),
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : Colors.black,
                    fontSize: 12,
                  ),
                ),
              );
            },
          ),
        ),

        // Restaurants List
        Expanded(
          child: Consumer<ClientProvider>(
            builder: (context, clientProvider, child) {
              if (clientProvider.isLoading) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(color: Color(0xFFFF5722)),
                      const SizedBox(height: 16),
                      Text(l10n.loadingRestaurants),
                    ],
                  ),
                );
              }

              if (clientProvider.error != null) {
                return _buildErrorState(clientProvider, l10n);
              }

              if (!_hasLoaded && clientProvider.restaurants.isEmpty) {
                return _buildInitialState(l10n);
              }

              final customerCity = _getCustomerCity();

              // Filter by city first
              var restaurants = clientProvider.restaurants.where((r) {
                if (customerCity == null || customerCity.isEmpty) return true;
                if (r.city == null || r.city!.isEmpty) return true;
                return r.city!.toLowerCase() == customerCity.toLowerCase();
              }).toList();

              // Then filter by search
              restaurants = restaurants
                  .where((r) => r.name.toLowerCase().contains(_searchQuery))
                  .toList();

              // Then filter by category
              if (_selectedCategory.isNotEmpty) {
                restaurants = restaurants
                    .where((r) =>
                        r.category.toLowerCase() ==
                        _selectedCategory.toLowerCase())
                    .toList();
              }

              // Get active promotions (already filtered by city from provider)
              final promotions = clientProvider.dishPromotions;

              if (restaurants.isEmpty && promotions.isEmpty) {
                return _buildEmptyState(l10n);
              }

              return RefreshIndicator(
                onRefresh: () => _loadRestaurants(),
                color: const Color(0xFFFF5722),
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Promotions section at the top
                    if (promotions.isNotEmpty && _searchQuery.isEmpty) ...[
                      Row(
                        children: [
                          const Icon(Icons.local_fire_department,
                              color: Color(0xFFFF5722), size: 22),
                          const SizedBox(width: 6),
                          Text(
                            l10n.currentPromotions,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 180,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: promotions.length,
                          itemBuilder: (context, index) {
                            return _PromotionCard(
                                promo: promotions[index]);
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        l10n.allRestaurants,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],

                    // Restaurant list
                    ...restaurants.map((restaurant) =>
                        _RestaurantCard(restaurant: restaurant)),

                    if (restaurants.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 40),
                        child: _buildEmptyState(l10n),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _loadRestaurants() async {
    setState(() {
      _hasLoaded = true;
    });
    final clientProvider = context.read<ClientProvider>();
    final customerCity = _getCustomerCity();
    await Future.wait([
      clientProvider.loadRestaurants(),
      clientProvider.loadDishPromotions(customerCity: customerCity),
    ]);
  }

  Widget _buildInitialState(AppLocalizations l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFFF5722).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.restaurant,
                  size: 80, color: Color(0xFFFF5722)),
            ),
            const SizedBox(height: 24),
            Text(l10n.discoverRestaurants,
                style:
                    const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(l10n.tapToLoadRestaurants,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey[600])),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _loadRestaurants,
              icon: const Icon(Icons.refresh),
              label: Text(l10n.loadRestaurants),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF5722),
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(
      ClientProvider clientProvider, AppLocalizations l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
            const SizedBox(height: 24),
            Text(l10n.error,
                style:
                    const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(clientProvider.error ?? '',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey[500])),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadRestaurants,
              icon: const Icon(Icons.refresh),
              label: Text(l10n.retry),
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF5722),
                  foregroundColor: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(AppLocalizations l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(_searchQuery.isEmpty ? Icons.restaurant : Icons.search_off,
                size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 24),
            Text(
              _searchQuery.isEmpty
                  ? l10n.noRestaurantsAvailable
                  : l10n.noResultsFound,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _searchQuery.isEmpty
                  ? l10n.restaurantsWillAppear
                  : l10n.tryAnotherSearch,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }
}

class _PromotionCard extends StatelessWidget {
  final DishPromotion promo;

  const _PromotionCard({required this.promo});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return GestureDetector(
      onTap: () async {
        // Navigate to the restaurant
        final clientProvider = context.read<ClientProvider>();
        final restaurant =
            await clientProvider.getRestaurantById(promo.restaurantId);
        if (restaurant != null && context.mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  RestaurantMenuScreen(restaurant: restaurant),
            ),
          );
        }
      },
      child: Container(
        width: 200,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image with discount badge
            Stack(
              children: [
                promo.dishImageUrl != null && promo.dishImageUrl!.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: promo.dishImageUrl!,
                        height: 100,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(
                          height: 100,
                          color: Colors.grey[200],
                          child: const Center(
                              child: CircularProgressIndicator(
                                  strokeWidth: 2)),
                        ),
                        errorWidget: (_, __, ___) => Container(
                          height: 100,
                          color: const Color(0xFFFF5722).withOpacity(0.1),
                          child: const Center(
                              child: Icon(Icons.fastfood,
                                  size: 40, color: Color(0xFFFF5722))),
                        ),
                      )
                    : Container(
                        height: 100,
                        color: const Color(0xFFFF5722).withOpacity(0.1),
                        child: const Center(
                            child: Icon(Icons.fastfood,
                                size: 40, color: Color(0xFFFF5722))),
                      ),
                // Discount badge
                Positioned(
                  top: 6,
                  right: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '-${promo.discountPercent}%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            // Info
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    promo.dishName,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    promo.restaurantName,
                    style: TextStyle(
                        fontSize: 11, color: Colors.grey[600]),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        '${promo.originalPrice.toStringAsFixed(0)} ${l10n.dhs}',
                        style: const TextStyle(
                          decoration: TextDecoration.lineThrough,
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${promo.promoPrice.toStringAsFixed(0)} ${l10n.dhs}',
                        style: const TextStyle(
                          color: Color(0xFFFF5722),
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RestaurantCard extends StatelessWidget {
  final RestaurantModel restaurant;

  const _RestaurantCard({required this.restaurant});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final authProvider = context.read<AuthProvider>();

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  RestaurantMenuScreen(restaurant: restaurant),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover image or gradient header
            Stack(
              children: [
                _buildHeader(),
                // Favorite button
                Positioned(
                  top: 8,
                  right: 8,
                  child: Consumer<ClientProvider>(
                    builder: (context, clientProvider, _) {
                      final isFav = clientProvider.isFavorite(restaurant.uid);
                      return GestureDetector(
                        onTap: () {
                          if (authProvider.currentUser != null) {
                            clientProvider.toggleFavorite(
                                authProvider.currentUser!.uid, restaurant.uid);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isFav ? Icons.favorite : Icons.favorite_border,
                            color: isFav ? Colors.red : Colors.grey,
                            size: 22,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                if (restaurant.category.isNotEmpty)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF5722),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        restaurant.category,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
              ],
            ),
            // Restaurant info
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          restaurant.name,
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (restaurant.averageRating > 0) ...[
                        const Icon(Icons.star, color: Colors.amber, size: 18),
                        const SizedBox(width: 2),
                        Text(restaurant.averageRating.toStringAsFixed(1),
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 14)),
                        Text(' (${restaurant.totalReviews})',
                            style: TextStyle(
                                color: Colors.grey[600], fontSize: 12)),
                      ],
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.restaurant_menu,
                          size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        '${restaurant.approvedItemsCount} ${restaurant.approvedItemsCount > 1 ? l10n.dishes : l10n.dish}',
                        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                      ),
                      const SizedBox(width: 16),
                      Icon(Icons.delivery_dining,
                          size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text('14.00 ${l10n.dhs}',
                          style:
                              TextStyle(fontSize: 13, color: Colors.grey[600])),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final bool hasImage = restaurant.coverImageUrl != null &&
        restaurant.coverImageUrl!.isNotEmpty;

    if (hasImage) {
      // Has image - use CachedNetworkImage
      return CachedNetworkImage(
        imageUrl: restaurant.coverImageUrl!,
        height: 150,
        width: double.infinity,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          height: 150,
          color: Colors.grey[200],
          child: const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF5722)),
            ),
          ),
        ),
        errorWidget: (context, url, error) => _buildGradientHeader(),
      );
    } else {
      // No image - show gradient with letter
      return _buildGradientHeader();
    }
  }

  Widget _buildGradientHeader() {
    return Container(
      height: 150,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFFF5722), Color(0xFFFF7043)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Text(
          restaurant.name.isNotEmpty
              ? restaurant.name.substring(0, 1).toUpperCase()
              : 'R',
          style: const TextStyle(
              fontSize: 60, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
    );
  }
}
