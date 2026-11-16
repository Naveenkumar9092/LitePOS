import "package:intl/intl.dart";
import "../constants/app_constants.dart";

class CurrencyFormatter {
  static final NumberFormat _formatter = NumberFormat.currency(
    symbol: AppConstants.defaultCurrencySymbol,
    locale: "en_IN",
    decimalDigits: 2,
  );

  static String format(num? amount, {String? customSymbol}) {
    if (amount == null) return "${customSymbol ?? AppConstants.defaultCurrencySymbol}0.00";
    if (customSymbol != null) {
      return "$customSymbol${NumberFormat("#,##,##0.00", "en_IN").format(amount)}";
    }
    return _formatter.format(amount);
  }

  static String formatINR(num? amount) => format(amount);

  static double round(double amount) {
    return (amount * 100).roundToDouble() / 100;
  }
}

