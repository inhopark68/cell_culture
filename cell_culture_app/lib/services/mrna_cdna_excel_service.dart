import 'dart:io';

import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class MrnaCdnaExcelService {
  static Future<String?> export({
    required int sampleCount,
    required int cdnaReplicateCount,
    required double extraPercent,
    required double inputRnaNg,
    required double reactionVolume,
    required double fixedMixVolume,
    required double defaultElutionVolume,
    required String experimentId,
    required String operator,
    required String kitName,
    required String notes,
    required List<Map<String, dynamic>> samples,
  }) async {
    final excel = Excel.createExcel();

    final Sheet summarySheet = excel['Summary'];
    final Sheet sampleSheet = excel['Samples'];
    final Sheet formulaSheet = excel['Formula'];

    // remove default if exists and not one of ours
    if (excel.sheets.containsKey('Sheet1')) {
      excel.delete('Sheet1');
    }

    final adjustedReactionCount =
        cdnaReplicateCount * (1 + extraPercent);
    final totalRequiredRnaNgPerSample =
        inputRnaNg * adjustedReactionCount;

    // -----------------------------
    // Summary sheet
    // -----------------------------
    _setCell(summarySheet, 0, 0, 'mRNA → cDNA Template');
    _setCell(summarySheet, 2, 0, 'Experiment ID');
    _setCell(summarySheet, 2, 1, experimentId);

    _setCell(summarySheet, 3, 0, 'Operator');
    _setCell(summarySheet, 3, 1, operator);

    _setCell(summarySheet, 4, 0, 'Kit name');
    _setCell(summarySheet, 4, 1, kitName);

    _setCell(summarySheet, 5, 0, 'Notes');
    _setCell(summarySheet, 5, 1, notes);

    _setCell(summarySheet, 7, 0, 'Sample count');
    _setCell(summarySheet, 7, 1, sampleCount);

    _setCell(summarySheet, 8, 0, 'cDNA reactions / sample');
    _setCell(summarySheet, 8, 1, cdnaReplicateCount);

    _setCell(summarySheet, 9, 0, 'Extra (%)');
    _setCell(summarySheet, 9, 1, extraPercent * 100);

    _setCell(summarySheet, 10, 0, 'Adjusted reaction count');
    _setCell(summarySheet, 10, 1, adjustedReactionCount);

    _setCell(summarySheet, 11, 0, 'Target RNA input / reaction (ng)');
    _setCell(summarySheet, 11, 1, inputRnaNg);

    _setCell(summarySheet, 12, 0, 'Required RNA / sample (ng)');
    _setCell(summarySheet, 12, 1, totalRequiredRnaNgPerSample);

    _setCell(summarySheet, 13, 0, 'Reaction volume (µL)');
    _setCell(summarySheet, 13, 1, reactionVolume);

    _setCell(summarySheet, 14, 0, 'Fixed mix volume (µL)');
    _setCell(summarySheet, 14, 1, fixedMixVolume);

    _setCell(summarySheet, 15, 0, 'Default elution volume (µL)');
    _setCell(summarySheet, 15, 1, defaultElutionVolume);

    _setCell(summarySheet, 17, 0, 'Generated at');
    _setCell(summarySheet, 17, 1, DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now()));

    // -----------------------------
    // Samples sheet
    // -----------------------------
    final headers = [
      'No',
      'Sample name',
      'mRNA concentration (ng/µL)',
      'Elution volume (µL)',
      'Total yield (ng)',
      'Required RNA / sample (ng)',
      'RNA volume / reaction (µL)',
      'Total RNA volume needed (µL)',
      'Water / reaction (µL)',
      'Remaining RNA (ng)',
      'Enough yield',
      'Volume valid',
      'Status',
    ];

    for (int i = 0; i < headers.length; i++) {
      _setCell(sampleSheet, 0, i, headers[i]);
    }

    int readyCount = 0;
    int lowYieldCount = 0;
    int invalidVolumeCount = 0;
    int noConcentrationCount = 0;

    for (int i = 0; i < samples.length; i++) {
      final row = samples[i];

      final String sampleName =
          (row['sampleName'] ?? 'Sample ${i + 1}').toString();

      final double concentrationNgPerUl =
          _toDouble(row['concentrationNgPerUl']);
      final double elutionVolumeUl =
          _toDouble(row['elutionVolumeUl']);

      final double totalYieldNg =
          concentrationNgPerUl * elutionVolumeUl;

      final double rnaVolumePerReactionUl = concentrationNgPerUl <= 0
          ? 0
          : inputRnaNg / concentrationNgPerUl;

      final double totalRnaVolumeNeededUl = concentrationNgPerUl <= 0
          ? 0
          : totalRequiredRnaNgPerSample / concentrationNgPerUl;

      final double waterPerReactionUl =
          reactionVolume - fixedMixVolume - rnaVolumePerReactionUl;

      final double remainingRnaNg =
          totalYieldNg - totalRequiredRnaNgPerSample;

      final bool enoughYield =
          totalYieldNg >= totalRequiredRnaNgPerSample;
      final bool volumeValid = waterPerReactionUl >= 0;

      String status;
      if (concentrationNgPerUl <= 0) {
        status = 'No concentration';
        noConcentrationCount++;
      } else if (!enoughYield) {
        status = 'Low yield';
        lowYieldCount++;
      } else if (!volumeValid) {
        status = 'RNA volume too high';
        invalidVolumeCount++;
      } else {
        status = 'Ready';
        readyCount++;
      }

      final int r = i + 1;

      _setCell(sampleSheet, r, 0, i + 1);
      _setCell(sampleSheet, r, 1, sampleName);
      _setCell(sampleSheet, r, 2, concentrationNgPerUl);
      _setCell(sampleSheet, r, 3, elutionVolumeUl);
      _setCell(sampleSheet, r, 4, totalYieldNg);
      _setCell(sampleSheet, r, 5, totalRequiredRnaNgPerSample);
      _setCell(sampleSheet, r, 6, rnaVolumePerReactionUl);
      _setCell(sampleSheet, r, 7, totalRnaVolumeNeededUl);
      _setCell(sampleSheet, r, 8, waterPerReactionUl);
      _setCell(sampleSheet, r, 9, remainingRnaNg);
      _setCell(sampleSheet, r, 10, enoughYield ? 'Yes' : 'No');
      _setCell(sampleSheet, r, 11, volumeValid ? 'Yes' : 'No');
      _setCell(sampleSheet, r, 12, status);
    }

    _setCell(summarySheet, 19, 0, 'Ready samples');
    _setCell(summarySheet, 19, 1, readyCount);

    _setCell(summarySheet, 20, 0, 'Low yield samples');
    _setCell(summarySheet, 20, 1, lowYieldCount);

    _setCell(summarySheet, 21, 0, 'Invalid volume samples');
    _setCell(summarySheet, 21, 1, invalidVolumeCount);

    _setCell(summarySheet, 22, 0, 'No concentration samples');
    _setCell(summarySheet, 22, 1, noConcentrationCount);

    // -----------------------------
    // Formula sheet
    // -----------------------------
    _setCell(formulaSheet, 0, 0, 'Formula');
    _setCell(formulaSheet, 0, 1, 'Description');

    _setCell(formulaSheet, 1, 0, '1');
    _setCell(
      formulaSheet,
      1,
      1,
      'Total yield (ng) = Concentration (ng/µL) × Elution volume (µL)',
    );

    _setCell(formulaSheet, 2, 0, '2');
    _setCell(
      formulaSheet,
      2,
      1,
      'Adjusted reaction count = Replicates × (1 + extra %)',
    );

    _setCell(formulaSheet, 3, 0, '3');
    _setCell(
      formulaSheet,
      3,
      1,
      'Required RNA / sample (ng) = RNA input / reaction × adjusted reaction count',
    );

    _setCell(formulaSheet, 4, 0, '4');
    _setCell(
      formulaSheet,
      4,
      1,
      'RNA volume / reaction (µL) = RNA input (ng) ÷ Concentration (ng/µL)',
    );

    _setCell(formulaSheet, 5, 0, '5');
    _setCell(
      formulaSheet,
      5,
      1,
      'Water / reaction (µL) = Reaction volume - Fixed mix volume - RNA volume',
    );

    _setCell(formulaSheet, 6, 0, '6');
    _setCell(
      formulaSheet,
      6,
      1,
      'Remaining RNA (ng) = Total yield - Required RNA / sample',
    );

    // -----------------------------
    // Save file
    // -----------------------------
    final dir = await _getSaveDirectory();
    if (dir == null) return null;

    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final safeExperimentId =
        experimentId.trim().isEmpty ? 'mRNA_cDNA' : _sanitizeFileName(experimentId.trim());

    final filePath = p.join(
      dir.path,
      '${safeExperimentId}_template_$timestamp.xlsx',
    );

    final bytes = excel.encode();
    if (bytes == null) return null;

    final file = File(filePath)
      ..createSync(recursive: true)
      ..writeAsBytesSync(bytes);

    return file.path;
  }

  static void _setCell(Sheet sheet, int row, int col, dynamic value) {
    final cell = sheet.cell(
      CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row),
    );

    if (value is int) {
      cell.value = IntCellValue(value);
    } else if (value is double) {
      cell.value = DoubleCellValue(value);
    } else if (value is bool) {
      cell.value = BoolCellValue(value);
    } else {
      cell.value = TextCellValue(value?.toString() ?? '');
    }
  }

  static double _toDouble(dynamic value) {
    if (value == null) return 0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }

  static String _sanitizeFileName(String input) {
    return input.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
  }

  static Future<Directory?> _getSaveDirectory() async {
    try {
      if (Platform.isAndroid) {
        final dir = await getExternalStorageDirectory();
        return dir;
      }

      if (Platform.isIOS) {
        return await getApplicationDocumentsDirectory();
      }

      if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        return await getDownloadsDirectory() ??
            await getApplicationDocumentsDirectory();
      }

      return await getApplicationDocumentsDirectory();
    } catch (_) {
      return await getApplicationDocumentsDirectory();
    }
  }
}