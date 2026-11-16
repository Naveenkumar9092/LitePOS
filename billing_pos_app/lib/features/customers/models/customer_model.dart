class CustomerModel {
  final int id;
  final String customerGuid;
  final String customerName;
  final String mobileNumber;
  final String? whatsAppNumber;
  final String? email;
  final String? address;
  final String? gstin;
  final bool emailConsent;
  final bool whatsAppConsent;
  final int totalInvoicesCount;
  final double totalSpent;
  final DateTime? lastVisitDateUtc;
  final bool isActive;
  final DateTime createdAtUtc;

  const CustomerModel({
    required this.id,
    required this.customerGuid,
    required this.customerName,
    required this.mobileNumber,
    this.whatsAppNumber,
    this.email,
    this.address,
    this.gstin,
    required this.emailConsent,
    required this.whatsAppConsent,
    required this.totalInvoicesCount,
    required this.totalSpent,
    this.lastVisitDateUtc,
    required this.isActive,
    required this.createdAtUtc,
  });

  factory CustomerModel.fromJson(Map<String, dynamic> json) {
    return CustomerModel(
      id: (json["id"] as num).toInt(),
      customerGuid: json["customerGuid"]?.toString() ?? "",
      customerName: json["customerName"]?.toString() ?? "",
      mobileNumber: json["mobileNumber"]?.toString() ?? "",
      whatsAppNumber: json["whatsAppNumber"]?.toString(),
      email: json["email"]?.toString(),
      address: json["address"]?.toString(),
      gstin: json["gstin"]?.toString(),
      emailConsent: json["emailConsent"] as bool? ?? false,
      whatsAppConsent: json["whatsAppConsent"] as bool? ?? false,
      totalInvoicesCount: (json["totalInvoicesCount"] as num?)?.toInt() ?? 0,
      totalSpent: (json["totalSpent"] as num?)?.toDouble() ?? 0.0,
      lastVisitDateUtc: json["lastVisitDateUtc"] != null
          ? DateTime.tryParse(json["lastVisitDateUtc"].toString())
          : null,
      isActive: json["isActive"] as bool? ?? true,
      createdAtUtc: DateTime.tryParse(json["createdAtUtc"]?.toString() ?? "") ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    "id": id,
    "customerGuid": customerGuid,
    "customerName": customerName,
    "mobileNumber": mobileNumber,
    "whatsAppNumber": whatsAppNumber,
    "email": email,
    "address": address,
    "gstin": gstin,
    "emailConsent": emailConsent,
    "whatsAppConsent": whatsAppConsent,
    "totalInvoicesCount": totalInvoicesCount,
    "totalSpent": totalSpent,
    "lastVisitDateUtc": lastVisitDateUtc?.toIso8601String(),
    "isActive": isActive,
    "createdAtUtc": createdAtUtc.toIso8601String(),
  };

  Map<String, dynamic> toSqlite() => {
    "CustomerId": id,
    "CustomerGuid": customerGuid,
    "CustomerName": customerName,
    "MobileNumber": mobileNumber,
    "WhatsAppNumber": whatsAppNumber,
    "Email": email,
    "Address": address,
    "GSTIN": gstin,
    "EmailConsent": emailConsent ? 1 : 0,
    "WhatsAppConsent": whatsAppConsent ? 1 : 0,
    "IsActive": isActive ? 1 : 0,
    "CreatedAtUTC": createdAtUtc.toIso8601String(),
  };

  factory CustomerModel.fromSqlite(Map<String, dynamic> map) {
    return CustomerModel(
      id: (map["CustomerId"] as num).toInt(),
      customerGuid: map["CustomerGuid"]?.toString() ?? "",
      customerName: map["CustomerName"]?.toString() ?? "",
      mobileNumber: map["MobileNumber"]?.toString() ?? "",
      whatsAppNumber: map["WhatsAppNumber"]?.toString(),
      email: map["Email"]?.toString(),
      address: map["Address"]?.toString(),
      gstin: map["GSTIN"]?.toString(),
      emailConsent: (map["EmailConsent"] as num?) == 1,
      whatsAppConsent: (map["WhatsAppConsent"] as num?) == 1,
      totalInvoicesCount: 0,
      totalSpent: 0.0,
      lastVisitDateUtc: null,
      isActive: (map["IsActive"] as num?) == 1,
      createdAtUtc: DateTime.tryParse(map["CreatedAtUTC"]?.toString() ?? "") ?? DateTime.now(),
    );
  }
}

class CustomerLookupModel {
  final int id;
  final String customerName;
  final String mobileNumber;
  final String? gstin;
  final String? email;
  final String? whatsAppNumber;

  const CustomerLookupModel({
    required this.id,
    required this.customerName,
    required this.mobileNumber,
    this.gstin,
    this.email,
    this.whatsAppNumber,
  });

  factory CustomerLookupModel.fromJson(Map<String, dynamic> json) {
    return CustomerLookupModel(
      id: (json["id"] as num).toInt(),
      customerName: json["customerName"]?.toString() ?? "",
      mobileNumber: json["mobileNumber"]?.toString() ?? "",
      gstin: json["gstin"]?.toString(),
      email: json["email"]?.toString(),
      whatsAppNumber: json["whatsAppNumber"]?.toString(),
    );
  }
}

class CreateCustomerRequest {
  final String customerName;
  final String mobileNumber;
  final String? whatsAppNumber;
  final String? email;
  final String? address;
  final String? gstin;
  final bool emailConsent;
  final bool whatsAppConsent;

  const CreateCustomerRequest({
    required this.customerName,
    required this.mobileNumber,
    this.whatsAppNumber,
    this.email,
    this.address,
    this.gstin,
    this.emailConsent = false,
    this.whatsAppConsent = false,
  });

  Map<String, dynamic> toJson() => {
    "customerName": customerName,
    "mobileNumber": mobileNumber,
    if (whatsAppNumber != null) "whatsAppNumber": whatsAppNumber,
    if (email != null) "email": email,
    if (address != null) "address": address,
    if (gstin != null) "gstin": gstin,
    "emailConsent": emailConsent,
    "whatsAppConsent": whatsAppConsent,
  };
}

class UpdateCustomerRequest {
  final String customerName;
  final String mobileNumber;
  final String? whatsAppNumber;
  final String? email;
  final String? address;
  final String? gstin;
  final bool emailConsent;
  final bool whatsAppConsent;
  final bool isActive;

  const UpdateCustomerRequest({
    required this.customerName,
    required this.mobileNumber,
    this.whatsAppNumber,
    this.email,
    this.address,
    this.gstin,
    required this.emailConsent,
    required this.whatsAppConsent,
    required this.isActive,
  });

  Map<String, dynamic> toJson() => {
    "customerName": customerName,
    "mobileNumber": mobileNumber,
    if (whatsAppNumber != null) "whatsAppNumber": whatsAppNumber,
    if (email != null) "email": email,
    if (address != null) "address": address,
    if (gstin != null) "gstin": gstin,
    "emailConsent": emailConsent,
    "whatsAppConsent": whatsAppConsent,
    "isActive": isActive,
  };
}

class CustomerInvoiceModel {
  final int invoiceId;
  final String invoiceNumber;
  final DateTime invoiceDateUtc;
  final double grandTotal;
  final String paymentStatus;
  final int totalItems;

  const CustomerInvoiceModel({
    required this.invoiceId,
    required this.invoiceNumber,
    required this.invoiceDateUtc,
    required this.grandTotal,
    required this.paymentStatus,
    required this.totalItems,
  });

  factory CustomerInvoiceModel.fromJson(Map<String, dynamic> json) {
    return CustomerInvoiceModel(
      invoiceId: (json["invoiceId"] as num).toInt(),
      invoiceNumber: json["invoiceNumber"]?.toString() ?? "",
      invoiceDateUtc: DateTime.tryParse(json["invoiceDateUtc"]?.toString() ?? "") ?? DateTime.now(),
      grandTotal: (json["grandTotal"] as num?)?.toDouble() ?? 0.0,
      paymentStatus: json["paymentStatus"]?.toString() ?? "Paid",
      totalItems: (json["totalItems"] as num?)?.toInt() ?? 0,
    );
  }
}

class CustomerPurchaseHistoryModel {
  final int customerId;
  final String customerName;
  final String mobileNumber;
  final String? gstin;
  final int totalInvoices;
  final double totalSpent;
  final DateTime? firstVisitDateUtc;
  final DateTime? lastVisitDateUtc;
  final List<CustomerInvoiceModel> invoices;

  const CustomerPurchaseHistoryModel({
    required this.customerId,
    required this.customerName,
    required this.mobileNumber,
    this.gstin,
    required this.totalInvoices,
    required this.totalSpent,
    this.firstVisitDateUtc,
    this.lastVisitDateUtc,
    required this.invoices,
  });

  factory CustomerPurchaseHistoryModel.fromJson(Map<String, dynamic> json) {
    return CustomerPurchaseHistoryModel(
      customerId: (json["customerId"] as num).toInt(),
      customerName: json["customerName"]?.toString() ?? "",
      mobileNumber: json["mobileNumber"]?.toString() ?? "",
      gstin: json["gstin"]?.toString(),
      totalInvoices: (json["totalInvoices"] as num?)?.toInt() ?? 0,
      totalSpent: (json["totalSpent"] as num?)?.toDouble() ?? 0.0,
      firstVisitDateUtc: json["firstVisitDateUtc"] != null
          ? DateTime.tryParse(json["firstVisitDateUtc"].toString())
          : null,
      lastVisitDateUtc: json["lastVisitDateUtc"] != null
          ? DateTime.tryParse(json["lastVisitDateUtc"].toString())
          : null,
      invoices: (json["invoices"] as List<dynamic>?)
              ?.map((e) => CustomerInvoiceModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class PagedCustomersResponse {
  final List<CustomerModel> items;
  final int totalCount;
  final int pageNumber;
  final int pageSize;
  final int totalPages;

  const PagedCustomersResponse({
    required this.items,
    required this.totalCount,
    required this.pageNumber,
    required this.pageSize,
    required this.totalPages,
  });

  factory PagedCustomersResponse.fromJson(Map<String, dynamic> json) {
    return PagedCustomersResponse(
      items: (json["items"] as List<dynamic>?)
              ?.map((e) => CustomerModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      totalCount: (json["totalCount"] as num?)?.toInt() ?? 0,
      pageNumber: (json["pageNumber"] as num?)?.toInt() ?? 1,
      pageSize: (json["pageSize"] as num?)?.toInt() ?? 20,
      totalPages: (json["totalPages"] as num?)?.toInt() ?? 1,
    );
  }
}

