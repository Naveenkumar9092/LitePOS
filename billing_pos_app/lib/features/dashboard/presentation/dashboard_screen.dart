import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:billing_pos_app/shared/widgets/status_badge.dart";
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

    final isSAdmin = user?.isSAdmin ?? false;
    final isAdmin = user?.isAdmin ?? false;
    final isCashier = user?.isCashier ?? false;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text("LitePOS Billing"),
            const SizedBox(width: 12),
            if (user != null)
              StatusBadge(
                label: user.roleName.toUpperCase(),
                type: isSAdmin
                    ? BadgeType.info
                    : isAdmin
                        ? BadgeType.success
                        : BadgeType.warning,
              ),
          ],
        ),
        actions: [
          const OfflineStatusIndicator(
            isOnline: true,
            pendingSyncCount: 0,
          ),
          const SizedBox(width: 12),
          IconButton(
            icon: const Icon(Icons.refresh),
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
      body: _buildRoleDashboard(isSAdmin, isAdmin, isCashier),
    );
  }

  Widget _buildRoleDashboard(bool isSAdmin, bool isAdmin, bool isCashier) {
    if (isSAdmin) {
      return const SAdminDashboardView();
    }
    if (isCashier) {
      return const CashierDashboardView();
    }
    // Default to Admin Dashboard
    return const AdminDashboardView();
  }
}
