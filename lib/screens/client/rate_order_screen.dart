// lib/screens/client/rate_order_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sendy/l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../providers/client_provider.dart';
import '../../models/order_model.dart';

class RateOrderScreen extends StatefulWidget {
  final OrderModel order;

  const RateOrderScreen({Key? key, required this.order}) : super(key: key);

  @override
  State<RateOrderScreen> createState() => _RateOrderScreenState();
}

class _RateOrderScreenState extends State<RateOrderScreen> {
  double _rating = 0;
  final _commentController = TextEditingController();
  bool _isSubmitting = false;

  String? _restaurantName;
  bool _isLoadingRestaurant = true;

  @override
  void initState() {
    super.initState();
    _loadRestaurantName();
  }

  Future<void> _loadRestaurantName() async {
    final clientProvider = context.read<ClientProvider>();
    final restaurant =
        await clientProvider.getRestaurantById(widget.order.restaurantId!);
    if (mounted) {
      setState(() {
        _restaurantName = restaurant?.name ?? 'Restaurant';
        _isLoadingRestaurant = false;
      });
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitReview() async {
    final l10n = AppLocalizations.of(context)!;
    if (_rating == 0) return;

    setState(() => _isSubmitting = true);

    try {
      final authProvider = context.read<AuthProvider>();
      final clientProvider = context.read<ClientProvider>();

      await clientProvider.submitReview(
        userId: authProvider.currentUser!.uid,
        restaurantId: widget.order.restaurantId,
        orderId: widget.order.orderId,
        rating: _rating,
        comment: _commentController.text.trim().isNotEmpty
            ? _commentController.text.trim()
            : null,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.reviewSubmitted),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
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
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.rateOrder),
        backgroundColor: const Color(0xFFFF5722),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 20),

            // Order info
            Text(
              '${l10n.orderNumber} #${widget.order.orderId.substring(0, 8)}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _isLoadingRestaurant
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    _restaurantName ?? l10n.restaurant,
                    style: TextStyle(fontSize: 18, color: Colors.grey[700]),
                  ),
            const SizedBox(height: 40),

            // Rate your experience
            Text(
              l10n.rateYourExperience,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),

            // Star Rating
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                final starValue = index + 1.0;
                return GestureDetector(
                  onTap: () => setState(() => _rating = starValue),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Icon(
                      _rating >= starValue ? Icons.star : Icons.star_border,
                      size: 48,
                      color: _rating >= starValue
                          ? Colors.amber
                          : Colors.grey[400],
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 8),
            if (_rating > 0)
              Text(
                '${_rating.toInt()}/5',
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
            const SizedBox(height: 32),

            // Comment field
            TextField(
              controller: _commentController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: l10n.writeReview,
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: Color(0xFFFF5722), width: 2),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Submit Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _rating > 0 && !_isSubmitting ? _submitReview : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF5722),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  disabledBackgroundColor: Colors.grey[300],
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        l10n.submitReview,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
