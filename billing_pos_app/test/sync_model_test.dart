import "package:flutter_test/flutter_test.dart";
import "package:billing_pos_app/features/sync/models/sync_models.dart";

void main() {
  group("Sync Models Tests", () {
    test("DeviceStatusModel serializes to and from JSON correctly", () {
      final json = {
        "deviceId": "POS-TERM-01",
        "deviceName": "Main Counter Terminal",
        "appVersion": "1.0.0",
        "isOnline": true,
        "lastSyncTimeUtc": "2026-11-13T12:00:00Z",
        "syncFailuresCount": 0,
        "registeredAtUtc": "2026-11-01T10:00:00Z",
      };

      final model = DeviceStatusModel.fromJson(json);

      expect(model.deviceId, "POS-TERM-01");
      expect(model.deviceName, "Main Counter Terminal");
      expect(model.appVersion, "1.0.0");
      expect(model.isOnline, true);
      expect(model.syncFailuresCount, 0);

      final outJson = model.toJson();
      expect(outJson["deviceId"], "POS-TERM-01");
      expect(outJson["deviceName"], "Main Counter Terminal");
    });

    test("SyncedEntityMappingModel parses mapping JSON", () {
      final json = {
        "clientGuid": "guid-1234",
        "serverId": 42,
        "serverReference": "INV-2026-0042",
        "wasAlreadySynced": false,
      };

      final model = SyncedEntityMappingModel.fromJson(json);

      expect(model.clientGuid, "guid-1234");
      expect(model.serverId, 42);
      expect(model.serverReference, "INV-2026-0042");
      expect(model.wasAlreadySynced, false);
    });

    test("SyncPushResultModel deserializes batch result JSON", () {
      final json = {
        "totalReceived": 5,
        "totalProcessed": 5,
        "totalFailed": 0,
        "syncedInvoices": [
          {
            "clientGuid": "inv-guid-1",
            "serverId": 101,
            "serverReference": "INV-101",
            "wasAlreadySynced": false,
          }
        ],
        "syncedCustomers": [
          {
            "clientGuid": "cust-guid-1",
            "serverId": 55,
            "serverReference": "Karthik",
            "wasAlreadySynced": true,
          }
        ],
        "errors": <String>[],
      };

      final model = SyncPushResultModel.fromJson(json);

      expect(model.totalReceived, 5);
      expect(model.totalProcessed, 5);
      expect(model.totalFailed, 0);
      expect(model.syncedInvoices.length, 1);
      expect(model.syncedCustomers.length, 1);
      expect(model.syncedCustomers.first.wasAlreadySynced, true);
    });

    test("SyncAuditLogModel parses log entry JSON", () {
      final json = {
        "id": 1,
        "deviceId": "POS-TERM-01",
        "syncType": "Full",
        "status": "Success",
        "recordsPushed": 3,
        "recordsPulled": 25,
        "conflictsCount": 0,
        "errorDetails": null,
        "startedAtUtc": "2026-11-13T12:00:00Z",
        "completedAtUtc": "2026-11-13T12:00:01Z",
        "durationMs": 450,
      };

      final model = SyncAuditLogModel.fromJson(json);

      expect(model.id, 1);
      expect(model.deviceId, "POS-TERM-01");
      expect(model.syncType, "Full");
      expect(model.status, "Success");
      expect(model.recordsPushed, 3);
      expect(model.recordsPulled, 25);
      expect(model.durationMs, 450);
    });
  });
}

