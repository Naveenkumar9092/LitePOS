import "dart:ui";
import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:google_fonts/google_fonts.dart";
import "package:billing_pos_app/core/theme/app_colors.dart";
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
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          roleNeonColor,
                          roleNeonColor.withValues(alpha: 0.7),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: roleNeonColor.withValues(alpha: 0.4),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.point_of_sale_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    "LitePOS Billing",
                    style: GoogleFonts.dmSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                      color: isDark ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  if (user != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: roleNeonColor,
                        ),
                      ),
                    ),
                ],
              ),
              actions: [
                const OfflineStatusIndicator(
                  isOnline: true,
                  pendingSyncCount: 0,
                ),
                const SizedBox(width: 10),
                IconButton(
                  icon: const Icon(Icons.refresh_rounded),
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
                const SizedBox(width: 16),
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
