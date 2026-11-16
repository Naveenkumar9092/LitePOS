import "package:flutter_riverpod/flutter_riverpod.dart";
import "../data/customer_repository.dart";
import "../models/customer_model.dart";

final customerNotifierProvider = StateNotifierProvider<CustomerNotifier, CustomerState>((ref) {
  final repo = ref.watch(customerRepositoryProvider);
  return CustomerNotifier(repo);
});

class CustomerState {
  final bool isLoading;
  final bool isActionLoading;
  final String? errorMessage;
  final String? successMessage;
  final List<CustomerModel> customers;
  final String searchQuery;
  final int page;
  final int pageSize;
  final int totalCount;
  final int totalPages;
  final CustomerPurchaseHistoryModel? selectedCustomerHistory;

  const CustomerState({
    this.isLoading = false,
    this.isActionLoading = false,
    this.errorMessage,
    this.successMessage,
    this.customers = const [],
    this.searchQuery = "",
    this.page = 1,
    this.pageSize = 20,
    this.totalCount = 0,
    this.totalPages = 1,
    this.selectedCustomerHistory,
  });

  CustomerState copyWith({
    bool? isLoading,
    bool? isActionLoading,
    String? errorMessage,
    String? successMessage,
    List<CustomerModel>? customers,
    String? searchQuery,
    int? page,
    int? pageSize,
    int? totalCount,
    int? totalPages,
    CustomerPurchaseHistoryModel? selectedCustomerHistory,
  }) {
    return CustomerState(
      isLoading: isLoading ?? this.isLoading,
      isActionLoading: isActionLoading ?? this.isActionLoading,
      errorMessage: errorMessage,
      successMessage: successMessage,
      customers: customers ?? this.customers,
      searchQuery: searchQuery ?? this.searchQuery,
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
      totalCount: totalCount ?? this.totalCount,
      totalPages: totalPages ?? this.totalPages,
      selectedCustomerHistory: selectedCustomerHistory ?? this.selectedCustomerHistory,
    );
  }
}

class CustomerNotifier extends StateNotifier<CustomerState> {
  final CustomerRepository _repository;

  CustomerNotifier(this._repository) : super(const CustomerState()) {
    loadCustomers();
  }

  Future<void> loadCustomers({String? search, int page = 1}) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    final query = search ?? state.searchQuery;
    final res = await _repository.getCustomers(
      search: query.isEmpty ? null : query,
      page: page,
      size: state.pageSize,
    );

    if (res.success && res.data != null) {
      state = state.copyWith(
        isLoading: false,
        customers: res.data!.items,
        page: res.data!.pageNumber,
        totalCount: res.data!.totalCount,
        totalPages: res.data!.totalPages,
        searchQuery: query,
      );
    } else {
      state = state.copyWith(
        isLoading: false,
        errorMessage: res.message,
      );
    }
  }

  void onSearchChanged(String query) {
    state = state.copyWith(searchQuery: query);
    loadCustomers(search: query, page: 1);
  }

  Future<bool> createCustomer(CreateCustomerRequest request) async {
    state = state.copyWith(isActionLoading: true);
    final res = await _repository.createCustomer(request);

    if (res.success) {
      await loadCustomers(page: 1);
      state = state.copyWith(
        isActionLoading: false,
        successMessage: "Customer created successfully.",
      );
      return true;
    }

    state = state.copyWith(
      isActionLoading: false,
      errorMessage: res.message,
    );
    return false;
  }

  Future<bool> updateCustomer(int id, UpdateCustomerRequest request) async {
    state = state.copyWith(isActionLoading: true);
    final res = await _repository.updateCustomer(id, request);

    if (res.success) {
      await loadCustomers(page: state.page);
      state = state.copyWith(
        isActionLoading: false,
        successMessage: "Customer profile updated successfully.",
      );
      return true;
    }

    state = state.copyWith(
      isActionLoading: false,
      errorMessage: res.message,
    );
    return false;
  }

  Future<void> loadCustomerHistory(int customerId) async {
    state = state.copyWith(isActionLoading: true);
    final res = await _repository.getPurchaseHistory(customerId);

    state = state.copyWith(
      isActionLoading: false,
      selectedCustomerHistory: res.data,
      errorMessage: !res.success ? res.message : null,
    );
  }

  void clearMessages() {
    state = state.copyWith(errorMessage: null, successMessage: null);
  }
}

