// lib/screens/admin/admin_panel_screen.dart
import 'package:flutter/material.dart';
import 'package:sendy/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import '../../providers/admin_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/order_provider.dart';
import '../../models/settlement_model.dart';
import '../../theme/neumorphic_theme.dart';
import 'pending_users_screen.dart';
import 'pending_menu_items_screen.dart';
import 'pending_image_changes_screen.dart';
import 'pending_settlements_screen.dart';
import 'delivery_fees_screen.dart';
import '../../screens/admin/config_management_screen.dart';
import '../../models/user_model.dart';

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({Key? key}) : super(key: key);

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final adminProvider = context.read<AdminProvider>();
    await Future.wait([
      adminProvider.loadPendingUsers(),
      adminProvider.loadPendingMenuItems(),
      adminProvider.loadPendingImageChanges(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final adminProvider = Provider.of<AdminProvider>(context);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: NeuColors.background,
      appBar: AppBar(
        title: Text(l10n.adminPanel),
        backgroundColor: NeuColors.accent,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: l10n.refresh,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => authProvider.signOut(),
            tooltip: l10n.logout,
          ),
        ],
      ),
      body: adminProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header
                    Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [NeuColors.accent, NeuColors.accentLight],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: NeuColors.accent.withOpacity(0.3),
                            offset: const Offset(0, 4),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.admin_panel_settings,
                              size: 60,
                              color: Colors.white,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              l10n.adminPanel,
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              l10n.manageApprovalsAndConfig,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Pending Users Section
                    _buildSectionCard(
                      title: l10n.pendingUsers,
                      icon: Icons.people,
                      iconColor: Colors.blue,
                      count: adminProvider.pendingUsers.length,
                      children: [
                        _buildStatTile(
                          l10n.deliveryPersons,
                          adminProvider.pendingDelivery.length,
                          Icons.delivery_dining,
                          Colors.orange,
                          () => _navigateToPendingUsers(UserType.delivery),
                        ),
                        const Divider(height: 1),
                        _buildStatTile(
                          l10n.restaurants,
                          adminProvider.pendingRestaurants.length,
                          Icons.restaurant,
                          Colors.green,
                          () => _navigateToPendingUsers(UserType.restaurant),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Pending Menu Items
                    _buildSectionCard(
                      title: l10n.pendingDishes,
                      icon: Icons.menu_book,
                      iconColor: Colors.purple,
                      count: adminProvider.pendingMenuItems.length,
                      children: [
                        ListTile(
                          leading:
                              const Icon(Icons.fastfood, color: Colors.purple),
                          title: Text(
                            '${adminProvider.pendingMenuItems.length} ${l10n.dishesToValidate}',
                            style: const TextStyle(color: NeuColors.textPrimary),
                          ),
                          trailing:
                              const Icon(Icons.arrow_forward_ios, size: 16),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const PendingMenuItemsScreen(),
                              ),
                            ).then((_) => _loadData());
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Pending Image Changes
                    if (adminProvider.pendingImageUsers.isNotEmpty)
                      _buildActionCard(
                        title: l10n.pendingImageChanges,
                        subtitle: '${adminProvider.pendingImageUsers.length} ${l10n.pendingImageChanges.toLowerCase()}',
                        icon: Icons.image,
                        iconColor: Colors.teal,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const PendingImageChangesScreen(),
                            ),
                          ).then((_) => _loadData());
                        },
                      ),
                    if (adminProvider.pendingImageUsers.isNotEmpty)
                      const SizedBox(height: 16),

                    // Pending Settlements
                    StreamBuilder<List<SettlementModel>>(
                      stream: context
                          .read<OrderProvider>()
                          .getPendingSettlements(),
                      builder: (context, snapshot) {
                        final count = snapshot.data?.length ?? 0;
                        if (count == 0) return const SizedBox();
                        return Column(
                          children: [
                            _buildActionCard(
                              title: l10n.pendingSettlements,
                              subtitle:
                                  '$count ${l10n.settlementsToReview}',
                              icon: Icons.account_balance_wallet,
                              iconColor: Colors.red,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const PendingSettlementsScreen(),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 16),
                          ],
                        );
                      },
                    ),

                    // Delivery Fees Table
                    StreamBuilder<List<Map<String, dynamic>>>(
                      stream: context
                          .read<OrderProvider>()
                          .getAllDeliveryPersonsWithFees(),
                      builder: (context, snapshot) {
                        final persons = snapshot.data ?? [];
                        final overThreshold = persons
                            .where((p) =>
                                (p['owedAmount'] as double) >= 100.0)
                            .length;
                        final subtitle = overThreshold > 0
                            ? '$overThreshold ${l10n.overThreshold}'
                            : l10n.deliveryFeesSubtitle;
                        return Column(
                          children: [
                            _buildActionCard(
                              title: l10n.deliveryFeesTitle,
                              subtitle: subtitle,
                              icon: Icons.monetization_on,
                              iconColor: overThreshold > 0
                                  ? Colors.red
                                  : Colors.amber[700]!,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const DeliveryFeesScreen(),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 16),
                          ],
                        );
                      },
                    ),

                    // Configuration
                    _buildActionCard(
                      title: l10n.appConfig,
                      subtitle: l10n.appConfigSubtitle,
                      icon: Icons.settings,
                      iconColor: NeuColors.accent,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const ConfigManagementScreen(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),

                    // Quick Stats
                    Row(
                      children: [
                        Expanded(
                          child: _buildQuickStatCard(
                            l10n.totalPending,
                            (adminProvider.pendingUsers.length +
                                    adminProvider.pendingMenuItems.length)
                                .toString(),
                            Icons.pending_actions,
                            Colors.orange,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildQuickStatCard(
                            l10n.deliveryPersons,
                            adminProvider.pendingDelivery.length.toString(),
                            Icons.delivery_dining,
                            Colors.blue,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildQuickStatCard(
                            l10n.restaurants,
                            adminProvider.pendingRestaurants.length.toString(),
                            Icons.restaurant,
                            Colors.green,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildQuickStatCard(
                            l10n.dishes,
                            adminProvider.pendingMenuItems.length.toString(),
                            Icons.fastfood,
                            Colors.purple,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    required int count,
    required List<Widget> children,
  }) {
    return Container(
      decoration: NeuDecoration.raised(),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(icon, color: iconColor, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: NeuColors.textPrimary,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    count.toString(),
                    style: TextStyle(
                      color: iconColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ...children,
        ],
      ),
    );
  }

  Widget _buildStatTile(
    String title,
    int count,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(title, style: const TextStyle(color: NeuColors.textPrimary)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              count.toString(),
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.arrow_forward_ios, size: 16),
        ],
      ),
      onTap: onTap,
    );
  }

  Widget _buildActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: NeuDecoration.raised(),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          leading: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor),
          ),
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, color: NeuColors.textPrimary),
          ),
          subtitle: Text(subtitle, style: const TextStyle(color: NeuColors.textSecondary)),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: onTap,
        ),
      ),
    );
  }

  Widget _buildQuickStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      decoration: NeuDecoration.raised(),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: NeuColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _navigateToPendingUsers(UserType userType) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PendingUsersScreen(userType: userType),
      ),
    ).then((_) => _loadData());
  }
}
