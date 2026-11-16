import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:billing_pos_app/features/company/data/company_repository.dart";
import "../data/order_repository.dart";
import "../models/order_model.dart";

final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  final db = ref.watch(appDatabaseProvider);
  return OrderRepository(dioClient, db);
});

class OrderState {
  final bool isLoading;
  final bool isActionLoading;
  final List<OrderModel> orders;
  final List<OrderModel> historyOrders;
  final OrderModel? selectedOrder;
  final OrderStatusEnum? filterStatus;
  final OrderTypeEnum? filterType;
  final String searchQuery;
  final String? errorMessage;
  final String? successMessage;
  final int totalCount;
  final int page;
  final int totalPages;
  final bool isHistoryMode;

  const OrderState({
    this.isLoading = false,
    this.isActionLoading = false,
    this.orders = const [],
    this.historyOrders = const [],
    this.selectedOrder,
    this.filterStatus,
    this.filterType,
    this.searchQuery = "",
    this.errorMessage,
    this.successMessage,
    this.totalCount = 0,
    this.page = 1,
    this.totalPages = 1,
    this.isHistoryMode = false,
  });

  List<OrderModel> get displayedOrders {
    final source = isHistoryMode ? historyOrders : orders;
    return source.where((o) {
      if (filterStatus != null && o.orderStatus != filterStatus) return false;
      if (filterType != null && o.orderType != filterType) return false;
      if (searchQuery.isNotEmpty) {
        final query = searchQuery.toLowerCase();
        final matchNum = o.orderNumber.toLowerCase().contains(query);
        final matchCust = o.customerName?.toLowerCase().contains(query) ?? false;
        final matchPhone = o.customerMobile?.contains(query) ?? false;
        final matchCashier = o.cashierUsername.toLowerCase().contains(query);
        if (!matchNum && !matchCust && !matchPhone && !matchCashier) return false;
      }
      return true;
    }).toList();
  }

  OrderState copyWith({
    bool? isLoading,
    bool? isActionLoading,
    List<OrderModel>? orders,
    List<OrderModel>? historyOrders,
    OrderModel? selectedOrder,
    OrderStatusEnum? filterStatus,
    OrderTypeEnum? filterType,
    String? searchQuery,
    String? errorMessage,
    String? successMessage,
    int? totalCount,
    int? page,
    int? totalPages,
    bool? isHistoryMode,
    bool clearSelectedOrder = false,
    bool clearFilterStatus = false,
    bool clearFilterType = false,
    bool clearMessages = false,
  }) {
    return OrderState(
      isLoading: isLoading ?? this.isLoading,
      isActionLoading: isActionLoading ?? this.isActionLoading,
      orders: orders ?? this.orders,
      historyOrders: historyOrders ?? this.historyOrders,
      selectedOrder: clearSelectedOrder ? null : (selectedOrder ?? this.selectedOrder),
      filterStatus: clearFilterStatus ? null : (filterStatus ?? this.filterStatus),
      filterType: clearFilterType ? null : (filterType ?? this.filterType),
      searchQuery: searchQuery ?? this.searchQuery,
      errorMessage: clearMessages ? null : (errorMessage ?? this.errorMessage),
      successMessage: clearMessages ? null : (successMessage ?? this.successMessage),
      totalCount: totalCount ?? this.totalCount,
      page: page ?? this.page,
      totalPages: totalPages ?? this.totalPages,
      isHistoryMode: isHistoryMode ?? this.isHistoryMode,
    );
  }
}

class OrderNotifier extends StateNotifier<OrderState> {
  final OrderRepository _repository;

  OrderNotifier(this._repository) : super(const OrderState()) {
    loadOrders();
  }

  Future<void> loadOrders({bool refresh = false}) async {
    state = state.copyWith(
      isLoading: true,
      clearMessages: true,
      page: refresh ? 1 : state.page,
    );

    final params = OrderFilterParams(
      status: state.filterStatus,
      type: state.filterType,
      searchTerm: state.searchQuery,
      page: refresh ? 1 : state.page,
      pageSize: 50,
    );

    final result = await _repository.getOrders(params);
    if (result.success && result.data != null) {
      state = state.copyWith(
        isLoading: false,
        orders: result.data!.items,
        totalCount: result.data!.totalCount,
        totalPages: result.data!.totalPages,
      );
    } else {
      state = state.copyWith(
        isLoading: false,
        errorMessage: result.message.isNotEmpty ? result.message : "Failed to load orders.",
      );
    }
  }

  Future<void> loadHistory() async {
    state = state.copyWith(isLoading: true, clearMessages: true);

    final params = OrderFilterParams(
      type: state.filterType,
      searchTerm: state.searchQuery,
      page: 1,
      pageSize: 50,
    );

    final result = await _repository.getOrderHistory(params);
    if (result.success && result.data != null) {
      state = state.copyWith(
        isLoading: false,
        historyOrders: result.data!.items,
      );
    } else {
      state = state.copyWith(
        isLoading: false,
        errorMessage: result.message.isNotEmpty ? result.message : "Failed to load order history.",
      );
    }
  }

  void setHistoryMode(bool isHistory) {
    state = state.copyWith(isHistoryMode: isHistory, clearMessages: true);
    if (isHistory) {
      loadHistory();
    } else {
      loadOrders();
    }
  }

  void setFilterStatus(OrderStatusEnum? status) {
    if (status == null) {
      state = state.copyWith(clearFilterStatus: true);
    } else {
      state = state.copyWith(filterStatus: status);
    }
    loadOrders(refresh: true);
  }

  void setFilterType(OrderTypeEnum? type) {
    if (type == null) {
      state = state.copyWith(clearFilterType: true);
    } else {
      state = state.copyWith(filterType: type);
    }
    loadOrders(refresh: true);
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
    loadOrders(refresh: true);
  }

  void selectOrder(OrderModel? order) {
    if (order == null) {
      state = state.copyWith(clearSelectedOrder: true);
    } else {
      state = state.copyWith(selectedOrder: order);
    }
  }

  Future<bool> createOrder(CreateOrderRequest request) async {
    state = state.copyWith(isActionLoading: true, clearMessages: true);

    final result = await _repository.createOrder(request);
    if (result.success && result.data != null) {
      state = state.copyWith(
        isActionLoading: false,
        successMessage: "Order #${result.data!.orderNumber} created successfully.",
      );
      await loadOrders(refresh: true);
      return true;
    } else {
      state = state.copyWith(
        isActionLoading: false,
        errorMessage: result.message.isNotEmpty ? result.message : "Failed to create order.",
      );
      return false;
    }
  }

  Future<bool> updateOrderStatus(int id, OrderStatusEnum newStatus, {String? notes}) async {
    state = state.copyWith(isActionLoading: true, clearMessages: true);

    final result = await _repository.updateOrderStatus(id, newStatus, notes: notes);
    if (result.success && result.data != null) {
      final updatedOrder = result.data!;
      final updatedList = state.orders.map((o) => o.id == id ? updatedOrder : o).toList();
      state = state.copyWith(
        isActionLoading: false,
        orders: updatedList,
        selectedOrder: state.selectedOrder?.id == id ? updatedOrder : state.selectedOrder,
        successMessage: "Order #${updatedOrder.orderNumber} updated to ${newStatus.label}.",
      );
      return true;
    } else {
      state = state.copyWith(
        isActionLoading: false,
        errorMessage: result.message.isNotEmpty ? result.message : "Failed to update order status.",
      );
      return false;
    }
  }

  Future<bool> cancelOrder(int id, String reason) async {
    state = state.copyWith(isActionLoading: true, clearMessages: true);

    final result = await _repository.cancelOrder(id, reason);
    if (result.success && result.data != null) {
      final updatedOrder = result.data!;
      final updatedList = state.orders.map((o) => o.id == id ? updatedOrder : o).toList();
      state = state.copyWith(
        isActionLoading: false,
        orders: updatedList,
        selectedOrder: state.selectedOrder?.id == id ? updatedOrder : state.selectedOrder,
        successMessage: "Order #${updatedOrder.orderNumber} was cancelled.",
      );
      return true;
    } else {
      state = state.copyWith(
        isActionLoading: false,
        errorMessage: result.message.isNotEmpty ? result.message : "Failed to cancel order.",
      );
      return false;
    }
  }

  void clearMessages() {
    state = state.copyWith(clearMessages: true);
  }
}

final orderStateProvider = StateNotifierProvider<OrderNotifier, OrderState>((ref) {
  final repository = ref.watch(orderRepositoryProvider);
  return OrderNotifier(repository);
});

