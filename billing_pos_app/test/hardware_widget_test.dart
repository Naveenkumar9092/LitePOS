import "dart:typed_data";
import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_test/flutter_test.dart";
import "package:billing_pos_app/features/authentication/presentation/auth_state.dart";
import "package:billing_pos_app/features/authentication/models/user_model.dart";
import "package:billing_pos_app/features/hardware/models/discovered_printer_model.dart";
import "package:billing_pos_app/features/hardware/models/printer_model.dart";
import "package:billing_pos_app/features/hardware/presentation/hardware_settings_screen.dart";
import "package:billing_pos_app/features/hardware/presentation/hardware_state.dart";

class FakeHardwareNotifier extends StateNotifier<HardwareState> implements HardwareNotifier {
  FakeHardwareNotifier(super.state);

  @override
  Future<void> loadPrinters() async {}

  @override
  Future<bool> createPrinter(PrinterConfigurationModel config) async => true;

  @override
  Future<bool> updatePrinter(int id, PrinterConfigurationModel config) async => true;

  @override
  Future<bool> deletePrinter(int id) async => true;

  @override
  Future<bool> setDefaultPrinter(int id) async => true;

  @override
  Future<TestPrintResultModel?> testPrint({int? printerId}) async => null;

  @override
  Future<CashDrawerCommandModel?> openCashDrawer() async => null;

  @override
  Future<ReceiptPrintResultModel?> getInvoiceReceipt(int invoiceId, {int? printerId}) async => null;

  @override
  Future<List<DiscoveredPrinterModel>> scanPrinters(PrinterConnectionType type) async => [];

  @override
  Future<bool> directPrintRaw(PrinterConfigurationModel config, Uint8List bytes) async => true;

  @override
  Future<bool> directTestPrint(PrinterConfigurationModel config) async => true;

  @override
  Future<bool> directPrintToken({
    required PrinterConfigurationModel config,
    required List<TokenItemModel> items,
    required String orderId,
    required String tokenNumber,
    bool isEstimate = false,
  }) async => true;

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
  const testPrinter1 = PrinterConfigurationModel(
    id: 1,
    printerName: "Billing Counter 80mm",
    connectionType: PrinterConnectionType.network,
    ipAddress: "192.168.1.100",
    port: 9100,
    paperSize: PrinterPaperSize.mm80,
    characterColumns: 48,
    autoCutReceipt: true,
    openCashDrawer: true,
    printQrCode: true,
    printCopies: 1,
    isDefault: true,
    isActive: true,
  );

  const testPrinter2 = PrinterConfigurationModel(
    id: 2,
    printerName: "Dessert Station 58mm",
    connectionType: PrinterConnectionType.usb,
    usbDeviceName: "POS-58-USB",
    paperSize: PrinterPaperSize.mm58,
    characterColumns: 32,
    autoCutReceipt: false,
    openCashDrawer: false,
    printQrCode: false,
    printCopies: 1,
    isDefault: false,
    isActive: true,
  );

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

  Widget createWidgetUnderTest({required HardwareState hardwareState}) {
    return ProviderScope(
      overrides: [
        hardwareNotifierProvider.overrideWith((ref) => FakeHardwareNotifier(hardwareState)),
        authNotifierProvider.overrideWith((ref) => FakeAuthNotifier(AuthState(user: testUser))),
      ],
      child: const MaterialApp(
        home: HardwareSettingsScreen(),
      ),
    );
  }

  group("HardwareSettingsScreen Tests", () {
    testWidgets("Renders header, default printer banner, and printer cards", (tester) async {
      const state = HardwareState(
        isLoading: false,
        printers: [testPrinter1, testPrinter2],
        defaultPrinter: testPrinter1,
      );

      await tester.pumpWidget(createWidgetUnderTest(hardwareState: state));
      await tester.pumpAndSettle();

      expect(find.text("Hardware & Thermal Printers"), findsOneWidget);
      expect(find.text("Configured Printers (2)"), findsOneWidget);
      expect(find.text("Billing Counter 80mm"), findsWidgets);
      expect(find.text("Dessert Station 58mm"), findsOneWidget);
      expect(find.text("DEFAULT"), findsWidgets);
      expect(find.text("Kick Cash Drawer"), findsOneWidget);
    });

    testWidgets("Renders empty state when no printers configured", (tester) async {
      const state = HardwareState(
        isLoading: false,
        printers: [],
        defaultPrinter: null,
      );

      await tester.pumpWidget(createWidgetUnderTest(hardwareState: state));
      await tester.pumpAndSettle();

      expect(find.text("No Default Printer Set"), findsOneWidget);
      expect(find.text("No thermal printers configured yet"), findsOneWidget);
      expect(find.text("Add First Printer"), findsOneWidget);
    });

    testWidgets("Opens Add Printer dialog when floating action button pressed", (tester) async {
      const state = HardwareState(
        isLoading: false,
        printers: [testPrinter1],
        defaultPrinter: testPrinter1,
      );

      await tester.pumpWidget(createWidgetUnderTest(hardwareState: state));
      await tester.pumpAndSettle();

      final fab = find.byType(FloatingActionButton);
      expect(fab, findsOneWidget);
      await tester.tap(fab);
      await tester.pumpAndSettle();

      expect(find.text("Add Thermal Printer"), findsOneWidget);
      expect(find.text("Printer Name *"), findsOneWidget);
      expect(find.text("Network"), findsOneWidget);
      expect(find.text("USB"), findsOneWidget);
      expect(find.text("Bluetooth"), findsOneWidget);
    });
  });
}
