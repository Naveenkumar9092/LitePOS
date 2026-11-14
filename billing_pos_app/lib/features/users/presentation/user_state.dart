import "package:flutter_riverpod/flutter_riverpod.dart";
import "../../authentication/models/user_model.dart";
import "../../company/data/company_repository.dart";
import "../data/user_repository.dart";
import "../models/login_audit_log_model.dart";
import "../models/role_model.dart";

final userRepositoryProvider = Provider<UserRepository>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  final db = ref.watch(appDatabaseProvider);
  return UserRepository(dioClient, db);
});

class UserListState {
  final bool isLoading;
  final List<UserModel> users;
  final int totalCount;
  final String searchQuery;
  final int? selectedRoleId;
  final bool? selectedStatus;
  final String? errorMessage;
  final String? successMessage;

  const UserListState({
    this.isLoading = false,
    this.users = const [],
    this.totalCount = 0,
    this.searchQuery = "",
    this.selectedRoleId,
    this.selectedStatus,
    this.errorMessage,
    this.successMessage,
  });

  UserListState copyWith({
    bool? isLoading,
    List<UserModel>? users,
    int? totalCount,
    String? searchQuery,
    int? selectedRoleId,
    bool? selectedStatus,
    String? errorMessage,
    String? successMessage,
    bool clearRoleFilter = false,
    bool clearStatusFilter = false,
  }) {
    return UserListState(
      isLoading: isLoading ?? this.isLoading,
      users: users ?? this.users,
      totalCount: totalCount ?? this.totalCount,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedRoleId: clearRoleFilter ? null : (selectedRoleId ?? this.selectedRoleId),
      selectedStatus: clearStatusFilter ? null : (selectedStatus ?? this.selectedStatus),
      errorMessage: errorMessage,
      successMessage: successMessage,
    );
  }
}

class UserListNotifier extends StateNotifier<UserListState> {
  final UserRepository _repository;

  UserListNotifier(this._repository) : super(const UserListState()) {
    loadUsers();
  }

  Future<void> loadUsers() async {
    state = state.copyWith(isLoading: true, errorMessage: null, successMessage: null);
    try {
      final result = await _repository.getUsers(
        search: state.searchQuery.isEmpty ? null : state.searchQuery,
        roleId: state.selectedRoleId,
        isActive: state.selectedStatus,
      );

      state = state.copyWith(
        isLoading: false,
        users: result.items,
        totalCount: result.totalCount,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceAll("Exception: ", ""),
      );
    }
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
    loadUsers();
  }

  void setRoleFilter(int? roleId) {
    state = state.copyWith(
      selectedRoleId: roleId,
      clearRoleFilter: roleId == null || roleId == 0,
    );
    loadUsers();
  }

  void setStatusFilter(bool? isActive) {
    state = state.copyWith(
      selectedStatus: isActive,
      clearStatusFilter: isActive == null,
    );
    loadUsers();
  }

  Future<bool> createUser(Map<String, dynamic> data) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _repository.createUser(data);
      state = state.copyWith(
        isLoading: false,
        successMessage: "User created successfully",
      );
      await loadUsers();
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceAll("Exception: ", ""),
      );
      return false;
    }
  }

  Future<bool> updateUser(int id, Map<String, dynamic> data) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _repository.updateUser(id, data);
      state = state.copyWith(
        isLoading: false,
        successMessage: "User updated successfully",
      );
      await loadUsers();
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceAll("Exception: ", ""),
      );
      return false;
    }
  }

  Future<bool> toggleUserStatus(int id, bool newStatus) async {
    try {
      final ok = await _repository.updateUserStatus(id, newStatus);
      if (ok) {
        state = state.copyWith(
          successMessage: "User status updated to ${newStatus ? 'Active' : 'Inactive'}",
        );
        await loadUsers();
        return true;
      }
      return false;
    } catch (e) {
      state = state.copyWith(
        errorMessage: e.toString().replaceAll("Exception: ", ""),
      );
      return false;
    }
  }
}

final userListNotifierProvider = StateNotifierProvider<UserListNotifier, UserListState>((ref) {
  final repo = ref.watch(userRepositoryProvider);
  return UserListNotifier(repo);
});

final rolesProvider = FutureProvider<List<RoleModel>>((ref) async {
  final repo = ref.watch(userRepositoryProvider);
  return repo.getRoles();
});

final permissionsProvider = FutureProvider<List<PermissionModel>>((ref) async {
  final repo = ref.watch(userRepositoryProvider);
  return repo.getPermissions();
});

final auditLogsProvider = FutureProvider<List<LoginAuditLogModel>>((ref) async {
  final repo = ref.watch(userRepositoryProvider);
  return repo.getAuditLogs(limit: 50);
});

