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

class FakeUserListNotifier extends StateNotifier<UserListState> implements UserListNotifier {
  FakeUserListNotifier([UserListState? initialState]) : super(initialState ?? const UserListState());

  Map<String, dynamic>? lastCreatedUserData;

  @override
  dynamic noSuchMethod(Invocation invocation) => null;

  @override
  Future<bool> createUser(Map<String, dynamic> data) async {
    lastCreatedUserData = data;
    return true;
  }

  @override
  Future<void> loadUsers() async {}

  @override
  void setSearchQuery(String query) {}

  @override
  void setRoleFilter(int? roleId) {}

  @override
  void setStatusFilter(bool? isActive) {}
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
      tester.view.physicalSize = const Size(1200, 1400);
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

      await tester.ensureVisible(find.text("Create Admin"));
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

  group("UserManagementScreen Role Hierarchy & Access Control Tests", () {
    testWidgets("allows Store Admin to view Cashier Management and create Cashiers", (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

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
            userListNotifierProvider.overrideWith((ref) => FakeUserListNotifier(
              UserListState(users: [
                UserModel(id: 3, companyId: 1, fullName: "Cashier 1", username: "cashier1", roleId: 3, roleName: "Cashier", isActive: true, createdAtUtc: DateTime.now()),
              ]),
            )),
          ],
          child: const MaterialApp(
            home: UserManagementScreen(),
          ),
        ),
      );

      expect(find.text("Cashier Management"), findsOneWidget);
      expect(find.text("Create Cashier"), findsOneWidget);
      expect(find.text("Cashiers"), findsOneWidget);
      expect(find.text("Role: Cashier"), findsOneWidget);
      expect(find.text("Super Admin Access Required"), findsNothing);
    });

    testWidgets("restricts access and shows warning when user is Cashier", (tester) async {
      final cashierUser = UserModel(
        id: 3,
        companyId: 1,
        fullName: "Counter Cashier",
        username: "cashier01",
        roleId: 3,
        roleName: "Cashier",
        isActive: true,
        createdAtUtc: DateTime.now(),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authNotifierProvider.overrideWith((ref) => MockAuthNotifier(AuthState(user: cashierUser, isAuthenticated: true))),
          ],
          child: const MaterialApp(
            home: UserManagementScreen(),
          ),
        ),
      );

      expect(find.text("Administrator Access Required"), findsOneWidget);
      expect(find.textContaining("Staff management is restricted exclusively to Store and System Administrators."), findsOneWidget);
      expect(find.text("Return to Billing"), findsOneWidget);
    });

    testWidgets("allows SAdmin to view Admin management and Create Admin Profile", (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

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

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authNotifierProvider.overrideWith((ref) => MockAuthNotifier(AuthState(user: sadminUser, isAuthenticated: true))),
            userListNotifierProvider.overrideWith((ref) => FakeUserListNotifier(
              UserListState(users: [
                UserModel(id: 1, companyId: 0, fullName: "Super Administrator", username: "sadmin", roleId: 1, roleName: "SAdmin", isActive: true, createdAtUtc: DateTime.now()),
                UserModel(id: 2, companyId: 1, fullName: "Shop Administrator", username: "admin", roleId: 2, roleName: "Admin", isActive: true, createdAtUtc: DateTime.now()),
              ]),
            )),
          ],
          child: const MaterialApp(
            home: UserManagementScreen(),
          ),
        ),
      );

      expect(find.text("Admin & User Management"), findsOneWidget);
      expect(find.text("Create Admin Profile"), findsOneWidget);
      expect(find.text("Roles & Permissions"), findsOneWidget);
    });
  });
}
