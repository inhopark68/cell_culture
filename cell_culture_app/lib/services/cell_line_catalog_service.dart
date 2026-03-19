import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

import '../models/cell_line_option.dart';

class CellLineCatalogService {
  static List<CellLineOption>? _cache;

  static Future<List<CellLineOption>> loadCatalog() async {
    if (_cache != null) return _cache!;

    final raw = await rootBundle.loadString('assets/cell_lines.json');
    final list = (jsonDecode(raw) as List)
        .map((e) => CellLineOption.fromJson(e as Map<String, dynamic>))
        .toList();

    _cache = list;
    return list;
  }

  static String normalizeCellLineText(String input) {
    return input
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[\s\-_./()]+'), '');
  }

  static bool hasAlias(CellLineOption item, String query) {
    final normalizedQuery = normalizeCellLineText(query);
    if (normalizedQuery.isEmpty) return false;

    if (normalizeCellLineText(item.primaryName) == normalizedQuery) {
      return true;
    }

    for (final synonym in item.synonyms) {
      if (normalizeCellLineText(synonym) == normalizedQuery) {
        return true;
      }
    }

    return false;
  }

  static bool matchesQuery(CellLineOption item, String query) {
    final normalizedQuery = normalizeCellLineText(query);
    if (normalizedQuery.isEmpty) return true;

    return item.searchableTexts.any(
      (text) => normalizeCellLineText(text).contains(normalizedQuery),
    );
  }
}