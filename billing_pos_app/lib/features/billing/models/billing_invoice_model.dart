class BillingInvoiceItemModel {
  final int invoiceDetailId;
  final int invoiceId;
  final int productId;
  final String productNameSnapshot;
  final double unitPrice;
  final int quantity;
  final double discountAmount;
  final double taxPercentage;
  final double taxAmount;
  final double lineTotal;

  BillingInvoiceItemModel({
    required this.invoiceDetailId,
    required this.invoiceId,
    required this.productId,
    required this.productNameSnapshot,
    required this.unitPrice,
    required this.quantity,
    this.discountAmount = 0.0,
    this.taxPercentage = 0.0,
    this.taxAmount = 0.0,
    required this.lineTotal,
  });

  factory BillingInvoiceItemModel.fromJson(Map<String, dynamic> json) {
    return BillingInvoiceItemModel(
      invoiceDetailId: (json["invoiceDetailId"] as num?)?.toInt() ?? 0,
      invoiceId: (json["invoiceId"] as num?)?.toInt() ?? 0,
      productId: (json["productId"] as num).toInt(),
      productNameSnapshot: json["productNameSnapshot"]?.toString() ?? "",
      unitPrice: (json["unitPrice"] as num?)?.toDouble() ?? 0.0,
      quantity: (json["quantity"] as num?)?.toInt() ?? 1,
      discountAmount: (json["discountAmount"] as num?)?.toDouble() ?? 0.0,
      taxPercentage: (json["taxPercentage"] as num?)?.toDouble() ?? 0.0,
      taxAmount: (json["taxAmount"] as num?)?.toDouble() ?? 0.0,
      lineTotal: (json["lineTotal"] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "invoiceDetailId": invoiceDetailId,
      "invoiceId": invoiceId,
      "productId": productId,
      "productNameSnapshot": productNameSnapshot,
      "unitPrice": unitPrice,
      "quantity": quantity,
      "discountAmount": discountAmount,
      "taxPercentage": taxPercentage,
      "taxAmount": taxAmount,
      "lineTotal": lineTotal,
    };
  }

  Map<String, dynamic> toLocalDbMap() {
    return {
      "InvoiceId": invoiceId,
      "ProductId": productId,
      "ProductNameSnapshot": productNameSnapshot,
      "UnitPrice": unitPrice,
      "Quantity": quantity,
      "DiscountAmount": discountAmount,
      "TaxPercentage": taxPercentage,
      "TaxAmount": taxAmount,
      "LineTotal": lineTotal,
    };
  }

  factory BillingInvoiceItemModel.fromLocalDbMap(Map<String, dynamic> map) {
    return BillingInvoiceItemModel(
      invoiceDetailId: (map["InvoiceDetailId"] as num?)?.toInt() ?? 0,
      invoiceId: (map["InvoiceId"] as num).toInt(),
      productId: (map["ProductId"] as num).toInt(),
      productNameSnapshot: map["ProductNameSnapshot"]?.toString() ?? "",
      unitPrice: (map["UnitPrice"] as num?)?.toDouble() ?? 0.0,
      quantity: (map["Quantity"] as num?)?.toInt() ?? 1,
      discountAmount: (map["DiscountAmount"] as num?)?.toDouble() ?? 0.0,
      taxPercentage: (map["TaxPercentage"] as num?)?.toDouble() ?? 0.0,
      taxAmount: (map["TaxAmount"] as num?)?.toDouble() ?? 0.0,
      lineTotal: (map["LineTotal"] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class BillingPaymentModel {
  final int paymentId;
  final String paymentGuid;
  final int invoiceId;
  final int paymentMode;
  final String paymentModeName;
  final double amount;
  final String? transactionReference;
  final int paymentStatus;
  final DateTime createdAtUtc;

  BillingPaymentModel({
    required this.paymentId,
    required this.paymentGuid,
    required this.invoiceId,
    required this.paymentMode,
    required this.paymentModeName,
    required this.amount,
    this.transactionReference,
    required this.paymentStatus,
    required this.createdAtUtc,
  });

  factory BillingPaymentModel.fromJson(Map<String, dynamic> json) {
    return BillingPaymentModel(
      paymentId: (json["paymentId"] as num?)?.toInt() ?? 0,
      paymentGuid: json["paymentGuid"]?.toString() ?? "",
      invoiceId: (json["invoiceId"] as num?)?.toInt() ?? 0,
      paymentMode: (json["paymentMode"] as num?)?.toInt() ?? 1,
      paymentModeName: json["paymentModeName"]?.toString() ?? "Cash",
      amount: (json["amount"] as num?)?.toDouble() ?? 0.0,
      transactionReference: json["transactionReference"]?.toString(),
      paymentStatus: (json["paymentStatus"] as num?)?.toInt() ?? 2,
      createdAtUtc: json["createdAtUtc"] != null
          ? DateTime.tryParse(json["createdAtUtc"].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "paymentId": paymentId,
      "paymentGuid": paymentGuid,
      "invoiceId": invoiceId,
      "paymentMode": paymentMode,
      "paymentModeName": paymentModeName,
      "amount": amount,
      "transactionReference": transactionReference,
      "paymentStatus": paymentStatus,
      "createdAtUtc": createdAtUtc.toIso8601String(),
    };
  }

  Map<String, dynamic> toLocalDbMap() {
    return {
      "InvoiceId": invoiceId,
      "PaymentMode": paymentMode,
      "PaymentModeName": paymentModeName,
      "Amount": amount,
      "TransactionReference": transactionReference,
      "PaymentStatus": paymentStatus,
      "CreatedAtUTC": createdAtUtc.toIso8601String(),
    };
  }

  factory BillingPaymentModel.fromLocalDbMap(Map<String, dynamic> map) {
    return BillingPaymentModel(
      paymentId: (map["PaymentId"] as num?)?.toInt() ?? 0,
      paymentGuid: map["PaymentGuid"]?.toString() ?? "",
      invoiceId: (map["InvoiceId"] as num).toInt(),
      paymentMode: (map["PaymentMode"] as num?)?.toInt() ?? 1,
      paymentModeName: map["PaymentModeName"]?.toString() ?? "Cash",
      amount: (map["Amount"] as num?)?.toDouble() ?? 0.0,
      transactionReference: map["TransactionReference"]?.toString(),
      paymentStatus: (map["PaymentStatus"] as num?)?.toInt() ?? 2,
      createdAtUtc: map["CreatedAtUTC"] != null
          ? DateTime.tryParse(map["CreatedAtUTC"].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

class BillingInvoiceModel {
  final int invoiceId;
  final String invoiceGuid;
  final String invoiceNumber;
  final int companyId;
  final String companyName;
  final int shopId;
  final String shopName;
  final int? customerId;
  final String? customerName;
  final String? customerMobile;
  final int cashierId;
  final String cashierName;
  final String deviceId;
  final DateTime invoiceDateUtc;
  final double subTotal;
  final double discountAmount;
  final double taxableAmount;
  final double taxAmount;
  final double grandTotal;
  final double paidAmount;
  final double balanceAmount;
  final int paymentStatus;
  final int invoiceStatus;
  final int syncStatus;
  final List<BillingInvoiceItemModel> items;
  final List<BillingPaymentModel> payments;
  final DateTime createdAtUtc;

  BillingInvoiceModel({
    required this.invoiceId,
    required this.invoiceGuid,
    required this.invoiceNumber,
    required this.companyId,
    required this.companyName,
    required this.shopId,
    required this.shopName,
    this.customerId,
    this.customerName,
    this.customerMobile,
    required this.cashierId,
    required this.cashierName,
    required this.deviceId,
    required this.invoiceDateUtc,
    required this.subTotal,
    required this.discountAmount,
    required this.taxableAmount,
    required this.taxAmount,
    required this.grandTotal,
    required this.paidAmount,
    required this.balanceAmount,
    required this.paymentStatus,
    required this.invoiceStatus,
    required this.syncStatus,
    this.items = const [],
    this.payments = const [],
    required this.createdAtUtc,
  });

  factory BillingInvoiceModel.fromJson(Map<String, dynamic> json) {
    final rawItems = json["items"] as List<dynamic>? ?? [];
    final items = rawItems.map((e) => BillingInvoiceItemModel.fromJson(e as Map<String, dynamic>)).toList();

    final rawPayments = json["payments"] as List<dynamic>? ?? [];
    final payments = rawPayments.map((e) => BillingPaymentModel.fromJson(e as Map<String, dynamic>)).toList();

    return BillingInvoiceModel(
      invoiceId: (json["invoiceId"] as num?)?.toInt() ?? 0,
      invoiceGuid: json["invoiceGuid"]?.toString() ?? "",
      invoiceNumber: json["invoiceNumber"]?.toString() ?? "",
      companyId: (json["companyId"] as num?)?.toInt() ?? 1,
      companyName: json["companyName"]?.toString() ?? "",
      shopId: (json["shopId"] as num?)?.toInt() ?? 1,
      shopName: json["shopName"]?.toString() ?? "",
      customerId: (json["customerId"] as num?)?.toInt(),
      customerName: json["customerName"]?.toString(),
      customerMobile: json["customerMobile"]?.toString(),
      cashierId: (json["cashierId"] as num?)?.toInt() ?? 1,
      cashierName: json["cashierName"]?.toString() ?? "Cashier",
      deviceId: json["deviceId"]?.toString() ?? "POS-TERMINAL-01",
      invoiceDateUtc: json["invoiceDateUtc"] != null
          ? DateTime.tryParse(json["invoiceDateUtc"].toString()) ?? DateTime.now()
          : DateTime.now(),
      subTotal: (json["subTotal"] as num?)?.toDouble() ?? 0.0,
      discountAmount: (json["discountAmount"] as num?)?.toDouble() ?? 0.0,
      taxableAmount: (json["taxableAmount"] as num?)?.toDouble() ?? 0.0,
      taxAmount: (json["taxAmount"] as num?)?.toDouble() ?? 0.0,
      grandTotal: (json["grandTotal"] as num?)?.toDouble() ?? 0.0,
      paidAmount: (json["paidAmount"] as num?)?.toDouble() ?? 0.0,
      balanceAmount: (json["balanceAmount"] as num?)?.toDouble() ?? 0.0,
      paymentStatus: (json["paymentStatus"] as num?)?.toInt() ?? 2,
      invoiceStatus: (json["invoiceStatus"] as num?)?.toInt() ?? 2,
      syncStatus: (json["syncStatus"] as num?)?.toInt() ?? 1,
      items: items,
      payments: payments,
      createdAtUtc: json["createdAtUtc"] != null
          ? DateTime.tryParse(json["createdAtUtc"].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "invoiceId": invoiceId,
      "invoiceGuid": invoiceGuid,
      "invoiceNumber": invoiceNumber,
      "companyId": companyId,
      "companyName": companyName,
      "shopId": shopId,
      "shopName": shopName,
      "customerId": customerId,
      "customerName": customerName,
      "customerMobile": customerMobile,
      "cashierId": cashierId,
      "cashierName": cashierName,
      "deviceId": deviceId,
      "invoiceDateUtc": invoiceDateUtc.toIso8601String(),
      "subTotal": subTotal,
      "discountAmount": discountAmount,
      "taxableAmount": taxableAmount,
      "taxAmount": taxAmount,
      "grandTotal": grandTotal,
      "paidAmount": paidAmount,
      "balanceAmount": balanceAmount,
      "paymentStatus": paymentStatus,
      "invoiceStatus": invoiceStatus,
      "syncStatus": syncStatus,
      "items": items.map((i) => i.toJson()).toList(),
      "payments": payments.map((p) => p.toJson()).toList(),
      "createdAtUtc": createdAtUtc.toIso8601String(),
    };
  }

  Map<String, dynamic> toLocalDbMap() {
    return {
      "InvoiceNumber": invoiceNumber,
      "CompanyId": companyId,
      "ShopId": shopId,
      "CustomerId": customerId,
      "CashierId": cashierId,
      "DeviceId": deviceId,
      "InvoiceDateUTC": invoiceDateUtc.toIso8601String(),
      "SubTotal": subTotal,
      "DiscountAmount": discountAmount,
      "TaxableAmount": taxableAmount,
      "TaxAmount": taxAmount,
      "GrandTotal": grandTotal,
      "PaidAmount": paidAmount,
      "BalanceAmount": balanceAmount,
      "PaymentStatus": paymentStatus,
      "InvoiceStatus": invoiceStatus,
      "SyncStatus": syncStatus,
      "CreatedAtUTC": createdAtUtc.toIso8601String(),
    };
  }

  factory BillingInvoiceModel.fromLocalDbMap(
    Map<String, dynamic> map, {
    List<BillingInvoiceItemModel> items = const [],
    List<BillingPaymentModel> payments = const [],
  }) {
    return BillingInvoiceModel(
      invoiceId: (map["InvoiceId"] as num?)?.toInt() ?? 0,
      invoiceGuid: map["InvoiceGuid"]?.toString() ?? "",
      invoiceNumber: map["InvoiceNumber"]?.toString() ?? "",
      companyId: (map["CompanyId"] as num?)?.toInt() ?? 1,
      companyName: "LitePOS Cafe",
      shopId: (map["ShopId"] as num?)?.toInt() ?? 1,
      shopName: "Main Branch",
      customerId: (map["CustomerId"] as num?)?.toInt(),
      cashierId: (map["CashierId"] as num?)?.toInt() ?? 1,
      cashierName: "Cashier",
      deviceId: map["DeviceId"]?.toString() ?? "POS-TERMINAL-01",
      invoiceDateUtc: map["InvoiceDateUTC"] != null
          ? DateTime.tryParse(map["InvoiceDateUTC"].toString()) ?? DateTime.now()
          : DateTime.now(),
      subTotal: (map["SubTotal"] as num?)?.toDouble() ?? 0.0,
      discountAmount: (map["DiscountAmount"] as num?)?.toDouble() ?? 0.0,
      taxableAmount: (map["TaxableAmount"] as num?)?.toDouble() ?? 0.0,
      taxAmount: (map["TaxAmount"] as num?)?.toDouble() ?? 0.0,
      grandTotal: (map["GrandTotal"] as num?)?.toDouble() ?? 0.0,
      paidAmount: (map["PaidAmount"] as num?)?.toDouble() ?? 0.0,
      balanceAmount: (map["BalanceAmount"] as num?)?.toDouble() ?? 0.0,
      paymentStatus: (map["PaymentStatus"] as num?)?.toInt() ?? 2,
      invoiceStatus: (map["InvoiceStatus"] as num?)?.toInt() ?? 2,
      syncStatus: (map["SyncStatus"] as num?)?.toInt() ?? 1,
      items: items,
      payments: payments,
      createdAtUtc: map["CreatedAtUTC"] != null
          ? DateTime.tryParse(map["CreatedAtUTC"].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

