import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/plate_drag_data.dart';
import '../services/elisa_calculator.dart';
import '../services/elisa_layout_service.dart';
import '../services/elisa_excel_service.dart';

class ElisaTemplatePage extends StatefulWidget {
  const ElisaTemplatePage({super.key});

  @override
  State<ElisaTemplatePage> createState() => _ElisaTemplatePageState();
}

class _ElisaTemplatePageState extends State<ElisaTemplatePage> {
  // =========================
  // Metadata
  // =========================
  final TextEditingController experimentIdController =
      TextEditingController(text: '');
  final TextEditingController assayNameController =
      TextEditingController(text: 'ELISA Assay');
  final TextEditingController targetAnalyteController =
      TextEditingController(text: '');
  final TextEditingController operatorNameController =
      TextEditingController(text: '');

  // =========================
  // Plate setup
  // =========================
  final TextEditingController sampleCountController =
      TextEditingController(text: '8');
  final TextEditingController sampleReplicateCountController =
      TextEditingController(text: '2');
  final TextEditingController blankCountController =
      TextEditingController(text: '1');
  final TextEditingController negativeControlCountController =
      TextEditingController(text: '1');
  final TextEditingController positiveControlCountController =
      TextEditingController(text: '1');
  final TextEditingController standardCountController =
      TextEditingController(text: '8');
  final TextEditingController standardReplicateCountController =
      TextEditingController(text: '2');

  // =========================
  // Volume / dilution
  // =========================
  final TextEditingController volumePerWellController =
      TextEditingController(text: '100');
  final TextEditingController extraPercentController =
      TextEditingController(text: '10');

  final TextEditingController dilutionFactorController =
      TextEditingController(text: '10');
  final TextEditingController targetDilutionVolumeController =
      TextEditingController(text: '1000');

  // =========================
  // Standard curve
  // =========================
  final TextEditingController standardTopConcentrationController =
      TextEditingController(text: '1000');
  final TextEditingController standardDilutionFactorController =
      TextEditingController(text: '2');

  String selectedPlateType = '96-well plate';

  List<List<String>> editablePlateLayout = [];
  bool autoGenerateLayout = true;

  // =========================
  // Getters
  // =========================
  int get sampleCount => int.tryParse(sampleCountController.text) ?? 0;
  int get sampleReplicateCount =>
      int.tryParse(sampleReplicateCountController.text) ?? 1;
  int get blankCount => int.tryParse(blankCountController.text) ?? 0;
  int get negativeControlCount =>
      int.tryParse(negativeControlCountController.text) ?? 0;
  int get positiveControlCount =>
      int.tryParse(positiveControlCountController.text) ?? 0;
  int get standardCount => int.tryParse(standardCountController.text) ?? 0;
  int get standardReplicateCount =>
      int.tryParse(standardReplicateCountController.text) ?? 1;

  double get volumePerWell =>
      double.tryParse(volumePerWellController.text) ?? 100.0;
  double get extraPercent =>
      (double.tryParse(extraPercentController.text) ?? 0.0) / 100.0;

  double get dilutionFactor =>
      double.tryParse(dilutionFactorController.text) ?? 1.0;
  double get targetDilutionVolume =>
      double.tryParse(targetDilutionVolumeController.text) ?? 0.0;

  double get standardTopConcentration =>
      double.tryParse(standardTopConcentrationController.text) ?? 0.0;
  double get standardDilutionFactor =>
      double.tryParse(standardDilutionFactorController.text) ?? 2.0;

  int get totalSampleWells => ElisaCalculator.totalSampleWells(
        sampleCount: sampleCount,
        replicateCount: sampleReplicateCount,
      );

  int get totalControlWells => ElisaCalculator.totalControlWells(
        blankCount: blankCount,
        negativeControlCount: negativeControlCount,
        positiveControlCount: positiveControlCount,
        standardCount: standardCount,
        standardReplicateCount: standardReplicateCount,
      );

  int get totalWells => ElisaCalculator.totalWells(
        totalSampleWells: totalSampleWells,
        totalControlWells: totalControlWells,
      );

  double get totalVolumeNeeded => ElisaCalculator.totalVolumeNeeded(
        volumePerWell: volumePerWell,
        totalWells: totalWells,
        extraPercent: extraPercent,
      );

  double get stockVolumeForDilution => ElisaCalculator.dilutionVolumeFromStock(
        targetVolume: targetDilutionVolume,
        dilutionFactor: dilutionFactor,
      );

  double get diluentVolumeForDilution => ElisaCalculator.diluentVolume(
        targetVolume: targetDilutionVolume,
        stockVolume: stockVolumeForDilution,
      );

  List<double> get standardCurveConcentrations {
    final values = <double>[];
    if (standardCount <= 0 || standardTopConcentration <= 0) return values;
    if (standardDilutionFactor <= 0) return values;

    for (int i = 0; i < standardCount; i++) {
      values.add(
        standardTopConcentration /
            (i == 0 ? 1 : math.pow(standardDilutionFactor, i)),
      );
    }
    return values;
  }

  // =========================
  // Layout helpers
  // =========================
  List<List<String>> buildGeneratedLayout() {
    return ElisaLayoutService.generatePlateLayout(
      plateType: selectedPlateType,
      sampleCount: sampleCount,
      sampleReplicateCount: sampleReplicateCount,
      blankCount: blankCount,
      negativeControlCount: negativeControlCount,
      positiveControlCount: positiveControlCount,
      standardCount: standardCount,
      standardReplicateCount: standardReplicateCount,
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

  // =========================
  // Edit well
  // =========================
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
          title: Text('Edit Well ${_wellName(row, col)}'),
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
                          value: 'Positive control',
                          child: Text('Positive control'),
                        ),
                        DropdownMenuItem(
                          value: 'Standard',
                          child: Text('Standard'),
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
                          case 'Positive control':
                            applyQuickLabel('PC');
                            break;
                          case 'Standard':
                            applyQuickLabel('STD');
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
                          onPressed: () => applyQuickLabel('PC'),
                          child: const Text('PC'),
                        ),
                        OutlinedButton(
                          onPressed: () => applyQuickLabel('STD'),
                          child: const Text('STD'),
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

  // =========================
  // Export
  // =========================
  Future<void> exportToExcel() async {
    try {
      final path = await ElisaExcelService.export(
        experimentId: experimentIdController.text.trim(),
        assayName: assayNameController.text.trim(),
        targetAnalyte: targetAnalyteController.text.trim(),
        operatorName: operatorNameController.text.trim(),
        plateType: selectedPlateType,
        sampleCount: sampleCount,
        sampleReplicateCount: sampleReplicateCount,
        blankCount: blankCount,
        negativeControlCount: negativeControlCount,
        positiveControlCount: positiveControlCount,
        standardCount: standardCount,
        standardReplicateCount: standardReplicateCount,
        volumePerWell: volumePerWell,
        extraPercent: extraPercent,
        totalSampleWells: totalSampleWells,
        totalControlWells: totalControlWells,
        totalWells: totalWells,
        totalVolumeNeeded: totalVolumeNeeded,
        dilutionFactor: dilutionFactor,
        targetDilutionVolume: targetDilutionVolume,
        stockVolumeForDilution: stockVolumeForDilution,
        diluentVolumeForDilution: diluentVolumeForDilution,
        standardTopConcentration: standardTopConcentration,
        standardDilutionFactor: standardDilutionFactor,
        standardCurveConcentrations: standardCurveConcentrations,
        layout: editablePlateLayout,
      );

      debugPrint('Excel saved path: $path');

      if (!mounted) return;

      if (path == null || path.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('엑셀 저장 실패')),
        );
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 8),
          content: const Text('엑셀 저장 완료'),
          action: SnackBarAction(
            label: '열기',
            onPressed: () async {
              await openSavedExcelFile(path);
            },
          ),
        ),
      );

      await showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('엑셀 저장 완료'),
            content: SelectableText(path),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('닫기'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await openSavedFolder(path);
                },
                child: const Text('폴더 열기'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await openSavedExcelFile(path);
                },
                child: const Text('파일 열기'),
              ),
            ],
          );
        },
      );
    } catch (e, st) {
      debugPrint('Excel export error: $e');
      debugPrint('$st');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('엑셀 저장 중 오류 발생: $e'),
        ),
      );
    }
  }

  Future<void> openSavedExcelFile(String path) async {
    final result = await OpenFilex.open(path);
    debugPrint('Open file result: ${result.type} / ${result.message}');
  }

  Future<void> openSavedFolder(String path) async {
    final directoryPath = File(path).parent.path;
    final uri = Uri.file(directoryPath);

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      debugPrint('Could not open folder: $directoryPath');

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('폴더를 열 수 없습니다: $directoryPath'),
        ),
      );
    }
  }

  // =========================
  // UI helpers
  // =========================
  String _wellName(int row, int col) {
    return '${String.fromCharCode(65 + row)}${col + 1}';
  }

  Widget buildSectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.bold,
        ),
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
        item(Colors.green.shade100, 'Positive control'),
        item(Colors.orange.shade100, 'Standard'),
        item(Colors.grey.shade100, 'Empty'),
      ],
    );
  }

  Widget buildSummaryCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            infoRow('Plate type', selectedPlateType),
            infoRow('Sample count', '$sampleCount'),
            infoRow('Sample replicates', '$sampleReplicateCount'),
            infoRow('Blank count', '$blankCount'),
            infoRow('Negative control count', '$negativeControlCount'),
            infoRow('Positive control count', '$positiveControlCount'),
            infoRow('Standard count', '$standardCount'),
            infoRow('Standard replicates', '$standardReplicateCount'),
            infoRow('Total sample wells', '$totalSampleWells'),
            infoRow('Total control wells', '$totalControlWells'),
            infoRow('Total wells', '$totalWells'),
            infoRow(
              'Total assay volume',
              '${totalVolumeNeeded.toStringAsFixed(2)} µL',
            ),
          ],
        ),
      ),
    );
  }

  Widget buildDilutionCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            infoRow('Dilution factor', '${dilutionFactor.toStringAsFixed(2)} x'),
            infoRow(
              'Target dilution volume',
              '${targetDilutionVolume.toStringAsFixed(2)} µL',
            ),
            infoRow(
              'Required stock volume',
              '${stockVolumeForDilution.toStringAsFixed(2)} µL',
            ),
            infoRow(
              'Required diluent volume',
              '${diluentVolumeForDilution.toStringAsFixed(2)} µL',
            ),
          ],
        ),
      ),
    );
  }

  Widget buildStandardCurveCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            infoRow(
              'Top concentration',
              standardTopConcentration.toStringAsFixed(2),
            ),
            infoRow(
              'Serial dilution factor',
              standardDilutionFactor.toStringAsFixed(2),
            ),
            const Divider(),
            ...List.generate(standardCurveConcentrations.length, (index) {
              return infoRow(
                'STD${index + 1}',
                standardCurveConcentrations[index].toStringAsFixed(4),
              );
            }),
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
              'Total sample wells = Sample count × Sample replicates',
            ),
            infoRow(
              'Formula 2',
              'Total control wells = Blank + NC + PC + (STD × STD replicates)',
            ),
            infoRow(
              'Formula 3',
              'Total wells = Total sample wells + Total control wells',
            ),
            infoRow(
              'Formula 4',
              'Total assay volume = Volume / well × Total wells × (1 + extra %)',
            ),
            infoRow(
              'Formula 5',
              'Stock volume = Target dilution volume ÷ Dilution factor',
            ),
            infoRow(
              'Formula 6',
              'Diluent volume = Target dilution volume - Stock volume',
            ),
            infoRow(
              'Formula 7',
              'STDn concentration = Top concentration ÷ (dilution factor^(n-1))',
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
          ElisaLayoutService.swapWells(
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
                color: ElisaLayoutService.getWellColor(value),
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
                    : ElisaLayoutService.getWellColor(value),
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
            '현재 선택한 plate type은 layout 표시 대상이 아닙니다.',
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

  // =========================
  // Lifecycle
  // =========================
  @override
  void initState() {
    super.initState();
    editablePlateLayout = buildGeneratedLayout();
  }

  @override
  void dispose() {
    experimentIdController.dispose();
    assayNameController.dispose();
    targetAnalyteController.dispose();
    operatorNameController.dispose();

    sampleCountController.dispose();
    sampleReplicateCountController.dispose();
    blankCountController.dispose();
    negativeControlCountController.dispose();
    positiveControlCountController.dispose();
    standardCountController.dispose();
    standardReplicateCountController.dispose();

    volumePerWellController.dispose();
    extraPercentController.dispose();

    dilutionFactorController.dispose();
    targetDilutionVolumeController.dispose();

    standardTopConcentrationController.dispose();
    standardDilutionFactorController.dispose();

    super.dispose();
  }

  // =========================
  // Build
  // =========================
  @override
  Widget build(BuildContext context) {
    final plateLayout = editablePlateLayout;

    return Scaffold(
      appBar: AppBar(
        title: const Text('ELISA Template'),
        actions: [
          IconButton(
            onPressed: exportToExcel,
            icon: const Icon(Icons.table_view),
            tooltip: 'Export Excel',
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              buildSectionTitle('Experiment Information'),
              const SizedBox(height: 8),
              buildTextField(
                label: 'Experiment ID',
                controller: experimentIdController,
              ),
              const SizedBox(height: 12),
              buildTextField(
                label: 'Assay Name',
                controller: assayNameController,
              ),
              const SizedBox(height: 12),
              buildTextField(
                label: 'Target Analyte',
                controller: targetAnalyteController,
              ),
              const SizedBox(height: 12),
              buildTextField(
                label: 'Operator',
                controller: operatorNameController,
              ),
              const SizedBox(height: 20),

              buildSectionTitle('Plate Setup'),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: selectedPlateType,
                decoration: const InputDecoration(
                  labelText: 'Plate type',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(
                    value: '96-well plate',
                    child: Text('96-well plate'),
                  ),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    selectedPlateType = value;
                    autoGenerateLayout = true;
                  });
                  syncPlateLayoutFromInputs();
                },
              ),
              const SizedBox(height: 12),
              buildTextField(
                label: 'Sample count',
                controller: sampleCountController,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              buildTextField(
                label: 'Sample replicates',
                controller: sampleReplicateCountController,
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
                label: 'Positive control count',
                controller: positiveControlCountController,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              buildTextField(
                label: 'Standard count',
                controller: standardCountController,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              buildTextField(
                label: 'Standard replicates',
                controller: standardReplicateCountController,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              buildTextField(
                label: 'Volume per well (µL)',
                controller: volumePerWellController,
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

              buildSectionTitle('Dilution Calculation'),
              const SizedBox(height: 8),
              buildTextField(
                label: 'Dilution factor',
                controller: dilutionFactorController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 12),
              buildTextField(
                label: 'Target dilution volume (µL)',
                controller: targetDilutionVolumeController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 12),
              buildDilutionCard(),
              const SizedBox(height: 20),

              buildSectionTitle('Standard Curve'),
              const SizedBox(height: 8),
              buildTextField(
                label: 'Top concentration',
                controller: standardTopConcentrationController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 12),
              buildTextField(
                label: 'Serial dilution factor',
                controller: standardDilutionFactorController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 12),
              buildStandardCurveCard(),
              const SizedBox(height: 20),

              buildSectionTitle('Calculated Result'),
              const SizedBox(height: 8),
              buildSummaryCard(),
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
              SizedBox(height: MediaQuery.of(context).padding.bottom + 24),
            ],
          ),
        ),
      ),
    );
  }
}