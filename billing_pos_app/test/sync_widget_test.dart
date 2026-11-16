import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_test/flutter_test.dart";
import "package:billing_pos_app/features/sync/models/sync_models.dart";
import "package:billing_pos_app/features/sync/presentation/sync_management_screen.dart";
import "package:billing_pos_app/features/sync/presentation/sync_state.dart";

class FakeSyncNotifier extends StateNotifier<SyncState> implements SyncNotifier {
  FakeSyncNotifier(super.state);

  @override
  Future<void> init() async {}

  @override
  Future<void> registerOrGetDevice() async {}

  @override
  Future<void> checkPending() async {}

  @override
  Future<void> loadHistory() async {}

  @override
  Future<void> syncNow() async {}
}

void main() {
  final testDevice = DeviceStatusModel(
    deviceId: "POS-TERM-01",
    deviceName: "Main Counter Tablet",
    appVersion: "1.0.0",
    isOnline: true,
    lastSyncTimeUtc: DateTime.utc(2026, 11, 13, 12, 0, 0),
    registeredAtUtc: DateTime.utc(2026, 11, 1, 10, 0, 0),
  );

  final testHistory = [
    SyncAuditLogModel(
      id: 1,
      deviceId: "POS-TERM-01",
      syncType: "Full",
      status: "Success",
      recordsPushed: 2,
      recordsPulled: 15,
      conflictsCount: 0,
      startedAtUtc: DateTime.utc(2026, 11, 13, 12, 0, 0),
      completedAtUtc: DateTime.utc(2026, 11, 13, 12, 0, 1),
      durationMs: 380,
    ),
  ];

  final testState = SyncState(
    isSyncing: false,
    deviceStatus: testDevice,
    pendingOutboxCount: 0,
    lastSyncTime: DateTime.utc(2026, 11, 13, 12, 0, 0),
    history: testHistory,
    isOnline: true,
  );

  Widget createWidgetForTesting(SyncState state) {
    return ProviderScope(
      overrides: [
        syncNotifierProvider.overrideWith((ref) => FakeSyncNotifier(state)),
      ],
      child: const MaterialApp(
        home: SyncManagementScreen(),
      ),
    );
  }

  group("SyncManagementScreen Widget Tests", () {
    testWidgets("SyncManagementScreen renders status, action card, and device info", (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 900));
      await tester.pumpWidget(createWidgetForTesting(testState));
      await tester.pumpAndSettle();

      expect(find.text("Offline Sync Engine"), findsOneWidget);
      expect(find.text("Terminal Sync Status"), findsOneWidget);
      expect(find.text("Online (Cloud Connected)"), findsOneWidget);
      expect(find.text("0 Pending Changes"), findsOneWidget);
      expect(find.text("Sync Now"), findsOneWidget);

      expect(find.text("POS Terminal Information"), findsOneWidget);
      expect(find.text("POS-TERM-01"), findsOneWidget);
      expect(find.text("Main Counter Tablet"), findsOneWidget);
      expect(find.text("1.0.0"), findsOneWidget);
    });

    testWidgets("SyncManagementScreen renders sync activity log table", (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 900));
      await tester.pumpWidget(createWidgetForTesting(testState));
      await tester.pumpAndSettle();

      expect(find.text("Sync Activity Log"), findsOneWidget);
      expect(find.text("Full"), findsOneWidget);
      expect(find.text("Success"), findsOneWidget);
      expect(find.text("380 ms"), findsOneWidget);
    });
  });
}

