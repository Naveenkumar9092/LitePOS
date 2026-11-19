import "dart:async";
import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:go_router/go_router.dart";
import "package:google_fonts/google_fonts.dart";
import "package:intl/intl.dart";
import "package:billing_pos_app/core/constants/api_endpoints.dart";
import "package:billing_pos_app/core/routing/route_names.dart";
import "package:billing_pos_app/core/theme/app_colors.dart";
import "package:billing_pos_app/core/utilities/currency_formatter.dart";
import "package:billing_pos_app/shared/widgets/app_loader.dart";
import "../../authentication/presentation/auth_state.dart";
import "../../categories/presentation/category_state.dart";
import "../../customers/presentation/customer_state.dart";
import "../../customers/presentation/widgets/customer_form_dialog.dart";
import "../../products/models/product_model.dart";
import "../../products/presentation/product_state.dart";
import "billing_state.dart";
import "cart_state.dart";
import "package:billing_pos_app/shared/widgets/app_toast.dart";
import "widgets/held_bills_dialog.dart";
import "widgets/payment_dialog.dart";
import "widgets/receipt_preview_dialog.dart";
import "widgets/reprint_invoice_dialog.dart";

class PosBillingScreen extends ConsumerStatefulWidget {
  const PosBillingScreen({super.key});

  @override
  ConsumerState<PosBillingScreen> createState() => _PosBillingScreenState();
}

class _PosBillingScreenState extends ConsumerState<PosBillingScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _productsScrollController = ScrollController();
  final ScrollController _cartScrollController = ScrollController();
  final ScrollController _categoryNavScrollController = ScrollController();
  final ScrollController _categoryBarScrollController = ScrollController();
  int? _selectedCategoryId;

  @override
  void dispose() {
    _searchController.dispose();
    _productsScrollController.dispose();
    _cartScrollController.dispose();
    _categoryNavScrollController.dispose();
    _categoryBarScrollController.dispose();
    super.dispose();
  }

  void _openHeldBillsDialog() {
    showDialog(
      context: context,
      builder: (_) => const HeldBillsDialog(),
    );
  }

  void _openReprintDialog() {
    showDialog(
      context: context,
      builder: (_) => const ReprintInvoiceDialog(),
    );
  }

  void _navigateToDashboard(AuthState authState) {
    final user = authState.user;
    if (user != null) {
      if (user.isCashier) {
        context.go(RouteNames.cashierDashboard);
      } else if (user.isSAdmin) {
        context.go(RouteNames.sadminDashboard);
      } else {
        context.go(RouteNames.adminDashboard);
      }
    } else {
      if (context.canPop()) {
        context.pop();
      } else {
        context.go(RouteNames.cashierDashboard);
      }
    }
  }

  Future<void> _handleHoldBill() async {
    final cart = ref.read(cartNotifierProvider);
    if (cart.isEmpty) {
      AppToast.showWarning(context, "Cannot hold an empty cart");
      return;
    }

    final success = await ref.read(billingNotifierProvider.notifier).holdBill(cart);
    if (mounted) {
      if (success) {
        AppToast.showSuccess(context, "Bill placed on hold successfully");
      } else {
        AppToast.showError(context, "Failed to place bill on hold");
      }
    }
  }

  Future<void> _handlePayment() async {
    final cart = ref.read(cartNotifierProvider);
    if (cart.isEmpty) {
      AppToast.showWarning(context, "Cart is empty. Tap products to add items to bill.");
      return;
    }

    final result = await showDialog<PaymentDialogResult>(
      context: context,
      barrierDismissible: false,
      builder: (_) => PaymentDialog(totalAmount: cart.grandTotal),
    );

    if (result != null && mounted) {
      final invoice = await ref.read(billingNotifierProvider.notifier).checkout(
            cart: cart,
            paidAmount: result.paidAmount,
            paymentMode: result.paymentMode,
            transactionReference: result.transactionReference,
          );

      if (invoice != null && mounted) {
        AppToast.showSuccess(context, "Sale completed! Invoice #${invoice.invoiceNumber}");
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => ReceiptPreviewDialog(invoice: invoice),
        );
      }
    }
  }

  void _showCustomerSelector() {
    final customerState = ref.read(customerNotifierProvider);
    final cartNotifier = ref.read(cartNotifierProvider.notifier);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final customers = customerState.customers;
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              constraints: const BoxConstraints(maxHeight: 460),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.person_pin_circle_rounded, color: AppColors.primary, size: 24),
                          const SizedBox(width: 8),
                          Text(
                            "Select Customer for Invoice",
                            style: GoogleFonts.dmSans(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.of(ctx).pop(),
                      ),
                    ],
                  ),
                  const Divider(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.person_off_outlined, size: 16),
                          label: Text("Walk-in Customer", style: GoogleFonts.dmSans(fontWeight: FontWeight.w600)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.textSecondary,
                            side: const BorderSide(color: Color(0xFFCBD5E1)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          onPressed: () {
                            cartNotifier.clearCustomer();
                            Navigator.of(ctx).pop();
                            AppToast.showInfo(context, "Switched to Walk-in Customer");
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.person_add_rounded, size: 16),
                          label: Text("+ New Customer", style: GoogleFonts.dmSans(fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          onPressed: () async {
                            Navigator.of(ctx).pop();
                            await showDialog(
                              context: context,
                              builder: (_) => const CustomerFormDialog(),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text("REGISTERED CUSTOMERS", style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary, letterSpacing: 0.8)),
                  const SizedBox(height: 8),
                  Expanded(
                    child: customers.isEmpty
                        ? Center(
                            child: Text("No registered customers found.", style: GoogleFonts.dmSans(color: Colors.grey)),
                          )
                        : ListView.separated(
                            itemCount: customers.length,
                            separatorBuilder: (_, __) => const Divider(height: 8),
                            itemBuilder: (context, idx) {
                              final c = customers[idx];
                              return ListTile(
                                dense: true,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                leading: CircleAvatar(
                                  backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                                  child: Text(
                                    c.customerName.isNotEmpty ? c.customerName[0].toUpperCase() : "C",
                                    style: GoogleFonts.dmSans(fontWeight: FontWeight.bold, color: AppColors.primary),
                                  ),
                                ),
                                title: Text(c.customerName, style: GoogleFonts.dmSans(fontWeight: FontWeight.bold, fontSize: 13)),
                                subtitle: Text(c.mobileNumber, style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.textSecondary)),
                                trailing: const Icon(Icons.check_circle_outline, color: AppColors.primary, size: 20),
                                onTap: () {
                                  cartNotifier.setCustomer(c.id, c.customerName);
                                  Navigator.of(ctx).pop();
                                  AppToast.showSuccess(context, "Customer '${c.customerName}' linked to bill");
                                },
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showDiscountDialog() {
    final cart = ref.read(cartNotifierProvider);
    final controller = TextEditingController(
      text: cart.discountAmount > 0 ? cart.discountAmount.toStringAsFixed(2) : "",
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.discount_rounded, color: AppColors.primary, size: 22),
            const SizedBox(width: 8),
            Text("Apply Cart Discount", style: GoogleFonts.dmSans(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Quick Presets:", style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [10.0, 20.0, 50.0, 100.0].map((preset) {
                return ActionChip(
                  label: Text("₹$preset", style: GoogleFonts.dmSans(fontWeight: FontWeight.bold, fontSize: 12)),
                  backgroundColor: const Color(0xFFEBF4F6),
                  side: const BorderSide(color: Color(0xFFCCE4E9)),
                  onPressed: () {
                    controller.text = preset.toStringAsFixed(2);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: "Discount Amount (₹)",
                labelStyle: GoogleFonts.dmSans(),
                prefixText: "₹ ",
                prefixStyle: GoogleFonts.dmSans(fontWeight: FontWeight.bold),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.primary, width: 2),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              ref.read(cartNotifierProvider.notifier).setDiscount(0.0);
              Navigator.of(ctx).pop();
              AppToast.showInfo(context, "Discount cleared");
            },
            child: Text("Remove", style: GoogleFonts.dmSans(color: AppColors.error, fontWeight: FontWeight.bold)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text("Cancel", style: GoogleFonts.dmSans(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              final discount = double.tryParse(controller.text.trim()) ?? 0.0;
              ref.read(cartNotifierProvider.notifier).setDiscount(discount);
              Navigator.of(ctx).pop();
              if (discount > 0) {
                AppToast.showSuccess(context, "Discount ₹${discount.toStringAsFixed(2)} applied");
              } else {
                AppToast.showInfo(context, "Discount removed");
              }
            },
            child: Text("Apply Discount", style: GoogleFonts.dmSans(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cartState = ref.watch(cartNotifierProvider);
    final productState = ref.watch(productListNotifierProvider);
    final categoryState = ref.watch(categoryNotifierProvider);
    final billingState = ref.watch(billingNotifierProvider);
    final authState = ref.watch(authNotifierProvider);

    final screenWidth = MediaQuery.sizeOf(context).width;
    final isTabletOrDesktop = screenWidth >= 700;
    final isWideDesktop = screenWidth >= 1150;

    // Filter products by selected category and search query
    final products = productState.products.where((p) {
      if (_selectedCategoryId != null && p.categoryId != _selectedCategoryId) {
        return false;
      }
      if (_searchController.text.isNotEmpty) {
        final q = _searchController.text.toLowerCase();
        final matchName = p.productName.toLowerCase().contains(q);
        final matchHsn = p.hsnCode?.toLowerCase().contains(q) ?? false;
        if (!matchName && !matchHsn) return false;
      }
      return true;
    }).toList();

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          _navigateToDashboard(authState);
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF1F7F9),
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(isTabletOrDesktop ? 66 : 58),
          child: _buildHeader(authState, billingState, cartState, !isTabletOrDesktop),
        ),
        body: isTabletOrDesktop
            ? Row(
                children: [
                  // Left Panel: Vertical Category List (Wide Desktop >= 1150)
                  if (isWideDesktop) ...[
                    SizedBox(
                      width: 210,
                      child: _buildCategoryList(categoryState),
                    ),
                    const VerticalDivider(width: 1, color: Color(0xFFE2E8F0)),
                  ],

                  // Center Panel: Modern Product Grid (with top Category horizontal pills on tablet)
                  Expanded(
                    child: Column(
                      children: [
                        if (!isWideDesktop)
                          Container(
                            color: Colors.white,
                            height: 50,
                            child: _buildCategoryHorizontalBar(categoryState),
                          ),
                        if (!isWideDesktop)
                          const Divider(height: 1, color: Color(0xFFE2E8F0)),
                        Expanded(
                          child: _buildProductCatalog(products, productState.isLoading, cartState),
                        ),
                      ],
                    ),
                  ),
                  const VerticalDivider(width: 1, color: Color(0xFFE2E8F0)),

                  // Right Panel: Active Order Cart & Settlement Box (Visible on Tablet & Desktop)
                  SizedBox(
                    width: screenWidth > 1200 ? 410 : (screenWidth > 950 ? 370 : 330),
                    child: _buildCartPanel(cartState, billingState.isProcessing),
                  ),
                ],
              )
            : Column(
                children: [
                  // Category Pills for Mobile (< 700px)
                  Container(
                    color: Colors.white,
                    height: 52,
                    child: _buildCategoryHorizontalBar(categoryState),
                  ),
                  const Divider(height: 1, color: Color(0xFFE2E8F0)),
                  Expanded(
                    child: _buildProductCatalog(products, productState.isLoading, cartState),
                  ),
                  const Divider(height: 1, color: Color(0xFFE2E8F0)),
                  _buildMobileCartSummary(cartState),
                ],
              ),
      ),
    );
  }

  Widget _buildHeader(AuthState authState, BillingState billingState, CartState cartState, bool isMobile) {
    final cashierName = authState.user?.fullName ?? "Cashier";

    if (isMobile) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(
            bottom: BorderSide(color: Color(0xFFCCE4E9), width: 1.2),
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: AppColors.primaryDark, size: 22),
                tooltip: "Back to Dashboard",
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                onPressed: () => _navigateToDashboard(authState),
              ),
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.point_of_sale_rounded, color: Colors.white, size: 17),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "PulsePOS",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.dmSans(
                        fontWeight: FontWeight.w800,
                        fontSize: 14.5,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.3,
                      ),
                    ),
                    Row(
                      children: [
                        Container(
                          width: 5,
                          height: 5,
                          decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.success),
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            "LIVE SYNC • DEV-POS-01",
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.dmSans(fontSize: 9.5, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              Badge(
                label: Text(
                  "${billingState.heldBills.length}",
                  style: GoogleFonts.dmSans(fontWeight: FontWeight.bold, fontSize: 9.5),
                ),
                isLabelVisible: billingState.heldBills.isNotEmpty,
                backgroundColor: AppColors.warning,
                child: IconButton(
                  icon: const Icon(Icons.pause_circle_outline_rounded, size: 22, color: AppColors.primaryDark),
                  tooltip: "Hold Bills",
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                  onPressed: _openHeldBillsDialog,
                ),
              ),
              const SizedBox(width: 2),
              IconButton(
                icon: const Icon(Icons.print_outlined, size: 22, color: AppColors.primaryDark),
                tooltip: "Reprint Bill",
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                onPressed: _openReprintDialog,
              ),
              const SizedBox(width: 2),
              Badge(
                label: Text(
                  "${cartState.totalItemsCount}",
                  style: GoogleFonts.dmSans(fontWeight: FontWeight.bold, fontSize: 9.5),
                ),
                isLabelVisible: cartState.isNotEmpty,
                backgroundColor: AppColors.primary,
                child: IconButton(
                  icon: const Icon(Icons.shopping_bag_outlined, size: 22, color: AppColors.primaryDark),
                  tooltip: "View Cart",
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                  onPressed: _openMobileCartSheet,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Color(0xFFCCE4E9), width: 1.2),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            // Back to Dashboard Button
            Tooltip(
              message: "Back to Dashboard",
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () => _navigateToDashboard(authState),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F7F9),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFCCE4E9), width: 1.2),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.arrow_back_rounded,
                          color: AppColors.primaryDark,
                          size: 19,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          "Dashboard",
                          style: GoogleFonts.dmSans(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: AppColors.primaryDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Store Logo & Terminal Identifier
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(Icons.point_of_sale_rounded, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          authState.user?.shopName ?? "PulsePOS Store",
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.dmSans(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                            color: AppColors.textPrimary,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.successContainer,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.success),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              "LIVE SYNC",
                              style: GoogleFonts.dmSans(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: AppColors.success,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Text(
                    "Main Store • Terminal DEV-POS-01",
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),

            // Cashier Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFFEBF4F6),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFCCE4E9)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 11,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.20),
                    child: Text(
                      cashierName.isNotEmpty ? cashierName[0].toUpperCase() : "C",
                      style: GoogleFonts.dmSans(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.primaryDark),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    cashierName,
                    style: GoogleFonts.dmSans(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textPrimary),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),

            // Live Digital Clock Pill (self-contained isolated widget)
            const _LiveClockBadge(),
            const SizedBox(width: 12),

            // Held Bills Button with Badge
            Badge(
              label: Text(
                "${billingState.heldBills.length}",
                style: GoogleFonts.dmSans(fontWeight: FontWeight.bold, fontSize: 10),
              ),
              isLabelVisible: billingState.heldBills.isNotEmpty,
              backgroundColor: AppColors.warning,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.pause_circle_outline_rounded, size: 17),
                label: Text("Hold Bills", style: GoogleFonts.dmSans(fontWeight: FontWeight.bold, fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textPrimary,
                  side: const BorderSide(color: Color(0xFFCCE4E9)),
                  backgroundColor: const Color(0xFFF8FAFC),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: _openHeldBillsDialog,
              ),
            ),
            const SizedBox(width: 8),

            // Reprint Recent Bills Button
            OutlinedButton.icon(
              icon: const Icon(Icons.print_outlined, size: 17),
              label: Text("Reprint", style: GoogleFonts.dmSans(fontWeight: FontWeight.bold, fontSize: 12)),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textPrimary,
                side: const BorderSide(color: Color(0xFFCCE4E9)),
                backgroundColor: const Color(0xFFF8FAFC),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: _openReprintDialog,
            ),
          ],
        ),
      ),
    );
  }

  void _openMobileCartSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Consumer(
          builder: (context, ref, _) {
            final cart = ref.watch(cartNotifierProvider);
            final billing = ref.watch(billingNotifierProvider);
            final sheetHeight = MediaQuery.sizeOf(context).height * 0.90;

            return Container(
              height: sheetHeight,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                child: Column(
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 10, bottom: 6),
                      width: 44,
                      height: 4.5,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    Expanded(
                      child: _buildCartPanel(
                        cart,
                        billing.isProcessing,
                        isMobileSheet: true,
                        onProceedPayment: () {
                          Navigator.of(sheetContext).pop();
                          _handlePayment();
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCategoryList(CategoryState categoryState) {
    return Container(
      color: const Color(0xFFF8FAFC),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "CATEGORIES",
                  style: GoogleFonts.dmSans(
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                    color: AppColors.textSecondary,
                    letterSpacing: 1.0,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    "${categoryState.categories.length + 1}",
                    style: GoogleFonts.dmSans(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),
          Expanded(
            child: RawScrollbar(
              controller: _categoryNavScrollController,
              thumbVisibility: false,
              interactive: true,
              thumbColor: AppColors.primary.withValues(alpha: 0.45),
              thickness: 4,
              radius: const Radius.circular(8),
              child: ListView(
                controller: _categoryNavScrollController,
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  _buildCategoryTile(null, "All Items", Icons.grid_view_rounded),
                  ...categoryState.categories.where((c) => c.isActive).map((cat) {
                    return _buildCategoryTile(
                      cat.categoryId,
                      cat.categoryName,
                      _getCategoryIcon(cat.categoryName),
                      count: cat.productCount,
                    );
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(String name) {
    final lower = name.toLowerCase();
    if (lower.contains("sweet")) return Icons.cake_rounded;
    if (lower.contains("bake") || lower.contains("snack") || lower.contains("puff") || lower.contains("samosa")) {
      return Icons.bakery_dining_rounded;
    }
    if (lower.contains("beverage") || lower.contains("coffee") || lower.contains("tea") || lower.contains("milk")) {
      return Icons.local_cafe_rounded;
    }
    if (lower.contains("pastr") || lower.contains("cake") || lower.contains("ice")) {
      return Icons.icecream_rounded;
    }
    return Icons.restaurant_menu_rounded;
  }

  Widget _buildCategoryTile(int? id, String name, IconData icon, {int count = 0}) {
    final isSelected = _selectedCategoryId == id;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        gradient: isSelected
            ? const LinearGradient(
                colors: [AppColors.primary, AppColors.primaryDark],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              )
            : null,
        color: isSelected ? null : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.30),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: ListTile(
        dense: true,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        leading: Icon(
          icon,
          size: 19,
          color: isSelected ? Colors.white : const Color(0xFF64748B),
        ),
        title: Text(
          name,
          style: GoogleFonts.dmSans(
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected ? Colors.white : AppColors.textPrimary,
            fontSize: 13,
          ),
        ),
        trailing: count > 0 && !isSelected
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  "$count",
                  style: GoogleFonts.dmSans(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF475569)),
                ),
              )
            : null,
        onTap: () {
          setState(() {
            _selectedCategoryId = id;
          });
        },
      ),
    );
  }

  Widget _buildCategoryHorizontalBar(CategoryState categoryState) {
    return ListView(
      controller: _categoryBarScrollController,
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      children: [
        ChoiceChip(
          label: Text("All", style: GoogleFonts.dmSans(fontWeight: FontWeight.w700, fontSize: 12)),
          selected: _selectedCategoryId == null,
          selectedColor: AppColors.primary,
          labelStyle: TextStyle(color: _selectedCategoryId == null ? Colors.white : AppColors.textPrimary),
          onSelected: (_) => setState(() => _selectedCategoryId = null),
        ),
        const SizedBox(width: 8),
        ...categoryState.categories.where((c) => c.isActive).map((cat) {
          final isSelected = _selectedCategoryId == cat.categoryId;
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ChoiceChip(
              label: Text(cat.categoryName, style: GoogleFonts.dmSans(fontWeight: FontWeight.w700, fontSize: 12)),
              selected: isSelected,
              selectedColor: AppColors.primary,
              labelStyle: TextStyle(color: isSelected ? Colors.white : AppColors.textPrimary),
              onSelected: (_) => setState(() => _selectedCategoryId = cat.categoryId),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildProductCatalog(List<ProductModel> products, bool isLoading, CartState cartState) {
    // Map productId -> count in current cart for instant visual feedback
    final cartItemCounts = <int, int>{};
    for (final item in cartState.items) {
      cartItemCounts[item.productId] = item.quantity;
    }

    final isNarrow = MediaQuery.sizeOf(context).width < 600;

    return Column(
      children: [
        // Modern Search Bar & Quick Filters
        Container(
          padding: EdgeInsets.symmetric(horizontal: isNarrow ? 10 : 12.0, vertical: 10),
          color: Colors.white,
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w500),
                  decoration: InputDecoration(
                    hintText: isNarrow ? "Search items or HSN..." : "Search sweets, bakery items, filter coffee or snacks (or HSN)...",
                    hintStyle: GoogleFonts.dmSans(color: const Color(0xFF94A3B8), fontSize: 13),
                    prefixIcon: const Icon(Icons.search_rounded, size: 20, color: AppColors.primary),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {});
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                    isDense: true,
                  ),
                  onChanged: (val) => setState(() {}),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFEBF4F6),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFCCE4E9)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.inventory_2_outlined, size: 15, color: AppColors.primaryDark),
                    const SizedBox(width: 5),
                    Text(
                      isNarrow ? "${products.length}" : "${products.length} Items",
                      style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primaryDark),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: Color(0xFFE2E8F0)),

        // Product Catalog Grid
        Expanded(
          child: isLoading && products.isEmpty
              ? const Center(child: AppLoader(message: "Loading Catalog..."))
              : products.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(18),
                            decoration: const BoxDecoration(
                              color: Color(0xFFEBF4F6),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.search_off_rounded, size: 48, color: AppColors.primary),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            "No matching products found",
                            style: GoogleFonts.dmSans(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Try searching with another name or switch category.",
                            style: GoogleFonts.dmSans(color: AppColors.textSecondary, fontSize: 12),
                          ),
                        ],
                      ),
                    )
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        // Responsive cross-axis count & compact aspect ratio to avoid oversized cards
                        final crossAxisCount = constraints.maxWidth > 1150
                            ? 5
                            : (constraints.maxWidth > 850
                                ? 4
                                : (constraints.maxWidth > 580 ? 3 : 2));
                        // Compact card aspect ratio: 1.25 gives ergonomic ~145-165px height (not tall)
                        final childAspectRatio = constraints.maxWidth > 850 ? 1.26 : 1.22;
                        return RawScrollbar(
                          controller: _productsScrollController,
                          thumbVisibility: true,
                          interactive: true,
                          thumbColor: AppColors.primary.withValues(alpha: 0.65),
                          thickness: 6,
                          radius: const Radius.circular(8),
                          minThumbLength: 48,
                          child: GridView.builder(
                            controller: _productsScrollController,
                            padding: const EdgeInsets.all(12),
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: crossAxisCount,
                              crossAxisSpacing: 10,
                              mainAxisSpacing: 10,
                              childAspectRatio: childAspectRatio,
                            ),
                            itemCount: products.length,
                            itemBuilder: (context, index) {
                              final product = products[index];
                              final qtyInCart = cartItemCounts[product.id] ?? 0;
                              return _buildPosProductCard(product, qtyInCart);
                            },
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildPosProductCard(ProductModel product, int qtyInCart) {
    final isAvailable = product.isAvailable;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: qtyInCart > 0
              ? AppColors.primary
              : (isAvailable ? const Color(0xFFE2E8F0) : const Color(0xFFFEE2E2)),
          width: qtyInCart > 0 ? 2.0 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: qtyInCart > 0
                ? AppColors.primary.withValues(alpha: 0.15)
                : Colors.black.withValues(alpha: 0.04),
            blurRadius: qtyInCart > 0 ? 10 : 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: isAvailable
              ? () {
                  ref.read(cartNotifierProvider.notifier).addToCart(product);
                  AppToast.showSuccess(
                    context,
                    "Added ${product.productName}",
                    duration: const Duration(milliseconds: 1400),
                  );
                }
              : () {
                  AppToast.showWarning(context, "${product.productName} is currently out of stock");
                },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hero Product Image (Compact flex 6)
              Expanded(
                flex: 6,
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(13)),
                      child: SizedBox(
                        width: double.infinity,
                        height: double.infinity,
                        child: _buildPosProductThumbnail(product.productImageStorageKey),
                      ),
                    ),

                    // Top Gradient Shadow for readability
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(13)),
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.center,
                            colors: [
                              Colors.black.withValues(alpha: 0.45),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Category Pill on Top-Left
                    Positioned(
                      top: 6,
                      left: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.65),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(
                          product.categoryName.toUpperCase(),
                          style: GoogleFonts.dmSans(
                            fontSize: 8.5,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ),

                    // Cart Quantity Badge or Out of Stock Badge on Top-Right
                    Positioned(
                      top: 6,
                      right: 6,
                      child: !isAvailable
                          ? Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.error,
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: Text(
                                "OUT",
                                style: GoogleFonts.dmSans(
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                ),
                              ),
                            )
                          : qtyInCart > 0
                              ? Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    borderRadius: BorderRadius.circular(10),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.primary.withValues(alpha: 0.5),
                                        blurRadius: 4,
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.check, size: 10, color: Colors.white),
                                      const SizedBox(width: 2),
                                      Text(
                                        "$qtyInCart",
                                        style: GoogleFonts.dmSans(
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.w800,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),

              // Product Info & Price (Compact flex 5)
              Expanded(
                flex: 5,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        product.productName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.dmSans(
                          fontWeight: FontWeight.w700,
                          fontSize: 12.5,
                          color: isAvailable ? AppColors.textPrimary : Colors.grey.shade500,
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                CurrencyFormatter.formatINR(product.sellingPrice),
                                style: GoogleFonts.dmSans(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 14.5,
                                  color: isAvailable ? AppColors.primaryDark : Colors.grey.shade500,
                                ),
                              ),
                              const SizedBox(width: 3),
                              Text(
                                "+5%",
                                style: GoogleFonts.dmSans(
                                  fontSize: 8.5,
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            width: 26,
                            height: 26,
                            decoration: BoxDecoration(
                              gradient: isAvailable
                                  ? const LinearGradient(
                                      colors: [AppColors.primary, AppColors.primaryDark],
                                    )
                                  : null,
                              color: isAvailable ? null : Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(7),
                            ),
                            child: const Icon(Icons.add_rounded, color: Colors.white, size: 16),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCartPanel(
    CartState cart,
    bool isProcessing, {
    bool isMobileSheet = false,
    VoidCallback? onProceedPayment,
  }) {
    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Order Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.receipt_long_rounded, color: AppColors.primary, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Current Sale",
                          style: GoogleFonts.dmSans(fontWeight: FontWeight.w800, fontSize: 16, color: AppColors.textPrimary),
                        ),
                        Text(
                          "Order Ticket",
                          style: GoogleFonts.dmSans(fontSize: 10, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        "${cart.totalItemsCount}",
                        style: GoogleFonts.dmSans(fontWeight: FontWeight.w800, color: Colors.white, fontSize: 11),
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    if (cart.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.delete_sweep_rounded, color: AppColors.error, size: 22),
                        tooltip: "Clear Order Ticket",
                        onPressed: () {
                          ref.read(cartNotifierProvider.notifier).clearCart();
                          AppToast.showInfo(context, "Order ticket cleared");
                        },
                      ),
                    if (isMobileSheet)
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 22),
                        tooltip: "Close Cart",
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),

          // Customer Quick Bar
          InkWell(
            onTap: _showCustomerSelector,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: const Color(0xFFF8FAFC),
              child: Row(
                children: [
                  Icon(
                    cart.customerName != null ? Icons.person_rounded : Icons.person_outline_rounded,
                    size: 18,
                    color: cart.customerName != null ? AppColors.primary : const Color(0xFF64748B),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      cart.customerName ?? "Walk-in Customer",
                      style: GoogleFonts.dmSans(
                        fontWeight: cart.customerName != null ? FontWeight.bold : FontWeight.w600,
                        fontSize: 12,
                        color: cart.customerName != null ? AppColors.textPrimary : const Color(0xFF64748B),
                      ),
                    ),
                  ),
                  if (cart.customerName != null)
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 16, color: Colors.grey),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => ref.read(cartNotifierProvider.notifier).clearCustomer(),
                    )
                  else
                    Text(
                      "Change",
                      style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
                    ),
                ],
              ),
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),

          // Cart Items List
          Expanded(
            child: cart.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: const BoxDecoration(
                            color: Color(0xFFEBF4F6),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.shopping_bag_outlined, size: 48, color: AppColors.primary),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          "Cart is empty",
                          style: GoogleFonts.dmSans(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Tap sweets or bakery cards to add to order ticket.",
                          style: GoogleFonts.dmSans(color: AppColors.textSecondary, fontSize: 12),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                : RawScrollbar(
                    controller: _cartScrollController,
                    thumbVisibility: true,
                    interactive: true,
                    thumbColor: AppColors.primary.withValues(alpha: 0.6),
                    thickness: 5,
                    radius: const Radius.circular(8),
                    minThumbLength: 40,
                    child: ListView.separated(
                      controller: _cartScrollController,
                      padding: const EdgeInsets.all(10),
                      itemCount: cart.items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                      final item = cart.items[index];
                      return Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          children: [
                            // Thumbnail
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                width: 40,
                                height: 40,
                                color: const Color(0xFFE2E8F0),
                                child: _buildPosProductThumbnail(item.imageUrl),
                              ),
                            ),
                            const SizedBox(width: 10),

                            // Name & Unit Price
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.productName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.dmSans(fontWeight: FontWeight.w700, fontSize: 13),
                                  ),
                                  Text(
                                    "${CurrencyFormatter.formatINR(item.unitPrice)} ea",
                                    style: GoogleFonts.dmSans(color: const Color(0xFF64748B), fontSize: 11, fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                            ),

                            // Quantity Stepper
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFFCBD5E1)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  InkWell(
                                    borderRadius: const BorderRadius.horizontal(left: Radius.circular(8)),
                                    onTap: () {
                                      final isRemoving = item.quantity == 1;
                                      ref.read(cartNotifierProvider.notifier).decrementQuantity(item.productId);
                                      if (isRemoving) {
                                        AppToast.showInfo(context, "Removed ${item.productName}", duration: const Duration(milliseconds: 1400));
                                      }
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.all(6.0),
                                      child: Icon(
                                        item.quantity == 1 ? Icons.delete_outline_rounded : Icons.remove_rounded,
                                        size: 16,
                                        color: item.quantity == 1 ? AppColors.error : AppColors.textPrimary,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    child: Text(
                                      "${item.quantity}",
                                      style: GoogleFonts.dmSans(fontWeight: FontWeight.w800, fontSize: 13),
                                    ),
                                  ),
                                  InkWell(
                                    borderRadius: const BorderRadius.horizontal(right: Radius.circular(8)),
                                    onTap: () {
                                      ref.read(cartNotifierProvider.notifier).incrementQuantity(item.productId);
                                      AppToast.showInfo(context, "${item.productName} qty: ${item.quantity + 1}", duration: const Duration(milliseconds: 1200));
                                    },
                                    child: const Padding(
                                      padding: EdgeInsets.all(6.0),
                                      child: Icon(
                                        Icons.add_rounded,
                                        size: 16,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),

                            // Line Total
                            SizedBox(
                              width: 68,
                              child: Text(
                                CurrencyFormatter.formatINR(item.lineTotal),
                                textAlign: TextAlign.right,
                                style: GoogleFonts.dmSans(fontWeight: FontWeight.w800, fontSize: 13, color: AppColors.textPrimary),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
          ),

          // Settlement Summary Box
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFFEBF4F6),
              border: Border(top: BorderSide(color: Color(0xFFCCE4E9), width: 1.2)),
            ),
            child: Column(
              children: [
                _buildSummaryLine("Subtotal", CurrencyFormatter.formatINR(cart.subTotal)),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Text("Discount", style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
                          const SizedBox(width: 6),
                          InkWell(
                            onTap: _showDiscountDialog,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: const Color(0xFFCBD5E1)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.edit, size: 10, color: AppColors.primary),
                                  const SizedBox(width: 2),
                                  Text("Edit", style: GoogleFonts.dmSans(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primary)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        cart.effectiveDiscount > 0 ? "-${CurrencyFormatter.formatINR(cart.effectiveDiscount)}" : "₹0.00",
                        style: GoogleFonts.dmSans(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: cart.effectiveDiscount > 0 ? AppColors.success : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildSummaryLine("Taxable Amount", CurrencyFormatter.formatINR(cart.taxableAmount)),
                _buildSummaryLine("GST Tax (5%)", CurrencyFormatter.formatINR(cart.totalTax)),
                const Divider(height: 18, color: Color(0xFFCCE4E9)),

                // GRAND TOTAL
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "TOTAL PAYABLE",
                          style: GoogleFonts.dmSans(
                            fontWeight: FontWeight.w800,
                            fontSize: 11,
                            color: AppColors.textSecondary,
                            letterSpacing: 0.8,
                          ),
                        ),
                        Text(
                          "Inclusive of all taxes",
                          style: GoogleFonts.dmSans(fontSize: 9, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                    Text(
                      CurrencyFormatter.formatINR(cart.grandTotal),
                      style: GoogleFonts.dmSans(
                        fontWeight: FontWeight.w900,
                        fontSize: 22,
                        color: AppColors.primaryDark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Action Buttons: Hold & Pay & Settle
                Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.pause_circle_outline_rounded, size: 16),
                        label: Text("Hold", style: GoogleFonts.dmSans(fontWeight: FontWeight.bold)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.secondary,
                          side: const BorderSide(color: AppColors.secondary, width: 1.2),
                          backgroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: cart.isEmpty || isProcessing ? null : _handleHoldBill,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.payments_rounded, size: 18),
                        label: Text(
                          "Pay & Settle",
                          style: GoogleFonts.dmSans(fontWeight: FontWeight.w800, fontSize: 15),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 3,
                          shadowColor: AppColors.primary.withValues(alpha: 0.4),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: cart.isEmpty || isProcessing
                            ? null
                            : () {
                                if (onProceedPayment != null) {
                                  onProceedPayment();
                                } else {
                                  _handlePayment();
                                }
                              },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryLine(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
          Text(value, style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        ],
      ),
    );
  }

  Widget _buildMobileCartSummary(CartState cart) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Tap area on the left to open cart sheet
            Expanded(
              child: InkWell(
                onTap: _openMobileCartSheet,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 2),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.shopping_bag_outlined, size: 14, color: AppColors.primary),
                          const SizedBox(width: 4),
                          Text(
                            "${cart.totalItemsCount} items",
                            style: GoogleFonts.dmSans(
                              fontSize: 11.5,
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.keyboard_arrow_up_rounded, size: 16, color: AppColors.primary),
                        ],
                      ),
                      const SizedBox(height: 1),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          CurrencyFormatter.formatINR(cart.grandTotal),
                          style: GoogleFonts.dmSans(
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                            color: AppColors.primaryDark,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            // View Cart Button
            OutlinedButton.icon(
              icon: const Icon(Icons.shopping_cart_outlined, size: 15),
              label: Text("Cart (${cart.totalItemsCount})", style: GoogleFonts.dmSans(fontWeight: FontWeight.bold, fontSize: 11.5)),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primaryDark,
                side: const BorderSide(color: AppColors.primary, width: 1.2),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: _openMobileCartSheet,
            ),
            const SizedBox(width: 6),
            // Pay / Checkout Button
            ElevatedButton.icon(
              icon: const Icon(Icons.payments_rounded, size: 16),
              label: Text("Pay", style: GoogleFonts.dmSans(fontWeight: FontWeight.bold, fontSize: 12.5)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 2,
              ),
              onPressed: cart.isEmpty ? null : () => _handlePayment(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPosProductThumbnail(String? keyOrUrl) {
    if (keyOrUrl != null && keyOrUrl.isNotEmpty) {
      final url = keyOrUrl.startsWith("http")
          ? keyOrUrl
          : "${ApiEndpoints.baseUrl.replaceAll("/api/v1", "")}$keyOrUrl";
      return Image.network(
        url,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          color: const Color(0xFFE2E8F0),
          child: const Center(
            child: Icon(Icons.fastfood_rounded, size: 24, color: AppColors.primary),
          ),
        ),
      );
    }
    return Container(
      color: const Color(0xFFE2E8F0),
      child: const Center(
        child: Icon(Icons.fastfood_rounded, size: 24, color: AppColors.primary),
      ),
    );
  }
}

class _LiveClockBadge extends StatefulWidget {
  const _LiveClockBadge();

  @override
  State<_LiveClockBadge> createState() => _LiveClockBadgeState();
}

class _LiveClockBadgeState extends State<_LiveClockBadge> {
  late Timer _timer;
  late DateTime _now;

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _now = DateTime.now();
        });
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final timeStr = DateFormat("hh:mm:ss a").format(_now);
    final dateStr = DateFormat("EEE, dd MMM yyyy").format(_now);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            timeStr,
            style: GoogleFonts.dmSans(
              fontWeight: FontWeight.w800,
              fontSize: 12,
              color: AppColors.textPrimary,
            ),
          ),
          Text(
            dateStr,
            style: GoogleFonts.dmSans(
              fontSize: 9,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
