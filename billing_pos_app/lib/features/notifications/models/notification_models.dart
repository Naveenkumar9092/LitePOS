enum NotificationChannel {
  email,
  whatsApp,
  sms,
}

enum NotificationStatus {
  pending,
  sent,
  failed,
}

class SendInvoiceNotificationModel {
  final int invoiceId;
  final NotificationChannel channel;
  final String? recipientOverride;
  final bool includePaymentQr;

  const SendInvoiceNotificationModel({
    required this.invoiceId,
    required this.channel,
    this.recipientOverride,
    this.includePaymentQr = true,
  });

  Map<String, dynamic> toJson() => {
        "invoiceId": invoiceId,
        "channel": channel == NotificationChannel.email
            ? 1
            : channel == NotificationChannel.whatsApp
                ? 2
                : 3,
        "recipientOverride": recipientOverride,
        "includePaymentQr": includePaymentQr,
      };
}

class NotificationResultModel {
  final bool success;
  final NotificationChannel channel;
  final String recipient;
  final String invoiceNumber;
  final String messageId;
  final DateTime sentAtUtc;
  final String message;
  final String previewSnippet;

  const NotificationResultModel({
    required this.success,
    required this.channel,
    required this.recipient,
    required this.invoiceNumber,
    required this.messageId,
    required this.sentAtUtc,
    required this.message,
    required this.previewSnippet,
  });

  factory NotificationResultModel.fromJson(Map<String, dynamic> json) {
    final chVal = (json["channel"] as num?)?.toInt() ?? 1;
    return NotificationResultModel(
      success: json["success"] as bool? ?? false,
      channel: chVal == 2
          ? NotificationChannel.whatsApp
          : chVal == 3
              ? NotificationChannel.sms
              : NotificationChannel.email,
      recipient: json["recipient"] as String? ?? "",
      invoiceNumber: json["invoiceNumber"] as String? ?? "",
      messageId: json["messageId"] as String? ?? "",
      sentAtUtc: DateTime.tryParse(json["sentAtUtc"]?.toString() ?? "") ?? DateTime.now(),
      message: json["message"] as String? ?? "",
      previewSnippet: json["previewSnippet"] as String? ?? "",
    );
  }
}

class NotificationAuditLogModel {
  final int id;
  final int invoiceId;
  final String invoiceNumber;
  final NotificationChannel channel;
  final String recipient;
  final NotificationStatus status;
  final DateTime? sentAtUtc;
  final String? subject;
  final String messageBody;
  final String? externalReferenceId;
  final String? failureReason;

  const NotificationAuditLogModel({
    required this.id,
    required this.invoiceId,
    required this.invoiceNumber,
    required this.channel,
    required this.recipient,
    required this.status,
    this.sentAtUtc,
    this.subject,
    required this.messageBody,
    this.externalReferenceId,
    this.failureReason,
  });

  factory NotificationAuditLogModel.fromJson(Map<String, dynamic> json) {
    final chVal = (json["channel"] as num?)?.toInt() ?? 1;
    final stVal = (json["status"] as num?)?.toInt() ?? 2;

    return NotificationAuditLogModel(
      id: (json["id"] as num?)?.toInt() ?? 0,
      invoiceId: (json["invoiceId"] as num?)?.toInt() ?? 0,
      invoiceNumber: json["invoiceNumber"] as String? ?? "",
      channel: chVal == 2
          ? NotificationChannel.whatsApp
          : chVal == 3
              ? NotificationChannel.sms
              : NotificationChannel.email,
      recipient: json["recipient"] as String? ?? "",
      status: stVal == 1
          ? NotificationStatus.pending
          : stVal == 3
              ? NotificationStatus.failed
              : NotificationStatus.sent,
      sentAtUtc: json["sentAtUtc"] != null ? DateTime.tryParse(json["sentAtUtc"].toString()) : null,
      subject: json["subject"] as String?,
      messageBody: json["messageBody"] as String? ?? "",
      externalReferenceId: json["externalReferenceId"] as String?,
      failureReason: json["failureReason"] as String?,
    );
  }
}

class ShopPreferenceModel {
  final int id;
  final int shopId;
  final bool enableEmailInvoicing;
  final bool enableWhatsAppInvoicing;
  final bool autoSendInvoiceOnPayment;
  final String? receiptHeaderCustom;
  final String? receiptFooterCustom;
  final double defaultGstRate;
  final bool enableSoundAlerts;
  final String? backupDirectoryPath;
  final DateTime? lastBackupUtc;
  final String appVersion;

  const ShopPreferenceModel({
    required this.id,
    this.shopId = 1,
    this.enableEmailInvoicing = true,
    this.enableWhatsAppInvoicing = true,
    this.autoSendInvoiceOnPayment = false,
    this.receiptHeaderCustom,
    this.receiptFooterCustom,
    this.defaultGstRate = 5.0,
    this.enableSoundAlerts = true,
    this.backupDirectoryPath,
    this.lastBackupUtc,
    this.appVersion = "1.0.0",
  });

  factory ShopPreferenceModel.fromJson(Map<String, dynamic> json) {
    return ShopPreferenceModel(
      id: (json["id"] as num?)?.toInt() ?? 0,
      shopId: (json["shopId"] as num?)?.toInt() ?? 1,
      enableEmailInvoicing: json["enableEmailInvoicing"] as bool? ?? true,
      enableWhatsAppInvoicing: json["enableWhatsAppInvoicing"] as bool? ?? true,
      autoSendInvoiceOnPayment: json["autoSendInvoiceOnPayment"] as bool? ?? false,
      receiptHeaderCustom: json["receiptHeaderCustom"] as String?,
      receiptFooterCustom: json["receiptFooterCustom"] as String?,
      defaultGstRate: (json["defaultGstRate"] as num?)?.toDouble() ?? 5.0,
      enableSoundAlerts: json["enableSoundAlerts"] as bool? ?? true,
      backupDirectoryPath: json["backupDirectoryPath"] as String?,
      lastBackupUtc: json["lastBackupUtc"] != null ? DateTime.tryParse(json["lastBackupUtc"].toString()) : null,
      appVersion: json["appVersion"] as String? ?? "1.0.0",
    );
  }

  Map<String, dynamic> toJson() => {
        "enableEmailInvoicing": enableEmailInvoicing,
        "enableWhatsAppInvoicing": enableWhatsAppInvoicing,
        "autoSendInvoiceOnPayment": autoSendInvoiceOnPayment,
        "receiptHeaderCustom": receiptHeaderCustom,
        "receiptFooterCustom": receiptFooterCustom,
        "defaultGstRate": defaultGstRate,
        "enableSoundAlerts": enableSoundAlerts,
        "backupDirectoryPath": backupDirectoryPath,
      };

  ShopPreferenceModel copyWith({
    int? id,
    int? shopId,
    bool? enableEmailInvoicing,
    bool? enableWhatsAppInvoicing,
    bool? autoSendInvoiceOnPayment,
    String? receiptHeaderCustom,
    String? receiptFooterCustom,
    double? defaultGstRate,
    bool? enableSoundAlerts,
    String? backupDirectoryPath,
    DateTime? lastBackupUtc,
    String? appVersion,
  }) {
    return ShopPreferenceModel(
      id: id ?? this.id,
      shopId: shopId ?? this.shopId,
      enableEmailInvoicing: enableEmailInvoicing ?? this.enableEmailInvoicing,
      enableWhatsAppInvoicing: enableWhatsAppInvoicing ?? this.enableWhatsAppInvoicing,
      autoSendInvoiceOnPayment: autoSendInvoiceOnPayment ?? this.autoSendInvoiceOnPayment,
      receiptHeaderCustom: receiptHeaderCustom ?? this.receiptHeaderCustom,
      receiptFooterCustom: receiptFooterCustom ?? this.receiptFooterCustom,
      defaultGstRate: defaultGstRate ?? this.defaultGstRate,
      enableSoundAlerts: enableSoundAlerts ?? this.enableSoundAlerts,
      backupDirectoryPath: backupDirectoryPath ?? this.backupDirectoryPath,
      lastBackupUtc: lastBackupUtc ?? this.lastBackupUtc,
      appVersion: appVersion ?? this.appVersion,
    );
  }
}

class DatabaseBackupResultModel {
  final String backupFileName;
  final int backupSizeBytes;
  final DateTime createdAtUtc;
  final String backupLocation;
  final String status;
  final String message;

  const DatabaseBackupResultModel({
    required this.backupFileName,
    required this.backupSizeBytes,
    required this.createdAtUtc,
    required this.backupLocation,
    required this.status,
    required this.message,
  });

  factory DatabaseBackupResultModel.fromJson(Map<String, dynamic> json) {
    return DatabaseBackupResultModel(
      backupFileName: json["backupFileName"] as String? ?? "",
      backupSizeBytes: (json["backupSizeBytes"] as num?)?.toInt() ?? 0,
      createdAtUtc: DateTime.tryParse(json["createdAtUtc"]?.toString() ?? "") ?? DateTime.now(),
      backupLocation: json["backupLocation"] as String? ?? "",
      status: json["status"] as String? ?? "Completed",
      message: json["message"] as String? ?? "",
    );
  }
}

class SystemInfoSummaryModel {
  final String appName;
  final String appVersion;
  final String environment;
  final String databaseEngine;
  final bool databaseConnected;
  final int totalInvoices;
  final int totalProducts;
  final int totalCustomers;
  final int activePrinters;
  final DateTime? lastSyncUtc;
  final DateTime? lastBackupUtc;
  final DateTime serverTimeUtc;

  const SystemInfoSummaryModel({
    required this.appName,
    required this.appVersion,
    required this.environment,
    required this.databaseEngine,
    required this.databaseConnected,
    required this.totalInvoices,
    required this.totalProducts,
    required this.totalCustomers,
    required this.activePrinters,
    this.lastSyncUtc,
    this.lastBackupUtc,
    required this.serverTimeUtc,
  });

  factory SystemInfoSummaryModel.fromJson(Map<String, dynamic> json) {
    return SystemInfoSummaryModel(
      appName: json["appName"] as String? ?? "LitePOS Billing Software",
      appVersion: json["appVersion"] as String? ?? "1.0.0",
      environment: json["environment"] as String? ?? "Production",
      databaseEngine: json["databaseEngine"] as String? ?? "Microsoft SQL Server",
      databaseConnected: json["databaseConnected"] as bool? ?? true,
      totalInvoices: (json["totalInvoices"] as num?)?.toInt() ?? 0,
      totalProducts: (json["totalProducts"] as num?)?.toInt() ?? 0,
      totalCustomers: (json["totalCustomers"] as num?)?.toInt() ?? 0,
      activePrinters: (json["activePrinters"] as num?)?.toInt() ?? 0,
      lastSyncUtc: json["lastSyncUtc"] != null ? DateTime.tryParse(json["lastSyncUtc"].toString()) : null,
      lastBackupUtc: json["lastBackupUtc"] != null ? DateTime.tryParse(json["lastBackupUtc"].toString()) : null,
      serverTimeUtc: DateTime.tryParse(json["serverTimeUtc"]?.toString() ?? "") ?? DateTime.now(),
    );
  }
}

