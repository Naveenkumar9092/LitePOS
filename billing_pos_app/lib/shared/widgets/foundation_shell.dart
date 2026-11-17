import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:go_router/go_router.dart";
import "package:google_fonts/google_fonts.dart";
import "../../core/routing/route_names.dart";
import "../../core/theme/app_colors.dart";
import "../../features/authentication/presentation/auth_state.dart";
import "app_brand_logo.dart";

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
  bool? _manualSidebarExpanded;

  bool get _isSidebarExpanded {
    if (_manualSidebarExpanded != null) return _manualSidebarExpanded!;
    return MediaQuery.sizeOf(context).width >= 1100;
  }

  int _calculateSelectedIndex(BuildContext context, bool isCashier, bool isSAdmin) {
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

    if (isSAdmin) {
      if (location.startsWith("/sadmin")) return 0;
      if (location.startsWith("/users")) return 1;
      if (location.startsWith("/reports")) return 2;
      if (location.startsWith("/sync")) return 3;
      if (location.startsWith("/hardware")) return 4;
      if (location.startsWith("/notifications")) return 5;
      return 0;
    }

    if (location.startsWith("/sadmin") || location.startsWith("/admin") || location.startsWith("/cashier")) {
      return 0;
    }
    if (location.startsWith("/pos-billing")) return 1;
    if (location.startsWith("/orders")) return 2;
    if (location.startsWith("/payments")) return 3;
    if (location.startsWith("/products") || location.startsWith("/categories")) return 4;
    if (location.startsWith("/users")) return 5;
    if (location.startsWith("/gst-settings")) return 6;
    if (location.startsWith("/customers")) return 7;
    if (location.startsWith("/reports")) return 8;
    if (location.startsWith("/sync")) return 9;
    if (location.startsWith("/hardware")) return 10;
    if (location.startsWith("/notifications")) return 11;
    if (location.startsWith("/company")) return 12;
    return 0;
  }

  void _onItemTapped(int index, BuildContext context, bool isCashier, bool isSAdmin) {
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

    if (isSAdmin) {
      switch (index) {
        case 0:
          context.go(RouteNames.sadminDashboard);
          break;
        case 1:
          context.go(RouteNames.users);
          break;
        case 2:
          context.go(RouteNames.reports);
          break;
        case 3:
          context.go(RouteNames.sync);
          break;
        case 4:
          context.go(RouteNames.hardware);
          break;
        case 5:
          context.go(RouteNames.notifications);
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
        context.go(RouteNames.users);
        break;
      case 6:
        context.go(RouteNames.gstSettings);
        break;
      case 7:
        context.go(RouteNames.customers);
        break;
      case 8:
        context.go(RouteNames.reports);
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

  List<_NavItem> _getSAdminItems() {
    return const [
      _NavItem(
        label: "SAdmin Console",
        icon: Icons.shield_outlined,
        selectedIcon: Icons.shield_rounded,
      ),
      _NavItem(
        label: "User & Role Management",
        icon: Icons.admin_panel_settings_outlined,
        selectedIcon: Icons.admin_panel_settings_rounded,
      ),
      _NavItem(
        label: "System Reports",
        icon: Icons.bar_chart_outlined,
        selectedIcon: Icons.bar_chart_rounded,
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
        label: "System Alerts",
        icon: Icons.notifications_active_outlined,
        selectedIcon: Icons.notifications_active_rounded,
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
        label: "Cashiers",
        icon: Icons.badge_outlined,
        selectedIcon: Icons.badge_rounded,
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


  Future<void> _safeLogout(BuildContext ctx, {bool isBottomSheet = false}) async {
    if (isBottomSheet && Navigator.canPop(ctx)) {
      Navigator.of(ctx).pop();
    }
    if (context.mounted) {
      context.go(RouteNames.login);
    }
    await ref.read(authNotifierProvider.notifier).logout();
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    if (location.startsWith(RouteNames.posBilling)) {
      return widget.child;
    }

    final authState = ref.watch(authNotifierProvider);
    final user = authState.user;
    final isCashier = user?.isCashier ?? false;
    final isSAdmin = user?.isSAdmin ?? false;
    final selectedIndex = _calculateSelectedIndex(context, isCashier, isSAdmin);
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isTabletOrDesktop = screenWidth >= 700;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final roleNeonColor = (user?.isSAdmin ?? false)
        ? AppColors.neonPurple
        : (user?.isAdmin ?? false)
            ? AppColors.neonCyan
            : AppColors.neonEmerald;

    final items = isCashier
        ? _getCashierItems()
        : (isSAdmin ? _getSAdminItems() : _getAdminItems());
    final mobileSelectedIndex = selectedIndex > 3 ? 4 : selectedIndex;

    return Scaffold(
      body: Row(
        children: [
          if (isTabletOrDesktop)
            // Collapsible & Expandable Modern Sidebar
            RepaintBoundary(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOutCubic,
                width: _isSidebarExpanded ? 245.0 : 76.0,
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF0F172A)
                      : Colors.white,
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
                            onTap: () => _onItemTapped(index, context, isCashier, isSAdmin),
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

          // Content Area - single stable element slot across all viewports
          Expanded(
            child: widget.child,
          ),
        ],
      ),
      bottomNavigationBar: isTabletOrDesktop
          ? null
          : NavigationBar(
              selectedIndex: mobileSelectedIndex,
              onDestinationSelected: (idx) {
                if (idx == 4) {
                  _showMobileMenuSheet(context, isCashier, isSAdmin, user, roleNeonColor, isDark);
                } else {
                  _onItemTapped(idx, context, isCashier, isSAdmin);
                }
              },
              destinations: const [
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
                  icon: Icon(Icons.grid_view_outlined),
                  selectedIcon: Icon(Icons.grid_view_rounded),
                  label: "More",
                ),
              ],
            ),
    );
  }

  void _showMobileMenuSheet(BuildContext context, bool isCashier, bool isSAdmin, dynamic user, Color roleNeonColor, bool isDark) {
    final items = isCashier
        ? _getCashierItems()
        : (isSAdmin ? _getSAdminItems() : _getAdminItems());
    final remainingItems = <Map<String, dynamic>>[];
    for (int i = 4; i < items.length; i++) {
      remainingItems.add({
        "index": i,
        "item": items[i],
      });
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0F172A) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "All Modules",
                          style: GoogleFonts.dmSans(
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                            color: isDark ? Colors.white : AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          "${user?.shopName ?? 'PulsePOS Store'} • ${user?.fullName ?? 'Staff'}",
                          style: GoogleFonts.dmSans(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: remainingItems.map((entry) {
                    final int idx = entry["index"];
                    final _NavItem navItem = entry["item"];
                    final isCurrent = _calculateSelectedIndex(context, isCashier, isSAdmin) == idx;

                    return SizedBox(
                      width: (MediaQuery.of(context).size.width - 62) / 3,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () {
                          Navigator.of(ctx).pop();
                          _onItemTapped(idx, context, isCashier, isSAdmin);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
                          decoration: BoxDecoration(
                            color: isCurrent
                                ? AppColors.primaryContainer
                                : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC)),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isCurrent
                                  ? AppColors.primary
                                  : (isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                              width: isCurrent ? 1.5 : 1.0,
                            ),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isCurrent ? navItem.selectedIcon : navItem.icon,
                                size: 24,
                                color: isCurrent
                                    ? AppColors.primaryDark
                                    : (isDark ? Colors.white70 : const Color(0xFF475569)),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                navItem.label,
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.dmSans(
                                  fontSize: 11,
                                  fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w600,
                                  color: isCurrent ? AppColors.primaryDark : (isDark ? Colors.white : AppColors.textPrimary),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  icon: const Icon(Icons.logout_rounded, size: 18, color: AppColors.error),
                  label: Text("Sign Out", style: GoogleFonts.dmSans(fontWeight: FontWeight.bold, color: AppColors.error)),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: AppColors.error.withValues(alpha: 0.5)),
                    minimumSize: const Size(double.infinity, 44),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () => _safeLogout(ctx, isBottomSheet: true),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(Color roleNeonColor, bool isDark) {
    if (!_isSidebarExpanded) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBrandLogo(
              size: 34,
              isDark: isDark,
              showText: false,
            ),
            const SizedBox(height: 10),
            IconButton(
              icon: Icon(
                Icons.menu_rounded,
                size: 20,
                color: isDark ? Colors.white70 : AppColors.textSecondary,
              ),
              tooltip: "Expand Sidebar",
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              onPressed: () {
                setState(() {
                  _manualSidebarExpanded = true;
                });
              },
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: AppBrandLogo(
              size: 36,
              isDark: isDark,
              showText: true,
              subtitle: "Smart Retail & Billing",
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.menu_open_rounded,
              size: 20,
              color: isDark ? Colors.white70 : AppColors.textSecondary,
            ),
            tooltip: "Collapse Sidebar",
            onPressed: () {
              setState(() {
                _manualSidebarExpanded = false;
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
                  onPressed: () => _safeLogout(context),
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
                  onPressed: () => _safeLogout(context),
                ),
              ],
            ),
    );
  }
}
