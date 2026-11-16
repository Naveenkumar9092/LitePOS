enum ReportDateRangeType {
  today,
  yesterday,
  thisWeek,
  thisMonth,
  custom,
}

class ReportFilterModel {
  final ReportDateRangeType rangeType;
  final DateTime fromDateUtc;
  final DateTime toDateUtc;
  final int? cashierId;
  final int? categoryId;

  const ReportFilterModel({
    required this.rangeType,
    required this.fromDateUtc,
    required this.toDateUtc,
    this.cashierId,
    this.categoryId,
  });

  factory ReportFilterModel.today() {
    final now = DateTime.now().toUtc();
    final from = DateTime.utc(now.year, now.month, now.day, 0, 0, 0);
    final to = DateTime.utc(now.year, now.month, now.day, 23, 59, 59, 999);
    return ReportFilterModel(
      rangeType: ReportDateRangeType.today,
      fromDateUtc: from,
      toDateUtc: to,
    );
  }

  factory ReportFilterModel.yesterday() {
    final now = DateTime.now().toUtc();
    final yest = now.subtract(const Duration(days: 1));
    final from = DateTime.utc(yest.year, yest.month, yest.day, 0, 0, 0);
    final to = DateTime.utc(yest.year, yest.month, yest.day, 23, 59, 59, 999);
    return ReportFilterModel(
      rangeType: ReportDateRangeType.yesterday,
      fromDateUtc: from,
      toDateUtc: to,
    );
  }

  factory ReportFilterModel.thisWeek() {
    final now = DateTime.now().toUtc();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final from = DateTime.utc(startOfWeek.year, startOfWeek.month, startOfWeek.day, 0, 0, 0);
    final to = DateTime.utc(now.year, now.month, now.day, 23, 59, 59, 999);
    return ReportFilterModel(
      rangeType: ReportDateRangeType.thisWeek,
      fromDateUtc: from,
      toDateUtc: to,
    );
  }

  factory ReportFilterModel.thisMonth() {
    final now = DateTime.now().toUtc();
    final from = DateTime.utc(now.year, now.month, 1, 0, 0, 0);
    final to = DateTime.utc(now.year, now.month, now.day, 23, 59, 59, 999);
    return ReportFilterModel(
      rangeType: ReportDateRangeType.thisMonth,
      fromDateUtc: from,
      toDateUtc: to,
    );
  }

  factory ReportFilterModel.custom(DateTime from, DateTime to) {
    return ReportFilterModel(
      rangeType: ReportDateRangeType.custom,
      fromDateUtc: from,
      toDateUtc: to,
    );
  }

  ReportFilterModel copyWith({
    ReportDateRangeType? rangeType,
    DateTime? fromDateUtc,
    DateTime? toDateUtc,
    int? cashierId,
    int? categoryId,
  }) {
    return ReportFilterModel(
      rangeType: rangeType ?? this.rangeType,
      fromDateUtc: fromDateUtc ?? this.fromDateUtc,
      toDateUtc: toDateUtc ?? this.toDateUtc,
      cashierId: cashierId ?? this.cashierId,
      categoryId: categoryId ?? this.categoryId,
    );
  }

  Map<String, dynamic> toQueryParams() {
    return {
      "fromDateUtc": fromDateUtc.toIso8601String(),
      "toDateUtc": toDateUtc.toIso8601String(),
      if (cashierId != null) "cashierId": cashierId,
      if (categoryId != null) "categoryId": categoryId,
    };
  }
}

class SalesReportSummaryModel {
  final DateTime fromDateUtc;
  final DateTime toDateUtc;
  final int totalInvoices;
  final int totalActiveInvoices;
  final int totalCancelledInvoices;
  final double grossSales;
  final double totalDiscount;
  final double netSales;
  final double totalTax;
  final double grandTotalSales;
  final double totalRefunds;
  final double netRevenue;
  final double totalCashCollected;
  final double totalUpiCollected;
  final double totalCardCollected;
  final double totalDueOutstanding;
  final double averageOrderValue;

  const SalesReportSummaryModel({
    required this.fromDateUtc,
    required this.toDateUtc,
    required this.totalInvoices,
    required this.totalActiveInvoices,
    required this.totalCancelledInvoices,
    required this.grossSales,
    required this.totalDiscount,
    required this.netSales,
    required this.totalTax,
    required this.grandTotalSales,
    required this.totalRefunds,
    required this.netRevenue,
    required this.totalCashCollected,
    required this.totalUpiCollected,
    required this.totalCardCollected,
    required this.totalDueOutstanding,
    required this.averageOrderValue,
  });

  factory SalesReportSummaryModel.fromJson(Map<String, dynamic> json) {
    return SalesReportSummaryModel(
      fromDateUtc: DateTime.tryParse(json["fromDateUtc"]?.toString() ?? "") ?? DateTime.now(),
      toDateUtc: DateTime.tryParse(json["toDateUtc"]?.toString() ?? "") ?? DateTime.now(),
      totalInvoices: (json["totalInvoices"] as num?)?.toInt() ?? 0,
      totalActiveInvoices: (json["totalActiveInvoices"] as num?)?.toInt() ?? 0,
      totalCancelledInvoices: (json["totalCancelledInvoices"] as num?)?.toInt() ?? 0,
      grossSales: (json["grossSales"] as num?)?.toDouble() ?? 0.0,
      totalDiscount: (json["totalDiscount"] as num?)?.toDouble() ?? 0.0,
      netSales: (json["netSales"] as num?)?.toDouble() ?? 0.0,
      totalTax: (json["totalTax"] as num?)?.toDouble() ?? 0.0,
      grandTotalSales: (json["grandTotalSales"] as num?)?.toDouble() ?? 0.0,
      totalRefunds: (json["totalRefunds"] as num?)?.toDouble() ?? 0.0,
      netRevenue: (json["netRevenue"] as num?)?.toDouble() ?? 0.0,
      totalCashCollected: (json["totalCashCollected"] as num?)?.toDouble() ?? 0.0,
      totalUpiCollected: (json["totalUpiCollected"] as num?)?.toDouble() ?? 0.0,
      totalCardCollected: (json["totalCardCollected"] as num?)?.toDouble() ?? 0.0,
      totalDueOutstanding: (json["totalDueOutstanding"] as num?)?.toDouble() ?? 0.0,
      averageOrderValue: (json["averageOrderValue"] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class DailySalesModel {
  final DateTime date;
  final int invoiceCount;
  final double grossSales;
  final double discountAmount;
  final double taxAmount;
  final double netSales;
  final double cashAmount;
  final double upiAmount;
  final double cardAmount;

  const DailySalesModel({
    required this.date,
    required this.invoiceCount,
    required this.grossSales,
    required this.discountAmount,
    required this.taxAmount,
    required this.netSales,
    required this.cashAmount,
    required this.upiAmount,
    required this.cardAmount,
  });

  factory DailySalesModel.fromJson(Map<String, dynamic> json) {
    return DailySalesModel(
      date: DateTime.tryParse(json["date"]?.toString() ?? "") ?? DateTime.now(),
      invoiceCount: (json["invoiceCount"] as num?)?.toInt() ?? 0,
      grossSales: (json["grossSales"] as num?)?.toDouble() ?? 0.0,
      discountAmount: (json["discountAmount"] as num?)?.toDouble() ?? 0.0,
      taxAmount: (json["taxAmount"] as num?)?.toDouble() ?? 0.0,
      netSales: (json["netSales"] as num?)?.toDouble() ?? 0.0,
      cashAmount: (json["cashAmount"] as num?)?.toDouble() ?? 0.0,
      upiAmount: (json["upiAmount"] as num?)?.toDouble() ?? 0.0,
      cardAmount: (json["cardAmount"] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class ProductSalesReportModel {
  final int productId;
  final String productName;
  final String categoryName;
  final int quantitySold;
  final double totalRevenue;
  final double totalTax;
  final double percentageOfSales;

  const ProductSalesReportModel({
    required this.productId,
    required this.productName,
    required this.categoryName,
    required this.quantitySold,
    required this.totalRevenue,
    required this.totalTax,
    required this.percentageOfSales,
  });

  factory ProductSalesReportModel.fromJson(Map<String, dynamic> json) {
    return ProductSalesReportModel(
      productId: (json["productId"] as num?)?.toInt() ?? 0,
      productName: json["productName"] as String? ?? "Unknown",
      categoryName: json["categoryName"] as String? ?? "General",
      quantitySold: (json["quantitySold"] as num?)?.toInt() ?? 0,
      totalRevenue: (json["totalRevenue"] as num?)?.toDouble() ?? 0.0,
      totalTax: (json["totalTax"] as num?)?.toDouble() ?? 0.0,
      percentageOfSales: (json["percentageOfSales"] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class CategorySalesReportModel {
  final int categoryId;
  final String categoryName;
  final int totalQuantitySold;
  final double totalRevenue;
  final double percentageOfSales;

  const CategorySalesReportModel({
    required this.categoryId,
    required this.categoryName,
    required this.totalQuantitySold,
    required this.totalRevenue,
    required this.percentageOfSales,
  });

  factory CategorySalesReportModel.fromJson(Map<String, dynamic> json) {
    return CategorySalesReportModel(
      categoryId: (json["categoryId"] as num?)?.toInt() ?? 0,
      categoryName: json["categoryName"] as String? ?? "General",
      totalQuantitySold: (json["totalQuantitySold"] as num?)?.toInt() ?? 0,
      totalRevenue: (json["totalRevenue"] as num?)?.toDouble() ?? 0.0,
      percentageOfSales: (json["percentageOfSales"] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class CashierPerformanceReportModel {
  final int cashierId;
  final String cashierName;
  final String username;
  final int invoicesCount;
  final double totalSales;
  final double cashCollected;
  final double digitalCollected;
  final double refundsHandled;

  const CashierPerformanceReportModel({
    required this.cashierId,
    required this.cashierName,
    required this.username,
    required this.invoicesCount,
    required this.totalSales,
    required this.cashCollected,
    required this.digitalCollected,
    required this.refundsHandled,
  });

  factory CashierPerformanceReportModel.fromJson(Map<String, dynamic> json) {
    return CashierPerformanceReportModel(
      cashierId: (json["cashierId"] as num?)?.toInt() ?? 0,
      cashierName: json["cashierName"] as String? ?? "Cashier",
      username: json["username"] as String? ?? "",
      invoicesCount: (json["invoicesCount"] as num?)?.toInt() ?? 0,
      totalSales: (json["totalSales"] as num?)?.toDouble() ?? 0.0,
      cashCollected: (json["cashCollected"] as num?)?.toDouble() ?? 0.0,
      digitalCollected: (json["digitalCollected"] as num?)?.toDouble() ?? 0.0,
      refundsHandled: (json["refundsHandled"] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class GstSlabSummaryModel {
  final double taxRate;
  final double taxableAmount;
  final double cgstAmount;
  final double sgstAmount;
  final double totalTax;

  const GstSlabSummaryModel({
    required this.taxRate,
    required this.taxableAmount,
    required this.cgstAmount,
    required this.sgstAmount,
    required this.totalTax,
  });

  factory GstSlabSummaryModel.fromJson(Map<String, dynamic> json) {
    return GstSlabSummaryModel(
      taxRate: (json["taxRate"] as num?)?.toDouble() ?? 0.0,
      taxableAmount: (json["taxableAmount"] as num?)?.toDouble() ?? 0.0,
      cgstAmount: (json["cgstAmount"] as num?)?.toDouble() ?? 0.0,
      sgstAmount: (json["sgstAmount"] as num?)?.toDouble() ?? 0.0,
      totalTax: (json["totalTax"] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class HsnSalesSummaryModel {
  final String hsnCode;
  final String description;
  final int totalQuantity;
  final double taxableAmount;
  final double totalTax;
  final double totalValue;

  const HsnSalesSummaryModel({
    required this.hsnCode,
    required this.description,
    required this.totalQuantity,
    required this.taxableAmount,
    required this.totalTax,
    required this.totalValue,
  });

  factory HsnSalesSummaryModel.fromJson(Map<String, dynamic> json) {
    return HsnSalesSummaryModel(
      hsnCode: json["hsnCode"] as String? ?? "",
      description: json["description"] as String? ?? "",
      totalQuantity: (json["totalQuantity"] as num?)?.toInt() ?? 0,
      taxableAmount: (json["taxableAmount"] as num?)?.toDouble() ?? 0.0,
      totalTax: (json["totalTax"] as num?)?.toDouble() ?? 0.0,
      totalValue: (json["totalValue"] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class GstSummaryReportModel {
  final List<GstSlabSummaryModel> slabs;
  final double totalTaxableAmount;
  final double totalCgst;
  final double totalSgst;
  final double totalGst;
  final List<HsnSalesSummaryModel> hsnSummary;

  const GstSummaryReportModel({
    required this.slabs,
    required this.totalTaxableAmount,
    required this.totalCgst,
    required this.totalSgst,
    required this.totalGst,
    required this.hsnSummary,
  });

  factory GstSummaryReportModel.fromJson(Map<String, dynamic> json) {
    return GstSummaryReportModel(
      slabs: (json["slabs"] as List<dynamic>?)
              ?.map((e) => GstSlabSummaryModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      totalTaxableAmount: (json["totalTaxableAmount"] as num?)?.toDouble() ?? 0.0,
      totalCgst: (json["totalCgst"] as num?)?.toDouble() ?? 0.0,
      totalSgst: (json["totalSgst"] as num?)?.toDouble() ?? 0.0,
      totalGst: (json["totalGst"] as num?)?.toDouble() ?? 0.0,
      hsnSummary: (json["hsnSummary"] as List<dynamic>?)
              ?.map((e) => HsnSalesSummaryModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class HourlySalesModel {
  final int hour;
  final String timeSlot;
  final int orderCount;
  final double totalSales;

  const HourlySalesModel({
    required this.hour,
    required this.timeSlot,
    required this.orderCount,
    required this.totalSales,
  });

  factory HourlySalesModel.fromJson(Map<String, dynamic> json) {
    return HourlySalesModel(
      hour: (json["hour"] as num?)?.toInt() ?? 0,
      timeSlot: json["timeSlot"] as String? ?? "",
      orderCount: (json["orderCount"] as num?)?.toInt() ?? 0,
      totalSales: (json["totalSales"] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class PaymentModeBreakdownModel {
  final String paymentMode;
  final int transactionCount;
  final double totalAmount;
  final double percentage;

  const PaymentModeBreakdownModel({
    required this.paymentMode,
    required this.transactionCount,
    required this.totalAmount,
    required this.percentage,
  });

  factory PaymentModeBreakdownModel.fromJson(Map<String, dynamic> json) {
    return PaymentModeBreakdownModel(
      paymentMode: json["paymentMode"] as String? ?? "",
      transactionCount: (json["transactionCount"] as num?)?.toInt() ?? 0,
      totalAmount: (json["totalAmount"] as num?)?.toDouble() ?? 0.0,
      percentage: (json["percentage"] as num?)?.toDouble() ?? 0.0,
    );
  }
}

