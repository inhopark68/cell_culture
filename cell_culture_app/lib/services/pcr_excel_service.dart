import 'dart:io';

import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';

class PcrExcelService {
  static Future<String?> export({
    required String plateType,
    required int sampleCount,
    required int replicateCount,
    required int ntcCount,
    required int positiveControlCount,
    required int standardCount,
    required double extraPercent,
    required double reactionVolume,
    required double masterMix2x,
    required double forwardPrimer,
    required double reversePrimer,
    required double templateVolume,
    required double waterPerReaction,
    required double masterMixPerReaction,
    required int totalWells,
    required int mixReactionCount,
    required double totalMasterMix2x,
    required double totalForwardPrimer,
    required double totalReversePrimer,
    required double totalWater,
    required double totalTemplate,
    required List<List<String>> layout,
    required String experimentId,
    required String targetGene,
    required String primerName,
    required String operator,
    required String instrument,
  }) async {
    final excel = Excel.createExcel();

    final defaultSheet = excel.getDefaultSheet();
    if (defaultSheet != null && defaultSheet != 'PCR_Calculation') {
      excel.delete(defaultSheet);
    }

    final calcSheet = excel['PCR_Calculation'];
    final inputSheet = excel['PCR_Input'];
    final layoutSheet = excel['PCR_Layout'];

    void setText(Sheet sheet, String cell, String value) {
      sheet.cell(CellIndex.indexByString(cell)).value = TextCellValue(value);
    }

    void setInt(Sheet sheet, String cell, int value) {
      sheet.cell(CellIndex.indexByString(cell)).value = IntCellValue(value);
    }

    void setDouble(Sheet sheet, String cell, double value) {
      sheet.cell(CellIndex.indexByString(cell)).value = DoubleCellValue(value);
    }

    // PCR_Calculation sheet
    setText(calcSheet, 'A1', 'PCR Triplicate Calculator');

    setText(calcSheet, 'A3', 'Experiment ID');
    setText(calcSheet, 'B3', experimentId);

    setText(calcSheet, 'A4', 'Target Gene');
    setText(calcSheet, 'B4', targetGene);

    setText(calcSheet, 'A5', 'Primer Name');
    setText(calcSheet, 'B5', primerName);

    setText(calcSheet, 'A6', 'Operator');
    setText(calcSheet, 'B6', operator);

    setText(calcSheet, 'A7', 'Instrument');
    setText(calcSheet, 'B7', instrument);

    setText(calcSheet, 'A8', 'Date');
    setText(calcSheet, 'B8', DateTime.now().toString());

    setText(calcSheet, 'A10', 'Plate type');
    setText(calcSheet, 'B10', plateType);

    setText(calcSheet, 'A11', 'Sample count');
    setInt(calcSheet, 'B11', sampleCount);

    setText(calcSheet, 'A12', 'Replicates');
    setInt(calcSheet, 'B12', replicateCount);

    setText(calcSheet, 'A13', 'NTC count');
    setInt(calcSheet, 'B13', ntcCount);

    setText(calcSheet, 'A14', 'Positive control count');
    setInt(calcSheet, 'B14', positiveControlCount);

    setText(calcSheet, 'A15', 'Standard count');
    setInt(calcSheet, 'B15', standardCount);

    setText(calcSheet, 'A16', 'Extra (%)');
    setDouble(calcSheet, 'B16', extraPercent * 100);

    setText(calcSheet, 'A18', 'Total wells');
    setInt(calcSheet, 'B18', totalWells);

    setText(calcSheet, 'A19', 'Mix reaction count');
    setInt(calcSheet, 'B19', mixReactionCount);

    setText(calcSheet, 'A21', 'Reaction volume (uL)');
    setDouble(calcSheet, 'B21', reactionVolume);

    setText(calcSheet, 'A22', '2X Master Mix / rxn');
    setDouble(calcSheet, 'B22', masterMix2x);

    setText(calcSheet, 'A23', 'Forward Primer / rxn');
    setDouble(calcSheet, 'B23', forwardPrimer);

    setText(calcSheet, 'A24', 'Reverse Primer / rxn');
    setDouble(calcSheet, 'B24', reversePrimer);

    setText(calcSheet, 'A25', 'Template / rxn');
    setDouble(calcSheet, 'B25', templateVolume);

    setText(calcSheet, 'A26', 'Water / rxn');
    setDouble(calcSheet, 'B26', waterPerReaction);

    setText(calcSheet, 'A27', 'Master mix / well');
    setDouble(calcSheet, 'B27', masterMixPerReaction);

    setText(calcSheet, 'A29', '2X Master Mix total');
    setDouble(calcSheet, 'B29', totalMasterMix2x);

    setText(calcSheet, 'A30', 'Forward Primer total');
    setDouble(calcSheet, 'B30', totalForwardPrimer);

    setText(calcSheet, 'A31', 'Reverse Primer total');
    setDouble(calcSheet, 'B31', totalReversePrimer);

    setText(calcSheet, 'A32', 'Water total');
    setDouble(calcSheet, 'B32', totalWater);

    setText(calcSheet, 'A33', 'Template total');
    setDouble(calcSheet, 'B33', totalTemplate);

    // PCR_Input sheet
    setText(inputSheet, 'A1', 'PCR Input Summary');

    setText(inputSheet, 'A3', 'Plate type');
    setText(inputSheet, 'B3', plateType);

    setText(inputSheet, 'A4', 'Sample count');
    setInt(inputSheet, 'B4', sampleCount);

    setText(inputSheet, 'A5', 'Replicates');
    setInt(inputSheet, 'B5', replicateCount);

    setText(inputSheet, 'A6', 'NTC count');
    setInt(inputSheet, 'B6', ntcCount);

    setText(inputSheet, 'A7', 'Positive control count');
    setInt(inputSheet, 'B7', positiveControlCount);

    setText(inputSheet, 'A8', 'Standard count');
    setInt(inputSheet, 'B8', standardCount);

    setText(inputSheet, 'A9', 'Extra (%)');
    setDouble(inputSheet, 'B9', extraPercent * 100);

    // PCR_Layout sheet
    if (layout.isNotEmpty && layout.first.isNotEmpty) {
      setText(layoutSheet, 'A1', 'PCR Plate Layout');

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
              .cell(
                CellIndex.indexByColumnRow(
                  columnIndex: c + 1,
                  rowIndex: r + 2,
                ),
              )
              .value = TextCellValue(value);
        }
      }
    } else {
      setText(layoutSheet, 'A1', 'No PCR layout available');
    }

    final bytes = excel.encode();
    if (bytes == null) return null;

    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/pcr_template.xlsx');
    await file.writeAsBytes(bytes, flush: true);

    return file.path;
  }
}