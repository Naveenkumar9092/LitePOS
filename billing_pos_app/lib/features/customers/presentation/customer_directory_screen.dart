import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:intl/intl.dart";
import "package:billing_pos_app/core/theme/app_colors.dart";
import "package:billing_pos_app/core/utilities/currency_formatter.dart";
import "../models/customer_model.dart";
import "customer_state.dart";
import "widgets/customer_form_dialog.dart";
import "widgets/customer_history_dialog.dart";

class CustomerDirectoryScreen extends ConsumerStatefulWidget {
  const CustomerDirectoryScreen({super.key});

  @override
  ConsumerState<CustomerDirectoryScreen> createState() => _CustomerDirectoryScreenState();
}

class _CustomerDirectoryScreenState extends ConsumerState<CustomerDirectoryScreen> {
  late TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    Future.microtask(() {
      ref.read(customerNotifierProvider.notifier).loadCustomers();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(customerNotifierProvider);

    ref.listen<CustomerState>(customerNotifierProvider, (prev, next) {
      if (next.errorMessage != null && next.errorMessage != prev?.errorMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.errorMessage!), backgroundColor: AppColors.error),
        );
        ref.read(customerNotifierProvider.notifier).clearMessages();
      }
      if (next.successMessage != null && next.successMessage != prev?.successMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.successMessage!), backgroundColor: Colors.green),
        );
        ref.read(customerNotifierProvider.notifier).clearMessages();
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text("Customer Management"),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.person_add),
              label: const Text("Add Customer"),
              onPressed: () => showDialog(
                context: context,
                builder: (ctx) => const CustomerFormDialog(),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search & Filter Header
          Container(
            padding: const EdgeInsets.all(16.0),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: "Search by customer name or 10-digit mobile number...",
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                ref.read(customerNotifierProvider.notifier).onSearchChanged("");
                              },
                            )
                          : null,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    onChanged: (val) {
                      ref.read(customerNotifierProvider.notifier).onSearchChanged(val);
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                  ),
                  child: Text(
                    "Total: ${state.totalCount} Customers",
                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Customer List
          Expanded(
            child: state.isLoading
                ? const Center(child: CircularProgressIndicator())
                : state.customers.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.people_outline, size: 56, color: Colors.grey),
                            const SizedBox(height: 12),
                            Text(
                              _searchController.text.isNotEmpty
                                  ? "No customers match '${_searchController.text}'."
                                  : "No customers found. Add your first customer!",
                              style: const TextStyle(fontSize: 15, color: Colors.grey),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              icon: const Icon(Icons.add),
                              label: const Text("Quick Add Customer"),
                              onPressed: () => showDialog(
                                context: context,
                                builder: (ctx) => const CustomerFormDialog(),
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16.0),
                        itemCount: state.customers.length,
                        separatorBuilder: (ctx, i) => const SizedBox(height: 10),
                        itemBuilder: (ctx, i) {
                          final c = state.customers[i];
                          return _buildCustomerCard(context, c);
                        },
                      ),
          ),

          // Pagination Controls
          if (state.totalPages > 1)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: Colors.white,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Showing page ${state.page} of ${state.totalPages}", style: const TextStyle(color: Colors.grey)),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left),
                        onPressed: state.page > 1
                            ? () => ref.read(customerNotifierProvider.notifier).loadCustomers(page: state.page - 1)
                            : null,
                      ),
                      Text("${state.page}", style: const TextStyle(fontWeight: FontWeight.bold)),
                      IconButton(
                        icon: const Icon(Icons.chevron_right),
                        onPressed: state.page < state.totalPages
                            ? () => ref.read(customerNotifierProvider.notifier).loadCustomers(page: state.page + 1)
                            : null,
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCustomerCard(BuildContext context, CustomerModel c) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: 24,
              backgroundColor: AppColors.primary.withValues(alpha: 0.12),
              child: Text(
                c.customerName.isNotEmpty ? c.customerName[0].toUpperCase() : "C",
                style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 18),
              ),
            ),
            const SizedBox(width: 16),

            // Customer Details
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        c.customerName,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      if (c.gstin != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.purple.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text("B2B: ${c.gstin}", style: const TextStyle(fontSize: 10, color: Colors.purple, fontWeight: FontWeight.bold)),
                        ),
                      ],
                      if (!c.isActive) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(4)),
                          child: const Text("INACTIVE", style: TextStyle(fontSize: 10, color: Colors.grey)),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.phone_android, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(c.mobileNumber, style: const TextStyle(fontSize: 13, color: Colors.black87)),
                      if (c.whatsAppConsent) ...[
                        const SizedBox(width: 10),
                        const Icon(Icons.chat_bubble, size: 14, color: Colors.green),
                        const SizedBox(width: 2),
                        const Text("WhatsApp Active", style: TextStyle(fontSize: 11, color: Colors.green)),
                      ],
                      if (c.email != null) ...[
                        const SizedBox(width: 12),
                        const Icon(Icons.email_outlined, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(c.email!, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ],
                  ),
                  if (c.address != null) ...[
                    const SizedBox(height: 2),
                    Text(c.address!, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                  ],
                ],
              ),
            ),

            // Spend & Metrics
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    CurrencyFormatter.format(c.totalSpent),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primary),
                  ),
                  Text(
                    "${c.totalInvoicesCount} Orders",
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  if (c.lastVisitDateUtc != null)
                    Text(
                      "Last: ${DateFormat("dd MMM yyyy").format(c.lastVisitDateUtc!)}",
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 16),

            // Actions
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                OutlinedButton.icon(
                  icon: const Icon(Icons.history, size: 16),
                  label: const Text("History"),
                  style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
                  onPressed: () => showDialog(
                    context: context,
                    builder: (ctx) => CustomerHistoryDialog(
                      customerId: c.id,
                      customerName: c.customerName,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 20),
                  tooltip: "Edit Profile",
                  onPressed: () => showDialog(
                    context: context,
                    builder: (ctx) => CustomerFormDialog(customer: c),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

