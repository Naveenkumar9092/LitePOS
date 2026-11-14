namespace BillingPOS.Application.Constants;

public static class AppPermissions
{
    // Users
    public const string UsersView = "users.view";
    public const string UsersCreate = "users.create";
    public const string UsersEdit = "users.edit";
    public const string UsersStatus = "users.status";
    public const string UsersRoles = "users.roles";
    public const string UsersAudit = "users.audit";

    // Company & Shop
    public const string CompanyView = "company.view";
    public const string CompanyEdit = "company.edit";

    // Products & Categories
    public const string ProductsView = "products.view";
    public const string ProductsManage = "products.manage";
    public const string CategoriesView = "categories.view";
    public const string CategoriesManage = "categories.manage";

    // POS Billing
    public const string BillingCreate = "billing.create";
    public const string BillingHold = "billing.hold";
    public const string BillingDiscount = "billing.discount";
    public const string BillingCancel = "billing.cancel";
    public const string BillingReprint = "billing.reprint";

    // Orders
    public const string OrdersView = "orders.view";
    public const string OrdersManage = "orders.manage";

    // Customers
    public const string CustomersView = "customers.view";
    public const string CustomersManage = "customers.manage";

    // Reports
    public const string ReportsView = "reports.view";
    public const string ReportsExport = "reports.export";

    // Sync & Hardware
    public const string SyncManage = "sync.manage";
    public const string HardwareManage = "hardware.manage";
    public const string NotificationsManage = "notifications.manage";

    public static readonly (string Code, string Name, string Category, string Description)[] AllPermissions =
    [
        (UsersView, "View Users", "Users", "Allows viewing user accounts and profiles"),
        (UsersCreate, "Create User", "Users", "Allows registering new users"),
        (UsersEdit, "Edit User", "Users", "Allows editing user profiles and credentials"),
        (UsersStatus, "Activate/Deactivate User", "Users", "Allows activating or deactivating user accounts"),
        (UsersRoles, "Manage Roles & Permissions", "Users", "Allows editing role permission assignments"),
        (UsersAudit, "View Login Audit Logs", "Users", "Allows viewing login history and audit logs"),

        (CompanyView, "View Company & Shop", "Company", "Allows viewing company and shop profiles"),
        (CompanyEdit, "Edit Company & Shop", "Company", "Allows configuring company and shop details"),

        (ProductsView, "View Products", "Catalog", "Allows viewing menu items and products"),
        (ProductsManage, "Manage Products", "Catalog", "Allows creating, updating, and removing products"),
        (CategoriesView, "View Categories", "Catalog", "Allows viewing product categories"),
        (CategoriesManage, "Manage Categories", "Catalog", "Allows creating and updating categories"),

        (BillingCreate, "Create POS Bill", "Billing", "Allows creating orders and processing checkout bills"),
        (BillingHold, "Hold & Resume Bill", "Billing", "Allows holding active bills and resuming them"),
        (BillingDiscount, "Apply Discount", "Billing", "Allows applying item or bill level discounts"),
        (BillingCancel, "Cancel Bill", "Billing", "Allows voiding or cancelling orders/invoices"),
        (BillingReprint, "Reprint Invoice", "Billing", "Allows reprinting previous customer receipts"),

        (OrdersView, "View Orders", "Orders", "Allows viewing past and active orders"),
        (OrdersManage, "Manage Orders", "Orders", "Allows modifying order statuses"),

        (CustomersView, "View Customers", "Customers", "Allows looking up customer records"),
        (CustomersManage, "Manage Customers", "Customers", "Allows creating and updating customer profiles"),

        (ReportsView, "View Sales Reports", "Reports", "Allows viewing daily and monthly sales summaries"),
        (ReportsExport, "Export Reports", "Reports", "Allows downloading sales reports"),

        (SyncManage, "Manage Offline Sync", "Sync", "Allows triggering and managing sync tasks"),
        (HardwareManage, "Configure Hardware", "Hardware", "Allows printer and terminal configuration"),
        (NotificationsManage, "Configure Notifications", "Notifications", "Allows configuring WhatsApp/Email")
    ];

    public static readonly string[] CashierPermissions =
    [
        BillingCreate,
        BillingHold,
        BillingReprint,
        OrdersView,
        CustomersView,
        CustomersManage,
        ReportsView
    ];

    public static readonly string[] AdminPermissions =
    [
        UsersView,
        UsersCreate,
        UsersEdit,
        UsersStatus,
        UsersAudit,
        CompanyView,
        CompanyEdit,
        ProductsView,
        ProductsManage,
        CategoriesView,
        CategoriesManage,
        BillingCreate,
        BillingHold,
        BillingDiscount,
        BillingCancel,
        BillingReprint,
        OrdersView,
        OrdersManage,
        CustomersView,
        CustomersManage,
        ReportsView,
        ReportsExport,
        SyncManage,
        HardwareManage,
        NotificationsManage
    ];
}

