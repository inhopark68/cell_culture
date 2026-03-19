import 'package:intl/intl.dart';

String formatIntWithComma(num value) {
  return NumberFormat('#,###').format(value);
}

String formatDecimalWithComma(num value) {
  return NumberFormat('#,##0.##').format(value);
}

double? parseFormattedDouble(String text) {
  final normalized = text.replaceAll(',', '').trim();
  if (normalized.isEmpty) return null;
  return double.tryParse(normalized);
}

int? parseFormattedInt(String text) {
  final normalized = text.replaceAll(',', '').trim();
  if (normalized.isEmpty) return null;
  return int.tryParse(normalized);
}