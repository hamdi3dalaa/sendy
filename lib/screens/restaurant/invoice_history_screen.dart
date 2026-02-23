// lib/screens/restaurant/invoice_history_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:sendy/l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../models/order_model.dart';
import '../../services/invoice_service.dart';
import '../../theme/neumorphic_theme.dart';

class InvoiceHistoryScreen extends StatefulWidget {
  const InvoiceHistoryScreen({Key? key}) : super(key: key);

  @override
  State<InvoiceHistoryScreen> createState() => _InvoiceHistoryScreenState();
}

class _InvoiceHistoryScreenState extends State<InvoiceHistoryScreen> {
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
          .where('restaurantId', isEqualTo: uid)
          .where('status', isEqualTo: OrderStatus.delivered.index);

      // Apply date filter
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
      print('Error loading orders: $e');
      setState(() => _isLoading = false);
    }
  }

  double get _totalRevenue =>
      _orders.fold(0.0, (sum, order) => sum + order.subtotal);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: NeuColors.background,
      appBar: AppBar(
        title: Text(l10n.invoiceHistory),
        backgroundColor: NeuColors.accent,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Summary card
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: NeuDecoration.accentRaised(radius: 16),
            child: Column(
              children: [
                Text(
                  l10n.totalRevenue,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${_totalRevenue.toStringAsFixed(2)} ${l10n.dhs}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${_orders.length} ${l10n.orders.toLowerCase()}',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
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
                const Text('Periode',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: NeuColors.textPrimary)),
                const SizedBox(width: 12),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildPeriodChip('all', l10n.allTime, l10n),
                        _buildPeriodChip('today', l10n.today, l10n),
                        _buildPeriodChip('week', l10n.thisWeek, l10n),
                        _buildPeriodChip('month', l10n.thisMonth, l10n),
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
                ? const Center(
                    child: CircularProgressIndicator(
                      valueColor:
                          AlwaysStoppedAnimation<Color>(NeuColors.accent),
                    ),
                  )
                : _orders.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.receipt_long,
                                size: 80, color: NeuColors.textHint),
                            const SizedBox(height: 16),
                            Text(l10n.noInvoices,
                                style: const TextStyle(
                                    fontSize: 16,
                                    color: NeuColors.textSecondary)),
                            Text(l10n.invoicesWillAppear,
                                style: const TextStyle(
                                    color: NeuColors.textHint)),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadOrders,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _orders.length,
                          itemBuilder: (context, index) =>
                              _buildOrderCard(_orders[index], l10n),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodChip(String value, String label, AppLocalizations l10n) {
    final isSelected = _selectedPeriod == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: NeuChip(
        label: label,
        isSelected: isSelected,
        onTap: () {
          setState(() => _selectedPeriod = value);
          _loadOrders();
        },
      ),
    );
  }

  Widget _buildOrderCard(OrderModel order, AppLocalizations l10n) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: NeuDecoration.raised(radius: 12),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: NeuColors.accent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.receipt, color: NeuColors.accent),
          ),
          title: Text(
            '${l10n.orderNumber} #${order.orderId.substring(0, 8).toUpperCase()}',
            style: const TextStyle(
                fontWeight: FontWeight.bold, color: NeuColors.textPrimary),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(DateFormat('dd/MM/yyyy HH:mm').format(order.createdAt),
                  style: const TextStyle(color: NeuColors.textSecondary)),
              Text(
                '${order.items.length} ${order.items.length > 1 ? l10n.articles : l10n.article}',
                style: const TextStyle(color: NeuColors.textHint),
              ),
            ],
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${order.total.toStringAsFixed(2)} ${l10n.dhs}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: NeuColors.accent,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              InkWell(
                onTap: () =>
                    InvoiceService.generateAndDownloadInvoice(order, l10n),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.download, size: 16, color: Colors.blue),
                    SizedBox(width: 4),
                    Text(
                      'Facture',
                      style: TextStyle(
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
      ),
    );
  }
}
