class DeviceStatusModel {
  final String deviceId;
  final String deviceName;
  final String appVersion;
  final bool isOnline;
  final DateTime? lastSyncTimeUtc;
  final int syncFailuresCount;
  final DateTime registeredAtUtc;

  const DeviceStatusModel({
    required this.deviceId,
    required this.deviceName,
    required this.appVersion,
    required this.isOnline,
    this.lastSyncTimeUtc,
    this.syncFailuresCount = 0,
    required this.registeredAtUtc,
  });

  factory DeviceStatusModel.fromJson(Map<String, dynamic> json) {
    return DeviceStatusModel(
      deviceId: json["deviceId"] as String? ?? "POS-TERM-01",
      deviceName: json["deviceName"] as String? ?? "POS Terminal",
      appVersion: json["appVersion"] as String? ?? "1.0.0",
      isOnline: json["isOnline"] as bool? ?? true,
      lastSyncTimeUtc: json["lastSyncTimeUtc"] != null
          ? DateTime.tryParse(json["lastSyncTimeUtc"].toString())
          : null,
      syncFailuresCount: (json["syncFailuresCount"] as num?)?.toInt() ?? 0,
      registeredAtUtc: DateTime.tryParse(json["registeredAtUtc"]?.toString() ?? "") ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        "deviceId": deviceId,
        "deviceName": deviceName,
        "appVersion": appVersion,
        "isOnline": isOnline,
        "lastSyncTimeUtc": lastSyncTimeUtc?.toIso8601String(),
        "syncFailuresCount": syncFailuresCount,
        "registeredAtUtc": registeredAtUtc.toIso8601String(),
      };
}

class SyncedEntityMappingModel {
  final String clientGuid;
  final int serverId;
  final String? serverReference;
  final bool wasAlreadySynced;

  const SyncedEntityMappingModel({
    required this.clientGuid,
    required this.serverId,
    this.serverReference,
    required this.wasAlreadySynced,
  });

  factory SyncedEntityMappingModel.fromJson(Map<String, dynamic> json) {
    return SyncedEntityMappingModel(
      clientGuid: json["clientGuid"] as String? ?? "",
      serverId: (json["serverId"] as num?)?.toInt() ?? 0,
      serverReference: json["serverReference"] as String?,
      wasAlreadySynced: json["wasAlreadySynced"] as bool? ?? false,
    );
  }
}

class SyncPushResultModel {
  final int totalReceived;
  final int totalProcessed;
  final int totalFailed;
  final List<SyncedEntityMappingModel> syncedInvoices;
  final List<SyncedEntityMappingModel> syncedCustomers;
  final List<String> errors;

  const SyncPushResultModel({
    required this.totalReceived,
    required this.totalProcessed,
    required this.totalFailed,
    required this.syncedInvoices,
    required this.syncedCustomers,
    required this.errors,
  });

  factory SyncPushResultModel.fromJson(Map<String, dynamic> json) {
    return SyncPushResultModel(
      totalReceived: (json["totalReceived"] as num?)?.toInt() ?? 0,
      totalProcessed: (json["totalProcessed"] as num?)?.toInt() ?? 0,
      totalFailed: (json["totalFailed"] as num?)?.toInt() ?? 0,
      syncedInvoices: (json["syncedInvoices"] as List<dynamic>?)
              ?.map((e) => SyncedEntityMappingModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      syncedCustomers: (json["syncedCustomers"] as List<dynamic>?)
              ?.map((e) => SyncedEntityMappingModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      errors: (json["errors"] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
    );
  }
}

class SyncAuditLogModel {
  final int id;
  final String deviceId;
  final String syncType;
  final String status;
  final int recordsPushed;
  final int recordsPulled;
  final int conflictsCount;
  final String? errorDetails;
  final DateTime startedAtUtc;
  final DateTime completedAtUtc;
  final int durationMs;

  const SyncAuditLogModel({
    required this.id,
    required this.deviceId,
    required this.syncType,
    required this.status,
    required this.recordsPushed,
    required this.recordsPulled,
    required this.conflictsCount,
    this.errorDetails,
    required this.startedAtUtc,
    required this.completedAtUtc,
    required this.durationMs,
  });

  factory SyncAuditLogModel.fromJson(Map<String, dynamic> json) {
    return SyncAuditLogModel(
      id: (json["id"] as num?)?.toInt() ?? 0,
      deviceId: json["deviceId"] as String? ?? "",
      syncType: json["syncType"] as String? ?? "Full",
      status: json["status"] as String? ?? "Success",
      recordsPushed: (json["recordsPushed"] as num?)?.toInt() ?? 0,
      recordsPulled: (json["recordsPulled"] as num?)?.toInt() ?? 0,
      conflictsCount: (json["conflictsCount"] as num?)?.toInt() ?? 0,
      errorDetails: json["errorDetails"] as String?,
      startedAtUtc: DateTime.tryParse(json["startedAtUtc"]?.toString() ?? "") ?? DateTime.now(),
      completedAtUtc: DateTime.tryParse(json["completedAtUtc"]?.toString() ?? "") ?? DateTime.now(),
      durationMs: (json["durationMs"] as num?)?.toInt() ?? 0,
    );
  }
}

