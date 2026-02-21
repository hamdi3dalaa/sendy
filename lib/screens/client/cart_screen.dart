// lib/screens/client/cart_screen.dart
// UPDATED with quantity controls and visible payment button

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/client_provider.dart';
import '../../providers/order_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/order_model.dart';
import 'package:uuid/uuid.dart';
import 'package:sendy/l10n/app_localizations.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class CartScreen extends StatefulWidget {
  final RestaurantModel restaurant;

  const CartScreen({
    Key? key,
    required this.restaurant,
  }) : super(key: key);

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final TextEditingController _commentController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _promoController = TextEditingController();
  bool _isLoading = false;
  bool _isGettingLocation = false;
  String? _promoError;
  List<String> _savedAddresses = [];
  String? _lastUsedAddress;

  double get _deliveryFee => 14.0;
  double get _serviceFee => 2.0;

  @override
  void initState() {
    super.initState();
    _loadSavedAddresses();
  }

  Future<void> _loadSavedAddresses() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final clientProvider = Provider.of<ClientProvider>(context, listen: false);
    final userId = authProvider.currentUser?.uid;
    if (userId == null) return;

    // Load saved addresses from ClientProvider
    final addresses = clientProvider.savedAddresses;
    final addressStrings = <String>[];
    for (final addr in addresses) {
      if (addr.address.isNotEmpty) {
        addressStrings.add(addr.address);
      }
    }

    // Get last used address from most recent order
    try {
      final snapshot = await Provider.of<OrderProvider>(context, listen: false)
          .getLastOrderAddress(userId);
      if (snapshot != null && snapshot.isNotEmpty) {
        setState(() {
          _lastUsedAddress = snapshot;
          _addressController.text = snapshot;
        });
      }
    } catch (_) {}

    if (mounted) {
      setState(() {
        _savedAddresses = addressStrings;
      });
    }
  }

  Future<void> _getLocationByGPS() async {
    setState(() => _isGettingLocation = true);
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Permission de localisation refusée'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty && mounted) {
        final place = placemarks.first;
        final address = [
          place.street,
          place.subLocality,
          place.locality,
          place.postalCode,
        ].where((s) => s != null && s.isNotEmpty).join(', ');

        setState(() {
          _addressController.text = address;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur GPS: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isGettingLocation = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.myCart),
        backgroundColor: const Color(0xFFFF5722),
      ),
      body: Consumer<ClientProvider>(
        builder: (context, clientProvider, child) {
          final l10n = AppLocalizations.of(context)!;
          final cartItems = clientProvider.cart.values.toList();

          if (cartItems.isEmpty) {
            return _buildEmptyCart();
          }

          final subtotal = clientProvider.cartTotal;
          final promoDiscount = clientProvider.promoDiscount;
          final total = subtotal + _deliveryFee + _serviceFee - promoDiscount;

          return Column(
            children: [
              // Cart Items List
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // Restaurant Header
                      _buildRestaurantHeader(),

                      // Cart Items
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: cartItems.length,
                        itemBuilder: (context, index) {
                          final cartItem = cartItems[index];
                          return _CartItemCard(cartItem: cartItem);
                        },
                      ),

                      // Delivery Address Section
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextField(
                              controller: _addressController,
                              maxLines: 2,
                              decoration: InputDecoration(
                                labelText: '${l10n.deliveryAddress} *',
                                hintText: l10n.enterFullAddress,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                prefixIcon: const Icon(Icons.location_on,
                                    color: Color(0xFFFF5722)),
                                suffixIcon: _isGettingLocation
                                    ? const Padding(
                                        padding: EdgeInsets.all(12),
                                        child: SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                              strokeWidth: 2),
                                        ),
                                      )
                                    : IconButton(
                                        icon: const Icon(Icons.my_location,
                                            color: Color(0xFFFF5722)),
                                        onPressed: _getLocationByGPS,
                                        tooltip: l10n.useGPS,
                                      ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            // GPS and saved address quick actions
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  ActionChip(
                                    avatar:
                                        const Icon(Icons.gps_fixed, size: 16),
                                    label: Text(l10n.useGPS),
                                    onPressed: _isGettingLocation
                                        ? null
                                        : _getLocationByGPS,
                                    backgroundColor: const Color(0xFFFF5722)
                                        .withOpacity(0.1),
                                  ),
                                  if (_lastUsedAddress != null &&
                                      _lastUsedAddress!.isNotEmpty &&
                                      _addressController.text !=
                                          _lastUsedAddress) ...[
                                    const SizedBox(width: 8),
                                    ActionChip(
                                      avatar:
                                          const Icon(Icons.history, size: 16),
                                      label: Text(
                                        _lastUsedAddress!.length > 25
                                            ? '${_lastUsedAddress!.substring(0, 25)}...'
                                            : _lastUsedAddress!,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _addressController.text =
                                              _lastUsedAddress!;
                                        });
                                      },
                                      backgroundColor:
                                          Colors.blue.withOpacity(0.1),
                                    ),
                                  ],
                                  ..._savedAddresses
                                      .where((a) =>
                                          a != _lastUsedAddress &&
                                          a != _addressController.text)
                                      .take(3)
                                      .map((addr) => Padding(
                                            padding:
                                                const EdgeInsets.only(left: 8),
                                            child: ActionChip(
                                              avatar: const Icon(Icons.bookmark,
                                                  size: 16),
                                              label: Text(
                                                addr.length > 20
                                                    ? '${addr.substring(0, 20)}...'
                                                    : addr,
                                              ),
                                              onPressed: () {
                                                setState(() {
                                                  _addressController.text =
                                                      addr;
                                                });
                                              },
                                            ),
                                          )),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Comment
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: TextField(
                          controller: _commentController,
                          maxLines: 3,
                          decoration: InputDecoration(
                            labelText: l10n.commentOptional,
                            hintText: l10n.specialInstructions,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            prefixIcon: const Icon(Icons.comment,
                                color: Color(0xFFFF5722)),
                          ),
                        ),
                      ),

                      // Promo Code
                      _buildPromoCodeSection(subtotal, clientProvider),

                      // Price Summary
                      _buildPriceSummary(subtotal, total, promoDiscount),

                      const SizedBox(height: 100), // Space for bottom button
                    ],
                  ),
                ),
              ),

              // Fixed Bottom Payment Button
              _buildCheckoutButton(cartItems, total),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyCart() {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 100,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 24),
          Text(
            l10n.emptyCart,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.addDishesToOrder,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.restaurant_menu),
            label: Text(l10n.viewMenu),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF5722),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRestaurantHeader() {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(
          bottom: BorderSide(color: Colors.grey[200]!),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFF5722), Color(0xFFFF7043)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.restaurant,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.restaurant,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
                Text(
                  widget.restaurant.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPromoCodeSection(
      double subtotal, ClientProvider clientProvider) {
    final l10n = AppLocalizations.of(context)!;
    final appliedPromo = clientProvider.appliedPromo;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (appliedPromo != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green[300]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green[700], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${l10n.promoApplied} -${clientProvider.promoDiscount.toStringAsFixed(2)} ${l10n.dhs}',
                      style: TextStyle(
                          color: Colors.green[700],
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      clientProvider.clearPromo();
                      _promoController.clear();
                      setState(() => _promoError = null);
                    },
                    child:
                        Icon(Icons.close, color: Colors.green[700], size: 20),
                  ),
                ],
              ),
            )
          else
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _promoController,
                    decoration: InputDecoration(
                      hintText: l10n.enterPromoCode,
                      prefixIcon: const Icon(Icons.local_offer,
                          color: Color(0xFFFF5722)),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      errorText: _promoError,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () async {
                    if (_promoController.text.trim().isEmpty) return;
                    final result = await clientProvider.validatePromoCode(
                      _promoController.text.trim(),
                      subtotal,
                    );
                    setState(() => _promoError = result);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF5722),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(l10n.apply),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildPriceSummary(
      double subtotal, double total, double promoDiscount) {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.summary,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildPriceRow(l10n.subtotal, subtotal),
            const SizedBox(height: 8),
            _buildPriceRow(l10n.deliveryFee, _deliveryFee),
            const SizedBox(height: 8),
            _buildPriceRow(l10n.serviceFee, _serviceFee),
            if (promoDiscount > 0) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(l10n.discount,
                      style: TextStyle(fontSize: 16, color: Colors.green[700])),
                  Text('-${promoDiscount.toStringAsFixed(2)} ${l10n.dhs}',
                      style: TextStyle(
                          fontSize: 16,
                          color: Colors.green[700],
                          fontWeight: FontWeight.bold)),
                ],
              ),
            ],
            const Divider(height: 24, thickness: 2),
            _buildPriceRow(l10n.total, total, isTotal: true),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceRow(String label, double amount, {bool isTotal = false}) {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 18 : 16,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          '${amount.toStringAsFixed(2)} ${l10n.dhs}',
          style: TextStyle(
            fontSize: isTotal ? 20 : 16,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            color: isTotal ? const Color(0xFFFF5722) : null,
          ),
        ),
      ],
    );
  }

  Widget _buildCheckoutButton(List<CartItem> cartItems, double total) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _isLoading ? null : () => _placeOrder(cartItems, total),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF5722),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.payment, size: 24),
                      const SizedBox(width: 12),
                      Text(
                        '${l10n.pay} ${total.toStringAsFixed(2)} ${l10n.dhs}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Future<void> _placeOrder(List<CartItem> cartItems, double total) async {
    final l10n = AppLocalizations.of(context)!;
    if (_addressController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.enterDeliveryAddress),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final orderProvider = Provider.of<OrderProvider>(context, listen: false);
      final clientProvider =
          Provider.of<ClientProvider>(context, listen: false);

      final orderItems = cartItems.map((cartItem) {
        return OrderItem(
          name: cartItem.menuItem.name,
          quantity: cartItem.quantity,
          price: cartItem.menuItem.price,
        );
      }).toList();

      final order = OrderModel(
        orderId: const Uuid().v4(),
        clientId: authProvider.currentUser!.uid,
        restaurantId: widget.restaurant.uid,
        status: OrderStatus.pending,
        items: orderItems,
        deliveryLocation: {},
        restaurantLocation: widget.restaurant.location ?? {},
        createdAt: DateTime.now(),
        subtotal: total - _deliveryFee - _serviceFee,
        deliveryFee: _deliveryFee,
        serviceFee: _serviceFee,
        total: total,
        paymentMethod: PaymentMethod.cash,
        paymentStatus: PaymentStatus.pending,
        clientComment: _commentController.text.trim().isNotEmpty
            ? _commentController.text.trim()
            : null,
        clientName: authProvider.currentUser!.name,
        clientPhone: authProvider.currentUser!.phoneNumber,
        deliveryAddress: _addressController.text.trim(),
      );

      await orderProvider.createOrder(order);

      clientProvider.clearCart();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text(l10n.orderPlacedSuccess),
              ],
            ),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.error}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    _addressController.dispose();
    super.dispose();
  }
}

class _CartItemCard extends StatelessWidget {
  final CartItem cartItem;

  const _CartItemCard({required this.cartItem});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Image
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: cartItem.menuItem.imageUrl != null
                  ? CachedNetworkImage(
                      imageUrl: cartItem.menuItem.imageUrl!,
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        width: 80,
                        height: 80,
                        color: Colors.grey[200],
                        child: const Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        width: 80,
                        height: 80,
                        color: Colors.grey[200],
                        child: const Icon(Icons.restaurant),
                      ),
                    )
                  : Container(
                      width: 80,
                      height: 80,
                      color: Colors.grey[200],
                      child: const Icon(Icons.restaurant),
                    ),
            ),
            const SizedBox(width: 12),

            // Item Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    cartItem.menuItem.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${cartItem.menuItem.price.toStringAsFixed(2)} ${l10n.dhs} ${l10n.perUnit}',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      // Quantity Controls
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            _buildQuantityButton(
                              icon: Icons.remove,
                              onPressed: () {
                                context
                                    .read<ClientProvider>()
                                    .decrementQuantity(cartItem.menuItem.id);
                              },
                            ),
                            Container(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                '${cartItem.quantity}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            _buildQuantityButton(
                              icon: Icons.add,
                              onPressed: () {
                                context
                                    .read<ClientProvider>()
                                    .incrementQuantity(cartItem.menuItem.id);
                              },
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      // Total Price
                      Text(
                        '${cartItem.totalPrice.toStringAsFixed(2)} ${l10n.dhs}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Color(0xFFFF5722),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Delete Button
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () {
                context
                    .read<ClientProvider>()
                    .removeFromCart(cartItem.menuItem.id);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(l10n.removedFromCart),
                    duration: Duration(seconds: 1),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuantityButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.all(8),
        child: Icon(icon, size: 20),
      ),
    );
  }
}
