import "package:flutter_test/flutter_test.dart";
import "package:billing_pos_app/features/authentication/data/auth_repository.dart";
import "package:billing_pos_app/features/authentication/models/auth_response_model.dart";
import "package:billing_pos_app/features/authentication/models/user_model.dart";
import "package:billing_pos_app/features/authentication/presentation/auth_state.dart";

void main() {
  group("AuthState Tests", () {
    test("Initial state is unauthenticated", () {
      const state = AuthState();
      expect(state.isLoading, false);
      expect(state.isAuthenticated, false);
      expect(state.user, null);
      expect(state.permissions, isEmpty);
    });

    test("copyWith updates state fields properly", () {
      const state = AuthState();
      final user = UserModel(
        id: 2,
        companyId: 1,
        fullName: "Admin User",
        username: "admin",
        roleId: 2,
        roleName: "Admin",
        isActive: true,
        createdAtUtc: DateTime.now(),
      );

      final updated = state.copyWith(
        isAuthenticated: true,
        user: user,
        permissions: ["users.view", "billing.create"],
        isOffline: false,
      );

      expect(updated.isAuthenticated, true);
      expect(updated.user?.username, "admin");
      expect(updated.permissions.length, 2);
      expect(updated.isOffline, false);
    });

    test("AuthNotifier initialized with initialUser starts authenticated immediately", () {
      final user = UserModel(
        id: 1,
        companyId: 0,
        fullName: "Super Administrator",
        username: "sadmin",
        roleId: 1,
        roleName: "SAdmin",
        isActive: true,
        createdAtUtc: DateTime.now(),
      );

      final notifier = AuthNotifier(
        _FakeAuthRepository(),
        user,
      );

      expect(notifier.state.isAuthenticated, true);
      expect(notifier.state.user?.username, "sadmin");
      expect(notifier.state.isOffline, true);
    });
  });

  group("Online Login and SAdmin Restrictions Tests", () {
    test("checkInitialAuth blocks SAdmin when offline and displays connection required message", () async {
      final sadminUser = UserModel(
        id: 1,
        companyId: 0,
        fullName: "Super Administrator",
        username: "sadmin",
        roleId: 1,
        roleName: "SAdmin",
        isActive: true,
        createdAtUtc: DateTime.now(),
      );

      final repo = _FakeAuthRepository(cachedUser: sadminUser, online: false);
      final notifier = AuthNotifier(repo);

      // Give checkInitialAuth async task time to complete
      await Future.delayed(const Duration(milliseconds: 50));

      expect(notifier.state.isAuthenticated, false);
      expect(notifier.state.user, isNull);
      expect(notifier.state.errorMessage, contains("Super Administrator requires an active internet connection"));
    });

    test("checkInitialAuth permits SAdmin when online", () async {
      final sadminUser = UserModel(
        id: 1,
        companyId: 0,
        fullName: "Super Administrator",
        username: "sadmin",
        roleId: 1,
        roleName: "SAdmin",
        isActive: true,
        createdAtUtc: DateTime.now(),
      );

      final repo = _FakeAuthRepository(cachedUser: sadminUser, online: true);
      final notifier = AuthNotifier(repo);

      await Future.delayed(const Duration(milliseconds: 50));

      expect(notifier.state.isAuthenticated, true);
      expect(notifier.state.user?.username, "sadmin");
      expect(notifier.state.errorMessage, isNull);
    });

    test("checkInitialAuth permits Admin/Cashier session restore for continuous POS operations", () async {
      final cashierUser = UserModel(
        id: 3,
        companyId: 1,
        fullName: "Cashier One",
        username: "cashier1",
        roleId: 3,
        roleName: "Cashier",
        isActive: true,
        createdAtUtc: DateTime.now(),
      );

      final repo = _FakeAuthRepository(cachedUser: cashierUser, online: false);
      final notifier = AuthNotifier(repo);

      await Future.delayed(const Duration(milliseconds: 50));

      expect(notifier.state.isAuthenticated, true);
      expect(notifier.state.user?.username, "cashier1");
    });

    test("login executes online authentication and sets isOffline to false on success", () async {
      final repo = _FakeAuthRepository(online: true);
      final notifier = AuthNotifier(repo);

      final success = await notifier.login("admin", "ValidPass123!");

      expect(success, true);
      expect(notifier.state.isAuthenticated, true);
      expect(notifier.state.isOffline, false);
      expect(notifier.state.user?.username, "admin");
    });

    test("login fails with appropriate error when connection is unavailable", () async {
      final repo = _FakeAuthRepository(
        online: false,
        throwOnLogin: Exception("An active internet connection is required to log in. Please connect to the internet."),
      );
      final notifier = AuthNotifier(repo);

      final success = await notifier.login("cashier1", "Password123!");

      expect(success, false);
      expect(notifier.state.isAuthenticated, false);
      expect(notifier.state.errorMessage, contains("active internet connection is required"));
    });

    test("login for sadmin fails with SAdmin specific message when offline", () async {
      final repo = _FakeAuthRepository(
        online: false,
        throwOnLogin: Exception("Super Administrator requires an active internet connection to log in."),
      );
      final notifier = AuthNotifier(repo);

      final success = await notifier.login("sadmin", "AnyPass!");

      expect(success, false);
      expect(notifier.state.isAuthenticated, false);
      expect(notifier.state.errorMessage, contains("Super Administrator requires an active internet connection to log in"));
    });
  });
}

class _FakeAuthRepository extends Fake implements AuthRepository {
  final UserModel? cachedUser;
  final bool online;
  final Exception? throwOnLogin;

  _FakeAuthRepository({
    this.cachedUser,
    this.online = true,
    this.throwOnLogin,
  });

  @override
  Future<UserModel?> getCachedUser() async => cachedUser;

  @override
  Future<bool> isOnline() async => online;

  @override
  Future<AuthResponseModel> login({
    required String username,
    required String password,
    String? deviceId,
    String? deviceName,
    bool forceOffline = false,
  }) async {
    if (throwOnLogin != null) {
      throw throwOnLogin!;
    }
    final user = UserModel(
      id: 2,
      companyId: 1,
      fullName: "Admin User",
      username: username,
      roleId: 2,
      roleName: "Admin",
      isActive: true,
      createdAtUtc: DateTime.now(),
    );
    return AuthResponseModel(
      accessToken: "online-jwt-token-xyz",
      refreshToken: "online-refresh-token-xyz",
      expiresAtUtc: DateTime.now().add(const Duration(hours: 8)),
      user: user,
      permissions: ["dashboard.view", "billing.create"],
    );
  }
}
