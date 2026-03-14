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
    setText(calcSheet, 'A1', 'PCR Experiment');

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

    setText(calcSheet, 'A1', 'PCR Triplicate Calculator');

    setText(calcSheet, 'A3', 'Plate type');
    setText(calcSheet, 'B3', plateType);

    setText(calcSheet, 'A4', 'Sample count');
    setInt(calcSheet, 'B4', sampleCount);

    setText(calcSheet, 'A5', 'Replicates');
    setInt(calcSheet, 'B5', replicateCount);

    setText(calcSheet, 'A6', 'NTC count');
    setInt(calcSheet, 'B6', ntcCount);

    setText(calcSheet, 'A7', 'Positive control count');
    setInt(calcSheet, 'B7', positiveControlCount);

    setText(calcSheet, 'A8', 'Standard count');
    setInt(calcSheet, 'B8', standardCount);

    setText(calcSheet, 'A9', 'Extra (%)');
    setDouble(calcSheet, 'B9', extraPercent * 100);

    setText(calcSheet, 'A11', 'Total wells');
    setInt(calcSheet, 'B11', totalWells);

    setText(calcSheet, 'A12', 'Mix reaction count');
    setInt(calcSheet, 'B12', mixReactionCount);

    setText(calcSheet, 'A14', 'Reaction volume (uL)');
    setDouble(calcSheet, 'B14', reactionVolume);

    setText(calcSheet, 'A15', '2X Master Mix / rxn');
    setDouble(calcSheet, 'B15', masterMix2x);

    setText(calcSheet, 'A16', 'Forward Primer / rxn');
    setDouble(calcSheet, 'B16', forwardPrimer);

    setText(calcSheet, 'A17', 'Reverse Primer / rxn');
    setDouble(calcSheet, 'B17', reversePrimer);

    setText(calcSheet, 'A18', 'Template / rxn');
    setDouble(calcSheet, 'B18', templateVolume);

    setText(calcSheet, 'A19', 'Water / rxn');
    setDouble(calcSheet, 'B19', waterPerReaction);

    setText(calcSheet, 'A20', 'Master mix / well');
    setDouble(calcSheet, 'B20', masterMixPerReaction);

    setText(calcSheet, 'A22', '2X Master Mix total');
    setDouble(calcSheet, 'B22', totalMasterMix2x);

    setText(calcSheet, 'A23', 'Forward Primer total');
    setDouble(calcSheet, 'B23', totalForwardPrimer);

    setText(calcSheet, 'A24', 'Reverse Primer total');
    setDouble(calcSheet, 'B24', totalReversePrimer);

    setText(calcSheet, 'A25', 'Water total');
    setDouble(calcSheet, 'B25', totalWater);

    setText(calcSheet, 'A26', 'Template total');
    setDouble(calcSheet, 'B26', totalTemplate);

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
              .cell(CellIndex.indexByColumnRow(
                columnIndex: c + 1,
                rowIndex: r + 2,
              ))
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