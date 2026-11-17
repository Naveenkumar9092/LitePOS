import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:billing_pos_app/core/theme/app_colors.dart";
import "package:billing_pos_app/features/authentication/presentation/auth_state.dart";
import "../models/discovered_printer_model.dart";
import "../models/printer_model.dart";
import "hardware_state.dart";

class HardwareSettingsScreen extends ConsumerStatefulWidget {
  const HardwareSettingsScreen({super.key});

  @override
  ConsumerState<HardwareSettingsScreen> createState() => _HardwareSettingsScreenState();
}

class _HardwareSettingsScreenState extends ConsumerState<HardwareSettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(hardwareNotifierProvider);
    final authState = ref.watch(authNotifierProvider);
    final user = authState.user;
    final canManagePrinters = user?.isAdmin == true || user?.isSAdmin == true;
    final isMobile = MediaQuery.sizeOf(context).width < 700;

    ref.listen<HardwareState>(hardwareNotifierProvider, (previous, next) {
      if (next.errorMessage != null && next.errorMessage != previous?.errorMessage) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(next.errorMessage!),
                backgroundColor: AppColors.error,
              ),
            );
          }
        });
      }
      if (next.successMessage != null && next.successMessage != previous?.successMessage) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(next.successMessage!),
                backgroundColor: AppColors.primary,
              ),
            );
          }
        });
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Hardware & Thermal Printers"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: "Refresh Printers",
            onPressed: () => ref.read(hardwareNotifierProvider.notifier).loadPrinters(),
          ),
          IconButton(
            icon: const Icon(Icons.point_of_sale),
            tooltip: "Test Cash Drawer Kick",
            onPressed: () => _handleDrawerKick(context),
          ),
        ],
      ),
      floatingActionButton: canManagePrinters
          ? FloatingActionButton.extended(
              onPressed: () => _openAddEditPrinterDialog(context, null),
              icon: const Icon(Icons.add),
              label: const Text("Add Printer"),
            )
          : null,
      body: state.isLoading && state.printers.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => ref.read(hardwareNotifierProvider.notifier).loadPrinters(),
              child: SingleChildScrollView(
                padding: EdgeInsets.all(isMobile ? 12.0 : 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildActivePrinterBanner(context, state.defaultPrinter, isMobile),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            "Configured Printers (${state.printers.length})",
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  fontSize: isMobile ? 15 : null,
                                ),
                          ),
                        ),
                        OutlinedButton.icon(
                          icon: const Icon(Icons.point_of_sale_outlined, size: 16),
                          label: const Text("Kick Cash Drawer", style: TextStyle(fontSize: 12)),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            visualDensity: VisualDensity.compact,
                          ),
                          onPressed: () => _handleDrawerKick(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (state.printers.isEmpty)
                      _buildEmptyState(context, canManagePrinters)
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: state.printers.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final printer = state.printers[index];
                          return _buildPrinterCard(context, printer, canManagePrinters, isMobile);
                        },
                      ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildActivePrinterBanner(BuildContext context, PrinterConfigurationModel? defaultPrinter, bool isMobile) {
    if (defaultPrinter == null) {
      return Card(
        color: Colors.amber.shade50,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.amber.shade300),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.amber.shade800, size: 32),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "No Default Printer Set",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.amber.shade900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      "Please configure or set a default ESC/POS printer to enable receipt printing at checkout.",
                      style: TextStyle(fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isMobile) ...[
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.print, color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                defaultPrinter.printerName,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.green,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Text(
                                "DEFAULT",
                                style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          "${defaultPrinter.connectionType.name.toUpperCase()} • ${defaultPrinter.paperSize == PrinterPaperSize.mm58 ? '58mm' : '80mm'}",
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _handleTestPrint(context, defaultPrinter.id),
                  icon: const Icon(Icons.receipt, size: 16),
                  label: const Text("Test Print"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ),
            ] else ...[
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.print, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                defaultPrinter.printerName,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.green,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                "DEFAULT",
                                style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "${defaultPrinter.connectionType.name.toUpperCase()} | "
                          "${defaultPrinter.paperSize == PrinterPaperSize.mm58 ? '58mm (32 col)' : '80mm (48 col)'} | "
                          "${defaultPrinter.connectionType == PrinterConnectionType.network ? '${defaultPrinter.ipAddress ?? "192.168.1.100"}:${defaultPrinter.port}' : (defaultPrinter.usbDeviceName ?? 'USB001')}",
                          style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _handleTestPrint(context, defaultPrinter.id),
                    icon: const Icon(Icons.receipt, size: 16),
                    label: const Text("Test Print"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                _buildFeatureBadge(
                  icon: Icons.content_cut,
                  label: "Auto-Cut",
                  isEnabled: defaultPrinter.autoCutReceipt,
                ),
                _buildFeatureBadge(
                  icon: Icons.point_of_sale,
                  label: "Cash Drawer",
                  isEnabled: defaultPrinter.openCashDrawer,
                ),
                _buildFeatureBadge(
                  icon: Icons.qr_code,
                  label: "UPI QR Code",
                  isEnabled: defaultPrinter.printQrCode,
                ),
                _buildFeatureBadge(
                  icon: Icons.copy,
                  label: "Copies: ${defaultPrinter.printCopies}",
                  isEnabled: true,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureBadge({
    required IconData icon,
    required String label,
    required bool isEnabled,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 16,
          color: isEnabled ? Colors.green.shade700 : Colors.grey.shade500,
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isEnabled ? Colors.grey.shade900 : Colors.grey.shade500,
          ),
        ),
      ],
    );
  }

  Widget _buildPrinterCard(
    BuildContext context,
    PrinterConfigurationModel printer,
    bool canManage,
    bool isMobile,
  ) {
    return Card(
      elevation: printer.isDefault ? 2 : 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: printer.isDefault ? AppColors.primary : Colors.grey.shade300,
          width: printer.isDefault ? 1.5 : 1.0,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  printer.connectionType == PrinterConnectionType.network
                      ? Icons.lan
                      : printer.connectionType == PrinterConnectionType.usb
                          ? Icons.usb
                          : Icons.bluetooth,
                  color: AppColors.primary,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              printer.printerName,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (printer.isDefault) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.green.shade100,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                "DEFAULT",
                                style: TextStyle(
                                  color: Colors.green.shade800,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _getConnectionDetailString(printer),
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.blueGrey.shade50,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    printer.paperSize == PrinterPaperSize.mm58 ? "58mm" : "80mm",
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueGrey.shade800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              alignment: WrapAlignment.end,
              spacing: 8,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _handleTestPrint(context, printer.id),
                  icon: const Icon(Icons.print_outlined, size: 14),
                  label: const Text("Test Print", style: TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
                if (!printer.isDefault && canManage) ...[
                  OutlinedButton(
                    onPressed: () => ref.read(hardwareNotifierProvider.notifier).setDefaultPrinter(printer.id),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      visualDensity: VisualDensity.compact,
                    ),
                    child: const Text("Set Default", style: TextStyle(fontSize: 12)),
                  ),
                ],
                if (canManage) ...[
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    visualDensity: VisualDensity.compact,
                    tooltip: "Edit Printer",
                    onPressed: () => _openAddEditPrinterDialog(context, printer),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.error),
                    visualDensity: VisualDensity.compact,
                    tooltip: "Delete Printer",
                    onPressed: () => _confirmDeletePrinter(context, printer),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getConnectionDetailString(PrinterConfigurationModel p) {
    switch (p.connectionType) {
      case PrinterConnectionType.network:
        return "Network TCP/IP: ${p.ipAddress ?? '192.168.1.100'}:${p.port}";
      case PrinterConnectionType.usb:
        return "USB Device: ${p.usbDeviceName ?? 'POS-80'}";
      case PrinterConnectionType.bluetooth:
        return "Bluetooth MAC: ${p.bluetoothMacAddress ?? '00:11:22:33:44:55'}";
    }
  }

  Widget _buildEmptyState(BuildContext context, bool canManage) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48.0),
        child: Column(
          children: [
            Icon(Icons.print_disabled, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            const Text(
              "No thermal printers configured yet",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              "Add an ESC/POS 80mm or 58mm printer to enable receipt generation.",
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 16),
            if (canManage)
              ElevatedButton.icon(
                onPressed: () => _openAddEditPrinterDialog(context, null),
                icon: const Icon(Icons.add),
                label: const Text("Add First Printer"),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleDrawerKick(BuildContext context) async {
    final result = await ref.read(hardwareNotifierProvider.notifier).openCashDrawer();
    if (result != null && context.mounted) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.point_of_sale, color: AppColors.primary),
              SizedBox(width: 8),
              Text("Cash Drawer Signal"),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Cash drawer pulse generated successfully:"),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  "Hex Command: ${result.hexString}\nCommand: ${result.commandName}",
                  style: const TextStyle(fontFamily: "monospace", fontSize: 13),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text("OK"),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _handleTestPrint(BuildContext context, int printerId) async {
    final result = await ref.read(hardwareNotifierProvider.notifier).testPrint(printerId: printerId);
    if (result != null && context.mounted) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.receipt_long, color: AppColors.primary),
              const SizedBox(width: 8),
              Text("Receipt Preview (${result.printerName})"),
            ],
          ),
          content: SizedBox(
            width: 420,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      border: Border.all(color: Colors.grey.shade400),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      result.plainTextPreview,
                      style: const TextStyle(
                        fontFamily: "monospace",
                        fontSize: 12,
                        height: 1.25,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Bytes: ${result.byteCount} bytes",
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                      Text(
                        "Paper: ${result.paperSize == PrinterPaperSize.mm58 ? '58mm' : '80mm'}",
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          actions: [
            FilledButton.icon(
              icon: const Icon(Icons.print, size: 16),
              label: const Text("Direct Physical Print"),
              onPressed: () async {
                Navigator.of(ctx).pop();
                final state = ref.read(hardwareNotifierProvider);
                final printer = state.printers.firstWhere(
                  (p) => p.id == printerId,
                  orElse: () => state.defaultPrinter ?? PrinterConfigurationModel(id: printerId, printerName: result.printerName),
                );
                final ok = await ref.read(hardwareNotifierProvider.notifier).directTestPrint(printer);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(ok
                          ? "Test receipt sent to '${printer.printerName}'!"
                          : "Could not transmit to physical printer. Verify device is paired or IP is reachable."),
                      backgroundColor: ok ? AppColors.primary : AppColors.error,
                    ),
                  );
                }
              },
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text("Close"),
            ),
          ],
        ),
      );
    }
  }

  void _openAddEditPrinterDialog(BuildContext context, PrinterConfigurationModel? printer) {
    showDialog(
      context: context,
      builder: (ctx) => _PrinterFormDialog(
        printer: printer,
        onSave: (config) async {
          if (printer == null) {
            await ref.read(hardwareNotifierProvider.notifier).createPrinter(config);
          } else {
            await ref.read(hardwareNotifierProvider.notifier).updatePrinter(printer.id, config);
          }
        },
      ),
    );
  }

  void _confirmDeletePrinter(BuildContext context, PrinterConfigurationModel printer) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Printer?"),
        content: Text("Are you sure you want to delete '${printer.printerName}'?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text("Cancel"),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              Navigator.of(ctx).pop();
              ref.read(hardwareNotifierProvider.notifier).deletePrinter(printer.id);
            },
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }
}

class _PrinterFormDialog extends ConsumerStatefulWidget {
  final PrinterConfigurationModel? printer;
  final Future<void> Function(PrinterConfigurationModel) onSave;

  const _PrinterFormDialog({
    required this.printer,
    required this.onSave,
  });

  @override
  ConsumerState<_PrinterFormDialog> createState() => _PrinterFormDialogState();
}

class _PrinterFormDialogState extends ConsumerState<_PrinterFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _ipController;
  late TextEditingController _portController;
  late TextEditingController _usbNameController;
  late TextEditingController _btMacController;
  late TextEditingController _headerController;
  late TextEditingController _footerController;

  late PrinterConnectionType _connectionType;
  late PrinterPaperSize _paperSize;
  late bool _autoCut;
  late bool _openDrawer;
  late bool _printQr;
  late bool _isDefault;
  late int _copies;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final p = widget.printer;
    _nameController = TextEditingController(text: p?.printerName ?? "");
    _ipController = TextEditingController(text: p?.ipAddress ?? "192.168.1.100");
    _portController = TextEditingController(text: (p?.port ?? 9100).toString());
    _usbNameController = TextEditingController(text: p?.usbDeviceName ?? "POS-80");
    _btMacController = TextEditingController(text: p?.bluetoothMacAddress ?? "00:11:22:33:44:55");
    _headerController = TextEditingController(text: p?.headerCustomText ?? "");
    _footerController = TextEditingController(text: p?.footerCustomText ?? "");

    _connectionType = p?.connectionType ?? PrinterConnectionType.network;
    _paperSize = p?.paperSize ?? PrinterPaperSize.mm80;
    _autoCut = p?.autoCutReceipt ?? true;
    _openDrawer = p?.openCashDrawer ?? true;
    _printQr = p?.printQrCode ?? true;
    _isDefault = p?.isDefault ?? false;
    _copies = p?.printCopies ?? 1;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ipController.dispose();
    _portController.dispose();
    _usbNameController.dispose();
    _btMacController.dispose();
    _headerController.dispose();
    _footerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.printer != null;

    return AlertDialog(
      title: Text(isEdit ? "Edit Printer" : "Add Thermal Printer"),
      content: SizedBox(
        width: 480,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: "Printer Name *",
                    hintText: "e.g. Counter Thermal 80mm",
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? "Printer name is required" : null,
                ),
                const SizedBox(height: 16),
                const Text("Connection Type", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 6),
                SegmentedButton<PrinterConnectionType>(
                  segments: const [
                    ButtonSegment(value: PrinterConnectionType.network, label: Text("Network")),
                    ButtonSegment(value: PrinterConnectionType.usb, label: Text("USB")),
                    ButtonSegment(value: PrinterConnectionType.bluetooth, label: Text("Bluetooth")),
                  ],
                  selected: {_connectionType},
                  onSelectionChanged: (set) {
                    setState(() => _connectionType = set.first);
                  },
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.radar, size: 16),
                    label: Text("Scan for ${_connectionType.name.toUpperCase()} Printers"),
                    onPressed: () => _scanAndPickPrinter(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                if (_connectionType == PrinterConnectionType.network) ...[
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: TextFormField(
                          controller: _ipController,
                          decoration: const InputDecoration(
                            labelText: "IP Address *",
                            hintText: "192.168.1.100",
                          ),
                          validator: (v) => v == null || v.trim().isEmpty ? "IP address required" : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: TextFormField(
                          controller: _portController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: "Port",
                            hintText: "9100",
                          ),
                          validator: (v) {
                            final n = int.tryParse(v ?? "");
                            if (n == null || n < 1 || n > 65535) return "Invalid";
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                ] else if (_connectionType == PrinterConnectionType.usb) ...[
                  TextFormField(
                    controller: _usbNameController,
                    decoration: const InputDecoration(
                      labelText: "USB Device Name",
                      hintText: "e.g. POS-80 or USB001",
                    ),
                  ),
                ] else ...[
                  TextFormField(
                    controller: _btMacController,
                    decoration: const InputDecoration(
                      labelText: "Bluetooth MAC Address",
                      hintText: "00:11:22:33:44:55",
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                const Text("Paper Size", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 6),
                SegmentedButton<PrinterPaperSize>(
                  segments: const [
                    ButtonSegment(value: PrinterPaperSize.mm80, label: Text("80mm (48 Col)")),
                    ButtonSegment(value: PrinterPaperSize.mm58, label: Text("58mm (32 Col)")),
                  ],
                  selected: {_paperSize},
                  onSelectionChanged: (set) {
                    setState(() => _paperSize = set.first);
                  },
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text("Auto-Cut Receipt"),
                  subtitle: const Text("Feed and cut paper after printing"),
                  value: _autoCut,
                  onChanged: (v) => setState(() => _autoCut = v),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text("Open Cash Drawer"),
                  subtitle: const Text("Kick drawer latch with pulse code"),
                  value: _openDrawer,
                  onChanged: (v) => setState(() => _openDrawer = v),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text("Print UPI QR Code"),
                  subtitle: const Text("Include dynamic UPI payment QR"),
                  value: _printQr,
                  onChanged: (v) => setState(() => _printQr = v),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text("Set as Default Printer"),
                  value: _isDefault,
                  onChanged: (v) => setState(() => _isDefault = v),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Text("Print Copies:", style: TextStyle(fontWeight: FontWeight.w500)),
                    const SizedBox(width: 16),
                    DropdownButton<int>(
                      value: _copies,
                      items: [1, 2, 3, 4, 5]
                          .map((n) => DropdownMenuItem(value: n, child: Text("$n")))
                          .toList(),
                      onChanged: (v) => setState(() => _copies = v ?? 1),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
          child: const Text("Cancel"),
        ),
        FilledButton(
          onPressed: _isSubmitting ? null : _submit,
          child: _isSubmitting
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : Text(isEdit ? "Save Changes" : "Add Printer"),
        ),
      ],
    );
  }

  Future<void> _scanAndPickPrinter(BuildContext context) async {
    final notifier = ref.read(hardwareNotifierProvider.notifier);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (scanCtx) {
        return FutureBuilder<List<DiscoveredPrinterModel>>(
          future: notifier.scanPrinters(_connectionType),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return AlertDialog(
                title: Row(
                  children: [
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: 12),
                    Text("Scanning ${_connectionType.name.toUpperCase()}..."),
                  ],
                ),
                content: const Text(
                  "Discovering nearby paired Bluetooth devices, connected USB printers, or network printers on port 9100...",
                  style: TextStyle(fontSize: 13),
                ),
              );
            }

            final list = snapshot.data ?? [];
            return AlertDialog(
              title: Text("Discovered ${_connectionType.name.toUpperCase()} Printers (${list.length})"),
              content: SizedBox(
                width: 380,
                height: 260,
                child: list.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.print_disabled, size: 48, color: Colors.grey.shade400),
                            const SizedBox(height: 12),
                            Text(
                              "No ${_connectionType.name} printers detected.",
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _connectionType == PrinterConnectionType.bluetooth
                                  ? "Pair your thermal printer in Android Bluetooth settings first."
                                  : _connectionType == PrinterConnectionType.usb
                                      ? "Verify USB OTG cable connection and printer power."
                                      : "Ensure printer is connected to local Wi-Fi / LAN with port 9100 open.",
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        itemCount: list.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (ctx, index) {
                          final item = list[index];
                          return ListTile(
                            leading: Icon(
                              _connectionType == PrinterConnectionType.bluetooth
                                  ? Icons.bluetooth
                                  : _connectionType == PrinterConnectionType.usb
                                      ? Icons.usb
                                      : Icons.lan,
                              color: AppColors.primary,
                            ),
                            title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                            subtitle: Text(item.address, style: const TextStyle(fontSize: 12)),
                            onTap: () {
                              Navigator.of(scanCtx).pop(item);
                            },
                          );
                        },
                      ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(scanCtx).pop(),
                  child: const Text("Close"),
                ),
              ],
            );
          },
        );
      },
    ).then((selected) {
      if (selected is DiscoveredPrinterModel) {
        setState(() {
          _nameController.text = selected.name;
          if (_connectionType == PrinterConnectionType.bluetooth) {
            _btMacController.text = selected.address;
          } else if (_connectionType == PrinterConnectionType.usb) {
            _usbNameController.text = selected.address;
          } else if (_connectionType == PrinterConnectionType.network) {
            _ipController.text = selected.address;
            _portController.text = selected.port.toString();
          }
        });
      }
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    final config = PrinterConfigurationModel(
      id: widget.printer?.id ?? 0,
      printerName: _nameController.text.trim(),
      connectionType: _connectionType,
      ipAddress: _connectionType == PrinterConnectionType.network ? _ipController.text.trim() : null,
      port: int.tryParse(_portController.text.trim()) ?? 9100,
      usbDeviceName: _connectionType == PrinterConnectionType.usb ? _usbNameController.text.trim() : null,
      bluetoothMacAddress: _connectionType == PrinterConnectionType.bluetooth ? _btMacController.text.trim() : null,
      paperSize: _paperSize,
      characterColumns: _paperSize == PrinterPaperSize.mm58 ? 32 : 48,
      autoCutReceipt: _autoCut,
      openCashDrawer: _openDrawer,
      printQrCode: _printQr,
      printCopies: _copies,
      isDefault: _isDefault,
      headerCustomText: _headerController.text.trim().isEmpty ? null : _headerController.text.trim(),
      footerCustomText: _footerController.text.trim().isEmpty ? null : _footerController.text.trim(),
    );

    await widget.onSave(config);
    if (mounted) {
      Navigator.of(context).pop();
    }
  }
}

