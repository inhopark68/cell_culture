import 'dart:io';
import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(const CellCultureApp());
}

class CellCultureApp extends StatelessWidget {
  const CellCultureApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Cell Culture Template',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const CellCultureTemplatePage(),
    );
  }
}

class CellCultureTemplatePage extends StatefulWidget {
  const CellCultureTemplatePage({super.key});

  @override
  State<CellCultureTemplatePage> createState() =>
      _CellCultureTemplatePageState();
}

class _CellCultureTemplatePageState extends State<CellCultureTemplatePage> {
  final TextEditingController cellLineController =
      TextEditingController(text: 'HeLa');
  final TextEditingController seedingDensityController =
      TextEditingController(text: '50000');
  final TextEditingController sampleCountController =
      TextEditingController(text: '4');
  final TextEditingController replicateController =
      TextEditingController(text: '3');
  final TextEditingController targetConfluencyController =
      TextEditingController(text: '70');
  final TextEditingController seedingVolumeController =
      TextEditingController(text: '0.5');
  final TextEditingController stockConcentrationController =
      TextEditingController(text: '1000000');
  final TextEditingController extraPercentController =
      TextEditingController(text: '10');

  final TextEditingController blankCountController =
      TextEditingController(text: '0');
  final TextEditingController vehicleCountController =
      TextEditingController(text: '0');
  final TextEditingController positiveControlCountController =
      TextEditingController(text: '0');
  final TextEditingController negativeControlCountController =
      TextEditingController(text: '0');

  String selectedAssay = 'qPCR';
  String selectedWare = '24-well plate';

  final Map<String, double> cultureWareAreaMap = {
    '6-well plate': 9.6,
    '12-well plate': 3.8,
    '24-well plate': 1.9,
    '48-well plate': 1.0,
    '96-well plate': 0.32,
    'T25 flask': 25.0,
    'T75 flask': 75.0,
  };

  final Map<String, String> cultureWareVolumeMap = {
    '6-well plate': '2–3 mL/well',
    '12-well plate': '1–1.5 mL/well',
    '24-well plate': '0.5–1 mL/well',
    '48-well plate': '0.2–0.5 mL/well',
    '96-well plate': '0.1–0.2 mL/well',
    'T25 flask': '5–7 mL',
    'T75 flask': '12–15 mL',
  };

  final Map<String, double> defaultDensityByAssay = {
    'Viability assay': 20000,
    'qPCR': 50000,
    'ELISA': 40000,
    'Western blot': 80000,
    'Imaging / IF': 30000,
  };

  final Map<String, double> defaultSeedingVolumeByWare = {
    '6-well plate': 2.0,
    '12-well plate': 1.0,
    '24-well plate': 0.5,
    '48-well plate': 0.3,
    '96-well plate': 0.1,
    'T25 flask': 5.0,
    'T75 flask': 12.0,
  };

  double get selectedArea => cultureWareAreaMap[selectedWare] ?? 0.0;
  String get selectedVolume => cultureWareVolumeMap[selectedWare] ?? '-';

  double get seedingDensity =>
      double.tryParse(seedingDensityController.text) ?? 0.0;

  int get sampleCount => int.tryParse(sampleCountController.text) ?? 0;
  int get replicateCount => int.tryParse(replicateController.text) ?? 1;
  int get targetConfluency =>
      int.tryParse(targetConfluencyController.text) ?? 70;

  int get blankCount => int.tryParse(blankCountController.text) ?? 0;
  int get vehicleCount => int.tryParse(vehicleCountController.text) ?? 0;
  int get positiveControlCount =>
      int.tryParse(positiveControlCountController.text) ?? 0;
  int get negativeControlCount =>
      int.tryParse(negativeControlCountController.text) ?? 0;

  int get totalControlUnits =>
      blankCount + vehicleCount + positiveControlCount + negativeControlCount;

  double get seedingVolumePerUnit =>
      double.tryParse(seedingVolumeController.text) ?? 0.0;

  double get stockConcentration =>
      double.tryParse(stockConcentrationController.text) ?? 0.0;

  double get extraPercent =>
      (double.tryParse(extraPercentController.text) ?? 0.0) / 100.0;

  int get cellsPerUnit => (selectedArea * seedingDensity).round();
  int get totalSampleUnits => sampleCount * replicateCount;
  int get totalCultureUnits => totalSampleUnits + totalControlUnits;
  int get totalCellsNeeded => cellsPerUnit * totalCultureUnits;

  int get totalCellsNeededWithExtra =>
      (totalCellsNeeded * (1 + extraPercent)).ceil();

  double get totalSeedingVolume => seedingVolumePerUnit * totalCultureUnits;

  double get totalSeedingVolumeWithExtra =>
      totalSeedingVolume * (1 + extraPercent);

  double get requiredCellSuspensionVolume {
    if (stockConcentration <= 0) return 0.0;
    return totalCellsNeeded / stockConcentration;
  }

  double get requiredCellSuspensionVolumeWithExtra {
    if (stockConcentration <= 0) return 0.0;
    return totalCellsNeededWithExtra / stockConcentration;
  }

  double get requiredMediaVolume {
    final media = totalSeedingVolume - requiredCellSuspensionVolume;
    return media < 0 ? 0.0 : media;
  }

  double get requiredMediaVolumeWithExtra {
    final media =
        totalSeedingVolumeWithExtra - requiredCellSuspensionVolumeWithExtra;
    return media < 0 ? 0.0 : media;
  }

  String get recommendationText {
    if (selectedWare.contains('96')) {
      return 'High-throughput assay에 적합합니다.';
    } else if (selectedWare.contains('24')) {
      return 'qPCR, ELISA, imaging assay에 많이 사용됩니다.';
    } else if (selectedWare.contains('6')) {
      return 'Protein/RNA harvest가 필요한 assay에 적합합니다.';
    } else if (selectedWare.contains('T25') || selectedWare.contains('T75')) {
      return 'Expansion 또는 대량 세포 확보에 적합합니다.';
    }
    return '선택한 culture ware 조건을 확인하세요.';
  }

  void applyDefaultDensityByAssay(String assay) {
    final density = defaultDensityByAssay[assay];
    if (density != null) {
      seedingDensityController.text = density.toStringAsFixed(0);
    }
  }

  void applyDefaultSeedingVolumeByWare(String ware) {
    final volume = defaultSeedingVolumeByWare[ware];
    if (volume != null) {
      seedingVolumeController.text = volume.toStringAsFixed(1);
    }
  }

  int getPlateRows(String ware) {
    switch (ware) {
      case '6-well plate':
        return 2;
      case '12-well plate':
        return 3;
      case '24-well plate':
        return 4;
      case '48-well plate':
        return 6;
      case '96-well plate':
        return 8;
      default:
        return 0;
    }
  }

  int getPlateCols(String ware) {
    switch (ware) {
      case '6-well plate':
        return 3;
      case '12-well plate':
        return 4;
      case '24-well plate':
        return 6;
      case '48-well plate':
        return 8;
      case '96-well plate':
        return 12;
      default:
        return 0;
    }
  }

  List<List<String>> generatePlateLayout({
    required String ware,
    required int sampleCount,
    required int replicates,
    required int blankCount,
    required int vehicleCount,
    required int positiveControlCount,
    required int negativeControlCount,
  }) {
    final rows = getPlateRows(ware);
    final cols = getPlateCols(ware);

    if (rows == 0 || cols == 0) return [];

    final totalSlots = rows * cols;
    final grid = List.generate(rows, (_) => List.generate(cols, (_) => ''));

    final sampleLabels = <String>[];
    final controlLabels = <String>[];

    for (int s = 1; s <= sampleCount; s++) {
      for (int r = 1; r <= replicates; r++) {
        sampleLabels.add('S$s-R$r');
      }
    }

    for (int i = 1; i <= blankCount; i++) {
      controlLabels.add('BLK$i');
    }
    for (int i = 1; i <= negativeControlCount; i++) {
      controlLabels.add('NC$i');
    }
    for (int i = 1; i <= vehicleCount; i++) {
      controlLabels.add('VEH$i');
    }
    for (int i = 1; i <= positiveControlCount; i++) {
      controlLabels.add('PC$i');
    }

    int controlIndex = 0;
    for (int c = cols - 1; c >= 0; c--) {
      for (int r = 0; r < rows; r++) {
        if (controlIndex >= controlLabels.length) break;
        grid[r][c] = controlLabels[controlIndex];
        controlIndex++;
      }
      if (controlIndex >= controlLabels.length) break;
    }

    int sampleIndex = 0;
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        if (grid[r][c].isNotEmpty) continue;
        if (sampleIndex >= sampleLabels.length) break;
        grid[r][c] = sampleLabels[sampleIndex];
        sampleIndex++;
      }
    }

    if (sampleLabels.length + controlLabels.length > totalSlots) {
      debugPrint('Warning: plate capacity exceeded for $ware');
    }

    return grid;
  }

  Color getWellColor(String value) {
    if (value.isEmpty) return Colors.grey.shade100;
    if (value.startsWith('BLK')) return Colors.grey.shade300;
    if (value.startsWith('NC')) return Colors.red.shade100;
    if (value.startsWith('VEH')) return Colors.yellow.shade100;
    if (value.startsWith('PC')) return Colors.green.shade100;
    if (value.startsWith('S')) return Colors.blue.shade50;
    return Colors.white;
  }

  Widget buildSectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget buildTextField({
    required String label,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      onChanged: (_) => setState(() {}),
    );
  }

  Widget infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Text(label)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildLegend() {
    Widget item(Color color, String label) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 16, height: 16, color: color),
          const SizedBox(width: 6),
          Text(label),
        ],
      );
    }

    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: [
        item(Colors.blue.shade50, 'Sample'),
        item(Colors.grey.shade300, 'Blank'),
        item(Colors.red.shade100, 'Negative control'),
        item(Colors.yellow.shade100, 'Vehicle'),
        item(Colors.green.shade100, 'Positive control'),
        item(Colors.grey.shade100, 'Empty'),
      ],
    );
  }

  Widget buildResultCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            infoRow(
              'Cell line',
              cellLineController.text.trim().isEmpty
                  ? '-'
                  : cellLineController.text.trim(),
            ),
            infoRow('Assay type', selectedAssay),
            infoRow('Culture ware', selectedWare),
            infoRow('Surface area', '${selectedArea.toStringAsFixed(2)} cm²'),
            infoRow('Working volume', selectedVolume),
            infoRow(
              'Seeding density',
              '${seedingDensity.toStringAsFixed(0)} cells/cm²',
            ),
            infoRow('Target confluency', '$targetConfluency %'),
            infoRow('Cells / unit', '$cellsPerUnit cells'),
            infoRow('Sample count', '$sampleCount'),
            infoRow('Replicates', '$replicateCount'),
            infoRow('Blank', '$blankCount'),
            infoRow('Negative control', '$negativeControlCount'),
            infoRow('Vehicle', '$vehicleCount'),
            infoRow('Positive control', '$positiveControlCount'),
            infoRow('Total controls', '$totalControlUnits'),
            infoRow('Total sample units', '$totalSampleUnits'),
            infoRow('Total culture units', '$totalCultureUnits'),
            infoRow('Total cells needed', '$totalCellsNeeded cells'),
            infoRow(
              'Total cells needed (+extra)',
              '$totalCellsNeededWithExtra cells',
            ),
          ],
        ),
      ),
    );
  }

  Widget buildSuspensionCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            infoRow(
              'Seeding volume / unit',
              '${seedingVolumePerUnit.toStringAsFixed(2)} mL',
            ),
            infoRow(
              'Stock concentration',
              '${stockConcentration.toStringAsFixed(0)} cells/mL',
            ),
            infoRow(
              'Extra',
              '${(extraPercent * 100).toStringAsFixed(0)} %',
            ),
            infoRow(
              'Total seeding volume',
              '${totalSeedingVolume.toStringAsFixed(2)} mL',
            ),
            infoRow(
              'Total seeding volume (+extra)',
              '${totalSeedingVolumeWithExtra.toStringAsFixed(2)} mL',
            ),
            infoRow(
              'Required cell suspension',
              '${requiredCellSuspensionVolume.toStringAsFixed(2)} mL',
            ),
            infoRow(
              'Required cell suspension (+extra)',
              '${requiredCellSuspensionVolumeWithExtra.toStringAsFixed(2)} mL',
            ),
            infoRow(
              'Required media volume',
              '${requiredMediaVolume.toStringAsFixed(2)} mL',
            ),
            infoRow(
              'Required media volume (+extra)',
              '${requiredMediaVolumeWithExtra.toStringAsFixed(2)} mL',
            ),
          ],
        ),
      ),
    );
  }

  Widget buildRecommendationCard() {
    return Card(
      color: Colors.blue.shade50,
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.science_outlined),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                recommendationText,
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildFormulaCard() {
    return Card(
      elevation: 0,
      color: Colors.grey.shade100,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            infoRow(
              'Formula 1',
              'Cells / unit = Surface area × Seeding density',
            ),
            infoRow(
              'Formula 2',
              'Total sample units = Sample count × Replicates',
            ),
            infoRow(
              'Formula 3',
              'Total culture units = Total sample units + Total controls',
            ),
            infoRow(
              'Formula 4',
              'Total cells = Cells / unit × Total culture units',
            ),
            infoRow(
              'Formula 5',
              'Total cells (+extra) = Total cells × (1 + extra %)',
            ),
            infoRow(
              'Formula 6',
              'Total seeding volume = Seeding volume / unit × Total culture units',
            ),
            infoRow(
              'Formula 7',
              'Cell suspension volume = Total cells ÷ Stock concentration',
            ),
            infoRow(
              'Formula 8',
              'Media volume = Total seeding volume - Cell suspension volume',
            ),
          ],
        ),
      ),
    );
  }

  Widget buildPlateLayoutTable(List<List<String>> layout) {
    if (layout.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            '현재 선택한 culture ware는 plate layout 표시 대상이 아닙니다.',
            style: TextStyle(color: Colors.grey.shade700),
          ),
        ),
      );
    }

    final rowCount = layout.length;
    final colCount = layout.first.length;
    final rowLabels =
        List.generate(rowCount, (index) => String.fromCharCode(65 + index));

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Table(
        border: TableBorder.all(color: Colors.grey.shade400),
        defaultColumnWidth: const FixedColumnWidth(78),
        children: [
          TableRow(
            children: [
              const SizedBox(),
              ...List.generate(
                colCount,
                (c) => Padding(
                  padding: const EdgeInsets.all(8),
                  child: Center(
                    child: Text(
                      '${c + 1}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
            ],
          ),
          ...List.generate(rowCount, (r) {
            return TableRow(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Center(
                    child: Text(
                      rowLabels[r],
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                ...List.generate(colCount, (c) {
                  final value = layout[r][c];
                  return Container(
                    height: 56,
                    alignment: Alignment.center,
                    color: getWellColor(value),
                    padding: const EdgeInsets.all(6),
                    child: Text(
                      value.isEmpty ? '-' : value,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 12),
                    ),
                  );
                }),
              ],
            );
          }),
        ],
      ),
    );
  }

  Future<void> exportToExcel() async {
    final excel = Excel.createExcel();

    final calcSheet = excel['Cell_Culture_Calc'];
    final inputSheet = excel['Cell_Culture_Input'];
    final layoutSheet = excel['Plate_Layout'];

    final layout = generatePlateLayout(
      ware: selectedWare,
      sampleCount: sampleCount,
      replicates: replicateCount,
      blankCount: blankCount,
      vehicleCount: vehicleCount,
      positiveControlCount: positiveControlCount,
      negativeControlCount: negativeControlCount,
    );

    calcSheet.cell(CellIndex.indexByString('A1')).value =
        TextCellValue('Cell Culture Seeding Calculator');

    calcSheet.cell(CellIndex.indexByString('A3')).value =
        TextCellValue('Cell line');
    calcSheet.cell(CellIndex.indexByString('B3')).value =
        TextCellValue(cellLineController.text.trim());

    calcSheet.cell(CellIndex.indexByString('A4')).value =
        TextCellValue('Assay type');
    calcSheet.cell(CellIndex.indexByString('B4')).value =
        TextCellValue(selectedAssay);

    calcSheet.cell(CellIndex.indexByString('A5')).value =
        TextCellValue('Culture ware');
    calcSheet.cell(CellIndex.indexByString('B5')).value =
        TextCellValue(selectedWare);

    calcSheet.cell(CellIndex.indexByString('A6')).value =
        TextCellValue('Surface area (cm2)');
    calcSheet.cell(CellIndex.indexByString('B6')).value =
        DoubleCellValue(selectedArea);

    calcSheet.cell(CellIndex.indexByString('A7')).value =
        TextCellValue('Working volume');
    calcSheet.cell(CellIndex.indexByString('B7')).value =
        TextCellValue(selectedVolume);

    calcSheet.cell(CellIndex.indexByString('A8')).value =
        TextCellValue('Seeding density (cells/cm2)');
    calcSheet.cell(CellIndex.indexByString('B8')).value =
        DoubleCellValue(seedingDensity);

    calcSheet.cell(CellIndex.indexByString('A9')).value =
        TextCellValue('Target confluency (%)');
    calcSheet.cell(CellIndex.indexByString('B9')).value =
        IntCellValue(targetConfluency);

    calcSheet.cell(CellIndex.indexByString('A10')).value =
        TextCellValue('Sample count');
    calcSheet.cell(CellIndex.indexByString('B10')).value =
        IntCellValue(sampleCount);

    calcSheet.cell(CellIndex.indexByString('A11')).value =
        TextCellValue('Replicates');
    calcSheet.cell(CellIndex.indexByString('B11')).value =
        IntCellValue(replicateCount);

    calcSheet.cell(CellIndex.indexByString('A12')).value =
        TextCellValue('Blank');
    calcSheet.cell(CellIndex.indexByString('B12')).value =
        IntCellValue(blankCount);

    calcSheet.cell(CellIndex.indexByString('A13')).value =
        TextCellValue('Negative control');
    calcSheet.cell(CellIndex.indexByString('B13')).value =
        IntCellValue(negativeControlCount);

    calcSheet.cell(CellIndex.indexByString('A14')).value =
        TextCellValue('Vehicle');
    calcSheet.cell(CellIndex.indexByString('B14')).value =
        IntCellValue(vehicleCount);

    calcSheet.cell(CellIndex.indexByString('A15')).value =
        TextCellValue('Positive control');
    calcSheet.cell(CellIndex.indexByString('B15')).value =
        IntCellValue(positiveControlCount);

    calcSheet.cell(CellIndex.indexByString('A16')).value =
        TextCellValue('Total controls');
    calcSheet.cell(CellIndex.indexByString('B16')).value =
        IntCellValue(totalControlUnits);

    calcSheet.cell(CellIndex.indexByString('A17')).value =
        TextCellValue('Total sample units');
    calcSheet.cell(CellIndex.indexByString('B17')).value =
        IntCellValue(totalSampleUnits);

    calcSheet.cell(CellIndex.indexByString('A18')).value =
        TextCellValue('Total culture units');
    calcSheet.cell(CellIndex.indexByString('B18')).value =
        IntCellValue(totalCultureUnits);

    calcSheet.cell(CellIndex.indexByString('A19')).value =
        TextCellValue('Cells per unit');
    calcSheet.cell(CellIndex.indexByString('B19')).value =
        IntCellValue(cellsPerUnit);

    calcSheet.cell(CellIndex.indexByString('A20')).value =
        TextCellValue('Total cells needed');
    calcSheet.cell(CellIndex.indexByString('B20')).value =
        IntCellValue(totalCellsNeeded);

    calcSheet.cell(CellIndex.indexByString('A21')).value =
        TextCellValue('Extra (%)');
    calcSheet.cell(CellIndex.indexByString('B21')).value =
        DoubleCellValue(extraPercent * 100);

    calcSheet.cell(CellIndex.indexByString('A22')).value =
        TextCellValue('Total cells needed (+extra)');
    calcSheet.cell(CellIndex.indexByString('B22')).value =
        IntCellValue(totalCellsNeededWithExtra);

    calcSheet.cell(CellIndex.indexByString('A24')).value =
        TextCellValue('Seeding volume per unit (mL)');
    calcSheet.cell(CellIndex.indexByString('B24')).value =
        DoubleCellValue(seedingVolumePerUnit);

    calcSheet.cell(CellIndex.indexByString('A25')).value =
        TextCellValue('Total seeding volume (mL)');
    calcSheet.cell(CellIndex.indexByString('B25')).value =
        DoubleCellValue(totalSeedingVolume);

    calcSheet.cell(CellIndex.indexByString('A26')).value =
        TextCellValue('Total seeding volume (+extra) (mL)');
    calcSheet.cell(CellIndex.indexByString('B26')).value =
        DoubleCellValue(totalSeedingVolumeWithExtra);

    calcSheet.cell(CellIndex.indexByString('A27')).value =
        TextCellValue('Stock concentration (cells/mL)');
    calcSheet.cell(CellIndex.indexByString('B27')).value =
        DoubleCellValue(stockConcentration);

    calcSheet.cell(CellIndex.indexByString('A28')).value =
        TextCellValue('Required cell suspension (mL)');
    calcSheet.cell(CellIndex.indexByString('B28')).value =
        DoubleCellValue(requiredCellSuspensionVolume);

    calcSheet.cell(CellIndex.indexByString('A29')).value =
        TextCellValue('Required cell suspension (+extra) (mL)');
    calcSheet.cell(CellIndex.indexByString('B29')).value =
        DoubleCellValue(requiredCellSuspensionVolumeWithExtra);

    calcSheet.cell(CellIndex.indexByString('A30')).value =
        TextCellValue('Required media volume (mL)');
    calcSheet.cell(CellIndex.indexByString('B30')).value =
        DoubleCellValue(requiredMediaVolume);

    calcSheet.cell(CellIndex.indexByString('A31')).value =
        TextCellValue('Required media volume (+extra) (mL)');
    calcSheet.cell(CellIndex.indexByString('B31')).value =
        DoubleCellValue(requiredMediaVolumeWithExtra);

    inputSheet.cell(CellIndex.indexByString('A1')).value =
        TextCellValue('Input Summary');
    inputSheet.cell(CellIndex.indexByString('A3')).value =
        TextCellValue('Cell line');
    inputSheet.cell(CellIndex.indexByString('B3')).value =
        TextCellValue(cellLineController.text.trim());
    inputSheet.cell(CellIndex.indexByString('A4')).value =
        TextCellValue('Assay type');
    inputSheet.cell(CellIndex.indexByString('B4')).value =
        TextCellValue(selectedAssay);
    inputSheet.cell(CellIndex.indexByString('A5')).value =
        TextCellValue('Culture ware');
    inputSheet.cell(CellIndex.indexByString('B5')).value =
        TextCellValue(selectedWare);
    inputSheet.cell(CellIndex.indexByString('A6')).value =
        TextCellValue('Seeding density');
    inputSheet.cell(CellIndex.indexByString('B6')).value =
        DoubleCellValue(seedingDensity);
    inputSheet.cell(CellIndex.indexByString('A7')).value =
        TextCellValue('Sample count');
    inputSheet.cell(CellIndex.indexByString('B7')).value =
        IntCellValue(sampleCount);
    inputSheet.cell(CellIndex.indexByString('A8')).value =
        TextCellValue('Replicates');
    inputSheet.cell(CellIndex.indexByString('B8')).value =
        IntCellValue(replicateCount);
    inputSheet.cell(CellIndex.indexByString('A9')).value =
        TextCellValue('Blank');
    inputSheet.cell(CellIndex.indexByString('B9')).value =
        IntCellValue(blankCount);
    inputSheet.cell(CellIndex.indexByString('A10')).value =
        TextCellValue('Negative control');
    inputSheet.cell(CellIndex.indexByString('B10')).value =
        IntCellValue(negativeControlCount);
    inputSheet.cell(CellIndex.indexByString('A11')).value =
        TextCellValue('Vehicle');
    inputSheet.cell(CellIndex.indexByString('B11')).value =
        IntCellValue(vehicleCount);
    inputSheet.cell(CellIndex.indexByString('A12')).value =
        TextCellValue('Positive control');
    inputSheet.cell(CellIndex.indexByString('B12')).value =
        IntCellValue(positiveControlCount);
    inputSheet.cell(CellIndex.indexByString('A13')).value =
        TextCellValue('Target confluency');
    inputSheet.cell(CellIndex.indexByString('B13')).value =
        IntCellValue(targetConfluency);
    inputSheet.cell(CellIndex.indexByString('A14')).value =
        TextCellValue('Seeding volume per unit');
    inputSheet.cell(CellIndex.indexByString('B14')).value =
        DoubleCellValue(seedingVolumePerUnit);
    inputSheet.cell(CellIndex.indexByString('A15')).value =
        TextCellValue('Stock concentration');
    inputSheet.cell(CellIndex.indexByString('B15')).value =
        DoubleCellValue(stockConcentration);
    inputSheet.cell(CellIndex.indexByString('A16')).value =
        TextCellValue('Extra (%)');
    inputSheet.cell(CellIndex.indexByString('B16')).value =
        DoubleCellValue(extraPercent * 100);

    if (layout.isNotEmpty) {
      layoutSheet.cell(CellIndex.indexByString('A1')).value =
          TextCellValue('Cell Culture Plate Layout');

      for (int c = 0; c < layout.first.length; c++) {
        layoutSheet
            .cell(CellIndex.indexByColumnRow(columnIndex: c + 1, rowIndex: 1))
            .value = IntCellValue(c + 1);
      }

      for (int r = 0; r < layout.length; r++) {
        layoutSheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: r + 2))
            .value = TextCellValue(String.fromCharCode(65 + r));

        for (int c = 0; c < layout[r].length; c++) {
          layoutSheet
              .cell(
                CellIndex.indexByColumnRow(
                  columnIndex: c + 1,
                  rowIndex: r + 2,
                ),
              )
              .value = TextCellValue(layout[r][c]);
        }
      }
    } else {
      layoutSheet.cell(CellIndex.indexByString('A1')).value =
          TextCellValue('No plate layout available for selected culture ware');
    }

    final bytes = excel.encode();
    if (bytes == null) return;

    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/cell_culture_template.xlsx');
    await file.writeAsBytes(bytes, flush: true);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('엑셀 저장 완료: ${file.path}')),
    );
  }

  @override
  void initState() {
    super.initState();
    applyDefaultDensityByAssay(selectedAssay);
    applyDefaultSeedingVolumeByWare(selectedWare);
  }

  @override
  void dispose() {
    cellLineController.dispose();
    seedingDensityController.dispose();
    sampleCountController.dispose();
    replicateController.dispose();
    targetConfluencyController.dispose();
    seedingVolumeController.dispose();
    stockConcentrationController.dispose();
    extraPercentController.dispose();
    blankCountController.dispose();
    vehicleCountController.dispose();
    positiveControlCountController.dispose();
    negativeControlCountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final plateLayout = generatePlateLayout(
      ware: selectedWare,
      sampleCount: sampleCount,
      replicates: replicateCount,
      blankCount: blankCount,
      vehicleCount: vehicleCount,
      positiveControlCount: positiveControlCount,
      negativeControlCount: negativeControlCount,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cell Culture Template'),
        actions: [
          IconButton(
            onPressed: exportToExcel,
            icon: const Icon(Icons.table_view),
            tooltip: 'Export Excel',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            buildSectionTitle('Basic Information'),
            const SizedBox(height: 8),
            buildTextField(
              label: 'Cell line',
              controller: cellLineController,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: selectedAssay,
              decoration: const InputDecoration(
                labelText: 'Assay type',
                border: OutlineInputBorder(),
              ),
              items: defaultDensityByAssay.keys.map((assay) {
                return DropdownMenuItem<String>(
                  value: assay,
                  child: Text(assay),
                );
              }).toList(),
              onChanged: (value) {
                if (value == null) return;
                setState(() {
                  selectedAssay = value;
                  applyDefaultDensityByAssay(value);
                });
              },
            ),
            const SizedBox(height: 20),
            buildSectionTitle('Culture Ware'),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: selectedWare,
              decoration: const InputDecoration(
                labelText: 'Culture ware',
                border: OutlineInputBorder(),
              ),
              items: cultureWareAreaMap.keys.map((ware) {
                return DropdownMenuItem<String>(
                  value: ware,
                  child: Text(ware),
                );
              }).toList(),
              onChanged: (value) {
                if (value == null) return;
                setState(() {
                  selectedWare = value;
                  applyDefaultSeedingVolumeByWare(value);
                });
              },
            ),
            const SizedBox(height: 20),
            buildSectionTitle('Seeding Conditions'),
            const SizedBox(height: 8),
            buildTextField(
              label: 'Seeding density (cells/cm²)',
              controller: seedingDensityController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 12),
            buildTextField(
              label: 'Sample count',
              controller: sampleCountController,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            buildTextField(
              label: 'Replicates',
              controller: replicateController,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            buildTextField(
              label: 'Blank count',
              controller: blankCountController,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            buildTextField(
              label: 'Negative control count',
              controller: negativeControlCountController,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            buildTextField(
              label: 'Vehicle count',
              controller: vehicleCountController,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            buildTextField(
              label: 'Positive control count',
              controller: positiveControlCountController,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            buildTextField(
              label: 'Target confluency (%)',
              controller: targetConfluencyController,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            buildTextField(
              label: 'Seeding volume per unit (mL)',
              controller: seedingVolumeController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 12),
            buildTextField(
              label: 'Cell stock concentration (cells/mL)',
              controller: stockConcentrationController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 12),
            buildTextField(
              label: 'Extra (%)',
              controller: extraPercentController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 20),
            buildSectionTitle('Calculated Result'),
            const SizedBox(height: 8),
            buildResultCard(),
            const SizedBox(height: 12),
            buildSectionTitle('Suspension Preparation'),
            const SizedBox(height: 8),
            buildSuspensionCard(),
            const SizedBox(height: 12),
            buildSectionTitle('Plate Layout'),
            const SizedBox(height: 8),
            buildLegend(),
            const SizedBox(height: 12),
            buildPlateLayoutTable(plateLayout),
            const SizedBox(height: 12),
            buildRecommendationCard(),
            const SizedBox(height: 12),
            buildFormulaCard(),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: exportToExcel,
                icon: const Icon(Icons.download),
                label: const Text('Export Excel'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}