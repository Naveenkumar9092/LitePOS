import "package:flutter_test/flutter_test.dart";
import "package:billing_pos_app/features/authentication/models/user_model.dart";
import "package:billing_pos_app/features/users/data/user_repository.dart";
import "package:billing_pos_app/features/users/presentation/user_state.dart";

class MockUserRepository implements UserRepository {
  List<UserModel> mockUsers = [];
  Map<String, dynamic>? createdData;

  @override
  Future<PagedUsersResult> getUsers({
    int pageNumber = 1,
    int pageSize = 20,
    String? search,
    int? roleId,
    bool? isActive,
    int? companyId,
    bool excludeCashiers = false,
    bool onlyCashiers = false,
  }) async {
    var items = List<UserModel>.from(mockUsers);
    if (excludeCashiers) items = items.where((u) => !u.isCashier).toList();
    if (onlyCashiers) {
      items = items.where((u) => u.isCashier && (companyId == null || companyId == 0 || u.companyId == companyId)).toList();
    }
    return PagedUsersResult(items: items, totalCount: items.length, pageIndex: 1, pageSize: 20);
  }

  @override
  Future<UserModel> createUser(Map<String, dynamic> data) async {
    createdData = data;
    return UserModel(
      id: 99,
      companyId: (data["companyId"] as num?)?.toInt() ?? 1,
      fullName: data["fullName"]?.toString() ?? "",
      username: data["username"]?.toString() ?? "",
      roleId: (data["roleId"] as num?)?.toInt() ?? 3,
      roleName: data["roleId"] == 2 ? "Admin" : "Cashier",
      isActive: true,
      createdAtUtc: DateTime.now(),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

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
      expect(sqliteMap["CompanyId"], 1);
      expect(sqliteMap["Username"], "operator1");
      expect(sqliteMap["RoleName"], "Cashier");
      expect(sqliteMap["IsActive"], 1);

      final reconstructed = UserModel.fromSqlite(sqliteMap);
      expect(reconstructed.id, 42);
      expect(reconstructed.companyId, 1);
      expect(reconstructed.username, "operator1");
      expect(reconstructed.roleName, "Cashier");
      expect(reconstructed.isActive, true);
    });
  });

  group("User Role Hierarchy & Scoping Tests", () {
    late MockUserRepository mockRepo;

    final sadminUser = UserModel(
      id: 1,
      companyId: 0,
      fullName: "Super Admin",
      username: "sadmin",
      roleId: 1,
      roleName: "SAdmin",
      isActive: true,
      createdAtUtc: DateTime.now(),
    );

    final adminCompany1 = UserModel(
      id: 2,
      companyId: 1,
      fullName: "Shop Admin 1",
      username: "admin1",
      roleId: 2,
      roleName: "Admin",
      isActive: true,
      createdAtUtc: DateTime.now(),
    );

    final cashierCompany1 = UserModel(
      id: 3,
      companyId: 1,
      fullName: "Cashier Comp 1",
      username: "cashier1",
      roleId: 3,
      roleName: "Cashier",
      isActive: true,
      createdAtUtc: DateTime.now(),
    );

    final cashierCompany2 = UserModel(
      id: 4,
      companyId: 2,
      fullName: "Cashier Comp 2",
      username: "cashier2",
      roleId: 3,
      roleName: "Cashier",
      isActive: true,
      createdAtUtc: DateTime.now(),
    );

    setUp(() {
      mockRepo = MockUserRepository();
      mockRepo.mockUsers = [sadminUser, adminCompany1, cashierCompany1, cashierCompany2];
    });

    test("SAdmin views only Admins and SAdmins, Cashiers are never visible", () async {
      final notifier = UserListNotifier(mockRepo, currentUser: sadminUser);
      await notifier.loadUsers();

      final state = notifier.state;
      expect(state.users.any((u) => u.isCashier), false);
      expect(state.users.any((u) => u.isSAdmin), true);
      expect(state.users.any((u) => u.isAdmin), true);
      expect(state.users.length, 2);
    });

    test("SAdmin cannot create Cashier", () async {
      final notifier = UserListNotifier(mockRepo, currentUser: sadminUser);
      await notifier.loadUsers();
      final result = await notifier.createUser({
        "fullName": "New Cashier",
        "username": "new_cashier",
        "roleId": 3,
      });

      expect(result, false);
      expect(notifier.state.errorMessage, contains("Super Administrators cannot create Cashiers"));
    });

    test("SAdmin can create Admin profile", () async {
      final notifier = UserListNotifier(mockRepo, currentUser: sadminUser);
      await notifier.loadUsers();
      final result = await notifier.createUser({
        "fullName": "New Admin",
        "username": "new_admin",
        "roleId": 2,
      });

      expect(result, true);
      expect(mockRepo.createdData?["roleId"], 2);
    });

    test("Admin views only Cashiers belonging to their own company", () async {
      final notifier = UserListNotifier(mockRepo, currentUser: adminCompany1);
      await notifier.loadUsers();

      final state = notifier.state;
      expect(state.users.every((u) => u.isCashier), true);
      expect(state.users.every((u) => u.companyId == 1), true);
      expect(state.users.any((u) => u.id == 4), false); // Comp 2 cashier excluded
      expect(state.users.any((u) => u.isSAdmin || u.isAdmin), false); // Admins excluded
      expect(state.users.length, 1);
      expect(state.users.first.username, "cashier1");
    });

    test("Admin cannot create Admin profile", () async {
      final notifier = UserListNotifier(mockRepo, currentUser: adminCompany1);
      await notifier.loadUsers();
      final result = await notifier.createUser({
        "fullName": "Attempted Admin",
        "username": "attempted_admin",
        "roleId": 2,
      });

      expect(result, false);
      expect(notifier.state.errorMessage, contains("Shop Admins can only create Cashiers"));
    });

    test("Admin creates Cashier automatically scoped to own company", () async {
      final notifier = UserListNotifier(mockRepo, currentUser: adminCompany1);
      await notifier.loadUsers();
      final result = await notifier.createUser({
        "fullName": "New Counter Cashier",
        "username": "counter_cashier",
        "roleId": 3,
      });

      expect(result, true);
      expect(mockRepo.createdData?["roleId"], 3);
      expect(mockRepo.createdData?["companyId"], 1); // Auto-assigned admin's companyId
    });
  });
}

