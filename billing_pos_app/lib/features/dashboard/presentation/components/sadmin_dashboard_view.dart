import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:billing_pos_app/core/theme/app_colors.dart";
import "package:billing_pos_app/core/utilities/currency_formatter.dart";
import "package:billing_pos_app/shared/widgets/app_card.dart";
import "package:billing_pos_app/shared/widgets/status_badge.dart";
import "package:billing_pos_app/features/dashboard/models/dashboard_models.dart";
import "package:billing_pos_app/features/dashboard/presentation/dashboard_state.dart";

class SAdminDashboardView extends ConsumerWidget {
  const SAdminDashboardView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sadminAsync = ref.watch(sadminDashboardProvider);

    return sadminAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: 12),
            Text("Failed to load SAdmin dashboard: $err"),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => ref.invalidate(sadminDashboardProvider),
              child: const Text("Retry"),
            ),
          ],
        ),
      ),
      data: (data) => _buildContent(context, data, ref),
    );
  }

  Widget _buildContent(BuildContext context, SAdminDashboardModel data, WidgetRef ref) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildShopProfileHeader(context, data.shop),
          const SizedBox(height: 20),
          _buildKpiMetrics(context, data),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: Column(
                  children: [
                    _buildAppHealthCard(context, data.appHealth),
                    const SizedBox(height: 20),
                    _buildDeviceStatusCard(context, data),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                flex: 2,
                child: _buildAuditLogCard(context, data.recentAuditActivities),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildShopProfileHeader(BuildContext context, ShopInfoModel shop) {
    return AppCard(
      backgroundColor: AppColors.primaryContainer.withValues(alpha: 0.35),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 26,
            backgroundColor: AppColors.primary,
            child: Icon(Icons.storefront, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  shop.companyName,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  "${shop.shopName}  â€¢  ${shop.businessType}  â€¢  Currency: ${shop.currencyCode}",
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
                Text(
                  "Contact: ${shop.contactNumber}  |  ${shop.email}",
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
          const StatusBadge(
            label: "SINGLE SHOP ACTIVE",
            type: BadgeType.success,
            icon: Icons.check_circle,
          ),
        ],
      ),
    );
  }

  Widget _buildKpiMetrics(BuildContext context, SAdminDashboardModel data) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = (constraints.maxWidth - 48) / 4;
        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            SizedBox(
              width: itemWidth,
              child: _buildMetricTile(
                title: "Total Revenue",
                value: CurrencyFormatter.format(data.totalSalesAllTime),
                subtitle: "${data.totalInvoicesAllTime} Invoices Billed",
                icon: Icons.monetization_on_outlined,
                color: Colors.green,
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: _buildMetricTile(
                title: "System Users",
                value: "${data.activeUsers} / ${data.totalUsers}",
                subtitle: "Active / Total Accounts",
                icon: Icons.group_outlined,
                color: AppColors.primary,
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: _buildMetricTile(
                title: "Registered Devices",
                value: "${data.registeredDevices}",
                subtitle: "${data.offlineDevices} Offline Devices",
                icon: Icons.devices_outlined,
                color: Colors.deepPurple,
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: _buildMetricTile(
                title: "Sync Status",
                value: data.syncFailures == 0 ? "Optimal" : "${data.syncFailures} Failed",
                subtitle: "${data.appHealth.pendingSyncRecords} Pending Outbox",
                icon: Icons.sync,
                color: data.syncFailures == 0 ? Colors.teal : Colors.orange,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMetricTile({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
              ),
              Icon(icon, size: 22, color: color),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildAppHealthCard(BuildContext context, AppHealthModel health) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Application Health & Architecture",
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              StatusBadge(
                label: health.status.toUpperCase(),
                type: BadgeType.success,
              ),
            ],
          ),
          const Divider(height: 24),
          _buildHealthRow("SQL Server Database", health.databaseConnection, Icons.cloud_done, Colors.blue),
          _buildHealthRow("Local SQLite Engine", health.localDbStatus, Icons.storage, Colors.indigo),
          _buildHealthRow("Pending Sync Records", "${health.pendingSyncRecords} in queue", Icons.sync, Colors.amber.shade800),
          _buildHealthRow("Server UTC Clock", health.serverTimeUtc, Icons.schedule, Colors.grey),
        ],
      ),
    );
  }

  Widget _buildHealthRow(String title, String val, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 10),
          Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
          const Spacer(),
          Text(val, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        ],
      ),
    );
  }

  Widget _buildDeviceStatusCard(BuildContext context, SAdminDashboardModel data) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "POS Device Terminals",
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          const ListTile(
            dense: true,
            leading: Icon(Icons.desktop_windows, color: Colors.green),
            title: Text("POS-MAIN-01 (Windows Counter)"),
            subtitle: Text("Status: Online  â€¢  Sync: Up-to-date"),
            trailing: StatusBadge(label: "ONLINE", type: BadgeType.success),
          ),
          const Divider(height: 1),
          const ListTile(
            dense: true,
            leading: Icon(Icons.point_of_sale, color: Colors.green),
            title: Text("POS-COUNTER-02 (POS Terminal)"),
            subtitle: Text("Status: Online  â€¢  Sync: Up-to-date"),
            trailing: StatusBadge(label: "ONLINE", type: BadgeType.success),
          ),
          const Divider(height: 1),
          const ListTile(
            dense: true,
            leading: Icon(Icons.tablet_android, color: Colors.orange),
            title: Text("POS-TABLET-03 (Android Tablet)"),
            subtitle: Text("Status: Offline  â€¢  Sync: 0 pending"),
            trailing: StatusBadge(label: "STANDALONE", type: BadgeType.warning),
          ),
        ],
      ),
    );
  }

  Widget _buildAuditLogCard(BuildContext context, List<String> logs) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "System Activities",
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const Icon(Icons.history, size: 20, color: AppColors.textSecondary),
            ],
          ),
          const SizedBox(height: 16),
          if (logs.isEmpty)
            const Text("No recent activities recorded.", style: TextStyle(color: AppColors.textSecondary))
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: logs.length,
              separatorBuilder: (_, __) => const Divider(height: 16),
              itemBuilder: (context, i) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 4.0),
                      child: Icon(Icons.circle, size: 8, color: AppColors.primary),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        logs[i],
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }
}
