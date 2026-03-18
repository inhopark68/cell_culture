import 'dart:io';

import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';

class ElisaExcelService {
  static Future<String?> export({
    required String experimentId,
    required String assayName,
    required String targetAnalyte,
    required String operatorName,
    required String plateType,
    required int sampleCount,
    required int sampleReplicateCount,
    required int blankCount,
    required int negativeControlCount,
    required int positiveControlCount,
    required int standardCount,
    required int standardReplicateCount,
    required double volumePerWell,
    required double extraPercent,
    required int totalSampleWells,
    required int totalControlWells,
    required int totalWells,
    required double totalVolumeNeeded,
    required List<List<String>> layout,
    required double dilutionFactor,
    required double targetDilutionVolume,
    required double stockVolumeForDilution,
    required double diluentVolumeForDilution,
    required double standardTopConcentration,
    required double standardDilutionFactor,
    required List<double> standardCurveConcentrations,
  }) async {
    final excel = Excel.createExcel();

    final defaultSheet = excel.getDefaultSheet();
    if (defaultSheet != null && defaultSheet != 'ELISA_Calculation') {
      excel.delete(defaultSheet);
    }

    final calcSheet = excel['ELISA_Calculation'];
    final inputSheet = excel['ELISA_Input'];
    final layoutSheet = excel['ELISA_Layout'];
    final standardSheet = excel['ELISA_StandardCurve'];

    void setText(Sheet sheet, String cell, String value) {
      sheet.cell(CellIndex.indexByString(cell)).value = TextCellValue(value);
    }

    void setInt(Sheet sheet, String cell, int value) {
      sheet.cell(CellIndex.indexByString(cell)).value = IntCellValue(value);
    }

    void setDouble(Sheet sheet, String cell, double value) {
      sheet.cell(CellIndex.indexByString(cell)).value = DoubleCellValue(value);
    }

    void setDynamic(Sheet sheet, String cell, dynamic value) {
      final target = sheet.cell(CellIndex.indexByString(cell));

      if (value is int) {
        target.value = IntCellValue(value);
      } else if (value is double) {
        target.value = DoubleCellValue(value);
      } else {
        target.value = TextCellValue(value.toString());
      }
    }

    void setRow(Sheet sheet, int row, String label, dynamic value) {
      setText(sheet, 'A$row', label);
      setDynamic(sheet, 'B$row', value);
    }

    void setSectionTitle(Sheet sheet, int row, String title) {
      setText(sheet, 'A$row', title);
    }

    String sanitizeFileName(String value) {
      final sanitized = value.trim().replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
      return sanitized.isEmpty ? 'elisa_template' : sanitized;
    }

    String formatConcentrationList(List<double> values) {
      if (values.isEmpty) return '-';
      return values.map((e) => e.toString()).join(', ');
    }

    void setColumnWidths(Sheet sheet, Map<int, double> widths) {
      for (final entry in widths.entries) {
        sheet.setColumnWidth(entry.key, entry.value);
      }
    }

    final extraPercentDisplay = extraPercent * 100;

    // -------------------------------------------------------------------------
    // ELISA_Calculation
    // -------------------------------------------------------------------------
    setText(calcSheet, 'A1', 'ELISA Template');

    setSectionTitle(calcSheet, 3, 'Basic Information');
    setRow(calcSheet, 4, 'Experiment ID', experimentId);
    setRow(calcSheet, 5, 'Assay Name', assayName);
    setRow(calcSheet, 6, 'Target Analyte', targetAnalyte);
    setRow(calcSheet, 7, 'Operator', operatorName);
    setRow(calcSheet, 8, 'Plate Type', plateType);

    setSectionTitle(calcSheet, 10, 'Experiment Counts');
    setRow(calcSheet, 11, 'Sample count', sampleCount);
    setRow(calcSheet, 12, 'Sample replicates', sampleReplicateCount);
    setRow(calcSheet, 13, 'Blank count', blankCount);
    setRow(calcSheet, 14, 'Negative control count', negativeControlCount);
    setRow(calcSheet, 15, 'Positive control count', positiveControlCount);
    setRow(calcSheet, 16, 'Standard count', standardCount);
    setRow(calcSheet, 17, 'Standard replicates', standardReplicateCount);
    setRow(calcSheet, 18, 'Total sample wells', totalSampleWells);
    setRow(calcSheet, 19, 'Total control wells', totalControlWells);
    setRow(calcSheet, 20, 'Total wells', totalWells);

    setSectionTitle(calcSheet, 22, 'Volume Summary');
    setRow(calcSheet, 23, 'Volume / well (uL)', volumePerWell);
    setRow(calcSheet, 24, 'Extra (%)', extraPercentDisplay);
    setRow(calcSheet, 25, 'Total assay volume needed (uL)', totalVolumeNeeded);

    setSectionTitle(calcSheet, 27, 'Sample Dilution');
    setRow(calcSheet, 28, 'Dilution factor', dilutionFactor);
    setRow(calcSheet, 29, 'Target dilution volume (uL)', targetDilutionVolume);
    setRow(calcSheet, 30, 'Stock volume for dilution (uL)', stockVolumeForDilution);
    setRow(calcSheet, 31, 'Diluent volume for dilution (uL)', diluentVolumeForDilution);

    setSectionTitle(calcSheet, 33, 'Standard Curve');
    setRow(calcSheet, 34, 'Standard top concentration', standardTopConcentration);
    setRow(calcSheet, 35, 'Standard dilution factor', standardDilutionFactor);
    setRow(
      calcSheet,
      36,
      'Standard curve concentrations',
      formatConcentrationList(standardCurveConcentrations),
    );

    setColumnWidths(calcSheet, {
      0: 32,
      1: 22,
    });

    // -------------------------------------------------------------------------
    // ELISA_Input
    // -------------------------------------------------------------------------
    setText(inputSheet, 'A1', 'ELISA Input Summary');

    setSectionTitle(inputSheet, 3, 'Basic Information');
    setRow(inputSheet, 4, 'Experiment ID', experimentId);
    setRow(inputSheet, 5, 'Assay Name', assayName);
    setRow(inputSheet, 6, 'Target Analyte', targetAnalyte);
    setRow(inputSheet, 7, 'Operator', operatorName);
    setRow(inputSheet, 8, 'Plate Type', plateType);

    setSectionTitle(inputSheet, 10, 'Experiment Inputs');
    setRow(inputSheet, 11, 'Sample count', sampleCount);
    setRow(inputSheet, 12, 'Sample replicates', sampleReplicateCount);
    setRow(inputSheet, 13, 'Blank count', blankCount);
    setRow(inputSheet, 14, 'Negative control count', negativeControlCount);
    setRow(inputSheet, 15, 'Positive control count', positiveControlCount);
    setRow(inputSheet, 16, 'Standard count', standardCount);
    setRow(inputSheet, 17, 'Standard replicates', standardReplicateCount);
    setRow(inputSheet, 18, 'Volume / well (uL)', volumePerWell);
    setRow(inputSheet, 19, 'Extra (%)', extraPercentDisplay);

    setSectionTitle(inputSheet, 21, 'Dilution Inputs');
    setRow(inputSheet, 22, 'Dilution factor', dilutionFactor);
    setRow(inputSheet, 23, 'Target dilution volume (uL)', targetDilutionVolume);
    setRow(inputSheet, 24, 'Stock volume for dilution (uL)', stockVolumeForDilution);
    setRow(inputSheet, 25, 'Diluent volume for dilution (uL)', diluentVolumeForDilution);

    setSectionTitle(inputSheet, 27, 'Standard Inputs');
    setRow(inputSheet, 28, 'Standard top concentration', standardTopConcentration);
    setRow(inputSheet, 29, 'Standard dilution factor', standardDilutionFactor);
    setRow(
      inputSheet,
      30,
      'Standard curve concentrations',
      formatConcentrationList(standardCurveConcentrations),
    );

    setColumnWidths(inputSheet, {
      0: 32,
      1: 22,
    });

    // -------------------------------------------------------------------------
    // ELISA_Layout
    // -------------------------------------------------------------------------
    setText(layoutSheet, 'A1', 'ELISA Plate Layout');

    setText(layoutSheet, 'A3', 'Plate Type');
    setText(layoutSheet, 'B3', plateType);

    setText(layoutSheet, 'A4', 'Total wells');
    setInt(layoutSheet, 'B4', totalWells);

    setText(layoutSheet, 'A5', 'Standard concentrations');
    setText(
      layoutSheet,
      'B5',
      formatConcentrationList(standardCurveConcentrations),
    );

    if (layout.isNotEmpty && layout.first.isNotEmpty) {
      final rowCount = layout.length;
      final colCount = layout.first.length;

      const headerRow = 8;
      const startRow = 9;

      for (int c = 0; c < colCount; c++) {
        layoutSheet
            .cell(
              CellIndex.indexByColumnRow(
                columnIndex: c + 1,
                rowIndex: headerRow - 1,
              ),
            )
            .value = IntCellValue(c + 1);
      }

      for (int r = 0; r < rowCount; r++) {
        layoutSheet
            .cell(
              CellIndex.indexByColumnRow(
                columnIndex: 0,
                rowIndex: startRow + r - 1,
              ),
            )
            .value = TextCellValue(String.fromCharCode(65 + r));

        for (int c = 0; c < colCount; c++) {
          final value = layout[r][c].isEmpty ? '-' : layout[r][c];
          layoutSheet
              .cell(
                CellIndex.indexByColumnRow(
                  columnIndex: c + 1,
                  rowIndex: startRow + r - 1,
                ),
              )
              .value = TextCellValue(value);
        }
      }

      layoutSheet.setColumnWidth(0, 8);
      for (int c = 1; c <= colCount; c++) {
        layoutSheet.setColumnWidth(c, 14);
      }
    } else {
      setText(layoutSheet, 'A8', 'No ELISA layout available');
    }

    // -------------------------------------------------------------------------
    // ELISA_StandardCurve
    // -------------------------------------------------------------------------
    setText(standardSheet, 'A1', 'ELISA Standard Curve');
    setText(standardSheet, 'A3', 'Experiment ID');
    setText(standardSheet, 'B3', experimentId);
    setText(standardSheet, 'A4', 'Assay Name');
    setText(standardSheet, 'B4', assayName);
    setText(standardSheet, 'A5', 'Target Analyte');
    setText(standardSheet, 'B5', targetAnalyte);
    setText(standardSheet, 'A6', 'Standard top concentration');
    setDouble(standardSheet, 'B6', standardTopConcentration);
    setText(standardSheet, 'A7', 'Standard dilution factor');
    setDouble(standardSheet, 'B7', standardDilutionFactor);

    setText(standardSheet, 'A9', 'Level');
    setText(standardSheet, 'B9', 'Concentration');

    if (standardCurveConcentrations.isEmpty) {
      setText(standardSheet, 'A10', 'No standard curve concentrations');
    } else {
      for (int i = 0; i < standardCurveConcentrations.length; i++) {
        final row = i + 10;
        setInt(standardSheet, 'A$row', i + 1);
        setDouble(standardSheet, 'B$row', standardCurveConcentrations[i]);
      }
    }

    setColumnWidths(standardSheet, {
      0: 14,
      1: 20,
    });

    final bytes = excel.encode();
    if (bytes == null) return null;

    final dir = await getApplicationDocumentsDirectory();
    final safeName = sanitizeFileName(experimentId);
    final file = File('${dir.path}/${safeName}_elisa_template.xlsx');
    await file.writeAsBytes(bytes, flush: true);

    return file.path;
  }
}