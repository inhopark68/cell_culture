import 'package:flutter/material.dart';

class CellCultureLayoutService {
  static int getPlateRows(String ware) {
    switch (ware) {
      case '6-well plate':
        return 2;
      case '12-well plate':
        return 3;
      case '24-well plate':
        return 4;
      case '48-well plate':
        return 6;
      case '96-well plate':
        return 8;
      default:
        return 0;
    }
  }

  static int getPlateCols(String ware) {
    switch (ware) {
      case '6-well plate':
        return 3;
      case '12-well plate':
        return 4;
      case '24-well plate':
        return 6;
      case '48-well plate':
        return 8;
      case '96-well plate':
        return 12;
      default:
        return 0;
    }
  }

  static List<List<String>> generatePlateLayout({
    required String ware,
    required int sampleCount,
    required int replicates,
    required int blankCount,
    required int vehicleCount,
    required int positiveControlCount,
    required int negativeControlCount,
  }) {
    final rows = getPlateRows(ware);
    final cols = getPlateCols(ware);

    if (rows == 0 || cols == 0) return [];

    final totalSlots = rows * cols;
    final grid = List.generate(rows, (_) => List.generate(cols, (_) => ''));

    final sampleLabels = <String>[];
    final controlLabels = <String>[];

    for (int s = 1; s <= sampleCount; s++) {
      for (int r = 1; r <= replicates; r++) {
        sampleLabels.add('S$s-R$r');
      }
    }

    for (int i = 1; i <= blankCount; i++) {
      controlLabels.add('BLK$i');
    }
    for (int i = 1; i <= negativeControlCount; i++) {
      controlLabels.add('NC$i');
    }
    for (int i = 1; i <= vehicleCount; i++) {
      controlLabels.add('VEH$i');
    }
    for (int i = 1; i <= positiveControlCount; i++) {
      controlLabels.add('PC$i');
    }

    if (sampleLabels.length + controlLabels.length > totalSlots) {
      final allLabels = [...sampleLabels, ...controlLabels];
      for (int i = 0; i < allLabels.length && i < totalSlots; i++) {
        final row = i ~/ cols;
        final col = i % cols;
        grid[row][col] = allLabels[i];
      }
      return grid;
    }

    int controlIndex = 0;
    for (int c = cols - 1; c >= 0; c--) {
      for (int r = 0; r < rows; r++) {
        if (controlIndex >= controlLabels.length) break;
        grid[r][c] = controlLabels[controlIndex];
        controlIndex++;
      }
      if (controlIndex >= controlLabels.length) break;
    }

    int sampleIndex = 0;
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        if (grid[r][c].isNotEmpty) continue;
        if (sampleIndex >= sampleLabels.length) break;
        grid[r][c] = sampleLabels[sampleIndex];
        sampleIndex++;
      }
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
    if (value.startsWith('S')) return Colors.blue.shade50;
    return Colors.white;
  }
}