import 'package:flutter/material.dart';

class ElisaLayoutService {
  static int getPlateRows(String plateType) {
    switch (plateType) {
      case '96-well plate':
        return 8;
      default:
        return 0;
    }
  }

  static int getPlateCols(String plateType) {
    switch (plateType) {
      case '96-well plate':
        return 12;
      default:
        return 0;
    }
  }

  static List<List<String>> generatePlateLayout({
    required String plateType,
    required int sampleCount,
    required int sampleReplicateCount,
    required int blankCount,
    required int negativeControlCount,
    required int positiveControlCount,
    required int standardCount,
    required int standardReplicateCount,
  }) {
    final rows = getPlateRows(plateType);
    final cols = getPlateCols(plateType);

    if (rows == 0 || cols == 0) return [];

    final totalSlots = rows * cols;
    final grid = List.generate(rows, (_) => List.generate(cols, (_) => ''));

    final sampleLabels = <String>[];
    final controlLabels = <String>[];

    for (int s = 1; s <= sampleCount; s++) {
      for (int r = 1; r <= sampleReplicateCount; r++) {
        sampleLabels.add('S$s-R$r');
      }
    }

    for (int i = 1; i <= blankCount; i++) {
      controlLabels.add('BLK$i');
    }
    for (int i = 1; i <= negativeControlCount; i++) {
      controlLabels.add('NC$i');
    }
    for (int i = 1; i <= positiveControlCount; i++) {
      controlLabels.add('PC$i');
    }
    for (int s = 1; s <= standardCount; s++) {
      for (int r = 1; r <= standardReplicateCount; r++) {
        controlLabels.add('STD$s-R$r');
      }
    }

    if (sampleLabels.length + controlLabels.length > totalSlots) {
      final all = [...sampleLabels, ...controlLabels];
      for (int i = 0; i < all.length && i < totalSlots; i++) {
        grid[i ~/ cols][i % cols] = all[i];
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
    if (value.startsWith('PC')) return Colors.green.shade100;
    if (value.startsWith('STD')) return Colors.orange.shade100;
    if (value.startsWith('S')) return Colors.blue.shade50;
    return Colors.white;
  }
}