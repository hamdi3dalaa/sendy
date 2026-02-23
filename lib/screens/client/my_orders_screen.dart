// lib/screens/client/my_orders_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:sendy/l10n/app_localizations.dart';
import '../../providers/order_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/order_model.dart';
import '../../theme/neumorphic_theme.dart';
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

    return Container(
      color: NeuColors.background,
      child: Consumer2<OrderProvider, AuthProvider>(
        builder: (context, orderProvider, authProvider, child) {
          if (orderProvider.isLoading) {
            return const Center(child: CircularProgressIndicator(color: NeuColors.accent));
          }

          final orders = orderProvider.userOrders;

          if (orders.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: NeuDecoration.raised(radius: 40),
                    child: const Icon(Icons.receipt_long_rounded, size: 50, color: NeuColors.textHint),
                  ),
                  const SizedBox(height: 20),
                  Text(l10n.noOrders, style: const TextStyle(fontSize: 18, color: NeuColors.textSecondary, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Text(l10n.ordersWillAppear, style: const TextStyle(fontSize: 14, color: NeuColors.textHint)),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _loadOrders,
            color: NeuColors.accent,
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
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final OrderModel order;
  final AppLocalizations l10n;

  const _OrderCard({required this.order, required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: NeuDecoration.raised(radius: 16),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => OrderDetailsScreen(order: order)));
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('${l10n.orderNumber} #${order.orderId.substring(0, 8)}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: NeuColors.textPrimary)),
                    _buildStatusChip(order.status),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.access_time_rounded, size: 14, color: NeuColors.textHint),
                    const SizedBox(width: 4),
                    Text(DateFormat('dd/MM/yyyy HH:mm').format(order.createdAt),
                        style: const TextStyle(fontSize: 12, color: NeuColors.textSecondary)),
                  ],
                ),
                const SizedBox(height: 12),
                Text('${order.items.length} ${order.items.length > 1 ? l10n.articles : l10n.article}',
                    style: const TextStyle(fontSize: 14, color: NeuColors.textSecondary)),
                const SizedBox(height: 4),
                ...order.items.take(2).map((item) => Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text('${item.quantity}x ${item.name}',
                          style: const TextStyle(fontSize: 13, color: NeuColors.textHint), maxLines: 1, overflow: TextOverflow.ellipsis),
                    )),
                if (order.items.length > 2)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text('+${order.items.length - 2} ${order.items.length - 2 > 1 ? l10n.others : l10n.other}...',
                        style: const TextStyle(fontSize: 13, color: NeuColors.textHint)),
                  ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: NeuDecoration.pressed(radius: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(l10n.total, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: NeuColors.textPrimary)),
                      Text('${order.total.toStringAsFixed(2)} ${l10n.dhs}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: NeuColors.accent)),
                    ],
                  ),
                ),
                if (order.status == OrderStatus.delivered)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: SizedBox(
                      width: double.infinity,
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => RateOrderScreen(order: order)));
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: NeuDecoration.raised(radius: 10),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.star_rounded, color: Colors.amber, size: 20),
                              const SizedBox(width: 6),
                              Text(l10n.rateOrder, style: const TextStyle(color: NeuColors.accent, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                if (order.status == OrderStatus.inProgress)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: SizedBox(
                      width: double.infinity,
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => TrackingMapScreen(order: order)));
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: NeuDecoration.accentRaised(radius: 10),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.location_on_rounded, color: Colors.white, size: 20),
                              const SizedBox(width: 6),
                              Text(l10n.trackOrder, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
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
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(text, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
    );
  }
}
