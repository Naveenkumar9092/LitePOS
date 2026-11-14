import "dart:async";
import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:intl/intl.dart";
import "package:billing_pos_app/core/theme/app_colors.dart";
import "package:billing_pos_app/core/utilities/currency_formatter.dart";
import "package:billing_pos_app/core/utilities/responsive_layout.dart";
import "package:billing_pos_app/shared/widgets/app_button.dart";
import "package:billing_pos_app/shared/widgets/status_badge.dart";
import "../../authentication/presentation/auth_state.dart";
import "../../categories/presentation/category_state.dart";
import "../../products/models/product_model.dart";
import "../../products/presentation/product_state.dart";
import "billing_state.dart";
import "cart_state.dart";
import "widgets/held_bills_dialog.dart";
import "widgets/payment_dialog.dart";
import "widgets/receipt_preview_dialog.dart";

class PosBillingScreen extends ConsumerStatefulWidget {
  const PosBillingScreen({super.key});

  @override
  ConsumerState<PosBillingScreen> createState() => _PosBillingScreenState();
}

class _PosBillingScreenState extends ConsumerState<PosBillingScreen> {
  final TextEditingController _searchController = TextEditingController();
  int? _selectedCategoryId;
  late Timer _clockTimer;
  DateTime _currentTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _currentTime = DateTime.now();
        });
      }
    });
  }

  @override
  void dispose() {
    _clockTimer.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _openHeldBillsDialog() {
    showDialog(
      context: context,
      builder: (_) => const HeldBillsDialog(),
    );
  }

  Future<void> _handleHoldBill() async {
    final cart = ref.read(cartNotifierProvider);
    if (cart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Cannot hold an empty cart.")),
      );
      return;
    }

    final success = await ref.read(billingNotifierProvider.notifier).holdBill(cart);
    if (mounted && success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Bill successfully placed on hold."), backgroundColor: AppColors.secondary),
      );
    }
  }

  Future<void> _handlePayment() async {
    final cart = ref.read(cartNotifierProvider);
    if (cart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Cart is empty. Add products to bill.")),
      );
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
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => ReceiptPreviewDialog(invoice: invoice),
        );
      }
    }
  }

  void _showDiscountDialog() {
    final cart = ref.read(cartNotifierProvider);
    final controller = TextEditingController(
      text: cart.discountAmount > 0 ? cart.discountAmount.toStringAsFixed(2) : "",
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Apply Cart Discount"),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: "Discount Amount (₹)",
            prefixText: "₹ ",
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              final discount = double.tryParse(controller.text.trim()) ?? 0.0;
              ref.read(cartNotifierProvider.notifier).setDiscount(discount);
              Navigator.of(ctx).pop();
            },
            child: const Text("Apply"),
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

    final isDesktop = ResponsiveLayout.isDesktop(context);

    // Filter products by selected category and search query
    final products = productState.products.where((p) {
      if (_selectedCategoryId != null && p.categoryId != _selectedCategoryId) {
        return false;
      }
      if (_searchController.text.isNotEmpty) {
        final q = _searchController.text.toLowerCase();
        if (!p.productName.toLowerCase().contains(q)) return false;
      }
      return true;
    }).toList();

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(64),
        child: _buildHeader(authState, billingState),
      ),
      body: isDesktop
          ? Row(
              children: [
                // Left Panel: Categories
                SizedBox(
                  width: 200,
                  child: _buildCategoryList(categoryState),
                ),
                const VerticalDivider(width: 1),

                // Center Panel: Product Grid
                Expanded(
                  flex: 5,
                  child: _buildProductCatalog(products, productState.isLoading),
                ),
                const VerticalDivider(width: 1),

                // Right Panel: Active Cart & Checkout
                SizedBox(
                  width: 380,
                  child: _buildCartPanel(cartState, billingState.isProcessing),
                ),
              ],
            )
          : Column(
              children: [
                // Category Pills for Mobile/Tablet
                SizedBox(
                  height: 50,
                  child: _buildCategoryHorizontalBar(categoryState),
                ),
                const Divider(height: 1),
                Expanded(
                  child: _buildProductCatalog(products, productState.isLoading),
                ),
                const Divider(height: 1),
                // Bottom cart sheet summary
                _buildMobileCartSummary(cartState),
              ],
            ),
    );
  }

  Widget _buildHeader(AuthState authState, BillingState billingState) {
    final cashierName = authState.user?.fullName ?? "Cashier";
    final timeStr = DateFormat("hh:mm:ss a").format(_currentTime);
    final dateStr = DateFormat("dd MMM yyyy").format(_currentTime);

    return AppBar(
      automaticallyImplyLeading: false,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.point_of_sale, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("LitePOS Counter Sales", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.success),
                  ),
                  const SizedBox(width: 4),
                  const Text("ONLINE • POS-TERMINAL-01", style: TextStyle(fontSize: 10, color: Colors.grey)),
                ],
              ),
            ],
          ),
        ],
      ),
      actions: [
        // Cashier Badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Row(
            children: [
              const Icon(Icons.person, size: 16, color: AppColors.primary),
              const SizedBox(width: 6),
              Text(cashierName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            ],
          ),
        ),
        const SizedBox(width: 12),

        // Date & Clock
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(timeStr, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, fontFamily: "monospace")),
            Text(dateStr, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
          ],
        ),
        const SizedBox(width: 16),

        // Held Bills Button
        Badge(
          label: Text("${billingState.heldBills.length}"),
          isLabelVisible: billingState.heldBills.isNotEmpty,
          backgroundColor: AppColors.secondary,
          child: OutlinedButton.icon(
            icon: const Icon(Icons.pause_circle_outline, size: 18),
            label: const Text("Held Bills"),
            onPressed: _openHeldBillsDialog,
          ),
        ),
        const SizedBox(width: 16),
      ],
    );
  }

  Widget _buildCategoryList(CategoryState categoryState) {
    return Container(
      color: Colors.grey.shade50,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Text("CATEGORIES", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey, letterSpacing: 1.0)),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView(
              children: [
                _buildCategoryTile(null, "All Items", Icons.dashboard_outlined),
                ...categoryState.categories.where((c) => c.isActive).map((cat) {
                  return _buildCategoryTile(cat.categoryId, cat.categoryName, Icons.restaurant_menu, count: cat.productCount);
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTile(int? id, String name, IconData icon, {int count = 0}) {
    final isSelected = _selectedCategoryId == id;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primary : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        dense: true,
        leading: Icon(icon, size: 18, color: isSelected ? Colors.white : AppColors.textPrimary),
        title: Text(
          name,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? Colors.white : AppColors.textPrimary,
            fontSize: 13,
          ),
        ),
        trailing: count > 0 && !isSelected
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(10)),
                child: Text("$count", style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
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
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      children: [
        ChoiceChip(
          label: const Text("All"),
          selected: _selectedCategoryId == null,
          onSelected: (_) => setState(() => _selectedCategoryId = null),
        ),
        const SizedBox(width: 8),
        ...categoryState.categories.where((c) => c.isActive).map((cat) {
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ChoiceChip(
              label: Text(cat.categoryName),
              selected: _selectedCategoryId == cat.categoryId,
              onSelected: (_) => setState(() => _selectedCategoryId = cat.categoryId),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildProductCatalog(List<ProductModel> products, bool isLoading) {
    return Column(
      children: [
        // Search Bar
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: "Search products by name...",
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {});
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              isDense: true,
            ),
            onChanged: (val) => setState(() {}),
          ),
        ),
        const Divider(height: 1),

        // Product Grid
        Expanded(
          child: isLoading && products.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : products.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search_off, size: 48, color: Colors.grey),
                          SizedBox(height: 8),
                          Text("No matching products found.", style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.all(12),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 1.15,
                      ),
                      itemCount: products.length,
                      itemBuilder: (context, index) {
                        final product = products[index];
                        return _buildPosProductCard(product);
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildPosProductCard(ProductModel product) {
    final isAvailable = product.isAvailable;

    return Card(
      elevation: isAvailable ? 1 : 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: isAvailable ? Colors.grey.shade200 : Colors.red.shade100),
      ),
      color: isAvailable ? Colors.white : Colors.grey.shade100,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: isAvailable
            ? () {
                ref.read(cartNotifierProvider.notifier).addToCart(product);
              }
            : null,
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Top Row: Category tag & Availability badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      product.categoryName.toUpperCase(),
                      style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.primary),
                    ),
                  ),
                  if (!isAvailable)
                    const StatusBadge(label: "OUT", type: BadgeType.error)
                  else
                    const Icon(Icons.add_circle, color: AppColors.primary, size: 20),
                ],
              ),

              // Product Name
              Text(
                product.productName,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: isAvailable ? AppColors.textPrimary : Colors.grey.shade500,
                ),
              ),

              // Bottom Price
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    CurrencyFormatter.formatINR(product.sellingPrice),
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                      color: isAvailable ? AppColors.primary : Colors.grey.shade500,
                    ),
                  ),
                  Text(
                    "+${product.taxPercentage.toInt()}% GST",
                    style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCartPanel(CartState cart, bool isProcessing) {
    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cart Header
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.shopping_cart_outlined, color: AppColors.primary),
                    const SizedBox(width: 8),
                    const Text("Current Sale", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text("${cart.totalItemsCount}", style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 11)),
                    ),
                  ],
                ),
                if (cart.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.delete_sweep_outlined, color: AppColors.error),
                    tooltip: "Clear Cart",
                    onPressed: () => ref.read(cartNotifierProvider.notifier).clearCart(),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Cart Items List
          Expanded(
            child: cart.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.shopping_basket_outlined, size: 54, color: Colors.grey),
                        SizedBox(height: 10),
                        Text("Cart is empty", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                        SizedBox(height: 4),
                        Text("Tap product cards to add items", style: TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(8),
                    itemCount: cart.items.length,
                    separatorBuilder: (_, __) => const Divider(height: 8),
                    itemBuilder: (context, index) {
                      final item = cart.items[index];
                      return Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item.productName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                Text(
                                  "${CurrencyFormatter.formatINR(item.unitPrice)} ea",
                                  style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                                ),
                              ],
                            ),
                          ),

                          // Quantity Stepper
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline, size: 20),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed: () => ref.read(cartNotifierProvider.notifier).decrementQuantity(item.productId),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                child: Text("${item.quantity}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              ),
                              IconButton(
                                icon: const Icon(Icons.add_circle_outline, size: 20),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed: () => ref.read(cartNotifierProvider.notifier).incrementQuantity(item.productId),
                              ),
                            ],
                          ),
                          const SizedBox(width: 12),

                          // Line Total
                          Text(
                            CurrencyFormatter.formatINR(item.lineTotal),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ],
                      );
                    },
                  ),
          ),
          const Divider(height: 1),

          // Cart Totals & Settlement Box
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              border: Border(top: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Column(
              children: [
                _buildSummaryLine("Subtotal", CurrencyFormatter.formatINR(cart.subTotal)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Text("Discount", style: TextStyle(fontSize: 12, color: Colors.grey)),
                        const SizedBox(width: 4),
                        InkWell(
                          onTap: _showDiscountDialog,
                          child: const Icon(Icons.edit, size: 14, color: AppColors.primary),
                        ),
                      ],
                    ),
                    Text(
                      cart.effectiveDiscount > 0 ? "-${CurrencyFormatter.formatINR(cart.effectiveDiscount)}" : "₹0.00",
                      style: TextStyle(fontSize: 12, color: cart.effectiveDiscount > 0 ? AppColors.success : Colors.grey),
                    ),
                  ],
                ),
                _buildSummaryLine("Taxable Amount", CurrencyFormatter.formatINR(cart.taxableAmount)),
                _buildSummaryLine("GST Tax", CurrencyFormatter.formatINR(cart.totalTax)),
                const Divider(height: 16),

                // Grand Total
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("GRAND TOTAL", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
                    Text(
                      CurrencyFormatter.formatINR(cart.grandTotal),
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: AppColors.primary),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.pause, size: 16),
                        label: const Text("Hold"),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.secondary,
                          side: const BorderSide(color: AppColors.secondary),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: cart.isEmpty || isProcessing ? null : _handleHoldBill,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: AppButton(
                        text: "Pay & Settle",
                        icon: Icons.payments_outlined,
                        isLoading: isProcessing,
                        onPressed: cart.isEmpty ? null : _handlePayment,
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
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildMobileCartSummary(CartState cart) {
    return Container(
      padding: const EdgeInsets.all(12),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("${cart.totalItemsCount} items in cart", style: const TextStyle(fontSize: 12, color: Colors.grey)),
              Text(
                CurrencyFormatter.formatINR(cart.grandTotal),
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: AppColors.primary),
              ),
            ],
          ),
          AppButton(
            text: "View Cart & Pay",
            icon: Icons.arrow_forward,
            onPressed: cart.isEmpty ? null : _handlePayment,
          ),
        ],
      ),
    );
  }
}

