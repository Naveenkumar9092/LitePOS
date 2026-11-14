import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:go_router/go_router.dart";
import "../../../core/constants/api_endpoints.dart";
import "../../../core/routing/route_names.dart";
import "../../../core/theme/app_colors.dart";
import "../../../shared/widgets/app_button.dart";
import "../../../shared/widgets/app_card.dart";
import "../../../shared/widgets/status_badge.dart";
import "../data/company_repository.dart";
import "../models/company_model.dart";

final companyProfileProvider = FutureProvider.autoDispose<CompanyProfileModel>((ref) async {
  final repo = ref.watch(companyRepositoryProvider);
  return await repo.getProfile();
});

class CompanyProfileScreen extends ConsumerWidget {
  const CompanyProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(companyProfileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Company & Shop Profile"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: "Refresh Profile",
            onPressed: () => ref.refresh(companyProfileProvider),
          ),
        ],
      ),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.storefront, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              const Text(
                "No Company Configured",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text("Setup your business details to start billing"),
              const SizedBox(height: 24),
              AppButton(
                text: "Start Setup",
                icon: Icons.add_business,
                onPressed: () => context.go(RouteNames.companySetup),
              ),
            ],
          ),
        ),
        data: (profile) => SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeaderCard(context, profile),
              const SizedBox(height: 20),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 3, child: _buildCompanyDetailsCard(context, profile)),
                  const SizedBox(width: 20),
                  Expanded(flex: 2, child: _buildShopDetailsCard(context, profile)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCard(BuildContext context, CompanyProfileModel profile) {
    return AppCard(
      backgroundColor: AppColors.primaryContainer,
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4),
                ],
              ),
              child: profile.logoStorageKey != null && profile.logoStorageKey!.isNotEmpty
                  ? Image.network(
                      profile.logoStorageKey!.startsWith("http")
                          ? profile.logoStorageKey!
                          : "${ApiEndpoints.baseUrl.replaceAll("/api/v1", "")}${profile.logoStorageKey!}",
                      fit: BoxFit.cover,
                      errorBuilder: (c, e, s) => Container(
                        color: AppColors.primary,
                        child: const Icon(Icons.store, color: Colors.white, size: 32),
                      ),
                    )
                  : Container(
                      color: AppColors.primary,
                      child: const Icon(Icons.store, color: Colors.white, size: 32),
                    ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      profile.companyName,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.onPrimaryContainer,
                          ),
                    ),
                    const SizedBox(width: 12),
                    StatusBadge(
                      label: profile.businessCategory.title,
                      type: BadgeType.info,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  profile.legalName ?? "Sole Proprietorship",
                  style: TextStyle(color: AppColors.onPrimaryContainer.withAlpha(200)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompanyDetailsCard(BuildContext context, CompanyProfileModel profile) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Registration Details", style: Theme.of(context).textTheme.titleLarge),
          const Divider(height: 24),
          _buildInfoRow("GSTIN", profile.gstin ?? "Unregistered"),
          _buildInfoRow("PAN", profile.pan ?? "Not provided"),
          _buildInfoRow("Official Email", profile.email),
          _buildInfoRow("Mobile Number", profile.mobileNumber),
          _buildInfoRow("Website", profile.website ?? "Not provided"),
          _buildInfoRow("Business Category", profile.businessCategory.title),
        ],
      ),
    );
  }

  Widget _buildShopDetailsCard(BuildContext context, CompanyProfileModel profile) {
    final shop = profile.shop;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Active Shop Counter", style: Theme.of(context).textTheme.titleLarge),
          const Divider(height: 24),
          if (shop != null) ...[
            _buildInfoRow("Shop Name", shop.shopName),
            _buildInfoRow("Counter Phone", shop.contactNumber),
            _buildInfoRow("Counter Email", shop.email),
            _buildInfoRow(
              "Address",
              "${shop.addressLine1}${shop.addressLine2 != null ? ', ${shop.addressLine2}' : ''}, ${shop.city}, ${shop.state} - ${shop.pincode}",
            ),
            _buildInfoRow("Currency", shop.currencyCode),
            _buildInfoRow("Time Zone", shop.timeZone),
          ] else ...[
            const Text("No active shop linked."),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black54, fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

