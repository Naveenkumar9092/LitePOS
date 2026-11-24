// ignore: avoid_web_libraries_in_flutter
import "dart:html" as html;

/// Browser-specific implementation for direct 80mm thermal receipt printing.
/// Creates a clean, hidden iframe to trigger the browser's native print engine
/// without disrupting the main POS user interface.
void printHtmlDirectly(String htmlContent) {
  final existingIframe = html.document.getElementById("pos_thermal_receipt_frame");
  existingIframe?.remove();

  final iframe = html.IFrameElement()
    ..id = "pos_thermal_receipt_frame"
    ..style.position = "fixed"
    ..style.right = "0"
    ..style.bottom = "0"
    ..style.width = "0"
    ..style.height = "0"
    ..style.border = "0"
    ..style.visibility = "hidden"
    ..srcdoc = htmlContent;

  html.document.body?.append(iframe);

  Future.delayed(const Duration(milliseconds: 350), () {
    try {
      (iframe as dynamic).contentWindow?.focus();
      (iframe as dynamic).contentWindow?.print();
    } catch (_) {
      html.window.print();
    }
  });

  Future.delayed(const Duration(seconds: 10), () {
    iframe.remove();
  });
}
