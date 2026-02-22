// lib/screens/admin/delivery_fees_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sendy/l10n/app_localizations.dart';
import '../../providers/order_provider.dart';

class DeliveryFeesScreen extends StatefulWidget {
  const DeliveryFeesScreen({Key? key}) : super(key: key);

  @override
  State<DeliveryFeesScreen> createState() => _DeliveryFeesScreenState();
}

class _DeliveryFeesScreenState extends State<DeliveryFeesScreen> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.deliveryFeesTitle),
        backgroundColor: const Color(0xFFFF5722),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: l10n.searchByNameOrPhone,
                prefixIcon: const Icon(Icons.search, color: Color(0xFFFF5722)),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: Color(0xFFFF5722), width: 2),
                ),
              ),
              onChanged: (value) {
                setState(() => _searchQuery = value.toLowerCase());
              },
            ),
          ),

          // Table
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: context
                  .read<OrderProvider>()
                  .getAllDeliveryPersonsWithFees(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.delivery_dining,
                            size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        Text(l10n.noDeliveryPersonsFound,
                            style: const TextStyle(
                                fontSize: 16, color: Colors.grey)),
                      ],
                    ),
                  );
                }

                // Filter by search query
                var deliveryPersons = snapshot.data!;
                if (_searchQuery.isNotEmpty) {
                  deliveryPersons = deliveryPersons.where((p) {
                    final name = (p['name'] as String).toLowerCase();
                    final phone = (p['phoneNumber'] as String).toLowerCase();
                    final amount = (p['owedAmount'] as double)
                        .toStringAsFixed(0);
                    return name.contains(_searchQuery) ||
                        phone.contains(_searchQuery) ||
                        amount.contains(_searchQuery);
                  }).toList();
                }

                // Sort: highest owed amount first
                deliveryPersons.sort((a, b) =>
                    (b['owedAmount'] as double)
                        .compareTo(a['owedAmount'] as double));

                // Count those over 100 DH
                final overThreshold = deliveryPersons
                    .where((p) => (p['owedAmount'] as double) >= 100.0)
                    .length;

                // Total owed
                final totalOwed = deliveryPersons.fold<double>(
                    0.0, (sum, p) => sum + (p['owedAmount'] as double));

                return Column(
                  children: [
                    // Summary row
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      color: Colors.grey[100],
                      child: Row(
                        children: [
                          _buildSummaryChip(
                            l10n.totalDeliveryPersons,
                            deliveryPersons.length.toString(),
                            Colors.blue,
                          ),
                          const SizedBox(width: 12),
                          _buildSummaryChip(
                            l10n.overThreshold,
                            overThreshold.toString(),
                            Colors.red,
                          ),
                          const SizedBox(width: 12),
                          _buildSummaryChip(
                            l10n.totalOwed,
                            '${totalOwed.toStringAsFixed(0)} ${l10n.dhs}',
                            const Color(0xFFFF5722),
                          ),
                        ],
                      ),
                    ),

                    // Table header
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF5722).withOpacity(0.1),
                      ),
                      child: Row(
                        children: [
                          const SizedBox(width: 4),
                          Expanded(
                            flex: 3,
                            child: Text(l10n.name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13)),
                          ),
                          Expanded(
                            flex: 3,
                            child: Text(l10n.phone,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13)),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(l10n.amountDue,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13),
                                textAlign: TextAlign.end),
                          ),
                          const SizedBox(width: 8),
                        ],
                      ),
                    ),
                    const Divider(height: 1),

                    // Table rows
                    Expanded(
                      child: ListView.separated(
                        itemCount: deliveryPersons.length,
                        separatorBuilder: (_, __) =>
                            const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final person = deliveryPersons[index];
                          final owedAmount =
                              person['owedAmount'] as double;
                          final isOverThreshold = owedAmount >= 100.0;

                          return Container(
                            color: isOverThreshold
                                ? Colors.red.withOpacity(0.05)
                                : null,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            child: Row(
                              children: [
                                // Warning icon for 100+ DH
                                if (isOverThreshold)
                                  const Padding(
                                    padding: EdgeInsets.only(right: 4),
                                    child: Icon(Icons.warning_amber,
                                        color: Colors.red, size: 18),
                                  )
                                else
                                  const SizedBox(width: 4),

                                // Name
                                Expanded(
                                  flex: 3,
                                  child: Text(
                                    person['name']?.isNotEmpty == true
                                        ? person['name']
                                        : '-',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: isOverThreshold
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),

                                // Phone
                                Expanded(
                                  flex: 3,
                                  child: Text(
                                    person['phoneNumber'] ?? '-',
                                    style: const TextStyle(fontSize: 13),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),

                                // Amount
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    '${owedAmount.toStringAsFixed(0)} ${l10n.dhs}',
                                    textAlign: TextAlign.end,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: isOverThreshold
                                          ? Colors.red
                                          : owedAmount > 0
                                              ? const Color(0xFFFF5722)
                                              : Colors.grey,
                                    ),
                                  ),
                                ),

                                const SizedBox(width: 8),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryChip(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(fontSize: 10, color: color),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
