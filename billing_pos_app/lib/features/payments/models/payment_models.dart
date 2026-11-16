enum PaymentModeEnum {
  cash(1, "Cash"),
  upi(2, "UPI"),
  card(3, "Card"),
  split(4, "Split");

  final int value;
  final String label;
  const PaymentModeEnum(this.value, this.label);

  static PaymentModeEnum fromValue(dynamic val) {
    if (val == 2 || val == "UPI" || val == "upi") return PaymentModeEnum.upi;
    if (val == 3 || val == "Card" || val == "card") return PaymentModeEnum.card;
    if (val == 4 || val == "Split" || val == "split") return PaymentModeEnum.split;
    return PaymentModeEnum.cash;
  }
}

enum PaymentStatusEnum {
  pending(1, "Pending"),
  paid(2, "Paid"),
  partiallyPaid(3, "Partially Paid"),
  refunded(4, "Refunded");

  final int value;
  final String label;
  const PaymentStatusEnum(this.value, this.label);

  static PaymentStatusEnum fromValue(dynamic val) {
    if (val == 2 || val == "Paid" || val == "paid") return PaymentStatusEnum.paid;
    if (val == 3 || val == "PartiallyPaid" || val == "partiallyPaid") return PaymentStatusEnum.partiallyPaid;
    if (val == 4 || val == "Refunded" || val == "refunded") return PaymentStatusEnum.refunded;
    return PaymentStatusEnum.pending;
  }
}

class PaymentTransactionModel {
  final int id;
  final String paymentGuid;
  final int invoiceId;
  final String invoiceNumber;
  final PaymentModeEnum paymentMode;
  final String paymentModeName;
  final double amount;
  final String? transactionReference;
  final PaymentStatusEnum paymentStatus;
  final DateTime createdAt;
  final String? cashierUsername;
  final String? customerName;

  PaymentTransactionModel({
    required this.id,
    required this.paymentGuid,
    required this.invoiceId,
    required this.invoiceNumber,
    required this.paymentMode,
    required this.paymentModeName,
    required this.amount,
    this.transactionReference,
    required this.paymentStatus,
    required this.createdAt,
    this.cashierUsername,
    this.customerName,
  });

  factory PaymentTransactionModel.fromJson(Map<String, dynamic> json) {
    return PaymentTransactionModel(
      id: (json["id"] as num?)?.toInt() ?? 0,
      paymentGuid: json["paymentGuid"] as String? ?? "",
      invoiceId: (json["invoiceId"] as num?)?.toInt() ?? 0,
      invoiceNumber: json["invoiceNumber"] as String? ?? "",
      paymentMode: PaymentModeEnum.fromValue(json["paymentMode"]),
      paymentModeName: json["paymentModeName"] as String? ?? "Cash",
      amount: (json["amount"] as num?)?.toDouble() ?? 0.0,
      transactionReference: json["transactionReference"] as String?,
      paymentStatus: PaymentStatusEnum.fromValue(json["paymentStatus"]),
      createdAt: json["createdAtUtc"] != null
          ? DateTime.tryParse(json["createdAtUtc"].toString()) ?? DateTime.now()
          : (json["createdAtUTC"] != null
              ? DateTime.tryParse(json["createdAtUTC"].toString()) ?? DateTime.now()
              : DateTime.now()),
      cashierUsername: json["cashierUsername"] as String?,
      customerName: json["customerName"] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "paymentGuid": paymentGuid,
      "invoiceId": invoiceId,
      "invoiceNumber": invoiceNumber,
      "paymentMode": paymentMode.value,
      "paymentModeName": paymentModeName,
      "amount": amount,
      "transactionReference": transactionReference,
      "paymentStatus": paymentStatus.value,
      "createdAtUtc": createdAt.toIso8601String(),
      "cashierUsername": cashierUsername,
      "customerName": customerName,
    };
  }
}

class ProcessPaymentRequest {
  final int invoiceId;
  final PaymentModeEnum paymentMode;
  final double amount;
  final String? transactionReference;
  final String? notes;

  ProcessPaymentRequest({
    required this.invoiceId,
    required this.paymentMode,
    required this.amount,
    this.transactionReference,
    this.notes,
  });

  Map<String, dynamic> toJson() {
    return {
      "invoiceId": invoiceId,
      "paymentMode": paymentMode.value,
      "amount": amount,
      if (transactionReference != null && transactionReference!.isNotEmpty)
        "transactionReference": transactionReference,
      if (notes != null && notes!.isNotEmpty) "notes": notes,
    };
  }
}

class SplitPaymentItemRequest {
  final PaymentModeEnum paymentMode;
  final double amount;
  final String? transactionReference;

  SplitPaymentItemRequest({
    required this.paymentMode,
    required this.amount,
    this.transactionReference,
  });

  Map<String, dynamic> toJson() {
    return {
      "paymentMode": paymentMode.value,
      "amount": amount,
      if (transactionReference != null && transactionReference!.isNotEmpty)
        "transactionReference": transactionReference,
    };
  }
}

class ProcessSplitPaymentRequest {
  final int invoiceId;
  final List<SplitPaymentItemRequest> payments;

  ProcessSplitPaymentRequest({
    required this.invoiceId,
    required this.payments,
  });

  Map<String, dynamic> toJson() {
    return {
      "invoiceId": invoiceId,
      "payments": payments.map((p) => p.toJson()).toList(),
    };
  }
}

class ProcessRefundRequest {
  final int invoiceId;
  final int? paymentId;
  final double amount;
  final String reason;
  final String? authorizedBy;

  ProcessRefundRequest({
    required this.invoiceId,
    this.paymentId,
    required this.amount,
    required this.reason,
    this.authorizedBy,
  });

  Map<String, dynamic> toJson() {
    return {
      "invoiceId": invoiceId,
      if (paymentId != null) "paymentId": paymentId,
      "amount": amount,
      "reason": reason,
      if (authorizedBy != null && authorizedBy!.isNotEmpty) "authorizedBy": authorizedBy,
    };
  }
}

class PaymentReconciliationModel {
  final DateTime date;
  final double openingFloat;
  final double cashCollected;
  final double upiCollected;
  final double cardCollected;
  final double totalRefunds;
  final double netCollected;
  final int totalTransactions;
  final double expectedCashInDrawer;
  final double? actualCashInDrawer;
  final double? cashDifference;
  final bool isRegisterOpen;
  final String? currentSessionGuid;

  PaymentReconciliationModel({
    required this.date,
    required this.openingFloat,
    required this.cashCollected,
    required this.upiCollected,
    required this.cardCollected,
    required this.totalRefunds,
    required this.netCollected,
    required this.totalTransactions,
    required this.expectedCashInDrawer,
    this.actualCashInDrawer,
    this.cashDifference,
    required this.isRegisterOpen,
    this.currentSessionGuid,
  });

  factory PaymentReconciliationModel.fromJson(Map<String, dynamic> json) {
    return PaymentReconciliationModel(
      date: json["date"] != null ? DateTime.tryParse(json["date"].toString()) ?? DateTime.now() : DateTime.now(),
      openingFloat: (json["openingFloat"] as num?)?.toDouble() ?? 0.0,
      cashCollected: (json["cashCollected"] as num?)?.toDouble() ?? 0.0,
      upiCollected: (json["upiCollected"] as num?)?.toDouble() ?? 0.0,
      cardCollected: (json["cardCollected"] as num?)?.toDouble() ?? 0.0,
      totalRefunds: (json["totalRefunds"] as num?)?.toDouble() ?? 0.0,
      netCollected: (json["netCollected"] as num?)?.toDouble() ?? 0.0,
      totalTransactions: (json["totalTransactions"] as num?)?.toInt() ?? 0,
      expectedCashInDrawer: (json["expectedCashInDrawer"] as num?)?.toDouble() ?? 0.0,
      actualCashInDrawer: (json["actualCashInDrawer"] as num?)?.toDouble(),
      cashDifference: (json["cashDifference"] as num?)?.toDouble(),
      isRegisterOpen: json["isRegisterOpen"] as bool? ?? false,
      currentSessionGuid: json["currentSessionGuid"] as String?,
    );
  }
}

class OpenRegisterRequest {
  final double openingFloat;
  final String? notes;
  final String? deviceId;

  OpenRegisterRequest({
    required this.openingFloat,
    this.notes,
    this.deviceId,
  });

  Map<String, dynamic> toJson() {
    return {
      "openingFloat": openingFloat,
      if (notes != null && notes!.isNotEmpty) "notes": notes,
      if (deviceId != null && deviceId!.isNotEmpty) "deviceId": deviceId,
    };
  }
}

class CloseRegisterRequest {
  final double actualCash;
  final String? notes;

  CloseRegisterRequest({
    required this.actualCash,
    this.notes,
  });

  Map<String, dynamic> toJson() {
    return {
      "actualCash": actualCash,
      if (notes != null && notes!.isNotEmpty) "notes": notes,
    };
  }
}

class CashRegisterSessionModel {
  final int id;
  final String sessionGuid;
  final String cashierUsername;
  final String deviceId;
  final double openingFloat;
  final DateTime openingTime;
  final String? openingNotes;
  final DateTime? closingTime;
  final double? actualCash;
  final double? expectedCash;
  final double? discrepancy;
  final String? closingNotes;
  final bool isOpen;

  CashRegisterSessionModel({
    required this.id,
    required this.sessionGuid,
    required this.cashierUsername,
    required this.deviceId,
    required this.openingFloat,
    required this.openingTime,
    this.openingNotes,
    this.closingTime,
    this.actualCash,
    this.expectedCash,
    this.discrepancy,
    this.closingNotes,
    required this.isOpen,
  });

  factory CashRegisterSessionModel.fromJson(Map<String, dynamic> json) {
    return CashRegisterSessionModel(
      id: (json["id"] as num?)?.toInt() ?? 0,
      sessionGuid: json["sessionGuid"] as String? ?? "",
      cashierUsername: json["cashierUsername"] as String? ?? "",
      deviceId: json["deviceId"] as String? ?? "",
      openingFloat: (json["openingFloat"] as num?)?.toDouble() ?? 0.0,
      openingTime: json["openingTimeUtc"] != null
          ? DateTime.tryParse(json["openingTimeUtc"].toString()) ?? DateTime.now()
          : DateTime.now(),
      openingNotes: json["openingNotes"] as String?,
      closingTime: json["closingTimeUtc"] != null
          ? DateTime.tryParse(json["closingTimeUtc"].toString())
          : null,
      actualCash: (json["actualCash"] as num?)?.toDouble(),
      expectedCash: (json["expectedCash"] as num?)?.toDouble(),
      discrepancy: (json["discrepancy"] as num?)?.toDouble(),
      closingNotes: json["closingNotes"] as String?,
      isOpen: json["isOpen"] as bool? ?? false,
    );
  }
}

class PagedPaymentsResponse {
  final List<PaymentTransactionModel> items;
  final int totalCount;
  final int pageNumber;
  final int pageSize;
  final int totalPages;

  PagedPaymentsResponse({
    required this.items,
    required this.totalCount,
    required this.pageNumber,
    required this.pageSize,
    required this.totalPages,
  });

  factory PagedPaymentsResponse.fromJson(Map<String, dynamic> json) {
    var rawItems = json["items"] as List<dynamic>? ?? [];
    return PagedPaymentsResponse(
      items: rawItems.map((e) => PaymentTransactionModel.fromJson(e as Map<String, dynamic>)).toList(),
      totalCount: (json["totalCount"] as num?)?.toInt() ?? 0,
      pageNumber: (json["pageNumber"] as num?)?.toInt() ?? 1,
      pageSize: (json["pageSize"] as num?)?.toInt() ?? 20,
      totalPages: (json["totalPages"] as num?)?.toInt() ?? 0,
    );
  }
}

