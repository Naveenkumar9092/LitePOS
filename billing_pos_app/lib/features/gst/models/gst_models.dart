class TaxModel {
  final int id;
  final String taxName;
  final double ratePercentage;
  final double cgstPercentage;
  final double sgstPercentage;
  final double igstPercentage;
  final bool isActive;
  final bool isDefault;
  final bool isTaxInclusiveDefault;

  const TaxModel({
    required this.id,
    required this.taxName,
    required this.ratePercentage,
    required this.cgstPercentage,
    required this.sgstPercentage,
    required this.igstPercentage,
    required this.isActive,
    required this.isDefault,
    required this.isTaxInclusiveDefault,
  });

  factory TaxModel.fromJson(Map<String, dynamic> json) {
    return TaxModel(
      id: (json["id"] as num).toInt(),
      taxName: json["taxName"]?.toString() ?? "",
      ratePercentage: (json["ratePercentage"] as num?)?.toDouble() ?? 0.0,
      cgstPercentage: (json["cgstPercentage"] as num?)?.toDouble() ?? 0.0,
      sgstPercentage: (json["sgstPercentage"] as num?)?.toDouble() ?? 0.0,
      igstPercentage: (json["igstPercentage"] as num?)?.toDouble() ?? 0.0,
      isActive: json["isActive"] as bool? ?? true,
      isDefault: json["isDefault"] as bool? ?? false,
      isTaxInclusiveDefault: json["isTaxInclusiveDefault"] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
    "id": id,
    "taxName": taxName,
    "ratePercentage": ratePercentage,
    "cgstPercentage": cgstPercentage,
    "sgstPercentage": sgstPercentage,
    "igstPercentage": igstPercentage,
    "isActive": isActive,
    "isDefault": isDefault,
    "isTaxInclusiveDefault": isTaxInclusiveDefault,
  };

  Map<String, dynamic> toSqlite() => {
    "TaxId": id,
    "TaxName": taxName,
    "RatePercentage": ratePercentage,
    "CgstPercentage": cgstPercentage,
    "SgstPercentage": sgstPercentage,
    "IgstPercentage": igstPercentage,
    "IsActive": isActive ? 1 : 0,
    "IsDefault": isDefault ? 1 : 0,
    "IsTaxInclusiveDefault": isTaxInclusiveDefault ? 1 : 0,
  };

  factory TaxModel.fromSqlite(Map<String, dynamic> map) {
    return TaxModel(
      id: (map["TaxId"] as num).toInt(),
      taxName: map["TaxName"]?.toString() ?? "",
      ratePercentage: (map["RatePercentage"] as num?)?.toDouble() ?? 0.0,
      cgstPercentage: (map["CgstPercentage"] as num?)?.toDouble() ?? 0.0,
      sgstPercentage: (map["SgstPercentage"] as num?)?.toDouble() ?? 0.0,
      igstPercentage: (map["IgstPercentage"] as num?)?.toDouble() ?? 0.0,
      isActive: (map["IsActive"] as num?) == 1,
      isDefault: (map["IsDefault"] as num?) == 1,
      isTaxInclusiveDefault: (map["IsTaxInclusiveDefault"] as num?) == 1,
    );
  }
}

class HsnSacModel {
  final int id;
  final String code;
  final String description;
  final String type;
  final double defaultGstRate;
  final bool isActive;

  const HsnSacModel({
    required this.id,
    required this.code,
    required this.description,
    required this.type,
    required this.defaultGstRate,
    required this.isActive,
  });

  factory HsnSacModel.fromJson(Map<String, dynamic> json) {
    return HsnSacModel(
      id: (json["id"] as num).toInt(),
      code: json["code"]?.toString() ?? "",
      description: json["description"]?.toString() ?? "",
      type: json["type"]?.toString() ?? "HSN",
      defaultGstRate: (json["defaultGstRate"] as num?)?.toDouble() ?? 5.0,
      isActive: json["isActive"] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
    "id": id,
    "code": code,
    "description": description,
    "type": type,
    "defaultGstRate": defaultGstRate,
    "isActive": isActive,
  };

  Map<String, dynamic> toSqlite() => {
    "HsnId": id,
    "Code": code,
    "Description": description,
    "Type": type,
    "DefaultGstRate": defaultGstRate,
    "IsActive": isActive ? 1 : 0,
  };

  factory HsnSacModel.fromSqlite(Map<String, dynamic> map) {
    return HsnSacModel(
      id: (map["HsnId"] as num).toInt(),
      code: map["Code"]?.toString() ?? "",
      description: map["Description"]?.toString() ?? "",
      type: map["Type"]?.toString() ?? "HSN",
      defaultGstRate: (map["DefaultGstRate"] as num?)?.toDouble() ?? 5.0,
      isActive: (map["IsActive"] as num?) == 1,
    );
  }
}

class GstConfigurationModel {
  final int id;
  final String gstin;
  final String legalName;
  final String tradeName;
  final String stateName;
  final String stateCode;
  final bool isCompositionScheme;
  final bool defaultPricingIsTaxInclusive;
  final String? invoiceTermsAndConditions;
  final String? invoiceHeader;
  final String? invoiceFooter;
  final bool showHsnSummaryOnReceipt;
  final bool showTaxBreakupOnReceipt;

  const GstConfigurationModel({
    required this.id,
    required this.gstin,
    required this.legalName,
    required this.tradeName,
    required this.stateName,
    required this.stateCode,
    required this.isCompositionScheme,
    required this.defaultPricingIsTaxInclusive,
    this.invoiceTermsAndConditions,
    this.invoiceHeader,
    this.invoiceFooter,
    required this.showHsnSummaryOnReceipt,
    required this.showTaxBreakupOnReceipt,
  });

  factory GstConfigurationModel.fromJson(Map<String, dynamic> json) {
    return GstConfigurationModel(
      id: (json["id"] as num).toInt(),
      gstin: json["gstin"]?.toString() ?? "",
      legalName: json["legalName"]?.toString() ?? "",
      tradeName: json["tradeName"]?.toString() ?? "",
      stateName: json["stateName"]?.toString() ?? "",
      stateCode: json["stateCode"]?.toString() ?? "",
      isCompositionScheme: json["isCompositionScheme"] as bool? ?? false,
      defaultPricingIsTaxInclusive: json["defaultPricingIsTaxInclusive"] as bool? ?? true,
      invoiceTermsAndConditions: json["invoiceTermsAndConditions"]?.toString(),
      invoiceHeader: json["invoiceHeader"]?.toString(),
      invoiceFooter: json["invoiceFooter"]?.toString(),
      showHsnSummaryOnReceipt: json["showHsnSummaryOnReceipt"] as bool? ?? true,
      showTaxBreakupOnReceipt: json["showTaxBreakupOnReceipt"] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
    "id": id,
    "gstin": gstin,
    "legalName": legalName,
    "tradeName": tradeName,
    "stateName": stateName,
    "stateCode": stateCode,
    "isCompositionScheme": isCompositionScheme,
    "defaultPricingIsTaxInclusive": defaultPricingIsTaxInclusive,
    "invoiceTermsAndConditions": invoiceTermsAndConditions,
    "invoiceHeader": invoiceHeader,
    "invoiceFooter": invoiceFooter,
    "showHsnSummaryOnReceipt": showHsnSummaryOnReceipt,
    "showTaxBreakupOnReceipt": showTaxBreakupOnReceipt,
  };
}

class CreditNoteItemModel {
  final int productId;
  final String productName;
  final String? hsnCode;
  final int quantity;
  final double unitPrice;
  final double taxPercentage;
  final double taxAmount;
  final double lineTotal;
  final String? reason;

  const CreditNoteItemModel({
    required this.productId,
    required this.productName,
    this.hsnCode,
    required this.quantity,
    required this.unitPrice,
    required this.taxPercentage,
    required this.taxAmount,
    required this.lineTotal,
    this.reason,
  });

  factory CreditNoteItemModel.fromJson(Map<String, dynamic> json) {
    return CreditNoteItemModel(
      productId: (json["productId"] as num).toInt(),
      productName: json["productName"]?.toString() ?? "",
      hsnCode: json["hsnCode"]?.toString(),
      quantity: (json["quantity"] as num?)?.toInt() ?? 1,
      unitPrice: (json["unitPrice"] as num?)?.toDouble() ?? 0.0,
      taxPercentage: (json["taxPercentage"] as num?)?.toDouble() ?? 0.0,
      taxAmount: (json["taxAmount"] as num?)?.toDouble() ?? 0.0,
      lineTotal: (json["lineTotal"] as num?)?.toDouble() ?? 0.0,
      reason: json["reason"]?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    "productId": productId,
    "productName": productName,
    "hsnCode": hsnCode,
    "quantity": quantity,
    "unitPrice": unitPrice,
    "taxPercentage": taxPercentage,
    "taxAmount": taxAmount,
    "lineTotal": lineTotal,
    "reason": reason,
  };
}

class CreditNoteModel {
  final int id;
  final String creditNoteGuid;
  final String creditNoteNumber;
  final int invoiceId;
  final String invoiceNumber;
  final int? customerId;
  final String? customerName;
  final String? customerGstin;
  final DateTime creditNoteDateUtc;
  final String reason;
  final String noteType;
  final double taxableAmount;
  final double cgstAmount;
  final double sgstAmount;
  final double igstAmount;
  final double totalTaxAmount;
  final double grandTotal;
  final String status;
  final List<CreditNoteItemModel> items;

  const CreditNoteModel({
    required this.id,
    required this.creditNoteGuid,
    required this.creditNoteNumber,
    required this.invoiceId,
    required this.invoiceNumber,
    this.customerId,
    this.customerName,
    this.customerGstin,
    required this.creditNoteDateUtc,
    required this.reason,
    required this.noteType,
    required this.taxableAmount,
    required this.cgstAmount,
    required this.sgstAmount,
    required this.igstAmount,
    required this.totalTaxAmount,
    required this.grandTotal,
    required this.status,
    required this.items,
  });

  factory CreditNoteModel.fromJson(Map<String, dynamic> json) {
    return CreditNoteModel(
      id: (json["id"] as num).toInt(),
      creditNoteGuid: json["creditNoteGuid"]?.toString() ?? "",
      creditNoteNumber: json["creditNoteNumber"]?.toString() ?? "",
      invoiceId: (json["invoiceId"] as num).toInt(),
      invoiceNumber: json["invoiceNumber"]?.toString() ?? "",
      customerId: (json["customerId"] as num?)?.toInt(),
      customerName: json["customerName"]?.toString(),
      customerGstin: json["customerGstin"]?.toString(),
      creditNoteDateUtc: DateTime.tryParse(json["creditNoteDateUtc"]?.toString() ?? "") ?? DateTime.now(),
      reason: json["reason"]?.toString() ?? "",
      noteType: json["noteType"]?.toString() ?? "CreditNote",
      taxableAmount: (json["taxableAmount"] as num?)?.toDouble() ?? 0.0,
      cgstAmount: (json["cgstAmount"] as num?)?.toDouble() ?? 0.0,
      sgstAmount: (json["sgstAmount"] as num?)?.toDouble() ?? 0.0,
      igstAmount: (json["igstAmount"] as num?)?.toDouble() ?? 0.0,
      totalTaxAmount: (json["totalTaxAmount"] as num?)?.toDouble() ?? 0.0,
      grandTotal: (json["grandTotal"] as num?)?.toDouble() ?? 0.0,
      status: json["status"]?.toString() ?? "Issued",
      items: (json["items"] as List<dynamic>?)
              ?.map((e) => CreditNoteItemModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class B2cSummaryModel {
  final int totalInvoices;
  final double taxableValue;
  final double cgstAmount;
  final double sgstAmount;
  final double igstAmount;
  final double totalTax;
  final double grandTotal;

  const B2cSummaryModel({
    required this.totalInvoices,
    required this.taxableValue,
    required this.cgstAmount,
    required this.sgstAmount,
    required this.igstAmount,
    required this.totalTax,
    required this.grandTotal,
  });

  factory B2cSummaryModel.fromJson(Map<String, dynamic> json) {
    return B2cSummaryModel(
      totalInvoices: (json["totalInvoices"] as num?)?.toInt() ?? 0,
      taxableValue: (json["taxableValue"] as num?)?.toDouble() ?? 0.0,
      cgstAmount: (json["cgstAmount"] as num?)?.toDouble() ?? 0.0,
      sgstAmount: (json["sgstAmount"] as num?)?.toDouble() ?? 0.0,
      igstAmount: (json["igstAmount"] as num?)?.toDouble() ?? 0.0,
      totalTax: (json["totalTax"] as num?)?.toDouble() ?? 0.0,
      grandTotal: (json["grandTotal"] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class B2bInvoiceModel {
  final int invoiceId;
  final String invoiceNumber;
  final DateTime invoiceDateUtc;
  final String customerName;
  final String customerGstin;
  final double taxableValue;
  final double cgstAmount;
  final double sgstAmount;
  final double igstAmount;
  final double totalTax;
  final double grandTotal;

  const B2bInvoiceModel({
    required this.invoiceId,
    required this.invoiceNumber,
    required this.invoiceDateUtc,
    required this.customerName,
    required this.customerGstin,
    required this.taxableValue,
    required this.cgstAmount,
    required this.sgstAmount,
    required this.igstAmount,
    required this.totalTax,
    required this.grandTotal,
  });

  factory B2bInvoiceModel.fromJson(Map<String, dynamic> json) {
    return B2bInvoiceModel(
      invoiceId: (json["invoiceId"] as num).toInt(),
      invoiceNumber: json["invoiceNumber"]?.toString() ?? "",
      invoiceDateUtc: DateTime.tryParse(json["invoiceDateUtc"]?.toString() ?? "") ?? DateTime.now(),
      customerName: json["customerName"]?.toString() ?? "",
      customerGstin: json["customerGstin"]?.toString() ?? "",
      taxableValue: (json["taxableValue"] as num?)?.toDouble() ?? 0.0,
      cgstAmount: (json["cgstAmount"] as num?)?.toDouble() ?? 0.0,
      sgstAmount: (json["sgstAmount"] as num?)?.toDouble() ?? 0.0,
      igstAmount: (json["igstAmount"] as num?)?.toDouble() ?? 0.0,
      totalTax: (json["totalTax"] as num?)?.toDouble() ?? 0.0,
      grandTotal: (json["grandTotal"] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class B2bSummaryModel {
  final int totalInvoices;
  final double taxableValue;
  final double cgstAmount;
  final double sgstAmount;
  final double igstAmount;
  final double totalTax;
  final double grandTotal;
  final List<B2bInvoiceModel> invoices;

  const B2bSummaryModel({
    required this.totalInvoices,
    required this.taxableValue,
    required this.cgstAmount,
    required this.sgstAmount,
    required this.igstAmount,
    required this.totalTax,
    required this.grandTotal,
    required this.invoices,
  });

  factory B2bSummaryModel.fromJson(Map<String, dynamic> json) {
    return B2bSummaryModel(
      totalInvoices: (json["totalInvoices"] as num?)?.toInt() ?? 0,
      taxableValue: (json["taxableValue"] as num?)?.toDouble() ?? 0.0,
      cgstAmount: (json["cgstAmount"] as num?)?.toDouble() ?? 0.0,
      sgstAmount: (json["sgstAmount"] as num?)?.toDouble() ?? 0.0,
      igstAmount: (json["igstAmount"] as num?)?.toDouble() ?? 0.0,
      totalTax: (json["totalTax"] as num?)?.toDouble() ?? 0.0,
      grandTotal: (json["grandTotal"] as num?)?.toDouble() ?? 0.0,
      invoices: (json["invoices"] as List<dynamic>?)
              ?.map((e) => B2bInvoiceModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class HsnSummaryItemModel {
  final String hsnCode;
  final String description;
  final int totalQuantity;
  final double taxableValue;
  final double cgstAmount;
  final double sgstAmount;
  final double igstAmount;
  final double totalTax;

  const HsnSummaryItemModel({
    required this.hsnCode,
    required this.description,
    required this.totalQuantity,
    required this.taxableValue,
    required this.cgstAmount,
    required this.sgstAmount,
    required this.igstAmount,
    required this.totalTax,
  });

  factory HsnSummaryItemModel.fromJson(Map<String, dynamic> json) {
    return HsnSummaryItemModel(
      hsnCode: json["hsnCode"]?.toString() ?? "",
      description: json["description"]?.toString() ?? "",
      totalQuantity: (json["totalQuantity"] as num?)?.toInt() ?? 0,
      taxableValue: (json["taxableValue"] as num?)?.toDouble() ?? 0.0,
      cgstAmount: (json["cgstAmount"] as num?)?.toDouble() ?? 0.0,
      sgstAmount: (json["sgstAmount"] as num?)?.toDouble() ?? 0.0,
      igstAmount: (json["igstAmount"] as num?)?.toDouble() ?? 0.0,
      totalTax: (json["totalTax"] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class CreditNotesSummaryModel {
  final int totalCount;
  final double totalTaxableReduced;
  final double totalTaxReduced;
  final double netSalesLiability;

  const CreditNotesSummaryModel({
    required this.totalCount,
    required this.totalTaxableReduced,
    required this.totalTaxReduced,
    required this.netSalesLiability,
  });

  factory CreditNotesSummaryModel.fromJson(Map<String, dynamic> json) {
    return CreditNotesSummaryModel(
      totalCount: (json["totalCount"] as num?)?.toInt() ?? 0,
      totalTaxableReduced: (json["totalTaxableReduced"] as num?)?.toDouble() ?? 0.0,
      totalTaxReduced: (json["totalTaxReduced"] as num?)?.toDouble() ?? 0.0,
      netSalesLiability: (json["netSalesLiability"] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class GstSummaryModel {
  final DateTime fromUtc;
  final DateTime toUtc;
  final String companyGstin;
  final String legalName;
  final String stateCode;
  final B2cSummaryModel b2cSummary;
  final B2bSummaryModel b2bSummary;
  final List<HsnSummaryItemModel> hsnSummary;
  final CreditNotesSummaryModel creditNotesSummary;

  const GstSummaryModel({
    required this.fromUtc,
    required this.toUtc,
    required this.companyGstin,
    required this.legalName,
    required this.stateCode,
    required this.b2cSummary,
    required this.b2bSummary,
    required this.hsnSummary,
    required this.creditNotesSummary,
  });

  factory GstSummaryModel.fromJson(Map<String, dynamic> json) {
    return GstSummaryModel(
      fromUtc: DateTime.tryParse(json["fromUtc"]?.toString() ?? "") ?? DateTime.now(),
      toUtc: DateTime.tryParse(json["toUtc"]?.toString() ?? "") ?? DateTime.now(),
      companyGstin: json["companyGstin"]?.toString() ?? "",
      legalName: json["legalName"]?.toString() ?? "",
      stateCode: json["stateCode"]?.toString() ?? "",
      b2cSummary: B2cSummaryModel.fromJson(json["b2cSummary"] as Map<String, dynamic>? ?? {}),
      b2bSummary: B2bSummaryModel.fromJson(json["b2bSummary"] as Map<String, dynamic>? ?? {}),
      hsnSummary: (json["hsnSummary"] as List<dynamic>?)
              ?.map((e) => HsnSummaryItemModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      creditNotesSummary: CreditNotesSummaryModel.fromJson(json["creditNotesSummary"] as Map<String, dynamic>? ?? {}),
    );
  }
}

class CreateTaxRequest {
  final String taxName;
  final double ratePercentage;
  final bool isDefault;
  final bool isTaxInclusiveDefault;

  const CreateTaxRequest({
    required this.taxName,
    required this.ratePercentage,
    this.isDefault = false,
    this.isTaxInclusiveDefault = true,
  });

  Map<String, dynamic> toJson() => {
    "taxName": taxName,
    "ratePercentage": ratePercentage,
    "isDefault": isDefault,
    "isTaxInclusiveDefault": isTaxInclusiveDefault,
  };
}

class CreateHsnRequest {
  final String code;
  final String description;
  final String type;
  final double defaultGstRate;
  final bool isActive;

  const CreateHsnRequest({
    required this.code,
    required this.description,
    required this.type,
    required this.defaultGstRate,
    this.isActive = true,
  });

  Map<String, dynamic> toJson() => {
    "code": code,
    "description": description,
    "type": type,
    "defaultGstRate": defaultGstRate,
    "isActive": isActive,
  };
}

class UpdateGstConfigRequest {
  final String gstin;
  final String legalName;
  final String tradeName;
  final String stateName;
  final String stateCode;
  final bool isCompositionScheme;
  final bool defaultPricingIsTaxInclusive;
  final String? invoiceTermsAndConditions;
  final String? invoiceHeader;
  final String? invoiceFooter;
  final bool showHsnSummaryOnReceipt;
  final bool showTaxBreakupOnReceipt;

  const UpdateGstConfigRequest({
    required this.gstin,
    required this.legalName,
    required this.tradeName,
    required this.stateName,
    required this.stateCode,
    this.isCompositionScheme = false,
    this.defaultPricingIsTaxInclusive = true,
    this.invoiceTermsAndConditions,
    this.invoiceHeader,
    this.invoiceFooter,
    this.showHsnSummaryOnReceipt = true,
    this.showTaxBreakupOnReceipt = true,
  });

  Map<String, dynamic> toJson() => {
    "gstin": gstin,
    "legalName": legalName,
    "tradeName": tradeName,
    "stateName": stateName,
    "stateCode": stateCode,
    "isCompositionScheme": isCompositionScheme,
    "defaultPricingIsTaxInclusive": defaultPricingIsTaxInclusive,
    "invoiceTermsAndConditions": invoiceTermsAndConditions,
    "invoiceHeader": invoiceHeader,
    "invoiceFooter": invoiceFooter,
    "showHsnSummaryOnReceipt": showHsnSummaryOnReceipt,
    "showTaxBreakupOnReceipt": showTaxBreakupOnReceipt,
  };
}

class CreateCreditNoteItemRequest {
  final int productId;
  final int quantity;
  final double? unitPrice;
  final String? reason;

  const CreateCreditNoteItemRequest({
    required this.productId,
    required this.quantity,
    this.unitPrice,
    this.reason,
  });

  Map<String, dynamic> toJson() => {
    "productId": productId,
    "quantity": quantity,
    if (unitPrice != null) "unitPrice": unitPrice,
    if (reason != null) "reason": reason,
  };
}

class CreateCreditNoteRequest {
  final int invoiceId;
  final String reason;
  final String noteType;
  final List<CreateCreditNoteItemRequest> items;

  const CreateCreditNoteRequest({
    required this.invoiceId,
    required this.reason,
    this.noteType = "CreditNote",
    required this.items,
  });

  Map<String, dynamic> toJson() => {
    "invoiceId": invoiceId,
    "reason": reason,
    "noteType": noteType,
    "items": items.map((i) => i.toJson()).toList(),
  };
}

