class ShopInfoModel {
  final int companyId;
  final String companyName;
  final int shopId;
  final String shopName;
  final String businessType;
  final String currencyCode;
  final String contactNumber;
  final String email;

  ShopInfoModel({
    required this.companyId,
    required this.companyName,
    required this.shopId,
    required this.shopName,
    required this.businessType,
    required this.currencyCode,
    required this.contactNumber,
    required this.email,
  });

  factory ShopInfoModel.fromJson(Map<String, dynamic> json) {
    return ShopInfoModel(
      companyId: json["companyId"] ?? 0,
      companyName: json["companyName"] ?? "",
      shopId: json["shopId"] ?? 0,
      shopName: json["shopName"] ?? "",
      businessType: json["businessType"] ?? "",
      currencyCode: json["currencyCode"] ?? "INR",
      contactNumber: json["contactNumber"] ?? "",
      email: json["email"] ?? "",
    );
  }

  Map<String, dynamic> toJson() => {
    "companyId": companyId,
    "companyName": companyName,
    "shopId": shopId,
    "shopName": shopName,
    "businessType": businessType,
    "currencyCode": currencyCode,
    "contactNumber": contactNumber,
    "email": email,
  };
}

class AppHealthModel {
  final String status;
  final String databaseConnection;
  final String localDbStatus;
  final int pendingSyncRecords;
  final String serverTimeUtc;

  AppHealthModel({
    required this.status,
    required this.databaseConnection,
    required this.localDbStatus,
    required this.pendingSyncRecords,
    required this.serverTimeUtc,
  });

  factory AppHealthModel.fromJson(Map<String, dynamic> json) {
    return AppHealthModel(
      status: json["status"] ?? "Healthy",
      databaseConnection: json["databaseConnection"] ?? "Connected",
      localDbStatus: json["localDbStatus"] ?? "Ready",
      pendingSyncRecords: json["pendingSyncRecords"] ?? 0,
      serverTimeUtc: json["serverTimeUtc"] ?? "",
    );
  }

  Map<String, dynamic> toJson() => {
    "status": status,
    "databaseConnection": databaseConnection,
    "localDbStatus": localDbStatus,
    "pendingSyncRecords": pendingSyncRecords,
    "serverTimeUtc": serverTimeUtc,
  };
}

class SalesSummaryModel {
  final double totalSales;
  final int totalInvoices;
  final double averageBillValue;
  final double totalDiscount;
  final double totalTax;
  final double netSales;

  SalesSummaryModel({
    required this.totalSales,
    required this.totalInvoices,
    required this.averageBillValue,
    required this.totalDiscount,
    required this.totalTax,
    required this.netSales,
  });

  factory SalesSummaryModel.fromJson(Map<String, dynamic> json) {
    return SalesSummaryModel(
      totalSales: (json["totalSales"] as num?)?.toDouble() ?? 0.0,
      totalInvoices: json["totalInvoices"] ?? 0,
      averageBillValue: (json["averageBillValue"] as num?)?.toDouble() ?? 0.0,
      totalDiscount: (json["totalDiscount"] as num?)?.toDouble() ?? 0.0,
      totalTax: (json["totalTax"] as num?)?.toDouble() ?? 0.0,
      netSales: (json["netSales"] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() => {
    "totalSales": totalSales,
    "totalInvoices": totalInvoices,
    "averageBillValue": averageBillValue,
    "totalDiscount": totalDiscount,
    "totalTax": totalTax,
    "netSales": netSales,
  };
}

class PaymentSummaryModel {
  final double cashTotal;
  final double upiTotal;
  final double cardTotal;
  final double otherTotal;
  final double grandTotal;
  final int cashTransactions;
  final int upiTransactions;
  final int cardTransactions;

  PaymentSummaryModel({
    required this.cashTotal,
    required this.upiTotal,
    required this.cardTotal,
    required this.otherTotal,
    required this.grandTotal,
    required this.cashTransactions,
    required this.upiTransactions,
    required this.cardTransactions,
  });

  factory PaymentSummaryModel.fromJson(Map<String, dynamic> json) {
    return PaymentSummaryModel(
      cashTotal: (json["cashTotal"] as num?)?.toDouble() ?? 0.0,
      upiTotal: (json["upiTotal"] as num?)?.toDouble() ?? 0.0,
      cardTotal: (json["cardTotal"] as num?)?.toDouble() ?? 0.0,
      otherTotal: (json["otherTotal"] as num?)?.toDouble() ?? 0.0,
      grandTotal: (json["grandTotal"] as num?)?.toDouble() ?? 0.0,
      cashTransactions: json["cashTransactions"] ?? 0,
      upiTransactions: json["upiTransactions"] ?? 0,
      cardTransactions: json["cardTransactions"] ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    "cashTotal": cashTotal,
    "upiTotal": upiTotal,
    "cardTotal": cardTotal,
    "otherTotal": otherTotal,
    "grandTotal": grandTotal,
    "cashTransactions": cashTransactions,
    "upiTransactions": upiTransactions,
    "cardTransactions": cardTransactions,
  };
}

class SalesGraphPointModel {
  final String label;
  final double amount;
  final int invoiceCount;

  SalesGraphPointModel({
    required this.label,
    required this.amount,
    required this.invoiceCount,
  });

  factory SalesGraphPointModel.fromJson(Map<String, dynamic> json) {
    return SalesGraphPointModel(
      label: json["label"] ?? "",
      amount: (json["amount"] as num?)?.toDouble() ?? 0.0,
      invoiceCount: json["invoiceCount"] ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    "label": label,
    "amount": amount,
    "invoiceCount": invoiceCount,
  };
}

class CashierSalesModel {
  final int cashierId;
  final String cashierName;
  final int invoiceCount;
  final double totalSales;
  final double cashCollected;
  final double upiCollected;
  final double cardCollected;

  CashierSalesModel({
    required this.cashierId,
    required this.cashierName,
    required this.invoiceCount,
    required this.totalSales,
    required this.cashCollected,
    required this.upiCollected,
    required this.cardCollected,
  });

  factory CashierSalesModel.fromJson(Map<String, dynamic> json) {
    return CashierSalesModel(
      cashierId: json["cashierId"] ?? 0,
      cashierName: json["cashierName"] ?? "",
      invoiceCount: json["invoiceCount"] ?? 0,
      totalSales: (json["totalSales"] as num?)?.toDouble() ?? 0.0,
      cashCollected: (json["cashCollected"] as num?)?.toDouble() ?? 0.0,
      upiCollected: (json["upiCollected"] as num?)?.toDouble() ?? 0.0,
      cardCollected: (json["cardCollected"] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() => {
    "cashierId": cashierId,
    "cashierName": cashierName,
    "invoiceCount": invoiceCount,
    "totalSales": totalSales,
    "cashCollected": cashCollected,
    "upiCollected": upiCollected,
    "cardCollected": cardCollected,
  };
}

class RecentTransactionModel {
  final int invoiceId;
  final String invoiceNumber;
  final String customerName;
  final String cashierName;
  final double totalAmount;
  final String paymentMode;
  final String invoiceStatus;
  final String createdAt;

  RecentTransactionModel({
    required this.invoiceId,
    required this.invoiceNumber,
    required this.customerName,
    required this.cashierName,
    required this.totalAmount,
    required this.paymentMode,
    required this.invoiceStatus,
    required this.createdAt,
  });

  factory RecentTransactionModel.fromJson(Map<String, dynamic> json) {
    final rawAmount = json["totalAmount"] ?? json["amount"] ?? json["grandTotal"];
    final rawCreatedAt = json["createdAt"] ?? json["invoiceDateUtc"] ?? json["createdAtUtc"] ?? "";
    final rawStatus = json["invoiceStatus"] ?? json["paymentStatus"] ?? "Active";

    return RecentTransactionModel(
      invoiceId: (json["invoiceId"] ?? json["id"] as num?)?.toInt() ?? 0,
      invoiceNumber: json["invoiceNumber"] ?? "",
      customerName: json["customerName"] ?? "Walk-in Guest",
      cashierName: json["cashierName"] ?? "",
      totalAmount: (rawAmount as num?)?.toDouble() ?? 0.0,
      paymentMode: json["paymentMode"] ?? "Cash",
      invoiceStatus: rawStatus.toString(),
      createdAt: rawCreatedAt.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    "invoiceId": invoiceId,
    "invoiceNumber": invoiceNumber,
    "customerName": customerName,
    "cashierName": cashierName,
    "totalAmount": totalAmount,
    "paymentMode": paymentMode,
    "invoiceStatus": invoiceStatus,
    "createdAt": createdAt,
  };
}

class ShiftSummaryModel {
  final String shiftDate;
  final double openingFloat;
  final double cashCollected;
  final double cashOnHand;
  final int billsIssued;

  ShiftSummaryModel({
    required this.shiftDate,
    required this.openingFloat,
    required this.cashCollected,
    required this.cashOnHand,
    required this.billsIssued,
  });

  factory ShiftSummaryModel.fromJson(Map<String, dynamic> json) {
    return ShiftSummaryModel(
      shiftDate: json["shiftDate"] ?? "",
      openingFloat: (json["openingFloat"] as num?)?.toDouble() ?? 0.0,
      cashCollected: (json["cashCollected"] as num?)?.toDouble() ?? 0.0,
      cashOnHand: (json["cashOnHand"] as num?)?.toDouble() ?? 0.0,
      billsIssued: json["billsIssued"] ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    "shiftDate": shiftDate,
    "openingFloat": openingFloat,
    "cashCollected": cashCollected,
    "cashOnHand": cashOnHand,
    "billsIssued": billsIssued,
  };
}

class SAdminDashboardModel {
  final ShopInfoModel shop;
  final int totalUsers;
  final int activeUsers;
  final int registeredDevices;
  final int offlineDevices;
  final int syncFailures;
  final int totalInvoicesAllTime;
  final double totalSalesAllTime;
  final AppHealthModel appHealth;
  final List<String> recentAuditActivities;

  SAdminDashboardModel({
    required this.shop,
    required this.totalUsers,
    required this.activeUsers,
    required this.registeredDevices,
    required this.offlineDevices,
    required this.syncFailures,
    required this.totalInvoicesAllTime,
    required this.totalSalesAllTime,
    required this.appHealth,
    required this.recentAuditActivities,
  });

  factory SAdminDashboardModel.fromJson(Map<String, dynamic> json) {
    final auditLogs = json["recentAuditActivities"] ?? json["recentAuditLogs"];
    return SAdminDashboardModel(
      shop: ShopInfoModel.fromJson(json["shop"] ?? json["shopInfo"] ?? {}),
      totalUsers: json["totalUsers"] ?? 0,
      activeUsers: json["activeUsers"] ?? 0,
      registeredDevices: json["registeredDevices"] ?? 0,
      offlineDevices: json["offlineDevices"] ?? 0,
      syncFailures: json["syncFailures"] ?? 0,
      totalInvoicesAllTime: json["totalInvoicesAllTime"] ?? json["totalInvoices"] ?? 0,
      totalSalesAllTime: (json["totalSalesAllTime"] ?? json["totalSales"] as num?)?.toDouble() ?? 0.0,
      appHealth: AppHealthModel.fromJson(json["appHealth"] ?? {}),
      recentAuditActivities: (auditLogs as List<dynamic>?)
              ?.map((e) => e is Map ? (e["activityDescription"] ?? e["action"] ?? e.toString()).toString() : e.toString())
              .toList() ??
          [],
    );
  }
}

class AdminDashboardModel {
  final SalesSummaryModel salesSummary;
  final PaymentSummaryModel paymentSummary;
  final int totalCustomers;
  final int completedOrders;
  final int cancelledOrders;
  final List<SalesGraphPointModel> dailySalesTrend;
  final List<SalesGraphPointModel> monthlySalesTrend;
  final List<CashierSalesModel> cashierBreakdown;
  final List<RecentTransactionModel> recentInvoices;

  AdminDashboardModel({
    required this.salesSummary,
    required this.paymentSummary,
    required this.totalCustomers,
    required this.completedOrders,
    required this.cancelledOrders,
    required this.dailySalesTrend,
    required this.monthlySalesTrend,
    required this.cashierBreakdown,
    required this.recentInvoices,
  });

  factory AdminDashboardModel.fromJson(Map<String, dynamic> json) {
    // Handle both nested salesSummary/paymentSummary and flat fields from .NET AdminDashboardDto
    final salesSummary = json["salesSummary"] != null
        ? SalesSummaryModel.fromJson(json["salesSummary"] as Map<String, dynamic>)
        : SalesSummaryModel(
            totalSales: (json["todaySales"] as num?)?.toDouble() ?? 0.0,
            totalInvoices: (json["todayInvoices"] as num?)?.toInt() ?? 0,
            averageBillValue: ((json["todayInvoices"] as num?)?.toInt() ?? 0) > 0
                ? ((json["todaySales"] as num?)?.toDouble() ?? 0.0) /
                    ((json["todayInvoices"] as num?)?.toInt() ?? 1)
                : 0.0,
            totalDiscount: (json["totalDiscount"] as num?)?.toDouble() ?? 0.0,
            totalTax: (json["totalTax"] as num?)?.toDouble() ?? 0.0,
            netSales: (json["todaySales"] as num?)?.toDouble() ?? 0.0,
          );

    final paymentSummary = json["paymentSummary"] != null
        ? PaymentSummaryModel.fromJson(json["paymentSummary"] as Map<String, dynamic>)
        : PaymentSummaryModel(
            cashTotal: (json["cashSales"] as num?)?.toDouble() ?? 0.0,
            upiTotal: (json["upiSales"] as num?)?.toDouble() ?? 0.0,
            cardTotal: (json["cardSales"] as num?)?.toDouble() ?? 0.0,
            otherTotal: 0.0,
            grandTotal: ((json["cashSales"] as num?)?.toDouble() ?? 0.0) +
                ((json["upiSales"] as num?)?.toDouble() ?? 0.0) +
                ((json["cardSales"] as num?)?.toDouble() ?? 0.0),
            cashTransactions: 0,
            upiTransactions: 0,
            cardTransactions: 0,
          );

    final dailyList = (json["dailySalesTrend"] ?? json["dailySalesGraph"]) as List<dynamic>?;
    final monthlyList = (json["monthlySalesTrend"] ?? json["monthlySalesGraph"]) as List<dynamic>?;
    final cashierList = (json["cashierBreakdown"] ?? json["cashierWiseSales"]) as List<dynamic>?;
    final invoiceList = (json["recentInvoices"] ?? json["recentTransactions"]) as List<dynamic>?;

    return AdminDashboardModel(
      salesSummary: salesSummary,
      paymentSummary: paymentSummary,
      totalCustomers: json["totalCustomers"] ?? 0,
      completedOrders: json["completedOrders"] ?? 0,
      cancelledOrders: json["cancelledOrders"] ?? 0,
      dailySalesTrend: dailyList
              ?.map((e) => SalesGraphPointModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      monthlySalesTrend: monthlyList
              ?.map((e) => SalesGraphPointModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      cashierBreakdown: cashierList
              ?.map((e) => CashierSalesModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      recentInvoices: invoiceList
              ?.map((e) => RecentTransactionModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class CashierDashboardModel {
  final int cashierId;
  final String cashierName;
  final double todaySales;
  final int todayInvoices;
  final double cashCollected;
  final double upiCollected;
  final double cardCollected;
  final int heldBillsCount;
  final ShiftSummaryModel shiftSummary;
  final List<RecentTransactionModel> recentTransactions;

  CashierDashboardModel({
    required this.cashierId,
    required this.cashierName,
    required this.todaySales,
    required this.todayInvoices,
    required this.cashCollected,
    required this.upiCollected,
    required this.cardCollected,
    required this.heldBillsCount,
    required this.shiftSummary,
    required this.recentTransactions,
  });

  factory CashierDashboardModel.fromJson(Map<String, dynamic> json) {
    return CashierDashboardModel(
      cashierId: json["cashierId"] ?? 0,
      cashierName: json["cashierName"] ?? "",
      todaySales: (json["todaySales"] as num?)?.toDouble() ?? 0.0,
      todayInvoices: json["todayInvoices"] ?? 0,
      cashCollected: (json["cashCollected"] as num?)?.toDouble() ?? 0.0,
      upiCollected: (json["upiCollected"] as num?)?.toDouble() ?? 0.0,
      cardCollected: (json["cardCollected"] as num?)?.toDouble() ?? 0.0,
      heldBillsCount: json["heldBillsCount"] ?? 0,
      shiftSummary: ShiftSummaryModel.fromJson(json["shiftSummary"] ?? {}),
      recentTransactions: (json["recentTransactions"] as List<dynamic>?)
              ?.map((e) => RecentTransactionModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

