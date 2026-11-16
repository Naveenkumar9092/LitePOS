# LitePOS Windows Desktop Production Deployment & Administration Guide

## 1. Package Overview
This distribution bundle contains everything required to deploy, run, and maintain **LitePOS** on Windows POS Terminals and Desktop PCs.

```
dist\LitePOS_Windows_x64\
├── backend\                   # Published ASP.NET Core Web API (.NET 10 Release)
│   ├── BillingPOS.Api.exe     # Standalone Web API Executable
│   ├── appsettings.json       # Production Database & Security Configuration
│   └── ...                    # Runtime Dependencies & Libraries
├── Setup-Database.bat         # Automated SQL Server LocalDB Setup & Migration
├── Start-LitePOS.bat          # 1-Click Launch: Starts Backend Service & POS UI
├── Stop-LitePOS.bat           # Graceful Shutdown of all LitePOS processes
└── DEPLOYMENT_GUIDE.md        # This Deployment & Administration Manual
```

---

## 2. Hardware & System Requirements

- **Operating System**: Windows 10 (version 1903+) or Windows 11 (64-bit).
- **CPU**: Dual-Core 2.0 GHz or higher.
- **RAM**: Minimum 4 GB (8 GB recommended for heavy rush hour queues).
- **Storage**: At least 10 GB free SSD storage.
- **Display**: Minimum 1024x768 resolution (Full HD 1920x1080 recommended for dual-pane counter checkout).
- **Thermal Printer**: Any ESC/POS compatible 80mm or 58mm printer connected via Network (TCP/IP Port 9100), USB, or Bluetooth.
- **Cash Drawer**: Standard RJ11 / RJ12 cash drawer connected to printer kick-out port (Pulse: `1B 70 00 19 FA`).

---

## 3. Initial Installation & First Run

### Step 1: Database Setup
1. Double-click `Setup-Database.bat`.
2. The script will initialize the local SQL Server LocalDB instance `(localdb)\MSSQLLocalDB` and verify the `LitePOS_BillingDb_Dev` database.

### Step 2: Starting LitePOS
1. Double-click `Start-LitePOS.bat`.
2. The backend server starts automatically on port `5270`.
3. The POS interface launches in fullscreen/counter mode.

### Step 3: Default User Credentials
| Role | Username | Default Password | Permissions |
|---|---|---|---|
| **Shop Administrator** | `admin` | `Admin@123!` | Full control over catalog, tax, users, reports, hardware & backups |
| **Billing Cashier** | `cashier` | `Cashier@123!` | POS billing, order creation, payment collection, receipts |
| **Super Admin** | `sadmin` | `SAdmin@123!` | Master system administration |

---

## 4. Hardware & Thermal Printer Setup

1. In LitePOS, log in as `admin`.
2. Navigate to **Printers** from the navigation rail or settings menu.
3. Click **Add Printer**:
   - **For Network Thermal Printers**: Select **Network**, enter the printer's static IP (e.g., `192.168.1.100`), Port `9100`.
   - **For USB Thermal Printers**: Select **USB**, enter the Windows printer name (e.g., `POS-80`).
   - **Paper Size**: Choose `80mm (48 Columns)` for standard rolls or `58mm (32 Columns)` for compact rolls.
   - **Options**: Enable **Auto-Cut Receipt**, **Open Cash Drawer**, and **Print UPI QR Code**.
4. Click **Test Print** to verify standard ESC/POS output, alignment, and paper cut.
5. Click **Set Default** to route all counter receipts to this printer.

---

## 5. Offline-First Operation & Synchronization

- LitePOS operates seamlessly **100% offline**:
  - All sales, cart orders, and payments are committed immediately to the fast local SQLite database.
  - Transactions are queued in the internal sync outbox.
- When an internet connection or LAN connectivity is restored:
  - The Sync engine automatically performs a batch push to the central cloud/LocalDB database.
  - Conflicts are safely reconciled using client-server GUID mapping.
  - View sync health and history anytime under the **Sync** tab.

---

## 6. Daily Backup & Maintenance

- In LitePOS under **Settings > Backup & System**, click **Backup Database Now** at the end of each business day.
- Backups are timestamped and archived to `C:\LitePOS\Backups\` by default.
- Backups include complete sales, customer profiles, invoices, tax records, and configuration logs.

---

## 7. Windows Developer Mode (Optional for Native Binary Rebuilding)

To compile the Flutter Windows runner into a standalone `.exe` without relying on Flutter runtime:
1. Open Windows Settings (`Win + I`).
2. Go to **Privacy & security > For developers**.
3. Toggle **Developer Mode** to **ON**.
4. Open terminal and run:
   ```cmd
   cd billing_pos_app
   flutter build windows --release
   ```
5. The standalone executable will be located in `billing_pos_app\build\windows\x64\runner\Release\`.

