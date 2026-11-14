import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:billing_pos_app/features/company/data/company_repository.dart";
import "../data/payment_repository.dart";
import "../models/payment_models.dart";

final paymentRepositoryProvider = Provider<PaymentRepository>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  final db = ref.watch(appDatabaseProvider);
  return PaymentRepository(dioClient, db);
});

class PaymentState {
  final bool isLoading;
  final bool isActionLoading;
  final List<PaymentTransactionModel> payments;
  final PaymentReconciliationModel? reconciliation;
  final CashRegisterSessionModel? activeRegisterSession;
  final PaymentModeEnum? filterMode;
  final String searchQuery;
  final String? errorMessage;
  final String? successMessage;
  final int totalCount;
  final int page;

  const PaymentState({
    this.isLoading = false,
    this.isActionLoading = false,
    this.payments = const [],
    this.reconciliation,
    this.activeRegisterSession,
    this.filterMode,
    this.searchQuery = "",
    this.errorMessage,
    this.successMessage,
    this.totalCount = 0,
    this.page = 1,
  });

  List<PaymentTransactionModel> get displayedPayments {
    return payments.where((p) {
      if (filterMode != null && p.paymentMode != filterMode) return false;
      if (searchQuery.isNotEmpty) {
        final q = searchQuery.toLowerCase();
        final matchInv = p.invoiceNumber.toLowerCase().contains(q);
        final matchRef = p.transactionReference?.toLowerCase().contains(q) ?? false;
        final matchCust = p.customerName?.toLowerCase().contains(q) ?? false;
        if (!matchInv && !matchRef && !matchCust) return false;
      }
      return true;
    }).toList();
  }

  PaymentState copyWith({
    bool? isLoading,
    bool? isActionLoading,
    List<PaymentTransactionModel>? payments,
    PaymentReconciliationModel? reconciliation,
    CashRegisterSessionModel? activeRegisterSession,
    PaymentModeEnum? filterMode,
    String? searchQuery,
    String? errorMessage,
    String? successMessage,
    int? totalCount,
    int? page,
    bool clearActiveSession = false,
    bool clearFilterMode = false,
    bool clearMessages = false,
  }) {
    return PaymentState(
      isLoading: isLoading ?? this.isLoading,
      isActionLoading: isActionLoading ?? this.isActionLoading,
      payments: payments ?? this.payments,
      reconciliation: reconciliation ?? this.reconciliation,
      activeRegisterSession: clearActiveSession ? null : (activeRegisterSession ?? this.activeRegisterSession),
      filterMode: clearFilterMode ? null : (filterMode ?? this.filterMode),
      searchQuery: searchQuery ?? this.searchQuery,
      errorMessage: clearMessages ? null : (errorMessage ?? this.errorMessage),
      successMessage: clearMessages ? null : (successMessage ?? this.successMessage),
      totalCount: totalCount ?? this.totalCount,
      page: page ?? this.page,
    );
  }
}

class PaymentNotifier extends StateNotifier<PaymentState> {
  final PaymentRepository _repository;

  PaymentNotifier(this._repository) : super(const PaymentState()) {
    loadData();
  }

  Future<void> loadData() async {
    await Future.wait([
      loadPayments(),
      loadReconciliation(),
    ]);
  }

  Future<void> loadPayments({bool refresh = false}) async {
    state = state.copyWith(isLoading: true, clearMessages: true);

    final res = await _repository.getPayments(
      mode: state.filterMode,
      search: state.searchQuery,
      page: refresh ? 1 : state.page,
      pageSize: 50,
    );

    if (res.success && res.data != null) {
      state = state.copyWith(
        isLoading: false,
        payments: res.data!.items,
        totalCount: res.data!.totalCount,
      );
    } else {
      state = state.copyWith(
        isLoading: false,
        errorMessage: res.message.isNotEmpty ? res.message : "Failed to load payments.",
      );
    }
  }

  Future<void> loadReconciliation({DateTime? date}) async {
    final res = await _repository.getReconciliation(date: date);
    if (res.success && res.data != null) {
      state = state.copyWith(reconciliation: res.data);
    }
  }

  Future<bool> openRegister(double floatAmount, {String? notes}) async {
    state = state.copyWith(isActionLoading: true, clearMessages: true);

    final res = await _repository.openCashRegister(OpenRegisterRequest(
      openingFloat: floatAmount,
      notes: notes,
    ));

    if (res.success && res.data != null) {
      state = state.copyWith(
        isActionLoading: false,
        activeRegisterSession: res.data,
        successMessage: "Cash register opened with ₹${floatAmount.toStringAsFixed(2)} opening float.",
      );
      await loadReconciliation();
      return true;
    } else {
      state = state.copyWith(
        isActionLoading: false,
        errorMessage: res.message.isNotEmpty ? res.message : "Failed to open register.",
      );
      return false;
    }
  }

  Future<bool> closeRegister(double actualCash, {String? notes}) async {
    state = state.copyWith(isActionLoading: true, clearMessages: true);

    final res = await _repository.closeCashRegister(CloseRegisterRequest(
      actualCash: actualCash,
      notes: notes,
    ));

    if (res.success && res.data != null) {
      state = state.copyWith(
        isActionLoading: false,
        clearActiveSession: true,
        successMessage: "Cash register closed. Counted: ₹${actualCash.toStringAsFixed(2)}",
      );
      await loadReconciliation();
      return true;
    } else {
      state = state.copyWith(
        isActionLoading: false,
        errorMessage: res.message.isNotEmpty ? res.message : "Failed to close register.",
      );
      return false;
    }
  }

  Future<bool> processRefund(int invoiceId, double amount, String reason, {int? paymentId}) async {
    state = state.copyWith(isActionLoading: true, clearMessages: true);

    final res = await _repository.processRefund(ProcessRefundRequest(
      invoiceId: invoiceId,
      paymentId: paymentId,
      amount: amount,
      reason: reason,
    ));

    if (res.success && res.data != null) {
      state = state.copyWith(
        isActionLoading: false,
        successMessage: "Refund of ₹${amount.toStringAsFixed(2)} processed successfully.",
      );
      await loadData();
      return true;
    } else {
      state = state.copyWith(
        isActionLoading: false,
        errorMessage: res.message.isNotEmpty ? res.message : "Failed to process refund.",
      );
      return false;
    }
  }

  void setFilterMode(PaymentModeEnum? mode) {
    if (mode == null) {
      state = state.copyWith(clearFilterMode: true);
    } else {
      state = state.copyWith(filterMode: mode);
    }
    loadPayments(refresh: true);
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
    loadPayments(refresh: true);
  }

  void clearMessages() {
    state = state.copyWith(clearMessages: true);
  }
}

final paymentStateProvider = StateNotifierProvider<PaymentNotifier, PaymentState>((ref) {
  final repository = ref.watch(paymentRepositoryProvider);
  return PaymentNotifier(repository);
});

