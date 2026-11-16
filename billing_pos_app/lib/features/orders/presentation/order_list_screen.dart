import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:billing_pos_app/core/theme/app_colors.dart";
import "package:billing_pos_app/core/services/softcopy_service.dart";
import "package:billing_pos_app/core/utilities/currency_formatter.dart";
import "package:billing_pos_app/core/utilities/date_formatter.dart";
import "package:billing_pos_app/features/orders/models/order_model.dart";
import "package:billing_pos_app/features/orders/presentation/order_state.dart";
import "widgets/order_details_dialog.dart";

class OrderListScreen extends ConsumerStatefulWidget {
  const OrderListScreen({super.key});

  @override
  ConsumerState<OrderListScreen> createState() => _OrderListScreenState();
}

class _OrderListScreenState extends ConsumerState<OrderListScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Color _getStatusColor(OrderStatusEnum status) {
    switch (status) {
      case OrderStatusEnum.newOrder:
        return Colors.amber.shade800;
      case OrderStatusEnum.confirmed:
        return AppColors.primary;
      case OrderStatusEnum.preparing:
        return Colors.orange.shade800;
      case OrderStatusEnum.ready:
        return Colors.green.shade700;
      case OrderStatusEnum.completed:
        return Colors.teal.shade700;
      case OrderStatusEnum.cancelled:
        return AppColors.error;
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(orderStateProvider);
    final displayedOrders = state.displayedOrders;
    final isMobile = MediaQuery.sizeOf(context).width < 700;

    ref.listen(orderStateProvider, (previous, next) {
      if (next.errorMessage != null && next.errorMessage != previous?.errorMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.errorMessage!), backgroundColor: AppColors.error),
        );
        ref.read(orderStateProvider.notifier).clearMessages();
      }
      if (next.successMessage != null && next.successMessage != previous?.successMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.successMessage!), backgroundColor: AppColors.success),
        );
        ref.read(orderStateProvider.notifier).clearMessages();
      }
    });

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: SafeArea(
        child: Column(
          children: [
            // Top App Bar / Header
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 12 : 20,
                vertical: isMobile ? 10 : 14,
              ),
              color: Colors.white,
              child: isMobile
                  ? Column(
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.receipt_long, color: AppColors.primary, size: 24),
                            const SizedBox(width: 8),
                            const Text(
                              "Orders",
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                "${displayedOrders.length}",
                                style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 12),
                              ),
                            ),
                            const Spacer(),
                            IconButton.filledTonal(
                              icon: const Icon(Icons.refresh, size: 18),
                              visualDensity: VisualDensity.compact,
                              tooltip: "Refresh Orders",
                              onPressed: () {
                                if (state.isHistoryMode) {
                                  ref.read(orderStateProvider.notifier).loadHistory();
                                } else {
                                  ref.read(orderStateProvider.notifier).loadOrders(refresh: true);
                                }
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: SegmentedButton<bool>(
                            segments: const [
                              ButtonSegment(
                                value: false,
                                label: Text("Active Orders", style: TextStyle(fontSize: 12)),
                                icon: Icon(Icons.timer_outlined, size: 14),
                              ),
                              ButtonSegment(
                                value: true,
                                label: Text("History", style: TextStyle(fontSize: 12)),
                                icon: Icon(Icons.history, size: 14),
                              ),
                            ],
                            selected: {state.isHistoryMode},
                            onSelectionChanged: (selected) {
                              ref.read(orderStateProvider.notifier).setHistoryMode(selected.first);
                            },
                          ),
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        const Icon(Icons.receipt_long, color: AppColors.primary, size: 28),
                        const SizedBox(width: 12),
                        const Text(
                          "Order Management",
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            "${displayedOrders.length} orders",
                            style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 13),
                          ),
                        ),
                        const Spacer(),

                        // Mode Toggle: Active Orders vs Order History
                        SegmentedButton<bool>(
                          segments: const [
                            ButtonSegment(
                              value: false,
                              label: Text("Active Orders"),
                              icon: Icon(Icons.timer_outlined, size: 16),
                            ),
                            ButtonSegment(
                              value: true,
                              label: Text("Order History"),
                              icon: Icon(Icons.history, size: 16),
                            ),
                          ],
                          selected: {state.isHistoryMode},
                          onSelectionChanged: (selected) {
                            ref.read(orderStateProvider.notifier).setHistoryMode(selected.first);
                          },
                        ),
                        const SizedBox(width: 12),

                        // Refresh Button
                        IconButton.filledTonal(
                          icon: const Icon(Icons.refresh, size: 20),
                          tooltip: "Refresh Orders",
                          onPressed: () {
                            if (state.isHistoryMode) {
                              ref.read(orderStateProvider.notifier).loadHistory();
                            } else {
                              ref.read(orderStateProvider.notifier).loadOrders(refresh: true);
                            }
                          },
                        ),
                      ],
                    ),
            ),
            const Divider(height: 1),

            // Filter & Search Controls Bar
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 12 : 20,
                vertical: isMobile ? 8 : 10,
              ),
              color: Colors.white,
              child: Column(
                children: [
                  if (isMobile) ...[
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: "Search order #, customer...",
                        prefixIcon: const Icon(Icons.search, size: 18),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 16),
                                onPressed: () {
                                  _searchController.clear();
                                  ref.read(orderStateProvider.notifier).setSearchQuery("");
                                },
                              )
                            : null,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onChanged: (val) {
                        ref.read(orderStateProvider.notifier).setSearchQuery(val);
                      },
                    ),
                    const SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          ChoiceChip(
                            label: const Text("All Types", style: TextStyle(fontSize: 12)),
                            visualDensity: VisualDensity.compact,
                            selected: state.filterType == null,
                            onSelected: (selected) {
                              if (selected) ref.read(orderStateProvider.notifier).setFilterType(null);
                            },
                          ),
                          const SizedBox(width: 6),
                          ChoiceChip(
                            avatar: const Icon(Icons.point_of_sale, size: 14),
                            label: const Text("Counter", style: TextStyle(fontSize: 12)),
                            visualDensity: VisualDensity.compact,
                            selected: state.filterType == OrderTypeEnum.counterSale,
                            onSelected: (selected) {
                              ref.read(orderStateProvider.notifier).setFilterType(
                                    selected ? OrderTypeEnum.counterSale : null,
                                  );
                            },
                          ),
                          const SizedBox(width: 6),
                          ChoiceChip(
                            avatar: const Icon(Icons.takeout_dining, size: 14),
                            label: const Text("Takeaway", style: TextStyle(fontSize: 12)),
                            visualDensity: VisualDensity.compact,
                            selected: state.filterType == OrderTypeEnum.takeaway,
                            onSelected: (selected) {
                              ref.read(orderStateProvider.notifier).setFilterType(
                                    selected ? OrderTypeEnum.takeaway : null,
                                  );
                            },
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    // Row 1: Search + Order Type Filter
                    Row(
                      children: [
                        // Search Bar
                        Expanded(
                          flex: 3,
                          child: TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              hintText: "Search by order #, customer, mobile...",
                              prefixIcon: const Icon(Icons.search, size: 20),
                              suffixIcon: _searchController.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear, size: 18),
                                      onPressed: () {
                                        _searchController.clear();
                                        ref.read(orderStateProvider.notifier).setSearchQuery("");
                                      },
                                    )
                                  : null,
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            onChanged: (val) {
                              ref.read(orderStateProvider.notifier).setSearchQuery(val);
                            },
                          ),
                        ),
                        const SizedBox(width: 16),

                        // Order Type Segment
                        Wrap(
                          spacing: 8,
                          children: [
                            ChoiceChip(
                              label: const Text("All Types"),
                              selected: state.filterType == null,
                              onSelected: (selected) {
                                if (selected) ref.read(orderStateProvider.notifier).setFilterType(null);
                              },
                            ),
                            ChoiceChip(
                              avatar: const Icon(Icons.point_of_sale, size: 16),
                              label: const Text("Counter Sale"),
                              selected: state.filterType == OrderTypeEnum.counterSale,
                              onSelected: (selected) {
                                ref.read(orderStateProvider.notifier).setFilterType(
                                      selected ? OrderTypeEnum.counterSale : null,
                                    );
                              },
                            ),
                            ChoiceChip(
                              avatar: const Icon(Icons.takeout_dining, size: 16),
                              label: const Text("Takeaway"),
                              selected: state.filterType == OrderTypeEnum.takeaway,
                              onSelected: (selected) {
                                ref.read(orderStateProvider.notifier).setFilterType(
                                      selected ? OrderTypeEnum.takeaway : null,
                                    );
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 8),

                  // Row 2: Status Chips Filter (only in Active Orders mode)
                  if (!state.isHistoryMode)
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          ChoiceChip(
                            label: Text("All Active", style: TextStyle(fontSize: isMobile ? 12 : 13)),
                            visualDensity: isMobile ? VisualDensity.compact : null,
                            selected: state.filterStatus == null,
                            onSelected: (selected) {
                              if (selected) ref.read(orderStateProvider.notifier).setFilterStatus(null);
                            },
                          ),
                          const SizedBox(width: 8),
                          ChoiceChip(
                            avatar: CircleAvatar(backgroundColor: Colors.amber.shade800, radius: 5),
                            label: Text("New", style: TextStyle(fontSize: isMobile ? 12 : 13)),
                            visualDensity: isMobile ? VisualDensity.compact : null,
                            selected: state.filterStatus == OrderStatusEnum.newOrder,
                            onSelected: (selected) {
                              ref.read(orderStateProvider.notifier).setFilterStatus(
                                    selected ? OrderStatusEnum.newOrder : null,
                                  );
                            },
                          ),
                          const SizedBox(width: 8),
                          ChoiceChip(
                            avatar: const CircleAvatar(backgroundColor: AppColors.primary, radius: 5),
                            label: Text("Confirmed", style: TextStyle(fontSize: isMobile ? 12 : 13)),
                            visualDensity: isMobile ? VisualDensity.compact : null,
                            selected: state.filterStatus == OrderStatusEnum.confirmed,
                            onSelected: (selected) {
                              ref.read(orderStateProvider.notifier).setFilterStatus(
                                    selected ? OrderStatusEnum.confirmed : null,
                                  );
                            },
                          ),
                          const SizedBox(width: 8),
                          ChoiceChip(
                            avatar: CircleAvatar(backgroundColor: Colors.orange.shade800, radius: 5),
                            label: Text("Preparing", style: TextStyle(fontSize: isMobile ? 12 : 13)),
                            visualDensity: isMobile ? VisualDensity.compact : null,
                            selected: state.filterStatus == OrderStatusEnum.preparing,
                            onSelected: (selected) {
                              ref.read(orderStateProvider.notifier).setFilterStatus(
                                    selected ? OrderStatusEnum.preparing : null,
                                  );
                            },
                          ),
                          const SizedBox(width: 8),
                          ChoiceChip(
                            avatar: CircleAvatar(backgroundColor: Colors.green.shade700, radius: 5),
                            label: Text("Ready", style: TextStyle(fontSize: isMobile ? 12 : 13)),
                            visualDensity: isMobile ? VisualDensity.compact : null,
                            selected: state.filterStatus == OrderStatusEnum.ready,
                            onSelected: (selected) {
                              ref.read(orderStateProvider.notifier).setFilterStatus(
                                    selected ? OrderStatusEnum.ready : null,
                                  );
                            },
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Orders Content Area
            Expanded(
              child: state.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : displayedOrders.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                state.isHistoryMode ? Icons.history_toggle_off : Icons.receipt_long_outlined,
                                size: 64,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                state.isHistoryMode ? "No order history found" : "No active orders found",
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                state.isHistoryMode
                                    ? "Completed and cancelled orders will appear here."
                                    : "New orders placed from POS billing will appear here.",
                                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                        )
                      : LayoutBuilder(
                          builder: (context, constraints) {
                            // Responsive grid: 1 col on small screens, 2 cols on medium, 3 cols on large
                            final crossAxisCount = constraints.maxWidth > 1100
                                ? 3
                                : (constraints.maxWidth > 700 ? 2 : 1);

                            return GridView.builder(
                              padding: EdgeInsets.all(isMobile ? 10 : 16),
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: crossAxisCount,
                                crossAxisSpacing: isMobile ? 10 : 16,
                                mainAxisSpacing: isMobile ? 10 : 16,
                                mainAxisExtent: 265,
                              ),
                              itemCount: displayedOrders.length,
                              itemBuilder: (context, index) {
                                final order = displayedOrders[index];
                                return _buildOrderCard(order);
                              },
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderCard(OrderModel order) {
    final statusColor = _getStatusColor(order.orderStatus);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Order Number + Status Badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    order.orderNumber,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    order.orderStatus.label,
                    style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 11),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),

            // Second Row: Order Type & Time
            Row(
              children: [
                Icon(
                  order.orderType == OrderTypeEnum.counterSale ? Icons.point_of_sale : Icons.takeout_dining,
                  size: 14,
                  color: Colors.grey.shade600,
                ),
                const SizedBox(width: 4),
                Text(
                  order.orderType.label,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade700),
                ),
                const SizedBox(width: 8),
                Text("•", style: TextStyle(color: Colors.grey.shade400)),
                const SizedBox(width: 8),
                Text(
                  DateFormatter.formatRelative(order.createdAt),
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
            const SizedBox(height: 4),

            // Customer info
            Text(
              order.customerName != null && order.customerName!.isNotEmpty
                  ? "Customer: ${order.customerName!} (${order.customerMobile ?? ''})"
                  : "Customer: Walk-in Guest",
              style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const Divider(height: 16),

            // Items preview
            Expanded(
              child: ListView.builder(
                physics: const NeverScrollableScrollPhysics(),
                itemCount: order.details.length > 2 ? 2 : order.details.length,
                itemBuilder: (context, i) {
                  final it = order.details[i];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Row(
                      children: [
                        Text("${it.quantity}x ", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        Expanded(
                          child: Text(
                            it.productName,
                            style: const TextStyle(fontSize: 12),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(CurrencyFormatter.formatINR(it.lineTotal), style: const TextStyle(fontSize: 12)),
                      ],
                    ),
                  );
                },
              ),
            ),
            if (order.details.length > 2)
              Text(
                "+ ${order.details.length - 2} more items...",
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontStyle: FontStyle.italic),
              ),
            const SizedBox(height: 6),

            // Grand Total Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Total:", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: Text(
                      CurrencyFormatter.formatINR(order.grandTotal),
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Bottom Actions
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              reverse: true,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    icon: const Icon(Icons.picture_as_pdf_outlined, size: 18, color: AppColors.primary),
                    tooltip: "Invoice Softcopy (PDF)",
                    visualDensity: VisualDensity.compact,
                    onPressed: () async {
                      final pdfBytes = await SoftcopyService.instance.generateOrderInvoicePdf(order);
                      if (!mounted) return;
                      await SoftcopyService.instance.previewOrPrintPdf(
                        context: context,
                        pdfBytes: pdfBytes,
                        title: "Invoice ${order.orderNumber}",
                        fileName: "Invoice_${order.orderNumber}.pdf",
                      );
                    },
                  ),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      visualDensity: VisualDensity.compact,
                    ),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (ctx) => OrderDetailsDialog(order: order),
                      );
                    },
                    child: const Text("Details", style: TextStyle(fontSize: 12)),
                  ),
                  const SizedBox(width: 8),

                  // Quick Status Transitions
                  if (order.orderStatus == OrderStatusEnum.newOrder) ...[
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        visualDensity: VisualDensity.compact,
                      ),
                      onPressed: () {
                        ref.read(orderStateProvider.notifier).updateOrderStatus(
                              order.id,
                              OrderStatusEnum.confirmed,
                            );
                      },
                      child: const Text("Confirm", style: TextStyle(fontSize: 12)),
                    ),
                  ] else if (order.orderStatus == OrderStatusEnum.confirmed) ...[
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.orange.shade800,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        visualDensity: VisualDensity.compact,
                      ),
                      onPressed: () {
                        ref.read(orderStateProvider.notifier).updateOrderStatus(
                              order.id,
                              OrderStatusEnum.preparing,
                            );
                      },
                      child: const Text("Prepare", style: TextStyle(fontSize: 12)),
                    ),
                  ] else if (order.orderStatus == OrderStatusEnum.preparing) ...[
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.green.shade700,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        visualDensity: VisualDensity.compact,
                      ),
                      onPressed: () {
                        ref.read(orderStateProvider.notifier).updateOrderStatus(
                              order.id,
                              OrderStatusEnum.ready,
                            );
                      },
                      child: const Text("Ready", style: TextStyle(fontSize: 12)),
                    ),
                  ] else if (order.orderStatus == OrderStatusEnum.ready) ...[
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.teal.shade700,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        visualDensity: VisualDensity.compact,
                      ),
                      onPressed: () {
                        ref.read(orderStateProvider.notifier).updateOrderStatus(
                              order.id,
                              OrderStatusEnum.completed,
                            );
                      },
                      child: const Text("Complete", style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
