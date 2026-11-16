import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:google_fonts/google_fonts.dart";
import "package:billing_pos_app/core/theme/app_colors.dart";
import "package:billing_pos_app/core/utilities/currency_formatter.dart";
import "package:billing_pos_app/features/dashboard/models/dashboard_models.dart";
import "package:billing_pos_app/features/dashboard/presentation/dashboard_state.dart";
import "package:billing_pos_app/features/users/presentation/widgets/create_admin_dialog.dart";
import "package:billing_pos_app/shared/widgets/glass_card.dart";
import "package:billing_pos_app/shared/widgets/app_loader.dart";
import "package:billing_pos_app/shared/widgets/status_badge.dart";

class SAdminDashboardView extends ConsumerWidget {
  const SAdminDashboardView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sadminAsync = ref.watch(sadminDashboardProvider);

    return sadminAsync.when(
      loading: () => const Center(
        child: AppLoader(message: "Initializing Super Admin Intelligence..."),
      ),
      error: (err, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: 12),
            Text(
              "Failed to load SAdmin dashboard: $err",
              style: GoogleFonts.dmSans(),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => ref.invalidate(sadminDashboardProvider),
              child: Text("Retry", style: GoogleFonts.dmSans(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
      data: (data) => _buildContent(context, data, ref),
    );
  }

  Widget _buildContent(BuildContext context, SAdminDashboardModel data, WidgetRef ref) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth > 900;
        final isMobile = constraints.maxWidth < 650;

        return SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 12 : 22,
            vertical: isMobile ? 14 : 20,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildShopProfileHeader(context, data.shop, isMobile),
              const SizedBox(height: 16),
              _buildSAdminQuickActions(context, ref),
              const SizedBox(height: 18),
              _buildKpiMetrics(context, data),
              const SizedBox(height: 18),

              if (isDesktop)
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
                )
              else
                Column(
                  children: [
                    _buildAppHealthCard(context, data.appHealth),
                    const SizedBox(height: 18),
                    _buildDeviceStatusCard(context, data),
                    const SizedBox(height: 18),
                    _buildAuditLogCard(context, data.recentAuditActivities),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildShopProfileHeader(BuildContext context, ShopInfoModel shop, bool isMobile) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GlassCard(
      borderRadius: 20,
      glowColor: AppColors.neonPurple,
      glowOpacity: isDark ? 0.16 : 0.08,
      gradient: LinearGradient(
        colors: isDark
            ? [
                const Color(0xFF1E1B4B),
                const Color(0xFF0F172A),
              ]
            : [
                AppColors.primaryContainer.withValues(alpha: 0.6),
                Colors.white,
              ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      padding: EdgeInsets.all(isMobile ? 16 : 22),
      child: isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.neonPurple.withValues(alpha: isDark ? 0.25 : 0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.neonPurple.withValues(alpha: 0.4),
                        ),
                      ),
                      child: const Icon(Icons.storefront_rounded, color: AppColors.neonPurple, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            shop.companyName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.dmSans(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: isDark ? Colors.white : AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "${shop.shopName} • ${shop.businessType}",
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.dmSans(
                              color: isDark ? Colors.white70 : AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  "Support: ${shop.contactNumber}  |  ${shop.email}",
                  style: GoogleFonts.dmSans(
                    color: isDark ? Colors.white54 : AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.neonEmerald.withValues(alpha: isDark ? 0.20 : 0.12),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.neonEmerald.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_circle_rounded, size: 12, color: AppColors.neonEmerald),
                      const SizedBox(width: 5),
                      Text(
                        "SINGLE SHOP ACTIVE",
                        style: GoogleFonts.dmSans(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: AppColors.neonEmerald,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            )
          : Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.neonPurple.withValues(alpha: isDark ? 0.25 : 0.15),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppColors.neonPurple.withValues(alpha: 0.4),
                    ),
                  ),
                  child: const Icon(Icons.storefront_rounded, color: AppColors.neonPurple, size: 28),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        shop.companyName,
                        style: GoogleFonts.dmSans(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        "${shop.shopName} • ${shop.businessType} • Currency: ${shop.currencyCode}",
                        style: GoogleFonts.dmSans(
                          color: isDark ? Colors.white70 : AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "Support: ${shop.contactNumber}  |  ${shop.email}",
                        style: GoogleFonts.dmSans(
                          color: isDark ? Colors.white54 : AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.neonEmerald.withValues(alpha: isDark ? 0.20 : 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.neonEmerald.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_circle_rounded, size: 14, color: AppColors.neonEmerald),
                      const SizedBox(width: 6),
                      Text(
                        "SINGLE SHOP ACTIVE",
                        style: GoogleFonts.dmSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: AppColors.neonEmerald,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildSAdminQuickActions(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GlassCard(
      borderRadius: 18,
      glowColor: AppColors.neonPurple,
      glowOpacity: isDark ? 0.12 : 0.05,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.neonPurple.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.bolt_rounded, color: AppColors.neonPurple, size: 18),
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  "Super Admin Operations — Admin Profile Creation",
                  style: GoogleFonts.dmSans(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              // Create Admin Profile
              ElevatedButton.icon(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => const CreateAdminDialog(),
                  );
                },
                icon: const Icon(Icons.admin_panel_settings_rounded, size: 16),
                label: const Text("Create Admin Profile", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
              ),

              // Refresh Metrics
              OutlinedButton.icon(
                onPressed: () => ref.invalidate(sadminDashboardProvider),
                icon: const Icon(Icons.refresh_rounded, size: 16, color: AppColors.neonCyan),
                label: const Text("Refresh SAdmin Metrics", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  side: BorderSide(
                    color: isDark ? AppColors.neonCyan.withValues(alpha: 0.4) : AppColors.outlineLight,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKpiMetrics(BuildContext context, SAdminDashboardModel data) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final int columns;
        final double spacing;

        if (w >= 900) {
          columns = 4;
          spacing = 16;
        } else if (w >= 540) {
          columns = 2;
          spacing = 14;
        } else if (w >= 360) {
          columns = 2;
          spacing = 10;
        } else {
          columns = 1;
          spacing = 10;
        }

        final itemWidth = (w - (spacing * (columns - 1))) / columns;
        final isCompact = itemWidth < 210;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            SizedBox(
              width: itemWidth,
              child: _buildMetricTile(
                context: context,
                title: "Total Revenue",
                value: CurrencyFormatter.format(data.totalSalesAllTime),
                subtitle: "${data.totalInvoicesAllTime} Invoices Billed",
                icon: Icons.monetization_on_outlined,
                neonColor: AppColors.neonEmerald,
                isCompact: isCompact,
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: _buildMetricTile(
                context: context,
                title: "System Users",
                value: "${data.activeUsers} / ${data.totalUsers}",
                subtitle: "Active / Total Accounts",
                icon: Icons.group_outlined,
                neonColor: AppColors.neonCyan,
                isCompact: isCompact,
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: _buildMetricTile(
                context: context,
                title: "Registered Devices",
                value: "${data.registeredDevices}",
                subtitle: "${data.offlineDevices} Standalone",
                icon: Icons.devices_outlined,
                neonColor: AppColors.neonViolet,
                isCompact: isCompact,
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: _buildMetricTile(
                context: context,
                title: "Cloud Sync Engine",
                value: data.syncFailures == 0 ? "Optimal" : "${data.syncFailures} Failed",
                subtitle: "${data.appHealth.pendingSyncRecords} Pending Outbox",
                icon: Icons.sync_rounded,
                neonColor: data.syncFailures == 0 ? AppColors.neonEmerald : AppColors.neonAmber,
                isCompact: isCompact,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMetricTile({
    required BuildContext context,
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color neonColor,
    required bool isCompact,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GlassCard(
      borderRadius: 16,
      glowColor: neonColor,
      glowOpacity: isDark ? 0.14 : 0.06,
      padding: EdgeInsets.all(isCompact ? 12 : 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.dmSans(
                    fontSize: isCompact ? 11.5 : 13,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white70 : AppColors.textSecondary,
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.all(isCompact ? 6 : 8),
                decoration: BoxDecoration(
                  color: neonColor.withValues(alpha: isDark ? 0.20 : 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: neonColor.withValues(alpha: isDark ? 0.40 : 0.30),
                  ),
                ),
                child: Icon(icon, size: isCompact ? 15 : 18, color: neonColor),
              ),
            ],
          ),
          SizedBox(height: isCompact ? 8 : 12),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              maxLines: 1,
              style: GoogleFonts.dmSans(
                fontSize: isCompact ? 18 : 22,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.4,
                color: isDark ? Colors.white : AppColors.textPrimary,
              ),
            ),
          ),
          SizedBox(height: isCompact ? 4 : 4),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.dmSans(
              fontSize: isCompact ? 10 : 12,
              color: isDark ? Colors.white54 : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppHealthCard(BuildContext context, AppHealthModel health) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GlassCard(
      borderRadius: 18,
      glowColor: AppColors.neonCyan,
      glowOpacity: isDark ? 0.10 : 0.04,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 4,
                    height: 18,
                    decoration: BoxDecoration(
                      color: AppColors.neonCyan,
                      borderRadius: BorderRadius.circular(4),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.neonCyan.withValues(alpha: 0.6),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    "Cloud Infrastructure Health",
                    style: GoogleFonts.dmSans(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              StatusBadge(
                label: health.status.toUpperCase(),
                type: BadgeType.success,
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildHealthRow(context, "Lakebase Neon Cloud DB", health.databaseConnection, Icons.cloud_done_rounded, AppColors.neonCyan),
          _buildHealthRow(context, "Local SQLite Cache", health.localDbStatus, Icons.storage_rounded, AppColors.neonEmerald),
          _buildHealthRow(context, "Pending Sync Queue", "${health.pendingSyncRecords} in queue", Icons.sync_rounded, AppColors.neonAmber),
          _buildHealthRow(context, "Host Server UTC", health.serverTimeUtc, Icons.schedule_rounded, isDark ? Colors.white54 : Colors.grey),
        ],
      ),
    );
  }

  Widget _buildHealthRow(BuildContext context, String title, String val, IconData icon, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.dmSans(
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white70 : AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(width: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              val,
              style: GoogleFonts.dmSans(
                fontSize: 12.5,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceStatusCard(BuildContext context, SAdminDashboardModel data) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GlassCard(
      borderRadius: 18,
      glowColor: AppColors.neonEmerald,
      glowOpacity: isDark ? 0.08 : 0.03,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 4,
                    height: 18,
                    decoration: BoxDecoration(
                      color: AppColors.neonEmerald,
                      borderRadius: BorderRadius.circular(4),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.neonEmerald.withValues(alpha: 0.6),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    "Connected POS Terminal Nodes",
                    style: GoogleFonts.dmSans(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.neonEmerald.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  "${data.registeredDevices} Nodes",
                  style: GoogleFonts.dmSans(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: AppColors.neonEmerald,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildDeviceRow("DEV-POS-01 (Main Counter)", "Online • Synchronized", Icons.desktop_windows_rounded, AppColors.neonEmerald, "ONLINE"),
          Divider(height: 14, color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.05)),
          _buildDeviceRow("DEV-POS-02 (Billing Counter 2)", "Online • Idle & Ready", Icons.point_of_sale_rounded, AppColors.neonCyan, "ONLINE"),
          Divider(height: 14, color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.05)),
          _buildDeviceRow("DEV-POS-MOB (Mobile App)", "Standby • Local Cache", Icons.tablet_android_rounded, AppColors.neonAmber, "STANDBY"),
        ],
      ),
    );
  }

  Widget _buildDeviceRow(String name, String sub, IconData icon, Color color, String status) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.dmSans(fontWeight: FontWeight.bold, fontSize: 12.5)),
                Text(sub, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.dmSans(fontSize: 10.5, color: AppColors.textSecondary)),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              status,
              style: GoogleFonts.dmSans(fontSize: 8.5, fontWeight: FontWeight.bold, color: color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAuditLogCard(BuildContext context, List<String> logs) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GlassCard(
      borderRadius: 18,
      glowColor: AppColors.neonViolet,
      glowOpacity: isDark ? 0.08 : 0.03,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 4,
                    height: 18,
                    decoration: BoxDecoration(
                      color: AppColors.neonViolet,
                      borderRadius: BorderRadius.circular(4),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.neonViolet.withValues(alpha: 0.6),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    "Security & Audit Trail",
                    style: GoogleFonts.dmSans(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const Icon(Icons.security_rounded, size: 16, color: AppColors.neonViolet),
            ],
          ),
          const SizedBox(height: 14),
          if (logs.isEmpty)
            Text(
              "No recent activities recorded.",
              style: GoogleFonts.dmSans(color: isDark ? Colors.white54 : AppColors.textSecondary, fontSize: 12),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: logs.length,
              separatorBuilder: (_, __) => Divider(
                height: 14,
                color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.05),
              ),
              itemBuilder: (context, i) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 5.0),
                      child: Container(
                        width: 5,
                        height: 5,
                        decoration: const BoxDecoration(
                          color: AppColors.neonViolet,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        logs[i],
                        style: GoogleFonts.dmSans(
                          fontSize: 11.5,
                          color: isDark ? Colors.white70 : AppColors.textPrimary,
                        ),
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
