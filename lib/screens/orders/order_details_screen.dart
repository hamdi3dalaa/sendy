// lib/screens/orders/order_details_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../models/order_model.dart';
import '../../services/invoice_service.dart';
import 'package:intl/intl.dart';

class OrderDetailsScreen extends StatelessWidget {
  final OrderModel order;

  const OrderDetailsScreen({Key? key, required this.order}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.orderDetails),
        backgroundColor: const Color(0xFFFF5722),
        actions: [
          if (order.status == OrderStatus.delivered)
            IconButton(
              icon: const Icon(Icons.download),
              onPressed: () => InvoiceService.generateAndDownloadInvoice(order),
              tooltip: l10n.downloadInvoice,
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Order Status
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              color: _getStatusColor(order.status),
              child: Column(
                children: [
                  Icon(
                    _getStatusIcon(order.status),
                    size: 60,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _getStatusText(order.status, l10n),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    DateFormat('dd/MM/yyyy HH:mm').format(order.createdAt),
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),

            // Client Comment
            if (order.clientComment != null && order.clientComment!.isNotEmpty)
              Card(
                margin: const EdgeInsets.all(16),
                color: Colors.orange[50],
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.comment, color: Color(0xFFFF5722)),
                          const SizedBox(width: 8),
                          Text(
                            l10n.clientComment,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        order.clientComment!,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),

            // Items
            Card(
              margin: const EdgeInsets.all(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Articles',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Divider(),
                    ...order.items.map((item) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('${item.quantity}x ${item.name}'),
                              Text(
                                '${(item.price * item.quantity).toStringAsFixed(2)} ${l10n.dhs}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        )),
                  ],
                ),
              ),
            ),

            // Price Breakdown
            Card(
              margin: const EdgeInsets.all(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildPriceRow(l10n.subtotal, order.subtotal, l10n),
                    _buildPriceRow(l10n.deliveryFee, order.deliveryFee, l10n),
                    _buildPriceRow(l10n.serviceFee, order.serviceFee, l10n),
                    const Divider(thickness: 2),
                    _buildPriceRow(l10n.total, order.total, l10n,
                        isTotal: true),
                  ],
                ),
              ),
            ),

            // Payment Method
            Card(
              margin: const EdgeInsets.all(16),
              child: ListTile(
                leading: Icon(
                  order.paymentMethod == PaymentMethod.cash
                      ? Icons.money
                      : Icons.credit_card,
                  color: const Color(0xFFFF5722),
                ),
                title: Text(l10n.paymentMethod),
                subtitle: Text(
                  order.paymentMethod == PaymentMethod.cash
                      ? l10n.cashOnDelivery
                      : l10n.cardPayment,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceRow(String label, double amount, AppLocalizations l10n,
      {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
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
              fontSize: isTotal ? 18 : 16,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isTotal ? const Color(0xFFFF5722) : null,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return Colors.orange;
      case OrderStatus.accepted:
        return Colors.blue;
      case OrderStatus.inProgress:
        return Colors.purple;
      case OrderStatus.delivered:
        return Colors.green;
      case OrderStatus.cancelled:
        return Colors.red;
    }
  }

  IconData _getStatusIcon(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return Icons.access_time;
      case OrderStatus.accepted:
        return Icons.check_circle;
      case OrderStatus.inProgress:
        return Icons.delivery_dining;
      case OrderStatus.delivered:
        return Icons.done_all;
      case OrderStatus.cancelled:
        return Icons.cancel;
    }
  }

  String _getStatusText(OrderStatus status, AppLocalizations l10n) {
    switch (status) {
      case OrderStatus.pending:
        return 'En attente';
      case OrderStatus.accepted:
        return l10n.orderAccepted;
      case OrderStatus.inProgress:
        return l10n.orderInProgress;
      case OrderStatus.delivered:
        return l10n.orderDelivered;
      case OrderStatus.cancelled:
        return 'Annulé';
    }
  }
}
