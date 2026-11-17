import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:go_router/go_router.dart";
import "../../../core/constants/api_endpoints.dart";
import "../../company/data/company_repository.dart";
import "../../../core/routing/route_names.dart";
import "../../../core/theme/app_colors.dart";
import "../../../shared/widgets/app_brand_logo.dart";
import "../../../shared/widgets/app_button.dart";
import "../../../shared/widgets/app_card.dart";
import "../../../shared/widgets/app_text_field.dart";
import "../../../shared/widgets/app_toast.dart";
import "auth_state.dart";

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAutoLogin();
    });
  }

  void _checkAutoLogin() {
    final authState = ref.read(authNotifierProvider);
    if (authState.isAuthenticated && authState.user != null && mounted) {
      final user = authState.user!;
      if (user.isCashier) {
        context.go(RouteNames.posBilling);
      } else if (user.isSAdmin) {
        context.go(RouteNames.sadminDashboard);
      } else {
        context.go(RouteNames.adminDashboard);
      }
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    if (username.isEmpty) {
      AppToast.showError(context, "Please enter username.");
      return;
    }

    final success = await ref.read(authNotifierProvider.notifier).login(
      username,
      password,
    );

    if (success && mounted) {
      final authState = ref.read(authNotifierProvider);
      final user = authState.user;

      if (authState.isOffline) {
        AppToast.showSuccess(context, "Offline POS Active: Ready to Bill (${user?.roleName})");
      }

      if (user?.isCashier == true) {
        context.go(RouteNames.posBilling);
      } else if (user?.isSAdmin == true) {
        context.go(RouteNames.sadminDashboard);
      } else {
        context.go(RouteNames.adminDashboard);
      }
    } else if (mounted) {
      final err = ref.read(authNotifierProvider).errorMessage;
      if (err != null && err.isNotEmpty) {
        AppToast.showError(context, err);
      }
    }
  }

  void _showServerSettingsDialog() {
    final dioClient = ref.read(dioClientProvider);
    final storage = ref.read(storageServiceProvider);
    final controller = TextEditingController(text: dioClient.baseUrl);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.dns_rounded, color: AppColors.primary),
            SizedBox(width: 10),
            Text("Backend Server URL"),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Set the backend API endpoint URL. If testing on local Wi-Fi, enter your laptop's IP address (e.g. http://192.168.1.100:5000/api/v1).",
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            AppTextField(
              label: "API Base URL",
              controller: controller,
              prefixIcon: const Icon(Icons.link),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          OutlinedButton(
            onPressed: () async {
              final resetUrl = ApiEndpoints.cloudBaseUrl;
              dioClient.setBaseUrl(resetUrl);
              await storage.write("custom_server_url", resetUrl);
              if (ctx.mounted) Navigator.pop(ctx);
              if (mounted) AppToast.showSuccess(context, "Reset to Cloud URL");
            },
            child: const Text("Reset to Cloud"),
          ),
          ElevatedButton(
            onPressed: () async {
              final newUrl = controller.text.trim();
              if (newUrl.isNotEmpty) {
                dioClient.setBaseUrl(newUrl);
                await storage.write("custom_server_url", newUrl);
                if (ctx.mounted) Navigator.pop(ctx);
                if (mounted) AppToast.showSuccess(context, "Server URL updated");
              }
            },
            child: const Text("Save & Apply"),
          ),
        ],
      ),
    );
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
                      const Expanded(
                        child: AppBrandLogo(
                          size: 48,
                          showText: true,
                          subtitle: "Cafe • Food Court • Retail POS",
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.settings_ethernet, color: AppColors.textSecondary),
                        tooltip: "Server & Network Settings",
                        onPressed: _showServerSettingsDialog,
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
                    hintText: "Enter your username",
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
