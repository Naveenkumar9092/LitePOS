class UserModel {
  final int id;
  final int companyId;
  final int? shopId;
  final String fullName;
  final String username;
  final String? email;
  final String? mobileNumber;
  final int roleId;
  final String roleName;
  final String? shopName;
  final bool isActive;
  final DateTime createdAtUtc;
  final DateTime? updatedAtUtc;

  UserModel({
    required this.id,
    required this.companyId,
    this.shopId,
    required this.fullName,
    required this.username,
    this.email,
    this.mobileNumber,
    required this.roleId,
    required this.roleName,
    this.shopName,
    required this.isActive,
    required this.createdAtUtc,
    this.updatedAtUtc,
  });

  bool get isSAdmin => roleName.toLowerCase() == "sadmin" || roleId == 1;
  bool get isAdmin => roleName.toLowerCase() == "admin" || roleId == 2;
  bool get isCashier => roleName.toLowerCase() == "cashier" || roleId == 3;
  int get userId => id;

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: (json["id"] as num).toInt(),
      companyId: (json["companyId"] as num?)?.toInt() ?? 1,
      shopId: (json["shopId"] as num?)?.toInt(),
      fullName: json["fullName"]?.toString() ?? "",
      username: json["username"]?.toString() ?? "",
      email: json["email"]?.toString(),
      mobileNumber: json["mobileNumber"]?.toString(),
      roleId: (json["roleId"] as num?)?.toInt() ?? 3,
      roleName: json["roleName"]?.toString() ?? "Cashier",
      shopName: json["shopName"]?.toString(),
      isActive: json["isActive"] as bool? ?? true,
      createdAtUtc: json["createdAtUtc"] != null 
          ? DateTime.tryParse(json["createdAtUtc"].toString()) ?? DateTime.now()
          : DateTime.now(),
      updatedAtUtc: json["updatedAtUtc"] != null 
          ? DateTime.tryParse(json["updatedAtUtc"].toString()) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "companyId": companyId,
      "shopId": shopId,
      "fullName": fullName,
      "username": username,
      "email": email,
      "mobileNumber": mobileNumber,
      "roleId": roleId,
      "roleName": roleName,
      "shopName": shopName,
      "isActive": isActive,
      "createdAtUtc": createdAtUtc.toIso8601String(),
      "updatedAtUtc": updatedAtUtc?.toIso8601String(),
    };
  }

  factory UserModel.fromSqlite(Map<String, dynamic> map) {
    return UserModel(
      id: (map["UserId"] as num).toInt(),
      companyId: 1,
      shopId: null,
      fullName: map["FullName"]?.toString() ?? "",
      username: map["Username"]?.toString() ?? "",
      email: map["Email"]?.toString(),
      mobileNumber: map["MobileNumber"]?.toString(),
      roleId: (map["RoleId"] as num?)?.toInt() ?? 3,
      roleName: map["RoleName"]?.toString() ?? "Cashier",
      shopName: null,
      isActive: (map["IsActive"] as num?) == 1,
      createdAtUtc: DateTime.now(),
    );
  }

  Map<String, dynamic> toSqlite() {
    return {
      "UserId": id,
      "FullName": fullName,
      "Username": username,
      "Email": email,
      "MobileNumber": mobileNumber,
      "RoleId": roleId,
      "RoleName": roleName,
      "IsActive": isActive ? 1 : 0,
    };
  }
}

