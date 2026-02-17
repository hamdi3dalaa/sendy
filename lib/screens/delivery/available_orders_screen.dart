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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final authProvider = Provider.of<AuthProvider>(context);
    final currentUser = authProvider.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.availableOrders),
        backgroundColor: const Color(0xFFFF5722),
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('orders')
            .where('status', isEqualTo: OrderStatus.accepted.index)
            .where('deliveryPersonId', isNull: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('${l10n.error}: ${snapshot.error}'),
            );
          }

          final orders = snapshot.data?.docs
                  .map((doc) =>
                      OrderModel.fromMap(doc.data() as Map<String, dynamic>))
                  .toList() ??
              [];

          if (orders.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.delivery_dining,
                      size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    l10n.noAvailableOrders,
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.ordersWillAppearHere,
                    style: TextStyle(color: Colors.grey[500]),
                  ),
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

        return Card(
          elevation: 3,
          margin: const EdgeInsets.only(bottom: 16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                        color: const Color(0xFFFF5722).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.restaurant,
                          color: Color(0xFFFF5722)),
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
                            ),
                          ),
                          if (restaurantCity.isNotEmpty)
                            Row(
                              children: [
                                const Icon(Icons.location_city,
                                    size: 14, color: Colors.grey),
                                const SizedBox(width: 4),
                                Text(
                                  restaurantCity,
                                  style: TextStyle(
                                      color: Colors.grey[600], fontSize: 13),
                                ),
                              ],
                            ),
                          if (restaurantAddress.isNotEmpty)
                            Row(
                              children: [
                                const Icon(Icons.pin_drop,
                                    size: 14, color: Colors.grey),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    restaurantAddress,
                                    style: TextStyle(
                                        color: Colors.grey[600], fontSize: 12),
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
                            color: Color(0xFFFF5722),
                          ),
                        ),
                        Text(
                          '${l10n.deliveryFee}: ${order.deliveryFee.toStringAsFixed(0)} ${l10n.dhs}',
                          style: TextStyle(
                              fontSize: 12, color: Colors.green[700]),
                        ),
                      ],
                    ),
                  ],
                ),
                const Divider(height: 24),

                // Order items
                ...order.items.map((item) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          Text(
                            '${item.quantity}x',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFFF5722)),
                          ),
                          const SizedBox(width: 8),
                          Expanded(child: Text(item.name)),
                          Text(
                            '${(item.price * item.quantity).toStringAsFixed(2)} ${l10n.dhs}',
                            style: TextStyle(color: Colors.grey[600]),
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
                                style: const TextStyle(fontSize: 13),
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
                      Icon(Icons.location_on,
                          size: 18, color: Colors.red[400]),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '${l10n.deliveryAddress}: ${order.deliveryAddress}',
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 8),
                // Order time
                Row(
                  children: [
                    Icon(Icons.access_time, size: 16, color: Colors.grey[500]),
                    const SizedBox(width: 4),
                    Text(
                      DateFormat('dd/MM/yyyy HH:mm').format(order.createdAt),
                      style:
                          TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                    const Spacer(),
                    if (order.clientName != null)
                      Text(
                        order.clientName!,
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey[600]),
                      ),
                  ],
                ),

                const SizedBox(height: 12),
                // Accept button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _acceptOrder(order, currentUser, l10n),
                    icon: const Icon(Icons.check_circle),
                    label: Text(l10n.acceptDelivery),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
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
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
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
            backgroundColor: Colors.green,
          ),
        );
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
    }
  }
}
