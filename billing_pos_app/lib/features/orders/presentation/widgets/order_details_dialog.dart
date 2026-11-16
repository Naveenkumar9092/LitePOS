import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:billing_pos_app/core/theme/app_colors.dart";
import "package:billing_pos_app/core/services/softcopy_service.dart";
import "package:billing_pos_app/core/utilities/currency_formatter.dart";
import "package:billing_pos_app/core/utilities/date_formatter.dart";
import "package:billing_pos_app/features/orders/models/order_model.dart";
import "package:billing_pos_app/features/orders/presentation/order_state.dart";
import "cancel_order_dialog.dart";

class OrderDetailsDialog extends ConsumerWidget {
  final OrderModel order;

  const OrderDetailsDialog({
    super.key,
    required this.order,
  });

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
  Widget build(BuildContext context, WidgetRef ref) {
    final statusColor = _getStatusColor(order.orderStatus);
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isMobile = screenWidth < 600;

    return Dialog(
      insetPadding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 40, vertical: isMobile ? 16 : 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 650, maxHeight: 750),
        child: Padding(
          padding: EdgeInsets.all(isMobile ? 14.0 : 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              order.orderNumber,
                              style: TextStyle(fontSize: isMobile ? 16 : 20, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: statusColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: statusColor.withValues(alpha: 0.4)),
                              ),
                              child: Text(
                                order.orderStatus.label,
                                style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Created: ${DateFormatter.formatDateTime(order.createdAt)} • Cashier: ${order.cashierUsername}",
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const Divider(height: 24),

              // Customer & Type info card
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: isMobile
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text("Order Type", style: TextStyle(fontSize: 11, color: Colors.grey)),
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      Icon(
                                        order.orderType == OrderTypeEnum.counterSale ? Icons.point_of_sale : Icons.takeout_dining,
                                        size: 16,
                                        color: AppColors.primary,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        order.orderType.label,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              if (order.invoiceNumber != null)
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    const Text("Invoice", style: TextStyle(fontSize: 11, color: Colors.grey)),
                                    const SizedBox(height: 2),
                                    Text(
                                      order.invoiceNumber!,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.secondary),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("Customer", style: TextStyle(fontSize: 11, color: Colors.grey)),
                              const SizedBox(height: 2),
                              Text(
                                order.customerName != null && order.customerName!.isNotEmpty
                                    ? "${order.customerName!} (${order.customerMobile ?? ''})"
                                    : "Walk-in Guest",
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                            ],
                          ),
                        ],
                      )
                    : Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text("Order Type", style: TextStyle(fontSize: 11, color: Colors.grey)),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    Icon(
                                      order.orderType == OrderTypeEnum.counterSale ? Icons.point_of_sale : Icons.takeout_dining,
                                      size: 16,
                                      color: AppColors.primary,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      order.orderType.label,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text("Customer", style: TextStyle(fontSize: 11, color: Colors.grey)),
                                const SizedBox(height: 2),
                                Text(
                                  order.customerName != null && order.customerName!.isNotEmpty
                                      ? "${order.customerName!} (${order.customerMobile ?? ''})"
                                      : "Walk-in Guest",
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                          if (order.invoiceNumber != null)
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text("Invoice", style: TextStyle(fontSize: 11, color: Colors.grey)),
                                  const SizedBox(height: 2),
                                  Text(
                                    order.invoiceNumber!,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.secondary),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
              ),
              const SizedBox(height: 16),

              // Items table
              const Text("Order Items", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 8),

              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade200),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: ListView.separated(
                    itemCount: order.details.length,
                    separatorBuilder: (context, index) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final item = order.details[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                "${item.quantity}x",
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.productName,
                                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                  ),
                                  Text(
                                    "Rate: ${CurrencyFormatter.formatINR(item.unitPrice)} • GST: ${item.taxPercentage.toStringAsFixed(0)}%",
                                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              CurrencyFormatter.formatINR(item.lineTotal),
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Financial Totals
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Sub Total:", style: TextStyle(fontSize: 12, color: Colors.grey)),
                        Text(CurrencyFormatter.formatINR(order.subTotal), style: const TextStyle(fontSize: 12)),
                      ],
                    ),
                    if (order.discountAmount > 0) ...[
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Discount:", style: TextStyle(fontSize: 12, color: AppColors.error)),
                          Text("-${CurrencyFormatter.formatINR(order.discountAmount)}",
                              style: const TextStyle(fontSize: 12, color: AppColors.error, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("GST Tax:", style: TextStyle(fontSize: 12, color: Colors.grey)),
                        Text(CurrencyFormatter.formatINR(order.taxAmount), style: const TextStyle(fontSize: 12)),
                      ],
                    ),
                    const Divider(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Grand Total:", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                        Text(
                          CurrencyFormatter.formatINR(order.grandTotal),
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Actions
              Wrap(
                spacing: 12,
                runSpacing: 8,
                alignment: WrapAlignment.end,
                children: [
                  if (order.orderStatus != OrderStatusEnum.completed && order.orderStatus != OrderStatusEnum.cancelled) ...[
                    OutlinedButton.icon(
                      icon: const Icon(Icons.cancel_outlined, size: 16, color: AppColors.error),
                      label: const Text("Cancel Order", style: TextStyle(color: AppColors.error)),
                      onPressed: () async {
                        final cancelled = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => CancelOrderDialog(
                            order: order,
                            onConfirm: (reason) => ref.read(orderStateProvider.notifier).cancelOrder(order.id, reason),
                          ),
                        );
                        if (cancelled == true && context.mounted) {
                          Navigator.of(context).pop();
                        }
                      },
                    ),
                  ],

                  if (order.orderStatus == OrderStatusEnum.newOrder) ...[
                    ElevatedButton.icon(
                      icon: const Icon(Icons.check, size: 16),
                      label: const Text("Confirm Order"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () async {
                        final ok = await ref.read(orderStateProvider.notifier).updateOrderStatus(
                              order.id,
                              OrderStatusEnum.confirmed,
                            );
                        if (ok && context.mounted) {
                          Navigator.of(context).pop();
                        }
                      },
                    ),
                  ],

                  if (order.orderStatus == OrderStatusEnum.confirmed) ...[
                    ElevatedButton.icon(
                      icon: const Icon(Icons.soup_kitchen, size: 16),
                      label: const Text("Start Preparing"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange.shade800,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () async {
                        final ok = await ref.read(orderStateProvider.notifier).updateOrderStatus(
                              order.id,
                              OrderStatusEnum.preparing,
                            );
                        if (ok && context.mounted) {
                          Navigator.of(context).pop();
                        }
                      },
                    ),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.done_all, size: 16),
                      label: const Text("Mark Ready"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade700,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () async {
                        final ok = await ref.read(orderStateProvider.notifier).updateOrderStatus(
                              order.id,
                              OrderStatusEnum.ready,
                            );
                        if (ok && context.mounted) {
                          Navigator.of(context).pop();
                        }
                      },
                    ),
                  ],

                  if (order.orderStatus == OrderStatusEnum.preparing) ...[
                    ElevatedButton.icon(
                      icon: const Icon(Icons.done_all, size: 16),
                      label: const Text("Mark Ready"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade700,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () async {
                        final ok = await ref.read(orderStateProvider.notifier).updateOrderStatus(
                              order.id,
                              OrderStatusEnum.ready,
                            );
                        if (ok && context.mounted) {
                          Navigator.of(context).pop();
                        }
                      },
                    ),
                  ],

                  if (order.orderStatus == OrderStatusEnum.ready) ...[
                    ElevatedButton.icon(
                      icon: const Icon(Icons.task_alt, size: 16),
                      label: const Text("Complete Order"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal.shade700,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () async {
                        final ok = await ref.read(orderStateProvider.notifier).updateOrderStatus(
                              order.id,
                              OrderStatusEnum.completed,
                            );
                        if (ok && context.mounted) {
                          Navigator.of(context).pop();
                        }
                      },
                    ),
                  ],

                  ElevatedButton.icon(
                    icon: const Icon(Icons.print_rounded, size: 16),
                    label: const Text("Print Thermal (58mm)"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () async {
                      final receiptPdf = await SoftcopyService.instance.generateOrderThermalReceiptPdf(order, is58mm: true);
                      if (context.mounted) {
                        await SoftcopyService.instance.previewOrPrintPdf(
                          context: context,
                          pdfBytes: receiptPdf,
                          title: "Receipt_${order.orderNumber}",
                          fileName: "Receipt_${order.orderNumber}.pdf",
                          pageFormat: PdfPageFormat.roll57,
                        );
                      }
                    },
                  ),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.picture_as_pdf_rounded, size: 16, color: AppColors.primary),
                    label: const Text("Invoice Softcopy (PDF)"),
                    onPressed: () async {
                      final pdfBytes = await SoftcopyService.instance.generateOrderInvoicePdf(order);
                      if (context.mounted) {
                        await SoftcopyService.instance.previewOrPrintPdf(
                          context: context,
                          pdfBytes: pdfBytes,
                          title: "Invoice ${order.orderNumber}",
                          fileName: "Invoice_${order.orderNumber}.pdf",
                        );
                      }
                    },
                  ),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.download_rounded, size: 16),
                    label: const Text("Save PDF"),
                    onPressed: () async {
                      final pdfBytes = await SoftcopyService.instance.generateOrderInvoicePdf(order);
                      final path = await SoftcopyService.instance.savePdfToFile(
                        pdfBytes: pdfBytes,
                        defaultFileName: "Invoice_${order.orderNumber}.pdf",
                      );
                      if (context.mounted && path != null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text("Invoice softcopy saved: $path"),
                            backgroundColor: AppColors.success,
                          ),
                        );
                      }
                    },
                  ),

                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text("Close"),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

