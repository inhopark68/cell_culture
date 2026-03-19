import 'number_formatters.dart';

String? validateRequiredNumber(String? value, String fieldName) {
  if (value == null || value.trim().isEmpty) {
    return '$fieldName 값을 입력하세요.';
  }

  final n = parseFormattedDouble(value);
  if (n == null) {
    return '$fieldName 숫자 형식이 올바르지 않습니다.';
  }

  return null;
}

String? validatePositiveNumber(String? value, String fieldName) {
  final basic = validateRequiredNumber(value, fieldName);
  if (basic != null) return basic;

  final n = parseFormattedDouble(value!);
  if (n == null) {
    return '$fieldName 숫자 형식이 올바르지 않습니다.';
  }

  if (n <= 0) {
    return '$fieldName 0보다 커야 합니다.';
  }

  return null;
}

String? validateNonNegativeNumber(String? value, String fieldName) {
  final basic = validateRequiredNumber(value, fieldName);
  if (basic != null) return basic;

  final n = parseFormattedDouble(value!);
  if (n == null) {
    return '$fieldName 숫자 형식이 올바르지 않습니다.';
  }

  if (n < 0) {
    return '$fieldName 0 이상이어야 합니다.';
  }

  return null;
}

String? validateNonNegativeInteger(String? value, String fieldName) {
  if (value == null || value.trim().isEmpty) {
    return '$fieldName 값을 입력하세요.';
  }

  final n = parseFormattedInt(value);
  if (n == null) {
    return '$fieldName 정수를 입력하세요.';
  }

  if (n < 0) {
    return '$fieldName 0 이상이어야 합니다.';
  }

  return null;
}

String? validatePositiveInteger(String? value, String fieldName) {
  final basic = validateNonNegativeInteger(value, fieldName);
  if (basic != null) return basic;

  final n = parseFormattedInt(value!);
  if (n == null) {
    return '$fieldName 정수를 입력하세요.';
  }

  if (n <= 0) {
    return '$fieldName 1 이상이어야 합니다.';
  }

  return null;
}

String? validatePercent0to100(String? value, String fieldName) {
  final basic = validateRequiredNumber(value, fieldName);
  if (basic != null) return basic;

  final n = parseFormattedDouble(value!);
  if (n == null) {
    return '$fieldName 숫자 형식이 올바르지 않습니다.';
  }

  if (n < 0 || n > 100) {
    return '$fieldName 0~100 범위여야 합니다.';
  }

  return null;
}