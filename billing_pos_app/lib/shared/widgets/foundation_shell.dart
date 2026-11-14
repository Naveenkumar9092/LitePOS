import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:go_router/go_router.dart";
import "../../core/routing/route_names.dart";
import "../../core/theme/app_colors.dart";
import "../../core/utilities/responsive_layout.dart";
import "../../features/authentication/presentation/auth_state.dart";

class FoundationShell extends ConsumerStatefulWidget {
  final Widget child;

  const FoundationShell({super.key, required this.child});

  @override
  ConsumerState<FoundationShell> createState() => _FoundationShellState();
}

class _FoundationShellState extends ConsumerState<FoundationShell> {
  int _calculateSelectedIndex(BuildContext context, bool isCashier) {
    final location = GoRouterState.of(context).uri.toString();
    if (isCashier) {
      if (location.startsWith("/cashier")) return 0;
      if (location.startsWith("/pos-billing")) return 1;
      if (location.startsWith("/orders")) return 2;
      if (location.startsWith("/payments")) return 3;
      if (location.startsWith("/customers")) return 4;
      if (location.startsWith("/reports")) return 5;
      if (location.startsWith("/sync")) return 6;
      return 0;
    }

    if (location.startsWith("/sadmin") || location.startsWith("/admin") || location.startsWith("/cashier")) {
      return 0;
    }
    if (location.startsWith("/pos-billing")) return 1;
    if (location.startsWith("/orders")) return 2;
    if (location.startsWith("/payments")) return 3;
    if (location.startsWith("/products") || location.startsWith("/categories")) return 4;
    if (location.startsWith("/gst-settings")) return 5;
    if (location.startsWith("/customers")) return 6;
    if (location.startsWith("/reports")) return 7;
    if (location.startsWith("/users")) return 8;
    if (location.startsWith("/sync")) return 9;
    if (location.startsWith("/hardware")) return 10;
    if (location.startsWith("/notifications")) return 11;
    if (location.startsWith("/company")) return 12;
    return 0;
  }

  void _onItemTapped(int index, BuildContext context, bool isCashier) {
    if (isCashier) {
      switch (index) {
        case 0:
          context.go(RouteNames.cashierDashboard);
          break;
        case 1:
          context.go(RouteNames.posBilling);
          break;
        case 2:
          context.go(RouteNames.orders);
          break;
        case 3:
          context.go(RouteNames.payments);
          break;
        case 4:
          context.go(RouteNames.customers);
          break;
        case 5:
          context.go(RouteNames.reports);
          break;
        case 6:
          context.go(RouteNames.sync);
          break;
      }
      return;
    }

    switch (index) {
      case 0:
        context.go(RouteNames.adminDashboard);
        break;
      case 1:
        context.go(RouteNames.posBilling);
        break;
      case 2:
        context.go(RouteNames.orders);
        break;
      case 3:
        context.go(RouteNames.payments);
        break;
      case 4:
        context.go(RouteNames.products);
        break;
      case 5:
        context.go(RouteNames.gstSettings);
        break;
      case 6:
        context.go(RouteNames.customers);
        break;
      case 7:
        context.go(RouteNames.reports);
        break;
      case 8:
        context.go(RouteNames.users);
        break;
      case 9:
        context.go(RouteNames.sync);
        break;
      case 10:
        context.go(RouteNames.hardware);
        break;
      case 11:
        context.go(RouteNames.notifications);
        break;
      case 12:
        context.go(RouteNames.companyProfile);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final user = authState.user;
    final isCashier = user?.isCashier ?? false;
    final selectedIndex = _calculateSelectedIndex(context, isCashier);
    final isDesktop = ResponsiveLayout.isDesktop(context);

    if (isDesktop) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: selectedIndex,
              onDestinationSelected: (idx) => _onItemTapped(idx, context, isCashier),
              labelType: NavigationRailLabelType.all,
              leading: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12.0),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.point_of_sale, color: Colors.white, size: 26),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      "LitePOS",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ],
                ),
              ),
              trailing: Expanded(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (user != null) ...[
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: user.isSAdmin
                                ? Colors.purple.withValues(alpha: 0.15)
                                : user.isAdmin
                                    ? AppColors.primary.withValues(alpha: 0.15)
                                    : Colors.green.withValues(alpha: 0.15),
                            child: Icon(
                              user.isSAdmin
                                  ? Icons.shield
                                  : user.isAdmin
                                      ? Icons.admin_panel_settings
                                      : Icons.point_of_sale,
                              size: 16,
                              color: user.isSAdmin
                                  ? Colors.purple
                                  : user.isAdmin
                                      ? AppColors.primary
                                      : Colors.green,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            user.username,
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            user.roleName,
                            style: TextStyle(
                              fontSize: 9,
                              color: user.isSAdmin
                                  ? Colors.purple
                                  : user.isAdmin
                                      ? AppColors.primary
                                      : Colors.green,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                        IconButton(
                          icon: const Icon(Icons.logout, size: 20, color: AppColors.error),
                          tooltip: "Logout",
                          onPressed: () async {
                            await ref.read(authNotifierProvider.notifier).logout();
                            if (context.mounted) {
                              context.go(RouteNames.login);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              destinations: isCashier
                  ? const [
                      NavigationRailDestination(
                        icon: Icon(Icons.dashboard_outlined),
                        selectedIcon: Icon(Icons.dashboard),
                        label: Text("Dashboard"),
                      ),
                      NavigationRailDestination(
                        icon: Icon(Icons.receipt_long_outlined),
                        selectedIcon: Icon(Icons.receipt_long),
                        label: Text("POS Billing"),
                      ),
                      NavigationRailDestination(
                        icon: Icon(Icons.list_alt_outlined),
                        selectedIcon: Icon(Icons.list_alt),
                        label: Text("Orders"),
                      ),
                      NavigationRailDestination(
                        icon: Icon(Icons.payments_outlined),
                        selectedIcon: Icon(Icons.payments),
                        label: Text("Payments"),
                      ),
                      NavigationRailDestination(
                        icon: Icon(Icons.people_outline),
                        selectedIcon: Icon(Icons.people),
                        label: Text("Customers"),
                      ),
                      NavigationRailDestination(
                        icon: Icon(Icons.bar_chart_outlined),
                        selectedIcon: Icon(Icons.bar_chart),
                        label: Text("Reports"),
                      ),
                      NavigationRailDestination(
                        icon: Icon(Icons.sync_outlined),
                        selectedIcon: Icon(Icons.sync),
                        label: Text("Sync"),
                      ),
                    ]
                  : const [
                      NavigationRailDestination(
                        icon: Icon(Icons.dashboard_outlined),
                        selectedIcon: Icon(Icons.dashboard),
                        label: Text("Dashboard"),
                      ),
                      NavigationRailDestination(
                        icon: Icon(Icons.receipt_long_outlined),
                        selectedIcon: Icon(Icons.receipt_long),
                        label: Text("POS Billing"),
                      ),
                      NavigationRailDestination(
                        icon: Icon(Icons.list_alt_outlined),
                        selectedIcon: Icon(Icons.list_alt),
                        label: Text("Orders"),
                      ),
                      NavigationRailDestination(
                        icon: Icon(Icons.payments_outlined),
                        selectedIcon: Icon(Icons.payments),
                        label: Text("Payments"),
                      ),
                      NavigationRailDestination(
                        icon: Icon(Icons.restaurant_menu_outlined),
                        selectedIcon: Icon(Icons.restaurant_menu),
                        label: Text("Menu"),
                      ),
                      NavigationRailDestination(
                        icon: Icon(Icons.receipt_outlined),
                        selectedIcon: Icon(Icons.receipt),
                        label: Text("GST & Tax"),
                      ),
                      NavigationRailDestination(
                        icon: Icon(Icons.people_outline),
                        selectedIcon: Icon(Icons.people),
                        label: Text("Customers"),
                      ),
                      NavigationRailDestination(
                        icon: Icon(Icons.bar_chart_outlined),
                        selectedIcon: Icon(Icons.bar_chart),
                        label: Text("Reports"),
                      ),
                      NavigationRailDestination(
                        icon: Icon(Icons.group_outlined),
                        selectedIcon: Icon(Icons.group),
                        label: Text("Users"),
                      ),
                      NavigationRailDestination(
                        icon: Icon(Icons.sync_outlined),
                        selectedIcon: Icon(Icons.sync),
                        label: Text("Sync"),
                      ),
                      NavigationRailDestination(
                        icon: Icon(Icons.print_outlined),
                        selectedIcon: Icon(Icons.print),
                        label: Text("Printers"),
                      ),
                      NavigationRailDestination(
                        icon: Icon(Icons.notifications_active_outlined),
                        selectedIcon: Icon(Icons.notifications_active),
                        label: Text("Alerts"),
                      ),
                      NavigationRailDestination(
                        icon: Icon(Icons.settings_outlined),
                        selectedIcon: Icon(Icons.settings),
                        label: Text("Shop Setup"),
                      ),
                    ],
            ),
            const VerticalDivider(thickness: 1, width: 1, color: AppColors.outlineLight),
            Expanded(child: widget.child),
          ],
        ),
      );
    }

    return Scaffold(
      body: widget.child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex > 4 ? 0 : selectedIndex,
        onDestinationSelected: (idx) => _onItemTapped(idx, context, isCashier),
        destinations: isCashier
            ? const [
                NavigationDestination(
                  icon: Icon(Icons.dashboard_outlined),
                  selectedIcon: Icon(Icons.dashboard),
                  label: "Dashboard",
                ),
                NavigationDestination(
                  icon: Icon(Icons.receipt_long_outlined),
                  selectedIcon: Icon(Icons.receipt_long),
                  label: "POS",
                ),
                NavigationDestination(
                  icon: Icon(Icons.list_alt_outlined),
                  selectedIcon: Icon(Icons.list_alt),
                  label: "Orders",
                ),
                NavigationDestination(
                  icon: Icon(Icons.payments_outlined),
                  selectedIcon: Icon(Icons.payments),
                  label: "Payments",
                ),
                NavigationDestination(
                  icon: Icon(Icons.sync_outlined),
                  selectedIcon: Icon(Icons.sync),
                  label: "Sync",
                ),
              ]
            : const [
                NavigationDestination(
                  icon: Icon(Icons.dashboard_outlined),
                  selectedIcon: Icon(Icons.dashboard),
                  label: "Dashboard",
                ),
                NavigationDestination(
                  icon: Icon(Icons.receipt_long_outlined),
                  selectedIcon: Icon(Icons.receipt_long),
                  label: "POS",
                ),
                NavigationDestination(
                  icon: Icon(Icons.list_alt_outlined),
                  selectedIcon: Icon(Icons.list_alt),
                  label: "Orders",
                ),
                NavigationDestination(
                  icon: Icon(Icons.payments_outlined),
                  selectedIcon: Icon(Icons.payments),
                  label: "Payments",
                ),
                NavigationDestination(
                  icon: Icon(Icons.settings_outlined),
                  selectedIcon: Icon(Icons.settings),
                  label: "Setup",
                ),
              ],
      ),
    );
  }
}
