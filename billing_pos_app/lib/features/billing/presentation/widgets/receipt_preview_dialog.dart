import "package:flutter/material.dart";
import "package:billing_pos_app/core/theme/app_colors.dart";
import "package:billing_pos_app/core/utilities/currency_formatter.dart";
import "package:billing_pos_app/core/utilities/date_formatter.dart";
import "package:billing_pos_app/shared/widgets/app_button.dart";
import "package:billing_pos_app/features/billing/models/billing_invoice_model.dart";

class ReceiptPreviewDialog extends StatelessWidget {
  final BillingInvoiceModel invoice;

  const ReceiptPreviewDialog({super.key, required this.invoice});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Success Header
              const CircleAvatar(
                radius: 28,
                backgroundColor: AppColors.successContainer,
                child: Icon(Icons.check, color: AppColors.success, size: 32),
              ),
              const SizedBox(height: 12),
              const Text(
                "Sale Completed Successfully!",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              // Thermal Receipt Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Shop Header
                    Text(
                      invoice.shopName,
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 0.5),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      invoice.companyName,
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                    const Divider(thickness: 1, height: 16),

                    // Invoice Metadata
                    _buildReceiptRow("Invoice No:", invoice.invoiceNumber),
                    _buildReceiptRow("Date & Time:", DateFormatter.formatDateTime(invoice.invoiceDateUtc)),
                    _buildReceiptRow("Cashier:", invoice.cashierName),
                    _buildReceiptRow("POS Device:", invoice.deviceId),
                    if (invoice.customerName != null) _buildReceiptRow("Customer:", invoice.customerName!),
                    const Divider(thickness: 1, height: 16),

                    // Items Table
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(child: Text("Item", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                        Text("Qty x Rate", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        SizedBox(width: 16),
                        Text("Total", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ...invoice.items.map((it) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  it.productNameSnapshot,
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                                ),
                              ),
                              Text(
                                "${it.quantity} x ${CurrencyFormatter.formatINR(it.unitPrice)}",
                                style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                              ),
                              const SizedBox(width: 16),
                              Text(
                                CurrencyFormatter.formatINR(it.lineTotal),
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        )),
                    const Divider(thickness: 1, height: 16),

                    // Totals
                    _buildReceiptRow("Subtotal:", CurrencyFormatter.formatINR(invoice.subTotal)),
                    if (invoice.discountAmount > 0)
                      _buildReceiptRow("Discount:", "-${CurrencyFormatter.formatINR(invoice.discountAmount)}"),
                    _buildReceiptRow("Taxable Amount:", CurrencyFormatter.formatINR(invoice.taxableAmount)),
                    _buildReceiptRow("GST Tax:", CurrencyFormatter.formatINR(invoice.taxAmount)),
                    const Divider(thickness: 1.5, height: 16),

                    // Grand Total
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("GRAND TOTAL:", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                        Text(
                          CurrencyFormatter.formatINR(invoice.grandTotal),
                          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: AppColors.primary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    _buildReceiptRow("Paid Amount:", CurrencyFormatter.formatINR(invoice.paidAmount)),
                    if (invoice.balanceAmount > 0)
                      _buildReceiptRow("Balance Due:", CurrencyFormatter.formatINR(invoice.balanceAmount)),
                    const SizedBox(height: 12),

                    // Payment Mode Pill
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        "Payment Mode: ${invoice.payments.isNotEmpty ? invoice.payments.first.paymentModeName : 'Cash'}",
                        style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      "*** THANK YOU! PLEASE VISIT AGAIN ***",
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 11, letterSpacing: 0.8),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Actions
              Wrap(
                spacing: 12,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  OutlinedButton.icon(
                    icon: const Icon(Icons.print),
                    label: const Text("Print Receipt"),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Receipt sent to POS thermal printer.")),
                      );
                    },
                  ),
                  AppButton(
                    text: "New Sale",
                    icon: Icons.add_shopping_cart,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReceiptRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade700))),
          const SizedBox(width: 8),
          Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
