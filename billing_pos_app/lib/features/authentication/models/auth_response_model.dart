import "user_model.dart";

class AuthResponseModel {
  final String accessToken;
  final String refreshToken;
  final DateTime expiresAtUtc;
  final UserModel user;
  final List<String> permissions;

  AuthResponseModel({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresAtUtc,
    required this.user,
    required this.permissions,
  });

  factory AuthResponseModel.fromJson(Map<String, dynamic> json) {
    return AuthResponseModel(
      accessToken: json["accessToken"]?.toString() ?? "",
      refreshToken: json["refreshToken"]?.toString() ?? "",
      expiresAtUtc: json["expiresAtUtc"] != null 
          ? DateTime.tryParse(json["expiresAtUtc"].toString()) ?? DateTime.now().add(const Duration(hours: 1))
          : DateTime.now().add(const Duration(hours: 1)),
      user: UserModel.fromJson(json["user"] as Map<String, dynamic>),
      permissions: (json["permissions"] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }
}

