// lib/screens/client/payment_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../models/order_model.dart';
import '../../providers/order_provider.dart';
import '../../providers/auth_provider.dart';
import 'package:uuid/uuid.dart';

class PaymentScreen extends StatefulWidget {
  final List<OrderItem> cartItems;
  final String restaurantId;
  final Map<String, dynamic> restaurantLocation;

  const PaymentScreen({
    Key? key,
    required this.cartItems,
    required this.restaurantId,
    required this.restaurantLocation,
  }) : super(key: key);

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  PaymentMethod _selectedPayment = PaymentMethod.cash;
  final TextEditingController _commentController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  bool _isLoading = false;

  double get _subtotal {
    return widget.cartItems
        .fold(0, (sum, item) => sum + (item.price * item.quantity));
  }

  double get _deliveryFee => 14.0;
  double get _serviceFee => 2.0;
  double get _total => _subtotal + _deliveryFee + _serviceFee;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.paymentMethod),
        backgroundColor: const Color(0xFFFF5722),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Order Summary Card
            Card(
              margin: const EdgeInsets.all(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.orderDetails,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Divider(height: 20),
                    ...widget.cartItems.map((item) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('${item.quantity}x ${item.name}'),
                              Text('${item.price * item.quantity} ${l10n.dhs}'),
                            ],
                          ),
                        )),
                    const Divider(height: 20),
                    _buildPriceRow(l10n.subtotal, _subtotal, l10n),
                    _buildPriceRow(l10n.deliveryFee, _deliveryFee, l10n),
                    _buildPriceRow(l10n.serviceFee, _serviceFee, l10n),
                    const Divider(height: 20),
                    _buildPriceRow(
                      l10n.total,
                      _total,
                      l10n,
                      isTotal: true,
                    ),
                  ],
                ),
              ),
            ),

            // Delivery Address
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _addressController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: l10n.deliveryLocation,
                  border: const OutlineInputBorder(),
                  hintText: 'Adresse complète de livraison...',
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Comment Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _commentController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: l10n.addComment,
                  border: const OutlineInputBorder(),
                  hintText: l10n.commentPlaceholder,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Payment Methods
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.paymentMethod,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildPaymentOption(
                    PaymentMethod.cash,
                    l10n.cashOnDelivery,
                    Icons.money,
                    Colors.green,
                  ),
                  _buildPaymentOption(
                    PaymentMethod.card,
                    '${l10n.cardPayment} (${l10n.comingSoon})',
                    Icons.credit_card,
                    Colors.grey,
                    enabled: false,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // Place Order Button
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _placeOrder,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF5722),
                    padding: const EdgeInsets.all(16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          l10n.placeOrder,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
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

  Widget _buildPaymentOption(
    PaymentMethod method,
    String title,
    IconData icon,
    Color color, {
    bool enabled = true,
  }) {
    return Card(
      color: !enabled ? Colors.grey[200] : null,
      child: RadioListTile<PaymentMethod>(
        value: method,
        groupValue: _selectedPayment,
        onChanged: enabled
            ? (value) => setState(() => _selectedPayment = value!)
            : null,
        title: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 10),
            Expanded(child: Text(title)),
          ],
        ),
        activeColor: const Color(0xFFFF5722),
      ),
    );
  }

  Future<void> _placeOrder() async {
    if (_addressController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Veuillez entrer l\'adresse de livraison')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final orderProvider = Provider.of<OrderProvider>(context, listen: false);

      final order = OrderModel(
        orderId: const Uuid().v4(),
        clientId: authProvider.currentUser!.uid,
        restaurantId: widget.restaurantId,
        status: OrderStatus.pending,
        items: widget.cartItems,
        deliveryLocation: {}, // Get from GPS
        restaurantLocation: widget.restaurantLocation,
        createdAt: DateTime.now(),
        subtotal: _subtotal,
        deliveryFee: _deliveryFee,
        serviceFee: _serviceFee,
        total: _total,
        paymentMethod: _selectedPayment,
        paymentStatus: PaymentStatus.pending,
        clientComment: _commentController.text.trim().isNotEmpty
            ? _commentController.text.trim()
            : null,
        clientName: authProvider.currentUser!.phoneNumber,
        clientPhone: authProvider.currentUser!.phoneNumber,
        deliveryAddress: _addressController.text.trim(),
      );

      await orderProvider.createOrder(order);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Commande passée avec succès!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
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
