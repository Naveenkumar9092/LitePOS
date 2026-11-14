enum BusinessCategory {
  cafe(1, "Cafe", "Beverages, snacks, coffee & bakery items"),
  foodCourt(2, "Food Court", "Quick counter orders & token numbers"),
  iceCreamAndDesserts(3, "Ice Cream & Desserts", "Ice cream scoops, tubs & plated desserts");

  final int id;
  final String title;
  final String description;

  const BusinessCategory(this.id, this.title, this.description);

  static BusinessCategory fromId(int? id) {
    return BusinessCategory.values.firstWhere(
      (c) => c.id == id,
      orElse: () => BusinessCategory.cafe,
    );
  }
}

class ShopModel {
  final int shopId;
  final int companyId;
  final String shopName;
  final String addressLine1;
  final String? addressLine2;
  final String city;
  final String state;
  final String pincode;
  final String country;
  final String contactNumber;
  final String email;
  final String timeZone;
  final String currencyCode;
  final String? invoiceHeader;
  final String? invoiceFooter;
  final bool isActive;

  ShopModel({
    required this.shopId,
    required this.companyId,
    required this.shopName,
    required this.addressLine1,
    this.addressLine2,
    required this.city,
    required this.state,
    required this.pincode,
    required this.country,
    required this.contactNumber,
    required this.email,
    required this.timeZone,
    required this.currencyCode,
    this.invoiceHeader,
    this.invoiceFooter,
    required this.isActive,
  });

  factory ShopModel.fromJson(Map<String, dynamic> json) {
    return ShopModel(
      shopId: (json["shopId"] as num?)?.toInt() ?? 0,
      companyId: (json["companyId"] as num?)?.toInt() ?? 0,
      shopName: json["shopName"] as String? ?? "",
      addressLine1: json["addressLine1"] as String? ?? "",
      addressLine2: json["addressLine2"] as String?,
      city: json["city"] as String? ?? "",
      state: json["state"] as String? ?? "",
      pincode: json["pincode"] as String? ?? "",
      country: json["country"] as String? ?? "India",
      contactNumber: json["contactNumber"] as String? ?? "",
      email: json["email"] as String? ?? "",
      timeZone: json["timeZone"] as String? ?? "India Standard Time",
      currencyCode: json["currencyCode"] as String? ?? "INR",
      invoiceHeader: json["invoiceHeader"] as String?,
      invoiceFooter: json["invoiceFooter"] as String?,
      isActive: json["isActive"] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "shopId": shopId,
      "companyId": companyId,
      "shopName": shopName,
      "addressLine1": addressLine1,
      "addressLine2": addressLine2,
      "city": city,
      "state": state,
      "pincode": pincode,
      "country": country,
      "contactNumber": contactNumber,
      "email": email,
      "timeZone": timeZone,
      "currencyCode": currencyCode,
      "invoiceHeader": invoiceHeader,
      "invoiceFooter": invoiceFooter,
      "isActive": isActive,
    };
  }
}

class CompanyProfileModel {
  final int companyId;
  final String companyName;
  final String? legalName;
  final BusinessCategory businessCategory;
  final String? gstin;
  final String? pan;
  final String email;
  final String mobileNumber;
  final String? website;
  final String? logoStorageKey;
  final bool isActive;
  final ShopModel? shop;

  CompanyProfileModel({
    required this.companyId,
    required this.companyName,
    this.legalName,
    required this.businessCategory,
    this.gstin,
    this.pan,
    required this.email,
    required this.mobileNumber,
    this.website,
    this.logoStorageKey,
    required this.isActive,
    this.shop,
  });

  factory CompanyProfileModel.fromJson(Map<String, dynamic> json) {
    return CompanyProfileModel(
      companyId: (json["companyId"] as num?)?.toInt() ?? 0,
      companyName: json["companyName"] as String? ?? "",
      legalName: json["legalName"] as String?,
      businessCategory: BusinessCategory.fromId(json["businessType"] as int?),
      gstin: json["gstin"] as String?,
      pan: json["pan"] as String?,
      email: json["email"] as String? ?? "",
      mobileNumber: json["mobileNumber"] as String? ?? "",
      website: json["website"] as String?,
      logoStorageKey: json["logoStorageKey"] as String?,
      isActive: json["isActive"] as bool? ?? true,
      shop: json["shop"] != null && json["shop"] is Map<String, dynamic>
          ? ShopModel.fromJson(json["shop"] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "companyId": companyId,
      "companyName": companyName,
      "legalName": legalName,
      "businessType": businessCategory.id,
      "gstin": gstin,
      "pan": pan,
      "email": email,
      "mobileNumber": mobileNumber,
      "website": website,
      "logoStorageKey": logoStorageKey,
      "isActive": isActive,
      "shop": shop?.toJson(),
    };
  }
}

