import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/plate_drag_data.dart';
import '../services/pcr_calculator.dart';
import '../services/pcr_excel_service.dart';
import '../services/pcr_layout_service.dart';

class PcrTemplatePage extends StatefulWidget {
  const PcrTemplatePage({super.key});

  @override
  State<PcrTemplatePage> createState() => _PcrTemplatePageState();
}

class _PcrTemplatePageState extends State<PcrTemplatePage> {
  final TextEditingController sampleCountController =
      TextEditingController(text: '8');
  final TextEditingController replicateController =
      TextEditingController(text: '3');
  final TextEditingController ntcCountController =
      TextEditingController(text: '1');
  final TextEditingController positiveControlCountController =
      TextEditingController(text: '1');
  final TextEditingController standardCountController =
      TextEditingController(text: '0');
  final TextEditingController extraPercentController =
      TextEditingController(text: '10');

  final TextEditingController reactionVolumeController =
      TextEditingController(text: '20');
  final TextEditingController masterMix2xController =
      TextEditingController(text: '10');
  final TextEditingController forwardPrimerController =
      TextEditingController(text: '0.5');
  final TextEditingController reversePrimerController =
      TextEditingController(text: '0.5');
  final TextEditingController templateVolumeController =
      TextEditingController(text: '2');

  final TextEditingController experimentIdController = TextEditingController();
  final TextEditingController targetGeneController = TextEditingController();
  final TextEditingController primerNameController = TextEditingController();
  final TextEditingController operatorController = TextEditingController();
  final TextEditingController instrumentController = TextEditingController();

  String selectedPlateType = '96-well plate';

  List<List<String>> editablePlateLayout = [];
  bool autoGenerateLayout = true;

  double get reactionVolume =>
      double.tryParse(reactionVolumeController.text) ?? 20.0;

  double get masterMix2x =>
      double.tryParse(masterMix2xController.text) ?? 10.0;

  double get forwardPrimer =>
      double.tryParse(forwardPrimerController.text) ?? 0.5;

  double get reversePrimer =>
      double.tryParse(reversePrimerController.text) ?? 0.5;

  double get templateVolume =>
      double.tryParse(templateVolumeController.text) ?? 2.0;

  double get extraPercent =>
      (double.tryParse(extraPercentController.text) ?? 0.0) / 100.0;

  int get sampleCount => int.tryParse(sampleCountController.text) ?? 0;
  int get replicateCount => int.tryParse(replicateController.text) ?? 3;
  int get ntcCount => int.tryParse(ntcCountController.text) ?? 0;
  int get positiveControlCount =>
      int.tryParse(positiveControlCountController.text) ?? 0;
  int get standardCount => int.tryParse(standardCountController.text) ?? 0;

  int get controlCount => ntcCount + positiveControlCount + standardCount;

  int get totalWells => PcrCalculator.totalWells(
        sampleCount: sampleCount,
        replicateCount: replicateCount,
        controlCount: controlCount,
      );

  int get mixReactionCount => PcrCalculator.mixReactionCount(
        totalWells: totalWells,
        extraPercent: extraPercent,
      );

  double get waterPerReaction => PcrCalculator.waterPerReaction(
        reactionVolume: reactionVolume,
        masterMix2x: masterMix2x,
        forwardPrimer: forwardPrimer,
        reversePrimer: reversePrimer,
        templateVolume: templateVolume,
      );

  double get masterMixPerReaction => PcrCalculator.masterMixPerReaction(
        masterMix2x: masterMix2x,
        forwardPrimer: forwardPrimer,
        reversePrimer: reversePrimer,
        waterPerReaction: waterPerReaction,
      );

  double get totalMasterMix2x => PcrCalculator.totalReagentVolume(
        perReactionVolume: masterMix2x,
        mixReactionCount: mixReactionCount,
      );

  double get totalForwardPrimer => PcrCalculator.totalReagentVolume(
        perReactionVolume: forwardPrimer,
        mixReactionCount: mixReactionCount,
      );

  double get totalReversePrimer => PcrCalculator.totalReagentVolume(
        perReactionVolume: reversePrimer,
        mixReactionCount: mixReactionCount,
      );

  double get totalWater => PcrCalculator.totalReagentVolume(
        perReactionVolume: waterPerReaction,
        mixReactionCount: mixReactionCount,
      );

  double get totalTemplate => PcrCalculator.totalTemplateVolume(
        templateVolume: templateVolume,
        totalWells: totalWells,
      );

  void syncPlateLayoutFromInputs() {
    if (!autoGenerateLayout) {
      setState(() {});
      return;
    }

    editablePlateLayout = buildGeneratedLayout();
    setState(() {});
  }

  List<List<String>> buildGeneratedLayout() {
    return PcrLayoutService.generatePlateLayout(
      plateType: selectedPlateType,
      sampleCount: sampleCount,
      replicateCount: replicateCount,
      ntcCount: ntcCount,
      positiveControlCount: positiveControlCount,
      standardCount: standardCount,
    );
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
                        DropdownMenuItem(value: 'NTC', child: Text('NTC')),
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
                          case 'NTC':
                            applyQuickLabel('NTC');
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
                          onPressed: () => applyQuickLabel('NTC'),
                          child: const Text('NTC'),
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

  Future<void> exportToExcel() async {
    try {
      final path = await PcrExcelService.export(
        plateType: selectedPlateType,
        sampleCount: sampleCount,
        replicateCount: replicateCount,
        ntcCount: ntcCount,
        positiveControlCount: positiveControlCount,
        standardCount: standardCount,
        extraPercent: extraPercent,
        reactionVolume: reactionVolume,
        masterMix2x: masterMix2x,
        forwardPrimer: forwardPrimer,
        reversePrimer: reversePrimer,
        templateVolume: templateVolume,
        waterPerReaction: waterPerReaction,
        masterMixPerReaction: masterMixPerReaction,
        totalWells: totalWells,
        mixReactionCount: mixReactionCount,
        totalMasterMix2x: totalMasterMix2x,
        totalForwardPrimer: totalForwardPrimer,
        totalReversePrimer: totalReversePrimer,
        totalWater: totalWater,
        totalTemplate: totalTemplate,
        layout: editablePlateLayout,
        experimentId: experimentIdController.text.trim(),
        targetGene: targetGeneController.text.trim(),
        primerName: primerNameController.text.trim(),
        operator: operatorController.text.trim(),
        instrument: instrumentController.text.trim(),
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
        item(Colors.grey.shade300, 'NTC'),
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
            infoRow('Replicates', '$replicateCount'),
            infoRow('NTC count', '$ntcCount'),
            infoRow('Positive control count', '$positiveControlCount'),
            infoRow('Standard count', '$standardCount'),
            infoRow('Total wells', '$totalWells'),
            infoRow('Mix reaction count', '$mixReactionCount'),
            infoRow(
              'Master mix / well',
              '${masterMixPerReaction.toStringAsFixed(2)} µL',
            ),
          ],
        ),
      ),
    );
  }

  Widget buildReagentCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            infoRow(
              'Reaction volume',
              '${reactionVolume.toStringAsFixed(2)} µL',
            ),
            infoRow(
              '2X Master Mix / rxn',
              '${masterMix2x.toStringAsFixed(2)} µL',
            ),
            infoRow(
              'Forward primer / rxn',
              '${forwardPrimer.toStringAsFixed(2)} µL',
            ),
            infoRow(
              'Reverse primer / rxn',
              '${reversePrimer.toStringAsFixed(2)} µL',
            ),
            infoRow(
              'Template / rxn',
              '${templateVolume.toStringAsFixed(2)} µL',
            ),
            infoRow(
              'Water / rxn',
              '${waterPerReaction.toStringAsFixed(2)} µL',
            ),
            const Divider(),
            infoRow(
              '2X Master Mix total',
              '${totalMasterMix2x.toStringAsFixed(2)} µL',
            ),
            infoRow(
              'Forward primer total',
              '${totalForwardPrimer.toStringAsFixed(2)} µL',
            ),
            infoRow(
              'Reverse primer total',
              '${totalReversePrimer.toStringAsFixed(2)} µL',
            ),
            infoRow(
              'Water total',
              '${totalWater.toStringAsFixed(2)} µL',
            ),
            infoRow(
              'Template total',
              '${totalTemplate.toStringAsFixed(2)} µL',
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
              'Total wells = (Sample count × Replicates) + Controls',
            ),
            infoRow(
              'Formula 2',
              'Mix reaction count = Total wells × (1 + extra %)',
            ),
            infoRow(
              'Formula 3',
              'Water / rxn = Reaction volume - (MM + F + R + Template)',
            ),
            infoRow(
              'Formula 4',
              'Total reagent = Per reaction volume × Mix reaction count',
            ),
            infoRow(
              'Formula 5',
              'Template total = Template / rxn × Total wells',
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
          PcrLayoutService.swapWells(
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
                color: PcrLayoutService.getWellColor(value),
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
                    : PcrLayoutService.getWellColor(value),
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

  @override
  void initState() {
    super.initState();
    editablePlateLayout = buildGeneratedLayout();
  }

  @override
  void dispose() {
    sampleCountController.dispose();
    replicateController.dispose();
    ntcCountController.dispose();
    positiveControlCountController.dispose();
    standardCountController.dispose();
    extraPercentController.dispose();
    reactionVolumeController.dispose();
    masterMix2xController.dispose();
    forwardPrimerController.dispose();
    reversePrimerController.dispose();
    templateVolumeController.dispose();

    experimentIdController.dispose();
    targetGeneController.dispose();
    primerNameController.dispose();
    operatorController.dispose();
    instrumentController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final plateLayout = editablePlateLayout;

    return Scaffold(
      appBar: AppBar(
        title: const Text('PCR Template'),
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
              buildSectionTitle('Basic Information'),
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
                  DropdownMenuItem(
                    value: '384-well plate',
                    child: Text('384-well plate'),
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
              const SizedBox(height: 20),

              buildSectionTitle('Plate Setup'),
              const SizedBox(height: 8),
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
                label: 'NTC count',
                controller: ntcCountController,
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
                label: 'Extra (%)',
                controller: extraPercentController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 20),

              buildSectionTitle('Reaction Composition'),
              const SizedBox(height: 8),
              buildTextField(
                label: 'Reaction volume (µL)',
                controller: reactionVolumeController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 12),
              buildTextField(
                label: '2X Master Mix (µL)',
                controller: masterMix2xController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 12),
              buildTextField(
                label: 'Forward Primer (µL)',
                controller: forwardPrimerController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 12),
              buildTextField(
                label: 'Reverse Primer (µL)',
                controller: reversePrimerController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 12),
              buildTextField(
                label: 'Template (µL)',
                controller: templateVolumeController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 20),

              buildSectionTitle('Experiment Information'),
              const SizedBox(height: 8),
              buildTextField(
                label: 'Experiment ID',
                controller: experimentIdController,
              ),
              const SizedBox(height: 12),
              buildTextField(
                label: 'Target Gene',
                controller: targetGeneController,
              ),
              const SizedBox(height: 12),
              buildTextField(
                label: 'Primer Name',
                controller: primerNameController,
              ),
              const SizedBox(height: 12),
              buildTextField(
                label: 'Operator',
                controller: operatorController,
              ),
              const SizedBox(height: 12),
              buildTextField(
                label: 'Instrument',
                controller: instrumentController,
              ),
              const SizedBox(height: 20),

              buildSectionTitle('Calculated Result'),
              const SizedBox(height: 8),
              buildSummaryCard(),
              const SizedBox(height: 12),

              buildSectionTitle('Master Mix Preparation'),
              const SizedBox(height: 8),
              buildReagentCard(),
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