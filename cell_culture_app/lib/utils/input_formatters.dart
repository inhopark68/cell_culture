import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class ThousandsSeparatorInputFormatter extends TextInputFormatter {
  ThousandsSeparatorInputFormatter() : _formatter = NumberFormat('#,###');

  final NumberFormat _formatter;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final rawText = newValue.text.replaceAll(',', '');

    if (rawText.isEmpty) {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }

    final number = int.tryParse(rawText);
    if (number == null) return oldValue;

    final formatted = _formatter.format(number);

    final digitsBeforeCursor = _countDigits(
      newValue.text.substring(
        0,
        newValue.selection.baseOffset.clamp(0, newValue.text.length),
      ),
    );

    final newCursor = _findCursorPositionFromDigitCount(
      formatted,
      digitsBeforeCursor,
    );

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: newCursor),
    );
  }

  int _countDigits(String text) {
    return text.replaceAll(RegExp(r'[^0-9]'), '').length;
  }

  int _findCursorPositionFromDigitCount(String text, int digitCount) {
    if (digitCount <= 0) return 0;

    int seenDigits = 0;
    for (int i = 0; i < text.length; i++) {
      if (RegExp(r'[0-9]').hasMatch(text[i])) {
        seenDigits++;
        if (seenDigits == digitCount) return i + 1;
      }
    }

    return text.length;
  }
}

class DecimalThousandsSeparatorInputFormatter extends TextInputFormatter {
  DecimalThousandsSeparatorInputFormatter({this.decimalRange = 2})
      : _intFormatter = NumberFormat('#,###');

  final int decimalRange;
  final NumberFormat _intFormatter;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final raw = newValue.text.replaceAll(',', '');

    if (raw.isEmpty) {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }

    if (!RegExp('^\\d*\\.?\\d{0,$decimalRange}\$').hasMatch(raw)) {
      return oldValue;
    }

    final parts = raw.split('.');
    if (parts.length > 2) return oldValue;

    final intPartRaw = parts[0];
    final hasDot = raw.contains('.');
    final decimalPart = parts.length == 2 ? parts[1] : null;

    final intPart = intPartRaw.isEmpty ? 0 : int.tryParse(intPartRaw);
    if (intPart == null) return oldValue;

    final formattedInt = _intFormatter.format(intPart);

    String formatted;
    if (hasDot && decimalPart != null) {
      formatted = '$formattedInt.$decimalPart';
    } else if (hasDot) {
      formatted = '$formattedInt.';
    } else {
      formatted = formattedInt;
    }

    final rawCursor =
        _rawCursorIndex(newValue.text, newValue.selection.baseOffset);
    final newCursor = _formattedCursorIndex(formatted, rawCursor);

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: newCursor),
    );
  }

  int _rawCursorIndex(String text, int cursor) {
    final safeCursor = cursor.clamp(0, text.length);
    return text.substring(0, safeCursor).replaceAll(',', '').length;
  }

  int _formattedCursorIndex(String formatted, int rawCursor) {
    if (rawCursor <= 0) return 0;

    int rawCount = 0;
    for (int i = 0; i < formatted.length; i++) {
      final ch = formatted[i];
      if (RegExp(r'[0-9.]').hasMatch(ch)) {
        rawCount++;
        if (rawCount == rawCursor) return i + 1;
      }
    }

    return formatted.length;
  }
}