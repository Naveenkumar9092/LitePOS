import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "../../../../core/theme/app_colors.dart";
import "../../../../shared/widgets/app_button.dart";
import "../../../../shared/widgets/app_text_field.dart";
import "../../../../shared/widgets/app_toast.dart";
import "../../../company/data/company_repository.dart";
import "../../../company/models/company_model.dart";
import "../../../dashboard/presentation/dashboard_state.dart";
import "../user_state.dart";

class CreateAdminDialog extends ConsumerStatefulWidget {
  const CreateAdminDialog({super.key});

  @override
  ConsumerState<CreateAdminDialog> createState() => _CreateAdminDialogState();
}

class _CreateAdminDialogState extends ConsumerState<CreateAdminDialog> {
  final _formKey = GlobalKey<FormState>();

  final _fullNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailController = TextEditingController();
  final _mobileController = TextEditingController();
  final _newCompanyNameController = TextEditingController();
  final _newCityController = TextEditingController();

  List<CompanyProfileModel> _companies = [];
  bool _isLoadingCompanies = false;
  int? _selectedCompanyId;
  bool _isCreatingNewCompany = true;

  bool _isSubmitting = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _loadCompanies();
  }

  Future<void> _loadCompanies() async {
    try {
      final list = await ref.read(companyRepositoryProvider).getAllCompanies();
      if (mounted) {
        setState(() {
          _companies = list;
          _isLoadingCompanies = false;
          if (list.isNotEmpty) {
            _selectedCompanyId = list.first.companyId;
            _isCreatingNewCompany = false;
          } else {
            _isCreatingNewCompany = true;
          }
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoadingCompanies = false;
          _isCreatingNewCompany = true;
        });
      }
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _emailController.dispose();
    _mobileController.dispose();
    _newCompanyNameController.dispose();
    _newCityController.dispose();
    super.dispose();
  }

  Future<void> _handleCreateAdmin() async {
    if (!_formKey.currentState!.validate()) return;

    if (_isCreatingNewCompany && _newCompanyNameController.text.trim().isEmpty) {
      AppToast.showError(context, "Company / Store Name is required.");
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      int assignedCompanyId;
      String assignedCompanyName;

      if (_isCreatingNewCompany) {
        final newCompany = await ref.read(companyRepositoryProvider).createCompanyRecord(
          companyName: _newCompanyNameController.text.trim(),
          city: _newCityController.text.trim().isEmpty ? null : _newCityController.text.trim(),
        );
        assignedCompanyId = newCompany.companyId;
        assignedCompanyName = newCompany.companyName;
      } else {
        assignedCompanyId = _selectedCompanyId ?? 1;
        final matched = _companies.firstWhere(
          (c) => c.companyId == assignedCompanyId,
          orElse: () => _companies.first,
        );
        assignedCompanyName = matched.companyName;
      }

      final success = await ref.read(userListNotifierProvider.notifier).createUser({
        "fullName": _fullNameController.text.trim(),
        "username": _usernameController.text.trim().toLowerCase(),
        "password": _passwordController.text.trim(),
        "email": _emailController.text.trim().isEmpty ? null : _emailController.text.trim().toLowerCase(),
        "mobileNumber": _mobileController.text.trim().isEmpty ? null : _mobileController.text.trim(),
        "roleId": 2, // Role 2: Admin (Shop Administrator)
        "companyId": assignedCompanyId,
        "companyName": _isCreatingNewCompany ? assignedCompanyName : null,
      });

      if (mounted) {
        if (success) {
          ref.invalidate(sadminDashboardProvider);
          Navigator.of(context).pop(true);
          AppToast.showSuccess(
            context,
            "Admin '${_usernameController.text.trim()}' created for company '$assignedCompanyName'!",
          );
          ref.read(userListNotifierProvider.notifier).loadUsers();
        } else {
          final error = ref.read(userListNotifierProvider).errorMessage ?? "Failed to create Admin account.";
          AppToast.showError(context, error);
        }
      }
    } catch (e) {
      if (mounted) {
        AppToast.showError(context, "Error creating Admin: $e");
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Dialog Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primaryContainer,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.admin_panel_settings_rounded,
                          color: AppColors.primary,
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Create Admin User",
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              "Assign multi-tenant company & store management authority",
                              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(false),
                      ),
                    ],
                  ),
                  const Divider(height: 24),

                  // Role Confirmation Banner
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.shield_outlined, size: 18, color: AppColors.primary),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            "Role: Admin (Store Administrator) — Manages store catalog, billing, and cashier staff",
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primary),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Company / Store Assignment Section
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.business_rounded, size: 18, color: AppColors.primary),
                            SizedBox(width: 8),
                            Text(
                              "Company / Store Assignment *",
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        if (_isLoadingCompanies)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                          )
                        else ...[
                          if (_companies.isNotEmpty) ...[
                            Row(
                              children: [
                                Expanded(
                                  child: ChoiceChip(
                                    label: const Text("Existing Company", style: TextStyle(fontSize: 12)),
                                    selected: !_isCreatingNewCompany,
                                    onSelected: (val) {
                                      if (val) setState(() => _isCreatingNewCompany = false);
                                    },
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: ChoiceChip(
                                    label: const Text("+ New Company", style: TextStyle(fontSize: 12)),
                                    selected: _isCreatingNewCompany,
                                    onSelected: (val) {
                                      if (val) setState(() => _isCreatingNewCompany = true);
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                          ],
                          if (!_isCreatingNewCompany && _companies.isNotEmpty) ...[
                            DropdownButtonFormField<int>(
                              value: _selectedCompanyId,
                              decoration: InputDecoration(
                                labelText: "Choose Company *",
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                prefixIcon: const Icon(Icons.store_outlined),
                              ),
                              items: _companies.map((c) {
                                return DropdownMenuItem<int>(
                                  value: c.companyId,
                                  child: Text("${c.companyName} (Company #${c.companyId})"),
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) setState(() => _selectedCompanyId = val);
                              },
                            ),
                          ] else ...[
                            AppTextField(
                              label: "New Company / Store Name *",
                              hint: "e.g. Sri Murugan Stores, Annapoorna Bakery",
                              controller: _newCompanyNameController,
                              prefixIcon: const Icon(Icons.add_business_outlined),
                              validator: (v) {
                                if (_isCreatingNewCompany && (v == null || v.trim().isEmpty)) {
                                  return "Company name is required.";
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 10),
                            AppTextField(
                              label: "City / Branch Location (Optional)",
                              hint: "e.g. Chennai, Coimbatore, Bangalore",
                              controller: _newCityController,
                              prefixIcon: const Icon(Icons.location_on_outlined),
                            ),
                          ],
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Full Name
                  AppTextField(
                    label: "Admin Full Name *",
                    hint: "e.g. Ramesh Kumar",
                    controller: _fullNameController,
                    prefixIcon: const Icon(Icons.badge_outlined),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return "Full name is required.";
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),

                  // Username
                  AppTextField(
                    label: "Username *",
                    hint: "e.g. admin_store01",
                    controller: _usernameController,
                    prefixIcon: const Icon(Icons.person_outline),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return "Username is required.";
                      }
                      if (v.trim().length < 3) {
                        return "Username must be at least 3 characters.";
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),

                  // Password
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: "Temporary Password *",
                      hintText: "Minimum 6 characters",
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                      border: const OutlineInputBorder(),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return "Password is required.";
                      }
                      if (v.trim().length < 6) {
                        return "Password must be at least 6 characters.";
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),

                  // Email
                  AppTextField(
                    label: "Email Address (Optional)",
                    hint: "admin@store.com",
                    controller: _emailController,
                    prefixIcon: const Icon(Icons.email_outlined),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 14),

                  // Mobile
                  AppTextField(
                    label: "Mobile Number (10 digits) *",
                    hint: "e.g. 9840123456",
                    controller: _mobileController,
                    prefixIcon: const Icon(Icons.phone_android_outlined),
                    keyboardType: TextInputType.phone,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return "Mobile number is required.";
                      }
                      if (v.trim().length < 10) {
                        return "Enter a valid 10-digit mobile number.";
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  // Actions
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton(
                        onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(false),
                        child: const Text("Cancel"),
                      ),
                      const SizedBox(width: 12),
                      AppButton(
                        text: "Create Admin",
                        icon: Icons.check_circle_outline,
                        isLoading: _isSubmitting,
                        onPressed: _handleCreateAdmin,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
