import "package:flutter_test/flutter_test.dart";
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
      );

      expect(updated.isAuthenticated, true);
      expect(updated.user?.username, "admin");
      expect(updated.permissions.length, 2);
    });
  });
}

