import "package:flutter_test/flutter_test.dart";
import "package:billing_pos_app/features/notifications/models/notification_models.dart";
import "package:billing_pos_app/features/notifications/presentation/notification_state.dart";

void main() {
  group("NotificationState Tests", () {
    const testPrefs = ShopPreferenceModel(
      id: 1,
      shopId: 1,
      enableEmailInvoicing: true,
      enableWhatsAppInvoicing: true,
      autoSendInvoiceOnPayment: false,
      receiptHeaderCustom: "Welcome to Our Cafe",
      receiptFooterCustom: "Thank you!",
      defaultGstRate: 5.0,
      enableSoundAlerts: true,
    );

    final testSysInfo = SystemInfoSummaryModel(
      appName: "LitePOS Billing Software",
      appVersion: "1.0.0",
      environment: "Production",
      databaseEngine: "Microsoft SQL Server",
      databaseConnected: true,
      totalInvoices: 10,
      totalProducts: 6,
      totalCustomers: 5,
      activePrinters: 1,
      serverTimeUtc: DateTime.utc(2026, 11, 14, 10, 0, 0),
    );

    test("Initial NotificationState defaults are correct", () {
      const state = NotificationState();
      expect(state.isLoading, false);
      expect(state.isDispatching, false);
      expect(state.preferences, isNull);
      expect(state.systemInfo, isNull);
      expect(state.recentLogs, isEmpty);
      expect(state.lastDispatchResult, isNull);
      expect(state.lastBackupResult, isNull);
      expect(state.errorMessage, isNull);
      expect(state.successMessage, isNull);
    });

    test("NotificationState copyWith updates state properly", () {
      const state = NotificationState();
      final updated = state.copyWith(
        isLoading: false,
        preferences: testPrefs,
        systemInfo: testSysInfo,
        successMessage: "Preferences loaded successfully",
      );

      expect(updated.preferences?.receiptHeaderCustom, "Welcome to Our Cafe");
      expect(updated.systemInfo?.totalInvoices, 10);
      expect(updated.successMessage, "Preferences loaded successfully");
    });
  });
}
