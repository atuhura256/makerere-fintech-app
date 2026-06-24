import 'package:flutter/material.dart';

class CurrencyState {
  static final ValueNotifier<String> currency = ValueNotifier<String>('UGX');
  static const double exchangeRate = 3700.0; // 1 USD = 3700 UGX

  static void toggleCurrency() {
    if (currency.value == 'UGX') {
      currency.value = 'USD';
    } else {
      currency.value = 'UGX';
    }
  }

  static String formatAmount(double amountInUgx) {
    if (currency.value == 'UGX') {
      return 'UGX ${amountInUgx.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}';
    } else {
      double usdAmount = amountInUgx / exchangeRate;
      return '\$${usdAmount.toStringAsFixed(2)}';
    }
  }
}
