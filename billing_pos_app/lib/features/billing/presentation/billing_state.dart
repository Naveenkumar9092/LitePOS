import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:billing_pos_app/features/company/data/company_repository.dart";
import "../data/billing_repository.dart";
import "../models/billing_invoice_model.dart";
import "cart_state.dart";

final billingRepositoryProvider = Provider<BillingRepository>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  final db = ref.watch(appDatabaseProvider);
  return BillingRepository(dioClient, db);
});

class BillingState {
  final bool isProcessing;
  final bool isLoadingHeld;
  final List<BillingInvoiceModel> heldBills;
  final BillingInvoiceModel? lastCreatedInvoice;
  final String? errorMessage;
  final String? successMessage;

  const BillingState({
    this.isProcessing = false,
    this.isLoadingHeld = false,
    this.heldBills = const [],
    this.lastCreatedInvoice,
    this.errorMessage,
    this.successMessage,
  });

  BillingState copyWith({
    bool? isProcessing,
    bool? isLoadingHeld,
    List<BillingInvoiceModel>? heldBills,
    BillingInvoiceModel? lastCreatedInvoice,
    String? errorMessage,
    String? successMessage,
    bool clearLastInvoice = false,
    bool clearMessages = false,
  }) {
    return BillingState(
      isProcessing: isProcessing ?? this.isProcessing,
      isLoadingHeld: isLoadingHeld ?? this.isLoadingHeld,
      heldBills: heldBills ?? this.heldBills,
      lastCreatedInvoice: clearLastInvoice ? null : (lastCreatedInvoice ?? this.lastCreatedInvoice),
      errorMessage: clearMessages ? null : (errorMessage ?? this.errorMessage),
      successMessage: clearMessages ? null : (successMessage ?? this.successMessage),
    );
  }
}

class BillingNotifier extends StateNotifier<BillingState> {
  final BillingRepository _repository;
  final Ref _ref;

  BillingNotifier(this._repository, this._ref) : super(const BillingState()) {
    loadHeldBills();
  }

  Future<void> loadHeldBills() async {
    state = state.copyWith(isLoadingHeld: true, clearMessages: true);
    try {
      final bills = await _repository.getHeldBills();
      state = state.copyWith(
        isLoadingHeld: false,
        heldBills: bills,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingHeld: false,
        errorMessage: "Failed to load held bills: ${e.toString().replaceFirst('Exception: ', '')}",
      );
    }
  }

  Future<BillingInvoiceModel?> checkout({
    required CartState cart,
    required double paidAmount,
    required int paymentMode,
    String? transactionReference,
  }) async {
    if (cart.isEmpty) {
      state = state.copyWith(errorMessage: "Cart cannot be empty for checkout.");
      return null;
    }

    state = state.copyWith(isProcessing: true, clearMessages: true);
    try {
      final invoice = await _repository.createInvoice(
        customerId: cart.customerId,
        deviceId: "POS-TERMINAL-01",
        items: cart.items,
        discountAmount: cart.effectiveDiscount,
        paidAmount: paidAmount,
        paymentMode: paymentMode,
        transactionReference: transactionReference,
      );

      // Clear the cart on successful checkout
      _ref.read(cartNotifierProvider.notifier).clearCart();

      state = state.copyWith(
        isProcessing: false,
        lastCreatedInvoice: invoice,
        successMessage: "Invoice '${invoice.invoiceNumber}' generated successfully!",
      );
      return invoice;
    } catch (e) {
      state = state.copyWith(
        isProcessing: false,
        errorMessage: e.toString().replaceFirst("Exception: ", ""),
      );
      return null;
    }
  }

  Future<bool> holdBill(CartState cart) async {
    if (cart.isEmpty) {
      state = state.copyWith(errorMessage: "Cannot hold an empty cart.");
      return false;
    }

    state = state.copyWith(isProcessing: true, clearMessages: true);
    try {
      final held = await _repository.holdBill(
        customerId: cart.customerId,
        deviceId: "POS-TERMINAL-01",
        note: cart.note,
        items: cart.items,
        discountAmount: cart.effectiveDiscount,
      );

      // Clear the current active cart
      _ref.read(cartNotifierProvider.notifier).clearCart();

      final updatedHeld = [held, ...state.heldBills];

      state = state.copyWith(
        isProcessing: false,
        heldBills: updatedHeld,
        successMessage: "Bill '${held.invoiceNumber}' placed on hold.",
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isProcessing: false,
        errorMessage: e.toString().replaceFirst("Exception: ", ""),
      );
      return false;
    }
  }

  Future<bool> resumeHeldBill(BillingInvoiceModel heldBill) async {
    state = state.copyWith(isProcessing: true, clearMessages: true);
    try {
      final invoice = await _repository.resumeBill(heldBill.invoiceId);

      // Load invoice into active cart
      _ref.read(cartNotifierProvider.notifier).loadFromInvoice(invoice);

      // Remove from held list
      final updatedHeld = state.heldBills.where((b) => b.invoiceId != heldBill.invoiceId).toList();

      state = state.copyWith(
        isProcessing: false,
        heldBills: updatedHeld,
        successMessage: "Resumed bill '${invoice.invoiceNumber}'.",
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isProcessing: false,
        errorMessage: e.toString().replaceFirst("Exception: ", ""),
      );
      return false;
    }
  }

  void clearMessages() {
    state = state.copyWith(clearMessages: true);
  }
}

final billingNotifierProvider = StateNotifierProvider<BillingNotifier, BillingState>((ref) {
  final repo = ref.watch(billingRepositoryProvider);
  return BillingNotifier(repo, ref);
});
