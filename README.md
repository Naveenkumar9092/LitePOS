# LitePOS — Modern Offline-First Billing POS Software

> High-performance, production-ready, offline-first Point of Sale (POS) software built for **Cafe**, **Food Court**, and **Ice Cream & Desserts** businesses. Supports Android, iOS, Windows Desktop, and POS Terminals with single-company, single-shop operations and 3-tier Role-Based Access Control (`SAdmin`, `Admin`, `Cashier`).

---

## 🌟 Key Features

- **High-Speed Counter Billing**: Real-time reactive cart with category quick-switch, keyword search, item discounts, bill-level discounts, rounding adjustment, and rapid keyboard checkout.
- **Offline-First Synchronization**: Dual database architecture utilizing **SQLite** (`sqflite`) for instant offline sales and **SQL Server LocalDB** for cloud synchronization. Outbox queue, automatic conflict resolution, batch push/pull, and audit trails.
- **Hardware & Thermal Printing**: Pure cross-platform standard **ESC/POS byte generator** supporting 80mm (48-column) and 58mm (32-column) paper rolls, cash drawer kick pulses (`1B 70 00 19 FA`), full/partial paper cuts (`1D 56 42 00`), and dynamic UPI payment QR codes.
- **Multi-Mode Payment Engine**: Accepts Cash, UPI (with QR code generation), Card, and Split payments with cashier shift drawer reconciliation and refund management.
- **GST Compliance**: Intra-state intra-tax splits (50% CGST + 50% SGST), inter-state IGST handling, HSN/SAC code mapping, and GST-compliant tax invoicing.
- **Customer Directory & Loyalty**: Instant 10-digit mobile number lookup, order history, and digital invoicing consent flags.
- **Digital Softcopy Invoicing & Reports**: Instant PDF softcopy invoice generation, print preview, and local file export across mobile, desktop, and web. Executive Business Intelligence reports with PDF & CSV export for daily trends, top products, payment modes, and GST audit reconciliation.
- **Reports & Business Analytics**: Real-time KPI dashboards, hourly sales heatmaps (rush hour peaks), cashier performance tracking, category sales breakdowns, and GST tax summaries with one-click softcopy PDF and CSV exports.

---

## 🏗️ Architecture & Technology Stack

```
LitePOS
├── BillingPOS/               # ASP.NET Core Web API (.NET 10)
│   ├── BillingPOS.Domain/          # Entities, Enums, Interfaces, Base Auditable Models
│   ├── BillingPOS.Application/     # CQRS/Services, DTOs, FluentValidation, Business Logic
│   ├── BillingPOS.Infrastructure/  # EF Core, SQL Server LocalDB, Repositories, Unit of Work
│   ├── BillingPOS.Api/             # REST API Controllers, JWT Auth, Swagger OpenAPI
│   └── BillingPOS.Tests/           # xUnit Unit & Integration Tests (149 Tests)
│
└── billing_pos_app/          # Flutter Frontend (Cross-Platform)
    ├── lib/
    │   ├── core/                   # Theme, Network (Dio), SQLite DB, Routes, Formatting
    │   ├── features/               # 15 Self-Contained Domain Features (State, UI, Data)
    │   │   ├── authentication/     # JWT Token & Session Management
    │   │   ├── company/            # Company & Shop Setup
    │   │   ├── users/              # RBAC & User Administration
    │   │   ├── dashboard/          # Analytics & Overview Cards
    │   │   ├── categories/         # Menu Categories
    │   │   ├── products/           # Catalog & Availability Toggles
    │   │   ├── billing/            # High-Speed POS Cart & Billing Screen
    │   │   ├── orders/             # Order Tracking & Invoice Sequences
    │   │   ├── payments/           # Cash, UPI, Card, Split & Cash Register
    │   │   ├── gst/                # Tax Rates, HSN Mapping, GSTIN
    │   │   ├── customers/          # Directory & Purchase History
    │   │   ├── reports/            # Business & Sales Analytics
    │   │   ├── sync/               # Offline-First SQLite Sync Engine
    │   │   ├── hardware/           # ESC/POS Thermal Printers & Cash Drawer
    │   │   └── notifications/      # Digital Invoicing (Email & WhatsApp)
    │   └── shared/                 # Universal UI Shell & Reusable Widgets
    └── test/                       # Flutter Unit, State & Widget Tests (162 Tests)
```

---

## 📋 Implemented Modules (0 to 14)

| # | Module | Scope & Capabilities | Test Status |
|---|---|---|:---:|
| **0** | **Foundation & Clean Architecture** | .NET 10 Clean Architecture, EF Core LocalDB, Repository pattern, Error Middleware | 🟢 100% |
| **1** | **Authentication & RBAC** | JWT Access Tokens, Refresh Token Rotation, Password Hashing, 3 Roles (`SAdmin`, `Admin`, `Cashier`) | 🟢 100% |
| **2** | **Company & Shop Management** | Single Company & Single Shop constraint, Operating Hours, Tax Identifiers | 🟢 100% |
| **3** | **User & Session Management** | Cashier and Admin accounts, Profile Updates, Active Sessions | 🟢 100% |
| **4** | **Categories Management** | Display ordering, Item counts, Active status filters | 🟢 100% |
| **5** | **Products & Catalog** | Simple single-rate catalog (no variants/add-ons), Stock toggles, HSN assignments | 🟢 100% |
| **6** | **POS Billing & Cart** | Reactive cart, itemized line discounts, rounding adjustment, bill calculation | 🟢 100% |
| **7** | **Order Management** | Lifecycle tracking (`Placed`, `Billed`, `Completed`, `Cancelled`), daily invoice numbering | 🟢 100% |
| **8** | **Payment Management** | Cash, UPI QR, Card, Split modes, Cash drawer reconciliation, Refund tracking | 🟢 100% |
| **9** | **GST Billing & Tax Engine** | CGST/SGST 50/50 intra-state tax calculation, IGST, GSTIN format validation | 🟢 100% |
| **10** | **Customer Directory** | 10-digit mobile lookup, Purchase history, Invoicing consent flags | 🟢 100% |
| **11** | **Reports & Business Analytics** | KPI cards, Rush hour charts (cafe peaks), Cashier rankings, Tax reports | 🟢 100% |
| **12** | **Offline SQLite Sync Engine** | Offline outbox queue, Batch push/pull endpoints, GUID mappings, Sync audit logs | 🟢 100% |
| **13** | **Hardware & Thermal Printers** | ESC/POS byte generator, 80mm/58mm rolls, Cash drawer kick (`1B 70 00 19 FA`), Paper cut | 🟢 100% |
| **14** | **Settings & Notifications** | Branded HTML email invoices, WhatsApp digital summaries, Database backup snapshots | 🟢 100% |

---

## 🚀 Getting Started

### Prerequisites
- [.NET 10.0 SDK](https://dotnet.microsoft.com/)
- [Flutter 3.x](https://flutter.dev/) with Dart 3.x
- Microsoft SQL Server LocalDB (`(localdb)\MSSQLLocalDB`)
- Python 3.x (for running live verification scripts)

---

### 1. Backend Setup & Run

```bash
# Navigate to API project
cd BillingPOS/BillingPOS.Api

# Restore and run API on port 5270
dotnet run --urls "http://localhost:5270"
```

* Swagger UI: [http://localhost:5270/swagger](http://localhost:5270/swagger)
* Health Check: [http://localhost:5270/api/v1/health](http://localhost:5270/api/v1/health)

#### Default Seed Credentials:
- **Admin**: `admin` / `Admin@123!` (Role: `Admin`)
- **Cashier**: `cashier` / `Cashier@123!` (Role: `Cashier`)
- **Super Admin**: `sadmin` / `SAdmin@123!` (Role: `SAdmin`)

---

### 2. Frontend Setup & Run

```bash
# Navigate to Flutter app
cd billing_pos_app

# Fetch dependencies
flutter pub get

# Run on Windows Desktop
flutter run -d windows

# Run on Chrome/Web
flutter run -d chrome

# Run on Connected Android POS Device
flutter run -d android
```

---

## 🧪 Testing & Quality Assurance

### Run .NET 10 Backend Unit Tests
```bash
dotnet test "BillingPOS/BillingPOS.slnx"
```
> **Result**: 149 Passed, 0 Failed (100% Green)

### Run Flutter Frontend Tests
```bash
cd billing_pos_app
flutter test
```
> **Result**: 162 Passed, 0 Failed (100% Green)

### Run Flutter Static Code Analysis
```bash
cd billing_pos_app
flutter analyze
```
> **Result**: No issues found! (0 warnings, 0 errors)

---

## 📄 License
LitePOS is licensed under the MIT License.

