import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/mrna_cdna_calculator.dart';
import '../services/mrna_cdna_excel_service.dart';

class MrnaCdnaTemplatePage extends StatefulWidget {
  const MrnaCdnaTemplatePage({super.key});

  @override
  State<MrnaCdnaTemplatePage> createState() => _MrnaCdnaTemplatePageState();
}

class _MrnaCdnaTemplatePageState extends State<MrnaCdnaTemplatePage> {
  final TextEditingController sampleCountController =
      TextEditingController(text: '8');
  final TextEditingController cdnaReplicateController =
      TextEditingController(text: '1');
  final TextEditingController extraPercentController =
      TextEditingController(text: '10');

  final TextEditingController inputRnaNgController =
      TextEditingController(text: '500');
  final TextEditingController reactionVolumeController =
      TextEditingController(text: '20');
  final TextEditingController fixedMixVolumeController =
      TextEditingController(text: '10');
  final TextEditingController defaultElutionVolumeController =
      TextEditingController(text: '30');

  final TextEditingController experimentIdController = TextEditingController();
  final TextEditingController operatorController = TextEditingController();
  final TextEditingController kitNameController = TextEditingController();
  final TextEditingController notesController = TextEditingController();

  List<MrnaSampleRow> samples = [];

  int get sampleCount => int.tryParse(sampleCountController.text) ?? 0;

  int get cdnaReplicateCount =>
      int.tryParse(cdnaReplicateController.text) ?? 1;

  double get extraPercent =>
      (double.tryParse(extraPercentController.text) ?? 0) / 100.0;

  double get inputRnaNg =>
      double.tryParse(inputRnaNgController.text) ?? 500.0;

  double get reactionVolume =>
      double.tryParse(reactionVolumeController.text) ?? 20.0;

  double get fixedMixVolume =>
      double.tryParse(fixedMixVolumeController.text) ?? 10.0;

  double get defaultElutionVolume =>
      double.tryParse(defaultElutionVolumeController.text) ?? 30.0;

  double get adjustedReactionCount => MrnaCdnaCalculator.adjustedReactionCount(
        replicateCount: cdnaReplicateCount,
        extraPercent: extraPercent,
      );

  double get totalRequiredRnaNgPerSample =>
      MrnaCdnaCalculator.totalRequiredRnaNgPerSample(
        inputRnaNgPerReaction: inputRnaNg,
        replicateCount: cdnaReplicateCount,
        extraPercent: extraPercent,
      );

  @override
  void initState() {
    super.initState();
    syncSamplesFromInput();
  }

  @override
  void dispose() {
    sampleCountController.dispose();
    cdnaReplicateController.dispose();
    extraPercentController.dispose();
    inputRnaNgController.dispose();
    reactionVolumeController.dispose();
    fixedMixVolumeController.dispose();
    defaultElutionVolumeController.dispose();

    experimentIdController.dispose();
    operatorController.dispose();
    kitNameController.dispose();
    notesController.dispose();
    super.dispose();
  }

  void syncSamplesFromInput() {
    final count = sampleCount;

    if (count < 0) return;

    if (samples.length < count) {
      for (int i = samples.length; i < count; i++) {
        samples.add(
          MrnaSampleRow(
            sampleName: 'Sample ${i + 1}',
            concentrationNgPerUl: 0,
            elutionVolumeUl: defaultElutionVolume,
          ),
        );
      }
    } else if (samples.length > count) {
      samples = samples.sublist(0, count);
    }

    setState(() {});
  }

  void resetSampleDefaults() {
    setState(() {
      for (int i = 0; i < samples.length; i++) {
        samples[i] = MrnaSampleRow(
          sampleName: samples[i].sampleName,
          concentrationNgPerUl: samples[i].concentrationNgPerUl,
          elutionVolumeUl: defaultElutionVolume,
        );
      }
    });
  }

  double totalYieldNg(MrnaSampleRow row) => MrnaCdnaCalculator.totalYieldNg(
        concentrationNgPerUl: row.concentrationNgPerUl,
        elutionVolumeUl: row.elutionVolumeUl,
      );

  double requiredRnaVolumePerReactionUl(MrnaSampleRow row) =>
      MrnaCdnaCalculator.requiredRnaVolumePerReactionUl(
        inputRnaNgPerReaction: inputRnaNg,
        concentrationNgPerUl: row.concentrationNgPerUl,
      );

  double totalRequiredRnaVolumeUl(MrnaSampleRow row) =>
      MrnaCdnaCalculator.totalRequiredRnaVolumeUl(
        totalRequiredRnaNgPerSample: totalRequiredRnaNgPerSample,
        concentrationNgPerUl: row.concentrationNgPerUl,
      );

  double waterPerReactionUl(MrnaSampleRow row) =>
      MrnaCdnaCalculator.waterPerReactionUl(
        reactionVolumeUl: reactionVolume,
        fixedMixVolumeUl: fixedMixVolume,
        requiredRnaVolumePerReactionUl: requiredRnaVolumePerReactionUl(row),
      );

  double remainingRnaNg(MrnaSampleRow row) => MrnaCdnaCalculator.remainingRnaNg(
        totalYieldNg: totalYieldNg(row),
        totalRequiredRnaNgPerSample: totalRequiredRnaNgPerSample,
      );

  bool isEnoughYield(MrnaSampleRow row) => MrnaCdnaCalculator.isEnoughYield(
        totalYieldNg: totalYieldNg(row),
        totalRequiredRnaNgPerSample: totalRequiredRnaNgPerSample,
      );

  bool isVolumeValid(MrnaSampleRow row) => MrnaCdnaCalculator.isVolumeValid(
        waterPerReactionUl: waterPerReactionUl(row),
      );

  bool isReady(MrnaSampleRow row) => MrnaCdnaCalculator.isReady(
        concentrationNgPerUl: row.concentrationNgPerUl,
        totalYieldNg: totalYieldNg(row),
        totalRequiredRnaNgPerSample: totalRequiredRnaNgPerSample,
        waterPerReactionUl: waterPerReactionUl(row),
      );

  Color statusColor(MrnaSampleRow row) {
    if (isReady(row)) return Colors.green.shade100;
    if (row.concentrationNgPerUl <= 0) return Colors.grey.shade200;
    if (!isEnoughYield(row)) return Colors.orange.shade100;
    if (!isVolumeValid(row)) return Colors.red.shade100;
    return Colors.grey.shade100;
  }

  String statusText(MrnaSampleRow row) {
    if (row.concentrationNgPerUl <= 0) return 'No concentration';
    if (!isEnoughYield(row)) return 'Low yield';
    if (!isVolumeValid(row)) return 'RNA volume too high';
    return 'Ready';
  }

  Future<void> editSampleDialog(int index) async {
    final row = samples[index];

    final nameController = TextEditingController(text: row.sampleName);
    final concentrationController = TextEditingController(
      text: row.concentrationNgPerUl == 0
          ? ''
          : row.concentrationNgPerUl.toString(),
    );
    final elutionController = TextEditingController(
      text: row.elutionVolumeUl.toString(),
    );

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit ${row.sampleName}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Sample name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: concentrationController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'mRNA concentration (ng/µL)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: elutionController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Elution volume (µL)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  samples[index] = MrnaSampleRow(
                    sampleName: nameController.text.trim().isEmpty
                        ? 'Sample ${index + 1}'
                        : nameController.text.trim(),
                    concentrationNgPerUl:
                        double.tryParse(concentrationController.text) ?? 0,
                    elutionVolumeUl:
                        double.tryParse(elutionController.text) ??
                            defaultElutionVolume,
                  );
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
      final path = await MrnaCdnaExcelService.export(
        sampleCount: sampleCount,
        cdnaReplicateCount: cdnaReplicateCount,
        extraPercent: extraPercent,
        inputRnaNg: inputRnaNg,
        reactionVolume: reactionVolume,
        fixedMixVolume: fixedMixVolume,
        defaultElutionVolume: defaultElutionVolume,
        experimentId: experimentIdController.text.trim(),
        operator: operatorController.text.trim(),
        kitName: kitNameController.text.trim(),
        notes: notesController.text.trim(),
        samples: samples.map((e) => e.toMap()).toList(),
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
      debugPrint('mRNA cDNA export error: $e');
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
    VoidCallback? onChanged,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      onChanged: (_) {
        if (onChanged != null) onChanged();
        setState(() {});
      },
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
        item(Colors.green.shade100, 'Ready'),
        item(Colors.orange.shade100, 'Low yield'),
        item(Colors.red.shade100, 'RNA volume too high'),
        item(Colors.grey.shade200, 'No concentration'),
      ],
    );
  }

  Widget buildSummaryCard() {
    final readyCount = samples.where(isReady).length;
    final lowYieldCount = samples
        .where((e) => e.concentrationNgPerUl > 0 && !isEnoughYield(e))
        .length;
    final badVolumeCount = samples
        .where((e) => e.concentrationNgPerUl > 0 && !isVolumeValid(e))
        .length;
    final noConcentrationCount =
        samples.where((e) => e.concentrationNgPerUl <= 0).length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            infoRow('Sample count', '$sampleCount'),
            infoRow('cDNA reactions / sample', '$cdnaReplicateCount'),
            infoRow(
              'Extra applied',
              '${(extraPercent * 100).toStringAsFixed(1)} %',
            ),
            infoRow(
              'Adjusted reaction count',
              adjustedReactionCount.toStringAsFixed(2),
            ),
            infoRow(
              'Target RNA / reaction',
              '${inputRnaNg.toStringAsFixed(2)} ng',
            ),
            infoRow(
              'Total required RNA / sample',
              '${totalRequiredRnaNgPerSample.toStringAsFixed(2)} ng',
            ),
            const Divider(),
            infoRow('Ready samples', '$readyCount'),
            infoRow('Low yield samples', '$lowYieldCount'),
            infoRow('Invalid volume samples', '$badVolumeCount'),
            infoRow('No concentration samples', '$noConcentrationCount'),
          ],
        ),
      ),
    );
  }

  Widget buildReactionCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            infoRow(
              'Total reaction volume',
              '${reactionVolume.toStringAsFixed(2)} µL',
            ),
            infoRow(
              'Fixed mix volume',
              '${fixedMixVolume.toStringAsFixed(2)} µL',
            ),
            infoRow(
              'Max RNA + water space',
              '${(reactionVolume - fixedMixVolume).toStringAsFixed(2)} µL',
            ),
            infoRow(
              'Target RNA input',
              '${inputRnaNg.toStringAsFixed(2)} ng / reaction',
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
              'Total yield (ng) = Concentration (ng/µL) × Elution volume (µL)',
            ),
            infoRow(
              'Formula 2',
              'Adjusted reaction count = Replicates × (1 + extra %)',
            ),
            infoRow(
              'Formula 3',
              'Required RNA / sample (ng) = RNA input / reaction × adjusted reaction count',
            ),
            infoRow(
              'Formula 4',
              'RNA volume / reaction = RNA input (ng) ÷ Concentration (ng/µL)',
            ),
            infoRow(
              'Formula 5',
              'Water / reaction = Total reaction volume - Fixed mix volume - RNA volume',
            ),
            infoRow(
              'Formula 6',
              'Remaining RNA = Total yield - Required RNA / sample',
            ),
          ],
        ),
      ),
    );
  }

  Widget buildSampleCard(int index, MrnaSampleRow row) {
    final totalYield = totalYieldNg(row);
    final rnaVolPerRxn = requiredRnaVolumePerReactionUl(row);
    final totalRnaVol = totalRequiredRnaVolumeUl(row);
    final water = waterPerReactionUl(row);
    final remain = remainingRnaNg(row);

    return Card(
      color: statusColor(row),
      child: InkWell(
        onTap: () => editSampleDialog(index),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      row.sampleName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Chip(
                    label: Text(statusText(row)),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              infoRow(
                'Concentration',
                '${row.concentrationNgPerUl.toStringAsFixed(2)} ng/µL',
              ),
              infoRow(
                'Elution volume',
                '${row.elutionVolumeUl.toStringAsFixed(2)} µL',
              ),
              infoRow(
                'Total yield',
                '${totalYield.toStringAsFixed(2)} ng',
              ),
              const Divider(),
              infoRow(
                'Required RNA / sample',
                '${totalRequiredRnaNgPerSample.toStringAsFixed(2)} ng',
              ),
              infoRow(
                'RNA volume / reaction',
                '${rnaVolPerRxn.toStringAsFixed(2)} µL',
              ),
              infoRow(
                'Total RNA volume needed',
                '${totalRnaVol.toStringAsFixed(2)} µL',
              ),
              infoRow(
                'Water / reaction',
                '${water.toStringAsFixed(2)} µL',
              ),
              infoRow(
                'Remaining RNA',
                '${remain.toStringAsFixed(2)} ng',
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'Tap to edit',
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('mRNA → cDNA Template'),
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
              buildTextField(
                label: 'Sample count',
                controller: sampleCountController,
                keyboardType: TextInputType.number,
                onChanged: syncSamplesFromInput,
              ),
              const SizedBox(height: 12),
              buildTextField(
                label: 'cDNA reactions per sample',
                controller: cdnaReplicateController,
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

              buildSectionTitle('cDNA Reaction Setup'),
              const SizedBox(height: 8),
              buildTextField(
                label: 'Target RNA input per reaction (ng)',
                controller: inputRnaNgController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 12),
              buildTextField(
                label: 'Total reaction volume (µL)',
                controller: reactionVolumeController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 12),
              buildTextField(
                label: 'Fixed mix volume except RNA/water (µL)',
                controller: fixedMixVolumeController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 12),
              buildTextField(
                label: 'Default elution volume (µL)',
                controller: defaultElutionVolumeController,
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
                label: 'Operator',
                controller: operatorController,
              ),
              const SizedBox(height: 12),
              buildTextField(
                label: 'Kit name',
                controller: kitNameController,
              ),
              const SizedBox(height: 12),
              buildTextField(
                label: 'Notes',
                controller: notesController,
              ),
              const SizedBox(height: 20),

              buildSectionTitle('Calculated Result'),
              const SizedBox(height: 8),
              buildSummaryCard(),
              const SizedBox(height: 12),

              buildSectionTitle('Reaction Summary'),
              const SizedBox(height: 8),
              buildReactionCard(),
              const SizedBox(height: 20),

              buildSectionTitle('Sample Status'),
              const SizedBox(height: 8),
              buildLegend(),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: syncSamplesFromInput,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Sync Sample Count'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: resetSampleDefaults,
                      icon: const Icon(Icons.tune),
                      label: const Text('Reset Elution Vol'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              if (samples.isEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      '샘플 수를 입력하면 샘플 카드가 생성됩니다.',
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                  ),
                )
              else
                ...List.generate(
                  samples.length,
                  (index) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: buildSampleCard(index, samples[index]),
                  ),
                ),

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

class MrnaSampleRow {
  final String sampleName;
  final double concentrationNgPerUl;
  final double elutionVolumeUl;

  const MrnaSampleRow({
    required this.sampleName,
    required this.concentrationNgPerUl,
    required this.elutionVolumeUl,
  });

  Map<String, dynamic> toMap() {
    return {
      'sampleName': sampleName,
      'concentrationNgPerUl': concentrationNgPerUl,
      'elutionVolumeUl': elutionVolumeUl,
    };
  }
}