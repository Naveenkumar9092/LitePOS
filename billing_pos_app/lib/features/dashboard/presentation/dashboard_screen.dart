import "dart:ui";
import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:google_fonts/google_fonts.dart";
import "package:billing_pos_app/core/theme/app_colors.dart";
import "package:billing_pos_app/shared/widgets/app_brand_logo.dart";
import "package:billing_pos_app/shared/widgets/neon_ambient_background.dart";
import "../../authentication/presentation/auth_state.dart";
import "components/admin_dashboard_view.dart";
import "components/cashier_dashboard_view.dart";
import "components/offline_status_indicator.dart";
import "components/sadmin_dashboard_view.dart";
import "dashboard_state.dart";

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    final user = authState.user;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final isSAdmin = user?.isSAdmin ?? false;
    final isAdmin = user?.isAdmin ?? false;
    final isCashier = user?.isCashier ?? false;

    final roleNeonColor = isSAdmin
        ? AppColors.neonPurple
        : isAdmin
            ? AppColors.neonCyan
            : AppColors.neonEmerald;

    final screenWidth = MediaQuery.sizeOf(context).width;
    final isMobile = screenWidth < 600;

    return Scaffold(
      extendBodyBehindAppBar: false,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(64),
        child: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: AppBar(
              backgroundColor: isDark
                  ? const Color(0xFF0F172A).withValues(alpha: 0.75)
                  : Colors.white.withValues(alpha: 0.82),
              elevation: 0,
              scrolledUnderElevation: 0,
              titleSpacing: isMobile ? 12 : 20,
              title: Row(
                children: [
                  Flexible(
                    child: AppBrandLogo(
                      size: isMobile ? 30 : 34,
                      isDark: isDark,
                      showText: true,
                      showSubtitle: !isMobile,
                      subtitle: "Store Intelligence Hub",
                    ),
                  ),
                  if (!isMobile && user != null) ...[
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: roleNeonColor.withValues(alpha: isDark ? 0.20 : 0.12),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: roleNeonColor.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Text(
                        user.roleName.toUpperCase(),
                        style: GoogleFonts.dmSans(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          color: roleNeonColor,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              actions: [
                const OfflineStatusIndicator(
                  isOnline: true,
                  pendingSyncCount: 0,
                ),
                IconButton(
                  icon: const Icon(Icons.refresh_rounded, size: 20),
                  tooltip: "Refresh Dashboard",
                  onPressed: () {
                    if (isSAdmin) {
                      ref.invalidate(sadminDashboardProvider);
                    } else if (isAdmin) {
                      ref.invalidate(adminDashboardProvider);
                    } else {
                      ref.invalidate(cashierDashboardProvider);
                    }
                  },
                ),
                const SizedBox(width: 8),
              ],
            ),
          ),
        ),
      ),
      body: NeonAmbientBackground(
        child: _buildRoleDashboard(isSAdmin, isAdmin, isCashier),
      ),
    );
  }

  Widget _buildRoleDashboard(bool isSAdmin, bool isAdmin, bool isCashier) {
    if (isSAdmin) {
      return const SAdminDashboardView();
    }
    if (isCashier) {
      return const CashierDashboardView();
    }
    return const AdminDashboardView();
  }
}
