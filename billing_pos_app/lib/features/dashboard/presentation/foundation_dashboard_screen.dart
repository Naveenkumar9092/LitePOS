import "package:flutter/material.dart";
import "../../../core/theme/app_colors.dart";
import "../../../core/utilities/responsive_layout.dart";
import "../../../shared/widgets/app_card.dart";
import "../../../shared/widgets/status_badge.dart";

class FoundationDashboardScreen extends StatelessWidget {
  const FoundationDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("LitePOS Billing"),
        actions: const [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: StatusBadge(
              label: "SYSTEM READY (v1.0)",
              type: BadgeType.success,
              icon: Icons.check_circle,
            ),
          ),
        ],
      ),
      body: ResponsiveLayout(
        mobile: _buildMobileLayout(context),
        desktop: _buildDesktopLayout(context),
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildWelcomeCard(context),
        const SizedBox(height: 16),
        _buildArchitectureCard(context),
      ],
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildWelcomeCard(context),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 3, child: _buildArchitectureCard(context)),
              const SizedBox(width: 24),
              Expanded(flex: 2, child: _buildTechStackCard(context)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeCard(BuildContext context) {
    return AppCard(
      backgroundColor: AppColors.primaryContainer,
      child: Row(
        children: [
          const Icon(Icons.storefront, size: 48, color: AppColors.primary),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Module 0: Foundation & Architecture Active",
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: AppColors.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Offline-first SQLite & Cloud SQL Server Clean Architecture ready for business modules.",
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.onPrimaryContainer,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildArchitectureCard(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Foundation Checklist", style: Theme.of(context).textTheme.titleLarge),
              const StatusBadge(label: "VERIFIED", type: BadgeType.success),
            ],
          ),
          const Divider(height: 24),
          _buildCheckItem("ASP.NET Core Web API (.NET 10) Clean Architecture", true),
          _buildCheckItem("Entity Framework Core with SQL Server & SQLite Providers", true),
          _buildCheckItem("Standardized ApiResponse { success, message, data, errors }", true),
          _buildCheckItem("Global Exception Handling & Structured Logging Middleware", true),
          _buildCheckItem("API Versioning (/api/v1) & Swagger Documentation", true),
          _buildCheckItem("Flutter Riverpod State Management & GoRouter Shell", true),
          _buildCheckItem("Local SQLite Persistence & Sync Outbox Scaffolding", true),
          _buildCheckItem("Material 3 Theme & Responsive Layouts (Mobile/Desktop)", true),
        ],
      ),
    );
  }

  Widget _buildTechStackCard(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Target Profiles", style: Theme.of(context).textTheme.titleLarge),
          const Divider(height: 24),
          const ListTile(
            dense: true,
            leading: Icon(Icons.coffee, color: AppColors.primary),
            title: Text("1. Cafe"),
            subtitle: Text("Beverages, snacks & fast counter billing"),
          ),
          const ListTile(
            dense: true,
            leading: Icon(Icons.fastfood, color: AppColors.primary),
            title: Text("2. Food Court"),
            subtitle: Text("High-speed orders & token receipts"),
          ),
          const ListTile(
            dense: true,
            leading: Icon(Icons.icecream, color: AppColors.primary),
            title: Text("3. Ice Cream & Desserts"),
            subtitle: Text("Quick dessert selection & split payment"),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckItem(String text, bool completed) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Icon(
            completed ? Icons.check_circle : Icons.radio_button_unchecked,
            color: completed ? AppColors.success : Colors.grey,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text, style: const TextStyle(fontSize: 13)),
          ),
        ],
      ),
    );
  }
}

