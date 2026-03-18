import 'dart:io';

import 'package:excel/excel.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class CellCultureExcelService {
  static CellValue _toCellValue(dynamic value) {
    if (value == null) return TextCellValue('');
    if (value is CellValue) return value;
    if (value is String) return TextCellValue(value);
    if (value is int) return IntCellValue(value);
    if (value is double) return DoubleCellValue(value);
    if (value is bool) return BoolCellValue(value);
    return TextCellValue(value.toString());
  }

  static final CellStyle _titleStyle = CellStyle(
    bold: true,
    fontSize: 14,
    horizontalAlign: HorizontalAlign.Center,
    verticalAlign: VerticalAlign.Center,
  );

  static final CellStyle _sectionStyle = CellStyle(
    bold: true,
    backgroundColorHex: ExcelColor.fromHexString('#D9EAF7'),
    horizontalAlign: HorizontalAlign.Left,
    verticalAlign: VerticalAlign.Center,
  );

  static final CellStyle _labelStyle = CellStyle(
    bold: true,
    backgroundColorHex: ExcelColor.fromHexString('#F3F4F6'),
    horizontalAlign: HorizontalAlign.Left,
    verticalAlign: VerticalAlign.Center,
  );

  static final CellStyle _valueStyle = CellStyle(
    horizontalAlign: HorizontalAlign.Left,
    verticalAlign: VerticalAlign.Center,
  );

  static final CellStyle _plateHeaderStyle = CellStyle(
    bold: true,
    backgroundColorHex: ExcelColor.fromHexString('#E5E7EB'),
    horizontalAlign: HorizontalAlign.Center,
    verticalAlign: VerticalAlign.Center,
  );

  static final CellStyle _plateSampleStyle = CellStyle(
    backgroundColorHex: ExcelColor.fromHexString('#DBEAFE'),
    horizontalAlign: HorizontalAlign.Center,
    verticalAlign: VerticalAlign.Center,
  );

  static final CellStyle _plateBlankStyle = CellStyle(
    backgroundColorHex: ExcelColor.fromHexString('#D1D5DB'),
    horizontalAlign: HorizontalAlign.Center,
    verticalAlign: VerticalAlign.Center,
  );

  static final CellStyle _plateNegativeStyle = CellStyle(
    backgroundColorHex: ExcelColor.fromHexString('#FECACA'),
    horizontalAlign: HorizontalAlign.Center,
    verticalAlign: VerticalAlign.Center,
  );

  static final CellStyle _plateVehicleStyle = CellStyle(
    backgroundColorHex: ExcelColor.fromHexString('#FEF3C7'),
    horizontalAlign: HorizontalAlign.Center,
    verticalAlign: VerticalAlign.Center,
  );

  static final CellStyle _platePositiveStyle = CellStyle(
    backgroundColorHex: ExcelColor.fromHexString('#D1FAE5'),
    horizontalAlign: HorizontalAlign.Center,
    verticalAlign: VerticalAlign.Center,
  );

  static final CellStyle _plateEmptyStyle = CellStyle(
    backgroundColorHex: ExcelColor.fromHexString('#F9FAFB'),
    horizontalAlign: HorizontalAlign.Center,
    verticalAlign: VerticalAlign.Center,
  );

  static void _setCell(
    Sheet sheet,
    String cellRef,
    dynamic value, {
    CellStyle? style,
  }) {
    final cell = sheet.cell(CellIndex.indexByString(cellRef));
    cell.value = _toCellValue(value);
    if (style != null) {
      cell.cellStyle = style;
    }
  }

  static void _setCellByIndex(
    Sheet sheet, {
    required int columnIndex,
    required int rowIndex,
    required dynamic value,
    CellStyle? style,
  }) {
    final cell = sheet.cell(
      CellIndex.indexByColumnRow(
        columnIndex: columnIndex,
        rowIndex: rowIndex,
      ),
    );
    cell.value = _toCellValue(value);
    if (style != null) {
      cell.cellStyle = style;
    }
  }

  static void _setLabelValueRow(
    Sheet sheet, {
    required int rowNumber,
    required String label,
    required dynamic value,
  }) {
    _setCell(sheet, 'A$rowNumber', label, style: _labelStyle);
    _setCell(sheet, 'B$rowNumber', value, style: _valueStyle);
  }

  static CellStyle _plateStyleForValue(String value) {
    final v = value.trim().toUpperCase();

    if (v.isEmpty || v == '-') return _plateEmptyStyle;
    if (v == 'BLK') return _plateBlankStyle;
    if (v == 'NC') return _plateNegativeStyle;
    if (v == 'VEH') return _plateVehicleStyle;
    if (v == 'PC') return _platePositiveStyle;
    return _plateSampleStyle;
  }

  static Future<String?> export({
    required String cellLine,
    required String assayType,
    required String cultureWare,
    required double surfaceArea,
    required String workingVolume,
    required double seedingDensity,
    required int sampleCount,
    required int replicateCount,
    required int blankCount,
    required int negativeControlCount,
    required int vehicleCount,
    required int positiveControlCount,
    required int totalControlUnits,
    required int totalSampleUnits,
    required int totalCultureUnits,
    required int cellsPerUnit,
    required int totalCellsNeeded,
    required int totalCellsNeededWithExtra,
    required int targetConfluency,
    required double seedingVolumePerUnit,
    required double totalSeedingVolume,
    required double totalSeedingVolumeWithExtra,
    required double stockConcentration,
    required double requiredCellSuspensionVolume,
    required double requiredCellSuspensionVolumeWithExtra,
    required double requiredMediaVolume,
    required double requiredMediaVolumeWithExtra,
    required double extraPercent,
    required List<List<String>> layout,
  }) async {
    try {
      final excel = Excel.createExcel();

      final defaultSheet = excel.getDefaultSheet();

      final summarySheet = excel['Summary'];
      final suspensionSheet = excel['Suspension'];
      final layoutSheet = excel['Plate Layout'];

      if (defaultSheet != null &&
          defaultSheet != 'Summary' &&
          defaultSheet != 'Suspension' &&
          defaultSheet != 'Plate Layout') {
        excel.delete(defaultSheet);
      }

      // Summary sheet
      _setCell(summarySheet, 'A1', 'Cell Culture Summary', style: _titleStyle);
      summarySheet.merge(
        CellIndex.indexByString('A1'),
        CellIndex.indexByString('B1'),
      );

      _setCell(summarySheet, 'A3', 'Basic Information', style: _sectionStyle);
      summarySheet.merge(
        CellIndex.indexByString('A3'),
        CellIndex.indexByString('B3'),
      );

      _setLabelValueRow(
        summarySheet,
        rowNumber: 4,
        label: 'Cell line',
        value: cellLine,
      );
      _setLabelValueRow(
        summarySheet,
        rowNumber: 5,
        label: 'Assay type',
        value: assayType,
      );
      _setLabelValueRow(
        summarySheet,
        rowNumber: 6,
        label: 'Culture ware',
        value: cultureWare,
      );
      _setLabelValueRow(
        summarySheet,
        rowNumber: 7,
        label: 'Surface area (cm²)',
        value: surfaceArea,
      );
      _setLabelValueRow(
        summarySheet,
        rowNumber: 8,
        label: 'Working volume',
        value: workingVolume,
      );
      _setLabelValueRow(
        summarySheet,
        rowNumber: 9,
        label: 'Seeding density (cells/cm²)',
        value: seedingDensity,
      );
      _setLabelValueRow(
        summarySheet,
        rowNumber: 10,
        label: 'Target confluency (%)',
        value: targetConfluency,
      );

      _setCell(summarySheet, 'A12', 'Experimental Design', style: _sectionStyle);
      summarySheet.merge(
        CellIndex.indexByString('A12'),
        CellIndex.indexByString('B12'),
      );

      _setLabelValueRow(
        summarySheet,
        rowNumber: 13,
        label: 'Sample count',
        value: sampleCount,
      );
      _setLabelValueRow(
        summarySheet,
        rowNumber: 14,
        label: 'Replicates',
        value: replicateCount,
      );
      _setLabelValueRow(
        summarySheet,
        rowNumber: 15,
        label: 'Blank count',
        value: blankCount,
      );
      _setLabelValueRow(
        summarySheet,
        rowNumber: 16,
        label: 'Negative control count',
        value: negativeControlCount,
      );
      _setLabelValueRow(
        summarySheet,
        rowNumber: 17,
        label: 'Vehicle count',
        value: vehicleCount,
      );
      _setLabelValueRow(
        summarySheet,
        rowNumber: 18,
        label: 'Positive control count',
        value: positiveControlCount,
      );
      _setLabelValueRow(
        summarySheet,
        rowNumber: 19,
        label: 'Total control units',
        value: totalControlUnits,
      );
      _setLabelValueRow(
        summarySheet,
        rowNumber: 20,
        label: 'Total sample units',
        value: totalSampleUnits,
      );
      _setLabelValueRow(
        summarySheet,
        rowNumber: 21,
        label: 'Total culture units',
        value: totalCultureUnits,
      );

      _setCell(summarySheet, 'A23', 'Calculated Result', style: _sectionStyle);
      summarySheet.merge(
        CellIndex.indexByString('A23'),
        CellIndex.indexByString('B23'),
      );

      _setLabelValueRow(
        summarySheet,
        rowNumber: 24,
        label: 'Cells per unit',
        value: cellsPerUnit,
      );
      _setLabelValueRow(
        summarySheet,
        rowNumber: 25,
        label: 'Total cells needed',
        value: totalCellsNeeded,
      );
      _setLabelValueRow(
        summarySheet,
        rowNumber: 26,
        label: 'Total cells needed (+extra)',
        value: totalCellsNeededWithExtra,
      );

      summarySheet.setColumnWidth(0, 28);
      summarySheet.setColumnWidth(1, 24);

      // Suspension sheet
      _setCell(
        suspensionSheet,
        'A1',
        'Suspension Preparation',
        style: _titleStyle,
      );
      suspensionSheet.merge(
        CellIndex.indexByString('A1'),
        CellIndex.indexByString('B1'),
      );

      _setLabelValueRow(
        suspensionSheet,
        rowNumber: 3,
        label: 'Seeding volume per unit (mL)',
        value: seedingVolumePerUnit,
      );
      _setLabelValueRow(
        suspensionSheet,
        rowNumber: 4,
        label: 'Total seeding volume (mL)',
        value: totalSeedingVolume,
      );
      _setLabelValueRow(
        suspensionSheet,
        rowNumber: 5,
        label: 'Total seeding volume (+extra) (mL)',
        value: totalSeedingVolumeWithExtra,
      );
      _setLabelValueRow(
        suspensionSheet,
        rowNumber: 6,
        label: 'Stock concentration (cells/mL)',
        value: stockConcentration,
      );
      _setLabelValueRow(
        suspensionSheet,
        rowNumber: 7,
        label: 'Required cell suspension (mL)',
        value: requiredCellSuspensionVolume,
      );
      _setLabelValueRow(
        suspensionSheet,
        rowNumber: 8,
        label: 'Required cell suspension (+extra) (mL)',
        value: requiredCellSuspensionVolumeWithExtra,
      );
      _setLabelValueRow(
        suspensionSheet,
        rowNumber: 9,
        label: 'Required media volume (mL)',
        value: requiredMediaVolume,
      );
      _setLabelValueRow(
        suspensionSheet,
        rowNumber: 10,
        label: 'Required media volume (+extra) (mL)',
        value: requiredMediaVolumeWithExtra,
      );
      _setLabelValueRow(
        suspensionSheet,
        rowNumber: 11,
        label: 'Extra fraction',
        value: extraPercent,
      );
      _setLabelValueRow(
        suspensionSheet,
        rowNumber: 12,
        label: 'Extra percent (%)',
        value: extraPercent * 100,
      );

      suspensionSheet.setColumnWidth(0, 32);
      suspensionSheet.setColumnWidth(1, 22);

      // Plate Layout sheet
      _setCell(layoutSheet, 'A1', 'Plate Layout', style: _titleStyle);
      layoutSheet.merge(
        CellIndex.indexByString('A1'),
        CellIndex.indexByString('H1'),
      );

      if (layout.isNotEmpty) {
        final rowCount = layout.length;
        final colCount = layout.first.length;

        _setCellByIndex(
          layoutSheet,
          columnIndex: 0,
          rowIndex: 2,
          value: '',
          style: _plateHeaderStyle,
        );

        for (int c = 0; c < colCount; c++) {
          _setCellByIndex(
            layoutSheet,
            columnIndex: c + 1,
            rowIndex: 2,
            value: c + 1,
            style: _plateHeaderStyle,
          );
        }

        for (int r = 0; r < rowCount; r++) {
          final rowLabel = String.fromCharCode(65 + r);

          _setCellByIndex(
            layoutSheet,
            columnIndex: 0,
            rowIndex: 3 + r,
            value: rowLabel,
            style: _plateHeaderStyle,
          );

          for (int c = 0; c < colCount; c++) {
            final raw = layout[r][c];
            final display = raw.isEmpty ? '-' : raw;

            _setCellByIndex(
              layoutSheet,
              columnIndex: c + 1,
              rowIndex: 3 + r,
              value: display,
              style: _plateStyleForValue(display),
            );
          }
        }
      }

      for (int i = 0; i < 15; i++) {
        layoutSheet.setColumnWidth(i, 12);
      }

      final saveDir = await _getSaveDirectory();
      final fileName = _buildBaseFileName(
        cellLine: cellLine,
        assayType: assayType,
        cultureWare: cultureWare,
      );

      final filePath = _buildUniqueFilePath(
        directoryPath: saveDir.path,
        fileName: fileName,
      );

      final bytes = excel.encode();
      if (bytes == null) return null;

      final file = File(filePath);
      await file.writeAsBytes(bytes, flush: true);

      return file.path;
    } catch (e, st) {
      print('Excel export error: $e');
      print(st);
      return null;
    }
  }

  static Future<Directory> _getSaveDirectory() async {
    if (Platform.isAndroid) {
      final dir = await getExternalStorageDirectory();
      if (dir != null) return dir;
    }
    return getApplicationDocumentsDirectory();
  }

  static String _buildBaseFileName({
    required String cellLine,
    required String assayType,
    required String cultureWare,
  }) {
    final safeCellLine = _sanitizeFileName(cellLine);
    final safeAssay = _sanitizeFileName(assayType);
    final safeWare = _sanitizeFileName(cultureWare);
    final timestamp = _buildTimestamp();

    return '${safeCellLine}_${safeAssay}_${safeWare}_$timestamp.xlsx';
  }

  static String _sanitizeFileName(String input) {
    return input
        .trim()
        .replaceAll(RegExp(r'[\\/:*?"<>|]'), '_')
        .replaceAll(RegExp(r'\s+'), '_');
  }

  static String _buildTimestamp() {
    final now = DateTime.now();
    final y = now.year.toString().padLeft(4, '0');
    final m = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
    final hh = now.hour.toString().padLeft(2, '0');
    final mm = now.minute.toString().padLeft(2, '0');
    final ss = now.second.toString().padLeft(2, '0');
    return '${y}${m}${d}_${hh}${mm}${ss}';
  }

  static String _buildUniqueFilePath({
    required String directoryPath,
    required String fileName,
  }) {
    final extension = p.extension(fileName);
    final baseName = p.basenameWithoutExtension(fileName);

    var candidatePath = p.join(directoryPath, fileName);
    var index = 1;

    while (File(candidatePath).existsSync()) {
      candidatePath = p.join(directoryPath, '${baseName}_$index$extension');
      index++;
    }

    return candidatePath;
  }
}