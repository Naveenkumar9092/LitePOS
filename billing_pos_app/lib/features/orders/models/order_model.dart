enum OrderTypeEnum {
  counterSale(1, "Counter Sale"),
  takeaway(2, "Takeaway");

  final int value;
  final String label;
  const OrderTypeEnum(this.value, this.label);

  static OrderTypeEnum fromValue(dynamic value) {
    if (value == 2 || value == "Takeaway" || value == "takeaway") {
      return OrderTypeEnum.takeaway;
    }
    return OrderTypeEnum.counterSale;
  }
}

enum OrderStatusEnum {
  newOrder(1, "New"),
  confirmed(2, "Confirmed"),
  preparing(3, "Preparing"),
  ready(4, "Ready"),
  completed(5, "Completed"),
  cancelled(6, "Cancelled");

  final int value;
  final String label;
  const OrderStatusEnum(this.value, this.label);

  static OrderStatusEnum fromValue(dynamic value) {
    if (value == 2 || value == "Confirmed" || value == "confirmed") return OrderStatusEnum.confirmed;
    if (value == 3 || value == "Preparing" || value == "preparing") return OrderStatusEnum.preparing;
    if (value == 4 || value == "Ready" || value == "ready") return OrderStatusEnum.ready;
    if (value == 5 || value == "Completed" || value == "completed") return OrderStatusEnum.completed;
    if (value == 6 || value == "Cancelled" || value == "cancelled") return OrderStatusEnum.cancelled;
    return OrderStatusEnum.newOrder;
  }
}

class OrderDetailModel {
  final int id;
  final int orderId;
  final int productId;
  final String productName;
  final double unitPrice;
  final int quantity;
  final double discountAmount;
  final double taxPercentage;
  final double taxAmount;
  final double lineTotal;

  OrderDetailModel({
    required this.id,
    required this.orderId,
    required this.productId,
    required this.productName,
    required this.unitPrice,
    required this.quantity,
    this.discountAmount = 0.0,
    this.taxPercentage = 0.0,
    this.taxAmount = 0.0,
    this.lineTotal = 0.0,
  });

  factory OrderDetailModel.fromJson(Map<String, dynamic> json) {
    return OrderDetailModel(
      id: (json["id"] as num?)?.toInt() ?? 0,
      orderId: (json["orderId"] as num?)?.toInt() ?? 0,
      productId: (json["productId"] as num?)?.toInt() ?? 0,
      productName: json["productNameSnapshot"] as String? ?? json["productName"] as String? ?? "",
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
      "id": id,
      "orderId": orderId,
      "productId": productId,
      "productNameSnapshot": productName,
      "unitPrice": unitPrice,
      "quantity": quantity,
      "discountAmount": discountAmount,
      "taxPercentage": taxPercentage,
      "taxAmount": taxAmount,
      "lineTotal": lineTotal,
    };
  }
}

class OrderModel {
  final int id;
  final String orderGuid;
  final String orderNumber;
  final int? customerId;
  final String? customerName;
  final String? customerMobile;
  final OrderTypeEnum orderType;
  final OrderStatusEnum orderStatus;
  final double subTotal;
  final double discountAmount;
  final double taxAmount;
  final double grandTotal;
  final String cashierUsername;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? createdBy;
  final String? updatedBy;
  final int? invoiceId;
  final String? invoiceNumber;
  final List<OrderDetailModel> details;

  OrderModel({
    required this.id,
    required this.orderGuid,
    required this.orderNumber,
    this.customerId,
    this.customerName,
    this.customerMobile,
    required this.orderType,
    required this.orderStatus,
    required this.subTotal,
    this.discountAmount = 0.0,
    this.taxAmount = 0.0,
    required this.grandTotal,
    this.cashierUsername = "",
    required this.createdAt,
    this.updatedAt,
    this.createdBy,
    this.updatedBy,
    this.invoiceId,
    this.invoiceNumber,
    this.details = const [],
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    var rawDetails = json["details"] as List<dynamic>? ?? [];
    return OrderModel(
      id: (json["id"] as num?)?.toInt() ?? (json["orderId"] as num?)?.toInt() ?? 0,
      orderGuid: json["orderGuid"] as String? ?? "",
      orderNumber: json["orderNumber"] as String? ?? "",
      customerId: (json["customerId"] as num?)?.toInt(),
      customerName: json["customerName"] as String?,
      customerMobile: json["customerMobile"] as String?,
      orderType: OrderTypeEnum.fromValue(json["orderType"]),
      orderStatus: OrderStatusEnum.fromValue(json["orderStatus"]),
      subTotal: (json["subTotal"] as num?)?.toDouble() ?? 0.0,
      discountAmount: (json["discountAmount"] as num?)?.toDouble() ?? 0.0,
      taxAmount: (json["taxAmount"] as num?)?.toDouble() ?? 0.0,
      grandTotal: (json["grandTotal"] as num?)?.toDouble() ?? 0.0,
      cashierUsername: json["cashierUsername"] as String? ?? json["createdBy"] as String? ?? "",
      createdAt: json["createdAtUtc"] != null
          ? DateTime.tryParse(json["createdAtUtc"].toString()) ?? DateTime.now()
          : (json["createdAtUTC"] != null
              ? DateTime.tryParse(json["createdAtUTC"].toString()) ?? DateTime.now()
              : DateTime.now()),
      updatedAt: json["updatedAtUtc"] != null
          ? DateTime.tryParse(json["updatedAtUtc"].toString())
          : (json["updatedAtUTC"] != null
              ? DateTime.tryParse(json["updatedAtUTC"].toString())
              : null),
      createdBy: json["createdBy"] as String?,
      updatedBy: json["updatedBy"] as String?,
      invoiceId: (json["invoiceId"] as num?)?.toInt(),
      invoiceNumber: json["invoiceNumber"] as String?,
      details: rawDetails.map((e) => OrderDetailModel.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "orderGuid": orderGuid,
      "orderNumber": orderNumber,
      "customerId": customerId,
      "customerName": customerName,
      "customerMobile": customerMobile,
      "orderType": orderType.value,
      "orderStatus": orderStatus.value,
      "subTotal": subTotal,
      "discountAmount": discountAmount,
      "taxAmount": taxAmount,
      "grandTotal": grandTotal,
      "cashierUsername": cashierUsername,
      "createdAtUtc": createdAt.toIso8601String(),
      "updatedAtUtc": updatedAt?.toIso8601String(),
      "createdBy": createdBy,
      "updatedBy": updatedBy,
      "invoiceId": invoiceId,
      "invoiceNumber": invoiceNumber,
      "details": details.map((d) => d.toJson()).toList(),
    };
  }

  OrderModel copyWith({
    int? id,
    String? orderGuid,
    String? orderNumber,
    int? customerId,
    String? customerName,
    String? customerMobile,
    OrderTypeEnum? orderType,
    OrderStatusEnum? orderStatus,
    double? subTotal,
    double? discountAmount,
    double? taxAmount,
    double? grandTotal,
    String? cashierUsername,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    String? updatedBy,
    int? invoiceId,
    String? invoiceNumber,
    List<OrderDetailModel>? details,
  }) {
    return OrderModel(
      id: id ?? this.id,
      orderGuid: orderGuid ?? this.orderGuid,
      orderNumber: orderNumber ?? this.orderNumber,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      customerMobile: customerMobile ?? this.customerMobile,
      orderType: orderType ?? this.orderType,
      orderStatus: orderStatus ?? this.orderStatus,
      subTotal: subTotal ?? this.subTotal,
      discountAmount: discountAmount ?? this.discountAmount,
      taxAmount: taxAmount ?? this.taxAmount,
      grandTotal: grandTotal ?? this.grandTotal,
      cashierUsername: cashierUsername ?? this.cashierUsername,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      updatedBy: updatedBy ?? this.updatedBy,
      invoiceId: invoiceId ?? this.invoiceId,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      details: details ?? this.details,
    );
  }
}

class CreateOrderItemRequest {
  final int productId;
  final String? productNameSnapshot;
  final double unitPrice;
  final int quantity;
  final double discountAmount;
  final double taxPercentage;

  CreateOrderItemRequest({
    required this.productId,
    this.productNameSnapshot,
    required this.unitPrice,
    this.quantity = 1,
    this.discountAmount = 0.0,
    this.taxPercentage = 0.0,
  });

  Map<String, dynamic> toJson() {
    return {
      "productId": productId,
      if (productNameSnapshot != null) "productNameSnapshot": productNameSnapshot,
      "unitPrice": unitPrice,
      "quantity": quantity,
      "discountAmount": discountAmount,
      "taxPercentage": taxPercentage,
    };
  }
}

class CreateOrderRequest {
  final int? customerId;
  final OrderTypeEnum orderType;
  final double discountAmount;
  final String? notes;
  final List<CreateOrderItemRequest> items;

  CreateOrderRequest({
    this.customerId,
    this.orderType = OrderTypeEnum.counterSale,
    this.discountAmount = 0.0,
    this.notes,
    required this.items,
  });

  Map<String, dynamic> toJson() {
    return {
      if (customerId != null) "customerId": customerId,
      "orderType": orderType.value,
      "discountAmount": discountAmount,
      if (notes != null && notes!.isNotEmpty) "notes": notes,
      "items": items.map((i) => i.toJson()).toList(),
    };
  }
}

class OrderFilterParams {
  final OrderStatusEnum? status;
  final OrderTypeEnum? type;
  final String? searchTerm;
  final DateTime? fromDate;
  final DateTime? toDate;
  final int page;
  final int pageSize;

  OrderFilterParams({
    this.status,
    this.type,
    this.searchTerm,
    this.fromDate,
    this.toDate,
    this.page = 1,
    this.pageSize = 20,
  });

  Map<String, dynamic> toQueryParams() {
    final Map<String, dynamic> params = {
      "page": page,
      "pageSize": pageSize,
    };
    if (status != null) params["status"] = status!.value;
    if (type != null) params["type"] = type!.value;
    if (searchTerm != null && searchTerm!.trim().isNotEmpty) {
      params["search"] = searchTerm!.trim();
    }
    if (fromDate != null) params["fromDate"] = fromDate!.toIso8601String();
    if (toDate != null) params["toDate"] = toDate!.toIso8601String();
    return params;
  }
}

class PagedOrdersResponse {
  final List<OrderModel> items;
  final int totalCount;
  final int pageNumber;
  final int pageSize;
  final int totalPages;

  PagedOrdersResponse({
    required this.items,
    required this.totalCount,
    required this.pageNumber,
    required this.pageSize,
    required this.totalPages,
  });

  factory PagedOrdersResponse.fromJson(Map<String, dynamic> json) {
    var rawItems = json["items"] as List<dynamic>? ?? [];
    return PagedOrdersResponse(
      items: rawItems.map((e) => OrderModel.fromJson(e as Map<String, dynamic>)).toList(),
      totalCount: (json["totalCount"] as num?)?.toInt() ?? 0,
      pageNumber: (json["pageNumber"] as num?)?.toInt() ?? 1,
      pageSize: (json["pageSize"] as num?)?.toInt() ?? 20,
      totalPages: (json["totalPages"] as num?)?.toInt() ?? 0,
    );
  }
}

