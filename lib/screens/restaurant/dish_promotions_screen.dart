// lib/screens/restaurant/dish_promotions_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sendy/l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../providers/menu_provider.dart';
import '../../providers/client_provider.dart';
import '../../models/menu_item_model.dart';

class DishPromotionsScreen extends StatefulWidget {
  const DishPromotionsScreen({Key? key}) : super(key: key);

  @override
  State<DishPromotionsScreen> createState() => _DishPromotionsScreenState();
}

class _DishPromotionsScreenState extends State<DishPromotionsScreen> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final authProvider = context.read<AuthProvider>();
    final restaurantId = authProvider.currentUser?.uid ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.dishPromotions),
        backgroundColor: const Color(0xFFFF5722),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddPromotionDialog(context, restaurantId),
        icon: const Icon(Icons.add),
        label: Text(l10n.addPromotion),
        backgroundColor: const Color(0xFFFF5722),
      ),
      body: StreamBuilder<List<DishPromotion>>(
        stream: context
            .read<ClientProvider>()
            .getRestaurantPromotions(restaurantId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final promotions = snapshot.data ?? [];

          if (promotions.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.local_offer,
                      size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(l10n.noPromotions,
                      style:
                          const TextStyle(fontSize: 18, color: Colors.grey)),
                  const SizedBox(height: 8),
                  Text(l10n.addPromotionHint,
                      style:
                          TextStyle(fontSize: 14, color: Colors.grey[500]),
                      textAlign: TextAlign.center),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: promotions.length,
            itemBuilder: (context, index) {
              final promo = promotions[index];
              return _buildPromotionCard(context, promo, l10n);
            },
          );
        },
      ),
    );
  }

  Widget _buildPromotionCard(
      BuildContext context, DishPromotion promo, AppLocalizations l10n) {
    final now = DateTime.now();
    final isActive = promo.isActive;
    final isExpired = now.isAfter(promo.endDate);
    final isUpcoming = now.isBefore(promo.startDate);
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    Color statusColor;
    String statusText;
    if (isExpired) {
      statusColor = Colors.grey;
      statusText = l10n.expired;
    } else if (isUpcoming) {
      statusColor = Colors.blue;
      statusText = l10n.upcoming;
    } else {
      statusColor = Colors.green;
      statusText = l10n.active;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Dish image with diagonal discount banner
                SizedBox(
                  width: 80,
                  height: 80,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Banner(
                      message: '-${promo.discountPercent}%',
                      location: BannerLocation.topEnd,
                      color: Colors.red,
                      textStyle: const TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                      child: promo.dishImageUrl != null &&
                              promo.dishImageUrl!.isNotEmpty
                          ? Image.network(
                              promo.dishImageUrl!,
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                width: 80,
                                height: 80,
                                color: Colors.grey[200],
                                child: const Icon(Icons.fastfood,
                                    color: Colors.grey),
                              ),
                            )
                          : Container(
                              width: 80,
                              height: 80,
                              color: Colors.grey[200],
                              child:
                                  const Icon(Icons.fastfood, color: Colors.grey),
                            ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(promo.dishName,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            '${promo.originalPrice.toStringAsFixed(0)} ${l10n.dhs}',
                            style: const TextStyle(
                              decoration: TextDecoration.lineThrough,
                              color: Colors.grey,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${promo.promoPrice.toStringAsFixed(0)} ${l10n.dhs}',
                            style: const TextStyle(
                              color: Color(0xFFFF5722),
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '-${promo.discountPercent}%',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Status + delete
                Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(statusText,
                          style: TextStyle(
                              color: statusColor,
                              fontSize: 11,
                              fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () => _confirmDelete(context, promo, l10n),
                      child: const Icon(Icons.delete_outline,
                          color: Colors.red, size: 22),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Divider(height: 1),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.schedule, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  '${dateFormat.format(promo.startDate)} → ${dateFormat.format(promo.endDate)}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(
      BuildContext context, DishPromotion promo, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.confirmDeletion),
        content: Text(l10n.confirmDeletePromoMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await context
                  .read<ClientProvider>()
                  .deleteDishPromotion(promo.id);
            },
            child: Text(l10n.delete,
                style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showAddPromotionDialog(BuildContext context, String restaurantId) {
    final l10n = AppLocalizations.of(context)!;
    final menuProvider = context.read<MenuProvider>();
    final authProvider = context.read<AuthProvider>();

    // Get approved menu items
    final approvedItems = menuProvider.approvedItems;

    if (approvedItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.noDishesAvailable)),
      );
      return;
    }

    MenuItem? selectedItem;
    final promoPriceController = TextEditingController();
    DateTime startDate = DateTime.now();
    DateTime endDate = DateTime.now().add(const Duration(days: 7));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(l10n.addPromotion,
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 20),

                    // Select dish
                    Text(l10n.selectDish,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<MenuItem>(
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                      ),
                      hint: Text(l10n.selectDish),
                      value: selectedItem,
                      items: approvedItems.map((item) {
                        return DropdownMenuItem(
                          value: item,
                          child: Text(
                              '${item.name} - ${item.price.toStringAsFixed(0)} ${l10n.dhs}'),
                        );
                      }).toList(),
                      onChanged: (item) {
                        setModalState(() {
                          selectedItem = item;
                        });
                      },
                    ),
                    const SizedBox(height: 16),

                    // Promo price
                    Text(l10n.promoPrice,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: promoPriceController,
                      keyboardType: TextInputType.number,
                      onChanged: (_) => setModalState(() {}),
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                        hintText: l10n.promoPrice,
                        suffixText: l10n.dhs,
                      ),
                    ),
                    if (selectedItem != null &&
                        promoPriceController.text.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Builder(builder: (_) {
                        final pp =
                            double.tryParse(promoPriceController.text) ?? 0;
                        if (pp > 0 && pp < selectedItem!.price) {
                          final disc = ((1 - pp / selectedItem!.price) * 100)
                              .round();
                          final discColor = disc >= 1 ? Colors.green : Colors.red;
                          return Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: discColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: discColor.withOpacity(0.3)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.discount, color: discColor, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  '-$disc%',
                                  style: TextStyle(
                                    color: discColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '${selectedItem!.price.toStringAsFixed(0)} → ${pp.toStringAsFixed(0)} ${l10n.dhs}',
                                  style: TextStyle(
                                    color: discColor,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                        return const SizedBox();
                      }),
                    ],
                    const SizedBox(height: 16),

                    // Start date
                    Text(l10n.startDate,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: startDate,
                          firstDate: DateTime.now(),
                          lastDate:
                              DateTime.now().add(const Duration(days: 365)),
                        );
                        if (date != null) {
                          final time = await showTimePicker(
                            context: context,
                            initialTime:
                                TimeOfDay.fromDateTime(startDate),
                          );
                          setModalState(() {
                            startDate = DateTime(
                              date.year,
                              date.month,
                              date.day,
                              time?.hour ?? 0,
                              time?.minute ?? 0,
                            );
                          });
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 14),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[400]!),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today,
                                size: 18, color: Color(0xFFFF5722)),
                            const SizedBox(width: 8),
                            Text(dateFormat.format(startDate)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // End date
                    Text(l10n.endDate,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: endDate,
                          firstDate: DateTime.now(),
                          lastDate:
                              DateTime.now().add(const Duration(days: 365)),
                        );
                        if (date != null) {
                          final time = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay.fromDateTime(endDate),
                          );
                          setModalState(() {
                            endDate = DateTime(
                              date.year,
                              date.month,
                              date.day,
                              time?.hour ?? 23,
                              time?.minute ?? 59,
                            );
                          });
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 14),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[400]!),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today,
                                size: 18, color: Color(0xFFFF5722)),
                            const SizedBox(width: 8),
                            Text(dateFormat.format(endDate)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Submit
                    ElevatedButton(
                      onPressed: () async {
                        if (selectedItem == null) return;
                        final promoPrice =
                            double.tryParse(promoPriceController.text);
                        if (promoPrice == null ||
                            promoPrice <= 0 ||
                            promoPrice >= selectedItem!.price) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(l10n.invalidPromoPrice)),
                          );
                          return;
                        }
                        // Minimum 1% discount validation
                        final discountPct = ((1 - promoPrice / selectedItem!.price) * 100).round();
                        if (discountPct < 1) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(l10n.minimumDiscountError)),
                          );
                          return;
                        }
                        if (endDate.isBefore(startDate)) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(l10n.invalidPromoDates)),
                          );
                          return;
                        }

                        final user = authProvider.currentUser;
                        final promo = DishPromotion(
                          id: '',
                          restaurantId: restaurantId,
                          restaurantName:
                              user?.restaurantName ?? user?.name ?? '',
                          menuItemId: selectedItem!.id,
                          dishName: selectedItem!.name,
                          dishImageUrl: selectedItem!.imageUrl,
                          originalPrice: selectedItem!.price,
                          promoPrice: promoPrice,
                          startDate: startDate,
                          endDate: endDate,
                          restaurantCity: user?.city,
                          restaurantImageUrl: user?.profileImageUrl,
                        );

                        await context
                            .read<ClientProvider>()
                            .addDishPromotion(promo);

                        if (ctx.mounted) Navigator.pop(ctx);
                        if (mounted) {
                          ScaffoldMessenger.of(this.context).showSnackBar(
                            SnackBar(content: Text(l10n.promotionAdded)),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF5722),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(l10n.addPromotion,
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
