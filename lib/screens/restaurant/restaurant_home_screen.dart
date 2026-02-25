import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sendy/l10n/app_localizations.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../providers/auth_provider.dart';
import '../../providers/menu_provider.dart';
import '../../models/user_model.dart';
import '../../services/ai_image_service.dart';
import 'menu_management_screen.dart';
import 'invoice_history_screen.dart';
import 'dish_promotions_screen.dart';
import '../../providers/client_provider.dart';
import '../../models/order_model.dart';
import '../../providers/order_provider.dart';
import '../../theme/neumorphic_theme.dart';

class RestaurantHomeScreen extends StatefulWidget {
  const RestaurantHomeScreen({Key? key}) : super(key: key);

  @override
  State<RestaurantHomeScreen> createState() => _RestaurantHomeScreenState();
}

class _RestaurantHomeScreenState extends State<RestaurantHomeScreen> {
  bool _isInitialized = false;
  bool _isLoggingOut = false;
  bool _isAiLogoAnalyzing = false;
  bool _isAiLogoGenerating = false;
  String? _aiLogoSuggestions;

  @override
  void initState() {
    super.initState();
    // Load menu data after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeMenu();
    });
  }

  Future<void> _initializeMenu() async {
    if (_isInitialized || !mounted) return;

    final authProvider = context.read<AuthProvider>();
    final menuProvider = context.read<MenuProvider>();
    final orderProvider = context.read<OrderProvider>();

    if (authProvider.currentUser?.uid != null) {
      // Load menu and orders in parallel
      await Future.wait([
        menuProvider.loadMenuItems(authProvider.currentUser!.uid),
        // Load restaurant orders
        _loadRestaurantOrders(orderProvider, authProvider.currentUser!.uid),
      ]).then((_) {
        if (mounted) {
          setState(() {
            _isInitialized = true;
          });
        }
      }).catchError((error) {
        print('Error loading data: $error');
        if (mounted) {
          setState(() {
            _isInitialized = true;
          });
        }
      });
    }
  }

  Future<void> _loadRestaurantOrders(
      OrderProvider orderProvider, String restaurantId) async {
    try {
      // You can implement this in OrderProvider or use the stream
      print('Loading orders for restaurant: $restaurantId');
    } catch (e) {
      print('Error loading orders: $e');
    }
  }

  Future<void> _refreshData() async {
    final authProvider = context.read<AuthProvider>();
    final menuProvider = context.read<MenuProvider>();
    final orderProvider = context.read<OrderProvider>();

    if (authProvider.currentUser?.uid != null) {
      await Future.wait([
        menuProvider.loadMenuItems(authProvider.currentUser!.uid),
        _loadRestaurantOrders(orderProvider, authProvider.currentUser!.uid),
      ]);
    }
  }

  Future<void> _refreshMenu() async {
    final authProvider = context.read<AuthProvider>();
    final menuProvider = context.read<MenuProvider>();

    if (authProvider.currentUser?.uid != null) {
      await menuProvider.loadMenuItems(authProvider.currentUser!.uid);
    }
  }

  void _handleLogout() async {
    if (_isLoggingOut) return;

    // Show confirmation dialog first (non-blocking)
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Déconnexion'),
        content: const Text('Voulez-vous vraiment vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Déconnexion',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() {
      _isLoggingOut = true;
    });

    // Perform logout in background
    try {
      await context.read<AuthProvider>().signOut();
    } catch (e) {
      print('Error during logout: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la déconnexion: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoggingOut = false;
        });
      }
    }
  }

  void _navigateToMenuManagement() {
    // Use async navigation without blocking
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const MenuManagementScreen(),
      ),
    ).then((result) {
      // Refresh menu after returning (non-blocking)
      if (mounted && result == true) {
        _refreshMenu();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final authProvider = Provider.of<AuthProvider>(context);
    final menuProvider = Provider.of<MenuProvider>(context);
    final restaurantName =
        authProvider.currentUser?.restaurantName ?? 'Restaurant';

    return Scaffold(
      backgroundColor: NeuColors.background,
      appBar: AppBar(
        title: Text(restaurantName),
        backgroundColor: NeuColors.accent,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshMenu,
            tooltip: l10n.refresh,
          ),
          if (_isLoggingOut)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: _handleLogout,
              tooltip: l10n.logout,
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshMenu,
        child: menuProvider.isLoading && !_isInitialized
            ? const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(NeuColors.accent),
                ),
              )
            : _buildContent(context, l10n, restaurantName, menuProvider),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToMenuManagement,
        backgroundColor: NeuColors.accent,
        icon: const Icon(Icons.menu_book),
        label: Text(l10n.manageMenu),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    AppLocalizations l10n,
    String restaurantName,
    MenuProvider menuProvider,
  ) {
    final authProvider = Provider.of<AuthProvider>(context);
    final restaurantUser = authProvider.currentUser != null
        ? RestaurantUser.fromUserModel(authProvider.currentUser!)
        : null;
    final totalItems = menuProvider.menuItems.length;
    final approvedCount = menuProvider.approvedItems.length;
    final pendingCount = menuProvider.pendingItems.length;
    final rejectedCount = menuProvider.rejectedItems.length;
    final availableCount =
        menuProvider.approvedItems.where((item) => item.isAvailable).length;

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Restaurant Header with Logo
          Center(
            child: Column(
              children: [
                GestureDetector(
                  onTap: () => _uploadLogo(context, l10n),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(50),
                        child: authProvider.currentUser?.profileImageUrl != null
                            ? CachedNetworkImage(
                                imageUrl:
                                    authProvider.currentUser!.profileImageUrl!,
                                width: 100,
                                height: 100,
                                fit: BoxFit.cover,
                                placeholder: (_, __) => Container(
                                  width: 100,
                                  height: 100,
                                  color: NeuColors.background,
                                  child: const CircularProgressIndicator(),
                                ),
                                errorWidget: (_, __, ___) => Container(
                                  width: 100,
                                  height: 100,
                                  color: NeuColors.background,
                                  child: const Icon(Icons.restaurant,
                                      size: 50, color: NeuColors.accent),
                                ),
                              )
                            : Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  color: NeuColors.accent.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(50),
                                ),
                                child: const Icon(Icons.restaurant,
                                    size: 50, color: NeuColors.accent),
                              ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: NeuColors.accent,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.camera_alt,
                              size: 16, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
                if (authProvider.currentUser?.hasPendingImageChange == true)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.orange[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.orange[200]!),
                      ),
                      child: Text(
                        l10n.pendingImageApproval,
                        style:
                            TextStyle(fontSize: 12, color: Colors.orange[800]),
                      ),
                    ),
                  ),
                const SizedBox(height: 20),
                Text(
                  restaurantName,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: NeuColors.textPrimary,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                const Text(
                  'Espace Restaurant',
                  style: TextStyle(fontSize: 18, color: NeuColors.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // AI Logo buttons
          _buildAiLogoButtons(context, l10n, authProvider),

          // AI Logo suggestions
          if (_aiLogoSuggestions != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF3E8FF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFD8B4FE)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.auto_fix_high, size: 18, color: Color(0xFF7C3AED)),
                      const SizedBox(width: 8),
                      Text(l10n.aiSuggestions, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF7C3AED))),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => setState(() => _aiLogoSuggestions = null),
                        child: const Icon(Icons.close, size: 18, color: Color(0xFF7C3AED)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(_aiLogoSuggestions!, style: const TextStyle(fontSize: 13, color: NeuColors.textPrimary)),
                ],
              ),
            ),
          ],

          const SizedBox(height: 16),

          // Availability Toggle Card
          _buildAvailabilityCard(context, l10n, authProvider),
          const SizedBox(height: 16),

          // Working Hours Card
          _buildWorkingHoursCard(context, l10n, authProvider),
          const SizedBox(height: 20),

          // Menu Statistics Card
          Container(
            decoration: NeuDecoration.raised(),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.menu_book,
                        color: NeuColors.accent,
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        l10n.myMenu,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: NeuColors.textPrimary,
                            ),
                      ),
                      const Spacer(),
                      if (totalItems > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: NeuColors.accent.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '$totalItems plat${totalItems > 1 ? 's' : ''}',
                            style: const TextStyle(
                              color: NeuColors.accent,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const Divider(height: 24),

                  // Status Stats
                  if (totalItems > 0) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatColumn(
                          label: l10n.approvedItems,
                          count: approvedCount,
                          color: NeuColors.success,
                          icon: Icons.check_circle,
                        ),
                        _buildStatColumn(
                          label: l10n.pendingItems,
                          count: pendingCount,
                          color: Colors.orange,
                          icon: Icons.pending,
                        ),
                        _buildStatColumn(
                          label: l10n.rejectedItems,
                          count: rejectedCount,
                          color: NeuColors.error,
                          icon: Icons.cancel,
                        ),
                      ],
                    ),

                    // Available items indicator
                    if (approvedCount > 0) ...[
                      const Divider(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.visibility,
                            size: 20,
                            color: NeuColors.success,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '$availableCount/$approvedCount plat${approvedCount > 1 ? 's' : ''} disponible${availableCount > 1 ? 's' : ''}',
                            style: const TextStyle(
                              color: NeuColors.success,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],

                    const SizedBox(height: 16),
                  ] else ...[
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.restaurant_menu,
                              size: 60,
                              color: NeuColors.textHint,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              l10n.noMenuItems,
                              style: const TextStyle(
                                fontSize: 16,
                                color: NeuColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              l10n.startAddingDishes,
                              style: const TextStyle(
                                fontSize: 14,
                                color: NeuColors.textHint,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],

                  // Manage button
                  ElevatedButton.icon(
                    onPressed: _navigateToMenuManagement,
                    icon: const Icon(Icons.edit),
                    label: Text(
                      totalItems > 0 ? l10n.manageMyMenu : l10n.createMenu,
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: NeuColors.accent,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),

                  // Pending items warning
                  if (pendingCount > 0) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange[200]!),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.orange[700]),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Vous avez $pendingCount plat${pendingCount > 1 ? 's' : ''} en attente d\'approbation',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.orange[900],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Rejected items warning
                  if (rejectedCount > 0) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red[200]!),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.warning_outlined, color: Colors.red[700]),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              '$rejectedCount plat${rejectedCount > 1 ? 's' : ''} rejeté${rejectedCount > 1 ? 's' : ''} - Vérifiez les raisons',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.red[900],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Invoice History Card
          Container(
            decoration: NeuDecoration.raised(radius: 12),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              clipBehavior: Clip.antiAlias,
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: NeuColors.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.receipt_long, color: NeuColors.success),
                ),
                title: Text(
                  l10n.invoiceHistory,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: NeuColors.textPrimary),
                ),
                subtitle: Text(l10n.ordersSummary,
                    style: const TextStyle(color: NeuColors.textSecondary)),
                trailing: const Icon(Icons.arrow_forward_ios,
                    size: 16, color: NeuColors.textHint),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const InvoiceHistoryScreen(),
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Dish Promotions Card
          Container(
            decoration: NeuDecoration.raised(radius: 12),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              clipBehavior: Clip.antiAlias,
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: NeuColors.accent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.local_offer, color: NeuColors.accent),
                ),
                title: Text(
                  l10n.dishPromotions,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: NeuColors.textPrimary),
                ),
                subtitle: Text(l10n.managePromotions,
                    style: const TextStyle(color: NeuColors.textSecondary)),
                trailing: const Icon(Icons.arrow_forward_ios,
                    size: 16, color: NeuColors.textHint),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const DishPromotionsScreen(),
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 20),
          _buildOrdersSection(context, l10n, authProvider.currentUser!.uid),
        ],
      ),
    );
  }

  Widget _buildAiLogoButtons(
    BuildContext context,
    AppLocalizations l10n,
    AuthProvider authProvider,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Generate logo with AI
        _isAiLogoGenerating
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF7C3AED)),
                ),
              )
            : TextButton.icon(
                onPressed: () => _generateLogoWithAi(context, l10n, authProvider),
                icon: const Icon(Icons.auto_awesome, size: 16, color: Color(0xFF7C3AED)),
                label: Text(
                  l10n.aiGenerateLogo,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF7C3AED)),
                ),
              ),
        // Analyze logo (only if has image)
        if (authProvider.currentUser?.profileImageUrl != null) ...[
          const SizedBox(width: 8),
          _isAiLogoAnalyzing
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF7C3AED)),
                  ),
                )
              : TextButton.icon(
                  onPressed: () => _analyzeLogoWithAi(context, l10n, authProvider),
                  icon: const Icon(Icons.auto_fix_high, size: 16, color: Color(0xFF7C3AED)),
                  label: Text(
                    l10n.aiAnalyzeLogo,
                    style: const TextStyle(fontSize: 12, color: Color(0xFF7C3AED)),
                  ),
                ),
        ],
      ],
    );
  }

  Future<void> _analyzeLogoWithAi(
    BuildContext context,
    AppLocalizations l10n,
    AuthProvider authProvider,
  ) async {
    final imageUrl = authProvider.currentUser?.profileImageUrl;
    if (imageUrl == null) return;

    setState(() {
      _isAiLogoAnalyzing = true;
      _aiLogoSuggestions = null;
    });

    try {
      // Download the image to a temp file for analysis
      final httpClient = await HttpClient().getUrl(Uri.parse(imageUrl));
      final response = await httpClient.close();
      final dir = await Directory.systemTemp.createTemp();
      final file = File('${dir.path}/logo_temp.jpg');
      await response.pipe(file.openWrite());

      final locale = Localizations.localeOf(context).languageCode;
      final restaurantName = authProvider.currentUser?.restaurantName ?? '';

      final result = await AiImageService().analyzeLogoPhoto(
        file,
        restaurantName,
        language: locale,
      );

      if (mounted) {
        setState(() {
          _isAiLogoAnalyzing = false;
          _aiLogoSuggestions = result ?? l10n.aiAnalysisError;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isAiLogoAnalyzing = false;
          _aiLogoSuggestions = l10n.aiAnalysisError;
        });
      }
    }
  }

  Future<void> _generateLogoWithAi(
    BuildContext context,
    AppLocalizations l10n,
    AuthProvider authProvider,
  ) async {
    final promptController = TextEditingController();
    final restaurantName = authProvider.currentUser?.restaurantName ?? '';

    final prompt = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.aiGenerateLogo),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.aiLogoPromptDescription,
              style: const TextStyle(fontSize: 13, color: NeuColors.textSecondary),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: promptController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: l10n.aiLogoPromptHint,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, promptController.text.trim()),
            style: ElevatedButton.styleFrom(backgroundColor: NeuColors.accent),
            child: Text(l10n.generate),
          ),
        ],
      ),
    );

    if (prompt == null || prompt.isEmpty) return;

    setState(() => _isAiLogoGenerating = true);

    final generatedFile = await AiImageService().generateLogoImage(
      restaurantName,
      prompt,
    );

    if (mounted) {
      setState(() => _isAiLogoGenerating = false);

      if (generatedFile != null) {
        // Upload the generated logo
        final success = await authProvider.uploadProfileImage(generatedFile);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(success ? l10n.imageUploadSuccess : l10n.imageUploadError),
              backgroundColor: success ? NeuColors.success : NeuColors.error,
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.aiGenerationError),
            backgroundColor: NeuColors.error,
          ),
        );
      }
    }
  }

  Widget _buildAvailabilityCard(
    BuildContext context,
    AppLocalizations l10n,
    AuthProvider authProvider,
  ) {
    final isAvailable = authProvider.currentUser?.isAvailable ?? true;

    return Container(
      decoration: NeuDecoration.raised(radius: 12),
      child: SwitchListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        secondary: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isAvailable
                ? NeuColors.success.withOpacity(0.1)
                : NeuColors.error.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            isAvailable ? Icons.store : Icons.store_outlined,
            color: isAvailable ? NeuColors.success : NeuColors.error,
          ),
        ),
        title: Text(
          isAvailable ? l10n.restaurantOpen : l10n.restaurantClosed,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isAvailable ? NeuColors.success : NeuColors.error,
          ),
        ),
        subtitle: Text(
          isAvailable
              ? l10n.restaurantReceivingOrders
              : l10n.restaurantNotReceivingOrders,
          style: const TextStyle(fontSize: 12, color: NeuColors.textSecondary),
        ),
        value: isAvailable,
        activeColor: NeuColors.success,
        onChanged: (value) {
          authProvider.updateRestaurantAvailability(value);
        },
      ),
    );
  }

  Widget _buildWorkingHoursCard(
    BuildContext context,
    AppLocalizations l10n,
    AuthProvider authProvider,
  ) {
    final user = authProvider.currentUser;
    final openTime = user?.openTime ?? '';
    final closeTime = user?.closeTime ?? '';
    final hasHours = openTime.isNotEmpty && closeTime.isNotEmpty;

    return Container(
      decoration: NeuDecoration.raised(radius: 12),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: NeuColors.accent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.schedule, color: NeuColors.accent),
          ),
          title: Text(
            l10n.workingHours,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: NeuColors.textPrimary,
            ),
          ),
          subtitle: Text(
            hasHours ? '$openTime - $closeTime' : l10n.notConfigured,
            style: TextStyle(
              fontSize: 13,
              color: hasHours ? NeuColors.textPrimary : NeuColors.textHint,
            ),
          ),
          trailing: const Icon(Icons.edit, size: 20, color: NeuColors.accent),
          onTap: () => _showWorkingHoursDialog(context, l10n, authProvider),
        ),
      ),
    );
  }

  Future<void> _showWorkingHoursDialog(
    BuildContext context,
    AppLocalizations l10n,
    AuthProvider authProvider,
  ) async {
    final user = authProvider.currentUser;
    TimeOfDay openTime = const TimeOfDay(hour: 8, minute: 0);
    TimeOfDay closeTime = const TimeOfDay(hour: 22, minute: 0);

    // Parse existing hours
    if (user?.openTime != null && user!.openTime!.contains(':')) {
      final parts = user.openTime!.split(':');
      openTime = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    }
    if (user?.closeTime != null && user!.closeTime!.contains(':')) {
      final parts = user.closeTime!.split(':');
      closeTime = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    }

    final result = await showDialog<Map<String, TimeOfDay>>(
      context: context,
      builder: (ctx) => _WorkingHoursDialog(
        initialOpen: openTime,
        initialClose: closeTime,
        l10n: l10n,
      ),
    );

    if (result != null && mounted) {
      final open = result['open']!;
      final close = result['close']!;
      final openStr = '${open.hour.toString().padLeft(2, '0')}:${open.minute.toString().padLeft(2, '0')}';
      final closeStr = '${close.hour.toString().padLeft(2, '0')}:${close.minute.toString().padLeft(2, '0')}';
      await authProvider.updateRestaurantHours(openStr, closeStr);
    }
  }

  Widget _buildOrdersSection(
      BuildContext context, AppLocalizations l10n, String restaurantId) {
    return Container(
      decoration: NeuDecoration.raised(radius: 12),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.shopping_bag,
                  color: NeuColors.accent,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Text(
                  l10n.ordersSection,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: NeuColors.textPrimary,
                      ),
                ),
              ],
            ),
            const Divider(height: 24),

            // Use StreamBuilder to get real-time order counts
            StreamBuilder<List<OrderModel>>(
              stream: context.read<OrderProvider>().getOrdersForUser(
                    restaurantId,
                    UserType.restaurant,
                  ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20.0),
                      child: CircularProgressIndicator(
                        valueColor:
                            AlwaysStoppedAnimation<Color>(NeuColors.accent),
                      ),
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Text(
                        'Erreur: ${snapshot.error}',
                        style: const TextStyle(color: NeuColors.error),
                      ),
                    ),
                  );
                }

                final orders = snapshot.data ?? [];

                // Calculate order counts by status
                final pendingCount =
                    orders.where((o) => o.status == OrderStatus.pending).length;
                final acceptedCount = orders
                    .where((o) => o.status == OrderStatus.accepted)
                    .length;
                final inProgressCount = orders
                    .where((o) => o.status == OrderStatus.inProgress)
                    .length;

                return Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildStatColumn(
                          icon: Icons.pending,
                          label: 'En attente',
                          count: pendingCount,
                          color: Colors.orange,
                        ),
                        _buildStatColumn(
                          icon: Icons.check_circle,
                          label: 'Acceptées',
                          count: acceptedCount,
                          color: NeuColors.success,
                        ),
                        _buildStatColumn(
                          icon: Icons.local_shipping,
                          label: 'En livraison',
                          count: inProgressCount,
                          color: Colors.blue,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (orders.isEmpty)
                      const Center(
                        child: Text(
                          'Aucune commande active',
                          style: TextStyle(
                            fontSize: 14,
                            color: NeuColors.textSecondary,
                          ),
                        ),
                      )
                    else
                      Center(
                        child: Text(
                          '${orders.length} commande${orders.length > 1 ? 's' : ''} au total',
                          style: const TextStyle(
                            fontSize: 14,
                            color: NeuColors.textPrimary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _uploadLogo(BuildContext context, AppLocalizations l10n) async {
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
    final success =
        await authProvider.uploadProfileImage(File(pickedFile.path));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text(success ? l10n.imageUploadSuccess : l10n.imageUploadError),
          backgroundColor: success ? NeuColors.success : NeuColors.error,
        ),
      );
    }
  }

  Widget _buildStatColumn({
    required String label,
    required int count,
    required Color color,
    required IconData icon,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 8),
        Text(
          count.toString(),
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: NeuColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

/// Dialog for setting restaurant working hours
class _WorkingHoursDialog extends StatefulWidget {
  final TimeOfDay initialOpen;
  final TimeOfDay initialClose;
  final AppLocalizations l10n;

  const _WorkingHoursDialog({
    required this.initialOpen,
    required this.initialClose,
    required this.l10n,
  });

  @override
  State<_WorkingHoursDialog> createState() => _WorkingHoursDialogState();
}

class _WorkingHoursDialogState extends State<_WorkingHoursDialog> {
  late TimeOfDay _openTime;
  late TimeOfDay _closeTime;

  @override
  void initState() {
    super.initState();
    _openTime = widget.initialOpen;
    _closeTime = widget.initialClose;
  }

  String _formatTime(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = widget.l10n;

    return AlertDialog(
      title: Text(l10n.workingHours),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Open time
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.login, color: NeuColors.success),
            title: Text(l10n.openTime),
            trailing: TextButton(
              onPressed: () async {
                final picked = await showTimePicker(
                  context: context,
                  initialTime: _openTime,
                );
                if (picked != null) {
                  setState(() => _openTime = picked);
                }
              },
              child: Text(
                _formatTime(_openTime),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: NeuColors.accent,
                ),
              ),
            ),
          ),
          const Divider(),
          // Close time
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.logout, color: NeuColors.error),
            title: Text(l10n.closeTime),
            trailing: TextButton(
              onPressed: () async {
                final picked = await showTimePicker(
                  context: context,
                  initialTime: _closeTime,
                );
                if (picked != null) {
                  setState(() => _closeTime = picked);
                }
              },
              child: Text(
                _formatTime(_closeTime),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: NeuColors.accent,
                ),
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context, {
              'open': _openTime,
              'close': _closeTime,
            });
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: NeuColors.accent,
            foregroundColor: Colors.white,
          ),
          child: Text(l10n.save),
        ),
      ],
    );
  }
}
