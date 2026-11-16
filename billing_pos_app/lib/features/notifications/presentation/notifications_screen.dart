import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:billing_pos_app/core/theme/app_colors.dart";
import "package:billing_pos_app/features/authentication/presentation/auth_state.dart";
import "../models/notification_models.dart";
import "notification_state.dart";

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Controllers for Tab 1 Settings
  late TextEditingController _headerController;
  late TextEditingController _footerController;
  late TextEditingController _gstRateController;
  late TextEditingController _backupPathController;
  bool _enableEmail = true;
  bool _enableWhatsApp = true;
  bool _autoSendOnPayment = false;
  bool _soundAlerts = true;

  bool _initializedControllers = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _headerController = TextEditingController();
    _footerController = TextEditingController();
    _gstRateController = TextEditingController(text: "5.0");
    _backupPathController = TextEditingController(text: r"C:\LitePOS\Backups");
  }

  @override
  void dispose() {
    _tabController.dispose();
    _headerController.dispose();
    _footerController.dispose();
    _gstRateController.dispose();
    _backupPathController.dispose();
    super.dispose();
  }

  void _syncPreferencesToForm(ShopPreferenceModel? prefs) {
    if (prefs == null || _initializedControllers) return;
    _headerController.text = prefs.receiptHeaderCustom ?? "";
    _footerController.text = prefs.receiptFooterCustom ?? "";
    _gstRateController.text = prefs.defaultGstRate.toStringAsFixed(1);
    _backupPathController.text = prefs.backupDirectoryPath ?? r"C:\LitePOS\Backups";
    _enableEmail = prefs.enableEmailInvoicing;
    _enableWhatsApp = prefs.enableWhatsAppInvoicing;
    _autoSendOnPayment = prefs.autoSendInvoiceOnPayment;
    _soundAlerts = prefs.enableSoundAlerts;
    _initializedControllers = true;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(notificationNotifierProvider);
    final authState = ref.watch(authNotifierProvider);
    final user = authState.user;
    final canManageSettings = user?.isAdmin == true || user?.isSAdmin == true;
    final isMobile = MediaQuery.sizeOf(context).width < 700;

    if (state.preferences != null && !_initializedControllers) {
      _syncPreferencesToForm(state.preferences);
    }

    ref.listen<NotificationState>(notificationNotifierProvider, (previous, next) {
      if (next.errorMessage != null && next.errorMessage != previous?.errorMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: AppColors.error,
          ),
        );
      }
      if (next.successMessage != null && next.successMessage != previous?.successMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.successMessage!),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(isMobile ? "Settings & Alerts" : "Settings & Notifications"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: "Refresh Settings",
            onPressed: () => ref.read(notificationNotifierProvider.notifier).init(),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: const [
            Tab(icon: Icon(Icons.store), text: "Store & Receipts"),
            Tab(icon: Icon(Icons.notifications_active), text: "Invoicing Alerts"),
            Tab(icon: Icon(Icons.backup), text: "Backup & System"),
            Tab(icon: Icon(Icons.history), text: "Audit History"),
          ],
        ),
      ),
      body: state.isLoading && state.preferences == null
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildStoreSettingsTab(context, canManageSettings, isMobile),
                _buildInvoicingAlertsTab(context, canManageSettings, isMobile),
                _buildBackupSystemTab(context, state, canManageSettings, isMobile),
                _buildAuditHistoryTab(context, state),
              ],
            ),
    );
  }

  Widget _buildStoreSettingsTab(BuildContext context, bool canManage, bool isMobile) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 12.0 : 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: EdgeInsets.all(isMobile ? 14.0 : 18.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.receipt_long, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Text(
                        "Thermal Receipt Customization",
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: isMobile ? 15 : null,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _headerController,
                    enabled: canManage,
                    decoration: const InputDecoration(
                      labelText: "Custom Receipt Header Greeting",
                      hintText: "e.g. Welcome to Our Artisan Cafe",
                      prefixIcon: Icon(Icons.title),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _footerController,
                    enabled: canManage,
                    decoration: const InputDecoration(
                      labelText: "Custom Receipt Footer Message",
                      hintText: "e.g. Thank you for your visit! Please come again.",
                      prefixIcon: Icon(Icons.text_fields),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (isMobile) ...[
                    TextFormField(
                      controller: _gstRateController,
                      enabled: canManage,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: "Default GST Rate (%)",
                        hintText: "5.0",
                        prefixIcon: Icon(Icons.percent),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text("Audio & Sound Alerts", style: TextStyle(fontSize: 14)),
                      value: _soundAlerts,
                      onChanged: canManage ? (v) => setState(() => _soundAlerts = v) : null,
                    ),
                  ] else ...[
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _gstRateController,
                            enabled: canManage,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: "Default GST Rate (%)",
                              hintText: "5.0",
                              prefixIcon: Icon(Icons.percent),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text("Audio & Sound Alerts"),
                            value: _soundAlerts,
                            onChanged: canManage ? (v) => setState(() => _soundAlerts = v) : null,
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 20),
                  if (canManage)
                    Align(
                      alignment: Alignment.centerRight,
                      child: FilledButton.icon(
                        icon: const Icon(Icons.save),
                        label: const Text("Save Preferences"),
                        onPressed: _saveStorePreferences,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInvoicingAlertsTab(BuildContext context, bool canManage, bool isMobile) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 12.0 : 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: EdgeInsets.all(isMobile ? 14.0 : 18.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.send_to_mobile, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Text(
                        "Automatic Digital Invoicing",
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: isMobile ? 15 : null,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    title: const Text("Enable Email Invoicing"),
                    subtitle: const Text("Send HTML tax invoice to customer email"),
                    secondary: const Icon(Icons.email_outlined, color: Colors.blue),
                    value: _enableEmail,
                    onChanged: canManage ? (v) => setState(() => _enableEmail = v) : null,
                  ),
                  const Divider(),
                  SwitchListTile(
                    title: const Text("Enable WhatsApp Invoicing"),
                    subtitle: const Text("Dispatch instant receipt summary to customer WhatsApp"),
                    secondary: const Icon(Icons.chat_bubble_outline, color: Colors.green),
                    value: _enableWhatsApp,
                    onChanged: canManage ? (v) => setState(() => _enableWhatsApp = v) : null,
                  ),
                  const Divider(),
                  SwitchListTile(
                    title: const Text("Auto-Send on Payment Completion"),
                    subtitle: const Text("Trigger digital invoice automatically after checkout"),
                    secondary: const Icon(Icons.auto_awesome, color: Colors.amber),
                    value: _autoSendOnPayment,
                    onChanged: canManage ? (v) => setState(() => _autoSendOnPayment = v) : null,
                  ),
                  const SizedBox(height: 16),
                  if (isMobile) ...[
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.send, size: 16),
                        label: const Text("Send Manual Invoice"),
                        onPressed: () => _openSendInvoiceDialog(context),
                      ),
                    ),
                    if (canManage) ...[
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          icon: const Icon(Icons.save, size: 16),
                          label: const Text("Save Alert Settings"),
                          onPressed: _saveStorePreferences,
                        ),
                      ),
                    ],
                  ] else ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        OutlinedButton.icon(
                          icon: const Icon(Icons.send),
                          label: const Text("Send Manual Invoice"),
                          onPressed: () => _openSendInvoiceDialog(context),
                        ),
                        if (canManage)
                          FilledButton.icon(
                            icon: const Icon(Icons.save),
                            label: const Text("Save Alert Settings"),
                            onPressed: _saveStorePreferences,
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackupSystemTab(BuildContext context, NotificationState state, bool canManage, bool isMobile) {
    final sys = state.systemInfo;

    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 12.0 : 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isMobile) ...[
            Row(
              children: [
                Expanded(
                  child: _buildMetricTile(
                    icon: Icons.receipt_long,
                    title: "Invoices",
                    value: "${sys?.totalInvoices ?? 0}",
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildMetricTile(
                    icon: Icons.fastfood,
                    title: "Products",
                    value: "${sys?.totalProducts ?? 0}",
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildMetricTile(
                    icon: Icons.people,
                    title: "Customers",
                    value: "${sys?.totalCustomers ?? 0}",
                    color: Colors.purple,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildMetricTile(
                    icon: Icons.print,
                    title: "Printers",
                    value: "${sys?.activePrinters ?? 0}",
                    color: Colors.teal,
                  ),
                ),
              ],
            ),
          ] else ...[
            Row(
              children: [
                Expanded(
                  child: _buildMetricTile(
                    icon: Icons.receipt_long,
                    title: "Total Invoices",
                    value: "${sys?.totalInvoices ?? 0}",
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricTile(
                    icon: Icons.fastfood,
                    title: "Total Products",
                    value: "${sys?.totalProducts ?? 0}",
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricTile(
                    icon: Icons.people,
                    title: "Customers",
                    value: "${sys?.totalCustomers ?? 0}",
                    color: Colors.purple,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricTile(
                    icon: Icons.print,
                    title: "Active Printers",
                    value: "${sys?.activePrinters ?? 0}",
                    color: Colors.teal,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 20),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(18.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isMobile) ...[
                    Row(
                      children: [
                        const Icon(Icons.storage, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "Database Backup & Maintenance",
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                        ),
                      ],
                    ),
                    if (canManage) ...[
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          icon: const Icon(Icons.backup, size: 16),
                          label: const Text("Backup Database Now"),
                          onPressed: () => ref.read(notificationNotifierProvider.notifier).triggerDatabaseBackup(),
                        ),
                      ),
                    ],
                  ] else ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.storage, color: AppColors.primary),
                            const SizedBox(width: 8),
                            Text(
                              "Database Backup & Maintenance",
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        if (canManage)
                          FilledButton.icon(
                            icon: const Icon(Icons.backup),
                            label: const Text("Backup Database Now"),
                            onPressed: () => ref.read(notificationNotifierProvider.notifier).triggerDatabaseBackup(),
                          ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 16),
                  Text(
                    "Database Engine: ${sys?.databaseEngine ?? 'Microsoft SQL Server LocalDB'}",
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "Status: ${sys?.databaseConnected == true ? 'Connected & Healthy' : 'Disconnected'}",
                    style: TextStyle(
                      color: sys?.databaseConnected == true ? Colors.green : Colors.red,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "Last Backup: ${sys?.lastBackupUtc != null ? sys!.lastBackupUtc!.toLocal().toString().split('.')[0] : 'No backup taken yet'}",
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "App Version: ${sys?.appVersion ?? '1.0.0'} (${sys?.environment ?? 'Production'})",
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(title, style: TextStyle(color: Colors.grey.shade700, fontSize: 12)),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
      ),
    );
  }

  Widget _buildAuditHistoryTab(BuildContext context, NotificationState state) {
    if (state.recentLogs.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.history_toggle_off, size: 48, color: Colors.grey.shade400),
              const SizedBox(height: 12),
              const Text("No notification logs recorded yet", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              const Text("Invoices dispatched via Email or WhatsApp will appear here."),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columns: const [
              DataColumn(label: Text("Channel")),
              DataColumn(label: Text("Invoice #")),
              DataColumn(label: Text("Recipient")),
              DataColumn(label: Text("Status")),
              DataColumn(label: Text("Date & Time")),
              DataColumn(label: Text("Reference ID")),
            ],
            rows: state.recentLogs.map((log) {
              return DataRow(
                cells: [
                  DataCell(
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          log.channel == NotificationChannel.email
                              ? Icons.email
                              : Icons.chat_bubble,
                          color: log.channel == NotificationChannel.email ? Colors.blue : Colors.green,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(log.channel == NotificationChannel.email ? "Email" : "WhatsApp"),
                      ],
                    ),
                  ),
                  DataCell(Text(log.invoiceNumber, style: const TextStyle(fontWeight: FontWeight.bold))),
                  DataCell(Text(log.recipient)),
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: log.status == NotificationStatus.sent ? Colors.green.shade100 : Colors.orange.shade100,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        log.status.name.toUpperCase(),
                        style: TextStyle(
                          color: log.status == NotificationStatus.sent ? Colors.green.shade800 : Colors.orange.shade800,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  DataCell(Text(log.sentAtUtc != null ? log.sentAtUtc!.toLocal().toString().split('.')[0] : "-")),
                  DataCell(Text(log.externalReferenceId ?? "-", style: const TextStyle(fontSize: 11, fontFamily: "monospace"))),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  void _saveStorePreferences() {
    final cur = ref.read(notificationNotifierProvider).preferences;
    final model = (cur ?? const ShopPreferenceModel(id: 1)).copyWith(
      receiptHeaderCustom: _headerController.text.trim(),
      receiptFooterCustom: _footerController.text.trim(),
      defaultGstRate: double.tryParse(_gstRateController.text.trim()) ?? 5.0,
      enableEmailInvoicing: _enableEmail,
      enableWhatsAppInvoicing: _enableWhatsApp,
      autoSendInvoiceOnPayment: _autoSendOnPayment,
      enableSoundAlerts: _soundAlerts,
      backupDirectoryPath: _backupPathController.text.trim(),
    );

    ref.read(notificationNotifierProvider.notifier).updatePreferences(model);
  }

  void _openSendInvoiceDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => _ManualInvoiceDialog(
        onSendEmail: (invId, rec) => ref.read(notificationNotifierProvider.notifier).sendInvoiceEmail(invoiceId: invId, recipientOverride: rec),
        onSendWhatsApp: (invId, rec) => ref.read(notificationNotifierProvider.notifier).sendInvoiceWhatsApp(invoiceId: invId, recipientOverride: rec),
      ),
    );
  }
}

class _ManualInvoiceDialog extends StatefulWidget {
  final Future<NotificationResultModel?> Function(int, String?) onSendEmail;
  final Future<NotificationResultModel?> Function(int, String?) onSendWhatsApp;

  const _ManualInvoiceDialog({
    required this.onSendEmail,
    required this.onSendWhatsApp,
  });

  @override
  State<_ManualInvoiceDialog> createState() => _ManualInvoiceDialogState();
}

class _ManualInvoiceDialogState extends State<_ManualInvoiceDialog> {
  final _formKey = GlobalKey<FormState>();
  final _invoiceIdController = TextEditingController(text: "1");
  final _recipientController = TextEditingController();
  NotificationChannel _selectedChannel = NotificationChannel.email;
  bool _isSending = false;

  @override
  void dispose() {
    _invoiceIdController.dispose();
    _recipientController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Dispatch Digital Invoice"),
      content: SizedBox(
        width: 380,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _invoiceIdController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Invoice ID *",
                  hintText: "e.g. 1",
                ),
                validator: (v) {
                  final n = int.tryParse(v ?? "");
                  if (n == null || n <= 0) return "Valid Invoice ID required";
                  return null;
                },
              ),
              const SizedBox(height: 16),
              const Text("Notification Channel", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 6),
              SegmentedButton<NotificationChannel>(
                segments: const [
                  ButtonSegment(value: NotificationChannel.email, label: Text("Email")),
                  ButtonSegment(value: NotificationChannel.whatsApp, label: Text("WhatsApp")),
                ],
                selected: {_selectedChannel},
                onSelectionChanged: (set) => setState(() => _selectedChannel = set.first),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _recipientController,
                decoration: InputDecoration(
                  labelText: _selectedChannel == NotificationChannel.email ? "Recipient Email" : "Recipient WhatsApp / Mobile",
                  hintText: _selectedChannel == NotificationChannel.email ? "customer@example.com" : "9876543210",
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSending ? null : () => Navigator.of(context).pop(),
          child: const Text("Cancel"),
        ),
        FilledButton(
          onPressed: _isSending ? null : _submit,
          child: _isSending
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text("Send Invoice"),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSending = true);

    final invId = int.parse(_invoiceIdController.text.trim());
    final rec = _recipientController.text.trim().isEmpty ? null : _recipientController.text.trim();

    if (_selectedChannel == NotificationChannel.email) {
      await widget.onSendEmail(invId, rec);
    } else {
      await widget.onSendWhatsApp(invId, rec);
    }

    if (mounted) {
      Navigator.of(context).pop();
    }
  }
}

