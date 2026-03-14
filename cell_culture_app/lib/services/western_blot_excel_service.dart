import 'dart:io';

import 'package:excel/excel.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class WesternBlotExcelService {
  static int _replicateCountFromMode(String mode) {
    switch (mode) {
      case 'Single':
        return 1;
      case 'Duplicate':
        return 2;
      case 'Triplicate':
      default:
        return 3;
    }
  }

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
    required String standardReplicateMode,
    required String sampleReplicateMode,
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
    required List<Map<String, dynamic>> standards,
    required List<Map<String, dynamic>> samples,
  }) async {
    final excel = Excel.createExcel();

    final overviewSheet = excel['Overview'];
    final standardSheet = excel['BCA Standards'];
    final sampleSheet = excel['BCA Samples'];
    final processSheet = excel['Process Summary'];

    final standardReplicateCount =
        _replicateCountFromMode(standardReplicateMode);
    final sampleReplicateCount =
        _replicateCountFromMode(sampleReplicateMode);

    String wellLabel(int count) => count == 1 ? '1 well' : '$count wells';

    void writeRow(Sheet sheet, int rowIndex, List<dynamic> values) {
      for (int col = 0; col < values.length; col++) {
        final value = values[col];
        final cell = sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: col, rowIndex: rowIndex),
        );

        if (value is int) {
          cell.value = IntCellValue(value);
        } else if (value is double) {
          cell.value = DoubleCellValue(value);
        } else if (value is num) {
          cell.value = DoubleCellValue(value.toDouble());
        } else {
          cell.value = TextCellValue(value.toString());
        }
      }
    }

    void writeKeyValueRows(
      Sheet sheet,
      int startRow,
      List<List<dynamic>> rows,
    ) {
      for (int i = 0; i < rows.length; i++) {
        writeRow(sheet, startRow + i, rows[i]);
      }
    }

    writeKeyValueRows(overviewSheet, 0, [
      ['Field', 'Value'],
      ['Experiment ID', experimentId],
      ['Operator', operatorName],
      ['Sample count', sampleCount],
      ['Sample type', sampleType],
      ['Target form', targetForm],
      ['BCA format', bcaFormat],
      ['BCA assay completed', bcaCompleted ? 'Yes' : 'No'],
      [
        'Standard replicate mode',
        '$standardReplicateMode (${wellLabel(standardReplicateCount)})',
      ],
      [
        'Sample replicate mode',
        '$sampleReplicateMode (${wellLabel(sampleReplicateCount)})',
      ],
      ['BCA wavelength (nm)', bcaWavelengthNm],
      ['BCA incubation', bcaIncubationCondition],
      ['Use blank correction', useBlankCorrection ? 'Yes' : 'No'],
      ['Blank absorbance', blankAbsorbance],
      ['Standard slope', standardSlope],
      ['Standard intercept', standardIntercept],
      ['Standard unit', standardUnit],
      ['Loading amount (µg)', loadingProteinAmountUg],
      ['Notes', notes],
    ]);

    writeKeyValueRows(processSheet, 0, [
      ['Field', 'Value'],
      ['Lysis buffer', lysisBuffer],
      ['Gel type', gelType],
      ['Gel percent', gelPercent],
      ['Transfer method', transferMethod],
      ['Membrane', membrane],
      ['Transfer condition', transferCondition],
      ['Blocking buffer', blockingBuffer],
      ['Blocking time (min)', blockingTimeMin],
      ['Primary antibody', primaryAntibody],
      ['Primary host', primaryHost],
      ['Primary dilution', primaryDilution],
      ['Primary incubation', primaryIncubation],
      ['Secondary antibody', secondaryAntibody],
      ['Secondary detail', secondaryDetail],
      ['Secondary dilution', secondaryDilution],
      ['Secondary incubation', secondaryIncubation],
      ['PBST used', pbstUsed ? 'Yes' : 'No'],
      ['Wash count', washCount],
      ['Wash time (min)', washTimeMin],
      ['Chemiluminescence', chemiluminescence],
      ['Detection system', detectionSystem],
      ['Loading control included', loadingControlIncluded ? 'Yes' : 'No'],
      ['Film scan saved', filmScanSaved ? 'Yes' : 'No'],
    ]);

    final standardHeader = <dynamic>[
      'No',
      'Label',
      'Replicate mode',
      'Concentration ($standardUnit)',
    ];

    for (int i = 0; i < standardReplicateCount; i++) {
      standardHeader.add('Abs ${i + 1}');
    }

    standardHeader.addAll([
      'Average absorbance',
      'Corrected average',
    ]);

    writeRow(standardSheet, 0, standardHeader);

    for (int i = 0; i < standards.length; i++) {
      final row = standards[i];
      final absorbances =
          (row['absorbances'] as List?)
                  ?.map((e) => (e as num).toDouble())
                  .toList() ??
              <double>[];

      final excelRow = <dynamic>[
        i + 1,
        'Standard ${i + 1}',
        '$standardReplicateMode (${wellLabel(standardReplicateCount)})',
        row['concentrationUgPerMl'] ?? 0,
      ];

      for (int r = 0; r < standardReplicateCount; r++) {
        excelRow.add(r < absorbances.length ? absorbances[r] : 0);
      }

      excelRow.addAll([
        row['averageAbsorbance'] ?? 0,
        row['correctedAverageAbsorbance'] ?? 0,
      ]);

      writeRow(standardSheet, i + 1, excelRow);
    }

    final sampleHeader = <dynamic>[
      'No',
      'Sample name',
      'Replicate mode',
    ];

    for (int i = 0; i < sampleReplicateCount; i++) {
      sampleHeader.add('Raw absorbance ${i + 1}');
    }

    sampleHeader.addAll([
      'Average raw absorbance',
      'Corrected absorbance',
      'Dilution factor',
      'Calculated concentration (µg/µL)',
      'Loading volume (µL)',
    ]);

    writeRow(sampleSheet, 0, sampleHeader);

    for (int i = 0; i < samples.length; i++) {
      final row = samples[i];
      final absorbances =
          (row['absorbances'] as List?)
                  ?.map((e) => (e as num).toDouble())
                  .toList() ??
              <double>[];

      final excelRow = <dynamic>[
        i + 1,
        row['sampleName'] ?? '',
        '$sampleReplicateMode (${wellLabel(sampleReplicateCount)})',
      ];

      for (int r = 0; r < sampleReplicateCount; r++) {
        excelRow.add(r < absorbances.length ? absorbances[r] : 0);
      }

      excelRow.addAll([
        row['averageAbsorbance'] ?? 0,
        row['correctedAbsorbance'] ?? 0,
        row['dilutionFactor'] ?? 1,
        row['calculatedConcentrationUgPerUl'] ?? 0,
        row['loadingVolumeUl'] ?? 0,
      ]);

      writeRow(sampleSheet, i + 1, excelRow);
    }

    for (int i = 0; i < 14; i++) {
      overviewSheet.setColumnWidth(i, 24);
      processSheet.setColumnWidth(i, 24);
      standardSheet.setColumnWidth(i, 18);
      sampleSheet.setColumnWidth(i, 20);
    }

    final dir = await getApplicationDocumentsDirectory();
    final safeExperimentId =
        experimentId.trim().isEmpty ? 'western_blot' : experimentId.trim();
    final timestamp = DateTime.now()
        .toIso8601String()
        .replaceAll(':', '-')
        .replaceAll('.', '-');

    final fileName = '${safeExperimentId}_$timestamp.xlsx';
    final filePath = p.join(dir.path, fileName);

    final bytes = excel.encode();
    if (bytes == null) return null;

    final file = File(filePath);
    await file.writeAsBytes(bytes, flush: true);

    return file.path;
  }
}