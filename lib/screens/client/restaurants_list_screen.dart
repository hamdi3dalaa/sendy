// lib/screens/client/restaurants_list_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:sendy/l10n/app_localizations.dart';
import '../../providers/client_provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/neumorphic_theme.dart';
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

    return Container(
      color: NeuColors.background,
      child: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.all(16),
            color: NeuColors.background,
            child: Container(
              decoration: NeuDecoration.pressed(radius: 30),
              child: TextField(
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value.toLowerCase();
                  });
                },
                style: const TextStyle(color: NeuColors.textPrimary),
                decoration: InputDecoration(
                  hintText: l10n.searchRestaurants,
                  hintStyle: const TextStyle(color: NeuColors.textHint),
                  prefixIcon: const Icon(Icons.search, color: NeuColors.accent),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.transparent,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
                ),
              ),
            ),
          ),

          // Category Chips
          SizedBox(
            height: 56,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _categoryKeys.length,
              itemBuilder: (context, index) {
                final key = _categoryKeys[index];
                final isSelected = key == _selectedCategory;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                  child: NeuChip(
                    label: categoryLabels[key] ?? key,
                    isSelected: isSelected,
                    onTap: () {
                      setState(() {
                        _selectedCategory = key;
                      });
                    },
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
                        const CircularProgressIndicator(color: NeuColors.accent),
                        const SizedBox(height: 16),
                        Text(
                          l10n.loadingRestaurants,
                          style: const TextStyle(color: NeuColors.textSecondary),
                        ),
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

                // Sort: restaurants with active promotions appear first
                final promoRestaurantIds = promotions.map((p) => p.restaurantId).toSet();
                restaurants.sort((a, b) {
                  final aHasPromo = promoRestaurantIds.contains(a.uid);
                  final bHasPromo = promoRestaurantIds.contains(b.uid);
                  if (aHasPromo && !bHasPromo) return -1;
                  if (!aHasPromo && bHasPromo) return 1;
                  return 0;
                });

                if (restaurants.isEmpty && promotions.isEmpty) {
                  return _buildEmptyState(l10n);
                }

                return RefreshIndicator(
                  onRefresh: () => _loadRestaurants(),
                  color: NeuColors.accent,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Promotions section at the top
                      if (promotions.isNotEmpty && _searchQuery.isEmpty) ...[
                        Row(
                          children: [
                            const Icon(Icons.local_fire_department,
                                color: NeuColors.accent, size: 22),
                            const SizedBox(width: 6),
                            Text(
                              l10n.currentPromotions,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: NeuColors.textPrimary,
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
                            color: NeuColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],

                      // Restaurant list
                      ...restaurants.map((restaurant) =>
                          _RestaurantCard(
                            restaurant: restaurant,
                            hasPromotion: promoRestaurantIds.contains(restaurant.uid),
                          )),

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
      ),
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
      clientProvider.refreshCartPromotions(),
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
                color: NeuColors.accent.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.restaurant,
                  size: 80, color: NeuColors.accent),
            ),
            const SizedBox(height: 24),
            Text(l10n.discoverRestaurants,
                style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: NeuColors.textPrimary)),
            const SizedBox(height: 8),
            Text(l10n.tapToLoadRestaurants,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 14, color: NeuColors.textSecondary)),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _loadRestaurants,
              icon: const Icon(Icons.refresh),
              label: Text(l10n.loadRestaurants),
              style: ElevatedButton.styleFrom(
                backgroundColor: NeuColors.accent,
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
            Icon(Icons.error_outline, size: 64, color: NeuColors.error),
            const SizedBox(height: 24),
            Text(l10n.error,
                style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: NeuColors.textPrimary)),
            const SizedBox(height: 8),
            Text(clientProvider.error ?? '',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 12, color: NeuColors.textHint)),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadRestaurants,
              icon: const Icon(Icons.refresh),
              label: Text(l10n.retry),
              style: ElevatedButton.styleFrom(
                  backgroundColor: NeuColors.accent,
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
                size: 64, color: NeuColors.textHint),
            const SizedBox(height: 24),
            Text(
              _searchQuery.isEmpty
                  ? l10n.noRestaurantsAvailable
                  : l10n.noResultsFound,
              style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: NeuColors.textPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              _searchQuery.isEmpty
                  ? l10n.restaurantsWillAppear
                  : l10n.tryAnotherSearch,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 14, color: NeuColors.textSecondary),
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
        decoration: NeuDecoration.raised(radius: 14),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image with diagonal discount banner
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(14),
                topRight: Radius.circular(14),
              ),
              child: ClipRect(
                child: Banner(
                  message: '-${promo.discountPercent}%',
                  location: BannerLocation.topEnd,
                  color: Colors.red,
                  textStyle: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                  child: promo.dishImageUrl != null && promo.dishImageUrl!.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: promo.dishImageUrl!,
                          height: 100,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Container(
                            height: 100,
                            color: NeuColors.darkShadow.withOpacity(0.1),
                            child: const Center(
                                child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: NeuColors.accent)),
                          ),
                          errorWidget: (_, __, ___) => Container(
                            height: 100,
                            color: NeuColors.accent.withOpacity(0.1),
                            child: const Center(
                                child: Icon(Icons.fastfood,
                                    size: 40, color: NeuColors.accent)),
                          ),
                        )
                      : Container(
                          height: 100,
                          color: NeuColors.accent.withOpacity(0.1),
                          child: const Center(
                              child: Icon(Icons.fastfood,
                                  size: 40, color: NeuColors.accent)),
                        ),
                ),
              ),
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
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: NeuColors.textPrimary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    promo.restaurantName,
                    style: const TextStyle(
                        fontSize: 11, color: NeuColors.textSecondary),
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
                          color: NeuColors.textHint,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${promo.promoPrice.toStringAsFixed(0)} ${l10n.dhs}',
                        style: const TextStyle(
                          color: NeuColors.accent,
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
  final bool hasPromotion;

  const _RestaurantCard({required this.restaurant, this.hasPromotion = false});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final authProvider = context.read<AuthProvider>();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: NeuDecoration.raised(radius: 16),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
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
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
                child: Stack(
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
                                color: NeuColors.background.withOpacity(0.9),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                isFav ? Icons.favorite : Icons.favorite_border,
                                color: isFav ? Colors.red : NeuColors.textHint,
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
                            color: NeuColors.accent,
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
                    // Promotions band
                    if (hasPromotion)
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.red.shade700,
                                Colors.red.shade400,
                              ],
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.local_offer,
                                  color: Colors.white, size: 14),
                              const SizedBox(width: 6),
                              Text(
                                l10n.promotions,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
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
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: NeuColors.textPrimary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (restaurant.averageRating > 0) ...[
                          const Icon(Icons.star, color: Colors.amber, size: 18),
                          const SizedBox(width: 2),
                          Text(restaurant.averageRating.toStringAsFixed(1),
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: NeuColors.textPrimary)),
                          Text(' (${restaurant.totalReviews})',
                              style: const TextStyle(
                                  color: NeuColors.textSecondary, fontSize: 12)),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.restaurant_menu,
                            size: 14, color: NeuColors.textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          '${restaurant.approvedItemsCount} ${restaurant.approvedItemsCount > 1 ? l10n.dishes : l10n.dish}',
                          style: const TextStyle(
                              fontSize: 13, color: NeuColors.textSecondary),
                        ),
                        const SizedBox(width: 16),
                        const Icon(Icons.delivery_dining,
                            size: 14, color: NeuColors.textSecondary),
                        const SizedBox(width: 4),
                        Text('14.00 ${l10n.dhs}',
                            style: const TextStyle(
                                fontSize: 13, color: NeuColors.textSecondary)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
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
          color: NeuColors.darkShadow.withOpacity(0.1),
          child: const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(NeuColors.accent),
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
          colors: [NeuColors.accent, NeuColors.accentLight],
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
