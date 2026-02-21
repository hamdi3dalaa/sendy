// lib/screens/client/my_orders_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:sendy/l10n/app_localizations.dart';
import '../../providers/order_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/order_model.dart';
import '../orders/order_details_screen.dart';
import '../map/tracking_map_screen.dart';
import 'rate_order_screen.dart';

class MyOrdersScreen extends StatefulWidget {
  const MyOrdersScreen({Key? key}) : super(key: key);

  @override
  State<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends State<MyOrdersScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadOrders();
    });
  }

  Future<void> _loadOrders() async {
    final authProvider = context.read<AuthProvider>();
    final orderProvider = context.read<OrderProvider>();
    if (authProvider.currentUser != null) {
      await orderProvider.loadUserOrders(authProvider.currentUser!.uid);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Consumer2<OrderProvider, AuthProvider>(
      builder: (context, orderProvider, authProvider, child) {
        if (orderProvider.isLoading) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFFFF5722)));
        }

        final orders = orderProvider.userOrders;

        if (orders.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.receipt_long, size: 80, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(l10n.noOrders, style: TextStyle(fontSize: 18, color: Colors.grey[600])),
                const SizedBox(height: 8),
                Text(l10n.ordersWillAppear, style: TextStyle(fontSize: 14, color: Colors.grey[500])),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: _loadOrders,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];
              return _OrderCard(order: order, l10n: l10n);
            },
          ),
        );
      },
    );
  }
}

class _OrderCard extends StatelessWidget {
  final OrderModel order;
  final AppLocalizations l10n;

  const _OrderCard({required this.order, required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => OrderDetailsScreen(order: order)));
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${l10n.orderNumber} #${order.orderId.substring(0, 8)}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  _buildStatusChip(order.status),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(DateFormat('dd/MM/yyyy HH:mm').format(order.createdAt),
                      style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                ],
              ),
              const SizedBox(height: 12),
              Text('${order.items.length} ${order.items.length > 1 ? l10n.articles : l10n.article}',
                  style: TextStyle(fontSize: 14, color: Colors.grey[700])),
              const SizedBox(height: 4),
              ...order.items.take(2).map((item) => Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text('${item.quantity}x ${item.name}',
                        style: TextStyle(fontSize: 13, color: Colors.grey[600]), maxLines: 1, overflow: TextOverflow.ellipsis),
                  )),
              if (order.items.length > 2)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text('+${order.items.length - 2} ${order.items.length - 2 > 1 ? l10n.others : l10n.other}...',
                      style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(l10n.total, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text('${order.total.toStringAsFixed(2)} ${l10n.dhs}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFFFF5722))),
                ],
              ),
              if (order.status == OrderStatus.delivered)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => RateOrderScreen(order: order)));
                      },
                      icon: const Icon(Icons.star, color: Colors.amber),
                      label: Text(l10n.rateOrder),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFFF5722),
                        side: const BorderSide(color: Color(0xFFFF5722)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                ),
              if (order.status == OrderStatus.inProgress)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => TrackingMapScreen(order: order)));
                      },
                      icon: const Icon(Icons.location_on),
                      label: Text(l10n.trackOrder),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF5722),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(OrderStatus status) {
    Color color;
    String text;
    switch (status) {
      case OrderStatus.pending:
        color = Colors.orange;
        text = l10n.pending;
        break;
      case OrderStatus.accepted:
        color = Colors.blue;
        text = l10n.accepted;
        break;
      case OrderStatus.inProgress:
        color = Colors.purple;
        text = l10n.inProgress;
        break;
      case OrderStatus.delivered:
        color = Colors.green;
        text = l10n.delivered;
        break;
      case OrderStatus.cancelled:
        color = Colors.red;
        text = l10n.cancelled;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20), border: Border.all(color: color)),
      child: Text(text, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
    );
  }
}
