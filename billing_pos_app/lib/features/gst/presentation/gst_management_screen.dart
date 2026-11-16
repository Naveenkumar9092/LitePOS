import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:intl/intl.dart";
import "package:billing_pos_app/core/theme/app_colors.dart";
import "package:billing_pos_app/core/utilities/currency_formatter.dart";
import "../models/gst_models.dart";
import "gst_state.dart";
import "widgets/credit_note_dialog.dart";
import "widgets/hsn_form_dialog.dart";
import "widgets/tax_form_dialog.dart";

class GstManagementScreen extends ConsumerStatefulWidget {
  const GstManagementScreen({super.key});

  @override
  ConsumerState<GstManagementScreen> createState() => _GstManagementScreenState();
}

class _GstManagementScreenState extends ConsumerState<GstManagementScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Controllers for GST Configuration Form
  final _configFormKey = GlobalKey<FormState>();
  late TextEditingController _gstinController;
  late TextEditingController _legalNameController;
  late TextEditingController _tradeNameController;
  late TextEditingController _stateNameController;
  late TextEditingController _stateCodeController;
  late TextEditingController _termsController;
  late TextEditingController _headerController;
  late TextEditingController _footerController;
  bool _isComposition = false;
  bool _isTaxInclusive = true;
  bool _showHsnSummary = true;
  bool _showTaxBreakup = true;
  bool _configInitialized = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _gstinController = TextEditingController();
    _legalNameController = TextEditingController();
    _tradeNameController = TextEditingController();
    _stateNameController = TextEditingController();
    _stateCodeController = TextEditingController();
    _termsController = TextEditingController();
    _headerController = TextEditingController();
    _footerController = TextEditingController();

    Future.microtask(() {
      ref.read(gstNotifierProvider.notifier).loadAll();
      ref.read(gstNotifierProvider.notifier).loadCreditNotes();
      ref.read(gstNotifierProvider.notifier).loadSummary();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _gstinController.dispose();
    _legalNameController.dispose();
    _tradeNameController.dispose();
    _stateNameController.dispose();
    _stateCodeController.dispose();
    _termsController.dispose();
    _headerController.dispose();
    _footerController.dispose();
    super.dispose();
  }

  void _syncConfigForm(GstConfigurationModel config) {
    if (!_configInitialized) {
      _gstinController.text = config.gstin;
      _legalNameController.text = config.legalName;
      _tradeNameController.text = config.tradeName;
      _stateNameController.text = config.stateName;
      _stateCodeController.text = config.stateCode;
      _termsController.text = config.invoiceTermsAndConditions ?? "";
      _headerController.text = config.invoiceHeader ?? "";
      _footerController.text = config.invoiceFooter ?? "";
      _isComposition = config.isCompositionScheme;
      _isTaxInclusive = config.defaultPricingIsTaxInclusive;
      _showHsnSummary = config.showHsnSummaryOnReceipt;
      _showTaxBreakup = config.showTaxBreakupOnReceipt;
      _configInitialized = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(gstNotifierProvider);

    if (state.gstConfig != null && !_configInitialized) {
      _syncConfigForm(state.gstConfig!);
    }

    ref.listen<GstState>(gstNotifierProvider, (prev, next) {
      if (next.errorMessage != null && next.errorMessage != prev?.errorMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.errorMessage!), backgroundColor: AppColors.error),
        );
        ref.read(gstNotifierProvider.notifier).clearMessages();
      }
      if (next.successMessage != null && next.successMessage != prev?.successMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.successMessage!), backgroundColor: Colors.green),
        );
        ref.read(gstNotifierProvider.notifier).clearMessages();
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text("GST Billing & Invoicing"),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.tune), text: "Configuration"),
            Tab(icon: Icon(Icons.percent), text: "Tax Master"),
            Tab(icon: Icon(Icons.tag), text: "HSN/SAC Master"),
            Tab(icon: Icon(Icons.note_alt_outlined), text: "Credit / Debit Notes"),
            Tab(icon: Icon(Icons.analytics_outlined), text: "GSTR-1 Summary"),
          ],
        ),
      ),
      body: state.isLoading && state.taxes.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildConfigurationTab(context, state),
                _buildTaxMasterTab(context, state),
                _buildHsnMasterTab(context, state),
                _buildCreditNotesTab(context, state),
                _buildSummaryTab(context, state),
              ],
            ),
    );
  }

  Widget _buildConfigurationTab(BuildContext context, GstState state) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isMobile = screenWidth < 650;

    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 14.0 : 24.0),
      child: Form(
        key: _configFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Company GST & Invoice Details",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text(
              "Configure your GSTIN, state code, tax-inclusive pricing, and receipt layouts.",
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 20),
            if (isMobile) ...[
              TextFormField(
                controller: _gstinController,
                decoration: const InputDecoration(
                  labelText: "GSTIN (15 Digits) *",
                  hintText: "33AAAAA0000A1Z5",
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v == null || v.trim().length != 15 ? "Valid 15-digit GSTIN required." : null,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: TextFormField(
                      controller: _stateCodeController,
                      decoration: const InputDecoration(
                        labelText: "State Code *",
                        hintText: "33",
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => v == null || v.trim().length != 2 ? "2-digit state code required." : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _stateNameController,
                      decoration: const InputDecoration(
                        labelText: "State Name *",
                        hintText: "Tamil Nadu",
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => v == null || v.trim().isEmpty ? "State name required." : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _legalNameController,
                decoration: const InputDecoration(
                  labelText: "Legal Entity Name *",
                  hintText: "LitePOS Tech Pvt Ltd",
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v == null || v.trim().isEmpty ? "Legal name required." : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _tradeNameController,
                decoration: const InputDecoration(
                  labelText: "Trade Name *",
                  hintText: "LitePOS Cafe & Ice Creams",
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v == null || v.trim().isEmpty ? "Trade name required." : null,
              ),
            ] else ...[
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _gstinController,
                      decoration: const InputDecoration(
                        labelText: "GSTIN (15 Digits) *",
                        hintText: "33AAAAA0000A1Z5",
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => v == null || v.trim().length != 15 ? "Valid 15-digit GSTIN required." : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 1,
                    child: TextFormField(
                      controller: _stateCodeController,
                      decoration: const InputDecoration(
                        labelText: "State Code (2 Digits) *",
                        hintText: "33",
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => v == null || v.trim().length != 2 ? "2-digit state code required." : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _stateNameController,
                      decoration: const InputDecoration(
                        labelText: "State Name *",
                        hintText: "Tamil Nadu",
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => v == null || v.trim().isEmpty ? "State name required." : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _legalNameController,
                      decoration: const InputDecoration(
                        labelText: "Legal Entity Name *",
                        hintText: "LitePOS Tech Pvt Ltd",
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => v == null || v.trim().isEmpty ? "Legal name required." : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _tradeNameController,
                      decoration: const InputDecoration(
                        labelText: "Trade Name *",
                        hintText: "LitePOS Cafe & Ice Creams",
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => v == null || v.trim().isEmpty ? "Trade name required." : null,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 12),
            const Text("Pricing & Tax Settings", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text("Default Pricing is Tax-Inclusive", style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: const Text("Menu prices already include GST (Standard for Cafes and Food Courts)", style: TextStyle(fontSize: 12, color: Colors.grey)),
              value: _isTaxInclusive,
              onChanged: (v) => setState(() => _isTaxInclusive = v),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text("Composition Scheme Dealer", style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: const Text("Enable if business pays 1% lump sum without collecting tax from customers", style: TextStyle(fontSize: 12, color: Colors.grey)),
              value: _isComposition,
              onChanged: (v) => setState(() => _isComposition = v),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text("Show HSN Summary on Thermal Receipts", style: TextStyle(fontWeight: FontWeight.w600)),
              value: _showHsnSummary,
              onChanged: (v) => setState(() => _showHsnSummary = v),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text("Show CGST/SGST Tax Breakup on Receipts", style: TextStyle(fontWeight: FontWeight.w600)),
              value: _showTaxBreakup,
              onChanged: (v) => setState(() => _showTaxBreakup = v),
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),
            const Text("Receipt Layout & Terms", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            TextFormField(
              controller: _headerController,
              decoration: const InputDecoration(
                labelText: "Receipt Header Message",
                hintText: "Welcome to LitePOS! Enjoy delicious coffee & treats",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _footerController,
              decoration: const InputDecoration(
                labelText: "Receipt Footer Message",
                hintText: "Thank you for your visit! Follow us @litepos",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _termsController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: "Invoice Terms & Conditions",
                hintText: "1. Goods once sold cannot be returned. 2. Subject to Chennai jurisdiction.",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              ),
              icon: const Icon(Icons.save),
              label: const Text("Save Configuration"),
              onPressed: state.isLoading
                  ? null
                  : () async {
                      if (_configFormKey.currentState?.validate() ?? false) {
                        final req = UpdateGstConfigRequest(
                          gstin: _gstinController.text.trim(),
                          legalName: _legalNameController.text.trim(),
                          tradeName: _tradeNameController.text.trim(),
                          stateName: _stateNameController.text.trim(),
                          stateCode: _stateCodeController.text.trim(),
                          isCompositionScheme: _isComposition,
                          defaultPricingIsTaxInclusive: _isTaxInclusive,
                          invoiceTermsAndConditions: _termsController.text.trim(),
                          invoiceHeader: _headerController.text.trim(),
                          invoiceFooter: _footerController.text.trim(),
                          showHsnSummaryOnReceipt: _showHsnSummary,
                          showTaxBreakupOnReceipt: _showTaxBreakup,
                        );

                        await ref.read(gstNotifierProvider.notifier).saveConfig(req);
                      }
                    },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaxMasterTab(BuildContext context, GstState state) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isMobile = screenWidth < 650;

    return Padding(
      padding: EdgeInsets.all(isMobile ? 14.0 : 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isMobile) ...[
            const Text("Configured Tax Slabs", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            const Text("Indian GST rates with automatic CGST, SGST, and IGST division.", style: TextStyle(fontSize: 13, color: Colors.grey)),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
              icon: const Icon(Icons.add),
              label: const Text("Add Tax Slab"),
              onPressed: () => showDialog(
                context: context,
                builder: (ctx) => const TaxFormDialog(),
              ),
            ),
          ] else ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Configured Tax Slabs", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    SizedBox(height: 4),
                    Text("Indian GST rates with automatic CGST, SGST, and IGST division.", style: TextStyle(fontSize: 13, color: Colors.grey)),
                  ],
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                  icon: const Icon(Icons.add),
                  label: const Text("Add Tax Slab"),
                  onPressed: () => showDialog(
                    context: context,
                    builder: (ctx) => const TaxFormDialog(),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          Expanded(
            child: Card(
              elevation: 1,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListView.separated(
                itemCount: state.taxes.length,
                separatorBuilder: (ctx, i) => const Divider(height: 1),
                itemBuilder: (ctx, i) {
                  final t = state.taxes[i];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                      child: Text(
                        "${t.ratePercentage.toStringAsFixed(0)}%",
                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 13),
                      ),
                    ),
                    title: Row(
                      children: [
                        Flexible(child: Text(t.taxName, style: const TextStyle(fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis)),
                        if (t.isDefault) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(4)),
                            child: const Text("DEFAULT", style: TextStyle(fontSize: 10, color: Colors.green, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ],
                    ),
                    subtitle: Text(
                      "CGST: ${t.cgstPercentage}%  |  SGST: ${t.sgstPercentage}%  |  IGST: ${t.igstPercentage}%  •  ${t.isTaxInclusiveDefault ? "Inclusive" : "Exclusive"}",
                      style: const TextStyle(fontSize: 12),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          t.isActive ? Icons.check_circle : Icons.cancel,
                          color: t.isActive ? Colors.green : Colors.grey,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.edit, size: 18),
                          onPressed: () => showDialog(
                            context: context,
                            builder: (c) => TaxFormDialog(tax: t),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHsnMasterTab(BuildContext context, GstState state) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isMobile = screenWidth < 650;

    return Padding(
      padding: EdgeInsets.all(isMobile ? 14.0 : 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isMobile) ...[
            const Text("HSN & SAC Master", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            const Text("Harmonized System of Nomenclature codes for food, beverages, and catering services.", style: TextStyle(fontSize: 13, color: Colors.grey)),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
              icon: const Icon(Icons.add),
              label: const Text("Add HSN/SAC"),
              onPressed: () => showDialog(
                context: context,
                builder: (ctx) => const HsnFormDialog(),
              ),
            ),
          ] else ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("HSN & SAC Master", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    SizedBox(height: 4),
                    Text("Harmonized System of Nomenclature codes for food, beverages, and catering services.", style: TextStyle(fontSize: 13, color: Colors.grey)),
                  ],
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                  icon: const Icon(Icons.add),
                  label: const Text("Add HSN/SAC"),
                  onPressed: () => showDialog(
                    context: context,
                    builder: (ctx) => const HsnFormDialog(),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          Expanded(
            child: Card(
              elevation: 1,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListView.separated(
                itemCount: state.hsnSacs.length,
                separatorBuilder: (ctx, i) => const Divider(height: 1),
                itemBuilder: (ctx, i) {
                  final h = state.hsnSacs[i];
                  return ListTile(
                    leading: Chip(
                      label: Text(h.type, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      backgroundColor: h.type == "HSN" ? Colors.blue.withValues(alpha: 0.12) : Colors.amber.withValues(alpha: 0.12),
                    ),
                    title: Row(
                      children: [
                        Text("Code: ${h.code}", style: const TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(width: 8),
                        Text("(${h.defaultGstRate.toStringAsFixed(1)}% GST)", style: const TextStyle(color: Colors.grey, fontSize: 13)),
                      ],
                    ),
                    subtitle: Text(h.description, style: const TextStyle(fontSize: 12)),
                    trailing: IconButton(
                      icon: const Icon(Icons.edit, size: 18),
                      onPressed: () => showDialog(
                        context: context,
                        builder: (c) => HsnFormDialog(hsn: h),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreditNotesTab(BuildContext context, GstState state) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isMobile = screenWidth < 650;

    return Padding(
      padding: EdgeInsets.all(isMobile ? 14.0 : 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isMobile) ...[
            const Text("Credit & Debit Notes", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            const Text("Sales returns, post-sale discounts, and downward adjustments linked to invoices.", style: TextStyle(fontSize: 13, color: Colors.grey)),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
              icon: const Icon(Icons.post_add),
              label: const Text("Issue Note"),
              onPressed: () => showDialog(
                context: context,
                builder: (ctx) => const CreditNoteDialog(),
              ),
            ),
          ] else ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Credit & Debit Notes", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    SizedBox(height: 4),
                    Text("Sales returns, post-sale discounts, and downward adjustments linked to invoices.", style: TextStyle(fontSize: 13, color: Colors.grey)),
                  ],
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                  icon: const Icon(Icons.post_add),
                  label: const Text("Issue Note"),
                  onPressed: () => showDialog(
                    context: context,
                    builder: (ctx) => const CreditNoteDialog(),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          Expanded(
            child: state.creditNotes.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.assignment_turned_in_outlined, size: 48, color: Colors.grey),
                        SizedBox(height: 12),
                        Text("No credit or debit notes issued yet.", style: TextStyle(color: Colors.grey, fontSize: 14)),
                      ],
                    ),
                  )
                : Card(
                    elevation: 1,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: ListView.separated(
                      itemCount: state.creditNotes.length,
                      separatorBuilder: (ctx, i) => const Divider(height: 1),
                      itemBuilder: (ctx, i) {
                        final n = state.creditNotes[i];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: n.noteType == "CreditNote" ? Colors.red.withValues(alpha: 0.12) : Colors.blue.withValues(alpha: 0.12),
                            child: Icon(
                              n.noteType == "CreditNote" ? Icons.arrow_downward : Icons.arrow_upward,
                              color: n.noteType == "CreditNote" ? Colors.red : Colors.blue,
                              size: 18,
                            ),
                          ),
                          title: Row(
                            children: [
                              Flexible(child: Text(n.creditNoteNumber, style: const TextStyle(fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: n.noteType == "CreditNote" ? Colors.red.withValues(alpha: 0.12) : Colors.blue.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(n.noteType, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: n.noteType == "CreditNote" ? Colors.red : Colors.blue)),
                              ),
                              const SizedBox(width: 8),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(CurrencyFormatter.format(n.grandTotal), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              ),
                            ],
                          ),
                          subtitle: Text(
                            "Against Invoice: ${n.invoiceNumber} • Date: ${DateFormat("dd MMM yyyy, HH:mm").format(n.creditNoteDateUtc)}\nReason: ${n.reason} (Tax: ${CurrencyFormatter.format(n.totalTaxAmount)})",
                            style: const TextStyle(fontSize: 12),
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryTab(BuildContext context, GstState state) {
    final summary = state.gstSummary;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isMobile = screenWidth < 750;

    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 14.0 : 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isMobile) ...[
            const Text("GSTR-1 Tax Summary", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(
              "Period: ${DateFormat("dd MMM yyyy").format(state.summaryFrom)} - ${DateFormat("dd MMM yyyy").format(state.summaryTo)}",
              style: const TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text("Refresh Summary"),
              onPressed: () => ref.read(gstNotifierProvider.notifier).loadSummary(),
            ),
          ] else ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("GSTR-1 Tax Summary", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(
                      "Period: ${DateFormat("dd MMM yyyy").format(state.summaryFrom)} - ${DateFormat("dd MMM yyyy").format(state.summaryTo)}",
                      style: const TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                  ],
                ),
                OutlinedButton.icon(
                  icon: const Icon(Icons.refresh),
                  label: const Text("Refresh Summary"),
                  onPressed: () => ref.read(gstNotifierProvider.notifier).loadSummary(),
                ),
              ],
            ),
          ],
          const SizedBox(height: 20),
          if (summary == null)
            const Center(child: Text("Click Refresh to load GST report.", style: TextStyle(color: Colors.grey)))
          else ...[
            // Top Summary Cards
            if (isMobile)
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  SizedBox(
                    width: (screenWidth - 28 - 10) / 2,
                    child: _buildMetricCard("B2C Sales", CurrencyFormatter.format(summary.b2cSummary.grandTotal), "${summary.b2cSummary.totalInvoices} Invoices", Colors.blue),
                  ),
                  SizedBox(
                    width: (screenWidth - 28 - 10) / 2,
                    child: _buildMetricCard("B2B Sales", CurrencyFormatter.format(summary.b2bSummary.grandTotal), "${summary.b2bSummary.totalInvoices} Invoices", Colors.purple),
                  ),
                  SizedBox(
                    width: (screenWidth - 28 - 10) / 2,
                    child: _buildMetricCard("Credit Notes", CurrencyFormatter.format(summary.creditNotesSummary.totalTaxableReduced), "${summary.creditNotesSummary.totalCount} Notes", Colors.orange),
                  ),
                  SizedBox(
                    width: (screenWidth - 28 - 10) / 2,
                    child: _buildMetricCard("Net Taxable Sales", CurrencyFormatter.format(summary.creditNotesSummary.netSalesLiability), "Tax Liability Basis", Colors.green),
                  ),
                ],
              )
            else
              Row(
                children: [
                  Expanded(
                    child: _buildMetricCard("B2C Sales", CurrencyFormatter.format(summary.b2cSummary.grandTotal), "${summary.b2cSummary.totalInvoices} Invoices", Colors.blue),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMetricCard("B2B Sales", CurrencyFormatter.format(summary.b2bSummary.grandTotal), "${summary.b2bSummary.totalInvoices} Invoices", Colors.purple),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMetricCard("Credit Notes", CurrencyFormatter.format(summary.creditNotesSummary.totalTaxableReduced), "${summary.creditNotesSummary.totalCount} Notes", Colors.orange),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMetricCard("Net Taxable Sales", CurrencyFormatter.format(summary.creditNotesSummary.netSalesLiability), "Tax Liability Basis", Colors.green),
                  ),
                ],
              ),
            const SizedBox(height: 24),

            // B2B Invoices Section
            const Text("B2B Invoices (Business with Customer GSTIN)", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: summary.b2bSummary.invoices.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text("No B2B invoices in this period.", style: TextStyle(color: Colors.grey)),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: summary.b2bSummary.invoices.length,
                      separatorBuilder: (ctx, i) => const Divider(height: 1),
                      itemBuilder: (ctx, i) {
                        final inv = summary.b2bSummary.invoices[i];
                        return ListTile(
                          title: Text("${inv.invoiceNumber} - ${inv.customerName}"),
                          subtitle: Text("GSTIN: ${inv.customerGstin} • Taxable: ${CurrencyFormatter.format(inv.taxableValue)} • Tax: ${CurrencyFormatter.format(inv.totalTax)}"),
                          trailing: Text(CurrencyFormatter.format(inv.grandTotal), style: const TextStyle(fontWeight: FontWeight.bold)),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 24),

            // HSN-wise Summary Table
            const Text("HSN Summary (Item Wise Tax Breakdown)", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: summary.hsnSummary.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text("No item sales in this period.", style: TextStyle(color: Colors.grey)),
                    )
                  : SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columns: const [
                          DataColumn(label: Text("HSN Code")),
                          DataColumn(label: Text("Description")),
                          DataColumn(label: Text("Quantity")),
                          DataColumn(label: Text("Taxable Value")),
                          DataColumn(label: Text("CGST")),
                          DataColumn(label: Text("SGST")),
                          DataColumn(label: Text("Total Tax")),
                        ],
                        rows: summary.hsnSummary.map((h) {
                          return DataRow(
                            cells: [
                              DataCell(Text(h.hsnCode, style: const TextStyle(fontWeight: FontWeight.bold))),
                              DataCell(Text(h.description)),
                              DataCell(Text("${h.totalQuantity}")),
                              DataCell(Text(CurrencyFormatter.format(h.taxableValue))),
                              DataCell(Text(CurrencyFormatter.format(h.cgstAmount))),
                              DataCell(Text(CurrencyFormatter.format(h.sgstAmount))),
                              DataCell(Text(CurrencyFormatter.format(h.totalTax), style: const TextStyle(fontWeight: FontWeight.bold))),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, String subtitle, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 4),
          Text(subtitle, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        ],
      ),
    );
  }
}
