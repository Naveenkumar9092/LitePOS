// ignore_for_file: prefer_const_constructors
import "dart:convert";
import "dart:typed_data";
import "package:flutter/material.dart";
import "package:intl/intl.dart";
export "package:pdf/pdf.dart" show PdfPageFormat;
import "package:pdf/pdf.dart";
import "package:pdf/widgets.dart" as pw;
import "package:printing/printing.dart";
import "package:file_picker/file_picker.dart";
import "package:billing_pos_app/core/utilities/date_formatter.dart";
import "package:billing_pos_app/features/billing/models/billing_invoice_model.dart";
import "package:billing_pos_app/features/orders/models/order_model.dart";
import "package:billing_pos_app/features/reports/presentation/report_state.dart";
import "package:billing_pos_app/shared/widgets/app_toast.dart";

/// Comprehensive digital Softcopy Service for LitePOS.
/// Generates professional PDF invoices, receipt softcopies, and executive business analytics reports.
class SoftcopyService {
  SoftcopyService._();
  static final SoftcopyService instance = SoftcopyService._();

  static String _formatCurrency(double amount) {
    return "Rs. ${amount.toStringAsFixed(2)}";
  }

  // ==========================================
  // 1. INVOICE SOFTCOPY (BillingInvoiceModel)
  // ==========================================

  Future<Uint8List> generateInvoicePdf(BillingInvoiceModel invoice) async {
    final pdf = pw.Document(
      title: "Invoice ${invoice.invoiceNumber}",
      author: invoice.companyName,
    );

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header Brand & Company Info
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        invoice.shopName.toUpperCase(),
                        style: pw.TextStyle(
                          fontSize: 22,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.blue900,
                        ),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        invoice.companyName,
                        style: pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        "GSTIN / Tax ID: 33AAAAA0000A1Z5 | FSSAI: 12421000000123",
                        style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
                      ),
                      pw.Text(
                        "Flagship Sweets & Cafe Center | Contact: +91 98401 23456",
                        style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
                      ),
                    ],
                  ),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.blue50,
                      borderRadius: pw.BorderRadius.circular(8),
                      border: pw.Border.all(color: PdfColors.blue200),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text(
                          "TAX INVOICE",
                          style: pw.TextStyle(
                            fontSize: 14,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.blue800,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          "ORIGINAL SOFTCOPY",
                          style: pw.TextStyle(fontSize: 8, color: PdfColors.blue600),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 12),
              pw.Divider(thickness: 1.5, color: PdfColors.blue900),
              pw.SizedBox(height: 10),

              // Metadata Grid
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      _buildMetaText("Invoice Number:", invoice.invoiceNumber, isBold: true),
                      _buildMetaText("Date & Time:", DateFormatter.formatDateTime(invoice.invoiceDateUtc)),
                      _buildMetaText("POS Register Node:", invoice.deviceId),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      _buildMetaText("Billed by Cashier:", invoice.cashierName),
                      if (invoice.customerName != null && invoice.customerName!.isNotEmpty)
                        _buildMetaText("Customer Name:", invoice.customerName!),
                      if (invoice.customerMobile != null && invoice.customerMobile!.isNotEmpty)
                        _buildMetaText("Mobile Number:", invoice.customerMobile!),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 16),

              // Items Table
              pw.Text(
                "ITEMIZED ORDER DETAILS",
                style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.grey800),
              ),
              pw.SizedBox(height: 6),
              pw.TableHelper.fromTextArray(
                headers: ["#", "Item Description", "Qty", "Unit Rate", "GST %", "Tax Amount", "Total Amount"],
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9, color: PdfColors.white),
                headerDecoration: pw.BoxDecoration(color: PdfColors.blue800),
                cellStyle: pw.TextStyle(fontSize: 9),
                cellAlignment: pw.Alignment.centerLeft,
                cellAlignments: {
                  0: pw.Alignment.center,
                  2: pw.Alignment.center,
                  3: pw.Alignment.centerRight,
                  4: pw.Alignment.center,
                  5: pw.Alignment.centerRight,
                  6: pw.Alignment.centerRight,
                },
                data: List.generate(invoice.items.length, (i) {
                  final it = invoice.items[i];
                  return [
                    "${i + 1}",
                    it.productNameSnapshot,
                    "${it.quantity}",
                    _formatCurrency(it.unitPrice),
                    "${it.taxPercentage.toStringAsFixed(1)}%",
                    _formatCurrency(it.taxAmount),
                    _formatCurrency(it.lineTotal),
                  ];
                }),
              ),
              pw.SizedBox(height: 12),

              // Summary & Financial Reconciliation
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  // Payment Info
                  pw.Container(
                    width: 220,
                    padding: const pw.EdgeInsets.all(10),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.grey100,
                      borderRadius: pw.BorderRadius.circular(6),
                      border: pw.Border.all(color: PdfColors.grey300),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          "Settlement & Payment Modes",
                          style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
                        ),
                        pw.SizedBox(height: 6),
                        if (invoice.payments.isEmpty)
                          pw.Text("Settled via: Cash Counter", style: pw.TextStyle(fontSize: 9))
                        else
                          ...invoice.payments.map((p) => pw.Padding(
                                padding: const pw.EdgeInsets.symmetric(vertical: 2),
                                child: pw.Row(
                                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                                  children: [
                                    pw.Text(p.paymentModeName, style: pw.TextStyle(fontSize: 9)),
                                    pw.Text(_formatCurrency(p.amount), style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                                  ],
                                ),
                              )),
                        pw.Divider(thickness: 0.5, color: PdfColors.grey400),
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text("Total Tendered:", style: pw.TextStyle(fontSize: 9)),
                            pw.Text(_formatCurrency(invoice.paidAmount), style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                          ],
                        ),
                        if (invoice.balanceAmount > 0)
                          pw.Row(
                            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                            children: [
                              pw.Text("Balance Due:", style: pw.TextStyle(fontSize: 9, color: PdfColors.red800)),
                              pw.Text(_formatCurrency(invoice.balanceAmount), style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.red800)),
                            ],
                          ),
                      ],
                    ),
                  ),

                  // Grand Totals Table
                  pw.SizedBox(
                    width: 230,
                    child: pw.Column(
                      children: [
                        _buildTotalRow("Subtotal:", _formatCurrency(invoice.subTotal)),
                        if (invoice.discountAmount > 0)
                          _buildTotalRow("Discount Given:", "-${_formatCurrency(invoice.discountAmount)}", isDiscount: true),
                        _buildTotalRow("Taxable Value:", _formatCurrency(invoice.taxableAmount)),
                        _buildTotalRow("Total GST Tax:", _formatCurrency(invoice.taxAmount)),
                        pw.Divider(thickness: 1, color: PdfColors.grey600),
                        pw.Container(
                          padding: const pw.EdgeInsets.symmetric(vertical: 4),
                          child: pw.Row(
                            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                            children: [
                              pw.Text(
                                "GRAND TOTAL:",
                                style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900),
                              ),
                              pw.Text(
                                _formatCurrency(invoice.grandTotal),
                                style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900),
                              ),
                            ],
                          ),
                        ),
                        pw.Divider(thickness: 1.5, color: PdfColors.blue900),
                      ],
                    ),
                  ),
                ],
              ),

              pw.Spacer(),
              // Footer Notes & QR Stamp
              pw.Container(
                alignment: pw.Alignment.center,
                padding: const pw.EdgeInsets.only(top: 10),
                decoration: pw.BoxDecoration(
                  border: pw.Border(top: pw.BorderSide(color: PdfColors.grey300, width: 0.8)),
                ),
                child: pw.Column(
                  children: [
                    pw.Text(
                      "THANK YOU FOR YOUR VISIT!",
                      style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.grey800),
                    ),
                    pw.SizedBox(height: 2),
                    pw.Text(
                      "This is a computer-generated softcopy tax invoice. No signature required.",
                      style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }
  // ==========================================
  // 2. ORDER SOFTCOPY (OrderModel)
  // ==========================================

  Future<Uint8List> generateOrderInvoicePdf(
    OrderModel order, {
    String shopName = "PulsePOS Store",
    String companyName = "PulsePOS Retail",
  }) async {
    final pdf = pw.Document(
      title: "Order ${order.orderNumber}",
      author: companyName,
    );

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        shopName.toUpperCase(),
                        style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(companyName, style: pw.TextStyle(fontSize: 12, color: PdfColors.grey700)),
                      pw.Text("GSTIN: 33AAAAA0000A1Z5 | FSSAI: 12421000000123", style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
                    ],
                  ),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.green50,
                      borderRadius: pw.BorderRadius.circular(6),
                      border: pw.Border.all(color: PdfColors.green200),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text("CUSTOMER INVOICE", style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: PdfColors.green800)),
                        pw.Text("SOFTCOPY RECEIPT", style: pw.TextStyle(fontSize: 8, color: PdfColors.green600)),
                      ],
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 12),
              pw.Divider(thickness: 1.5, color: PdfColors.blue900),
              pw.SizedBox(height: 8),

              // Metadata
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      _buildMetaText("Order / Invoice:", order.orderNumber, isBold: true),
                      _buildMetaText("Order Date:", DateFormatter.formatDateTime(order.createdAt)),
                      _buildMetaText("Order Type:", order.orderType.label),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      _buildMetaText("Cashier:", order.cashierUsername),
                      if (order.customerName != null && order.customerName!.isNotEmpty)
                        _buildMetaText("Customer:", order.customerName!),
                      if (order.customerMobile != null && order.customerMobile!.isNotEmpty)
                        _buildMetaText("Contact:", order.customerMobile!),
                      _buildMetaText("Status:", order.orderStatus.label),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 16),

              // Items Table
              pw.TableHelper.fromTextArray(
                headers: ["#", "Item Description", "Qty", "Unit Rate", "GST %", "Total"],
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9, color: PdfColors.white),
                headerDecoration: pw.BoxDecoration(color: PdfColors.blue800),
                cellStyle: pw.TextStyle(fontSize: 9),
                cellAlignments: {
                  0: pw.Alignment.center,
                  2: pw.Alignment.center,
                  3: pw.Alignment.centerRight,
                  4: pw.Alignment.center,
                  5: pw.Alignment.centerRight,
                },
                data: List.generate(order.details.length, (i) {
                  final it = order.details[i];
                  return [
                    "${i + 1}",
                    it.productName,
                    "${it.quantity}",
                    _formatCurrency(it.unitPrice),
                    "${it.taxPercentage.toStringAsFixed(1)}%",
                    _formatCurrency(it.lineTotal),
                  ];
                }),
              ),
              pw.SizedBox(height: 12),

              // Totals
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.SizedBox(
                    width: 240,
                    child: pw.Column(
                      children: [
                        _buildTotalRow("Subtotal:", _formatCurrency(order.subTotal)),
                        if (order.discountAmount > 0)
                          _buildTotalRow("Discount:", "-${_formatCurrency(order.discountAmount)}", isDiscount: true),
                        _buildTotalRow("Tax Amount:", _formatCurrency(order.taxAmount)),
                        pw.Divider(thickness: 1, color: PdfColors.grey400),
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text("TOTAL BILL:", style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
                            pw.Text(_formatCurrency(order.grandTotal), style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              pw.Spacer(),
              pw.Container(
                alignment: pw.Alignment.center,
                padding: const pw.EdgeInsets.only(top: 8),
                decoration: pw.BoxDecoration(
                  border: pw.Border(top: pw.BorderSide(color: PdfColors.grey300, width: 0.8)),
                ),
                child: pw.Text(
                  "Thank you for choosing $shopName! Please come again.",
                  style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700),
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  // ==========================================
  // 2B. 58mm / 80mm THERMAL RECEIPT ROLL PDF
  // ==========================================

  Future<Uint8List> generateThermalReceiptPdf(
    BillingInvoiceModel invoice, {
    bool is58mm = false,
    String? shopAddress,
    String? contactPhone,
    String? gstin,
    String? upiId,
    String? customFooter,
    bool isIgst = false,
  }) async {
    final pdf = pw.Document(
      title: "Receipt ${invoice.invoiceNumber}",
      author: invoice.companyName,
    );

    final rollFormat = is58mm ? PdfPageFormat.roll57 : PdfPageFormat.roll80;

    final rawCustomer = invoice.customerName?.trim() ?? "";
    final isCustomerAvailable = rawCustomer.isNotEmpty &&
        rawCustomer.toLowerCase() != "walk-in" &&
        rawCustomer.toLowerCase() != "walk-in customer" &&
        rawCustomer.toLowerCase() != "walk-in guest";

    final invoiceDateTime = DateFormat("dd-MM-yyyy hh:mm a").format(invoice.invoiceDateUtc.toLocal());
    final hasTax = invoice.taxAmount > 0;
    final payments = invoice.payments;
    final isSplit = payments.length > 1;

    pdf.addPage(
      pw.Page(
        pageFormat: rollFormat,
        margin: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 8),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              // 1. Header: ListPos Logo & Shop Information
              pw.Text(
                "LISTPOS",
                style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, letterSpacing: 1.5),
              ),
              pw.SizedBox(height: 1),
              pw.Text(
                invoice.shopName.isNotEmpty ? invoice.shopName.toUpperCase() : "LISTPOS RETAIL STORE",
                style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
                textAlign: pw.TextAlign.center,
              ),
              if (shopAddress != null && shopAddress.isNotEmpty)
                pw.Text(shopAddress, style: const pw.TextStyle(fontSize: 7.5), textAlign: pw.TextAlign.center),
              if (contactPhone != null && contactPhone.isNotEmpty)
                pw.Text("Phone: $contactPhone", style: const pw.TextStyle(fontSize: 7.5)),
              if (gstin != null && gstin.isNotEmpty)
                pw.Text("GSTIN: $gstin", style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 3),

              // TAX INVOICE Box
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.symmetric(vertical: 2),
                decoration: const pw.BoxDecoration(
                  border: pw.Border(
                    top: pw.BorderSide(color: PdfColors.black, width: 0.8, style: pw.BorderStyle.dashed),
                    bottom: pw.BorderSide(color: PdfColors.black, width: 0.8, style: pw.BorderStyle.dashed),
                  ),
                ),
                child: pw.Center(
                  child: pw.Text("TAX INVOICE", style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold)),
                ),
              ),
              pw.SizedBox(height: 4),

              // 2. Invoice Information (Strict Combined Date & Time)
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text("Bill No: ${invoice.invoiceNumber}", style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                  pw.Text("Date: $invoiceDateTime", style: const pw.TextStyle(fontSize: 7.5)),
                ],
              ),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text("Cashier: ${invoice.cashierName.isNotEmpty ? invoice.cashierName : 'Counter'}", style: const pw.TextStyle(fontSize: 7.5)),
                  if (invoice.deviceId.isNotEmpty)
                    pw.Text("POS: ${invoice.deviceId}", style: const pw.TextStyle(fontSize: 7.5)),
                ],
              ),

              // 3. Customer Information (Strictly Conditional)
              if (isCustomerAvailable) ...[
                pw.SizedBox(height: 2),
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.symmetric(vertical: 2),
                  decoration: const pw.BoxDecoration(
                    border: pw.Border(
                      top: pw.BorderSide(color: PdfColors.grey500, width: 0.5, style: pw.BorderStyle.dashed),
                      bottom: pw.BorderSide(color: PdfColors.grey500, width: 0.5, style: pw.BorderStyle.dashed),
                    ),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text("Customer: $rawCustomer", style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold)),
                          if (invoice.customerMobile != null && invoice.customerMobile!.trim().isNotEmpty)
                            pw.Text("Mob: ${invoice.customerMobile!.trim()}", style: const pw.TextStyle(fontSize: 7.5)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],

              pw.SizedBox(height: 3),
              pw.Divider(thickness: 0.8, borderStyle: pw.BorderStyle.dashed),

              // 4. Product Items Table (5 Columns: #, Item, Qty, Rate, Amount)
              pw.Row(
                children: [
                  pw.Expanded(flex: 1, child: pw.Text("#", style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold))),
                  pw.Expanded(flex: 5, child: pw.Text("ITEM", style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold))),
                  pw.Expanded(flex: 2, child: pw.Text("QTY", style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.right)),
                  pw.Expanded(flex: 2, child: pw.Text("RATE", style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.right)),
                  pw.Expanded(flex: 2, child: pw.Text("AMOUNT", style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.right)),
                ],
              ),
              pw.Divider(thickness: 0.5, borderStyle: pw.BorderStyle.dashed),

              // Items Rows
              ...invoice.items.asMap().entries.map((entry) {
                final idx = entry.key + 1;
                final item = entry.value;
                return pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 1.5),
                  child: pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Expanded(flex: 1, child: pw.Text("$idx", style: const pw.TextStyle(fontSize: 7))),
                      pw.Expanded(
                        flex: 5,
                        child: pw.Text(
                          item.productNameSnapshot,
                          style: const pw.TextStyle(fontSize: 7),
                          maxLines: 2,
                        ),
                      ),
                      pw.Expanded(
                        flex: 2,
                        child: pw.Text(
                          "${item.quantity}",
                          style: const pw.TextStyle(fontSize: 7),
                          textAlign: pw.TextAlign.right,
                        ),
                      ),
                      pw.Expanded(
                        flex: 2,
                        child: pw.Text(
                          item.unitPrice.toStringAsFixed(2),
                          style: const pw.TextStyle(fontSize: 7),
                          textAlign: pw.TextAlign.right,
                        ),
                      ),
                      pw.Expanded(
                        flex: 2,
                        child: pw.Text(
                          item.lineTotal.toStringAsFixed(2),
                          style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold),
                          textAlign: pw.TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                );
              }),

              pw.Divider(thickness: 0.8, borderStyle: pw.BorderStyle.dashed),

              // 5. Billing Summary
              _buildCompactTotalRow("Subtotal:", _formatCurrency(invoice.subTotal)),
              if (invoice.discountAmount > 0)
                _buildCompactTotalRow("Discount:", "-${_formatCurrency(invoice.discountAmount)}"),
              _buildCompactTotalRow("Taxable Amount:", _formatCurrency(invoice.taxableAmount)),
              if (hasTax) ...[
                if (isIgst)
                  _buildCompactTotalRow("IGST:", _formatCurrency(invoice.taxAmount))
                else ...[
                  _buildCompactTotalRow("CGST:", _formatCurrency(invoice.taxAmount / 2)),
                  _buildCompactTotalRow("SGST:", _formatCurrency(invoice.taxAmount / 2)),
                ],
              ],

              // Highlighted Grand Total
              pw.Container(
                margin: const pw.EdgeInsets.symmetric(vertical: 3),
                padding: const pw.EdgeInsets.symmetric(vertical: 3),
                decoration: const pw.BoxDecoration(
                  border: pw.Border(
                    top: pw.BorderSide(color: PdfColors.black, width: 1.2),
                    bottom: pw.BorderSide(color: PdfColors.black, width: 1.2),
                  ),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text("GRAND TOTAL:", style: pw.TextStyle(fontSize: 10.5, fontWeight: pw.FontWeight.bold)),
                    pw.Text(_formatCurrency(invoice.grandTotal), style: pw.TextStyle(fontSize: 11.5, fontWeight: pw.FontWeight.bold)),
                  ],
                ),
              ),

              // 6. Payment Information
              if (isSplit) ...[
                pw.Row(
                  children: [
                    pw.Text("Split Payments:", style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold)),
                  ],
                ),
                ...payments.map((p) => pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(" - ${p.paymentModeName}", style: const pw.TextStyle(fontSize: 7)),
                        pw.Text(_formatCurrency(p.amount), style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold)),
                      ],
                    )),
              ] else if (payments.isNotEmpty) ...[
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text("Payment Mode:", style: const pw.TextStyle(fontSize: 7)),
                    pw.Text(payments.first.paymentModeName.toUpperCase(), style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold)),
                  ],
                ),
              ],
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text("Paid Amount:", style: const pw.TextStyle(fontSize: 7)),
                  pw.Text(_formatCurrency(invoice.paidAmount), style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold)),
                ],
              ),
              if (invoice.balanceAmount > 0)
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text("Balance Due:", style: const pw.TextStyle(fontSize: 7, color: PdfColors.red800)),
                    pw.Text(_formatCurrency(invoice.balanceAmount), style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold, color: PdfColors.red800)),
                  ],
                ),

              // 7. Dynamic Barcode Reference
              pw.SizedBox(height: 6),
              pw.BarcodeWidget(
                barcode: pw.Barcode.code128(),
                data: invoice.invoiceNumber,
                width: is58mm ? 120 : 160,
                height: 32,
                drawText: true,
                textStyle: const pw.TextStyle(fontSize: 7),
              ),

              // UPI QR Code (Only if configured and grandTotal > 0)
              if (upiId != null && upiId.isNotEmpty && invoice.grandTotal > 0) ...[
                pw.SizedBox(height: 6),
                pw.BarcodeWidget(
                  barcode: pw.Barcode.qrCode(),
                  data: "upi://pay?pa=$upiId&pn=${Uri.encodeComponent(invoice.shopName)}&am=${invoice.grandTotal.toStringAsFixed(2)}&cu=INR",
                  width: 44,
                  height: 44,
                ),
                pw.SizedBox(height: 2),
                pw.Text("Scan to Pay via UPI", style: const pw.TextStyle(fontSize: 6.5)),
              ],

              // 8. Footer
              pw.SizedBox(height: 6),
              pw.Divider(thickness: 0.8, borderStyle: pw.BorderStyle.dashed),
              pw.SizedBox(height: 2),
              pw.Text("Thank You!", style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold)),
              pw.Text("Visit Again!", style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
              if (customFooter != null && customFooter.isNotEmpty)
                pw.Text(customFooter, style: const pw.TextStyle(fontSize: 6.5)),
              pw.Text("Powered by ListPos", style: const pw.TextStyle(fontSize: 6, color: PdfColors.grey700)),
              pw.SizedBox(height: 6),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  Future<Uint8List> generateOrderThermalReceiptPdf(OrderModel order, {bool is58mm = true}) async {
    final pdf = pw.Document(
      title: "Receipt ${order.orderNumber}",
      author: "LitePOS",
    );

    final rollFormat = is58mm ? PdfPageFormat.roll57 : PdfPageFormat.roll80;

    pdf.addPage(
      pw.Page(
        pageFormat: rollFormat,
        margin: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Text(
                "LITEPOS CAFE & SWEETS",
                style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
                textAlign: pw.TextAlign.center,
              ),
              pw.Text("GST: 33AAAAA0000A1Z5 | Ph: +91 98401 23456", style: const pw.TextStyle(fontSize: 7)),
              pw.Divider(thickness: 0.8),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text("Order: ${order.orderNumber}", style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                  pw.Text(DateFormat("dd/MM/yy HH:mm").format(order.createdAt.toLocal()), style: const pw.TextStyle(fontSize: 7)),
                ],
              ),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text("Cashier: ${order.cashierUsername}", style: const pw.TextStyle(fontSize: 7)),
                  pw.Text("Customer: ${order.customerName}", style: const pw.TextStyle(fontSize: 7)),
                ],
              ),
              pw.Divider(thickness: 0.8),
              pw.Row(
                children: [
                  pw.Expanded(flex: 5, child: pw.Text("ITEM", style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold))),
                  pw.Expanded(flex: 2, child: pw.Text("QTY", style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.center)),
                  pw.Expanded(flex: 3, child: pw.Text("TOTAL", style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.right)),
                ],
              ),
              pw.Divider(thickness: 0.5),
              ...order.details.map((item) {
                return pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 1.5),
                  child: pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Expanded(flex: 5, child: pw.Text(item.productName, style: const pw.TextStyle(fontSize: 7), maxLines: 2)),
                      pw.Expanded(flex: 2, child: pw.Text("${item.quantity}", style: const pw.TextStyle(fontSize: 7), textAlign: pw.TextAlign.center)),
                      pw.Expanded(flex: 3, child: pw.Text(_formatCurrency(item.lineTotal), style: const pw.TextStyle(fontSize: 7), textAlign: pw.TextAlign.right)),
                    ],
                  ),
                );
              }),
              pw.Divider(thickness: 0.8),
              _buildCompactTotalRow("Subtotal:", _formatCurrency(order.subTotal)),
              if (order.discountAmount > 0)
                _buildCompactTotalRow("Discount:", "-${_formatCurrency(order.discountAmount)}"),
              _buildCompactTotalRow("GST Tax:", _formatCurrency(order.taxAmount)),
              pw.Divider(thickness: 1.2),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text("NET TOTAL:", style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                  pw.Text(_formatCurrency(order.grandTotal), style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
                ],
              ),
              pw.Divider(thickness: 1.2),
              pw.SizedBox(height: 6),
              pw.BarcodeWidget(
                barcode: pw.Barcode.qrCode(),
                data: "upi://pay?pa=litepos@upi&pn=LitePOS&am=${order.grandTotal.toStringAsFixed(2)}&cu=INR",
                width: 44,
                height: 44,
              ),
              pw.SizedBox(height: 4),
              pw.Text("Thank you for your visit!", style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
              pw.Text("*** LitePOS Billing ***", style: const pw.TextStyle(fontSize: 6, color: PdfColors.grey700)),
              pw.SizedBox(height: 10),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildCompactTotalRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 1),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: const pw.TextStyle(fontSize: 7)),
          pw.Text(value, style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold)),
        ],
      ),
    );
  }

  // ==========================================
  // 3. EXECUTIVE REPORT SOFTCOPY (ReportState)
  // ==========================================

  Future<Uint8List> generateReportPdf({
    required ReportState state,
    String shopName = "PulsePOS Store",
    String companyName = "PulsePOS Retail",
  }) async {
    final pdf = pw.Document(
      title: "Business Analytics Report",
      author: companyName,
    );

    final summary = state.summary;
    final dateRangeStr = "${DateFormat('dd MMM yyyy').format(state.filter.fromDateUtc)} - ${DateFormat('dd MMM yyyy').format(state.filter.toDateUtc)}";

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // Report Header
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      shopName.toUpperCase(),
                      style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900),
                    ),
                    pw.Text(companyName, style: pw.TextStyle(fontSize: 11, color: PdfColors.grey700)),
                    pw.Text("Business Intelligence & Tax Audit Softcopy", style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
                  ],
                ),
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.blue50,
                    borderRadius: pw.BorderRadius.circular(6),
                    border: pw.Border.all(color: PdfColors.blue200),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text("AUDIT REPORT", style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
                      pw.Text(dateRangeStr, style: pw.TextStyle(fontSize: 8, color: PdfColors.blue700)),
                    ],
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 10),
            pw.Divider(thickness: 1.5, color: PdfColors.blue900),
            pw.SizedBox(height: 10),

            // Section 1: Executive KPI Summary
            pw.Text("1. EXECUTIVE PERFORMANCE SUMMARY", style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800)),
            pw.SizedBox(height: 6),
            if (summary != null)
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                children: [
                  pw.TableRow(
                    decoration: pw.BoxDecoration(color: PdfColors.grey100),
                    children: [
                      _buildKpiCell("Gross Sales", _formatCurrency(summary.grossSales)),
                      _buildKpiCell("Invoices Billed", "${summary.totalInvoices}"),
                      _buildKpiCell("Avg Bill Value", _formatCurrency(summary.averageOrderValue)),
                      _buildKpiCell("Net Sales", _formatCurrency(summary.netSales)),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      _buildKpiCell("Total Tax Collected", _formatCurrency(summary.totalTax)),
                      _buildKpiCell("Total Discounts", _formatCurrency(summary.totalDiscount)),
                      _buildKpiCell("Cancelled Bills", "${summary.totalCancelledInvoices}"),
                      _buildKpiCell("Refunds Handled", _formatCurrency(summary.totalRefunds)),
                    ],
                  ),
                ],
              ),
            pw.SizedBox(height: 14),

            // Section 2: Payment Settlement Modes
            if (state.paymentBreakdown.isNotEmpty) ...[
              pw.Text("2. PAYMENT & SETTLEMENT BREAKDOWN", style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800)),
              pw.SizedBox(height: 6),
              pw.TableHelper.fromTextArray(
                headers: ["Payment Mode", "Transactions", "Total Amount Collected", "Contribution %"],
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8, color: PdfColors.white),
                headerDecoration: pw.BoxDecoration(color: PdfColors.blue800),
                cellStyle: pw.TextStyle(fontSize: 8),
                cellAlignments: {
                  1: pw.Alignment.center,
                  2: pw.Alignment.centerRight,
                  3: pw.Alignment.center,
                },
                data: state.paymentBreakdown.map((p) => [
                  p.paymentMode,
                  "${p.transactionCount}",
                  _formatCurrency(p.totalAmount),
                  "${p.percentage.toStringAsFixed(1)}%",
                ]).toList(),
              ),
              pw.SizedBox(height: 14),
            ],

            // Section 3: GST Summary
            if (state.gstSummary != null) ...[
              pw.Text("3. GST TAX RECONCILIATION", style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800)),
              pw.SizedBox(height: 6),
              pw.TableHelper.fromTextArray(
                headers: ["Tax Slab", "Taxable Turnover", "CGST Share", "SGST Share", "Total GST Liability"],
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8, color: PdfColors.white),
                headerDecoration: pw.BoxDecoration(color: PdfColors.blue800),
                cellStyle: pw.TextStyle(fontSize: 8),
                cellAlignments: {
                  0: pw.Alignment.center,
                  1: pw.Alignment.centerRight,
                  2: pw.Alignment.centerRight,
                  3: pw.Alignment.centerRight,
                  4: pw.Alignment.centerRight,
                },
                data: state.gstSummary!.slabs.map((s) => [
                  "${s.taxRate.toStringAsFixed(1)}% GST",
                  _formatCurrency(s.taxableAmount),
                  _formatCurrency(s.cgstAmount),
                  _formatCurrency(s.sgstAmount),
                  _formatCurrency(s.totalTax),
                ]).toList(),
              ),
              pw.SizedBox(height: 14),
            ],

            // Section 4: Top Performing Products
            if (state.productSales.isNotEmpty) ...[
              pw.Text("4. TOP SELLING PRODUCTS & CONTRIBUTIONS", style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800)),
              pw.SizedBox(height: 6),
              pw.TableHelper.fromTextArray(
                headers: ["Product Name", "Category", "Units Sold", "Total Revenue", "Share %"],
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8, color: PdfColors.white),
                headerDecoration: pw.BoxDecoration(color: PdfColors.blue800),
                cellStyle: pw.TextStyle(fontSize: 8),
                cellAlignments: {
                  2: pw.Alignment.center,
                  3: pw.Alignment.centerRight,
                  4: pw.Alignment.center,
                },
                data: state.productSales.take(15).map((p) => [
                  p.productName,
                  p.categoryName,
                  "${p.quantitySold}",
                  _formatCurrency(p.totalRevenue),
                  "${p.percentageOfSales.toStringAsFixed(1)}%",
                ]).toList(),
              ),
              pw.SizedBox(height: 14),
            ],

            // Section 5: Daily Trends
            if (state.dailySales.isNotEmpty) ...[
              pw.Text("5. DAILY SALES TRENDS", style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800)),
              pw.SizedBox(height: 6),
              pw.TableHelper.fromTextArray(
                headers: ["Date", "Invoices", "Gross Sales", "Discounts", "Tax", "Net Sales"],
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8, color: PdfColors.white),
                headerDecoration: pw.BoxDecoration(color: PdfColors.blue800),
                cellStyle: pw.TextStyle(fontSize: 8),
                cellAlignments: {
                  1: pw.Alignment.center,
                  2: pw.Alignment.centerRight,
                  3: pw.Alignment.centerRight,
                  4: pw.Alignment.centerRight,
                  5: pw.Alignment.centerRight,
                },
                data: state.dailySales.map((d) => [
                  DateFormat("yyyy-MM-dd").format(d.date),
                  "${d.invoiceCount}",
                  _formatCurrency(d.grossSales),
                  _formatCurrency(d.discountAmount),
                  _formatCurrency(d.taxAmount),
                  _formatCurrency(d.netSales),
                ]).toList(),
              ),
            ],
          ];
        },
      ),
    );

    return pdf.save();
  }
  // ==========================================
  // 4. REPORT CSV GENERATION
  // ==========================================

  String generateReportCsv(ReportState state, {String shopName = "PulsePOS Store"}) {
    final buffer = StringBuffer();
    final summary = state.summary;

    buffer.writeln("$shopName - Business Performance Report");
    buffer.writeln("Period,${DateFormat('yyyy-MM-dd').format(state.filter.fromDateUtc)} to ${DateFormat('yyyy-MM-dd').format(state.filter.toDateUtc)}");
    buffer.writeln("Generated On,${DateTime.now().toIso8601String()}");
    buffer.writeln();

    if (summary != null) {
      buffer.writeln("EXECUTIVE SUMMARY");
      buffer.writeln("Gross Sales,${summary.grossSales}");
      buffer.writeln("Total Invoices,${summary.totalInvoices}");
      buffer.writeln("Average Order Value,${summary.averageOrderValue}");
      buffer.writeln("Net Sales,${summary.netSales}");
      buffer.writeln("Total Tax,${summary.totalTax}");
      buffer.writeln("Total Discount,${summary.totalDiscount}");
      buffer.writeln("Total Cash Collected,${summary.totalCashCollected}");
      buffer.writeln("Total UPI Collected,${summary.totalUpiCollected}");
      buffer.writeln("Total Card Collected,${summary.totalCardCollected}");
      buffer.writeln();
    }

    if (state.dailySales.isNotEmpty) {
      buffer.writeln("DAILY SALES");
      buffer.writeln("Date,Invoices,Gross Sales,Discount,Tax,Net Sales");
      for (final d in state.dailySales) {
        buffer.writeln("${DateFormat('yyyy-MM-dd').format(d.date)},${d.invoiceCount},${d.grossSales},${d.discountAmount},${d.taxAmount},${d.netSales}");
      }
      buffer.writeln();
    }

    if (state.productSales.isNotEmpty) {
      buffer.writeln("PRODUCT SALES");
      buffer.writeln("Product,Category,Quantity,Revenue,SharePercentage");
      for (final p in state.productSales) {
        buffer.writeln('"${p.productName}","${p.categoryName}",${p.quantitySold},${p.totalRevenue},${p.percentageOfSales}');
      }
      buffer.writeln();
    }

    if (state.categorySales.isNotEmpty) {
      buffer.writeln("CATEGORY SALES");
      buffer.writeln("Category,Quantity,Revenue,SharePercentage");
      for (final c in state.categorySales) {
        buffer.writeln('"${c.categoryName}",${c.totalQuantitySold},${c.totalRevenue},${c.percentageOfSales}');
      }
      buffer.writeln();
    }

    return buffer.toString();
  }

  // ==========================================
  // 5. PRESENTATION & DISPATCH HELPERS
  // ==========================================

  /// Opens the native softcopy layout/print/save dialog.
  Future<void> previewOrPrintPdf({
    required BuildContext context,
    required Uint8List pdfBytes,
    required String title,
    String fileName = "document.pdf",
    bool is58mm = false,
    PdfPageFormat? pageFormat,
  }) async {
    try {
      final effectiveFormat = pageFormat ?? (is58mm ? PdfPageFormat.roll57 : PdfPageFormat.a4);
      await Printing.layoutPdf(
        name: fileName,
        format: effectiveFormat,
        onLayout: (PdfPageFormat format) async => pdfBytes,
      );
    } catch (e) {
      if (context.mounted) {
        AppToast.showError(context, "Could not open softcopy preview: $e");
      }
    }
  }

  /// Exports softcopy directly to local disk.
  Future<String?> savePdfToFile({
    required Uint8List pdfBytes,
    required String defaultFileName,
  }) async {
    try {
      final path = await FilePicker.saveFile(
        dialogTitle: "Save Softcopy Document",
        fileName: defaultFileName,
        type: FileType.custom,
        allowedExtensions: ["pdf"],
        bytes: pdfBytes,
      );
      return path;
    } catch (_) {
      return null;
    }
  }

  /// Exports CSV softcopy to local disk.
  Future<String?> saveCsvToFile({
    required String csvContent,
    required String defaultFileName,
  }) async {
    try {
      final bytes = Uint8List.fromList(utf8.encode(csvContent));
      final path = await FilePicker.saveFile(
        dialogTitle: "Save Softcopy CSV Report",
        fileName: defaultFileName,
        type: FileType.custom,
        allowedExtensions: ["csv"],
        bytes: bytes,
      );
      return path;
    } catch (_) {
      return null;
    }
  }

  // Private PDF Widget Builders
  static pw.Widget _buildMetaText(String label, String value, {bool isBold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 1.5),
      child: pw.Row(
        mainAxisSize: pw.MainAxisSize.min,
        children: [
          pw.Text("$label ", style: pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 9,
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
              color: PdfColors.black,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildTotalRow(String label, String value, {bool isDiscount = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 1.5),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 9,
              fontWeight: pw.FontWeight.bold,
              color: isDiscount ? PdfColors.red800 : PdfColors.black,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildKpiCell(String title, String val) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(title, style: pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
          pw.SizedBox(height: 2),
          pw.Text(val, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
        ],
      ),
    );
  }
}