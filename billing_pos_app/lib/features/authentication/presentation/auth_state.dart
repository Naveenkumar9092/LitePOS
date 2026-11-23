import "package:flutter_riverpod/flutter_riverpod.dart";
import "../../company/data/company_repository.dart";
import "../data/auth_repository.dart";
import "../models/user_model.dart";

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  final storage = ref.watch(storageServiceProvider);
  final db = ref.watch(appDatabaseProvider);
  return AuthRepository(dioClient, storage, db);
});

class AuthState {
  final bool isLoading;
  final bool isAuthenticated;
  final UserModel? user;
  final List<String> permissions;
  final String? errorMessage;
  final bool isOffline;

  const AuthState({
    this.isLoading = false,
    this.isAuthenticated = false,
    this.user,
    this.permissions = const [],
    this.errorMessage,
    this.isOffline = false,
  });

  AuthState copyWith({
    bool? isLoading,
    bool? isAuthenticated,
    UserModel? user,
    List<String>? permissions,
    String? errorMessage,
    bool? isOffline,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      user: user ?? this.user,
      permissions: permissions ?? this.permissions,
      errorMessage: errorMessage,
      isOffline: isOffline ?? this.isOffline,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repository;

  AuthNotifier(this._repository, [UserModel? initialUser])
      : super(
          initialUser != null
              ? AuthState(
                  isAuthenticated: true,
                  user: initialUser,
                  isOffline: true,
                )
              : const AuthState(),
        ) {
    checkInitialAuth();
  }

  Future<void> checkInitialAuth() async {
    final cached = await _repository.getCachedUser();
    if (cached != null) {
      if (cached.isSAdmin) {
        // Super Administrator strictly requires an active internet connection
        final online = await _repository.isOnline();
        if (!online) {
          state = state.copyWith(
            isAuthenticated: false,
            user: null,
            errorMessage: "Super Administrator requires an active internet connection.",
          );
          return;
        }
      }
      state = state.copyWith(
        isAuthenticated: true,
        user: cached,
      );
    }
  }

  Future<bool> login(String username, String password, {bool forceOffline = false}) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final authResponse = await _repository.login(
        username: username,
        password: password,
        forceOffline: forceOffline,
      );
      state = state.copyWith(
        isLoading: false,
        isAuthenticated: true,
        user: authResponse.user,
        permissions: authResponse.permissions,
        isOffline: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceAll("Exception: ", ""),
      );
      return false;
    }
  }

  Future<void> logout() async {
    await _repository.logout();
    state = const AuthState();
  }

  Future<bool> changePassword(String currentPassword, String newPassword, String confirmPassword) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final ok = await _repository.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
        confirmPassword: confirmPassword,
      );
      state = state.copyWith(isLoading: false);
      return ok;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceAll("Exception: ", ""),
      );
      return false;
    }
  }

  Future<bool> forgotPassword(String usernameOrEmail) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final ok = await _repository.forgotPassword(usernameOrEmail);
      state = state.copyWith(isLoading: false);
      return ok;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceAll("Exception: ", ""),
      );
      return false;
    }
  }
}

final initialUserProvider = Provider<UserModel?>((ref) => null);

final authNotifierProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  final initialUser = ref.watch(initialUserProvider);
  return AuthNotifier(repo, initialUser);
});

