import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_test/flutter_test.dart";
import "package:billing_pos_app/features/authentication/models/user_model.dart";
import "package:billing_pos_app/features/authentication/presentation/auth_state.dart";
import "package:billing_pos_app/features/users/presentation/user_management_screen.dart";
import "package:billing_pos_app/features/users/presentation/widgets/create_admin_dialog.dart";
import "package:billing_pos_app/features/users/presentation/widgets/create_cashier_dialog.dart";
import "package:billing_pos_app/features/users/presentation/user_state.dart";

class MockAuthNotifier extends StateNotifier<AuthState> implements AuthNotifier {
  MockAuthNotifier(super.state);

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class FakeUserListNotifier extends UserListNotifier {
  FakeUserListNotifier(super.repository);

  Map<String, dynamic>? lastCreatedUserData;

  @override
  Future<bool> createUser(Map<String, dynamic> data) async {
    lastCreatedUserData = data;
    return true;
  }
}

void main() {
  group("CreateAdminDialog Tests", () {
    testWidgets("renders all admin creation fields and pre-assigned Admin role badge", (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: CreateAdminDialog(),
            ),
          ),
        ),
      );

      expect(find.text("Create Admin User"), findsOneWidget);
      expect(find.textContaining("Role: Admin"), findsOneWidget);
      expect(find.text("Admin Full Name *"), findsOneWidget);
      expect(find.text("Username *"), findsOneWidget);
      expect(find.text("Temporary Password *"), findsOneWidget);
      expect(find.text("Mobile Number (10 digits) *"), findsOneWidget);
      expect(find.text("Create Admin"), findsOneWidget);
    });

    testWidgets("validates empty required fields on submit", (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: CreateAdminDialog(),
            ),
          ),
        ),
      );

      await tester.tap(find.text("Create Admin"));
      await tester.pumpAndSettle();

      expect(find.text("Full name is required."), findsOneWidget);
      expect(find.text("Username is required."), findsOneWidget);
      expect(find.text("Password is required."), findsOneWidget);
      expect(find.text("Mobile number is required."), findsOneWidget);
    });
  });

  group("CreateCashierDialog Tests", () {
    testWidgets("renders all cashier creation fields and Cashier role badge", (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: CreateCashierDialog(),
            ),
          ),
        ),
      );

      expect(find.text("Register New Cashier"), findsOneWidget);
      expect(find.textContaining("Role: Cashier (Billing Operator)"), findsOneWidget);
      expect(find.text("Cashier Full Name *"), findsOneWidget);
      expect(find.text("Username *"), findsOneWidget);
      expect(find.text("Temporary Password *"), findsOneWidget);
      expect(find.text("Mobile Number (10 digits) *"), findsOneWidget);
      expect(find.text("Create Cashier"), findsOneWidget);
    });

    testWidgets("validates required fields when submitting empty cashier form", (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: CreateCashierDialog(),
            ),
          ),
        ),
      );

      await tester.tap(find.text("Create Cashier"));
      await tester.pumpAndSettle();

      expect(find.text("Full name is required."), findsOneWidget);
      expect(find.text("Username is required."), findsOneWidget);
      expect(find.text("Password is required."), findsOneWidget);
      expect(find.text("Mobile number is required."), findsOneWidget);
    });
  });

  group("UserManagementScreen SAdmin Access Control Tests", () {
    testWidgets("restricts access and shows warning when user is Admin (not SAdmin)", (tester) async {
      final adminUser = UserModel(
        id: 2,
        companyId: 1,
        fullName: "Store Administrator",
        username: "store_admin",
        roleId: 2,
        roleName: "Admin",
        isActive: true,
        createdAtUtc: DateTime.now(),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authNotifierProvider.overrideWith((ref) => MockAuthNotifier(AuthState(user: adminUser, isAuthenticated: true))),
          ],
          child: const MaterialApp(
            home: UserManagementScreen(),
          ),
        ),
      );

      expect(find.text("Super Admin Access Required"), findsOneWidget);
      expect(find.textContaining("User & Role Management is restricted exclusively to Super Administrators (SAdmin)"), findsOneWidget);
      expect(find.text("Return to Dashboard"), findsOneWidget);
    });
  });
}
