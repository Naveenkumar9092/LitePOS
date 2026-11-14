import "dart:ui";
import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:go_router/go_router.dart";
import "package:google_fonts/google_fonts.dart";
import "../../core/routing/route_names.dart";
import "../../core/theme/app_colors.dart";
import "../../core/utilities/responsive_layout.dart";
import "../../features/authentication/presentation/auth_state.dart";

class _NavItem {
  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final String? badge;

  const _NavItem({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    this.badge,
  });
}

class FoundationShell extends ConsumerStatefulWidget {
  final Widget child;

  const FoundationShell({super.key, required this.child});

  @override
  ConsumerState<FoundationShell> createState() => _FoundationShellState();
}

class _FoundationShellState extends ConsumerState<FoundationShell> {
  bool _isSidebarExpanded = true;

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

  List<_NavItem> _getCashierItems() {
    return const [
      _NavItem(
        label: "Dashboard",
        icon: Icons.dashboard_outlined,
        selectedIcon: Icons.dashboard_rounded,
      ),
      _NavItem(
        label: "POS Billing",
        icon: Icons.receipt_long_outlined,
        selectedIcon: Icons.receipt_long_rounded,
        badge: "FAST",
      ),
      _NavItem(
        label: "Orders",
        icon: Icons.list_alt_outlined,
        selectedIcon: Icons.list_alt_rounded,
      ),
      _NavItem(
        label: "Payments",
        icon: Icons.payments_outlined,
        selectedIcon: Icons.payments_rounded,
      ),
      _NavItem(
        label: "Customers",
        icon: Icons.people_outline,
        selectedIcon: Icons.people_rounded,
      ),
      _NavItem(
        label: "Reports",
        icon: Icons.bar_chart_outlined,
        selectedIcon: Icons.bar_chart_rounded,
      ),
      _NavItem(
        label: "Cloud Sync",
        icon: Icons.sync_outlined,
        selectedIcon: Icons.sync_rounded,
      ),
    ];
  }

  List<_NavItem> _getAdminItems() {
    return const [
      _NavItem(
        label: "Dashboard",
        icon: Icons.dashboard_outlined,
        selectedIcon: Icons.dashboard_rounded,
      ),
      _NavItem(
        label: "POS Billing",
        icon: Icons.receipt_long_outlined,
        selectedIcon: Icons.receipt_long_rounded,
        badge: "FAST",
      ),
      _NavItem(
        label: "Orders",
        icon: Icons.list_alt_outlined,
        selectedIcon: Icons.list_alt_rounded,
      ),
      _NavItem(
        label: "Payments",
        icon: Icons.payments_outlined,
        selectedIcon: Icons.payments_rounded,
      ),
      _NavItem(
        label: "Catalog & Menu",
        icon: Icons.restaurant_menu_outlined,
        selectedIcon: Icons.restaurant_menu_rounded,
      ),
      _NavItem(
        label: "GST & Tax",
        icon: Icons.receipt_outlined,
        selectedIcon: Icons.receipt_rounded,
      ),
      _NavItem(
        label: "Customers",
        icon: Icons.people_outline,
        selectedIcon: Icons.people_rounded,
      ),
      _NavItem(
        label: "Reports",
        icon: Icons.bar_chart_outlined,
        selectedIcon: Icons.bar_chart_rounded,
      ),
      _NavItem(
        label: "Staff Users",
        icon: Icons.group_outlined,
        selectedIcon: Icons.group_rounded,
      ),
      _NavItem(
        label: "Cloud Sync",
        icon: Icons.sync_outlined,
        selectedIcon: Icons.sync_rounded,
      ),
      _NavItem(
        label: "Hardware",
        icon: Icons.print_outlined,
        selectedIcon: Icons.print_rounded,
      ),
      _NavItem(
        label: "Alerts",
        icon: Icons.notifications_active_outlined,
        selectedIcon: Icons.notifications_active_rounded,
      ),
      _NavItem(
        label: "Shop Setup",
        icon: Icons.settings_outlined,
        selectedIcon: Icons.settings_rounded,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final user = authState.user;
    final isCashier = user?.isCashier ?? false;
    final selectedIndex = _calculateSelectedIndex(context, isCashier);
    final isDesktop = ResponsiveLayout.isDesktop(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final roleNeonColor = (user?.isSAdmin ?? false)
        ? AppColors.neonPurple
        : (user?.isAdmin ?? false)
            ? AppColors.neonCyan
            : AppColors.neonEmerald;

    if (isDesktop) {
      final items = isCashier ? _getCashierItems() : _getAdminItems();

      return Scaffold(
        body: Row(
          children: [
            // Collapsible & Expandable Glassmorphic Sidebar
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOutCubic,
              width: _isSidebarExpanded ? 245.0 : 76.0,
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF0F172A).withValues(alpha: 0.90)
                    : Colors.white.withValues(alpha: 0.95),
                border: Border(
                  right: BorderSide(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.10)
                        : const Color(0xFFCCE4E9),
                    width: 1.2,
                  ),
                ),
                boxShadow: [
                  BoxShadow(
                    color: isDark
                        ? Colors.black.withValues(alpha: 0.35)
                        : Colors.black.withValues(alpha: 0.04),
                    blurRadius: 16,
                    offset: const Offset(2, 0),
                  ),
                ],
              ),
              child: ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                  child: Column(
                    children: [
                      // Sidebar Header with Branding & Toggle
                      _buildHeader(roleNeonColor, isDark),

                      Divider(
                        height: 1,
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : Colors.black.withValues(alpha: 0.06),
                      ),

                      // Navigation Destinations List
                      Expanded(
                        child: ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                          itemCount: items.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 4),
                          itemBuilder: (context, index) {
                            final item = items[index];
                            final isSelected = index == selectedIndex;
                            return _buildNavItem(
                              item: item,
                              isSelected: isSelected,
                              roleNeonColor: roleNeonColor,
                              isDark: isDark,
                              onTap: () => _onItemTapped(index, context, isCashier),
                            );
                          },
                        ),
                      ),

                      Divider(
                        height: 1,
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : Colors.black.withValues(alpha: 0.06),
                      ),

                      // Sidebar Footer: User Profile & Quick Logout
                      _buildFooter(user, roleNeonColor, isDark),
                    ],
                  ),
                ),
              ),
            ),

            // Content Area
            Expanded(child: widget.child),
          ],
        ),
      );
    }

    // Mobile / Tablet Bottom Navigation
    return Scaffold(
      body: widget.child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex > 4 ? 0 : selectedIndex,
        onDestinationSelected: (idx) => _onItemTapped(idx, context, isCashier),
        destinations: isCashier
            ? const [
                NavigationDestination(
                  icon: Icon(Icons.dashboard_outlined),
                  selectedIcon: Icon(Icons.dashboard_rounded),
                  label: "Dashboard",
                ),
                NavigationDestination(
                  icon: Icon(Icons.receipt_long_outlined),
                  selectedIcon: Icon(Icons.receipt_long_rounded),
                  label: "POS",
                ),
                NavigationDestination(
                  icon: Icon(Icons.list_alt_outlined),
                  selectedIcon: Icon(Icons.list_alt_rounded),
                  label: "Orders",
                ),
                NavigationDestination(
                  icon: Icon(Icons.payments_outlined),
                  selectedIcon: Icon(Icons.payments_rounded),
                  label: "Payments",
                ),
                NavigationDestination(
                  icon: Icon(Icons.sync_outlined),
                  selectedIcon: Icon(Icons.sync_rounded),
                  label: "Sync",
                ),
              ]
            : const [
                NavigationDestination(
                  icon: Icon(Icons.dashboard_outlined),
                  selectedIcon: Icon(Icons.dashboard_rounded),
                  label: "Dashboard",
                ),
                NavigationDestination(
                  icon: Icon(Icons.receipt_long_outlined),
                  selectedIcon: Icon(Icons.receipt_long_rounded),
                  label: "POS",
                ),
                NavigationDestination(
                  icon: Icon(Icons.list_alt_outlined),
                  selectedIcon: Icon(Icons.list_alt_rounded),
                  label: "Orders",
                ),
                NavigationDestination(
                  icon: Icon(Icons.payments_outlined),
                  selectedIcon: Icon(Icons.payments_rounded),
                  label: "Payments",
                ),
                NavigationDestination(
                  icon: Icon(Icons.settings_outlined),
                  selectedIcon: Icon(Icons.settings_rounded),
                  label: "Setup",
                ),
              ],
      ),
    );
  }

  Widget _buildHeader(Color roleNeonColor, bool isDark) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: _isSidebarExpanded ? 14 : 10,
        vertical: 14,
      ),
      child: Row(
        mainAxisAlignment:
            _isSidebarExpanded ? MainAxisAlignment.spaceBetween : MainAxisAlignment.center,
        children: [
          Row(
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
                      color: roleNeonColor.withValues(alpha: 0.35),
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
              if (_isSidebarExpanded) ...[
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "LitePOS",
                      style: GoogleFonts.dmSans(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        letterSpacing: -0.3,
                        color: isDark ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      "Cloud & Offline Suite",
                      style: GoogleFonts.dmSans(
                        fontSize: 10,
                        color: isDark ? Colors.white54 : AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
          IconButton(
            icon: Icon(
              _isSidebarExpanded ? Icons.menu_open_rounded : Icons.menu_rounded,
              size: 20,
              color: isDark ? Colors.white70 : AppColors.textSecondary,
            ),
            tooltip: _isSidebarExpanded ? "Collapse Sidebar" : "Expand Sidebar",
            onPressed: () {
              setState(() {
                _isSidebarExpanded = !_isSidebarExpanded;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required _NavItem item,
    required bool isSelected,
    required Color roleNeonColor,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    Widget content = InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: EdgeInsets.symmetric(
          horizontal: _isSidebarExpanded ? 12 : 0,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? roleNeonColor.withValues(alpha: isDark ? 0.20 : 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: isSelected
              ? Border.all(
                  color: roleNeonColor.withValues(alpha: isDark ? 0.45 : 0.35),
                  width: 1.2,
                )
              : null,
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: roleNeonColor.withValues(alpha: isDark ? 0.22 : 0.12),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment:
              _isSidebarExpanded ? MainAxisAlignment.start : MainAxisAlignment.center,
          children: [
            Icon(
              isSelected ? item.selectedIcon : item.icon,
              size: 20,
              color: isSelected
                  ? roleNeonColor
                  : (isDark ? Colors.white70 : AppColors.textSecondary),
            ),
            if (_isSidebarExpanded) ...[
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  item.label,
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected
                        ? (isDark ? Colors.white : AppColors.textPrimary)
                        : (isDark ? Colors.white70 : AppColors.textSecondary),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (item.badge != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: roleNeonColor,
                    borderRadius: BorderRadius.circular(6),
                    boxShadow: [
                      BoxShadow(
                        color: roleNeonColor.withValues(alpha: 0.4),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: Text(
                    item.badge!,
                    style: GoogleFonts.dmSans(
                      fontSize: 8,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );

    if (!_isSidebarExpanded) {
      return Tooltip(
        message: item.label,
        waitDuration: const Duration(milliseconds: 200),
        textStyle: GoogleFonts.dmSans(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
        ),
        child: content,
      );
    }

    return content;
  }

  Widget _buildFooter(dynamic user, Color roleNeonColor, bool isDark) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: _isSidebarExpanded ? 12 : 8,
        vertical: 12,
      ),
      child: _isSidebarExpanded
          ? Row(
              children: [
                CircleAvatar(
                  radius: 17,
                  backgroundColor: roleNeonColor.withValues(alpha: 0.20),
                  child: Icon(
                    user?.isSAdmin == true
                        ? Icons.shield_rounded
                        : user?.isAdmin == true
                            ? Icons.admin_panel_settings_rounded
                            : Icons.point_of_sale_rounded,
                    size: 18,
                    color: roleNeonColor,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        user?.username ?? "User",
                        style: GoogleFonts.dmSans(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        user?.roleName ?? "Cashier",
                        style: GoogleFonts.dmSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: roleNeonColor,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.logout_rounded, size: 18, color: AppColors.error),
                  tooltip: "Sign Out",
                  onPressed: () async {
                    await ref.read(authNotifierProvider.notifier).logout();
                    if (mounted) {
                      context.go(RouteNames.login);
                    }
                  },
                ),
              ],
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Tooltip(
                  message: "${user?.username ?? 'User'} (${user?.roleName ?? ''})",
                  child: CircleAvatar(
                    radius: 16,
                    backgroundColor: roleNeonColor.withValues(alpha: 0.20),
                    child: Icon(
                      user?.isSAdmin == true
                          ? Icons.shield_rounded
                          : user?.isAdmin == true
                              ? Icons.admin_panel_settings_rounded
                              : Icons.point_of_sale_rounded,
                      size: 16,
                      color: roleNeonColor,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                IconButton(
                  icon: const Icon(Icons.logout_rounded, size: 18, color: AppColors.error),
                  tooltip: "Sign Out",
                  onPressed: () async {
                    await ref.read(authNotifierProvider.notifier).logout();
                    if (mounted) {
                      context.go(RouteNames.login);
                    }
                  },
                ),
              ],
            ),
    );
  }
}
