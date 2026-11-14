import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:go_router/go_router.dart";
import "../../../core/routing/route_names.dart";
import "../../../core/theme/app_colors.dart";
import "../../../shared/widgets/app_button.dart";
import "../../../shared/widgets/app_card.dart";
import "../../../shared/widgets/app_text_field.dart";
import "auth_state.dart";

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _usernameController = TextEditingController(text: "admin");
  final _passwordController = TextEditingController(text: "Admin@123!");
  bool _obscurePassword = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _quickFill(String username, String password) {
    setState(() {
      _usernameController.text = username;
      _passwordController.text = password;
    });
  }

  Future<void> _handleLogin() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please enter both username and password."),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final success = await ref.read(authNotifierProvider.notifier).login(username, password);

    if (success && mounted) {
      final user = ref.read(authNotifierProvider).user;
      if (user?.isCashier == true) {
        context.go(RouteNames.posBilling);
      } else if (user?.isSAdmin == true) {
        context.go(RouteNames.sadminDashboard);
      } else {
        context.go(RouteNames.adminDashboard);
      }
    }
  }

  void _showForgotPasswordDialog() {
    final resetController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Reset Password"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Enter your registered username or email to receive password reset instructions.",
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            AppTextField(
              label: "Username or Email",
              controller: resetController,
              prefixIcon: const Icon(Icons.email_outlined),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              final target = resetController.text.trim();
              if (target.isNotEmpty) {
                final messenger = ScaffoldMessenger.of(context);
                final nav = Navigator.of(ctx);
                final ok = await ref.read(authNotifierProvider.notifier).forgotPassword(target);
                nav.pop();
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(ok
                        ? "Password reset instructions dispatched."
                        : "Could not dispatch reset instructions."),
                    backgroundColor: ok ? AppColors.success : AppColors.error,
                  ),
                );
              }
            },
            child: const Text("Send Reset Instructions"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: AppCard(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.point_of_sale, color: Colors.white, size: 28),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "LitePOS Sign In",
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            Text(
                              "Cafe • Food Court • Ice Cream & Desserts",
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  if (authState.errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: AppColors.error, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              authState.errorMessage!,
                              style: const TextStyle(color: AppColors.error, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  AppTextField(
                    label: "Username or Mobile Number",
                    controller: _usernameController,
                    prefixIcon: const Icon(Icons.person_outline),
                    hintText: "e.g. sadmin, admin, cashier",
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    label: "Password",
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                        size: 20,
                      ),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _showForgotPasswordDialog,
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        foregroundColor: AppColors.primary,
                      ),
                      child: const Text("Forgot password?"),
                    ),
                  ),
                  const SizedBox(height: 16),
                  AppButton(
                    text: authState.isLoading ? "Signing in..." : "Sign In",
                    icon: authState.isLoading ? null : Icons.login,
                    isLoading: authState.isLoading,
                    onPressed: authState.isLoading ? null : _handleLogin,
                  ),
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 12),
                  const Text(
                    "Quick Login Profiles:",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ActionChip(
                        avatar: const Icon(Icons.shield_outlined, size: 16, color: Colors.purple),
                        label: const Text("SAdmin", style: TextStyle(fontSize: 12)),
                        onPressed: () => _quickFill("sadmin", "SAdmin@123!"),
                      ),
                      ActionChip(
                        avatar: const Icon(Icons.admin_panel_settings_outlined, size: 16, color: AppColors.primary),
                        label: const Text("Admin", style: TextStyle(fontSize: 12)),
                        onPressed: () => _quickFill("admin", "Admin@123!"),
                      ),
                      ActionChip(
                        avatar: const Icon(Icons.point_of_sale, size: 16, color: Colors.green),
                        label: const Text("Cashier", style: TextStyle(fontSize: 12)),
                        onPressed: () => _quickFill("cashier", "Cashier@123!"),
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
