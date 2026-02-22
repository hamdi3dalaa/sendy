// lib/screens/delivery/delivery_home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sendy/l10n/app_localizations.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../providers/auth_provider.dart';
import '../../providers/location_provider.dart';
import '../../providers/order_provider.dart';
import '../../models/user_model.dart';
import 'delivery_invoice_history_screen.dart';
import 'settlement_upload_screen.dart';

class DeliveryHomeScreen extends StatefulWidget {
  const DeliveryHomeScreen({Key? key}) : super(key: key);

  @override
  State<DeliveryHomeScreen> createState() => _DeliveryHomeScreenState();
}

class _DeliveryHomeScreenState extends State<DeliveryHomeScreen> {
  bool _isAvailable = false;
  LocationProvider? _locationProvider;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeLocation();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _locationProvider = context.read<LocationProvider>();
  }

  Future<void> _initializeLocation() async {
    if (!mounted) return;

    final locationProvider = context.read<LocationProvider>();

    if (!locationProvider.isInitializing &&
        locationProvider.currentPosition == null) {
      await locationProvider.initializeLocation();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final authProvider = Provider.of<AuthProvider>(context);
    final locationProvider = Provider.of<LocationProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.deliveryPerson),
        backgroundColor: const Color(0xFFFF5722),
        actions: [
          // Language toggle
          TextButton(
            onPressed: () {
              final newLang = authProvider.locale.languageCode == 'fr' ? 'ar' : 'fr';
              authProvider.changeLanguage(newLang);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                authProvider.locale.languageCode == 'fr' ? 'AR' : 'FR',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => authProvider.signOut(),
          ),
        ],
      ),
      body: _buildBody(context, locationProvider, l10n),
    );
  }

  Widget _buildBody(
    BuildContext context,
    LocationProvider locationProvider,
    AppLocalizations l10n,
  ) {
    if (locationProvider.isInitializing) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF5722)),
            ),
            const SizedBox(height: 20),
            Text(
              l10n.locationInitializing,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      );
    }

    if (locationProvider.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.location_off,
                size: 80,
                color: Colors.red,
              ),
              const SizedBox(height: 20),
              Text(
                l10n.locationError,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 10),
              Text(
                locationProvider.error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 30),
              ElevatedButton.icon(
                onPressed: () => locationProvider.initializeLocation(),
                icon: const Icon(Icons.refresh),
                label: Text(l10n.retry),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF5722),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 30,
                    vertical: 15,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              if (locationProvider.error!.contains('paramètres'))
                TextButton.icon(
                  onPressed: () {
                    if (locationProvider.error!.contains('définitivement')) {
                      locationProvider.openAppSettings();
                    } else {
                      locationProvider.openLocationSettings();
                    }
                  },
                  icon: const Icon(Icons.settings),
                  label: Text(l10n.openSettings),
                ),
            ],
          ),
        ),
      );
    }

    final authProvider = Provider.of<AuthProvider>(context);

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Profile picture with upload
            GestureDetector(
              onTap: () => _uploadProfilePhoto(context, l10n),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(50),
                    child: authProvider.currentUser?.profileImageUrl != null
                        ? CachedNetworkImage(
                            imageUrl: authProvider.currentUser!.profileImageUrl!,
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => Container(
                              width: 100, height: 100,
                              color: Colors.grey[200],
                              child: const CircularProgressIndicator(),
                            ),
                            errorWidget: (_, __, ___) => Container(
                              width: 100, height: 100,
                              color: Colors.grey[200],
                              child: const Icon(Icons.delivery_dining, size: 50, color: Color(0xFFFF5722)),
                            ),
                          )
                        : Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF5722).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(50),
                            ),
                            child: const Icon(Icons.delivery_dining, size: 50, color: Color(0xFFFF5722)),
                          ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Color(0xFFFF5722),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
            if (authProvider.currentUser?.hasPendingImageChange == true)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange[200]!),
                  ),
                  child: Text(
                    l10n.pendingImageApproval,
                    style: TextStyle(fontSize: 12, color: Colors.orange[800]),
                  ),
                ),
              ),
            const SizedBox(height: 20),
            Text(
              l10n.deliverySpace,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 40),
            Card(
              elevation: 4,
              child: SwitchListTile(
                title: Text(
                  _isAvailable ? l10n.available : l10n.unavailable,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  _isAvailable
                      ? l10n.canReceiveOrders
                      : l10n.activateToReceiveOrders,
                ),
                value: _isAvailable,
                activeColor: const Color(0xFFFF5722),
                onChanged: locationProvider.currentPosition == null
                    ? null
                    : (value) {
                        setState(() {
                          _isAvailable = value;
                          if (_isAvailable) {
                            locationProvider.startTracking();
                          } else {
                            locationProvider.stopTracking();
                          }
                        });
                      },
              ),
            ),
            const SizedBox(height: 20),
            if (locationProvider.currentPosition != null)
              Card(
                elevation: 4,
                child: ListTile(
                  leading: const Icon(
                    Icons.location_on,
                    color: Color(0xFFFF5722),
                  ),
                  title: Text(l10n.currentPosition),
                  subtitle: Text(
                    'Lat: ${locationProvider.currentPosition!.latitude.toStringAsFixed(4)}\n'
                    'Lng: ${locationProvider.currentPosition!.longitude.toStringAsFixed(4)}',
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: () => locationProvider.initializeLocation(),
                    tooltip: l10n.refresh,
                  ),
                ),
              )
            else
              Card(
                elevation: 4,
                color: Colors.orange.shade50,
                child: ListTile(
                  leading: const Icon(
                    Icons.location_searching,
                    color: Colors.orange,
                  ),
                  title: Text(l10n.positionRequired),
                  subtitle: Text(
                    l10n.positionRequiredDescription,
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: () => locationProvider.initializeLocation(),
                  ),
                ),
              ),
            const SizedBox(height: 20),

            // Service Fee Balance Card
            _buildBalanceCard(context, l10n, authProvider),

            const SizedBox(height: 20),

            // Invoice History Card
            Card(
              elevation: 4,
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.receipt_long, color: Colors.green),
                ),
                title: Text(
                  l10n.invoiceHistory,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(l10n.deliverySummary),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const DeliveryInvoiceHistoryScreen(),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 20),
            Text(
              l10n.orders,
              style: const TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceCard(
      BuildContext context, AppLocalizations l10n, AuthProvider authProvider) {
    final userId = authProvider.currentUser?.uid;
    if (userId == null) return const SizedBox();

    return StreamBuilder<double>(
      stream: context.read<OrderProvider>().getOwedAmount(userId),
      builder: (context, snapshot) {
        final owedAmount = snapshot.data ?? 0.0;
        final isThresholdReached = owedAmount >= 100.0;

        return Card(
          elevation: 4,
          color: isThresholdReached ? Colors.red[50] : null,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: isThresholdReached
                ? BorderSide(color: Colors.red[300]!, width: 2)
                : BorderSide.none,
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isThresholdReached
                            ? Colors.red.withOpacity(0.1)
                            : const Color(0xFFFF5722).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.account_balance_wallet,
                        color: isThresholdReached
                            ? Colors.red
                            : const Color(0xFFFF5722),
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.serviceFeeBalance,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          Text(
                            l10n.amountOwedToSendy,
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${owedAmount.toStringAsFixed(0)} ${l10n.dhs}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                        color: isThresholdReached
                            ? Colors.red
                            : const Color(0xFFFF5722),
                      ),
                    ),
                  ],
                ),
                if (isThresholdReached) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.red[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded,
                            color: Colors.red, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            l10n.settlementRequired,
                            style: TextStyle(
                                fontSize: 12, color: Colors.red[800]),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SettlementUploadScreen(
                              owedAmount: owedAmount,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.send, size: 18),
                      label: Text(l10n.sendPayment),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _uploadProfilePhoto(BuildContext context, AppLocalizations l10n) async {
    final picker = ImagePicker();
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: Text(l10n.takePhoto),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: Text(l10n.chooseFromGallery),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    final pickedFile = await picker.pickImage(
      source: source,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );

    if (pickedFile == null || !mounted) return;

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.uploadProfileImage(File(pickedFile.path));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? l10n.imageUploadSuccess : l10n.imageUploadError),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    if (_isAvailable) {
      _locationProvider?.stopTracking();
    }
    super.dispose();
  }
}
