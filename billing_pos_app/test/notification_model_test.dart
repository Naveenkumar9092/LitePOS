import "package:flutter_test/flutter_test.dart";
import "package:billing_pos_app/features/notifications/models/notification_models.dart";

void main() {
  group("Notification & Settings Models Tests", () {
    test("SendInvoiceNotificationModel serializes to JSON correctly", () {
      const emailReq = SendInvoiceNotificationModel(
        invoiceId: 10,
        channel: NotificationChannel.email,
        recipientOverride: "priya@example.com",
      );

      final json = emailReq.toJson();
      expect(json["invoiceId"], 10);
      expect(json["channel"], 1);
      expect(json["recipientOverride"], "priya@example.com");
      expect(json["includePaymentQr"], true);
    });

    test("SendInvoiceNotificationModel serializes WhatsApp channel", () {
      const waReq = SendInvoiceNotificationModel(
        invoiceId: 10,
        channel: NotificationChannel.whatsApp,
        recipientOverride: "9876543201",
      );

      final json = waReq.toJson();
      expect(json["channel"], 2);
    });

    test("NotificationResultModel deserializes successfully", () {
      final json = {
        "success": true,
        "channel": 1,
        "recipient": "customer@example.com",
        "invoiceNumber": "INV-20261114-0010",
        "messageId": "EMAIL-MSG-abc12345",
        "sentAtUtc": "2026-11-14T10:00:00Z",
        "message": "Tax Invoice successfully dispatched",
        "previewSnippet": "Subject: Tax Invoice",
      };

      final model = NotificationResultModel.fromJson(json);
      expect(model.success, true);
      expect(model.channel, NotificationChannel.email);
      expect(model.recipient, "customer@example.com");
      expect(model.invoiceNumber, "INV-20261114-0010");
      expect(model.messageId, "EMAIL-MSG-abc12345");
    });

    test("NotificationAuditLogModel parses log JSON", () {
      final json = {
        "id": 1,
        "invoiceId": 10,
        "invoiceNumber": "INV-20261114-0010",
        "channel": 2, // WhatsApp
        "recipient": "9876543201",
        "status": 2,  // Sent
        "sentAtUtc": "2026-11-14T10:05:00Z",
        "subject": "WhatsApp Invoice",
        "messageBody": "🧾 TAX INVOICE",
        "externalReferenceId": "WA-MSG-12345",
        "failureReason": null,
      };

      final model = NotificationAuditLogModel.fromJson(json);
      expect(model.id, 1);
      expect(model.invoiceId, 10);
      expect(model.channel, NotificationChannel.whatsApp);
      expect(model.status, NotificationStatus.sent);
      expect(model.externalReferenceId, "WA-MSG-12345");
    });

    test("ShopPreferenceModel serializes and deserializes properly", () {
      final json = {
        "id": 1,
        "shopId": 1,
        "enableEmailInvoicing": true,
        "enableWhatsAppInvoicing": false,
        "autoSendInvoiceOnPayment": true,
        "receiptHeaderCustom": "Welcome to Our Cafe",
        "receiptFooterCustom": "Thank you!",
        "defaultGstRate": 5.0,
        "enableSoundAlerts": true,
        "backupDirectoryPath": r"C:\LitePOS\Backups",
        "lastBackupUtc": "2026-11-14T08:00:00Z",
        "appVersion": "1.0.0",
      };

      final model = ShopPreferenceModel.fromJson(json);
      expect(model.id, 1);
      expect(model.enableEmailInvoicing, true);
      expect(model.enableWhatsAppInvoicing, false);
      expect(model.autoSendInvoiceOnPayment, true);
      expect(model.receiptHeaderCustom, "Welcome to Our Cafe");
      expect(model.defaultGstRate, 5.0);

      final outJson = model.toJson();
      expect(outJson["enableEmailInvoicing"], true);
      expect(outJson["enableWhatsAppInvoicing"], false);
      expect(outJson["defaultGstRate"], 5.0);
    });

    test("DatabaseBackupResultModel parses backup response", () {
      final json = {
        "backupFileName": "LitePOS_Backup_20261114.bak",
        "backupSizeBytes": 1048576,
        "createdAtUtc": "2026-11-14T10:15:00Z",
        "backupLocation": r"C:\LitePOS\Backups\LitePOS_Backup_20261114.bak",
        "status": "Completed",
        "message": "Backup snapshot created.",
      };

      final model = DatabaseBackupResultModel.fromJson(json);
      expect(model.backupFileName, "LitePOS_Backup_20261114.bak");
      expect(model.backupSizeBytes, 1048576);
      expect(model.status, "Completed");
    });

    test("SystemInfoSummaryModel parses health status JSON", () {
      final json = {
        "appName": "LitePOS Billing Software",
        "appVersion": "1.0.0",
        "environment": "Production",
        "databaseEngine": "Microsoft SQL Server LocalDB",
        "databaseConnected": true,
        "totalInvoices": 25,
        "totalProducts": 10,
        "totalCustomers": 8,
        "activePrinters": 2,
        "lastSyncUtc": "2026-11-14T09:30:00Z",
        "lastBackupUtc": "2026-11-14T09:00:00Z",
        "serverTimeUtc": "2026-11-14T10:20:00Z",
      };

      final model = SystemInfoSummaryModel.fromJson(json);
      expect(model.appName, "LitePOS Billing Software");
      expect(model.totalInvoices, 25);
      expect(model.totalProducts, 10);
      expect(model.totalCustomers, 8);
      expect(model.activePrinters, 2);
      expect(model.databaseConnected, true);
    });
  });
}

