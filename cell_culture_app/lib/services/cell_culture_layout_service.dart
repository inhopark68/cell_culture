import 'package:flutter/material.dart';

class CellCultureLayoutService {
  static List<List<String>> generatePlateLayout({
    required String ware,
    required int sampleCount,
    required int replicates,
    required int blankCount,
    required int vehicleCount,
    required int positiveControlCount,
    required int negativeControlCount,
  }) {
    final size = _plateSize(ware);
    if (size == null) return [];

    final rows = size.$1;
    final cols = size.$2;
    final totalWells = rows * cols;

    final sampleLabels = _buildSampleLabels(
      sampleCount: sampleCount,
      replicates: replicates,
    );

    final controlLabels = _buildControlLabels(
      blankCount: blankCount,
      negativeControlCount: negativeControlCount,
      vehicleCount: vehicleCount,
      positiveControlCount: positiveControlCount,
    );

    final optimized = _optimizeWellOrder(
      samples: sampleLabels,
      controls: controlLabels,
      totalWells: totalWells,
      rows: rows,
      cols: cols,
    );

    return _toGrid(
      labels: optimized,
      rows: rows,
      cols: cols,
    );
  }

  static (int, int)? _plateSize(String ware) {
    switch (ware) {
      case '6-well plate':
        return (2, 3);
      case '12-well plate':
        return (3, 4);
      case '24-well plate':
        return (4, 6);
      case '48-well plate':
        return (6, 8);
      case '96-well plate':
        return (8, 12);
      default:
        return null;
    }
  }

  static List<String> _buildSampleLabels({
    required int sampleCount,
    required int replicates,
  }) {
    final labels = <String>[];

    for (int s = 1; s <= sampleCount; s++) {
      for (int r = 1; r <= replicates; r++) {
        labels.add('S$s-R$r');
      }
    }

    return labels;
  }

  static List<String> _buildControlLabels({
    required int blankCount,
    required int negativeControlCount,
    required int vehicleCount,
    required int positiveControlCount,
  }) {
    final labels = <String>[];

    for (int i = 1; i <= negativeControlCount; i++) {
      labels.add('NC$i');
    }
    for (int i = 1; i <= vehicleCount; i++) {
      labels.add('VEH$i');
    }
    for (int i = 1; i <= positiveControlCount; i++) {
      labels.add('PC$i');
    }
    for (int i = 1; i <= blankCount; i++) {
      labels.add('BLK$i');
    }

    return labels;
  }

  static List<String> _optimizeWellOrder({
    required List<String> samples,
    required List<String> controls,
    required int totalWells,
    required int rows,
    required int cols,
  }) {
    final placed = <String>[];

    placed.addAll(_groupSamplesByReplicateProximity(
      samples: samples,
      cols: cols,
    ));

    placed.addAll(controls);

    if (placed.length > totalWells) {
      return placed.take(totalWells).toList();
    }

    final remaining = totalWells - placed.length;
    return [
      ...placed,
      ...List.generate(remaining, (_) => ''),
    ];
  }

  static List<String> _groupSamplesByReplicateProximity({
    required List<String> samples,
    required int cols,
  }) {
    if (samples.isEmpty) return [];

    final grouped = <String, List<String>>{};

    for (final label in samples) {
      final parts = label.split('-');
      final sampleKey = parts.first;
      grouped.putIfAbsent(sampleKey, () => []);
      grouped[sampleKey]!.add(label);
    }

    for (final entry in grouped.entries) {
      entry.value.sort((a, b) {
        final ra = _extractReplicateNumber(a);
        final rb = _extractReplicateNumber(b);
        return ra.compareTo(rb);
      });
    }

    final orderedSampleKeys = grouped.keys.toList()
      ..sort((a, b) => _extractSampleNumber(a).compareTo(_extractSampleNumber(b)));

    final output = <String>[];

    for (final key in orderedSampleKeys) {
      final replicates = grouped[key]!;
      output.addAll(replicates);
    }

    return output;
  }

  static int _extractSampleNumber(String label) {
    final match = RegExp(r'S(\d+)').firstMatch(label);
    if (match == null) return 999999;
    return int.tryParse(match.group(1) ?? '') ?? 999999;
  }

  static int _extractReplicateNumber(String label) {
    final match = RegExp(r'R(\d+)').firstMatch(label);
    if (match == null) return 999999;
    return int.tryParse(match.group(1) ?? '') ?? 999999;
  }

  static List<List<String>> _toGrid({
    required List<String> labels,
    required int rows,
    required int cols,
  }) {
    final grid = <List<String>>[];
    int index = 0;

    for (int r = 0; r < rows; r++) {
      final row = <String>[];
      for (int c = 0; c < cols; c++) {
        row.add(index < labels.length ? labels[index] : '');
        index++;
      }
      grid.add(row);
    }

    return grid;
  }

  static void swapWells({
    required List<List<String>> layout,
    required int fromRow,
    required int fromCol,
    required int toRow,
    required int toCol,
  }) {
    final temp = layout[fromRow][fromCol];
    layout[fromRow][fromCol] = layout[toRow][toCol];
    layout[toRow][toCol] = temp;
  }

  static Color getWellColor(String value) {
    if (value.isEmpty) return Colors.grey.shade100;
    if (value.startsWith('BLK')) return Colors.grey.shade300;
    if (value.startsWith('NC')) return Colors.red.shade100;
    if (value.startsWith('VEH')) return Colors.yellow.shade100;
    if (value.startsWith('PC')) return Colors.green.shade100;
    return Colors.blue.shade50;
  }
}