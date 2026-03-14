import 'dart:io';
import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

class PcrTemplatePage extends StatefulWidget {
  const PcrTemplatePage({super.key});

  @override
  State<PcrTemplatePage> createState() => _PcrTemplatePageState();
}

class _PcrTemplatePageState extends State<PcrTemplatePage> {
  final TextEditingController sampleController = TextEditingController(text: '8');
  final TextEditingController controlController = TextEditingController(text: '2');
  final TextEditingController replicateController = TextEditingController(text: '3');
  final TextEditingController extraPercentController = TextEditingController(text: '10');

  final TextEditingController reactionVolumeController = TextEditingController(text: '20');
  final TextEditingController masterMix2xController = TextEditingController(text: '10');
  final TextEditingController forwardPrimerController = TextEditingController(text: '0.5');
  final TextEditingController reversePrimerController = TextEditingController(text: '0.5');
  final TextEditingController templateController = TextEditingController(text: '2');

  List<List<String>> plateLayout = [];

  int get sampleCount => int.tryParse(sampleController.text) ?? 0;
  int get controlCount => int.tryParse(controlController.text) ?? 0;
  int get replicates => int.tryParse(replicateController.text) ?? 3;
  double get extraPercent => (double.tryParse(extraPercentController.text) ?? 10) / 100.0;

  double get reactionVolume => double.tryParse(reactionVolumeController.text) ?? 20.0;
  double get masterMix2x => double.tryParse(masterMix2xController.text) ?? 10.0;
  double get forwardPrimer => double.tryParse(forwardPrimerController.text) ?? 0.5;
  double get reversePrimer => double.tryParse(reversePrimerController.text) ?? 0.5;
  double get templateVolume => double.tryParse(templateController.text) ?? 2.0;

  int get totalWells => (sampleCount * replicates) + controlCount;
  int get mixReactionCount => (totalWells * (1 + extraPercent)).ceil();

  double get waterPerReaction {
    final water = reactionVolume -
        (masterMix2x + forwardPrimer + reversePrimer + templateVolume);
    return water < 0 ? 0 : water;
  }

  double get masterMixPerReaction =>
      masterMix2x + forwardPrimer + reversePrimer + waterPerReaction;

  double get totalMasterMix2x => masterMix2x * mixReactionCount;
  double get totalForwardPrimer => forwardPrimer * mixReactionCount;
  double get totalReversePrimer => reversePrimer * mixReactionCount;
  double get totalWater => waterPerReaction * mixReactionCount;

  double get totalTemplate => templateVolume * totalWells;

  @override
  void initState() {
    super.initState();
    generatePlateLayout();
  }

  void generatePlateLayout() {
    final rows = ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H'];
    final cols = List.generate(12, (index) => index + 1);

    List<List<String>> grid =
        List.generate(8, (_) => List.generate(12, (_) => ''));

    List<String> wells = [];

    for (int i = 1; i <= sampleCount; i++) {
      for (int r = 0; r < replicates; r++) {
        wells.add('S$i');
      }
    }

    for (int i = 1; i <= controlCount; i++) {
      wells.add('CTRL$i');
    }

    for (int i = 0; i < wells.length && i < 96; i++) {
      int row = i ~/ 12;
      int col = i % 12;
      grid[row][col] = wells[i];
    }

    setState(() {
      plateLayout = grid;
    });
  }

  Future<void> exportToExcel() async {
    final excel = Excel.createExcel();

    // ===== Sheet 1: Calculation =====
    final calcSheet = excel['PCR_Calculation'];

    calcSheet.cell(CellIndex.indexByString('A1')).value = TextCellValue('PCR Triplicate Calculator');
    calcSheet.cell(CellIndex.indexByString('A3')).value = TextCellValue('Samples');
    calcSheet.cell(CellIndex.indexByString('B3')).value = IntCellValue(sampleCount);

    calcSheet.cell(CellIndex.indexByString('A4')).value = TextCellValue('Controls');
    calcSheet.cell(CellIndex.indexByString('B4')).value = IntCellValue(controlCount);

    calcSheet.cell(CellIndex.indexByString('A5')).value = TextCellValue('Replicates');
    calcSheet.cell(CellIndex.indexByString('B5')).value = IntCellValue(replicates);

    calcSheet.cell(CellIndex.indexByString('A6')).value = TextCellValue('Extra %');
    calcSheet.cell(CellIndex.indexByString('B6')).value = DoubleCellValue(extraPercent * 100);

    calcSheet.cell(CellIndex.indexByString('A8')).value = TextCellValue('Total Wells');
    calcSheet.cell(CellIndex.indexByString('B8')).value = IntCellValue(totalWells);

    calcSheet.cell(CellIndex.indexByString('A9')).value = TextCellValue('Mix Reaction Count');
    calcSheet.cell(CellIndex.indexByString('B9')).value = IntCellValue(mixReactionCount);

    calcSheet.cell(CellIndex.indexByString('A11')).value = TextCellValue('Reagent');
    calcSheet.cell(CellIndex.indexByString('B11')).value = TextCellValue('Per Reaction (uL)');
    calcSheet.cell(CellIndex.indexByString('C11')).value = TextCellValue('Total (uL)');

    calcSheet.cell(CellIndex.indexByString('A12')).value = TextCellValue('2X Master Mix');
    calcSheet.cell(CellIndex.indexByString('B12')).value = DoubleCellValue(masterMix2x);
    calcSheet.cell(CellIndex.indexByString('C12')).value = DoubleCellValue(totalMasterMix2x);

    calcSheet.cell(CellIndex.indexByString('A13')).value = TextCellValue('Forward Primer');
    calcSheet.cell(CellIndex.indexByString('B13')).value = DoubleCellValue(forwardPrimer);
    calcSheet.cell(CellIndex.indexByString('C13')).value = DoubleCellValue(totalForwardPrimer);

    calcSheet.cell(CellIndex.indexByString('A14')).value = TextCellValue('Reverse Primer');
    calcSheet.cell(CellIndex.indexByString('B14')).value = DoubleCellValue(reversePrimer);
    calcSheet.cell(CellIndex.indexByString('C14')).value = DoubleCellValue(totalReversePrimer);

    calcSheet.cell(CellIndex.indexByString('A15')).value = TextCellValue('Water');
    calcSheet.cell(CellIndex.indexByString('B15')).value = DoubleCellValue(waterPerReaction);
    calcSheet.cell(CellIndex.indexByString('C15')).value = DoubleCellValue(totalWater);

    calcSheet.cell(CellIndex.indexByString('A16')).value = TextCellValue('Template DNA');
    calcSheet.cell(CellIndex.indexByString('B16')).value = DoubleCellValue(templateVolume);
    calcSheet.cell(CellIndex.indexByString('C16')).value = DoubleCellValue(totalTemplate);

    calcSheet.cell(CellIndex.indexByString('A18')).value = TextCellValue('MasterMix / well (without template)');
    calcSheet.cell(CellIndex.indexByString('B18')).value = DoubleCellValue(masterMixPerReaction);

    // ===== Sheet 2: Layout =====
    final layoutSheet = excel['PCR_Layout'];
    final rowNames = ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H'];

    layoutSheet.cell(CellIndex.indexByString('A1')).value = TextCellValue('');
    for (int c = 0; c < 12; c++) {
      layoutSheet
          .cell(CellIndex.indexByColumnRow(columnIndex: c + 1, rowIndex: 0))
          .value = IntCellValue(c + 1);
    }

    for (int r = 0; r < 8; r++) {
      layoutSheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: r + 1))
          .value = TextCellValue(rowNames[r]);

      for (int c = 0; c < 12; c++) {
        layoutSheet
            .cell(CellIndex.indexByColumnRow(columnIndex: c + 1, rowIndex: r + 1))
            .value = TextCellValue(plateLayout[r][c]);
      }
    }

    final bytes = excel.encode();
    if (bytes == null) return;

    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/pcr_template.xlsx');
    await file.writeAsBytes(bytes, flush: true);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('엑셀 저장 완료: ${file.path}')),
    );
  }

  Widget buildInputField(String label, TextEditingController controller) {
    return Expanded(
      child: TextField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        onChanged: (_) => generatePlateLayout(),
      ),
    );
  }

  Widget buildLayoutTable() {
    final rows = ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H'];

    return Table(
      border: TableBorder.all(color: Colors.grey),
      defaultColumnWidth: const FixedColumnWidth(60),
      children: [
        TableRow(
          children: [
            const SizedBox(),
            ...List.generate(
              12,
              (index) => Padding(
                padding: const EdgeInsets.all(8.0),
                child: Center(child: Text('${index + 1}')),
              ),
            ),
          ],
        ),
        ...List.generate(8, (r) {
          return TableRow(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Center(child: Text(rows[r])),
              ),
              ...List.generate(
                12,
                (c) => Padding(
                  padding: const EdgeInsets.all(6.0),
                  child: Center(
                    child: Text(
                      plateLayout.isNotEmpty ? plateLayout[r][c] : '',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ),
              ),
            ],
          );
        }),
      ],
    );
  }

  Widget buildSummaryCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            summaryRow('Total wells', '$totalWells'),
            summaryRow('Mix reaction count', '$mixReactionCount'),
            summaryRow('2X Master Mix total', '${totalMasterMix2x.toStringAsFixed(2)} uL'),
            summaryRow('Forward Primer total', '${totalForwardPrimer.toStringAsFixed(2)} uL'),
            summaryRow('Reverse Primer total', '${totalReversePrimer.toStringAsFixed(2)} uL'),
            summaryRow('Water total', '${totalWater.toStringAsFixed(2)} uL'),
            summaryRow('Template total', '${totalTemplate.toStringAsFixed(2)} uL'),
          ],
        ),
      ),
    );
  }

  Widget summaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  @override
  void dispose() {
    sampleController.dispose();
    controlController.dispose();
    replicateController.dispose();
    extraPercentController.dispose();
    reactionVolumeController.dispose();
    masterMix2xController.dispose();
    forwardPrimerController.dispose();
    reversePrimerController.dispose();
    templateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PCR Template'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                buildInputField('Samples', sampleController),
                const SizedBox(width: 8),
                buildInputField('Controls', controlController),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                buildInputField('Replicates', replicateController),
                const SizedBox(width: 8),
                buildInputField('Extra %', extraPercentController),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                buildInputField('Reaction Vol (uL)', reactionVolumeController),
                const SizedBox(width: 8),
                buildInputField('2X Master Mix', masterMix2xController),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                buildInputField('F Primer', forwardPrimerController),
                const SizedBox(width: 8),
                buildInputField('R Primer', reversePrimerController),
                const SizedBox(width: 8),
                buildInputField('Template', templateController),
              ],
            ),
            const SizedBox(height: 16),
            buildSummaryCard(),
            const SizedBox(height: 16),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '96-well PCR Layout',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: buildLayoutTable(),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: exportToExcel,
              child: const Text('Export Excel'),
            ),
          ],
        ),
      ),
    );
  }
}


// 이 코드에서 되는 것

// 이 파일 하나로 아래가 됩니다.

// 샘플 수, 컨트롤 수, triplicate 수 입력

// 총 well 수 계산

// master mix 준비량 계산

// water 자동 계산

// 96-well plate layout 생성

// 엑셀 시트 2개 생성

// PCR_Calculation

// PCR_Layout