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
    required String bcaFormat,
    required bool bcaCompleted,
    required double bcaWavelengthNm,
    required String bcaIncubationCondition,
    required bool useBlankCorrection,
    required double blankAbsorbance,
    required double standardSlope,
    required double standardIntercept,
    required String standardUnit,
    required double loadingProteinAmountUg,
    required String gelType,
    required double gelPercent,
    required String transferMethod,
    required String membrane,
    required String transferCondition,
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
    required bool pbstUsed,
    required int washCount,
    required int washTimeMin,
    required String chemiluminescence,
    required String detectionSystem,
    required bool loadingControlIncluded,
    required bool filmScanSaved,
    required String notes,
    required List<Map<String, dynamic>> samples,
  }) async {
    try {
      final excel = Excel.createExcel();

      _removeDefaultSheetIfNeeded(excel);

      final summarySheet = excel['Summary'];
      final protocolSheet = excel['Protocol'];
      final bcaSheet = excel['BCA_Calculation'];
      final loadingSheet = excel['Sample_Loading'];

      _fillSummarySheet(
        sheet: summarySheet,
        experimentId: experimentId,
        operatorName: operatorName,
        sampleCount: sampleCount,
        sampleType: sampleType,
        targetForm: targetForm,
        bcaFormat: bcaFormat,
        bcaCompleted: bcaCompleted,
        loadingProteinAmountUg: loadingProteinAmountUg,
        gelType: gelType,
        gelPercent: gelPercent,
        transferMethod: transferMethod,
        membrane: membrane,
        blockingBuffer: blockingBuffer,
        chemiluminescence: chemiluminescence,
        detectionSystem: detectionSystem,
        loadingControlIncluded: loadingControlIncluded,
        filmScanSaved: filmScanSaved,
        notes: notes,
      );

      _fillProtocolSheet(
        sheet: protocolSheet,
        lysisBuffer: lysisBuffer,
        bcaFormat: bcaFormat,
        bcaWavelengthNm: bcaWavelengthNm,
        bcaIncubationCondition: bcaIncubationCondition,
        useBlankCorrection: useBlankCorrection,
        blankAbsorbance: blankAbsorbance,
        standardSlope: standardSlope,
        standardIntercept: standardIntercept,
        standardUnit: standardUnit,
        gelType: gelType,
        gelPercent: gelPercent,
        transferMethod: transferMethod,
        transferCondition: transferCondition,
        membrane: membrane,
        blockingBuffer: blockingBuffer,
        blockingTimeMin: blockingTimeMin,
        primaryAntibody: primaryAntibody,
        primaryHost: primaryHost,
        primaryDilution: primaryDilution,
        primaryIncubation: primaryIncubation,
        secondaryAntibody: secondaryAntibody,
        secondaryDetail: secondaryDetail,
        secondaryDilution: secondaryDilution,
        secondaryIncubation: secondaryIncubation,
        pbstUsed: pbstUsed,
        washCount: washCount,
        washTimeMin: washTimeMin,
        chemiluminescence: chemiluminescence,
        detectionSystem: detectionSystem,
      );

      _fillBcaSheet(
        sheet: bcaSheet,
        blankAbsorbance: blankAbsorbance,
        standardSlope: standardSlope,
        standardIntercept: standardIntercept,
        standardUnit: standardUnit,
        useBlankCorrection: useBlankCorrection,
        samples: samples,
      );

      _fillLoadingSheet(
        sheet: loadingSheet,
        targetProteinAmountUg: loadingProteinAmountUg,
        samples: samples,
      );

      _autoFitBasicColumns(summarySheet, 2);
      _autoFitBasicColumns(protocolSheet, 2);
      _autoFitBasicColumns(bcaSheet, 8);
      _autoFitBasicColumns(loadingSheet, 7);

      final directory = await getApplicationDocumentsDirectory();
      final exportDir = Directory(p.join(directory.path, 'western_blot_exports'));

      if (!exportDir.existsSync()) {
        exportDir.createSync(recursive: true);
      }

      final safeExperimentId = _sanitizeFileName(
        experimentId.isEmpty ? 'western_blot' : experimentId,
      );

      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());

      final filePath = p.join(
        exportDir.path,
        'western_blot_${safeExperimentId}_$timestamp.xlsx',
      );

      final fileBytes = excel.encode();
      if (fileBytes == null) {
        throw Exception('Excel encode failed.');
      }

      final file = File(filePath)
        ..createSync(recursive: true)
        ..writeAsBytesSync(fileBytes);

      return file.path;
    } catch (e) {
      throw Exception('Western blot Excel export failed: $e');
    }
  }

  static void _fillSummarySheet({
    required Sheet sheet,
    required String experimentId,
    required String operatorName,
    required int sampleCount,
    required String sampleType,
    required String targetForm,
    required String bcaFormat,
    required bool bcaCompleted,
    required double loadingProteinAmountUg,
    required String gelType,
    required double gelPercent,
    required String transferMethod,
    required String membrane,
    required String blockingBuffer,
    required String chemiluminescence,
    required String detectionSystem,
    required bool loadingControlIncluded,
    required bool filmScanSaved,
    required String notes,
  }) {
    final rows = <List<dynamic>>[
      ['Field', 'Value'],
      ['Exported at', DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now())],
      ['Experiment ID', experimentId],
      ['Operator', operatorName],
      ['Sample count', sampleCount],
      ['Sample type', sampleType],
      ['Target form', targetForm],
      ['BCA format', bcaFormat],
      ['BCA completed', _yesNo(bcaCompleted)],
      ['Loading amount (µg/lane)', loadingProteinAmountUg],
      ['Gel type', gelType],
      ['Gel percentage (%)', gelPercent],
      ['Transfer method', transferMethod],
      ['Membrane', membrane],
      ['Blocking buffer', blockingBuffer],
      ['Chemiluminescence', chemiluminescence],
      ['Detection system', detectionSystem],
      ['Loading control included', _yesNo(loadingControlIncluded)],
      ['Film scan saved', _yesNo(filmScanSaved)],
      ['Notes', notes],
    ];

    _writeRows(sheet, rows);
  }

  static void _fillProtocolSheet({
    required Sheet sheet,
    required String lysisBuffer,
    required String bcaFormat,
    required double bcaWavelengthNm,
    required String bcaIncubationCondition,
    required bool useBlankCorrection,
    required double blankAbsorbance,
    required double standardSlope,
    required double standardIntercept,
    required String standardUnit,
    required String gelType,
    required double gelPercent,
    required String transferMethod,
    required String transferCondition,
    required String membrane,
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
    required bool pbstUsed,
    required int washCount,
    required int washTimeMin,
    required String chemiluminescence,
    required String detectionSystem,
  }) {
    final rows = <List<dynamic>>[
      ['Section', 'Value'],
      ['Lysis buffer', lysisBuffer],
      ['BCA format', bcaFormat],
      ['BCA wavelength (nm)', bcaWavelengthNm],
      ['BCA incubation', bcaIncubationCondition],
      ['Use blank correction', _yesNo(useBlankCorrection)],
      ['Blank absorbance', blankAbsorbance],
      ['Standard slope', standardSlope],
      ['Standard intercept', standardIntercept],
      ['Standard unit', standardUnit],
      ['Gel type', gelType],
      ['Gel percentage (%)', gelPercent],
      ['Transfer method', transferMethod],
      ['Transfer condition', transferCondition],
      ['Membrane', membrane],
      ['Blocking buffer', blockingBuffer],
      ['Blocking time (min)', blockingTimeMin],
      ['Primary antibody', primaryAntibody],
      ['Primary host', primaryHost],
      ['Primary dilution', primaryDilution],
      ['Primary incubation', primaryIncubation],
      ['Secondary antibody-HRP', secondaryAntibody],
      ['Secondary detail', secondaryDetail],
      ['Secondary dilution', secondaryDilution],
      ['Secondary incubation', secondaryIncubation],
      ['PBST used', _yesNo(pbstUsed)],
      ['Wash count', washCount],
      ['Wash time per wash (min)', washTimeMin],
      ['Chemiluminescence substrate', chemiluminescence],
      ['Detection system', detectionSystem],
    ];

    _writeRows(sheet, rows);
  }

  static void _fillBcaSheet({
    required Sheet sheet,
    required double blankAbsorbance,
    required double standardSlope,
    required double standardIntercept,
    required String standardUnit,
    required bool useBlankCorrection,
    required List<Map<String, dynamic>> samples,
  }) {
    final header = [
      'Sample Name',
      'Raw Absorbance',
      'Corrected Absorbance',
      'Dilution Factor',
      'Calculated Conc. (µg/µL)',
      'Calculated Conc. ($standardUnit)',
      'Loading Volume (µL)',
      'Status',
    ];

    _writeRow(sheet, 1, header);

    for (int i = 0; i < samples.length; i++) {
      final rowIndex = i + 2;
      final row = samples[i];

      final sampleName = row['sampleName']?.toString() ?? '';
      final rawAbs = _toDouble(row['rawAbsorbance']);
      final correctedAbs = _toDouble(row['correctedAbsorbance']);
      final dilutionFactor = _toDouble(row['dilutionFactor']);
      final concUgPerUl = _toDouble(row['calculatedConcentrationUgPerUl']);
      final loadingVolume = _toDouble(row['loadingVolumeUl']);
      final concUgPerMl = concUgPerUl * 1000.0;

      final status = _sampleStatus(
        rawAbsorbance: rawAbs,
        concentrationUgPerUl: concUgPerUl,
        loadingVolumeUl: loadingVolume,
      );

      _writeRow(sheet, rowIndex, [
        sampleName,
        rawAbs,
        useBlankCorrection ? correctedAbs : rawAbs,
        dilutionFactor,
        concUgPerUl,
        concUgPerMl,
        loadingVolume,
        status,
      ]);
    }

    final startInfoRow = samples.length + 4;
    _writeRow(sheet, startInfoRow, ['Reference', 'Value']);
    _writeRow(sheet, startInfoRow + 1, ['Blank absorbance', blankAbsorbance]);
    _writeRow(sheet, startInfoRow + 2, ['Standard slope', standardSlope]);
    _writeRow(sheet, startInfoRow + 3, ['Standard intercept', standardIntercept]);
    _writeRow(sheet, startInfoRow + 4, ['Formula 1', 'Corrected = Raw - Blank']);
    _writeRow(
      sheet,
      startInfoRow + 5,
      ['Formula 2', 'Conc. (µg/mL) = (Corrected - Intercept) / Slope'],
    );
    _writeRow(
      sheet,
      startInfoRow + 6,
      ['Formula 3', 'Adjusted conc. = Calculated conc. × Dilution factor'],
    );
    _writeRow(
      sheet,
      startInfoRow + 7,
      ['Formula 4', 'Conc. (µg/µL) = Adjusted conc. (µg/mL) / 1000'],
    );
  }

  static void _fillLoadingSheet({
    required Sheet sheet,
    required double targetProteinAmountUg,
    required List<Map<String, dynamic>> samples,
  }) {
    final header = [
      'Sample Name',
      'Protein Conc. (µg/µL)',
      'Target Protein (µg)',
      'Required Volume (µL)',
      'Recommended Status',
      'Comment',
    ];

    _writeRow(sheet, 1, header);

    for (int i = 0; i < samples.length; i++) {
      final rowIndex = i + 2;
      final row = samples[i];

      final sampleName = row['sampleName']?.toString() ?? '';
      final concUgPerUl = _toDouble(row['calculatedConcentrationUgPerUl']);
      final loadingVolume = _toDouble(row['loadingVolumeUl']);
      final status = _sampleStatus(
        rawAbsorbance: _toDouble(row['rawAbsorbance']),
        concentrationUgPerUl: concUgPerUl,
        loadingVolumeUl: loadingVolume,
      );

      final comment = _loadingComment(status);

      _writeRow(sheet, rowIndex, [
        sampleName,
        concUgPerUl,
        targetProteinAmountUg,
        loadingVolume,
        status,
        comment,
      ]);
    }
  }

  static void _writeRows(Sheet sheet, List<List<dynamic>> rows) {
    for (int i = 0; i < rows.length; i++) {
      _writeRow(sheet, i + 1, rows[i]);
    }
  }

  static void _writeRow(Sheet sheet, int rowIndex, List<dynamic> values) {
    for (int col = 0; col < values.length; col++) {
      final cell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: col, rowIndex: rowIndex - 1),
      );
      cell.value = _toCellValue(values[col]);
    }
  }

  static CellValue? _toCellValue(dynamic value) {
    if (value == null) return null;

    if (value is CellValue) return value;
    if (value is String) return TextCellValue(value);
    if (value is int) return IntCellValue(value);
    if (value is double) return DoubleCellValue(value);
    if (value is bool) return TextCellValue(value ? 'TRUE' : 'FALSE');

    return TextCellValue(value.toString());
  }

  static void _removeDefaultSheetIfNeeded(Excel excel) {
    const defaultSheetName = 'Sheet1';
    if (excel.tables.containsKey(defaultSheetName) &&
        excel.tables.length > 1) {
      excel.delete(defaultSheetName);
    }
  }

  static void _autoFitBasicColumns(Sheet sheet, int columnCount) {
    for (int i = 0; i < columnCount; i++) {
      sheet.setColumnWidth(i, i == 0 ? 24 : 22);
    }
  }

  static String _sanitizeFileName(String input) {
    return input
        .trim()
        .replaceAll(RegExp(r'[\\/:*?"<>|]'), '_')
        .replaceAll(RegExp(r'\s+'), '_');
  }

  static String _yesNo(bool value) => value ? 'Yes' : 'No';

  static double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is int) return value.toDouble();
    if (value is double) return value;
    return double.tryParse(value.toString()) ?? 0.0;
  }

  static String _sampleStatus({
    required double rawAbsorbance,
    required double concentrationUgPerUl,
    required double loadingVolumeUl,
  }) {
    if (rawAbsorbance <= 0) return 'No BCA result';
    if (concentrationUgPerUl <= 0) return 'Invalid curve result';
    if (loadingVolumeUl > 30) return 'High loading volume';
    return 'Ready';
  }

  static String _loadingComment(String status) {
    switch (status) {
      case 'Ready':
        return 'Suitable for loading';
      case 'High loading volume':
        return 'Consider concentrating sample';
      case 'Invalid curve result':
        return 'Check BCA standard curve';
      case 'No BCA result':
        return 'Enter absorbance first';
      default:
        return '';
    }
  }
}