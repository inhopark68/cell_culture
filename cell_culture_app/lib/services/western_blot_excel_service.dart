import 'dart:io';

import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class WesternBlotExcelService {
  static Future<String?> export({
    required String experimentId,
    required String operatorName,
    required int sampleCount,
    required String sampleType,
    required String lysisBuffer,
    required String targetForm,

    // BCA
    required String bcaFormat,
    required bool bcaCompleted,
    required double bcaWavelengthNm,
    required String bcaIncubationCondition,
    required bool useBlankCorrection,
    required double blankAbsorbance,
    required double standardSlope,
    required double standardIntercept,
    required String standardUnit,
    required String standardReplicateMode,
    required String sampleReplicateMode,

    // Western blot loading / gel
    required double loadingProteinAmountUg,
    required String gelType,
    required double gelPercent,
    required String transferMethod,
    required String membrane,
    required String transferCondition,

    // Antibody / blocking
    required String blockingBuffer,
    required int blockingTimeMin,
    required String primaryAntibody,
    required String primaryHost,
    required String primaryDilution,
    required String primaryIncubation,
    required String secondaryAntibody,
    required String secondaryDetail,
    required String secondaryDilution,
    required String secondaryIncubation,

    // Wash / detection
    required bool pbstUsed,
    required int washCount,
    required int washTimeMin,
    required String chemiluminescence,
    required String detectionSystem,
    required bool loadingControlIncluded,
    required bool filmScanSaved,

    required String notes,

    // Page와 동일한 구조 사용
    required List<Map<String, dynamic>> standards,
    required List<Map<String, dynamic>> samples,
  }) async {
    final excel = Excel.createExcel();

    final summarySheet = excel['Summary'];
    final bcaSheet = excel['Microplate BCA'];
    final sampleSheet = excel['Samples'];
    final processSheet = excel['Process'];
    final formulaSheet = excel['Formula'];

    if (excel.sheets.containsKey('Sheet1')) {
      excel.delete('Sheet1');
    }

    // =========================
    // Summary
    // =========================
    _setCell(summarySheet, 0, 0, 'Western Blot Template');
    _setCell(summarySheet, 1, 0, 'Generated at');
    _setCell(
      summarySheet,
      1,
      1,
      DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now()),
    );

    _setCell(summarySheet, 3, 0, 'Experiment ID');
    _setCell(summarySheet, 3, 1, experimentId);

    _setCell(summarySheet, 4, 0, 'Operator');
    _setCell(summarySheet, 4, 1, operatorName);

    _setCell(summarySheet, 5, 0, 'Sample count');
    _setCell(summarySheet, 5, 1, sampleCount);

    _setCell(summarySheet, 6, 0, 'Sample type');
    _setCell(summarySheet, 6, 1, sampleType);

    _setCell(summarySheet, 7, 0, 'Lysis buffer');
    _setCell(summarySheet, 7, 1, lysisBuffer);

    _setCell(summarySheet, 8, 0, 'Target form');
    _setCell(summarySheet, 8, 1, targetForm);

    _setCell(summarySheet, 10, 0, 'BCA format');
    _setCell(summarySheet, 10, 1, bcaFormat);

    _setCell(summarySheet, 11, 0, 'BCA assay');
    _setCell(summarySheet, 11, 1, bcaCompleted ? 'Completed' : 'Pending');

    _setCell(summarySheet, 12, 0, 'BCA wavelength (nm)');
    _setCell(summarySheet, 12, 1, bcaWavelengthNm);

    _setCell(summarySheet, 13, 0, 'BCA incubation');
    _setCell(summarySheet, 13, 1, bcaIncubationCondition);

    _setCell(summarySheet, 14, 0, 'Use blank correction');
    _setCell(summarySheet, 14, 1, useBlankCorrection ? 'Yes' : 'No');

    _setCell(summarySheet, 15, 0, 'Blank absorbance');
    _setCell(summarySheet, 15, 1, blankAbsorbance);

    _setCell(summarySheet, 16, 0, 'Standard slope');
    _setCell(summarySheet, 16, 1, standardSlope);

    _setCell(summarySheet, 17, 0, 'Standard intercept');
    _setCell(summarySheet, 17, 1, standardIntercept);

    _setCell(summarySheet, 18, 0, 'Standard unit');
    _setCell(summarySheet, 18, 1, standardUnit);

    _setCell(summarySheet, 19, 0, 'Standard replicate');
    _setCell(summarySheet, 19, 1, standardReplicateMode);

    _setCell(summarySheet, 20, 0, 'Sample replicate');
    _setCell(summarySheet, 20, 1, sampleReplicateMode);

    _setCell(summarySheet, 22, 0, 'Loading protein amount (µg/lane)');
    _setCell(summarySheet, 22, 1, loadingProteinAmountUg);

    _setCell(summarySheet, 23, 0, 'Gel type');
    _setCell(summarySheet, 23, 1, gelType);

    _setCell(summarySheet, 24, 0, 'Gel percentage (%)');
    _setCell(summarySheet, 24, 1, gelPercent);

    _setCell(summarySheet, 25, 0, 'Transfer method');
    _setCell(summarySheet, 25, 1, transferMethod);

    _setCell(summarySheet, 26, 0, 'Membrane');
    _setCell(summarySheet, 26, 1, membrane);

    _setCell(summarySheet, 27, 0, 'Transfer condition');
    _setCell(summarySheet, 27, 1, transferCondition);

    _setCell(summarySheet, 29, 0, 'Blocking buffer');
    _setCell(summarySheet, 29, 1, blockingBuffer);

    _setCell(summarySheet, 30, 0, 'Blocking time (min)');
    _setCell(summarySheet, 30, 1, blockingTimeMin);

    _setCell(summarySheet, 31, 0, 'Primary antibody');
    _setCell(summarySheet, 31, 1, primaryAntibody);

    _setCell(summarySheet, 32, 0, 'Primary host');
    _setCell(summarySheet, 32, 1, primaryHost);

    _setCell(summarySheet, 33, 0, 'Primary dilution');
    _setCell(summarySheet, 33, 1, primaryDilution);

    _setCell(summarySheet, 34, 0, 'Primary incubation');
    _setCell(summarySheet, 34, 1, primaryIncubation);

    _setCell(summarySheet, 35, 0, 'Secondary antibody-HRP');
    _setCell(summarySheet, 35, 1, secondaryAntibody);

    _setCell(summarySheet, 36, 0, 'Secondary detail');
    _setCell(summarySheet, 36, 1, secondaryDetail);

    _setCell(summarySheet, 37, 0, 'Secondary dilution');
    _setCell(summarySheet, 37, 1, secondaryDilution);

    _setCell(summarySheet, 38, 0, 'Secondary incubation');
    _setCell(summarySheet, 38, 1, secondaryIncubation);

    _setCell(summarySheet, 40, 0, 'Washing buffer');
    _setCell(summarySheet, 40, 1, pbstUsed ? 'PBST' : 'Custom / Other');

    _setCell(summarySheet, 41, 0, 'Wash count');
    _setCell(summarySheet, 41, 1, washCount);

    _setCell(summarySheet, 42, 0, 'Wash time per wash (min)');
    _setCell(summarySheet, 42, 1, washTimeMin);

    _setCell(summarySheet, 43, 0, 'Chemiluminescence');
    _setCell(summarySheet, 43, 1, chemiluminescence);

    _setCell(summarySheet, 44, 0, 'Detection system');
    _setCell(summarySheet, 44, 1, detectionSystem);

    _setCell(summarySheet, 45, 0, 'Loading control included');
    _setCell(summarySheet, 45, 1, loadingControlIncluded ? 'Yes' : 'No');

    _setCell(summarySheet, 46, 0, 'Film scan saved');
    _setCell(summarySheet, 46, 1, filmScanSaved ? 'Yes' : 'No');

    _setCell(summarySheet, 48, 0, 'Notes');
    _setCell(summarySheet, 48, 1, notes);

    // =========================
    // Microplate BCA sheet
    // =========================
    _setCell(bcaSheet, 0, 0, 'Microplate BCA Summary');
    _setCell(bcaSheet, 2, 0, 'Assay format');
    _setCell(bcaSheet, 2, 1, bcaFormat);

    _setCell(bcaSheet, 3, 0, 'Wavelength (nm)');
    _setCell(bcaSheet, 3, 1, bcaWavelengthNm);

    _setCell(bcaSheet, 4, 0, 'Blank correction');
    _setCell(bcaSheet, 4, 1, useBlankCorrection ? 'Yes' : 'No');

    _setCell(bcaSheet, 5, 0, 'Blank absorbance');
    _setCell(bcaSheet, 5, 1, blankAbsorbance);

    _setCell(bcaSheet, 6, 0, 'Standard slope');
    _setCell(bcaSheet, 6, 1, standardSlope);

    _setCell(bcaSheet, 7, 0, 'Standard intercept');
    _setCell(bcaSheet, 7, 1, standardIntercept);

    _setCell(bcaSheet, 8, 0, 'Standard unit');
    _setCell(bcaSheet, 8, 1, standardUnit);

    _setCell(bcaSheet, 9, 0, 'Standard replicate');
    _setCell(bcaSheet, 9, 1, standardReplicateMode);

    _setCell(bcaSheet, 10, 0, 'Sample replicate');
    _setCell(bcaSheet, 10, 1, sampleReplicateMode);

    _setCell(bcaSheet, 11, 0, 'Curve equation');
    _setCell(
      bcaSheet,
      11,
      1,
      'y = ${standardSlope.toStringAsFixed(6)}x + ${standardIntercept.toStringAsFixed(6)}',
    );

    _setCell(bcaSheet, 13, 0, 'Protocol Step');
    _setCell(bcaSheet, 13, 1, 'Description');

    _setCell(bcaSheet, 14, 0, '1');
    _setCell(bcaSheet, 14, 1, 'Prepare BSA standards and blank');

    _setCell(bcaSheet, 15, 0, '2');
    _setCell(bcaSheet, 15, 1, 'Load standards and diluted samples into microplate');

    _setCell(bcaSheet, 16, 0, '3');
    _setCell(bcaSheet, 16, 1, 'Add BCA working reagent');

    _setCell(bcaSheet, 17, 0, '4');
    _setCell(bcaSheet, 17, 1, 'Incubate plate under selected condition');

    _setCell(bcaSheet, 18, 0, '5');
    _setCell(bcaSheet, 18, 1, 'Read absorbance at selected wavelength');

    _setCell(bcaSheet, 19, 0, '6');
    _setCell(bcaSheet, 19, 1, 'Correct absorbance using blank if enabled');

    _setCell(bcaSheet, 20, 0, '7');
    _setCell(bcaSheet, 20, 1, 'Calculate concentration from standard curve');

    _setCell(bcaSheet, 21, 0, '8');
    _setCell(bcaSheet, 21, 1, 'Multiply by dilution factor for original sample concentration');

    _setCell(bcaSheet, 22, 0, '9');
    _setCell(bcaSheet, 22, 1, 'Convert µg/mL to µg/µL for loading volume calculation');

    final standardTableRow = 25;
    final standardHeaders = [
      'No',
      'Standard concentration (µg/mL)',
      'Abs 1',
      'Abs 2',
      'Abs 3',
      'Average absorbance',
      'Corrected average absorbance',
    ];

    for (int i = 0; i < standardHeaders.length; i++) {
      _setCell(bcaSheet, standardTableRow, i, standardHeaders[i]);
    }

    for (int i = 0; i < standards.length; i++) {
      final row = standards[i];
      final absorbances = _toDoubleList(row['absorbances']);

      final r = standardTableRow + 1 + i;
      _setCell(bcaSheet, r, 0, i + 1);
      _setCell(bcaSheet, r, 1, _toDouble(row['concentrationUgPerMl']));
      _setCell(bcaSheet, r, 2, absorbances.isNotEmpty ? absorbances[0] : 0);
      _setCell(bcaSheet, r, 3, absorbances.length > 1 ? absorbances[1] : 0);
      _setCell(bcaSheet, r, 4, absorbances.length > 2 ? absorbances[2] : 0);
      _setCell(bcaSheet, r, 5, _toDouble(row['averageAbsorbance']));
      _setCell(bcaSheet, r, 6, _toDouble(row['correctedAverageAbsorbance']));
    }

    // =========================
    // Sample sheet
    // =========================
    final headers = [
      'No',
      'Sample name',
      'Average raw absorbance',
      'Dilution factor',
      'Corrected absorbance',
      'Protein concentration (µg/µL)',
      'Target loading amount (µg)',
      'Loading volume (µL)',
      'Status',
    ];

    for (int i = 0; i < headers.length; i++) {
      _setCell(sampleSheet, 0, i, headers[i]);
    }

    int readyCount = 0;
    int highVolumeCount = 0;
    int invalidCurveCount = 0;
    int noBcaCount = 0;

    for (int i = 0; i < samples.length; i++) {
      final row = samples[i];

      final sampleName = (row['sampleName'] ?? 'Sample ${i + 1}').toString();
      final averageAbsorbance = _toDouble(row['averageAbsorbance']);
      final dilutionFactor = _toDouble(row['dilutionFactor']);
      final correctedAbsorbance = _toDouble(row['correctedAbsorbance']);
      final calculatedConcentrationUgPerUl =
          _toDouble(row['calculatedConcentrationUgPerUl']);
      final loadingVolumeUl = _toDouble(row['loadingVolumeUl']);

      String status;
      if (averageAbsorbance <= 0) {
        status = 'No BCA result';
        noBcaCount++;
      } else if (calculatedConcentrationUgPerUl <= 0) {
        status = 'Invalid curve result';
        invalidCurveCount++;
      } else if (loadingVolumeUl > 30) {
        status = 'High loading volume';
        highVolumeCount++;
      } else {
        status = 'Ready';
        readyCount++;
      }

      final r = i + 1;
      _setCell(sampleSheet, r, 0, i + 1);
      _setCell(sampleSheet, r, 1, sampleName);
      _setCell(sampleSheet, r, 2, averageAbsorbance);
      _setCell(sampleSheet, r, 3, dilutionFactor);
      _setCell(sampleSheet, r, 4, correctedAbsorbance);
      _setCell(sampleSheet, r, 5, calculatedConcentrationUgPerUl);
      _setCell(sampleSheet, r, 6, loadingProteinAmountUg);
      _setCell(sampleSheet, r, 7, loadingVolumeUl);
      _setCell(sampleSheet, r, 8, status);
    }

    _setCell(summarySheet, 50, 0, 'Ready samples');
    _setCell(summarySheet, 50, 1, readyCount);

    _setCell(summarySheet, 51, 0, 'High loading volume samples');
    _setCell(summarySheet, 51, 1, highVolumeCount);

    _setCell(summarySheet, 52, 0, 'Invalid curve result samples');
    _setCell(summarySheet, 52, 1, invalidCurveCount);

    _setCell(summarySheet, 53, 0, 'No BCA result samples');
    _setCell(summarySheet, 53, 1, noBcaCount);

    // =========================
    // Process sheet
    // =========================
    _setCell(processSheet, 0, 0, 'Step');
    _setCell(processSheet, 0, 1, 'Detail');

    _setCell(processSheet, 1, 0, '1');
    _setCell(processSheet, 1, 1, 'Cell lysis and protein extraction');

    _setCell(processSheet, 2, 0, '2');
    _setCell(processSheet, 2, 1, 'Microplate BCA assay for quantification');

    _setCell(processSheet, 3, 0, '3');
    _setCell(processSheet, 3, 1, 'Determine loading volume from protein concentration');

    _setCell(processSheet, 4, 0, '4');
    _setCell(processSheet, 4, 1, 'Sample loading and SDS-PAGE');

    _setCell(processSheet, 5, 0, '5');
    _setCell(processSheet, 5, 1, 'Transfer proteins to membrane');

    _setCell(processSheet, 6, 0, '6');
    _setCell(processSheet, 6, 1, 'Blocking');

    _setCell(processSheet, 7, 0, '7');
    _setCell(processSheet, 7, 1, 'Primary antibody incubation');

    _setCell(processSheet, 8, 0, '8');
    _setCell(processSheet, 8, 1, 'PBST washing');

    _setCell(processSheet, 9, 0, '9');
    _setCell(processSheet, 9, 1, 'Secondary antibody-HRP incubation');

    _setCell(processSheet, 10, 0, '10');
    _setCell(processSheet, 10, 1, 'PBST washing');

    _setCell(processSheet, 11, 0, '11');
    _setCell(processSheet, 11, 1, 'Chemiluminescence detection');

    _setCell(processSheet, 12, 0, '12');
    _setCell(
      processSheet,
      12,
      1,
      detectionSystem == 'X-ray film'
          ? 'Film developing and scan storage'
          : 'LAS digital capture and image save',
    );

    // =========================
    // Formula sheet
    // =========================
    _setCell(formulaSheet, 0, 0, 'Formula');
    _setCell(formulaSheet, 0, 1, 'Description');

    _setCell(formulaSheet, 1, 0, '1');
    _setCell(
      formulaSheet,
      1,
      1,
      'Corrected absorbance = Average raw absorbance - Blank absorbance',
    );

    _setCell(formulaSheet, 2, 0, '2');
    _setCell(
      formulaSheet,
      2,
      1,
      'Protein concentration (µg/mL) = (Corrected absorbance - Intercept) ÷ Slope',
    );

    _setCell(formulaSheet, 3, 0, '3');
    _setCell(
      formulaSheet,
      3,
      1,
      'Adjusted concentration (µg/mL) = Calculated concentration × Dilution factor',
    );

    _setCell(formulaSheet, 4, 0, '4');
    _setCell(
      formulaSheet,
      4,
      1,
      'Protein concentration (µg/µL) = Adjusted concentration (µg/mL) ÷ 1000',
    );

    _setCell(formulaSheet, 5, 0, '5');
    _setCell(
      formulaSheet,
      5,
      1,
      'Loading volume (µL) = Target protein amount (µg) ÷ Protein concentration (µg/µL)',
    );

    _setCell(formulaSheet, 6, 0, '6');
    _setCell(
      formulaSheet,
      6,
      1,
      'If X-ray film is used, scanned image should be saved after developing',
    );

    // =========================
    // Save
    // =========================
    final dir = await _getSaveDirectory();
    if (dir == null) return null;

    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final safeExperimentId = experimentId.trim().isEmpty
        ? 'western_blot'
        : _sanitizeFileName(experimentId.trim());

    final filePath = p.join(
      dir.path,
      '${safeExperimentId}_western_blot_$timestamp.xlsx',
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

  static List<double> _toDoubleList(dynamic value) {
    if (value is List) {
      return value.map((e) => _toDouble(e)).toList();
    }
    return <double>[];
  }

  static String _sanitizeFileName(String input) {
    return input.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
  }

  static Future<Directory?> _getSaveDirectory() async {
    try {
      if (Platform.isAndroid) {
        return await getExternalStorageDirectory();
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