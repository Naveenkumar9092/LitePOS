class RoleModel {
  final int id;
  final String name;
  final String? description;
  final bool isActive;
  final List<String> permissions;

  RoleModel({
    required this.id,
    required this.name,
    this.description,
    required this.isActive,
    required this.permissions,
  });

  factory RoleModel.fromJson(Map<String, dynamic> json) {
    return RoleModel(
      id: (json["id"] as num).toInt(),
      name: json["name"]?.toString() ?? "",
      description: json["description"]?.toString(),
      isActive: json["isActive"] as bool? ?? true,
      permissions: (json["permissions"] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }
}

class PermissionModel {
  final int id;
  final String code;
  final String name;
  final String category;
  final String? description;

  PermissionModel({
    required this.id,
    required this.code,
    required this.name,
    required this.category,
    this.description,
  });

  factory PermissionModel.fromJson(Map<String, dynamic> json) {
    return PermissionModel(
      id: (json["id"] as num).toInt(),
      code: json["code"]?.toString() ?? "",
      name: json["name"]?.toString() ?? "",
      category: json["category"]?.toString() ?? "",
      description: json["description"]?.toString(),
    );
  }
}

