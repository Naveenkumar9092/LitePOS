import "thermal_receipt_printer_stub.dart"
    if (dart.library.html) "thermal_receipt_printer_web.dart";

/// Multi-platform entry point to trigger browser-native printing for 80mm thermal receipts.
void printThermalHtmlInBrowser(String htmlContent) {
  printHtmlDirectly(htmlContent);
}
