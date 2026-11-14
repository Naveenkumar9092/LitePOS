import "package:flutter_test/flutter_test.dart";
import "package:billing_pos_app/features/sync/models/sync_models.dart";
import "package:billing_pos_app/features/sync/presentation/sync_state.dart";

void main() {
  group("SyncState Tests", () {
    test("SyncState defaults are properly initialized", () {
      const state = SyncState();
      expect(state.isSyncing, false);
      expect(state.deviceStatus, isNull);
      expect(state.pendingOutboxCount, 0);
      expect(state.lastSyncTime, isNull);
      expect(state.history, isEmpty);
      expect(state.errorMessage, isNull);
      expect(state.successMessage, isNull);
      expect(state.isOnline, true);
    });

    test("SyncState copyWith updates fields properly", () {
      const state = SyncState();
      final device = DeviceStatusModel(
        deviceId: "POS-TERM-01",
        deviceName: "Counter 1",
        appVersion: "1.0.0",
        isOnline: true,
        registeredAtUtc: DateTime.now(),
      );

      final updated = state.copyWith(
        isSyncing: true,
        deviceStatus: device,
        pendingOutboxCount: 4,
        successMessage: "Sync done!",
      );

      expect(updated.isSyncing, true);
      expect(updated.deviceStatus?.deviceName, "Counter 1");
      expect(updated.pendingOutboxCount, 4);
      expect(updated.successMessage, "Sync done!");
    });
  });
}

