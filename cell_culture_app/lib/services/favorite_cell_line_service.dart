import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/cell_line_option.dart';

class RecentCellLineService {
  static const String _storageKey = 'recent_cell_lines_v1';
  static const int _maxItems = 5;

  static Future<List<CellLineOption>> loadRecentCellLines() async {
    final prefs = await SharedPreferences.getInstance();
    final rawList = prefs.getStringList(_storageKey) ?? [];

    return rawList
        .map((e) => CellLineOption.fromJson(jsonDecode(e) as Map<String, dynamic>))
        .toList();
  }

  static Future<void> saveRecentCellLine(CellLineOption option) async {
    final prefs = await SharedPreferences.getInstance();
    final current = await loadRecentCellLines();

    final updated = <CellLineOption>[
      option,
      ...current.where(
        (e) =>
            !(e.name == option.name &&
                e.source == option.source &&
                e.catalogNumber == option.catalogNumber),
      ),
    ];

    final trimmed = updated.take(_maxItems).toList();
    final encoded = trimmed.map((e) => jsonEncode(e.toJson())).toList();

    await prefs.setStringList(_storageKey, encoded);
  }

  static Future<void> clearRecentCellLines() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }
}