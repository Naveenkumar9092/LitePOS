import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "../../../../core/theme/app_colors.dart";
import "../../../../shared/widgets/app_button.dart";
import "../../../../shared/widgets/app_text_field.dart";
import "../../../../shared/widgets/app_toast.dart";
import "../user_state.dart";

class CreateCashierDialog extends ConsumerStatefulWidget {
  const CreateCashierDialog({super.key});

  @override
  ConsumerState<CreateCashierDialog> createState() => _CreateCashierDialogState();
}

class _CreateCashierDialogState extends ConsumerState<CreateCashierDialog> {
  final _formKey = GlobalKey<FormState>();

  final _fullNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailController = TextEditingController();
  final _mobileController = TextEditingController();

  bool _isSubmitting = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _fullNameController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _emailController.dispose();
    _mobileController.dispose();
    super.dispose();
  }

  Future<void> _handleCreateCashier() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final success = await ref.read(userListNotifierProvider.notifier).createUser({
        "fullName": _fullNameController.text.trim(),
        "username": _usernameController.text.trim().toLowerCase(),
        "password": _passwordController.text.trim(),
        "email": _emailController.text.trim().isEmpty ? null : _emailController.text.trim().toLowerCase(),
        "mobileNumber": _mobileController.text.trim().isEmpty ? null : _mobileController.text.trim(),
        "roleId": 3, // Role 3: Cashier (Billing Operator)
      });

      if (mounted) {
        if (success) {
          Navigator.of(context).pop(true);
          AppToast.showSuccess(
            context,
            "Cashier '${_usernameController.text.trim()}' created successfully!",
          );
        } else {
          final error = ref.read(userListNotifierProvider).errorMessage ?? "Failed to create Cashier account.";
          AppToast.showError(context, error);
        }
      }
    } catch (e) {
      if (mounted) {
        AppToast.showError(context, "Error creating Cashier: $e");
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
        constraints: const BoxConstraints(maxWidth: 500),
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
                          color: AppColors.successContainer,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.point_of_sale_rounded,
                          color: AppColors.success,
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Register New Cashier",
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              "Assign counter billing operator credentials",
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
                      color: AppColors.successContainer.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.badge_outlined, size: 18, color: AppColors.success),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            "Role: Cashier (Billing Operator) — Access to POS billing counter, receipts & cash register",
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.success),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Full Name
                  AppTextField(
                    label: "Cashier Full Name *",
                    hint: "e.g. Priya Sharma",
                    controller: _fullNameController,
                    prefixIcon: const Icon(Icons.person_outline),
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
                    hint: "e.g. cashier_morning",
                    controller: _usernameController,
                    prefixIcon: const Icon(Icons.account_circle_outlined),
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
                  const SizedBox(height: 14),

                  // Email
                  AppTextField(
                    label: "Email Address (Optional)",
                    hint: "cashier@poojasweets.com",
                    controller: _emailController,
                    prefixIcon: const Icon(Icons.email_outlined),
                    keyboardType: TextInputType.emailAddress,
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
                        text: "Create Cashier",
                        icon: Icons.check_circle_outline,
                        isLoading: _isSubmitting,
                        onPressed: _handleCreateCashier,
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
