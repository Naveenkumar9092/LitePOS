import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:go_router/go_router.dart";
import "../../../core/routing/route_names.dart";
import "../../../core/theme/app_colors.dart";
import "../../../core/utilities/responsive_layout.dart";
import "../../../shared/widgets/app_button.dart";
import "../../../shared/widgets/app_card.dart";
import "../../../shared/widgets/app_image_upload_picker.dart";
import "../../../shared/widgets/app_text_field.dart";
import "../data/company_repository.dart";
import "../models/company_model.dart";

class CompanySetupScreen extends ConsumerStatefulWidget {
  const CompanySetupScreen({super.key});

  @override
  ConsumerState<CompanySetupScreen> createState() => _CompanySetupScreenState();
}

class _CompanySetupScreenState extends ConsumerState<CompanySetupScreen> {
  final _formKey = GlobalKey<FormState>();

  // Form Controllers
  final _companyNameController = TextEditingController();
  final _legalNameController = TextEditingController();
  final _gstinController = TextEditingController();
  final _panController = TextEditingController();
  final _emailController = TextEditingController();
  final _mobileController = TextEditingController();
  final _websiteController = TextEditingController();

  final _shopNameController = TextEditingController();
  final _address1Controller = TextEditingController();
  final _address2Controller = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _pincodeController = TextEditingController();
  final _contactNumberController = TextEditingController();
  final _shopEmailController = TextEditingController();
  final _invoiceHeaderController = TextEditingController();
  final _invoiceFooterController = TextEditingController();

  BusinessCategory _selectedCategory = BusinessCategory.cafe;
  String? _logoUrl;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _companyNameController.dispose();
    _legalNameController.dispose();
    _gstinController.dispose();
    _panController.dispose();
    _emailController.dispose();
    _mobileController.dispose();
    _websiteController.dispose();
    _shopNameController.dispose();
    _address1Controller.dispose();
    _address2Controller.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    _contactNumberController.dispose();
    _shopEmailController.dispose();
    _invoiceHeaderController.dispose();
    _invoiceFooterController.dispose();
    super.dispose();
  }

  Future<void> _submitSetup() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final repo = ref.read(companyRepositoryProvider);
      final payload = {
        "companyName": _companyNameController.text.trim(),
        "legalName": _legalNameController.text.trim(),
        "businessType": _selectedCategory.id,
        "gstin": _gstinController.text.trim().toUpperCase(),
        "pan": _panController.text.trim().toUpperCase(),
        "email": _emailController.text.trim().toLowerCase(),
        "mobileNumber": _mobileController.text.trim(),
        "website": _websiteController.text.trim(),
        "logoStorageKey": _logoUrl,
        "shopName": _shopNameController.text.trim(),
        "addressLine1": _address1Controller.text.trim(),
        "addressLine2": _address2Controller.text.trim(),
        "city": _cityController.text.trim(),
        "state": _stateController.text.trim(),
        "pincode": _pincodeController.text.trim(),
        "country": "India",
        "contactNumber": _contactNumberController.text.trim(),
        "shopEmail": _shopEmailController.text.trim().toLowerCase(),
        "currencyCode": "INR",
        "timeZone": "India Standard Time",
        "invoiceHeader": _invoiceHeaderController.text.trim(),
        "invoiceFooter": _invoiceFooterController.text.trim(),
      };

      await repo.setupCompany(payload);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Company and Shop registered successfully!"),
            backgroundColor: AppColors.success,
          ),
        );
        context.go(RouteNames.adminDashboard);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceFirst("Exception: ", "");
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.sizeOf(context).width < 700;
    return Scaffold(
      appBar: AppBar(
        title: Text(isMobile ? "Company Setup" : "Company & Shop Registration"),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 24, vertical: isMobile ? 12 : 20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.errorContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: AppColors.error),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: AppColors.error, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              _buildCategorySelectionSection(),
              const SizedBox(height: 20),
              _buildCompanyProfileSection(isMobile),
              const SizedBox(height: 20),
              _buildShopDetailsSection(isMobile),
              const SizedBox(height: 20),
              _buildInvoiceDetailsSection(isMobile),
              const SizedBox(height: 32),
              Center(
                child: SizedBox(
                  width: isMobile ? double.infinity : 320,
                  child: AppButton(
                    text: "Complete Setup & Launch POS",
                    icon: Icons.check_circle_outline,
                    isLoading: _isLoading,
                    onPressed: _submitSetup,
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategorySelectionSection() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.store, color: AppColors.primary),
              const SizedBox(width: 8),
              Text("Business Category Selection", style: Theme.of(context).textTheme.titleLarge),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            "Select your business type. This configures the default dashboard and category suggestions.",
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
          const Divider(height: 24),
          ResponsiveLayout(
            mobile: Column(
              children: BusinessCategory.values.map(_buildCategoryCard).toList(),
            ),
            desktop: Row(
              children: BusinessCategory.values.map((c) => Expanded(child: _buildCategoryCard(c))).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(BusinessCategory category) {
    final isSelected = _selectedCategory == category;
    IconData icon;
    switch (category) {
      case BusinessCategory.cafe:
        icon = Icons.coffee;
        break;
      case BusinessCategory.foodCourt:
        icon = Icons.fastfood;
        break;
      case BusinessCategory.iceCreamAndDesserts:
        icon = Icons.icecream;
        break;
    }

    return Padding(
      padding: const EdgeInsets.all(6.0),
      child: InkWell(
        onTap: () => setState(() => _selectedCategory = category),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primaryContainer.withAlpha(80) : Colors.transparent,
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.outlineLight,
              width: isSelected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: isSelected ? AppColors.primary : Colors.grey[700], size: 28),
                  const Spacer(),
                  if (isSelected) const Icon(Icons.check_circle, color: AppColors.primary, size: 20),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                category.title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: isSelected ? AppColors.primary : Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(category.description, style: const TextStyle(fontSize: 12, color: Colors.black54)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompanyProfileSection(bool isMobile) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.business, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  "Company Registration & Profile",
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontSize: isMobile ? 16 : null,
                      ),
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          if (isMobile) ...[
            AppTextField(
              label: "Company Name *",
              hint: "e.g. Royal Cafe & Bistro",
              controller: _companyNameController,
              validator: (v) => v == null || v.trim().isEmpty ? "Company Name is required" : null,
            ),
            const SizedBox(height: 12),
            AppTextField(
              label: "Legal / Registered Name",
              hint: "e.g. Royal Food Ventures Pvt Ltd",
              controller: _legalNameController,
            ),
            const SizedBox(height: 12),
            AppTextField(
              label: "GSTIN",
              hint: "e.g. 33AAAAA0000A1Z5",
              controller: _gstinController,
            ),
            const SizedBox(height: 12),
            AppTextField(
              label: "PAN",
              hint: "e.g. AAAAA0000A",
              controller: _panController,
            ),
            const SizedBox(height: 12),
            AppTextField(
              label: "Company Email *",
              hint: "contact@example.com",
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              validator: (v) => v == null || !v.contains("@") ? "Valid email is required" : null,
            ),
            const SizedBox(height: 12),
            AppTextField(
              label: "Mobile Number *",
              hint: "10-digit mobile number",
              controller: _mobileController,
              keyboardType: TextInputType.phone,
              validator: (v) => v == null || v.trim().length < 10 ? "10-digit mobile number required" : null,
            ),
            const SizedBox(height: 12),
            AppTextField(
              label: "Website",
              hint: "https://example.com",
              controller: _websiteController,
            ),
          ] else ...[
            Row(
              children: [
                Expanded(
                  child: AppTextField(
                    label: "Company Name *",
                    hint: "e.g. Royal Cafe & Bistro",
                    controller: _companyNameController,
                    validator: (v) => v == null || v.trim().isEmpty ? "Company Name is required" : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: AppTextField(
                    label: "Legal / Registered Name",
                    hint: "e.g. Royal Food Ventures Pvt Ltd",
                    controller: _legalNameController,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: AppTextField(
                    label: "GSTIN",
                    hint: "e.g. 33AAAAA0000A1Z5",
                    controller: _gstinController,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: AppTextField(
                    label: "PAN",
                    hint: "e.g. AAAAA0000A",
                    controller: _panController,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: AppTextField(
                    label: "Company Email *",
                    hint: "contact@example.com",
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) => v == null || !v.contains("@") ? "Valid email is required" : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: AppTextField(
                    label: "Mobile Number *",
                    hint: "10-digit mobile number",
                    controller: _mobileController,
                    keyboardType: TextInputType.phone,
                    validator: (v) => v == null || v.trim().length < 10 ? "10-digit mobile number required" : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: AppTextField(
                    label: "Website",
                    hint: "https://example.com",
                    controller: _websiteController,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          AppImageUploadPicker(
            label: "Company Logo",
            hintText: "Upload business logo via Pozo API or edit URL",
            initialImageUrl: _logoUrl,
            onImageUploaded: (url) => setState(() => _logoUrl = url),
            onImageRemoved: () => setState(() => _logoUrl = null),
          ),
        ],
      ),
    );
  }

  Widget _buildShopDetailsSection(bool isMobile) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.storefront, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  "Shop & Address Details (Single Outlet)",
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontSize: isMobile ? 16 : null,
                      ),
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          if (isMobile) ...[
            AppTextField(
              label: "Shop / Counter Name *",
              hint: "e.g. Main Billing Counter",
              controller: _shopNameController,
              validator: (v) => v == null || v.trim().isEmpty ? "Shop Name is required" : null,
            ),
            const SizedBox(height: 12),
            AppTextField(
              label: "Contact Number *",
              hint: "10-digit counter phone",
              controller: _contactNumberController,
              validator: (v) => v == null || v.trim().length < 10 ? "Contact number required" : null,
            ),
            const SizedBox(height: 12),
            AppTextField(
              label: "Shop Email *",
              hint: "outlet@example.com",
              controller: _shopEmailController,
              validator: (v) => v == null || !v.contains("@") ? "Valid email required" : null,
            ),
            const SizedBox(height: 12),
            AppTextField(
              label: "Address Line 1 *",
              hint: "Street address, building name",
              controller: _address1Controller,
              validator: (v) => v == null || v.trim().isEmpty ? "Address is required" : null,
            ),
            const SizedBox(height: 12),
            AppTextField(
              label: "Address Line 2",
              hint: "Area, landmark",
              controller: _address2Controller,
            ),
            const SizedBox(height: 12),
            AppTextField(
              label: "City *",
              hint: "e.g. Chennai",
              controller: _cityController,
              validator: (v) => v == null || v.trim().isEmpty ? "City is required" : null,
            ),
            const SizedBox(height: 12),
            AppTextField(
              label: "State *",
              hint: "e.g. Tamil Nadu",
              controller: _stateController,
              validator: (v) => v == null || v.trim().isEmpty ? "State is required" : null,
            ),
            const SizedBox(height: 12),
            AppTextField(
              label: "Pincode *",
              hint: "6-digit pincode",
              controller: _pincodeController,
              validator: (v) => v == null || v.trim().length != 6 ? "6-digit pincode required" : null,
            ),
          ] else ...[
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: AppTextField(
                    label: "Shop / Counter Name *",
                    hint: "e.g. Main Billing Counter",
                    controller: _shopNameController,
                    validator: (v) => v == null || v.trim().isEmpty ? "Shop Name is required" : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: AppTextField(
                    label: "Contact Number *",
                    hint: "10-digit counter phone",
                    controller: _contactNumberController,
                    validator: (v) => v == null || v.trim().length < 10 ? "Contact number required" : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: AppTextField(
                    label: "Shop Email *",
                    hint: "outlet@example.com",
                    controller: _shopEmailController,
                    validator: (v) => v == null || !v.contains("@") ? "Valid email required" : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            AppTextField(
              label: "Address Line 1 *",
              hint: "Street address, building name",
              controller: _address1Controller,
              validator: (v) => v == null || v.trim().isEmpty ? "Address is required" : null,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: AppTextField(
                    label: "Address Line 2",
                    hint: "Area, landmark",
                    controller: _address2Controller,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: AppTextField(
                    label: "City *",
                    hint: "e.g. Chennai",
                    controller: _cityController,
                    validator: (v) => v == null || v.trim().isEmpty ? "City is required" : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: AppTextField(
                    label: "State *",
                    hint: "e.g. Tamil Nadu",
                    controller: _stateController,
                    validator: (v) => v == null || v.trim().isEmpty ? "State is required" : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: AppTextField(
                    label: "Pincode *",
                    hint: "6-digit pincode",
                    controller: _pincodeController,
                    validator: (v) => v == null || v.trim().length != 6 ? "6-digit pincode required" : null,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInvoiceDetailsSection(bool isMobile) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.receipt, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  "Invoice Details & Print Configuration",
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontSize: isMobile ? 16 : null,
                      ),
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          if (isMobile) ...[
            AppTextField(
              label: "Invoice Header Text",
              hint: "e.g. Welcome to Royal Cafe! Wi-Fi: RoyalCafe123",
              controller: _invoiceHeaderController,
            ),
            const SizedBox(height: 12),
            AppTextField(
              label: "Invoice Footer Text",
              hint: "e.g. Thank you for your visit! Follow us @royalcafe",
              controller: _invoiceFooterController,
            ),
          ] else ...[
            Row(
              children: [
                Expanded(
                  child: AppTextField(
                    label: "Invoice Header Text",
                    hint: "e.g. Welcome to Royal Cafe! Wi-Fi: RoyalCafe123",
                    controller: _invoiceHeaderController,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: AppTextField(
                    label: "Invoice Footer Text",
                    hint: "e.g. Thank you for your visit! Follow us @royalcafe",
                    controller: _invoiceFooterController,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

