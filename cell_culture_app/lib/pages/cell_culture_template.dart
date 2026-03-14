import 'package:flutter/material.dart';
import '../models/plate_drag_data.dart';
import '../services/cell_culture_calculator.dart';
import '../services/cell_culture_layout_service.dart';
import '../services/cell_culture_excel_service.dart';

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

  List<List<String>> editablePlateLayout = [];
  bool autoGenerateLayout = true;

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

  double get seedingVolumePerUnit =>
      double.tryParse(seedingVolumeController.text) ?? 0.0;

  double get stockConcentration =>
      double.tryParse(stockConcentrationController.text) ?? 0.0;

  double get extraPercent =>
      (double.tryParse(extraPercentController.text) ?? 0.0) / 100.0;

  int get cellsPerUnit => CellCultureCalculator.cellsPerUnit(
        surfaceArea: selectedArea,
        seedingDensity: seedingDensity,
      );

  int get totalSampleUnits => CellCultureCalculator.totalSampleUnits(
        sampleCount: sampleCount,
        replicateCount: replicateCount,
      );

  int get totalControlUnits => CellCultureCalculator.totalControlUnits(
        blankCount: blankCount,
        negativeControlCount: negativeControlCount,
        vehicleCount: vehicleCount,
        positiveControlCount: positiveControlCount,
      );

  int get totalCultureUnits => CellCultureCalculator.totalCultureUnits(
        totalSampleUnits: totalSampleUnits,
        totalControlUnits: totalControlUnits,
      );

  int get totalCellsNeeded => CellCultureCalculator.totalCellsNeeded(
        cellsPerUnit: cellsPerUnit,
        totalCultureUnits: totalCultureUnits,
      );

  int get totalCellsNeededWithExtra =>
      CellCultureCalculator.totalCellsNeededWithExtra(
        totalCellsNeeded: totalCellsNeeded,
        extraPercent: extraPercent,
      );

  double get totalSeedingVolume => CellCultureCalculator.totalSeedingVolume(
        seedingVolumePerUnit: seedingVolumePerUnit,
        totalCultureUnits: totalCultureUnits,
      );

  double get totalSeedingVolumeWithExtra =>
      CellCultureCalculator.totalSeedingVolumeWithExtra(
        totalSeedingVolume: totalSeedingVolume,
        extraPercent: extraPercent,
      );

  double get requiredCellSuspensionVolume =>
      CellCultureCalculator.requiredCellSuspensionVolume(
        totalCellsNeeded: totalCellsNeeded,
        stockConcentration: stockConcentration,
      );

  double get requiredCellSuspensionVolumeWithExtra =>
      CellCultureCalculator.requiredCellSuspensionVolume(
        totalCellsNeeded: totalCellsNeededWithExtra,
        stockConcentration: stockConcentration,
      );

  double get requiredMediaVolume => CellCultureCalculator.requiredMediaVolume(
        totalSeedingVolume: totalSeedingVolume,
        requiredCellSuspensionVolume: requiredCellSuspensionVolume,
      );

  double get requiredMediaVolumeWithExtra =>
      CellCultureCalculator.requiredMediaVolume(
        totalSeedingVolume: totalSeedingVolumeWithExtra,
        requiredCellSuspensionVolume: requiredCellSuspensionVolumeWithExtra,
      );

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

  List<List<String>> buildGeneratedLayout() {
    return CellCultureLayoutService.generatePlateLayout(
      ware: selectedWare,
      sampleCount: sampleCount,
      replicates: replicateCount,
      blankCount: blankCount,
      vehicleCount: vehicleCount,
      positiveControlCount: positiveControlCount,
      negativeControlCount: negativeControlCount,
    );
  }

  void syncPlateLayoutFromInputs() {
    if (!autoGenerateLayout) {
      setState(() {});
      return;
    }

    editablePlateLayout = buildGeneratedLayout();
    setState(() {});
  }

  void regenerateLayout() {
    setState(() {
      autoGenerateLayout = true;
      editablePlateLayout = buildGeneratedLayout();
    });
  }

  void clearLayout() {
    setState(() {
      for (int r = 0; r < editablePlateLayout.length; r++) {
        for (int c = 0; c < editablePlateLayout[r].length; c++) {
          editablePlateLayout[r][c] = '';
        }
      }
      autoGenerateLayout = false;
    });
  }

  Future<void> editWellDialog({
    required int row,
    required int col,
  }) async {
    if (editablePlateLayout.isEmpty) return;

    final controller = TextEditingController(
      text: editablePlateLayout[row][col],
    );

    String selectedType = 'Custom';

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit Well ${String.fromCharCode(65 + row)}${col + 1}'),
          content: StatefulBuilder(
            builder: (context, setLocalState) {
              void applyQuickLabel(String value) {
                controller.text = value;
                setLocalState(() {});
              }

              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      value: selectedType,
                      decoration: const InputDecoration(
                        labelText: 'Quick type',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'Custom', child: Text('Custom')),
                        DropdownMenuItem(value: 'Sample', child: Text('Sample')),
                        DropdownMenuItem(value: 'Blank', child: Text('Blank')),
                        DropdownMenuItem(
                          value: 'Negative control',
                          child: Text('Negative control'),
                        ),
                        DropdownMenuItem(
                          value: 'Vehicle',
                          child: Text('Vehicle'),
                        ),
                        DropdownMenuItem(
                          value: 'Positive control',
                          child: Text('Positive control'),
                        ),
                        DropdownMenuItem(value: 'Empty', child: Text('Empty')),
                      ],
                      onChanged: (value) {
                        if (value == null) return;
                        selectedType = value;

                        switch (value) {
                          case 'Blank':
                            applyQuickLabel('BLK');
                            break;
                          case 'Negative control':
                            applyQuickLabel('NC');
                            break;
                          case 'Vehicle':
                            applyQuickLabel('VEH');
                            break;
                          case 'Positive control':
                            applyQuickLabel('PC');
                            break;
                          case 'Empty':
                            applyQuickLabel('');
                            break;
                          default:
                            break;
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: controller,
                      decoration: const InputDecoration(
                        labelText: 'Label',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        OutlinedButton(
                          onPressed: () => applyQuickLabel('BLK'),
                          child: const Text('BLK'),
                        ),
                        OutlinedButton(
                          onPressed: () => applyQuickLabel('NC'),
                          child: const Text('NC'),
                        ),
                        OutlinedButton(
                          onPressed: () => applyQuickLabel('VEH'),
                          child: const Text('VEH'),
                        ),
                        OutlinedButton(
                          onPressed: () => applyQuickLabel('PC'),
                          child: const Text('PC'),
                        ),
                        OutlinedButton(
                          onPressed: () => applyQuickLabel(''),
                          child: const Text('Clear'),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  editablePlateLayout[row][col] = controller.text.trim();
                  autoGenerateLayout = false;
                });
                Navigator.pop(context);
              },
              child: const Text('저장'),
            ),
          ],
        );
      },
    );
  }

  Future<void> exportToExcel() async {
    final path = await CellCultureExcelService.export(
      cellLine: cellLineController.text.trim(),
      assayType: selectedAssay,
      cultureWare: selectedWare,
      surfaceArea: selectedArea,
      workingVolume: selectedVolume,
      seedingDensity: seedingDensity,
      sampleCount: sampleCount,
      replicateCount: replicateCount,
      blankCount: blankCount,
      negativeControlCount: negativeControlCount,
      vehicleCount: vehicleCount,
      positiveControlCount: positiveControlCount,
      totalControlUnits: totalControlUnits,
      totalSampleUnits: totalSampleUnits,
      totalCultureUnits: totalCultureUnits,
      cellsPerUnit: cellsPerUnit,
      totalCellsNeeded: totalCellsNeeded,
      totalCellsNeededWithExtra: totalCellsNeededWithExtra,
      targetConfluency: targetConfluency,
      seedingVolumePerUnit: seedingVolumePerUnit,
      totalSeedingVolume: totalSeedingVolume,
      totalSeedingVolumeWithExtra: totalSeedingVolumeWithExtra,
      stockConcentration: stockConcentration,
      requiredCellSuspensionVolume: requiredCellSuspensionVolume,
      requiredCellSuspensionVolumeWithExtra:
          requiredCellSuspensionVolumeWithExtra,
      requiredMediaVolume: requiredMediaVolume,
      requiredMediaVolumeWithExtra: requiredMediaVolumeWithExtra,
      extraPercent: extraPercent,
      layout: editablePlateLayout,
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          path == null ? '엑셀 저장 실패' : '엑셀 저장 완료: $path',
        ),
      ),
    );
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
      onChanged: (_) => syncPlateLayoutFromInputs(),
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

  Widget buildDraggableWell({
    required int row,
    required int col,
    required String value,
  }) {
    return DragTarget<PlateDragData>(
      onWillAcceptWithDetails: (details) => true,
      onAcceptWithDetails: (details) {
        final from = details.data;
        if (from.row == row && from.col == col) return;

        setState(() {
          CellCultureLayoutService.swapWells(
            layout: editablePlateLayout,
            fromRow: from.row,
            fromCol: from.col,
            toRow: row,
            toCol: col,
          );
          autoGenerateLayout = false;
        });
      },
      builder: (context, candidateData, rejectedData) {
        final isHovering = candidateData.isNotEmpty;

        return LongPressDraggable<PlateDragData>(
          data: PlateDragData(row: row, col: col),
          feedback: Material(
            color: Colors.transparent,
            child: Container(
              width: 78,
              height: 56,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: CellCultureLayoutService.getWellColor(value),
                border: Border.all(color: Colors.black26),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                value.isEmpty ? '-' : value,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          childWhenDragging: Container(
            height: 56,
            alignment: Alignment.center,
            color: Colors.grey.shade200,
            padding: const EdgeInsets.all(6),
            child: Text(
              value.isEmpty ? '-' : value,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
          child: GestureDetector(
            onTap: () => editWellDialog(row: row, col: col),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              height: 56,
              alignment: Alignment.center,
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: isHovering
                    ? Colors.indigo.shade100
                    : CellCultureLayoutService.getWellColor(value),
                border: Border.all(
                  color: isHovering ? Colors.indigo : Colors.grey.shade300,
                  width: isHovering ? 2 : 1,
                ),
              ),
              child: Text(
                value.isEmpty ? '-' : value,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ),
        );
      },
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
                  return buildDraggableWell(
                    row: r,
                    col: c,
                    value: value,
                  );
                }),
              ],
            );
          }),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    applyDefaultDensityByAssay(selectedAssay);
    applyDefaultSeedingVolumeByWare(selectedWare);
    editablePlateLayout = buildGeneratedLayout();
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
    final plateLayout = editablePlateLayout;

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
                  autoGenerateLayout = true;
                });
                syncPlateLayoutFromInputs();
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
                  autoGenerateLayout = true;
                });
                syncPlateLayoutFromInputs();
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
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                autoGenerateLayout
                    ? 'Mode: Auto-generated'
                    : 'Mode: Manually edited',
                style: TextStyle(
                  color: autoGenerateLayout ? Colors.green : Colors.orange,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Tap: edit well  •  Long press & drag: swap wells',
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontSize: 13,
                ),
              ),
            ),
            const SizedBox(height: 8),
            buildLegend(),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: regenerateLayout,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Auto Regenerate'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: clearLayout,
                    icon: const Icon(Icons.clear_all),
                    label: const Text('Clear Layout'),
                  ),
                ),
              ],
            ),
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