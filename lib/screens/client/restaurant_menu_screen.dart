// lib/screens/client/restaurant_menu_screen.dart
// UPDATED to work with CartItem

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:sendy/l10n/app_localizations.dart';
import '../../providers/client_provider.dart';
import '../../models/menu_item_model.dart';
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
      context.read<ClientProvider>().loadRestaurantMenu(widget.restaurant.uid);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.restaurant.name),
        backgroundColor: const Color(0xFFFF5722),
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
                color: Color(0xFFFF5722),
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
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
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
                height: 50,
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    final category = categories[index];
                    final isSelected = category == _selectedCategory;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(category),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            _selectedCategory = category;
                          });
                        },
                        selectedColor: const Color(0xFFFF5722),
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : Colors.black,
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
                    return _MenuItemCard(item: item);
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

  const _MenuItemCard({required this.item});

  void _showQuantitySelector(BuildContext context, ClientProvider clientProvider) {
    final l10n = AppLocalizations.of(context)!;
    int quantity = clientProvider.getQuantity(item.id);
    if (quantity == 0) quantity = 1;

    showModalBottomSheet(
      context: context,
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
                      color: Colors.grey[300],
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
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${item.price.toStringAsFixed(2)} ${l10n.dhs}',
                              style: const TextStyle(
                                fontSize: 16,
                                color: Color(0xFFFF5722),
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
                      Material(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: quantity > 1
                              ? () => setModalState(() => quantity--)
                              : null,
                          child: Container(
                            width: 48,
                            height: 48,
                            alignment: Alignment.center,
                            child: Icon(
                              Icons.remove,
                              color: quantity > 1 ? Colors.black : Colors.grey[400],
                              size: 28,
                            ),
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
                          ),
                        ),
                      ),
                      // Plus button
                      Material(
                        color: const Color(0xFFFF5722).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: quantity < 99
                              ? () => setModalState(() => quantity++)
                              : null,
                          child: const SizedBox(
                            width: 48,
                            height: 48,
                            child: Icon(
                              Icons.add,
                              color: Color(0xFFFF5722),
                              size: 28,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Total line
                  Text(
                    '${l10n.total}: ${(item.price * quantity).toStringAsFixed(2)} ${l10n.dhs}',
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Add to cart button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        final cp = Provider.of<ClientProvider>(ctx, listen: false);
                        if (cp.isInCart(item.id)) {
                          cp.updateQuantity(item.id, quantity);
                        } else {
                          cp.addToCart(item, quantity: quantity);
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
                      icon: const Icon(Icons.add_shopping_cart),
                      label: Text(
                        '${l10n.addedToCart} - ${(item.price * quantity).toStringAsFixed(2)} ${l10n.dhs}',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF5722),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Consumer<ClientProvider>(
      builder: (context, clientProvider, child) {
        final isInCart = clientProvider.isInCart(item.id);
        final quantity = clientProvider.getQuantity(item.id);

        return GestureDetector(
          onTap: () => _showQuantitySelector(context, clientProvider),
          child: Card(
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Image with Quantity Badge
                Expanded(
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius:
                            const BorderRadius.vertical(top: Radius.circular(12)),
                        child: item.imageUrl != null
                            ? CachedNetworkImage(
                                imageUrl: item.imageUrl!,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                placeholder: (context, url) => Container(
                                  color: Colors.grey[200],
                                  child: const Center(
                                      child: CircularProgressIndicator()),
                                ),
                                errorWidget: (context, url, error) => Container(
                                  color: Colors.grey[200],
                                  child: const Icon(Icons.restaurant, size: 40),
                                ),
                              )
                            : Container(
                                color: Colors.grey[200],
                                child: const Icon(Icons.restaurant, size: 40),
                              ),
                      ),
                      // Quantity Badge
                      if (isInCart)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: Color(0xFFFF5722),
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
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.description,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${item.price.toStringAsFixed(2)} ${l10n.dhs}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Color(0xFFFF5722),
                            ),
                          ),
                          if (isInCart)
                            // Quick quantity controls inline
                            Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF5722).withOpacity(0.1),
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
                                      child: Icon(Icons.remove, size: 18, color: Color(0xFFFF5722)),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 6),
                                    child: Text(
                                      '$quantity',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: Color(0xFFFF5722),
                                      ),
                                    ),
                                  ),
                                  InkWell(
                                    onTap: () {
                                      clientProvider.incrementQuantity(item.id);
                                    },
                                    child: const Padding(
                                      padding: EdgeInsets.all(4),
                                      child: Icon(Icons.add, size: 18, color: Color(0xFFFF5722)),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else
                            IconButton(
                              icon: const Icon(
                                Icons.add_shopping_cart,
                                color: Color(0xFFFF5722),
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
