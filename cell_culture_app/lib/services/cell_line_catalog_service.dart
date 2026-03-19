import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

import '../models/cell_line_option.dart';

class CellLineCatalogService {
  static Future<List<CellLineOption>> loadCatalog() async {
    final jsonString =
        await rootBundle.loadString('assets/data/cell_line_catalog.json');

    final decoded = jsonDecode(jsonString) as List<dynamic>;

    return decoded
        .map((e) => CellLineOption.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static String normalizeCellLineText(String text) {
    return text.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
  }

  static bool matchesQuery(CellLineOption item, String query) {
    final normalizedQuery = normalizeCellLineText(query);
    if (normalizedQuery.isEmpty) return true;

    return item.searchableTexts.any((text) {
      return normalizeCellLineText(text).contains(normalizedQuery);
    });
  }

  static bool hasAlias(CellLineOption item, String alias) {
    final normalizedAlias = normalizeCellLineText(alias);
    return item.searchableTexts.any((text) {
      return normalizeCellLineText(text) == normalizedAlias;
    });
  }
}