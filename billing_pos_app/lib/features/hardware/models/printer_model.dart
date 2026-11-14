enum PrinterConnectionType {
  network,
  usb,
  bluetooth,
}

enum PrinterPaperSize {
  mm80,
  mm58,
}

class PrinterConfigurationModel {
  final int id;
  final String printerName;
  final PrinterConnectionType connectionType;
  final String? ipAddress;
  final int port;
  final String? usbDeviceName;
  final String? bluetoothMacAddress;
  final PrinterPaperSize paperSize;
  final int characterColumns;
  final bool autoCutReceipt;
  final bool openCashDrawer;
  final bool printLogo;
  final bool printQrCode;
  final int printCopies;
  final String? headerCustomText;
  final String? footerCustomText;
  final bool isDefault;
  final bool isActive;

  const PrinterConfigurationModel({
    required this.id,
    required this.printerName,
    this.connectionType = PrinterConnectionType.network,
    this.ipAddress,
    this.port = 9100,
    this.usbDeviceName,
    this.bluetoothMacAddress,
    this.paperSize = PrinterPaperSize.mm80,
    this.characterColumns = 48,
    this.autoCutReceipt = true,
    this.openCashDrawer = true,
    this.printLogo = false,
    this.printQrCode = true,
    this.printCopies = 1,
    this.headerCustomText,
    this.footerCustomText,
    this.isDefault = false,
    this.isActive = true,
  });

  factory PrinterConfigurationModel.fromJson(Map<String, dynamic> json) {
    final connVal = (json["connectionType"] as num?)?.toInt() ?? 1;
    final sizeVal = (json["paperSize"] as num?)?.toInt() ?? 1;

    return PrinterConfigurationModel(
      id: (json["id"] as num?)?.toInt() ?? 0,
      printerName: json["printerName"] as String? ?? "Thermal Printer",
      connectionType: connVal == 2
          ? PrinterConnectionType.usb
          : connVal == 3
              ? PrinterConnectionType.bluetooth
              : PrinterConnectionType.network,
      ipAddress: json["ipAddress"] as String?,
      port: (json["port"] as num?)?.toInt() ?? 9100,
      usbDeviceName: json["usbDeviceName"] as String?,
      bluetoothMacAddress: json["bluetoothMacAddress"] as String?,
      paperSize: sizeVal == 2 ? PrinterPaperSize.mm58 : PrinterPaperSize.mm80,
      characterColumns: (json["characterColumns"] as num?)?.toInt() ?? 48,
      autoCutReceipt: json["autoCutReceipt"] as bool? ?? true,
      openCashDrawer: json["openCashDrawer"] as bool? ?? true,
      printLogo: json["printLogo"] as bool? ?? false,
      printQrCode: json["printQrCode"] as bool? ?? true,
      printCopies: (json["printCopies"] as num?)?.toInt() ?? 1,
      headerCustomText: json["headerCustomText"] as String?,
      footerCustomText: json["footerCustomText"] as String?,
      isDefault: json["isDefault"] as bool? ?? false,
      isActive: json["isActive"] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        "id": id,
        "printerName": printerName,
        "connectionType": connectionType == PrinterConnectionType.usb
            ? 2
            : connectionType == PrinterConnectionType.bluetooth
                ? 3
                : 1,
        "ipAddress": ipAddress,
        "port": port,
        "usbDeviceName": usbDeviceName,
        "bluetoothMacAddress": bluetoothMacAddress,
        "paperSize": paperSize == PrinterPaperSize.mm58 ? 2 : 1,
        "characterColumns": characterColumns,
        "autoCutReceipt": autoCutReceipt,
        "openCashDrawer": openCashDrawer,
        "printLogo": printLogo,
        "printQrCode": printQrCode,
        "printCopies": printCopies,
        "headerCustomText": headerCustomText,
        "footerCustomText": footerCustomText,
        "isDefault": isDefault,
        "isActive": isActive,
      };

  PrinterConfigurationModel copyWith({
    int? id,
    String? printerName,
    PrinterConnectionType? connectionType,
    String? ipAddress,
    int? port,
    String? usbDeviceName,
    String? bluetoothMacAddress,
    PrinterPaperSize? paperSize,
    int? characterColumns,
    bool? autoCutReceipt,
    bool? openCashDrawer,
    bool? printLogo,
    bool? printQrCode,
    int? printCopies,
    String? headerCustomText,
    String? footerCustomText,
    bool? isDefault,
    bool? isActive,
  }) {
    return PrinterConfigurationModel(
      id: id ?? this.id,
      printerName: printerName ?? this.printerName,
      connectionType: connectionType ?? this.connectionType,
      ipAddress: ipAddress ?? this.ipAddress,
      port: port ?? this.port,
      usbDeviceName: usbDeviceName ?? this.usbDeviceName,
      bluetoothMacAddress: bluetoothMacAddress ?? this.bluetoothMacAddress,
      paperSize: paperSize ?? this.paperSize,
      characterColumns: characterColumns ?? this.characterColumns,
      autoCutReceipt: autoCutReceipt ?? this.autoCutReceipt,
      openCashDrawer: openCashDrawer ?? this.openCashDrawer,
      printLogo: printLogo ?? this.printLogo,
      printQrCode: printQrCode ?? this.printQrCode,
      printCopies: printCopies ?? this.printCopies,
      headerCustomText: headerCustomText ?? this.headerCustomText,
      footerCustomText: footerCustomText ?? this.footerCustomText,
      isDefault: isDefault ?? this.isDefault,
      isActive: isActive ?? this.isActive,
    );
  }
}

class TestPrintResultModel {
  final String printerName;
  final PrinterPaperSize paperSize;
  final String base64EscPosBytes;
  final int byteCount;
  final String plainTextPreview;
  final DateTime generatedAtUtc;

  const TestPrintResultModel({
    required this.printerName,
    required this.paperSize,
    required this.base64EscPosBytes,
    required this.byteCount,
    required this.plainTextPreview,
    required this.generatedAtUtc,
  });

  factory TestPrintResultModel.fromJson(Map<String, dynamic> json) {
    final sizeVal = (json["paperSize"] as num?)?.toInt() ?? 1;
    return TestPrintResultModel(
      printerName: json["printerName"] as String? ?? "Thermal Printer",
      paperSize: sizeVal == 2 ? PrinterPaperSize.mm58 : PrinterPaperSize.mm80,
      base64EscPosBytes: json["base64EscPosBytes"] as String? ?? "",
      byteCount: (json["byteCount"] as num?)?.toInt() ?? 0,
      plainTextPreview: json["plainTextPreview"] as String? ?? "",
      generatedAtUtc: DateTime.tryParse(json["generatedAtUtc"]?.toString() ?? "") ?? DateTime.now(),
    );
  }
}

class ReceiptPrintResultModel {
  final int invoiceId;
  final String invoiceNumber;
  final String printerName;
  final PrinterPaperSize paperSize;
  final String base64EscPosBytes;
  final int byteCount;
  final String plainTextPreview;
  final DateTime generatedAtUtc;

  const ReceiptPrintResultModel({
    required this.invoiceId,
    required this.invoiceNumber,
    required this.printerName,
    required this.paperSize,
    required this.base64EscPosBytes,
    required this.byteCount,
    required this.plainTextPreview,
    required this.generatedAtUtc,
  });

  factory ReceiptPrintResultModel.fromJson(Map<String, dynamic> json) {
    final sizeVal = (json["paperSize"] as num?)?.toInt() ?? 1;
    return ReceiptPrintResultModel(
      invoiceId: (json["invoiceId"] as num?)?.toInt() ?? 0,
      invoiceNumber: json["invoiceNumber"] as String? ?? "",
      printerName: json["printerName"] as String? ?? "Thermal Printer",
      paperSize: sizeVal == 2 ? PrinterPaperSize.mm58 : PrinterPaperSize.mm80,
      base64EscPosBytes: json["base64EscPosBytes"] as String? ?? "",
      byteCount: (json["byteCount"] as num?)?.toInt() ?? 0,
      plainTextPreview: json["plainTextPreview"] as String? ?? "",
      generatedAtUtc: DateTime.tryParse(json["generatedAtUtc"]?.toString() ?? "") ?? DateTime.now(),
    );
  }
}

class CashDrawerCommandModel {
  final String commandName;
  final String base64EscPosBytes;
  final String hexString;

  const CashDrawerCommandModel({
    required this.commandName,
    required this.base64EscPosBytes,
    required this.hexString,
  });

  factory CashDrawerCommandModel.fromJson(Map<String, dynamic> json) {
    return CashDrawerCommandModel(
      commandName: json["commandName"] as String? ?? "Open Cash Drawer",
      base64EscPosBytes: json["base64EscPosBytes"] as String? ?? "",
      hexString: json["hexString"] as String? ?? "1B 70 00 19 FA",
    );
  }
}

