// lib/screens/delivery/available_orders_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:sendy/l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../providers/order_provider.dart';
import '../../models/order_model.dart';
import '../../models/user_model.dart';
import '../../theme/neumorphic_theme.dart';
import 'delivery_active_order_screen.dart';

class AvailableOrdersScreen extends StatefulWidget {
  const AvailableOrdersScreen({Key? key}) : super(key: key);

  @override
  State<AvailableOrdersScreen> createState() => _AvailableOrdersScreenState();
}

class _AvailableOrdersScreenState extends State<AvailableOrdersScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Cache restaurant names
  final Map<String, String> _restaurantNames = {};
  final Map<String, String> _restaurantCities = {};
  final Map<String, String> _restaurantAddresses = {};

  Future<String> _getRestaurantName(String restaurantId) async {
    if (_restaurantNames.containsKey(restaurantId)) {
      return _restaurantNames[restaurantId]!;
    }
    try {
      final doc = await _firestore.collection('users').doc(restaurantId).get();
      if (doc.exists) {
        final data = doc.data()!;
        final name = data['restaurantName'] ?? data['name'] ?? 'Restaurant';
        _restaurantNames[restaurantId] = name;
        _restaurantCities[restaurantId] = data['city'] ?? '';
        _restaurantAddresses[restaurantId] = data['restaurantAddress'] ?? '';
        return name;
      }
    } catch (e) {
      print('Error getting restaurant name: $e');
    }
    return 'Restaurant';
  }

  Future<List<OrderModel>> _filterOrdersByCity(
      List<OrderModel> orders, String deliveryCity) async {
    if (deliveryCity.isEmpty) return orders; // No city set, show all

    final filtered = <OrderModel>[];
    for (final order in orders) {
      // Get restaurant city for this order
      final restaurantId = order.restaurantId;
      if (!_restaurantCities.containsKey(restaurantId)) {
        await _getRestaurantName(restaurantId);
      }
      final restaurantCity =
          _restaurantCities[restaurantId]?.toLowerCase().trim() ?? '';
      if (restaurantCity.isEmpty || restaurantCity == deliveryCity) {
        filtered.add(order);
      }
    }
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final authProvider = Provider.of<AuthProvider>(context);
    final currentUser = authProvider.currentUser;

    return Scaffold(
      backgroundColor: NeuColors.background,
      appBar: AppBar(
        title: Text(l10n.availableOrders),
        backgroundColor: NeuColors.accent,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('orders')
            .where('status', isEqualTo: OrderStatus.accepted.index)
            .where('deliveryPersonId', isNull: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(NeuColors.accent),
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                '${l10n.error}: ${snapshot.error}',
                style: const TextStyle(color: NeuColors.textSecondary),
              ),
            );
          }

          final allOrders = snapshot.data?.docs
                  .map((doc) =>
                      OrderModel.fromMap(doc.data() as Map<String, dynamic>))
                  .toList() ??
              [];

          // Filter by delivery person's city using restaurant city
          final deliveryCity = currentUser?.city?.toLowerCase().trim() ?? '';

          return FutureBuilder<List<OrderModel>>(
            future: _filterOrdersByCity(allOrders, deliveryCity),
            builder: (context, filteredSnapshot) {
              final orders = filteredSnapshot.data ?? [];

              if (orders.isEmpty && allOrders.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.delivery_dining,
                          size: 80, color: NeuColors.textHint),
                      const SizedBox(height: 16),
                      Text(
                        l10n.noAvailableOrders,
                        style: const TextStyle(
                          fontSize: 18,
                          color: NeuColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.ordersWillAppearHere,
                        style: const TextStyle(color: NeuColors.textHint),
                      ),
                    ],
                  ),
                );
              }

              if (orders.isEmpty && allOrders.isNotEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.location_off,
                          size: 80, color: NeuColors.textHint),
                      const SizedBox(height: 16),
                      Text(
                        l10n.noOrdersInYourCity,
                        style: const TextStyle(
                          fontSize: 18,
                          color: NeuColors.textSecondary,
                        ),
                      ),
                      if (deliveryCity.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          '${l10n.cityLabel}: ${currentUser?.city}',
                          style: const TextStyle(color: NeuColors.textHint),
                        ),
                      ],
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: orders.length,
                itemBuilder: (context, index) {
                  return _buildOrderCard(orders[index], currentUser, l10n);
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildOrderCard(
      OrderModel order, UserModel? currentUser, AppLocalizations l10n) {
    return FutureBuilder<String>(
      future: _getRestaurantName(order.restaurantId),
      builder: (context, snapshot) {
        final restaurantName = snapshot.data ?? '...';
        final restaurantCity =
            _restaurantCities[order.restaurantId] ?? '';
        final restaurantAddress =
            _restaurantAddresses[order.restaurantId] ?? '';

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: NeuDecoration.raised(radius: 16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Restaurant info header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: NeuColors.accent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.restaurant,
                          color: NeuColors.accent),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            restaurantName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: NeuColors.textPrimary,
                            ),
                          ),
                          if (restaurantCity.isNotEmpty)
                            Row(
                              children: [
                                const Icon(Icons.location_city,
                                    size: 14, color: NeuColors.textHint),
                                const SizedBox(width: 4),
                                Text(
                                  restaurantCity,
                                  style: const TextStyle(
                                    color: NeuColors.textSecondary,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          if (restaurantAddress.isNotEmpty)
                            Row(
                              children: [
                                const Icon(Icons.pin_drop,
                                    size: 14, color: NeuColors.textHint),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    restaurantAddress,
                                    style: const TextStyle(
                                      color: NeuColors.textSecondary,
                                      fontSize: 12,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${order.total.toStringAsFixed(2)} ${l10n.dhs}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: NeuColors.accent,
                          ),
                        ),
                        Text(
                          '${l10n.deliveryFee}: ${order.deliveryFee.toStringAsFixed(0)} ${l10n.dhs}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: NeuColors.success,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const Divider(height: 24, color: NeuColors.textHint),

                // Order items
                ...order.items.map((item) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          Text(
                            '${item.quantity}x',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: NeuColors.accent),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              item.name,
                              style: const TextStyle(color: NeuColors.textPrimary),
                            ),
                          ),
                          Text(
                            '${(item.price * item.quantity).toStringAsFixed(2)} ${l10n.dhs}',
                            style: const TextStyle(color: NeuColors.textSecondary),
                          ),
                        ],
                      ),
                    )),

                // Customer comment
                if (order.clientComment != null &&
                    order.clientComment!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.yellow[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.yellow[200]!),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.comment, size: 18, color: Colors.orange[700]),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.clientComment,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: Colors.orange[800],
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                order.clientComment!,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: NeuColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Delivery address
                if (order.deliveryAddress != null &&
                    order.deliveryAddress!.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.location_on,
                          size: 18, color: NeuColors.error),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '${l10n.deliveryAddress}: ${order.deliveryAddress}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: NeuColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 8),
                // Order time
                Row(
                  children: [
                    const Icon(Icons.access_time, size: 16, color: NeuColors.textHint),
                    const SizedBox(width: 4),
                    Text(
                      DateFormat('dd/MM/yyyy HH:mm').format(order.createdAt),
                      style: const TextStyle(
                        fontSize: 12,
                        color: NeuColors.textHint,
                      ),
                    ),
                    const Spacer(),
                    if (order.clientName != null)
                      Text(
                        order.clientName!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: NeuColors.textSecondary,
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 12),
                // Accept button
                SizedBox(
                  width: double.infinity,
                  child: GestureDetector(
                    onTap: () => _acceptOrder(order, currentUser, l10n),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [NeuColors.success, Color(0xFF00D2A0)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: NeuColors.success.withOpacity(0.3),
                            offset: const Offset(0, 4),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.check_circle, color: Colors.white),
                          const SizedBox(width: 8),
                          Text(
                            l10n.acceptDelivery,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _acceptOrder(
      OrderModel order, UserModel? currentUser, AppLocalizations l10n) async {
    if (currentUser == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.confirmAcceptDelivery),
        content: Text(l10n.confirmAcceptDeliveryMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: NeuColors.success),
            child: Text(l10n.acceptOrder),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final orderProvider = context.read<OrderProvider>();
      await orderProvider.acceptOrderByDelivery(
          order.orderId, currentUser.uid);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.orderAcceptedSuccess),
            backgroundColor: NeuColors.success,
          ),
        );

        // Navigate to active delivery screen with map
        final updatedOrder = order.copyWith(
          deliveryPersonId: currentUser.uid,
          status: OrderStatus.inProgress,
        );
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                DeliveryActiveOrderScreen(order: updatedOrder),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.error}: $e'),
            backgroundColor: NeuColors.error,
          ),
        );
      }
    }
  }
}
