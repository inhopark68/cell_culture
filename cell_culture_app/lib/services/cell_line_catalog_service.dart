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
}