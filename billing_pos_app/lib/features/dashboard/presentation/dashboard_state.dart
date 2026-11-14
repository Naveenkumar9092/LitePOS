import "package:flutter_riverpod/flutter_riverpod.dart";
import "../../authentication/presentation/auth_state.dart";
import "../../company/data/company_repository.dart";
import "../data/dashboard_repository.dart";
import "../models/dashboard_models.dart";

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  final db = ref.watch(appDatabaseProvider);
  return DashboardRepository(dioClient, db);
});

// Selected Date Filter for Dashboard
final dashboardDateFilterProvider = StateProvider<DateTime?>((ref) => null);

// Selected Period Filter (today, week, month)
final dashboardPeriodFilterProvider = StateProvider<String>((ref) => "today");

// SAdmin Dashboard Provider
final sadminDashboardProvider = FutureProvider.autoDispose<SAdminDashboardModel>((ref) async {
  final repo = ref.watch(dashboardRepositoryProvider);
  return repo.getSAdminDashboard();
});

// Admin Dashboard Provider
final adminDashboardProvider = FutureProvider.autoDispose<AdminDashboardModel>((ref) async {
  final repo = ref.watch(dashboardRepositoryProvider);
  final date = ref.watch(dashboardDateFilterProvider);
  return repo.getAdminDashboard(date: date);
});

// Cashier Dashboard Provider
final cashierDashboardProvider = FutureProvider.autoDispose<CashierDashboardModel>((ref) async {
  final repo = ref.watch(dashboardRepositoryProvider);
  final auth = ref.watch(authNotifierProvider);
  final date = ref.watch(dashboardDateFilterProvider);
  return repo.getCashierDashboard(cashierId: auth.user?.userId, date: date);
});

// Sales Summary Provider
final salesSummaryProvider = FutureProvider.autoDispose<SalesSummaryModel>((ref) async {
  final repo = ref.watch(dashboardRepositoryProvider);
  final period = ref.watch(dashboardPeriodFilterProvider);
  return repo.getSalesSummary(period: period);
});

// Payment Summary Provider
final paymentSummaryProvider = FutureProvider.autoDispose<PaymentSummaryModel>((ref) async {
  final repo = ref.watch(dashboardRepositoryProvider);
  final period = ref.watch(dashboardPeriodFilterProvider);
  return repo.getPaymentSummary(period: period);
});

// Recent Transactions Provider
final recentTransactionsProvider = FutureProvider.autoDispose<List<RecentTransactionModel>>((ref) async {
  final repo = ref.watch(dashboardRepositoryProvider);
  final auth = ref.watch(authNotifierProvider);
  final cashierId = auth.user?.isCashier == true ? auth.user?.userId : null;
  return repo.getRecentTransactions(limit: 10, cashierId: cashierId);
});

