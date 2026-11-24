import "package:flutter/material.dart";
import "package:intl/intl.dart";
import "package:billing_pos_app/core/theme/app_colors.dart";
import "package:billing_pos_app/core/services/softcopy_service.dart";
import "package:billing_pos_app/core/utilities/currency_formatter.dart";
import "package:billing_pos_app/shared/widgets/app_button.dart";
import "package:billing_pos_app/features/billing/models/billing_invoice_model.dart";
import "package:billing_pos_app/features/billing/services/thermal_receipt_html_builder.dart";
import "package:billing_pos_app/features/billing/services/thermal_receipt_printer.dart";

/// Production-ready dialog providing visual preview and printing for
/// 3-inch (80mm) thermal receipts, browser HTML printing, and PDF softcopies.
class ReceiptPreviewDialog extends StatelessWidget {
  final BillingInvoiceModel invoice;
  final bool isReprint;

  const ReceiptPreviewDialog({
    super.key,
    required this.invoice,
    this.isReprint = false,
  });

  bool get _isCustomerAvailable {
    final rawCustomer = invoice.customerName?.trim() ?? "";
    return rawCustomer.isNotEmpty &&
        rawCustomer.toLowerCase() != "walk-in" &&
        rawCustomer.toLowerCase() != "walk-in customer" &&
        rawCustomer.toLowerCase() != "walk-in guest";
  }

  String get _combinedDateTime {
    return DateFormat("dd-MM-yyyy hh:mm a").format(invoice.invoiceDateUtc.toLocal());
  }

  @override
  Widget build(BuildContext context) {
    final hasTax = invoice.taxAmount > 0;
    final payments = invoice.payments;
    final isSplitPayment = payments.length > 1;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(22.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header Icon & Title
              CircleAvatar(
                radius: 26,
                backgroundColor: isReprint ? AppColors.primary.withValues(alpha: 0.15) : AppColors.successContainer,
                child: Icon(
                  isReprint ? Icons.print_rounded : Icons.check_circle_outline_rounded,
                  color: isReprint ? AppColors.primary : AppColors.success,
                  size: 28,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                isReprint ? "Reprint Invoice #${invoice.invoiceNumber}" : "Sale Completed Successfully!",
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 14),

              // 80mm Thermal Receipt Preview Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade400, width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Brand Logo
                    const Text(
                      "LISTPOS",
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 2, color: Colors.black87),
                    ),
                    const Text(
                      "• SMART RETAIL POS •",
                      style: TextStyle(fontSize: 8.5, letterSpacing: 0.8, color: Colors.grey),
                    ),
                    const SizedBox(height: 4),

                    // Shop Information
                    Text(
                      invoice.shopName.isNotEmpty ? invoice.shopName : "ListPos Retail Store",
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 0.4),
                      textAlign: TextAlign.center,
                    ),
                    if (invoice.companyName.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 1),
                        child: Text(
                          invoice.companyName,
                          style: TextStyle(color: Colors.grey.shade700, fontSize: 11),
                        ),
                      ),
                    const SizedBox(height: 6),

                    // TAX INVOICE Header Box
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(color: Colors.grey.shade600, style: BorderStyle.solid),
                          bottom: BorderSide(color: Colors.grey.shade600, style: BorderStyle.solid),
                        ),
                      ),
                      child: const Center(
                        child: Text(
                          "TAX INVOICE",
                          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 1),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // 2. Invoice Information (Strictly Combined Date & Time)
                    _buildReceiptRow("Bill No:", invoice.invoiceNumber, isBold: true),
                    _buildReceiptRow("Date:", _combinedDateTime),
                    _buildReceiptRow("Cashier:", invoice.cashierName.isNotEmpty ? invoice.cashierName : "Counter"),
                    if (invoice.deviceId.isNotEmpty) _buildReceiptRow("POS Node:", invoice.deviceId),

                    // 3. Customer Information (Strictly Conditional)
                    if (_isCustomerAvailable) ...[
                      const Divider(thickness: 0.8, height: 12),
                      _buildReceiptRow("Customer:", invoice.customerName!.trim(), isBold: true),
                      if (invoice.customerMobile != null && invoice.customerMobile!.trim().isNotEmpty)
                        _buildReceiptRow("Mobile:", invoice.customerMobile!.trim()),
                    ],

                    const Divider(thickness: 1, height: 14),

                    // 4. Product Items Table (5 Columns: #, Item, Qty, Rate, Amount)
                    const Row(
                      children: [
                        SizedBox(width: 20, child: Text("#", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                        Expanded(child: Text("Item", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                        SizedBox(width: 34, child: Text("Qty", textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                        SizedBox(width: 54, child: Text("Rate", textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                        SizedBox(width: 64, child: Text("Amount", textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                      ],
                    ),
                    const Divider(thickness: 0.8, height: 10),

                    // Items Rows
                    ...invoice.items.asMap().entries.map((entry) {
                      final idx = entry.key + 1;
                      final it = entry.value;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2.5),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(width: 20, child: Text("$idx", style: const TextStyle(fontSize: 11.5))),
                            Expanded(
                              child: Text(
                                it.productNameSnapshot,
                                style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w500),
                              ),
                            ),
                            SizedBox(width: 34, child: Text("${it.quantity}", textAlign: TextAlign.right, style: const TextStyle(fontSize: 11.5))),
                            SizedBox(width: 54, child: Text(it.unitPrice.toStringAsFixed(2), textAlign: TextAlign.right, style: TextStyle(fontSize: 11.5, color: Colors.grey.shade700))),
                            SizedBox(
                              width: 64,
                              child: Text(
                                it.lineTotal.toStringAsFixed(2),
                                textAlign: TextAlign.right,
                                style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),

                    const Divider(thickness: 1, height: 14),

                    // 5. Billing Summary
                    _buildReceiptRow("Subtotal:", CurrencyFormatter.formatINR(invoice.subTotal)),
                    if (invoice.discountAmount > 0)
                      _buildReceiptRow("Discount:", "-${CurrencyFormatter.formatINR(invoice.discountAmount)}"),
                    _buildReceiptRow("Taxable Amount:", CurrencyFormatter.formatINR(invoice.taxableAmount)),
                    if (hasTax) ...[
                      _buildReceiptRow("CGST:", CurrencyFormatter.formatINR(invoice.taxAmount / 2)),
                      _buildReceiptRow("SGST:", CurrencyFormatter.formatINR(invoice.taxAmount / 2)),
                    ],
                    const Divider(thickness: 1.5, height: 14),

                    // Highlighted Grand Total
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("GRAND TOTAL:", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14.5)),
                          Text(
                            CurrencyFormatter.formatINR(invoice.grandTotal),
                            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17, color: AppColors.primary),
                          ),
                        ],
                      ),
                    ),
                    const Divider(thickness: 1.5, height: 14),

                    // 6. Payment Information
                    if (isSplitPayment) ...[
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text("Split Payments:", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                      ...payments.map((p) => _buildReceiptRow(" • ${p.paymentModeName}:", CurrencyFormatter.formatINR(p.amount))),
                    ] else ...[
                      _buildReceiptRow(
                        "Payment Mode: ${payments.isNotEmpty ? payments.first.paymentModeName : 'Cash'}",
                        "",
                        isBold: true,
                      ),
                    ],
                    _buildReceiptRow("Paid Amount:", CurrencyFormatter.formatINR(invoice.paidAmount)),
                    if (invoice.balanceAmount > 0)
                      _buildReceiptRow("Balance Due:", CurrencyFormatter.formatINR(invoice.balanceAmount), isRed: true),

                    const SizedBox(height: 10),

                    // 7. Dynamic Barcode
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      child: Column(
                        children: [
                          Container(
                            height: 28,
                            width: 140,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.black54, width: 0.5),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: List.generate(
                                24,
                                (i) => Container(
                                  width: (i % 3 == 0) ? 3 : ((i % 2 == 0) ? 2 : 1),
                                  color: Colors.black,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "* ${invoice.invoiceNumber} *",
                            style: const TextStyle(fontSize: 9.5, letterSpacing: 2, fontFamily: "monospace", fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),

                    // 8. Receipt Footer
                    const SizedBox(height: 6),
                    const Text(
                      "Thank You!",
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
                    ),
                    const Text(
                      "Visit Again!",
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "Powered by ListPos",
                      style: TextStyle(fontSize: 9, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Action Buttons
              Wrap(
                spacing: 10,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  // 1. Primary 80mm Thermal Print (Standard 80mm Roll PDF / ESC-POS)
                  ElevatedButton.icon(
                    icon: const Icon(Icons.print_rounded, size: 18),
                    label: const Text("Print Receipt"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () async {
                      final receiptPdf = await SoftcopyService.instance.generateThermalReceiptPdf(
                        invoice,
                        is58mm: false,
                      );
                      if (context.mounted) {
                        await SoftcopyService.instance.previewOrPrintPdf(
                          context: context,
                          pdfBytes: receiptPdf,
                          title: "Receipt_${invoice.invoiceNumber}",
                          fileName: "Receipt_${invoice.invoiceNumber}.pdf",
                          pageFormat: PdfPageFormat.roll80,
                        );
                      }
                    },
                  ),

                  // 2. Browser Direct HTML Print (Native window.print() via 80mm CSS template)
                  OutlinedButton.icon(
                    icon: const Icon(Icons.language_rounded, size: 18, color: AppColors.primary),
                    label: const Text("Browser Print (HTML)"),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () {
                      final htmlContent = ThermalReceiptHtmlBuilder.build80mmReceiptHtml(
                        invoice: invoice,
                      );
                      printThermalHtmlInBrowser(htmlContent);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Sent 80mm HTML receipt to browser print engine."),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                  ),

                  // 3. Invoice Softcopy PDF
                  OutlinedButton.icon(
                    icon: const Icon(Icons.picture_as_pdf_rounded, size: 18),
                    label: const Text("Invoice Softcopy (PDF)"),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () async {
                      final pdfBytes = await SoftcopyService.instance.generateInvoicePdf(invoice);
                      if (context.mounted) {
                        await SoftcopyService.instance.previewOrPrintPdf(
                          context: context,
                          pdfBytes: pdfBytes,
                          title: "Invoice ${invoice.invoiceNumber}",
                          fileName: "Invoice_${invoice.invoiceNumber}.pdf",
                        );
                      }
                    },
                  ),

                  // 4. Save Softcopy (Download)
                  OutlinedButton.icon(
                    icon: const Icon(Icons.download_rounded, size: 18),
                    label: const Text("Save Softcopy"),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () async {
                      final pdfBytes = await SoftcopyService.instance.generateInvoicePdf(invoice);
                      final path = await SoftcopyService.instance.savePdfToFile(
                        pdfBytes: pdfBytes,
                        defaultFileName: "Invoice_${invoice.invoiceNumber}.pdf",
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

                  // 5. Close / New Sale
                  AppButton(
                    text: isReprint ? "Close" : "New Sale",
                    icon: isReprint ? Icons.close_rounded : Icons.add_shopping_cart,
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

  Widget _buildReceiptRow(String label, String value, {bool isBold = false, bool isRed = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1.5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                color: isRed ? Colors.red.shade800 : Colors.grey.shade800,
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          if (value.isNotEmpty) ...[
            const SizedBox(width: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
                color: isRed ? Colors.red.shade800 : Colors.black87,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
