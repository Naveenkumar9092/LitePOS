import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_test/flutter_test.dart";
import "package:billing_pos_app/features/authentication/presentation/auth_state.dart";
import "package:billing_pos_app/features/authentication/models/user_model.dart";
import "package:billing_pos_app/features/notifications/models/notification_models.dart";
import "package:billing_pos_app/features/notifications/presentation/notifications_screen.dart";
import "package:billing_pos_app/features/notifications/presentation/notification_state.dart";

class FakeNotificationNotifier extends StateNotifier<NotificationState> implements NotificationNotifier {
  FakeNotificationNotifier(super.state);

  @override
  Future<void> init() async {}

  @override
  Future<void> loadPreferences() async {}

  @override
  Future<bool> updatePreferences(ShopPreferenceModel prefs) async => true;

  @override
  Future<NotificationResultModel?> sendInvoiceEmail({required int invoiceId, String? recipientOverride}) async => null;

  @override
  Future<NotificationResultModel?> sendInvoiceWhatsApp({required int invoiceId, String? recipientOverride}) async => null;

  @override
  Future<DatabaseBackupResultModel?> triggerDatabaseBackup() async => null;

  @override
  Future<void> loadSystemInfo() async {}

  @override
  Future<void> loadLogs() async {}

  @override
  void clearMessages() {}
}

class FakeAuthNotifier extends StateNotifier<AuthState> implements AuthNotifier {
  FakeAuthNotifier(super.state);

  @override
  Future<void> checkInitialAuth() async {}

  @override
  Future<bool> login(String username, String password, {bool forceOffline = false}) async => true;

  @override
  Future<void> logout() async {}

  @override
  Future<bool> changePassword(String currentPassword, String newPassword, String confirmPassword) async => true;

  @override
  Future<bool> forgotPassword(String usernameOrEmail) async => true;
}

void main() {
  const testPrefs = ShopPreferenceModel(
    id: 1,
    shopId: 1,
    enableEmailInvoicing: true,
    enableWhatsAppInvoicing: true,
    autoSendInvoiceOnPayment: false,
    receiptHeaderCustom: "Welcome to LitePOS Cafe",
    receiptFooterCustom: "Thank you for visiting!",
    defaultGstRate: 5.0,
    enableSoundAlerts: true,
  );

  final testSysInfo = SystemInfoSummaryModel(
    appName: "LitePOS Billing Software",
    appVersion: "1.0.0",
    environment: "Production",
    databaseEngine: "Microsoft SQL Server",
    databaseConnected: true,
    totalInvoices: 15,
    totalProducts: 8,
    totalCustomers: 6,
    activePrinters: 2,
    serverTimeUtc: DateTime.utc(2026, 11, 14, 10, 0, 0),
  );

  final testLogs = [
    NotificationAuditLogModel(
      id: 1,
      invoiceId: 10,
      invoiceNumber: "INV-20261114-0010",
      channel: NotificationChannel.email,
      recipient: "priya@example.com",
      status: NotificationStatus.sent,
      sentAtUtc: DateTime.utc(2026, 11, 14, 10, 0, 0),
      messageBody: "Email Body",
      externalReferenceId: "EMAIL-MSG-001",
    ),
  ];

  final testUser = UserModel(
    id: 1,
    companyId: 1,
    fullName: "Admin User",
    username: "admin",
    roleId: 2,
    roleName: "Admin",
    isActive: true,
    createdAtUtc: DateTime.utc(2026, 11, 1),
  );

  Widget createWidgetUnderTest({required NotificationState notifState}) {
    return ProviderScope(
      overrides: [
        notificationNotifierProvider.overrideWith((ref) => FakeNotificationNotifier(notifState)),
        authNotifierProvider.overrideWith((ref) => FakeAuthNotifier(AuthState(user: testUser))),
      ],
      child: const MaterialApp(
        home: NotificationsScreen(),
      ),
    );
  }

  group("NotificationsScreen Tests", () {
    testWidgets("Renders screen title and tabs", (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 900));
      final state = NotificationState(
        isLoading: false,
        preferences: testPrefs,
        systemInfo: testSysInfo,
        recentLogs: testLogs,
      );

      await tester.pumpWidget(createWidgetUnderTest(notifState: state));
      await tester.pumpAndSettle();

      expect(find.text("Settings & Notifications"), findsOneWidget);
      expect(find.text("Store & Receipts"), findsOneWidget);
      expect(find.text("Invoicing Alerts"), findsOneWidget);
      expect(find.text("Backup & System"), findsOneWidget);
      expect(find.text("Audit History"), findsOneWidget);

      expect(find.text("Thermal Receipt Customization"), findsOneWidget);
      expect(find.text("Custom Receipt Header Greeting"), findsOneWidget);
      expect(find.text("Save Preferences"), findsOneWidget);
    });

    testWidgets("Switches to Invoicing Alerts tab and displays notification toggles", (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 900));
      final state = NotificationState(
        isLoading: false,
        preferences: testPrefs,
        systemInfo: testSysInfo,
        recentLogs: testLogs,
      );

      await tester.pumpWidget(createWidgetUnderTest(notifState: state));
      await tester.pumpAndSettle();

      await tester.tap(find.text("Invoicing Alerts"));
      await tester.pumpAndSettle();

      expect(find.text("Enable Email Invoicing"), findsOneWidget);
      expect(find.text("Enable WhatsApp Invoicing"), findsOneWidget);
      expect(find.text("Auto-Send on Payment Completion"), findsOneWidget);
      expect(find.text("Send Manual Invoice"), findsOneWidget);
    });

    testWidgets("Switches to Backup & System tab and renders metrics", (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 900));
      final state = NotificationState(
        isLoading: false,
        preferences: testPrefs,
        systemInfo: testSysInfo,
        recentLogs: testLogs,
      );

      await tester.pumpWidget(createWidgetUnderTest(notifState: state));
      await tester.pumpAndSettle();

      await tester.tap(find.text("Backup & System"));
      await tester.pumpAndSettle();

      expect(find.text("Total Invoices"), findsOneWidget);
      expect(find.text("Total Products"), findsOneWidget);
      expect(find.text("Backup Database Now"), findsOneWidget);
    });
  });
}

