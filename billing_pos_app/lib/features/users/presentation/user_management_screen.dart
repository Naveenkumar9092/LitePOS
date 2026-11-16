import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:go_router/go_router.dart";
import "../../../core/routing/route_names.dart";
import "../../../core/theme/app_colors.dart";
import "../../../core/utilities/date_formatter.dart";
import "../../../shared/widgets/app_card.dart";
import "../../../shared/widgets/app_text_field.dart";
import "../../../shared/widgets/status_badge.dart";
import "../../authentication/models/user_model.dart";
import "../../authentication/presentation/auth_state.dart";
import "user_state.dart";
import "widgets/create_admin_dialog.dart";

class UserManagementScreen extends ConsumerStatefulWidget {
  const UserManagementScreen({super.key});

  @override
  ConsumerState<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends ConsumerState<UserManagementScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _openCreateOrEditUserDialog([UserModel? existingUser]) {
    final currentUser = ref.read(authNotifierProvider).user;
    final isSAdmin = currentUser?.isSAdmin ?? false;
    final isAdmin = currentUser?.isAdmin ?? false;

    final isEditing = existingUser != null;
    final fullNameCtrl = TextEditingController(text: existingUser?.fullName ?? "");
    final usernameCtrl = TextEditingController(text: existingUser?.username ?? "");
    final emailCtrl = TextEditingController(text: existingUser?.email ?? "");
    final mobileCtrl = TextEditingController(text: existingUser?.mobileNumber ?? "");
    final passwordCtrl = TextEditingController();
    int selectedRoleId = existingUser?.roleId ?? (isSAdmin ? 2 : 3);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(isEditing ? "Edit User Account" : (isSAdmin ? "Register Admin Profile" : "Register New Cashier")),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppTextField(
                    label: "Full Name",
                    controller: fullNameCtrl,
                    prefixIcon: const Icon(Icons.badge_outlined),
                    hintText: "e.g. Ramesh Kumar",
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    label: "Username",
                    controller: usernameCtrl,
                    prefixIcon: const Icon(Icons.person_outline),
                    enabled: !isEditing, // Username immutable on edit
                    hintText: "e.g. cashier_morning",
                  ),
                  const SizedBox(height: 12),
                  if (!isEditing) ...[
                    AppTextField(
                      label: "Password",
                      controller: passwordCtrl,
                      obscureText: true,
                      prefixIcon: const Icon(Icons.lock_outline),
                      hintText: "Minimum 6 characters",
                    ),
                    const SizedBox(height: 12),
                  ],
                  AppTextField(
                    label: "Email Address (Optional)",
                    controller: emailCtrl,
                    prefixIcon: const Icon(Icons.email_outlined),
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    label: "Mobile Number (10 digits)",
                    controller: mobileCtrl,
                    prefixIcon: const Icon(Icons.phone_android_outlined),
                  ),
                  const SizedBox(height: 16),
                  const Text("Role Assignment:", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<int>(
                    value: selectedRoleId,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                    items: [
                      if (isSAdmin) ...[
                        const DropdownMenuItem(value: 2, child: Text("Admin (Shop Administrator)")),
                      ] else if (isAdmin) ...[
                        const DropdownMenuItem(value: 3, child: Text("Cashier (Billing Operator)")),
                      ] else ...[
                        const DropdownMenuItem(value: 1, child: Text("SAdmin (Super Administrator)")),
                        const DropdownMenuItem(value: 2, child: Text("Admin (Shop Administrator)")),
                        const DropdownMenuItem(value: 3, child: Text("Cashier (Billing Operator)")),
                      ],
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setDialogState(() => selectedRoleId = val);
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                if (fullNameCtrl.text.trim().isEmpty || (!isEditing && usernameCtrl.text.trim().isEmpty)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Full Name and Username are required.")),
                  );
                  return;
                }

                if (!isEditing && passwordCtrl.text.trim().length < 6) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Password must be at least 6 characters.")),
                  );
                  return;
                }

                bool success = false;
                final messenger = ScaffoldMessenger.of(context);
                final nav = Navigator.of(ctx);

                if (isEditing) {
                  success = await ref.read(userListNotifierProvider.notifier).updateUser(existingUser.id, {
                    "fullName": fullNameCtrl.text.trim(),
                    "email": emailCtrl.text.trim().isEmpty ? null : emailCtrl.text.trim(),
                    "mobileNumber": mobileCtrl.text.trim().isEmpty ? null : mobileCtrl.text.trim(),
                    "roleId": selectedRoleId,
                  });
                } else {
                  success = await ref.read(userListNotifierProvider.notifier).createUser({
                    "fullName": fullNameCtrl.text.trim(),
                    "username": usernameCtrl.text.trim(),
                    "password": passwordCtrl.text.trim(),
                    "email": emailCtrl.text.trim().isEmpty ? null : emailCtrl.text.trim(),
                    "mobileNumber": mobileCtrl.text.trim().isEmpty ? null : mobileCtrl.text.trim(),
                    "roleId": selectedRoleId,
                  });
                }

                if (success) {
                  nav.pop();
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(isEditing ? "User updated successfully!" : "User registered successfully!"),
                      backgroundColor: AppColors.success,
                    ),
                  );
                }
              },
              child: Text(isEditing ? "Save Changes" : "Create User"),
            ),
          ],
        ),
      ),
    );
  }

  void _showChangePasswordDialog(UserModel user) {
    final currentPassCtrl = TextEditingController();
    final newPassCtrl = TextEditingController();
    final confirmPassCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Change Password: ${user.username}"),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppTextField(
                label: "Current Password",
                controller: currentPassCtrl,
                obscureText: true,
                prefixIcon: const Icon(Icons.lock_outline),
              ),
              const SizedBox(height: 12),
              AppTextField(
                label: "New Password",
                controller: newPassCtrl,
                obscureText: true,
                prefixIcon: const Icon(Icons.key_outlined),
              ),
              const SizedBox(height: 12),
              AppTextField(
                label: "Confirm New Password",
                controller: confirmPassCtrl,
                obscureText: true,
                prefixIcon: const Icon(Icons.check_circle_outline),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              if (newPassCtrl.text != confirmPassCtrl.text) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("New passwords do not match.")),
                );
                return;
              }
              final messenger = ScaffoldMessenger.of(context);
              final nav = Navigator.of(ctx);
              final ok = await ref.read(authNotifierProvider.notifier).changePassword(
                    currentPassCtrl.text,
                    newPassCtrl.text,
                    confirmPassCtrl.text,
                  );
              if (ok) {
                nav.pop();
                messenger.showSnackBar(
                  const SnackBar(content: Text("Password updated successfully!"), backgroundColor: AppColors.success),
                );
              }
            },
            child: const Text("Update Password"),
          ),
        ],
      ),
    );
  }

  void _confirmStatusToggle(UserModel user) {
    final targetStatus = !user.isActive;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("${targetStatus ? 'Activate' : 'Deactivate'} User"),
        content: Text(
          "Are you sure you want to ${targetStatus ? 'activate' : 'deactivate'} user '${user.username}'?",
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: targetStatus ? AppColors.success : AppColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              final ok = await ref.read(userListNotifierProvider.notifier).toggleUserStatus(user.id, targetStatus);
              if (mounted && ok) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("User '${user.username}' status updated to ${targetStatus ? 'Active' : 'Inactive'}."),
                    backgroundColor: targetStatus ? AppColors.success : AppColors.warning,
                  ),
                );
              }
            },
            child: Text(targetStatus ? "Activate" : "Deactivate"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(authNotifierProvider).user;

    // Strict access control: User & Role Management is restricted exclusively to SAdmin
    if (currentUser != null && !currentUser.isSAdmin) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text("User & Role Management"),
          backgroundColor: Colors.white,
          foregroundColor: AppColors.textPrimary,
          elevation: 0,
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 0,
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: const BoxDecoration(
                        color: AppColors.errorContainer,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.lock_person_rounded, size: 48, color: AppColors.error),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      "Super Admin Access Required",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      "User & Role Management is restricted exclusively to Super Administrators (SAdmin). Store Admins can configure shop operations, manage catalog items, and register cashiers from the Admin Dashboard.",
                      style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.arrow_back_rounded, size: 16),
                      label: const Text("Return to Dashboard"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () => context.go(RouteNames.adminDashboard),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    final userListState = ref.watch(userListNotifierProvider);
    final isMobile = MediaQuery.sizeOf(context).width < 700;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(isMobile ? "Users & Roles" : "User & Role Management"),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: isMobile
                ? IconButton.filled(
                    style: IconButton.styleFrom(backgroundColor: AppColors.primary),
                    icon: const Icon(Icons.admin_panel_settings_rounded, size: 18, color: Colors.white),
                    tooltip: "Create Admin Profile",
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (ctx) => const CreateAdminDialog(),
                      );
                    },
                  )
                : ElevatedButton.icon(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (ctx) => const CreateAdminDialog(),
                      );
                    },
                    icon: const Icon(Icons.admin_panel_settings_rounded, size: 16),
                    label: const Text(
                      "Create Admin Profile",
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: isMobile,
          tabAlignment: isMobile ? TabAlignment.start : TabAlignment.fill,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(icon: Icon(Icons.people_alt_outlined), text: "Users"),
            Tab(icon: Icon(Icons.admin_panel_settings_outlined), text: "Roles & Permissions"),
            Tab(icon: Icon(Icons.history_outlined), text: "Login History"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // TAB 1: USERS LIST
          _buildUsersTab(userListState, currentUser, isMobile),

          // TAB 2: ROLES & PERMISSIONS
          _buildRolesTab(),

          // TAB 3: LOGIN HISTORY / AUDIT LOGS
          _buildAuditLogsTab(),
        ],
      ),
    );
  }

  Widget _buildUsersTab(UserListState state, UserModel? currentUser, bool isMobile) {
    return Column(
      children: [
        // Filter bar
        Container(
          color: Colors.white,
          padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 16, vertical: isMobile ? 8 : 12),
          child: isMobile
              ? Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              hintText: "Search name, username...",
                              prefixIcon: const Icon(Icons.search, size: 18),
                              suffixIcon: _searchController.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear, size: 16),
                                      onPressed: () {
                                        _searchController.clear();
                                        ref.read(userListNotifierProvider.notifier).setSearchQuery("");
                                      },
                                    )
                                  : null,
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            onSubmitted: (val) {
                              ref.read(userListNotifierProvider.notifier).setSearchQuery(val);
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton.filledTonal(
                          icon: const Icon(Icons.refresh, size: 18),
                          visualDensity: VisualDensity.compact,
                          tooltip: "Reload",
                          onPressed: () => ref.read(userListNotifierProvider.notifier).loadUsers(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<int?>(
                            value: state.selectedRoleId,
                            decoration: const InputDecoration(
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              border: OutlineInputBorder(),
                            ),
                            items: const [
                              DropdownMenuItem(value: null, child: Text("All Roles", style: TextStyle(fontSize: 12))),
                              DropdownMenuItem(value: 1, child: Text("SAdmin", style: TextStyle(fontSize: 12))),
                              DropdownMenuItem(value: 2, child: Text("Admin", style: TextStyle(fontSize: 12))),
                              DropdownMenuItem(value: 3, child: Text("Cashier", style: TextStyle(fontSize: 12))),
                            ],
                            onChanged: (val) {
                              ref.read(userListNotifierProvider.notifier).setRoleFilter(val);
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: DropdownButtonFormField<bool?>(
                            value: state.selectedStatus,
                            decoration: const InputDecoration(
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              border: OutlineInputBorder(),
                            ),
                            items: const [
                              DropdownMenuItem(value: null, child: Text("All Status", style: TextStyle(fontSize: 12))),
                              DropdownMenuItem(value: true, child: Text("Active", style: TextStyle(fontSize: 12))),
                              DropdownMenuItem(value: false, child: Text("Inactive", style: TextStyle(fontSize: 12))),
                            ],
                            onChanged: (val) {
                              ref.read(userListNotifierProvider.notifier).setStatusFilter(val);
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                )
              : Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: "Search user by name, username, mobile...",
                          prefixIcon: const Icon(Icons.search, size: 20),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 18),
                                  onPressed: () {
                                    _searchController.clear();
                                    ref.read(userListNotifierProvider.notifier).setSearchQuery("");
                                  },
                                )
                              : null,
                          isDense: true,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onSubmitted: (val) {
                          ref.read(userListNotifierProvider.notifier).setSearchQuery(val);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Role Filter Dropdown
                    DropdownButton<int?>(
                      value: state.selectedRoleId,
                      hint: const Text("All Roles"),
                      underline: const SizedBox(),
                      items: const [
                        DropdownMenuItem(value: null, child: Text("All Roles")),
                        DropdownMenuItem(value: 1, child: Text("SAdmin")),
                        DropdownMenuItem(value: 2, child: Text("Admin")),
                        DropdownMenuItem(value: 3, child: Text("Cashier")),
                      ],
                      onChanged: (val) {
                        ref.read(userListNotifierProvider.notifier).setRoleFilter(val);
                      },
                    ),
                    const SizedBox(width: 8),
                    // Status Filter
                    DropdownButton<bool?>(
                      value: state.selectedStatus,
                      hint: const Text("All Status"),
                      underline: const SizedBox(),
                      items: const [
                        DropdownMenuItem(value: null, child: Text("All Status")),
                        DropdownMenuItem(value: true, child: Text("Active")),
                        DropdownMenuItem(value: false, child: Text("Inactive")),
                      ],
                      onChanged: (val) {
                        ref.read(userListNotifierProvider.notifier).setStatusFilter(val);
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      tooltip: "Reload",
                      onPressed: () => ref.read(userListNotifierProvider.notifier).loadUsers(),
                    ),
                  ],
                ),
        ),
        const Divider(height: 1),

        // User list
        Expanded(
          child: state.isLoading && state.users.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : state.users.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.person_off_outlined, size: 48, color: Colors.grey[400]),
                          const SizedBox(height: 12),
                          const Text("No users found.", style: TextStyle(color: AppColors.textSecondary)),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: EdgeInsets.all(isMobile ? 10 : 16),
                      itemCount: state.users.length,
                      separatorBuilder: (_, __) => SizedBox(height: isMobile ? 8 : 12),
                      itemBuilder: (context, index) {
                        final user = state.users[index];
                        final isSelf = currentUser?.id == user.id;

                        if (isMobile) {
                          return AppCard(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 20,
                                      backgroundColor: user.isSAdmin
                                          ? Colors.purple.withValues(alpha: 0.15)
                                          : user.isAdmin
                                              ? AppColors.primary.withValues(alpha: 0.15)
                                              : Colors.green.withValues(alpha: 0.15),
                                      child: Icon(
                                        user.isSAdmin
                                            ? Icons.shield
                                            : user.isAdmin
                                                ? Icons.admin_panel_settings
                                                : Icons.point_of_sale,
                                        color: user.isSAdmin
                                            ? Colors.purple
                                            : user.isAdmin
                                                ? AppColors.primary
                                                : Colors.green,
                                        size: 20,
                                      ),
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
                                                  user.fullName,
                                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                              if (isSelf) ...[
                                                const SizedBox(width: 6),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                                  decoration: BoxDecoration(
                                                    color: Colors.blue.withValues(alpha: 0.15),
                                                    borderRadius: BorderRadius.circular(4),
                                                  ),
                                                  child: const Text("You", style: TextStyle(fontSize: 10, color: Colors.blue, fontWeight: FontWeight.bold)),
                                                ),
                                              ],
                                            ],
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            "@${user.username} • ${user.mobileNumber ?? 'N/A'}",
                                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                    StatusBadge(status: user.isActive ? "Active" : "Inactive"),
                                  ],
                                ),
                                const Divider(height: 16),
                                Row(
                                  children: [
                                    _buildRoleChip(user.roleName),
                                    const Spacer(),
                                    IconButton(
                                      icon: const Icon(Icons.edit_outlined, size: 18),
                                      visualDensity: VisualDensity.compact,
                                      tooltip: "Edit Profile",
                                      onPressed: () => _openCreateOrEditUserDialog(user),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.key_outlined, size: 18),
                                      visualDensity: VisualDensity.compact,
                                      tooltip: "Change Password",
                                      onPressed: () => _showChangePasswordDialog(user),
                                    ),
                                    Transform.scale(
                                      scale: 0.8,
                                      child: Switch(
                                        value: user.isActive,
                                        activeColor: AppColors.success,
                                        onChanged: (val) => _confirmStatusToggle(user),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        }

                        return AppCard(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundColor: user.isSAdmin
                                    ? Colors.purple.withValues(alpha: 0.15)
                                    : user.isAdmin
                                        ? AppColors.primary.withValues(alpha: 0.15)
                                        : Colors.green.withValues(alpha: 0.15),
                                child: Icon(
                                  user.isSAdmin
                                      ? Icons.shield
                                      : user.isAdmin
                                          ? Icons.admin_panel_settings
                                          : Icons.point_of_sale,
                                  color: user.isSAdmin
                                      ? Colors.purple
                                      : user.isAdmin
                                          ? AppColors.primary
                                          : Colors.green,
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
                                          user.fullName,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                        ),
                                        if (isSelf) ...[
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: Colors.blue.withValues(alpha: 0.15),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: const Text("You", style: TextStyle(fontSize: 11, color: Colors.blue, fontWeight: FontWeight.bold)),
                                          ),
                                        ],
                                        const SizedBox(width: 8),
                                        _buildRoleChip(user.roleName),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "@${user.username} • Mobile: ${user.mobileNumber ?? 'N/A'} • Email: ${user.email ?? 'N/A'}",
                                      style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                                    ),
                                  ],
                                ),
                              ),
                              StatusBadge(status: user.isActive ? "Active" : "Inactive"),
                              const SizedBox(width: 12),
                              // Edit button
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, size: 20),
                                tooltip: "Edit Profile",
                                onPressed: () => _openCreateOrEditUserDialog(user),
                              ),
                              // Password button
                              IconButton(
                                icon: const Icon(Icons.key_outlined, size: 20),
                                tooltip: "Change Password",
                                onPressed: () => _showChangePasswordDialog(user),
                              ),
                              // Active switch
                              Switch(
                                value: user.isActive,
                                activeColor: AppColors.success,
                                onChanged: (val) => _confirmStatusToggle(user),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildRoleChip(String roleName) {
    Color color;
    switch (roleName.toLowerCase()) {
      case "sadmin":
        color = Colors.purple;
        break;
      case "admin":
        color = AppColors.primary;
        break;
      default:
        color = Colors.green;
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        roleName,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }

  Widget _buildRolesTab() {
    final rolesAsync = ref.watch(rolesProvider);
    final permsAsync = ref.watch(permissionsProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "System Roles & Assigned Responsibilities",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            "Role privileges are strictly enforced. Cashier billing operators are automatically blocked from administration screens.",
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
          ),
          const SizedBox(height: 16),
          rolesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Text("Error loading roles: $err"),
            data: (roles) => Column(
              children: roles.map((r) {
                return AppCard(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _buildRoleChip(r.name),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              r.description ?? "",
                              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                            ),
                          ),
                          Text("${r.permissions.length} permissions", style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: r.permissions.map((p) {
                          return Chip(
                            label: Text(p, style: const TextStyle(fontSize: 11)),
                            backgroundColor: Colors.grey[100],
                            visualDensity: VisualDensity.compact,
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 24),
          const Text("Master System Permissions Matrix", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          permsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Text("Error: $err"),
            data: (perms) {
              final grouped = <String, List<dynamic>>{};
              for (final p in perms) {
                grouped.putIfAbsent(p.category, () => []).add(p);
              }
              return Column(
                children: grouped.entries.map((entry) {
                  return AppCard(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.key.toUpperCase(),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primary),
                        ),
                        const SizedBox(height: 8),
                        ...entry.value.map((p) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                children: [
                                  const Icon(Icons.check_circle, color: AppColors.success, size: 16),
                                  const SizedBox(width: 8),
                                  Text(p.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                                  const SizedBox(width: 8),
                                  Text("(${p.code})", style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                  const Spacer(),
                                  if (p.description != null)
                                    Text(p.description!, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                ],
                              ),
                            )),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAuditLogsTab() {
    final logsAsync = ref.watch(auditLogsProvider);

    return logsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text("Error loading audit logs: $err")),
      data: (logs) {
        if (logs.isEmpty) {
          return const Center(child: Text("No login history available."));
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: logs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final log = logs[index];
            return AppCard(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(
                    log.isSuccess ? Icons.check_circle : Icons.cancel,
                    color: log.isSuccess ? AppColors.success : AppColors.error,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              "Login Attempt: ${log.usernameAttempted}",
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            const SizedBox(width: 8),
                            StatusBadge(status: log.isSuccess ? "Success" : "Failed"),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "IP: ${log.ipAddress ?? '127.0.0.1'} • ${log.failureReason != null ? 'Reason: ${log.failureReason}' : 'Authenticated'}",
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    DateFormatter.formatDate(log.attemptedAtUtc),
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
