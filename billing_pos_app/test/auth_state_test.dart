import "package:flutter_test/flutter_test.dart";
import "package:billing_pos_app/features/authentication/data/auth_repository.dart";
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
        isOffline: true,
      );

      expect(updated.isAuthenticated, true);
      expect(updated.user?.username, "admin");
      expect(updated.permissions.length, 2);
      expect(updated.isOffline, true);
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
}

class _FakeAuthRepository extends Fake implements AuthRepository {
  @override
  Future<UserModel?> getCachedUser() async => null;
}

