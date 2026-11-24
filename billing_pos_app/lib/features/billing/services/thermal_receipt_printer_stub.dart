/// Fallback stub for non-web platforms (Windows, Linux, macOS, Android, iOS).
/// The POS application routes printing via `Printing.layoutPdf` or pure Dart ESC/POS on native OS.
void printHtmlDirectly(String htmlContent) {
  // Non-web platforms use Printing.layoutPdf or EscPosGenerator
}
