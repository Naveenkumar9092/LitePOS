import "dart:async";
import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:google_fonts/google_fonts.dart";
import "package:billing_pos_app/core/services/softcopy_service.dart";
import "package:billing_pos_app/core/theme/app_colors.dart";
import "package:billing_pos_app/core/utilities/currency_formatter.dart";
import "package:billing_pos_app/core/utilities/date_formatter.dart";
import "package:billing_pos_app/features/billing/models/billing_invoice_model.dart";
import "package:billing_pos_app/features/billing/presentation/billing_state.dart";
import "package:billing_pos_app/shared/widgets/app_loader.dart";
import "package:billing_pos_app/shared/widgets/app_toast.dart";
import "receipt_preview_dialog.dart";

class ReprintInvoiceDialog extends ConsumerStatefulWidget {
  const ReprintInvoiceDialog({super.key});

  @override
  ConsumerState<ReprintInvoiceDialog> createState() => _ReprintInvoiceDialogState();
}

class _ReprintInvoiceDialogState extends ConsumerState<ReprintInvoiceDialog> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;
  List<BillingInvoiceModel> _invoices = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadInvoices();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadInvoices({String? search}) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final repo = ref.read(billingRepositoryProvider);
      final list = await repo.getRecentInvoices(
        limit: 40,
        searchQuery: search,
      );
      if (mounted) {
        setState(() {
          _invoices = list;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = "Failed to load invoices: $e";
        });
      }
    }
  }

  void _onSearchChanged(String value) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      _loadInvoices(search: value.trim());
    });
  }

  Future<void> _quickThermalPrint(BillingInvoiceModel invoice) async {
    try {
      final receiptPdf = await SoftcopyService.instance.generateThermalReceiptPdf(invoice, is58mm: false);
      if (mounted) {
        await SoftcopyService.instance.previewOrPrintPdf(
          context: context,
          pdfBytes: receiptPdf,
          title: "Receipt_${invoice.invoiceNumber}",
          fileName: "Receipt_${invoice.invoiceNumber}.pdf",
          pageFormat: PdfPageFormat.roll80,
        );
      }
    } catch (e) {
      if (mounted) {
        AppToast.showError(context, "Could not print thermal receipt: $e");
      }
    }
  }

  void _viewInvoicePreview(BillingInvoiceModel invoice) {
    showDialog(
      context: context,
      builder: (_) => ReceiptPreviewDialog(
        invoice: invoice,
        isReprint: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final billingState = ref.watch(billingNotifierProvider);
    final lastCreated = billingState.lastCreatedInvoice ?? (_invoices.isNotEmpty ? _invoices.first : null);
    final isMobile = MediaQuery.sizeOf(context).width < 600;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 24, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680, maxHeight: 720),
        child: Padding(
          padding: EdgeInsets.all(isMobile ? 16.0 : 22.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.print_rounded, color: AppColors.primary, size: 22),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Reprint Bills",
                            style: GoogleFonts.dmSans(fontSize: 19, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                          ),
                          Text(
                            "Search & reprint recent completed receipts",
                            style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.refresh_rounded, size: 22, color: AppColors.textSecondary),
                        tooltip: "Reload recent bills",
                        onPressed: () => _loadInvoices(search: _searchController.text.trim()),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 22),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Instant Reprint Last Bill Banner
              if (lastCreated != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primary.withValues(alpha: 0.08),
                        AppColors.secondary.withValues(alpha: 0.08),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.bolt_rounded, color: Colors.white, size: 18),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                Text(
                                  "Last Bill: ",
                                  style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                                ),
                                Flexible(
                                  child: Text(
                                    lastCreated.invoiceNumber,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primaryDark),
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              "${CurrencyFormatter.formatINR(lastCreated.grandTotal)} • ${DateFormatter.formatRelative(lastCreated.createdAtUtc)}",
                              style: GoogleFonts.dmSans(fontSize: 11.5, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          elevation: 0,
                        ),
                        icon: const Icon(Icons.print_rounded, size: 15),
                        label: Text(
                          "Reprint Last",
                          style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                        onPressed: () => _quickThermalPrint(lastCreated),
                      ),
                    ],
                  ),
                ),

              // Search Bar
              TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                decoration: InputDecoration(
                  hintText: "Search by Invoice # (e.g. 0001) or customer phone...",
                  hintStyle: GoogleFonts.dmSans(fontSize: 13, color: Colors.grey.shade500),
                  prefixIcon: const Icon(Icons.search_rounded, size: 20, color: AppColors.textSecondary),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            _loadInvoices();
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Invoices Count / Status row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _isLoading ? "Loading bills..." : "Found ${_invoices.length} recent invoices",
                    style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                  ),
                  Text(
                    "Thermal (58mm/80mm) & Softcopy PDF",
                    style: GoogleFonts.dmSans(fontSize: 11, color: Colors.grey.shade600),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Invoices List
              Expanded(
                child: _isLoading
                    ? const Center(child: AppLoader())
                    : _errorMessage != null
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 36),
                                const SizedBox(height: 8),
                                Text(_errorMessage!, style: GoogleFonts.dmSans(color: AppColors.error, fontSize: 13)),
                                const SizedBox(height: 12),
                                OutlinedButton.icon(
                                  icon: const Icon(Icons.refresh, size: 16),
                                  label: const Text("Retry"),
                                  onPressed: () => _loadInvoices(search: _searchController.text.trim()),
                                ),
                              ],
                            ),
                          )
                        : _invoices.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.receipt_long_outlined, size: 48, color: Colors.grey.shade400),
                                    const SizedBox(height: 10),
                                    Text(
                                      _searchController.text.isNotEmpty
                                          ? "No invoices match '${_searchController.text}'"
                                          : "No recent invoices found",
                                      style: GoogleFonts.dmSans(fontSize: 14, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      "Invoices will appear here as soon as checkout completes.",
                                      style: GoogleFonts.dmSans(fontSize: 12, color: Colors.grey.shade500),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.separated(
                                itemCount: _invoices.length,
                                separatorBuilder: (_, __) => const SizedBox(height: 8),
                                itemBuilder: (context, index) {
                                  final invoice = _invoices[index];
                                  final paymentLabel = invoice.payments.isNotEmpty
                                      ? invoice.payments.first.paymentModeName
                                      : "Cash";

                                  return Card(
                                    elevation: 0,
                                    margin: EdgeInsets.zero,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      side: BorderSide(color: Colors.grey.shade200),
                                    ),
                                    color: const Color(0xFFFAFAFA),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                      child: Row(
                                        children: [
                                          // Leading Icon with Sync indicator
                                          Container(
                                            width: 40,
                                            height: 40,
                                            decoration: BoxDecoration(
                                              color: AppColors.primary.withValues(alpha: 0.1),
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                            child: const Icon(Icons.receipt_rounded, color: AppColors.primary, size: 20),
                                          ),
                                          const SizedBox(width: 12),

                                          // Invoice Info
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Row(
                                                  children: [
                                                    Text(
                                                      invoice.invoiceNumber,
                                                      style: GoogleFonts.dmSans(
                                                        fontWeight: FontWeight.bold,
                                                        fontSize: 14,
                                                        color: AppColors.textPrimary,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                      decoration: BoxDecoration(
                                                        color: invoice.paymentStatus == 2
                                                            ? AppColors.successContainer
                                                            : AppColors.warning.withValues(alpha: 0.15),
                                                        borderRadius: BorderRadius.circular(6),
                                                      ),
                                                      child: Text(
                                                        invoice.paymentStatus == 2 ? "Paid" : "Pending",
                                                        style: GoogleFonts.dmSans(
                                                          fontSize: 10,
                                                          fontWeight: FontWeight.bold,
                                                          color: invoice.paymentStatus == 2
                                                              ? AppColors.success
                                                              : AppColors.warning,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 3),
                                                Text(
                                                  "${DateFormatter.formatDateTime(invoice.invoiceDateUtc)} • ${invoice.customerName ?? 'Walk-in Customer'}",
                                                  style: GoogleFonts.dmSans(
                                                    fontSize: 12,
                                                    color: AppColors.textSecondary,
                                                  ),
                                                ),
                                                if (invoice.items.isNotEmpty)
                                                  Text(
                                                    "${invoice.items.length} items (${invoice.items.take(2).map((i) => i.productNameSnapshot).join(', ')}${invoice.items.length > 2 ? '...' : ''})",
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                    style: GoogleFonts.dmSans(
                                                      fontSize: 11,
                                                      color: Colors.grey.shade600,
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 8),

                                          // Amount & Payment Pill
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.end,
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                CurrencyFormatter.formatINR(invoice.grandTotal),
                                                style: GoogleFonts.dmSans(
                                                  fontWeight: FontWeight.w800,
                                                  fontSize: 15,
                                                  color: AppColors.primary,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: Colors.grey.shade200,
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: Text(
                                                  paymentLabel,
                                                  style: GoogleFonts.dmSans(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w600,
                                                    color: AppColors.textSecondary,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(width: 10),

                                          // Action Buttons
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              // Quick Thermal Print
                                              IconButton(
                                                icon: const Icon(Icons.print_rounded, size: 20, color: AppColors.primary),
                                                tooltip: "Print Thermal Receipt (58mm/80mm)",
                                                style: IconButton.styleFrom(
                                                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                                                  padding: const EdgeInsets.all(8),
                                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                                ),
                                                onPressed: () => _quickThermalPrint(invoice),
                                              ),
                                              const SizedBox(width: 6),
                                              // View Full Softcopy / Details
                                              IconButton(
                                                icon: const Icon(Icons.visibility_outlined, size: 20, color: AppColors.textPrimary),
                                                tooltip: "View & Reprint Softcopy",
                                                style: IconButton.styleFrom(
                                                  backgroundColor: Colors.grey.shade200,
                                                  padding: const EdgeInsets.all(8),
                                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                                ),
                                                onPressed: () => _viewInvoicePreview(invoice),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
