import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:intl/intl.dart";
import "package:billing_pos_app/core/theme/app_colors.dart";
import "package:billing_pos_app/shared/widgets/app_button.dart";
import "package:billing_pos_app/shared/widgets/app_card.dart";
import "package:billing_pos_app/shared/widgets/status_badge.dart";
import "sync_state.dart";

class SyncManagementScreen extends ConsumerWidget {
  const SyncManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(syncNotifierProvider);
    final notifier = ref.read(syncNotifierProvider.notifier);
    final isMobile = MediaQuery.sizeOf(context).width < 700;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Offline Sync Engine"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: "Refresh Sync Status",
            onPressed: () {
              notifier.checkPending();
              notifier.loadHistory();
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isMobile ? 12 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner messages
            if (state.successMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade300),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green),
                    const SizedBox(width: 12),
                    Expanded(child: Text(state.successMessage!, style: const TextStyle(color: Colors.green))),
                  ],
                ),
              ),
            ],
            if (state.errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade300),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red),
                    const SizedBox(width: 12),
                    Expanded(child: Text(state.errorMessage!, style: const TextStyle(color: Colors.red))),
                  ],
                ),
              ),
            ],

            // Top Status & Sync Action Card
            AppCard(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Sync Icon Avatar (Orange)
                        Container(
                          width: isMobile ? 48 : 64,
                          height: isMobile ? 48 : 64,
                          decoration: BoxDecoration(
                            color: Colors.orange.shade700,
                            shape: BoxShape.circle,
                          ),
                          child: state.isSyncing
                              ? Padding(
                                  padding: EdgeInsets.all(isMobile ? 12 : 16),
                                  child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                                )
                              : Icon(Icons.sync, color: Colors.white, size: isMobile ? 26 : 36),
                        ),
                        SizedBox(width: isMobile ? 12 : 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Terminal Sync Status",
                                style: TextStyle(fontSize: isMobile ? 16 : 20, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 8,
                                runSpacing: 6,
                                children: [
                                  StatusBadge(
                                    label: state.isOnline ? "Online (Cloud Connected)" : "Offline Mode",
                                    type: state.isOnline ? BadgeType.success : BadgeType.warning,
                                  ),
                                  StatusBadge(
                                    label: "${state.pendingOutboxCount} Pending Changes",
                                    type: state.pendingOutboxCount == 0 ? BadgeType.info : BadgeType.warning,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                state.lastSyncTime != null
                                    ? "Last Synced: ${DateFormat('dd MMM yyyy, hh:mm a').format(state.lastSyncTime!.toLocal())}"
                                    : "Last Synced: Not yet synced in this session",
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        AppButton(
                          text: state.isSyncing ? "Syncing..." : "Sync Now",
                          icon: Icons.sync,
                          isLoading: state.isSyncing,
                          onPressed: state.isSyncing ? null : () => notifier.syncNow(),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Device Information Card
            AppCard(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "POS Terminal Information",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 14),
                    if (isMobile) ...[
                      _buildInfoItem(
                        "Device ID",
                        state.deviceStatus?.deviceId ?? "POS-TERM-01",
                        Icons.devices,
                      ),
                      const SizedBox(height: 10),
                      _buildInfoItem(
                        "Terminal Name",
                        state.deviceStatus?.deviceName ?? "Counter 1 Terminal",
                        Icons.point_of_sale,
                      ),
                      const SizedBox(height: 10),
                      _buildInfoItem(
                        "App Version",
                        state.deviceStatus?.appVersion ?? "1.0.0",
                        Icons.info_outline,
                      ),
                    ] else ...[
                      Row(
                        children: [
                          Expanded(
                            child: _buildInfoItem(
                              "Device ID",
                              state.deviceStatus?.deviceId ?? "POS-TERM-01",
                              Icons.devices,
                            ),
                          ),
                          Expanded(
                            child: _buildInfoItem(
                              "Terminal Name",
                              state.deviceStatus?.deviceName ?? "Counter 1 Terminal",
                              Icons.point_of_sale,
                            ),
                          ),
                          Expanded(
                            child: _buildInfoItem(
                              "App Version",
                              state.deviceStatus?.appVersion ?? "1.0.0",
                              Icons.info_outline,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Sync Audit History Log
            AppCard(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Sync Activity Log",
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          icon: const Icon(Icons.refresh, size: 20),
                          tooltip: "Refresh Log",
                          onPressed: () => notifier.loadHistory(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (state.history.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Center(
                          child: Text("No sync events recorded yet. Tap 'Sync Now' to perform a sync."),
                        ),
                      )
                    else
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          columns: const [
                            DataColumn(label: Text("Timestamp")),
                            DataColumn(label: Text("Sync Type")),
                            DataColumn(label: Text("Status")),
                            DataColumn(label: Text("Pushed")),
                            DataColumn(label: Text("Pulled")),
                            DataColumn(label: Text("Duration")),
                          ],
                          rows: state.history.map((log) {
                            return DataRow(cells: [
                              DataCell(Text(DateFormat("dd/MM/yyyy HH:mm:ss").format(log.startedAtUtc.toLocal()))),
                              DataCell(Text(log.syncType, style: const TextStyle(fontWeight: FontWeight.w600))),
                              DataCell(StatusBadge(
                                label: log.status,
                                type: log.status == "Success" ? BadgeType.success : BadgeType.error,
                              )),
                              DataCell(Text("${log.recordsPushed}")),
                              DataCell(Text("${log.recordsPulled}")),
                              DataCell(Text("${log.durationMs} ms")),
                            ]);
                          }).toList(),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(String title, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 24, color: AppColors.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ],
    );
  }
}
