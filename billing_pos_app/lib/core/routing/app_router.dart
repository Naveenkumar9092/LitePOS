import "package:flutter/material.dart";
import "package:go_router/go_router.dart";
import "../../features/authentication/presentation/login_screen.dart";
import "../../features/billing/presentation/pos_billing_screen.dart";
import "../../features/categories/presentation/category_management_screen.dart";
import "../../features/company/presentation/company_profile_screen.dart";
import "../../features/company/presentation/company_setup_screen.dart";
import "../../features/dashboard/presentation/dashboard_screen.dart";
import "../../features/orders/presentation/order_list_screen.dart";
import "../../features/payments/presentation/payment_management_screen.dart";
import "../../features/gst/presentation/gst_management_screen.dart";
import "../../features/products/presentation/product_list_screen.dart";
import "../../features/users/presentation/user_management_screen.dart";
import "../../features/customers/presentation/customer_directory_screen.dart";
import "../../features/reports/presentation/reports_screen.dart";
import "../../features/sync/presentation/sync_management_screen.dart";
import "../../features/hardware/presentation/hardware_settings_screen.dart";
import "../../features/notifications/presentation/notifications_screen.dart";
import "../../shared/widgets/foundation_shell.dart";
import "route_names.dart";

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> _shellNavigatorKey = GlobalKey<NavigatorState>();

final GoRouter appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: RouteNames.login,
  routes: [
    GoRoute(
      path: RouteNames.login,
      builder: (context, state) => const LoginScreen(),
    ),
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) => FoundationShell(child: child),
      routes: [
        GoRoute(
          path: RouteNames.sadminDashboard,
          builder: (context, state) => const DashboardScreen(),
        ),
        GoRoute(
          path: RouteNames.adminDashboard,
          builder: (context, state) => const DashboardScreen(),
        ),
        GoRoute(
          path: RouteNames.cashierDashboard,
          builder: (context, state) => const DashboardScreen(),
        ),
        GoRoute(
          path: RouteNames.companySetup,
          builder: (context, state) => const CompanySetupScreen(),
        ),
        GoRoute(
          path: RouteNames.companyProfile,
          builder: (context, state) => const CompanyProfileScreen(),
        ),
        GoRoute(
          path: RouteNames.users,
          builder: (context, state) => const UserManagementScreen(),
        ),
        GoRoute(
          path: RouteNames.posBilling,
          builder: (context, state) => const PosBillingScreen(),
        ),
        GoRoute(
          path: RouteNames.orders,
          builder: (context, state) => const OrderListScreen(),
        ),
        GoRoute(
          path: RouteNames.payments,
          builder: (context, state) => const PaymentManagementScreen(),
        ),
        GoRoute(
          path: RouteNames.gstSettings,
          builder: (context, state) => const GstManagementScreen(),
        ),
        GoRoute(
          path: RouteNames.products,
          builder: (context, state) => const ProductListScreen(),
        ),
        GoRoute(
          path: RouteNames.categories,
          builder: (context, state) => const CategoryManagementScreen(),
        ),
        GoRoute(
          path: RouteNames.customers,
          builder: (context, state) => const CustomerDirectoryScreen(),
        ),
        GoRoute(
          path: RouteNames.reports,
          builder: (context, state) => const ReportsScreen(),
        ),
        GoRoute(
          path: RouteNames.sync,
          builder: (context, state) => const SyncManagementScreen(),
        ),
        GoRoute(
          path: RouteNames.hardware,
          builder: (context, state) => const HardwareSettingsScreen(),
        ),
        GoRoute(
          path: RouteNames.notifications,
          builder: (context, state) => const NotificationsScreen(),
        ),
      ],
    ),
  ],
);
