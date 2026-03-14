import 'dart:io';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';

class CellCultureExcelService {
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
    final excel = Excel.createExcel();

    final defaultSheet = excel.getDefaultSheet();
    if (defaultSheet != null && defaultSheet != 'Cell_Culture_Calc') {
      excel.delete(defaultSheet);
    }

    final calcSheet = excel['Cell_Culture_Calc'];
    final inputSheet = excel['Cell_Culture_Input'];
    final layoutSheet = excel['Plate_Layout'];

    void setText(Sheet sheet, String cell, String value) {
      sheet.cell(CellIndex.indexByString(cell)).value = TextCellValue(value);
    }

    void setInt(Sheet sheet, String cell, int value) {
      sheet.cell(CellIndex.indexByString(cell)).value = IntCellValue(value);
    }

    void setDouble(Sheet sheet, String cell, double value) {
      sheet.cell(CellIndex.indexByString(cell)).value = DoubleCellValue(value);
    }

    // =========================
    // Sheet 1: Calculation
    // =========================
    setText(calcSheet, 'A1', 'Cell Culture Seeding Calculator');

    setText(calcSheet, 'A3', 'Basic Information');
    setText(calcSheet, 'A4', 'Cell line');
    setText(calcSheet, 'B4', cellLine);

    setText(calcSheet, 'A5', 'Assay type');
    setText(calcSheet, 'B5', assayType);

    setText(calcSheet, 'A6', 'Culture ware');
    setText(calcSheet, 'B6', cultureWare);

    setText(calcSheet, 'A7', 'Surface area (cm2)');
    setDouble(calcSheet, 'B7', surfaceArea);

    setText(calcSheet, 'A8', 'Working volume');
    setText(calcSheet, 'B8', workingVolume);

    setText(calcSheet, 'A10', 'Seeding Conditions');
    setText(calcSheet, 'A11', 'Seeding density (cells/cm2)');
    setDouble(calcSheet, 'B11', seedingDensity);

    setText(calcSheet, 'A12', 'Target confluency (%)');
    setInt(calcSheet, 'B12', targetConfluency);

    setText(calcSheet, 'A13', 'Sample count');
    setInt(calcSheet, 'B13', sampleCount);

    setText(calcSheet, 'A14', 'Replicates');
    setInt(calcSheet, 'B14', replicateCount);

    setText(calcSheet, 'A15', 'Blank');
    setInt(calcSheet, 'B15', blankCount);

    setText(calcSheet, 'A16', 'Negative control');
    setInt(calcSheet, 'B16', negativeControlCount);

    setText(calcSheet, 'A17', 'Vehicle');
    setInt(calcSheet, 'B17', vehicleCount);

    setText(calcSheet, 'A18', 'Positive control');
    setInt(calcSheet, 'B18', positiveControlCount);

    setText(calcSheet, 'A19', 'Total controls');
    setInt(calcSheet, 'B19', totalControlUnits);

    setText(calcSheet, 'A20', 'Total sample units');
    setInt(calcSheet, 'B20', totalSampleUnits);

    setText(calcSheet, 'A21', 'Total culture units');
    setInt(calcSheet, 'B21', totalCultureUnits);

    setText(calcSheet, 'A22', 'Extra (%)');
    setDouble(calcSheet, 'B22', extraPercent * 100);

    setText(calcSheet, 'A24', 'Cell Requirement');
    setText(calcSheet, 'A25', 'Cells per unit');
    setInt(calcSheet, 'B25', cellsPerUnit);

    setText(calcSheet, 'A26', 'Total cells needed');
    setInt(calcSheet, 'B26', totalCellsNeeded);

    setText(calcSheet, 'A27', 'Total cells needed (+extra)');
    setInt(calcSheet, 'B27', totalCellsNeededWithExtra);

    setText(calcSheet, 'A29', 'Suspension Preparation');
    setText(calcSheet, 'A30', 'Seeding volume per unit (mL)');
    setDouble(calcSheet, 'B30', seedingVolumePerUnit);

    setText(calcSheet, 'A31', 'Total seeding volume (mL)');
    setDouble(calcSheet, 'B31', totalSeedingVolume);

    setText(calcSheet, 'A32', 'Total seeding volume (+extra) (mL)');
    setDouble(calcSheet, 'B32', totalSeedingVolumeWithExtra);

    setText(calcSheet, 'A33', 'Stock concentration (cells/mL)');
    setDouble(calcSheet, 'B33', stockConcentration);

    setText(calcSheet, 'A34', 'Required cell suspension (mL)');
    setDouble(calcSheet, 'B34', requiredCellSuspensionVolume);

    setText(calcSheet, 'A35', 'Required cell suspension (+extra) (mL)');
    setDouble(calcSheet, 'B35', requiredCellSuspensionVolumeWithExtra);

    setText(calcSheet, 'A36', 'Required media volume (mL)');
    setDouble(calcSheet, 'B36', requiredMediaVolume);

    setText(calcSheet, 'A37', 'Required media volume (+extra) (mL)');
    setDouble(calcSheet, 'B37', requiredMediaVolumeWithExtra);

    setText(calcSheet, 'A39', 'Formula Summary');
    setText(calcSheet, 'A40', 'Cells / unit = Surface area × Seeding density');
    setText(calcSheet, 'A41', 'Total sample units = Sample count × Replicates');
    setText(calcSheet, 'A42', 'Total culture units = Total sample units + Total controls');
    setText(calcSheet, 'A43', 'Total cells = Cells / unit × Total culture units');
    setText(calcSheet, 'A44', 'Total cells (+extra) = Total cells × (1 + extra %)');
    setText(calcSheet, 'A45', 'Total seeding volume = Seeding volume / unit × Total culture units');
    setText(calcSheet, 'A46', 'Cell suspension volume = Total cells ÷ Stock concentration');
    setText(calcSheet, 'A47', 'Media volume = Total seeding volume - Cell suspension volume');

    // =========================
    // Sheet 2: Input Summary
    // =========================
    setText(inputSheet, 'A1', 'Input Summary');

    setText(inputSheet, 'A3', 'Cell line');
    setText(inputSheet, 'B3', cellLine);

    setText(inputSheet, 'A4', 'Assay type');
    setText(inputSheet, 'B4', assayType);

    setText(inputSheet, 'A5', 'Culture ware');
    setText(inputSheet, 'B5', cultureWare);

    setText(inputSheet, 'A6', 'Surface area (cm2)');
    setDouble(inputSheet, 'B6', surfaceArea);

    setText(inputSheet, 'A7', 'Working volume');
    setText(inputSheet, 'B7', workingVolume);

    setText(inputSheet, 'A8', 'Seeding density (cells/cm2)');
    setDouble(inputSheet, 'B8', seedingDensity);

    setText(inputSheet, 'A9', 'Target confluency (%)');
    setInt(inputSheet, 'B9', targetConfluency);

    setText(inputSheet, 'A10', 'Sample count');
    setInt(inputSheet, 'B10', sampleCount);

    setText(inputSheet, 'A11', 'Replicates');
    setInt(inputSheet, 'B11', replicateCount);

    setText(inputSheet, 'A12', 'Blank count');
    setInt(inputSheet, 'B12', blankCount);

    setText(inputSheet, 'A13', 'Negative control count');
    setInt(inputSheet, 'B13', negativeControlCount);

    setText(inputSheet, 'A14', 'Vehicle count');
    setInt(inputSheet, 'B14', vehicleCount);

    setText(inputSheet, 'A15', 'Positive control count');
    setInt(inputSheet, 'B15', positiveControlCount);

    setText(inputSheet, 'A16', 'Seeding volume per unit (mL)');
    setDouble(inputSheet, 'B16', seedingVolumePerUnit);

    setText(inputSheet, 'A17', 'Stock concentration (cells/mL)');
    setDouble(inputSheet, 'B17', stockConcentration);

    setText(inputSheet, 'A18', 'Extra (%)');
    setDouble(inputSheet, 'B18', extraPercent * 100);

    // =========================
    // Sheet 3: Plate Layout
    // =========================
    if (layout.isNotEmpty && layout.first.isNotEmpty) {
      setText(layoutSheet, 'A1', 'Cell Culture Plate Layout');

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

      final legendStartRow = rowCount + 5;
      layoutSheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: legendStartRow))
          .value = TextCellValue('Legend');

      layoutSheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: legendStartRow + 1))
          .value = TextCellValue('S#-R# : Sample / Replicate');
      layoutSheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: legendStartRow + 2))
          .value = TextCellValue('BLK# : Blank');
      layoutSheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: legendStartRow + 3))
          .value = TextCellValue('NC# : Negative control');
      layoutSheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: legendStartRow + 4))
          .value = TextCellValue('VEH# : Vehicle');
      layoutSheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: legendStartRow + 5))
          .value = TextCellValue('PC# : Positive control');
    } else {
      setText(layoutSheet, 'A1', 'No plate layout available for selected culture ware');
    }

    final bytes = excel.encode();
    if (bytes == null) return null;

    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/cell_culture_template.xlsx');
    await file.writeAsBytes(bytes, flush: true);

    return file.path;
  }
}