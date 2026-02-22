// lib/screens/delivery/settlement_upload_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:sendy/l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../providers/order_provider.dart';
import '../../models/settlement_model.dart';

class SettlementUploadScreen extends StatefulWidget {
  final double owedAmount;

  const SettlementUploadScreen({
    Key? key,
    required this.owedAmount,
  }) : super(key: key);

  @override
  State<SettlementUploadScreen> createState() => _SettlementUploadScreenState();
}

class _SettlementUploadScreenState extends State<SettlementUploadScreen> {
  File? _proofImage;
  bool _isUploading = false;

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: source,
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 85,
    );

    if (pickedFile != null) {
      setState(() {
        _proofImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _submitSettlement() async {
    if (_proofImage == null || !mounted) return;

    final l10n = AppLocalizations.of(context)!;
    final authProvider = context.read<AuthProvider>();
    final orderProvider = context.read<OrderProvider>();
    final user = authProvider.currentUser;

    if (user == null) return;

    setState(() => _isUploading = true);

    try {
      // Upload proof image to Firebase Storage
      final settlementId = const Uuid().v4();
      final ref = FirebaseStorage.instance
          .ref()
          .child('settlements')
          .child('$settlementId.jpg');
      await ref.putFile(_proofImage!);
      final proofUrl = await ref.getDownloadURL();

      // Create settlement
      final settlement = SettlementModel(
        settlementId: settlementId,
        deliveryPersonId: user.uid,
        deliveryPersonName: user.displayName,
        deliveryPersonPhone: user.phoneNumber,
        amount: widget.owedAmount,
        proofImageUrl: proofUrl,
        status: SettlementStatus.pending,
        createdAt: DateTime.now(),
      );

      await orderProvider.createSettlement(settlement);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.settlementSent),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.error}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.sendPayment),
        backgroundColor: const Color(0xFFFF5722),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Amount card
            Card(
              color: const Color(0xFFFF5722),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const Icon(Icons.account_balance_wallet,
                        size: 48, color: Colors.white),
                    const SizedBox(height: 12),
                    Text(
                      l10n.amountToSend,
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${widget.owedAmount.toStringAsFixed(0)} ${l10n.dhs}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Instructions
            Text(
              l10n.uploadProofInstructions,
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
            ),

            const SizedBox(height: 16),

            // Image picker area
            GestureDetector(
              onTap: () => _showImageSourceSheet(),
              child: Container(
                height: 250,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _proofImage != null
                        ? Colors.green
                        : Colors.grey[300]!,
                    width: 2,
                    style: _proofImage != null
                        ? BorderStyle.solid
                        : BorderStyle.none,
                  ),
                ),
                child: _proofImage != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.file(_proofImage!, fit: BoxFit.cover),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: GestureDetector(
                                onTap: () =>
                                    setState(() => _proofImage = null),
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.close,
                                      color: Colors.white, size: 18),
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.cloud_upload_outlined,
                              size: 60, color: Colors.grey[400]),
                          const SizedBox(height: 12),
                          Text(
                            l10n.tapToUploadProof,
                            style: TextStyle(
                                fontSize: 15, color: Colors.grey[600]),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            l10n.proofDescription,
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey[400]),
                          ),
                        ],
                      ),
              ),
            ),

            const SizedBox(height: 24),

            // Submit button
            SizedBox(
              height: 50,
              child: ElevatedButton.icon(
                onPressed:
                    _proofImage != null && !_isUploading ? _submitSettlement : null,
                icon: _isUploading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.send),
                label: Text(
                  _isUploading ? l10n.sending : l10n.sendPayment,
                  style: const TextStyle(fontSize: 16),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showImageSourceSheet() {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: Text(l10n.takePhoto),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: Text(l10n.chooseFromGallery),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }
}
