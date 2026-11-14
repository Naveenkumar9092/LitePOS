class LoginAuditLogModel {
  final int id;
  final int? userId;
  final String usernameAttempted;
  final bool isSuccess;
  final String? ipAddress;
  final String? deviceId;
  final String? failureReason;
  final DateTime attemptedAtUtc;

  LoginAuditLogModel({
    required this.id,
    this.userId,
    required this.usernameAttempted,
    required this.isSuccess,
    this.ipAddress,
    this.deviceId,
    this.failureReason,
    required this.attemptedAtUtc,
  });

  factory LoginAuditLogModel.fromJson(Map<String, dynamic> json) {
    return LoginAuditLogModel(
      id: (json["id"] as num).toInt(),
      userId: (json["userId"] as num?)?.toInt(),
      usernameAttempted: json["usernameAttempted"]?.toString() ?? "",
      isSuccess: json["isSuccess"] as bool? ?? false,
      ipAddress: json["ipAddress"]?.toString(),
      deviceId: json["deviceId"]?.toString(),
      failureReason: json["failureReason"]?.toString(),
      attemptedAtUtc: json["attemptedAtUtc"] != null
          ? DateTime.tryParse(json["attemptedAtUtc"].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

