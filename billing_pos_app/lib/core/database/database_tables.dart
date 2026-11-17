class DatabaseTables {
  static const String localCompany = "LocalCompany";
  static const String localShop = "LocalShop";
  static const String localUser = "LocalUser";
  static const String localProduct = "LocalProduct";
  static const String localCategory = "LocalCategory";
  static const String localCustomer = "LocalCustomer";
  static const String localOrder = "LocalOrder";
  static const String localOrderDetail = "LocalOrderDetail";
  static const String localInvoice = "LocalInvoice";
  static const String localInvoiceDetail = "LocalInvoiceDetail";
  static const String localPayment = "LocalPayment";
  static const String localTax = "LocalTax";
  static const String localHsnSac = "LocalHsnSac";
  static const String localGstConfig = "LocalGstConfig";
  static const String localCreditNote = "LocalCreditNote";
  static const String localSyncOutbox = "LocalSyncOutbox";
  static const String localSyncLog = "LocalSyncLog";
  static const String localDeviceState = "LocalDeviceState";

  static const List<String> allTables = [
    localCompany,
    localShop,
    localUser,
    localProduct,
    localCategory,
    localCustomer,
    localOrder,
    localOrderDetail,
    localInvoice,
    localInvoiceDetail,
    localPayment,
    localTax,
    localHsnSac,
    localGstConfig,
    localCreditNote,
    localSyncOutbox,
    localSyncLog,
    localDeviceState,
  ];

  static const String createCompanyTable = """
    CREATE TABLE $localCompany (
      CompanyId INTEGER PRIMARY KEY,
      CompanyName TEXT NOT NULL,
      LegalName TEXT,
      BusinessType INTEGER NOT NULL,
      GSTIN TEXT,
      PAN TEXT,
      Email TEXT,
      MobileNumber TEXT,
      Website TEXT,
      LogoStorageKey TEXT,
      IsActive INTEGER NOT NULL DEFAULT 1,
      CreatedAtUTC TEXT NOT NULL,
      UpdatedAtUTC TEXT
    );
  """;

  static const String createShopTable = """
    CREATE TABLE $localShop (
      ShopId INTEGER PRIMARY KEY,
      CompanyId INTEGER NOT NULL,
      ShopName TEXT NOT NULL,
      AddressLine1 TEXT,
      AddressLine2 TEXT,
      City TEXT,
      State TEXT,
      Pincode TEXT,
      Country TEXT,
      ContactNumber TEXT,
      Email TEXT,
      TimeZone TEXT,
      CurrencyCode TEXT,
      IsActive INTEGER NOT NULL DEFAULT 1
    );
  """;

  static const String createUserTable = """
    CREATE TABLE $localUser (
      UserId INTEGER PRIMARY KEY,
      CompanyId INTEGER NOT NULL DEFAULT 1,
      FullName TEXT NOT NULL,
      Username TEXT NOT NULL UNIQUE,
      Email TEXT,
      MobileNumber TEXT,
      RoleId INTEGER NOT NULL,
      RoleName TEXT NOT NULL,
      IsActive INTEGER NOT NULL DEFAULT 1
    );
  """;

  static const String createCategoryTable = """
    CREATE TABLE $localCategory (
      CategoryId INTEGER PRIMARY KEY,
      CategoryGuid TEXT NOT NULL UNIQUE,
      CategoryName TEXT NOT NULL,
      Description TEXT,
      CategoryImageStorageKey TEXT,
      DisplayOrder INTEGER NOT NULL DEFAULT 0,
      IsActive INTEGER NOT NULL DEFAULT 1,
      CreatedAtUTC TEXT NOT NULL,
      UpdatedAtUTC TEXT
    );
  """;

  static const String createProductTable = """
    CREATE TABLE $localProduct (
      ProductId INTEGER PRIMARY KEY,
      ProductGuid TEXT NOT NULL UNIQUE,
      CompanyId INTEGER NOT NULL,
      CategoryId INTEGER NOT NULL,
      ProductName TEXT NOT NULL,
      Description TEXT,
      ProductImageStorageKey TEXT,
      SellingPrice REAL NOT NULL,
      TaxId INTEGER,
      TaxPercentage REAL NOT NULL DEFAULT 0,
      HSNCode TEXT,
      IsAvailable INTEGER NOT NULL DEFAULT 1,
      IsActive INTEGER NOT NULL DEFAULT 1,
      CreatedAtUTC TEXT NOT NULL,
      UpdatedAtUTC TEXT
    );
  """;

  static const String createCustomerTable = """
    CREATE TABLE $localCustomer (
      CustomerId INTEGER PRIMARY KEY AUTOINCREMENT,
      CustomerGuid TEXT NOT NULL UNIQUE,
      CustomerName TEXT NOT NULL,
      MobileNumber TEXT NOT NULL,
      WhatsAppNumber TEXT,
      Email TEXT,
      Address TEXT,
      GSTIN TEXT,
      EmailConsent INTEGER NOT NULL DEFAULT 0,
      WhatsAppConsent INTEGER NOT NULL DEFAULT 0,
      IsActive INTEGER NOT NULL DEFAULT 1,
      CreatedAtUTC TEXT NOT NULL
    );
  """;

  static const String createOrderTable = """
    CREATE TABLE $localOrder (
      OrderId INTEGER PRIMARY KEY AUTOINCREMENT,
      OrderGuid TEXT NOT NULL UNIQUE,
      OrderNumber TEXT NOT NULL,
      CustomerId INTEGER,
      OrderType INTEGER NOT NULL,
      OrderStatus INTEGER NOT NULL,
      SubTotal REAL NOT NULL,
      DiscountAmount REAL NOT NULL DEFAULT 0,
      TaxAmount REAL NOT NULL DEFAULT 0,
      GrandTotal REAL NOT NULL,
      CreatedBy TEXT NOT NULL,
      CreatedAtUTC TEXT NOT NULL,
      UpdatedAtUTC TEXT
    );
  """;

  static const String createOrderDetailTable = """
    CREATE TABLE $localOrderDetail (
      OrderDetailId INTEGER PRIMARY KEY AUTOINCREMENT,
      OrderId INTEGER NOT NULL,
      ProductId INTEGER NOT NULL,
      ProductNameSnapshot TEXT NOT NULL,
      UnitPrice REAL NOT NULL,
      Quantity REAL NOT NULL,
      DiscountAmount REAL NOT NULL DEFAULT 0,
      TaxPercentage REAL NOT NULL DEFAULT 0,
      TaxAmount REAL NOT NULL DEFAULT 0,
      LineTotal REAL NOT NULL
    );
  """;

  static const String createInvoiceTable = """
    CREATE TABLE $localInvoice (
      InvoiceId INTEGER PRIMARY KEY AUTOINCREMENT,
      InvoiceGuid TEXT NOT NULL UNIQUE,
      InvoiceNumber TEXT NOT NULL UNIQUE,
      CompanyId INTEGER NOT NULL,
      ShopId INTEGER NOT NULL,
      CustomerId INTEGER,
      CashierId INTEGER NOT NULL,
      DeviceId TEXT NOT NULL,
      InvoiceDateUTC TEXT NOT NULL,
      SubTotal REAL NOT NULL,
      DiscountAmount REAL NOT NULL DEFAULT 0,
      TaxableAmount REAL NOT NULL,
      TaxAmount REAL NOT NULL DEFAULT 0,
      GrandTotal REAL NOT NULL,
      PaidAmount REAL NOT NULL,
      BalanceAmount REAL NOT NULL DEFAULT 0,
      PaymentStatus INTEGER NOT NULL,
      InvoiceStatus INTEGER NOT NULL,
      SyncStatus INTEGER NOT NULL DEFAULT 1,
      CreatedAtUTC TEXT NOT NULL
    );
  """;

  static const String createInvoiceDetailTable = """
    CREATE TABLE $localInvoiceDetail (
      InvoiceDetailId INTEGER PRIMARY KEY AUTOINCREMENT,
      InvoiceId INTEGER NOT NULL,
      ProductId INTEGER NOT NULL,
      ProductNameSnapshot TEXT NOT NULL,
      UnitPrice REAL NOT NULL,
      Quantity REAL NOT NULL,
      DiscountAmount REAL NOT NULL DEFAULT 0,
      TaxPercentage REAL NOT NULL DEFAULT 0,
      TaxAmount REAL NOT NULL DEFAULT 0,
      LineTotal REAL NOT NULL
    );
  """;

  static const String createPaymentTable = """
    CREATE TABLE $localPayment (
      PaymentId INTEGER PRIMARY KEY AUTOINCREMENT,
      PaymentGuid TEXT NOT NULL UNIQUE,
      InvoiceId INTEGER NOT NULL,
      PaymentModeId INTEGER NOT NULL,
      PaymentModeName TEXT NOT NULL,
      Amount REAL NOT NULL,
      TransactionReference TEXT,
      PaymentStatus INTEGER NOT NULL,
      CreatedAtUTC TEXT NOT NULL
    );
  """;

  static const String createTaxTable = """
    CREATE TABLE $localTax (
      TaxId INTEGER PRIMARY KEY,
      TaxName TEXT NOT NULL,
      RatePercentage REAL NOT NULL,
      CgstPercentage REAL NOT NULL,
      SgstPercentage REAL NOT NULL,
      IgstPercentage REAL NOT NULL,
      IsActive INTEGER NOT NULL DEFAULT 1,
      IsDefault INTEGER NOT NULL DEFAULT 0,
      IsTaxInclusiveDefault INTEGER NOT NULL DEFAULT 1
    );
  """;

  static const String createHsnSacTable = """
    CREATE TABLE $localHsnSac (
      HsnId INTEGER PRIMARY KEY,
      Code TEXT NOT NULL,
      Description TEXT NOT NULL,
      Type TEXT NOT NULL DEFAULT 'HSN',
      DefaultGstRate REAL NOT NULL DEFAULT 5.0,
      IsActive INTEGER NOT NULL DEFAULT 1
    );
  """;

  static const String createGstConfigTable = """
    CREATE TABLE $localGstConfig (
      ConfigId INTEGER PRIMARY KEY,
      GSTIN TEXT NOT NULL,
      LegalName TEXT NOT NULL,
      TradeName TEXT NOT NULL,
      StateName TEXT NOT NULL,
      StateCode TEXT NOT NULL,
      IsCompositionScheme INTEGER NOT NULL DEFAULT 0,
      DefaultPricingIsTaxInclusive INTEGER NOT NULL DEFAULT 1,
      InvoiceTermsAndConditions TEXT,
      InvoiceHeader TEXT,
      InvoiceFooter TEXT,
      ShowHsnSummaryOnReceipt INTEGER NOT NULL DEFAULT 1,
      ShowTaxBreakupOnReceipt INTEGER NOT NULL DEFAULT 1
    );
  """;

  static const String createCreditNoteTable = """
    CREATE TABLE $localCreditNote (
      CreditNoteId INTEGER PRIMARY KEY,
      CreditNoteGuid TEXT NOT NULL UNIQUE,
      CreditNoteNumber TEXT NOT NULL UNIQUE,
      InvoiceId INTEGER NOT NULL,
      InvoiceNumber TEXT NOT NULL,
      CustomerId INTEGER,
      CustomerName TEXT,
      CustomerGstin TEXT,
      CreditNoteDateUTC TEXT NOT NULL,
      Reason TEXT NOT NULL,
      NoteType TEXT NOT NULL,
      TaxableAmount REAL NOT NULL,
      CgstAmount REAL NOT NULL,
      SgstAmount REAL NOT NULL,
      IgstAmount REAL NOT NULL,
      TotalTaxAmount REAL NOT NULL,
      GrandTotal REAL NOT NULL,
      Status TEXT NOT NULL
    );
  """;

  static const String createSyncOutboxTable = """
    CREATE TABLE $localSyncOutbox (
      OutboxId INTEGER PRIMARY KEY AUTOINCREMENT,
      EventGuid TEXT NOT NULL UNIQUE,
      IdempotencyKey TEXT NOT NULL UNIQUE,
      EntityType TEXT NOT NULL,
      EntityGuid TEXT NOT NULL,
      PayloadJson TEXT NOT NULL,
      SyncStatus INTEGER NOT NULL DEFAULT 1,
      RetryCount INTEGER NOT NULL DEFAULT 0,
      LastAttemptUTC TEXT,
      ErrorMessage TEXT,
      CreatedAtUTC TEXT NOT NULL
    );
  """;

  static const String createSyncLogTable = """
    CREATE TABLE $localSyncLog (
      LogId INTEGER PRIMARY KEY AUTOINCREMENT,
      SyncType TEXT NOT NULL,
      Status TEXT NOT NULL,
      RecordsProcessed INTEGER NOT NULL,
      ErrorMessage TEXT,
      TimestampUTC TEXT NOT NULL
    );
  """;

  static const String createDeviceStateTable = """
    CREATE TABLE $localDeviceState (
      DeviceId TEXT PRIMARY KEY,
      DeviceName TEXT NOT NULL,
      LastSyncTimeUTC TEXT,
      AppVersion TEXT NOT NULL,
      IsOnline INTEGER NOT NULL DEFAULT 1
    );
  """;
}

