class ApiEndpoints {
  static const String cloudBaseUrl = "https://litepos.onrender.com/api/v1";
  static const String localBaseUrl = "http://localhost:5000/api/v1";
  static const String baseUrl = cloudBaseUrl;

  // Health
  static const String health = "/health";
  static const String ping = "/health/ping";

  // Company & Shop Setup
  static const String companySetup = "/company/setup";
  static const String companyProfile = "/company/profile";
  static const String companyConfiguration = "/company/configuration";
  static const String companyLogo = "/company/logo";

  // Authentication & Users
  static const String login = "/auth/login";
  static const String refreshToken = "/auth/refresh";
  static const String logout = "/auth/logout";
  static const String changePassword = "/auth/change-password";
  static const String forgotPassword = "/auth/forgot-password";
  static const String users = "/users";
  static const String roles = "/roles";
  static const String permissions = "/permissions";

  // Dashboard
  static const String dashboardSAdmin = "/dashboard/sadmin";
  static const String dashboardAdmin = "/dashboard/admin";
  static const String dashboardCashier = "/dashboard/cashier";
  static const String salesSummary = "/dashboard/sales-summary";
  static const String paymentSummary = "/dashboard/payment-summary";
  static const String recentTransactions = "/dashboard/recent-transactions";

  // Products & Categories
  static const String products = "/products";
  static const String productSearch = "/products/search";
  static const String productCategoriesDropdown = "/products/categories-dropdown";
  static const String categories = "/categories";
  static const String categoriesSort = "/categories/sort-order";

  // POS Billing & Orders
  static const String billingCreate = "/billing/create";
  static const String invoices = "/billing/invoices";
  static const String holdBill = "/billing/hold";
  static const String heldBills = "/billing/held";
  static const String resumeBill = "/billing/resume";
  static const String cancelBill = "/billing/cancel";
  static const String reprintBill = "/billing/reprint";
  static const String orders = "/orders";

  // Payments
  static const String payments = "/payments";
  static const String splitPayment = "/payments/split";
  static const String refundPayment = "/payments/refund";
  static const String paymentReconciliation = "/payments/reconciliation";
  static const String cashRegisterOpen = "/cash-register/open";
  static const String cashRegisterClose = "/cash-register/close";

  // GST
  static const String gstTaxes = "/gst/taxes";
  static const String gstHsn = "/gst/hsn";
  static const String gstConfig = "/gst/config";
  static const String gstSummary = "/gst/summary";
  static const String creditNotes = "/gst/credit-notes";

  // Customers
  static const String customers = "/customers";
  static const String customerSearch = "/customers/search";

  // Reports
  static const String reportsSummary = "/reports/summary";
  static const String reportsDaily = "/reports/daily";
  static const String reportsProducts = "/reports/products";
  static const String reportsCategories = "/reports/categories";
  static const String reportsCashiers = "/reports/cashiers";
  static const String reportsGst = "/reports/gst";
  static const String reportsHourly = "/reports/hourly";
  static const String reportsPayments = "/reports/payments";
  static const String reportsExportCsv = "/reports/export/csv";
  static const String reportDailySales = "/reports/daily";
  static const String reportMonthlySales = "/reports/daily";
  static const String reportYearlySales = "/reports/daily";
  static const String reportProductSales = "/reports/products";
  static const String reportCategorySales = "/reports/categories";
  static const String reportCashierSales = "/reports/cashiers";

  // Sync
  static const String syncRegisterDevice = "/sync/register-device";
  static const String syncPush = "/sync/push";
  static const String syncPull = "/sync/pull";
  static const String syncStatus = "/sync/status";
  static const String syncHistory = "/sync/history";
  static const String syncRetry = "/sync/retry";

  // Hardware & Printers
  static const String hardwarePrinters = "/hardware/printers";
  static const String hardwareDefaultPrinter = "/hardware/printers/default";
  static const String hardwareTestPrint = "/hardware/test-print";
  static const String hardwareOpenDrawer = "/hardware/open-drawer";
  static const String hardwareReceipt = "/hardware/receipt";

  // Notifications & Settings
  static const String emailInvoice = "/notifications/email/invoice";
  static const String whatsappInvoice = "/notifications/whatsapp/invoice";
  static const String notificationLogs = "/notifications/logs";
  static const String settingsPreferences = "/settings/preferences";
  static const String settingsBackup = "/settings/backup";
  static const String settingsSystemInfo = "/settings/system-info";
}

