import "package:flutter_test/flutter_test.dart";
import "package:billing_pos_app/features/authentication/models/user_model.dart";

void main() {
  group("UserModel Tests", () {
    test("UserModel.fromJson parses correctly", () {
      final json = {
        "id": 1,
        "companyId": 1,
        "shopId": 10,
        "fullName": "Super Administrator",
        "username": "sadmin",
        "email": "sadmin@litepos.com",
        "mobileNumber": "9876543210",
        "roleId": 1,
        "roleName": "SAdmin",
        "shopName": "Main Cafe",
        "isActive": true,
        "createdAtUtc": "2026-11-12T10:00:00.000Z",
      };

      final user = UserModel.fromJson(json);

      expect(user.id, 1);
      expect(user.fullName, "Super Administrator");
      expect(user.username, "sadmin");
      expect(user.roleName, "SAdmin");
      expect(user.isSAdmin, true);
      expect(user.isAdmin, false);
      expect(user.isCashier, false);
    });

    test("UserModel Cashier role helper identifies correctly", () {
      final user = UserModel(
        id: 3,
        companyId: 1,
        fullName: "Cashier Operator",
        username: "cashier1",
        roleId: 3,
        roleName: "Cashier",
        isActive: true,
        createdAtUtc: DateTime.now(),
      );

      expect(user.isCashier, true);
      expect(user.isAdmin, false);
      expect(user.isSAdmin, false);
    });

    test("UserModel SQLite roundtrip preserves columns", () {
      final user = UserModel(
        id: 42,
        companyId: 1,
        fullName: "Test Operator",
        username: "operator1",
        email: "op@test.com",
        mobileNumber: "9988776655",
        roleId: 3,
        roleName: "Cashier",
        isActive: true,
        createdAtUtc: DateTime.now(),
      );

      final sqliteMap = user.toSqlite();
      expect(sqliteMap["UserId"], 42);
      expect(sqliteMap["Username"], "operator1");
      expect(sqliteMap["RoleName"], "Cashier");
      expect(sqliteMap["IsActive"], 1);

      final reconstructed = UserModel.fromSqlite(sqliteMap);
      expect(reconstructed.id, 42);
      expect(reconstructed.username, "operator1");
      expect(reconstructed.roleName, "Cashier");
      expect(reconstructed.isActive, true);
    });
  });
}

