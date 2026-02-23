// lib/screens/client/restaurant_menu_screen.dart
// UPDATED to work with CartItem

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:sendy/l10n/app_localizations.dart';
import '../../providers/client_provider.dart';
import '../../models/menu_item_model.dart';
import '../../theme/neumorphic_theme.dart';
import 'cart_screen.dart';

class RestaurantMenuScreen extends StatefulWidget {
  final RestaurantModel restaurant;

  const RestaurantMenuScreen({
    Key? key,
    required this.restaurant,
  }) : super(key: key);

  @override
  State<RestaurantMenuScreen> createState() => _RestaurantMenuScreenState();
}

class _RestaurantMenuScreenState extends State<RestaurantMenuScreen> {
  String _selectedCategory = 'Tous';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadMenuAndPromotions();
    });
  }

  Future<void> _loadMenuAndPromotions() async {
    final cp = context.read<ClientProvider>();
    // Load menu, promotions, and refresh cart promos in parallel
    // so promotions are ready when menu items display
    // and cart items reflect deleted/expired promos
    await Future.wait([
      cp.loadRestaurantMenu(widget.restaurant.uid),
      cp.loadActivePromotionsForRestaurant(widget.restaurant.uid),
      cp.refreshCartPromotions(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NeuColors.background,
      appBar: AppBar(
        title: Text(widget.restaurant.name),
        backgroundColor: NeuColors.accent,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CartScreen(
                        restaurant: widget.restaurant,
                      ),
                    ),
                  );
                },
              ),
              Positioned(
                right: 8,
                top: 8,
                child: Consumer<ClientProvider>(
                  builder: (context, clientProvider, _) {
                    final count = clientProvider.cartItemCount;
                    if (count == 0) return const SizedBox();
                    return Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        count.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
      body: Consumer<ClientProvider>(
        builder: (context, clientProvider, child) {
          final l10n = AppLocalizations.of(context)!;
          if (clientProvider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(
                color: NeuColors.accent,
              ),
            );
          }

          if (clientProvider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('${l10n.error}: ${clientProvider.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => clientProvider
                        .loadRestaurantMenu(widget.restaurant.uid),
                    icon: const Icon(Icons.refresh),
                    label: Text(l10n.retry),
                  ),
                ],
              ),
            );
          }

          final menuItems = clientProvider.restaurantMenuItems;

          if (menuItems.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.restaurant_menu,
                      size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    l10n.noDishesAvailable,
                    style: const TextStyle(
                        fontSize: 18, color: NeuColors.textSecondary),
                  ),
                ],
              ),
            );
          }

          final categories = [
            'Tous',
            ...menuItems.map((item) => item.category).toSet().toList()
          ];
          final filteredItems = _selectedCategory == 'Tous'
              ? menuItems
              : menuItems
                  .where((item) => item.category == _selectedCategory)
                  .toList();

          return Column(
            children: [
              // Category Filter
              Container(
                height: 56,
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    final category = categories[index];
                    final isSelected = category == _selectedCategory;
                    return Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedCategory = category;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: isSelected
                              ? NeuDecoration.accentRaised(radius: 20)
                              : NeuDecoration.raised(
                                  radius: 20, intensity: 0.6),
                          child: Center(
                            child: Text(
                              category,
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : NeuColors.textPrimary,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Menu Items Grid
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.75,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: filteredItems.length,
                  itemBuilder: (context, index) {
                    final item = filteredItems[index];
                    final promo = clientProvider.getActivePromotion(item.id);
                    return _MenuItemCard(item: item, promotion: promo);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _MenuItemCard extends StatelessWidget {
  final MenuItem item;
  final DishPromotion? promotion;

  const _MenuItemCard({required this.item, this.promotion});

  void _showQuantitySelector(BuildContext context, ClientProvider clientProvider) {
    final l10n = AppLocalizations.of(context)!;
    int quantity = clientProvider.getQuantity(item.id);
    if (quantity == 0) quantity = 1;

    showModalBottomSheet(
      context: context,
      backgroundColor: NeuColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle bar
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: NeuColors.textHint,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Item info
                  Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: item.imageUrl != null
                            ? CachedNetworkImage(
                                imageUrl: item.imageUrl!,
                                width: 70,
                                height: 70,
                                fit: BoxFit.cover,
                                errorWidget: (c, u, e) => Container(
                                  width: 70, height: 70,
                                  color: Colors.grey[200],
                                  child: const Icon(Icons.restaurant),
                                ),
                              )
                            : Container(
                                width: 70, height: 70,
                                color: Colors.grey[200],
                                child: const Icon(Icons.restaurant),
                              ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.name,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: NeuColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            if (promotion != null) ...[
                              Text(
                                '${item.price.toStringAsFixed(0)} ${l10n.dhs}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: NeuColors.textHint,
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
                              Row(
                                children: [
                                  Text(
                                    '${promotion!.promoPrice.toStringAsFixed(0)} ${l10n.dhs}',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      color: NeuColors.accent,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.red,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      '-${promotion!.discountPercent}%',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ] else
                              Text(
                                '${item.price.toStringAsFixed(2)} ${l10n.dhs}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: NeuColors.accent,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Quantity selector
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Minus button
                      GestureDetector(
                        onTap: quantity > 1
                            ? () => setModalState(() => quantity--)
                            : null,
                        child: Container(
                          width: 48,
                          height: 48,
                          alignment: Alignment.center,
                          decoration: NeuDecoration.raised(radius: 12),
                          child: Icon(
                            Icons.remove,
                            color: quantity > 1
                                ? NeuColors.textPrimary
                                : NeuColors.textHint,
                            size: 28,
                          ),
                        ),
                      ),
                      // Quantity display
                      Container(
                        width: 80,
                        alignment: Alignment.center,
                        child: Text(
                          '$quantity',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: NeuColors.textPrimary,
                          ),
                        ),
                      ),
                      // Plus button
                      GestureDetector(
                        onTap: quantity < 99
                            ? () => setModalState(() => quantity++)
                            : null,
                        child: Container(
                          width: 48,
                          height: 48,
                          alignment: Alignment.center,
                          decoration: NeuDecoration.raised(radius: 12),
                          child: const Icon(
                            Icons.add,
                            color: NeuColors.accent,
                            size: 28,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Total line
                  Text(
                    '${l10n.total}: ${((promotion?.promoPrice ?? item.price) * quantity).toStringAsFixed(2)} ${l10n.dhs}',
                    style: const TextStyle(
                      fontSize: 15,
                      color: NeuColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Add to cart button
                  GestureDetector(
                    onTap: () {
                      final cp = Provider.of<ClientProvider>(ctx, listen: false);
                      if (cp.isInCart(item.id)) {
                        cp.updateQuantity(item.id, quantity);
                      } else {
                        cp.addToCart(item, quantity: quantity, promoPrice: promotion?.promoPrice);
                      }
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${item.name} x$quantity ${l10n.addedToCart}'),
                          duration: const Duration(seconds: 1),
                          backgroundColor: Colors.green,
                        ),
                      );
                    },
                    child: Container(
                      width: double.infinity,
                      height: 50,
                      decoration: NeuDecoration.accentRaised(radius: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.add_shopping_cart,
                              color: Colors.white),
                          const SizedBox(width: 8),
                          Text(
                            '${l10n.addedToCart} - ${((promotion?.promoPrice ?? item.price) * quantity).toStringAsFixed(2)} ${l10n.dhs}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildItemImage() {
    if (item.imageUrl != null) {
      return CachedNetworkImage(
        imageUrl: item.imageUrl!,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        placeholder: (context, url) => Container(
          color: Colors.grey[200],
          child: const Center(child: CircularProgressIndicator()),
        ),
        errorWidget: (context, url, error) => Container(
          color: Colors.grey[200],
          child: const Icon(Icons.restaurant, size: 40),
        ),
      );
    }
    return Container(
      color: Colors.grey[200],
      child: const Icon(Icons.restaurant, size: 40),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Consumer<ClientProvider>(
      builder: (context, clientProvider, child) {
        final isInCart = clientProvider.isInCart(item.id);
        final quantity = clientProvider.getQuantity(item.id);

        return GestureDetector(
          onTap: () => _showQuantitySelector(context, clientProvider),
          child: Container(
            decoration: NeuDecoration.raised(radius: 12),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Image with Quantity Badge and Promo Banner
                Expanded(
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius:
                            const BorderRadius.vertical(top: Radius.circular(12)),
                        child: promotion != null
                            ? Banner(
                                message: '-${promotion!.discountPercent}%',
                                location: BannerLocation.topEnd,
                                color: Colors.red,
                                textStyle: const TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                                child: _buildItemImage(),
                              )
                            : _buildItemImage(),
                      ),
                      // Quantity Badge
                      if (isInCart)
                        Positioned(
                          top: 8,
                          left: 8,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: NeuColors.accent,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              quantity.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // Item Info
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: NeuColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.description,
                        style: const TextStyle(
                          fontSize: 12,
                          color: NeuColors.textSecondary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: promotion != null
                                ? Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${item.price.toStringAsFixed(0)} ${l10n.dhs}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: NeuColors.textHint,
                                          decoration: TextDecoration.lineThrough,
                                        ),
                                      ),
                                      Text(
                                        '${promotion!.promoPrice.toStringAsFixed(0)} ${l10n.dhs}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                          color: NeuColors.accent,
                                        ),
                                      ),
                                    ],
                                  )
                                : Text(
                                    '${item.price.toStringAsFixed(2)} ${l10n.dhs}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: NeuColors.accent,
                                    ),
                                  ),
                          ),
                          if (isInCart)
                            // Quick quantity controls inline
                            Container(
                              decoration: BoxDecoration(
                                color: NeuColors.accent.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  InkWell(
                                    onTap: () {
                                      clientProvider.decrementQuantity(item.id);
                                    },
                                    child: const Padding(
                                      padding: EdgeInsets.all(4),
                                      child: Icon(Icons.remove, size: 18, color: NeuColors.accent),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 6),
                                    child: Text(
                                      '$quantity',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: NeuColors.accent,
                                      ),
                                    ),
                                  ),
                                  InkWell(
                                    onTap: () {
                                      clientProvider.incrementQuantity(item.id);
                                    },
                                    child: const Padding(
                                      padding: EdgeInsets.all(4),
                                      child: Icon(Icons.add, size: 18, color: NeuColors.accent),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else
                            IconButton(
                              icon: const Icon(
                                Icons.add_shopping_cart,
                                color: NeuColors.accent,
                              ),
                              onPressed: () => _showQuantitySelector(context, clientProvider),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
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
      },
    );
  }
}
