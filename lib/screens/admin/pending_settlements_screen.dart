// lib/screens/admin/pending_settlements_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:sendy/l10n/app_localizations.dart';
import '../../providers/order_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/settlement_model.dart';

class PendingSettlementsScreen extends StatelessWidget {
  const PendingSettlementsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.pendingSettlements),
        backgroundColor: const Color(0xFFFF5722),
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<List<SettlementModel>>(
        stream: context.read<OrderProvider>().getPendingSettlements(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: Color(0xFFFF5722)));
          }

          final settlements = snapshot.data ?? [];

          if (settlements.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_outline,
                      size: 80, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text(
                    l10n.noSettlementsPending,
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: settlements.length,
            itemBuilder: (context, index) {
              return _SettlementCard(settlement: settlements[index]);
            },
          );
        },
      ),
    );
  }
}

class _SettlementCard extends StatelessWidget {
  final SettlementModel settlement;

  const _SettlementCard({required this.settlement});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFFFF5722),
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                const Icon(Icons.person, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        settlement.deliveryPersonName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        settlement.deliveryPersonPhone,
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${settlement.amount.toStringAsFixed(0)} ${l10n.dhs}',
                    style: const TextStyle(
                      color: Color(0xFFFF5722),
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Date
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 6),
                Text(
                  DateFormat('dd/MM/yyyy HH:mm').format(settlement.createdAt),
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
              ],
            ),
          ),

          // Proof Image
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GestureDetector(
              onTap: () => _showFullImage(context, settlement.proofImageUrl),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: settlement.proofImageUrl,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(
                    height: 200,
                    color: Colors.grey[200],
                    child: const Center(child: CircularProgressIndicator()),
                  ),
                  errorWidget: (_, __, ___) => Container(
                    height: 200,
                    color: Colors.grey[200],
                    child: const Icon(Icons.broken_image, size: 48),
                  ),
                ),
              ),
            ),
          ),

          // Action buttons
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () =>
                        _rejectSettlement(context, settlement, l10n),
                    icon: const Icon(Icons.close, size: 18),
                    label: Text(l10n.reject),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: () =>
                        _approveSettlement(context, settlement, l10n),
                    icon: const Icon(Icons.check, size: 18),
                    label: Text(l10n.approve),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showFullImage(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: CachedNetworkImage(
          imageUrl: imageUrl,
          fit: BoxFit.contain,
        ),
      ),
    );
  }

  Future<void> _approveSettlement(BuildContext context,
      SettlementModel settlement, AppLocalizations l10n) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.confirmApproval),
        content: Text(l10n.confirmSettlementApproval(
            settlement.amount.toStringAsFixed(0))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: Text(l10n.approve),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    final adminUid = context.read<AuthProvider>().currentUser?.uid ?? '';
    await context
        .read<OrderProvider>()
        .approveSettlement(settlement.settlementId, adminUid);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.settlementApproved),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _rejectSettlement(BuildContext context,
      SettlementModel settlement, AppLocalizations l10n) async {
    final reasonController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.rejectSettlement),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.rejectSettlementMessage),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              decoration: InputDecoration(
                labelText: l10n.rejectionReason,
                border: const OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(l10n.reject),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    final adminUid = context.read<AuthProvider>().currentUser?.uid ?? '';
    await context.read<OrderProvider>().rejectSettlement(
        settlement.settlementId, adminUid, reasonController.text);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.settlementRejected),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
