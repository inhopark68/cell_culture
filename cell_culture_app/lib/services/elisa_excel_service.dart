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

    void setText(Sheet sheet, String cell, String value) {
      sheet.cell(CellIndex.indexByString(cell)).value = TextCellValue(value);
    }

    void setInt(Sheet sheet, String cell, int value) {
      sheet.cell(CellIndex.indexByString(cell)).value = IntCellValue(value);
    }

    void setDouble(Sheet sheet, String cell, double value) {
      sheet.cell(CellIndex.indexByString(cell)).value = DoubleCellValue(value);
    }

    setText(calcSheet, 'A1', 'ELISA Template');

    setText(calcSheet, 'A3', 'Experiment ID');
    setText(calcSheet, 'B3', experimentId);
    setText(calcSheet, 'A4', 'Assay Name');
    setText(calcSheet, 'B4', assayName);
    setText(calcSheet, 'A5', 'Target Analyte');
    setText(calcSheet, 'B5', targetAnalyte);
    setText(calcSheet, 'A6', 'Operator');
    setText(calcSheet, 'B6', operatorName);
    setText(calcSheet, 'A7', 'Plate Type');
    setText(calcSheet, 'B7', plateType);

    setText(calcSheet, 'A9', 'Sample count');
    setInt(calcSheet, 'B9', sampleCount);
    setText(calcSheet, 'A10', 'Sample replicates');
    setInt(calcSheet, 'B10', sampleReplicateCount);
    setText(calcSheet, 'A11', 'Blank count');
    setInt(calcSheet, 'B11', blankCount);
    setText(calcSheet, 'A12', 'Negative control count');
    setInt(calcSheet, 'B12', negativeControlCount);
    setText(calcSheet, 'A13', 'Positive control count');
    setInt(calcSheet, 'B13', positiveControlCount);
    setText(calcSheet, 'A14', 'Standard count');
    setInt(calcSheet, 'B14', standardCount);
    setText(calcSheet, 'A15', 'Standard replicates');
    setInt(calcSheet, 'B15', standardReplicateCount);

    setText(calcSheet, 'A17', 'Volume / well (uL)');
    setDouble(calcSheet, 'B17', volumePerWell);
    setText(calcSheet, 'A18', 'Extra (%)');
    setDouble(calcSheet, 'B18', extraPercent * 100);

    setText(calcSheet, 'A20', 'Total sample wells');
    setInt(calcSheet, 'B20', totalSampleWells);
    setText(calcSheet, 'A21', 'Total control wells');
    setInt(calcSheet, 'B21', totalControlWells);
    setText(calcSheet, 'A22', 'Total wells');
    setInt(calcSheet, 'B22', totalWells);
    setText(calcSheet, 'A23', 'Total assay volume needed (uL)');
    setDouble(calcSheet, 'B23', totalVolumeNeeded);

    setText(inputSheet, 'A1', 'ELISA Input Summary');
    setText(inputSheet, 'A3', 'Experiment ID');
    setText(inputSheet, 'B3', experimentId);
    setText(inputSheet, 'A4', 'Assay Name');
    setText(inputSheet, 'B4', assayName);
    setText(inputSheet, 'A5', 'Target Analyte');
    setText(inputSheet, 'B5', targetAnalyte);
    setText(inputSheet, 'A6', 'Operator');
    setText(inputSheet, 'B6', operatorName);
    setText(inputSheet, 'A7', 'Plate Type');
    setText(inputSheet, 'B7', plateType);

    if (layout.isNotEmpty && layout.first.isNotEmpty) {
      setText(layoutSheet, 'A1', 'ELISA Plate Layout');

      final rowCount = layout.length;
      final colCount = layout.first.length;

      for (int c = 0; c < colCount; c++) {
        layoutSheet
            .cell(CellIndex.indexByColumnRow(columnIndex: c + 1, rowIndex: 1))
            .value = IntCellValue(c + 1);
      }

      for (int r = 0; r < rowCount; r++) {
        layoutSheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: r + 2))
            .value = TextCellValue(String.fromCharCode(65 + r));

        for (int c = 0; c < colCount; c++) {
          final value = layout[r][c].isEmpty ? '-' : layout[r][c];
          layoutSheet
              .cell(CellIndex.indexByColumnRow(
                columnIndex: c + 1,
                rowIndex: r + 2,
              ))
              .value = TextCellValue(value);
        }
      }
    } else {
      setText(layoutSheet, 'A1', 'No ELISA layout available');
    }

    final bytes = excel.encode();
    if (bytes == null) return null;

    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/elisa_template.xlsx');
    await file.writeAsBytes(bytes, flush: true);

    return file.path;
  }
}