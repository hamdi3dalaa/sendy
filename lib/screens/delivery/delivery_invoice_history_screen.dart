// lib/screens/delivery/delivery_invoice_history_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:sendy/l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../models/order_model.dart';
import '../../services/invoice_service.dart';

class DeliveryInvoiceHistoryScreen extends StatefulWidget {
  const DeliveryInvoiceHistoryScreen({Key? key}) : super(key: key);

  @override
  State<DeliveryInvoiceHistoryScreen> createState() =>
      _DeliveryInvoiceHistoryScreenState();
}

class _DeliveryInvoiceHistoryScreenState
    extends State<DeliveryInvoiceHistoryScreen> {
  String _selectedPeriod = 'all';
  List<OrderModel> _orders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadOrders();
    });
  }

  Future<void> _loadOrders() async {
    setState(() => _isLoading = true);

    final authProvider = context.read<AuthProvider>();
    final uid = authProvider.currentUser?.uid;
    if (uid == null) return;

    try {
      Query query = FirebaseFirestore.instance
          .collection('orders')
          .where('deliveryPersonId', isEqualTo: uid)
          .where('status', isEqualTo: OrderStatus.delivered.index);

      final now = DateTime.now();
      DateTime? startDate;

      switch (_selectedPeriod) {
        case 'today':
          startDate = DateTime(now.year, now.month, now.day);
          break;
        case 'week':
          startDate = now.subtract(const Duration(days: 7));
          break;
        case 'month':
          startDate = DateTime(now.year, now.month, 1);
          break;
        case 'all':
        default:
          break;
      }

      if (startDate != null) {
        query = query.where('createdAt',
            isGreaterThanOrEqualTo: startDate.toIso8601String());
      }

      final snapshot = await query.get();
      setState(() {
        _orders = snapshot.docs
            .map((doc) =>
                OrderModel.fromMap(doc.data() as Map<String, dynamic>))
            .toList();
        _orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading delivery orders: $e');
      setState(() => _isLoading = false);
    }
  }

  double get _totalEarnings =>
      _orders.fold(0.0, (sum, order) => sum + order.deliveryFee);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.invoiceHistory),
        backgroundColor: const Color(0xFFFF5722),
      ),
      body: Column(
        children: [
          // Summary card
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFF5722), Color(0xFFFF8A65)],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        l10n.deliveryEarnings,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${_totalEarnings.toStringAsFixed(2)} ${l10n.dhs}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 1,
                  height: 60,
                  color: Colors.white30,
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        l10n.totalDeliveries,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${_orders.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Period filter
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(l10n.period,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(width: 12),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildPeriodChip('all', l10n.allTime),
                        _buildPeriodChip('today', l10n.today),
                        _buildPeriodChip('week', l10n.thisWeek),
                        _buildPeriodChip('month', l10n.thisMonth),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Orders list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _orders.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.receipt_long,
                                size: 80, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text(l10n.noInvoices,
                                style: TextStyle(
                                    fontSize: 16, color: Colors.grey[600])),
                            Text(l10n.invoicesWillAppear,
                                style: TextStyle(color: Colors.grey[500])),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadOrders,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _orders.length,
                          itemBuilder: (context, index) =>
                              _buildDeliveryCard(_orders[index], l10n),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodChip(String value, String label) {
    final isSelected = _selectedPeriod == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        selectedColor: const Color(0xFFFF5722),
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : Colors.black87,
        ),
        onSelected: (selected) {
          if (selected) {
            setState(() => _selectedPeriod = value);
            _loadOrders();
          }
        },
      ),
    );
  }

  Widget _buildDeliveryCard(OrderModel order, AppLocalizations l10n) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.delivery_dining, color: Colors.green),
        ),
        title: Text(
          '${l10n.orderNumber} #${order.orderId.substring(0, 8).toUpperCase()}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(DateFormat('dd/MM/yyyy HH:mm').format(order.createdAt)),
            if (order.deliveryAddress != null)
              Text(
                order.deliveryAddress!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${order.deliveryFee.toStringAsFixed(2)} ${l10n.dhs}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.green,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            InkWell(
              onTap: () =>
                  InvoiceService.generateAndDownloadInvoice(order, l10n),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.download, size: 16, color: Colors.blue),
                  const SizedBox(width: 4),
                  Text(
                    l10n.invoice,
                    style: const TextStyle(
                      color: Colors.blue,
                      fontSize: 12,
                    ),
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
