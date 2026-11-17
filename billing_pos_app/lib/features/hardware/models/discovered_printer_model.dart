import "printer_model.dart";

/// Represents a discovered thermal printer found via Bluetooth, USB, or Network scanning.
class DiscoveredPrinterModel {
  final String name;
  final String address; // MAC address for BT, deviceId for USB, IP address for Network
  final PrinterConnectionType connectionType;
  final int port;
  final bool isOnline;
  final String? extraInfo;

  const DiscoveredPrinterModel({
    required this.name,
    required this.address,
    required this.connectionType,
    this.port = 9100,
    this.isOnline = true,
    this.extraInfo,
  });

  factory DiscoveredPrinterModel.fromMap(Map<String, dynamic> map, PrinterConnectionType fallbackType) {
    final typeStr = (map["type"] as String?)?.toLowerCase();
    final type = typeStr == "bluetooth"
        ? PrinterConnectionType.bluetooth
        : typeStr == "usb"
            ? PrinterConnectionType.usb
            : typeStr == "network"
                ? PrinterConnectionType.network
                : fallbackType;

    return DiscoveredPrinterModel(
      name: map["name"] as String? ?? "Thermal Printer",
      address: map["address"] as String? ?? "",
      connectionType: type,
      port: (map["port"] as num?)?.toInt() ?? 9100,
      isOnline: map["connected"] as bool? ?? true,
      extraInfo: map["vendorId"] != null ? "VID:${map["vendorId"]} PID:${map["productId"]}" : null,
    );
  }

  Map<String, dynamic> toMap() => {
        "name": name,
        "address": address,
        "connectionType": connectionType.name,
        "port": port,
        "isOnline": isOnline,
        "extraInfo": extraInfo,
      };
}

/// Represents an item on a Kitchen Order Token (KOT) / Order Token.
class TokenItemModel {
  final int slNo;
  final String itemName;
  final double quantity;
  final double rate;
  final double amount;

  const TokenItemModel({
    required this.slNo,
    required this.itemName,
    required this.quantity,
    required this.rate,
    required this.amount,
  });

  factory TokenItemModel.fromJson(Map<String, dynamic> json) {
    return TokenItemModel(
      slNo: (json["slNo"] as num?)?.toInt() ?? 0,
      itemName: json["foodName"] as String? ?? json["itemName"] as String? ?? "",
      quantity: (json["qty"] as num?)?.toDouble() ?? (json["quantity"] as num?)?.toDouble() ?? 1.0,
      rate: (json["rate"] as num?)?.toDouble() ?? 0.0,
      amount: (json["price"] as num?)?.toDouble() ?? (json["amount"] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() => {
        "slNo": slNo,
        "foodName": itemName,
        "qty": quantity,
        "rate": rate,
        "price": amount,
      };
}
