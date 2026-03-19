import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/western_blot_excel_service.dart';

class WesternBlotTemplatePage extends StatefulWidget {
  const WesternBlotTemplatePage({super.key});

  @override
  State<WesternBlotTemplatePage> createState() =>
      _WesternBlotTemplatePageState();
}

class _WesternBlotTemplatePageState extends State<WesternBlotTemplatePage> {
  final TextEditingController experimentIdController = TextEditingController();
  final TextEditingController operatorController = TextEditingController();
  final TextEditingController sampleCountController =
      TextEditingController(text: '6');
  final TextEditingController sampleTypeController =
      TextEditingController(text: 'Cell lysate');
  final TextEditingController lysisBufferController =
      TextEditingController(text: 'RIPA buffer + inhibitor');

  final TextEditingController proteinAmountController =
      TextEditingController(text: '20');
  final TextEditingController gelPercentController =
      TextEditingController(text: '10');
  final TextEditingController transferConditionController =
      TextEditingController(text: '100 V, 60 min');

  final TextEditingController primaryAntibodyController =
      TextEditingController();
  final TextEditingController primaryDilutionController =
      TextEditingController(text: '1:1000');
  final TextEditingController secondaryAntibodyController =
      TextEditingController();
  final TextEditingController secondaryDilutionController =
      TextEditingController(text: '1:5000');

  final TextEditingController blockingTimeController =
      TextEditingController(text: '60');
  final TextEditingController primaryIncubationController =
      TextEditingController(text: 'overnight, 4°C');
  final TextEditingController secondaryIncubationController =
      TextEditingController(text: '60 min, RT');
  final TextEditingController washCountController =
      TextEditingController(text: '3');
  final TextEditingController washTimeController =
      TextEditingController(text: '10');

  final TextEditingController notesController = TextEditingController();
  final TextEditingController customBlockingBufferController =
      TextEditingController();

  // Microplate BCA
  final TextEditingController bcaWavelengthController =
      TextEditingController(text: '562');
  final TextEditingController bcaIncubationController =
      TextEditingController(text: '30 min at 37°C');
  final TextEditingController sampleDilutionFactorController =
      TextEditingController(text: '1');

  // SDS-PAGE gel preparation
  String selectedGelPreparationType = 'Mini hand-cast';
  String selectedGradientRange = '4-20%';
  String selectedGelThickness = '1.0 mm';
  String selectedCombTeeth = '10';

  final TextEditingController gelCountController =
      TextEditingController(text: '1');
  final TextEditingController resolvingPercentController =
      TextEditingController(text: '10');
  final TextEditingController stackingPercentController =
      TextEditingController(text: '4');
  final TextEditingController resolvingVolumePerGelController =
      TextEditingController(text: '4.0');
  final TextEditingController stackingVolumePerGelController =
      TextEditingController(text: '1.5');
  final TextEditingController gelExtraPercentController =
      TextEditingController(text: '10');

  final TextEditingController acrylamideStockPercentController =
      TextEditingController(text: '30');
  final TextEditingController trisResolvingStockController =
      TextEditingController(text: '1.5');
  final TextEditingController trisStackingStockController =
      TextEditingController(text: '0.5');
  final TextEditingController sdsStockPercentController =
      TextEditingController(text: '10');
  final TextEditingController apsStockPercentController =
      TextEditingController(text: '10');

  String selectedTargetForm = 'Phospho form';
  String selectedMembrane = 'Nitrocellulose';
  String selectedBlockingBuffer = '5% BSA';
  String selectedPrimaryHost = 'Rabbit';
  String selectedSecondaryHost = 'Anti-rabbit HRP';
  String selectedChemiluminescence = 'Pico';
  String selectedDetectionSystem = 'LAS system';
  String selectedTransferMethod = 'Wet transfer';
  String selectedGelType = 'SDS-PAGE';
  String selectedBcaFormat = 'Microplate BCA';
  String selectedStandardUnit = 'µg/mL';

  String selectedStandardReplicate = 'Triplicate';
  String selectedSampleReplicate = 'Single';

  bool bcaCompleted = true;
  bool loadingControlIncluded = true;
  bool pbstUsed = true;
  bool filmScanSaved = false;
  bool useBlankCorrection = true;

  List<WesternSampleRow> samples = [];
  List<WesternStandardRow> standards = [];

  int get sampleCount => int.tryParse(sampleCountController.text) ?? 0;

  double get loadingProteinAmountUg =>
      double.tryParse(proteinAmountController.text) ?? 20.0;

  double get gelPercent => double.tryParse(gelPercentController.text) ?? 10.0;

  int get washCount => int.tryParse(washCountController.text) ?? 3;

  int get washTimeMin => int.tryParse(washTimeController.text) ?? 10;

  int get blockingTimeMin => int.tryParse(blockingTimeController.text) ?? 60;

  double get defaultDilutionFactor =>
      double.tryParse(sampleDilutionFactorController.text) ?? 1.0;

  bool get isHandCast => selectedGelPreparationType == 'Mini hand-cast';
  bool get isPrecast => selectedGelPreparationType == 'Gradient precast';

  int get gelCount => int.tryParse(gelCountController.text) ?? 1;

  double get resolvingPercent =>
      double.tryParse(resolvingPercentController.text) ?? 10.0;

  double get stackingPercent =>
      double.tryParse(stackingPercentController.text) ?? 4.0;

  double get resolvingVolumePerGelMl =>
      double.tryParse(resolvingVolumePerGelController.text) ?? 4.0;

  double get stackingVolumePerGelMl =>
      double.tryParse(stackingVolumePerGelController.text) ?? 1.5;

  double get gelExtraPercent =>
      double.tryParse(gelExtraPercentController.text) ?? 10.0;

  double get acrylamideStockPercent =>
      double.tryParse(acrylamideStockPercentController.text) ?? 30.0;

  double get trisResolvingStockM =>
      double.tryParse(trisResolvingStockController.text) ?? 1.5;

  double get trisStackingStockM =>
      double.tryParse(trisStackingStockController.text) ?? 0.5;

  double get sdsStockPercent =>
      double.tryParse(sdsStockPercentController.text) ?? 10.0;

  double get apsStockPercent =>
      double.tryParse(apsStockPercentController.text) ?? 10.0;

  double get resolvingTotalMl =>
      resolvingVolumePerGelMl * gelCount * (1 + gelExtraPercent / 100);

  double get stackingTotalMl =>
      stackingVolumePerGelMl * gelCount * (1 + gelExtraPercent / 100);

  int get standardReplicateCount {
    switch (selectedStandardReplicate) {
      case 'Single':
        return 1;
      case 'Duplicate':
        return 2;
      case 'Triplicate':
      default:
        return 3;
    }
  }

  int get sampleReplicateCount {
    switch (selectedSampleReplicate) {
      case 'Single':
        return 1;
      case 'Duplicate':
        return 2;
      case 'Triplicate':
      default:
        return 3;
    }
  }

  String get standardWellLabel => _wellLabel(standardReplicateCount);

  String get sampleWellLabel => _wellLabel(sampleReplicateCount);

  String get resolvedBlockingBuffer {
    if (selectedBlockingBuffer == 'Custom') {
      final custom = customBlockingBufferController.text.trim();
      return custom.isEmpty ? 'Custom' : custom;
    }
    return selectedBlockingBuffer;
  }

  String _wellLabel(int count) {
    if (count == 1) return '(1 well)';
    return '($count wells)';
  }

  double get blankAbsorbance {
    final blankRow = standards.firstWhere(
      (e) => e.concentrationUgPerMl == 0,
      orElse: () => const WesternStandardRow(
        concentrationUgPerMl: 0,
        absorbances: [0, 0, 0],
      ),
    );
    return blankRow.averageAbsorbance;
  }

  double get standardSlope {
    final points = standards
        .map(
          (e) => (
            x: e.concentrationUgPerMl,
            y: useBlankCorrection
                ? e.averageAbsorbance - blankAbsorbance
                : e.averageAbsorbance,
          ),
        )
        .toList();

    if (points.length < 2) return 0;

    final n = points.length;
    final sumX = points.fold<double>(0, (sum, p) => sum + p.x);
    final sumY = points.fold<double>(0, (sum, p) => sum + p.y);
    final sumXY = points.fold<double>(0, (sum, p) => sum + (p.x * p.y));
    final sumX2 = points.fold<double>(0, (sum, p) => sum + (p.x * p.x));

    final denominator = (n * sumX2) - (sumX * sumX);
    if (denominator == 0) return 0;

    return ((n * sumXY) - (sumX * sumY)) / denominator;
  }

  double get standardIntercept {
    final points = standards
        .map(
          (e) => (
            x: e.concentrationUgPerMl,
            y: useBlankCorrection
                ? e.averageAbsorbance - blankAbsorbance
                : e.averageAbsorbance,
          ),
        )
        .toList();

    if (points.isEmpty) return 0;

    final n = points.length;
    final sumX = points.fold<double>(0, (sum, p) => sum + p.x);
    final sumY = points.fold<double>(0, (sum, p) => sum + p.y);

    final slope = standardSlope;
    return (sumY - (slope * sumX)) / n;
  }

  @override
  void initState() {
    super.initState();
    initializeStandards();
    syncSamplesFromInput();
    applyDefaultGelVolumes();
  }

  @override
  void dispose() {
    experimentIdController.dispose();
    operatorController.dispose();
    sampleCountController.dispose();
    sampleTypeController.dispose();
    lysisBufferController.dispose();
    proteinAmountController.dispose();
    gelPercentController.dispose();
    transferConditionController.dispose();
    primaryAntibodyController.dispose();
    primaryDilutionController.dispose();
    secondaryAntibodyController.dispose();
    secondaryDilutionController.dispose();
    blockingTimeController.dispose();
    primaryIncubationController.dispose();
    secondaryIncubationController.dispose();
    washCountController.dispose();
    washTimeController.dispose();
    notesController.dispose();
    customBlockingBufferController.dispose();
    bcaWavelengthController.dispose();
    bcaIncubationController.dispose();
    sampleDilutionFactorController.dispose();

    gelCountController.dispose();
    resolvingPercentController.dispose();
    stackingPercentController.dispose();
    resolvingVolumePerGelController.dispose();
    stackingVolumePerGelController.dispose();
    gelExtraPercentController.dispose();
    acrylamideStockPercentController.dispose();
    trisResolvingStockController.dispose();
    trisStackingStockController.dispose();
    sdsStockPercentController.dispose();
    apsStockPercentController.dispose();

    super.dispose();
  }

  void initializeStandards() {
    standards = [
      0,
      25,
      125,
      250,
      500,
      750,
      1000,
      1500,
      2000,
    ]
        .map(
          (value) => WesternStandardRow(
            concentrationUgPerMl: value.toDouble(),
            absorbances: List.filled(standardReplicateCount, 0),
          ),
        )
        .toList();
  }

  List<double> resizeAbsorbances(List<double> values, int newCount) {
    final resized = List<double>.from(values);
    if (resized.length < newCount) {
      resized.addAll(List.filled(newCount - resized.length, 0));
    } else if (resized.length > newCount) {
      return resized.sublist(0, newCount);
    }
    return resized;
  }

  bool _hasTrimmedStandardData(int newCount) {
    for (final row in standards) {
      if (row.absorbances.length > newCount) {
        final trimmed = row.absorbances.sublist(newCount);
        if (trimmed.any((e) => e != 0)) return true;
      }
    }
    return false;
  }

  bool _hasTrimmedSampleData(int newCount) {
    for (final row in samples) {
      if (row.absorbances.length > newCount) {
        final trimmed = row.absorbances.sublist(newCount);
        if (trimmed.any((e) => e != 0)) return true;
      }
    }
    return false;
  }

  Future<bool> _confirmReplicateReduction({
    required String title,
    required String message,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('변경'),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }

  Future<void> updateStandardReplicate(String value) async {
    final newCount = switch (value) {
      'Single' => 1,
      'Duplicate' => 2,
      _ => 3,
    };

    if (newCount < standardReplicateCount &&
        _hasTrimmedStandardData(newCount)) {
      final confirmed = await _confirmReplicateReduction(
        title: 'Standard replicate 변경',
        message:
            '현재 standard의 뒤쪽 well 데이터가 입력되어 있습니다.\n'
            '$selectedStandardReplicate $standardWellLabel 에서 '
            '$value ${_wellLabel(newCount)} 로 변경하면 일부 absorbance 값이 삭제됩니다.\n\n'
            '계속하시겠습니까?',
      );

      if (!confirmed) return;
    }

    if (!mounted) return;

    setState(() {
      selectedStandardReplicate = value;
      standards = standards
          .map(
            (e) => e.copyWith(
              absorbances: resizeAbsorbances(e.absorbances, newCount),
            ),
          )
          .toList();
    });
  }

  Future<void> updateSampleReplicate(String value) async {
    final newCount = switch (value) {
      'Single' => 1,
      'Duplicate' => 2,
      _ => 3,
    };

    if (newCount < sampleReplicateCount && _hasTrimmedSampleData(newCount)) {
      final confirmed = await _confirmReplicateReduction(
        title: 'Sample replicate 변경',
        message:
            '현재 sample의 뒤쪽 well 데이터가 입력되어 있습니다.\n'
            '$selectedSampleReplicate $sampleWellLabel 에서 '
            '$value ${_wellLabel(newCount)} 로 변경하면 일부 absorbance 값이 삭제됩니다.\n\n'
            '계속하시겠습니까?',
      );

      if (!confirmed) return;
    }

    if (!mounted) return;

    setState(() {
      selectedSampleReplicate = value;
      samples = samples
          .map(
            (e) => e.copyWith(
              absorbances: resizeAbsorbances(e.absorbances, newCount),
            ),
          )
          .toList();
    });
  }

  void syncSamplesFromInput() {
    final text = sampleCountController.text.trim();
    if (text.isEmpty) return;

    final count = int.tryParse(text);
    if (count == null || count < 0) return;

    if (samples.length < count) {
      for (int i = samples.length; i < count; i++) {
        samples.add(
          WesternSampleRow(
            sampleName: 'Sample ${i + 1}',
            absorbances: List.filled(sampleReplicateCount, 0),
            dilutionFactor: defaultDilutionFactor,
          ),
        );
      }
    } else if (samples.length > count) {
      samples = samples.sublist(0, count);
    }

    setState(() {});
  }

  void applyDefaultDilutionFactorToAll() {
    setState(() {
      for (int i = 0; i < samples.length; i++) {
        samples[i] = samples[i].copyWith(
          dilutionFactor: defaultDilutionFactor,
        );
      }
    });
  }

  void applyDefaultGelVolumes() {
    double resolving = 4.0;
    double stacking = 1.5;

    if (selectedGelThickness == '0.75 mm') {
      if (selectedCombTeeth == '10') {
        resolving = 3.5;
        stacking = 1.2;
      } else if (selectedCombTeeth == '15') {
        resolving = 3.8;
        stacking = 1.3;
      }
    } else if (selectedGelThickness == '1.0 mm') {
      if (selectedCombTeeth == '10') {
        resolving = 4.0;
        stacking = 1.5;
      } else if (selectedCombTeeth == '15') {
        resolving = 4.4;
        stacking = 1.7;
      }
    } else if (selectedGelThickness == '1.5 mm') {
      if (selectedCombTeeth == '10') {
        resolving = 5.5;
        stacking = 2.0;
      } else if (selectedCombTeeth == '15') {
        resolving = 6.0;
        stacking = 2.3;
      }
    }

    resolvingVolumePerGelController.text = resolving.toStringAsFixed(1);
    stackingVolumePerGelController.text = stacking.toStringAsFixed(1);
  }

  GelMixRecipe calculateResolvingRecipe() {
    const trisFinalM = 0.375;
    const sdsFinalPercent = 0.1;
    const apsFinalPercent = 0.05;
    const temedFraction = 0.0005;

    final totalMl = resolvingTotalMl;

    final acrylamideMl = totalMl * (resolvingPercent / acrylamideStockPercent);
    final trisMl = totalMl * (trisFinalM / trisResolvingStockM);
    final sdsMl = totalMl * (sdsFinalPercent / sdsStockPercent);
    final apsMl = totalMl * (apsFinalPercent / apsStockPercent);
    final temedMl = totalMl * temedFraction;
    final waterMl =
        totalMl - acrylamideMl - trisMl - sdsMl - apsMl - temedMl;

    return GelMixRecipe(
      totalMl: totalMl,
      acrylamideMl: acrylamideMl,
      trisMl: trisMl,
      sdsMl: sdsMl,
      apsMl: apsMl,
      temedMl: temedMl,
      waterMl: waterMl,
    );
  }

  GelMixRecipe calculateStackingRecipe() {
    const trisFinalM = 0.125;
    const sdsFinalPercent = 0.1;
    const apsFinalPercent = 0.05;
    const temedFraction = 0.0005;

    final totalMl = stackingTotalMl;

    final acrylamideMl = totalMl * (stackingPercent / acrylamideStockPercent);
    final trisMl = totalMl * (trisFinalM / trisStackingStockM);
    final sdsMl = totalMl * (sdsFinalPercent / sdsStockPercent);
    final apsMl = totalMl * (apsFinalPercent / apsStockPercent);
    final temedMl = totalMl * temedFraction;
    final waterMl =
        totalMl - acrylamideMl - trisMl - sdsMl - apsMl - temedMl;

    return GelMixRecipe(
      totalMl: totalMl,
      acrylamideMl: acrylamideMl,
      trisMl: trisMl,
      sdsMl: sdsMl,
      apsMl: apsMl,
      temedMl: temedMl,
      waterMl: waterMl,
    );
  }

  String formatMlOrUl(double valueMl) {
    if (valueMl >= 1) {
      return '${valueMl.toStringAsFixed(2)} mL';
    }
    return '${(valueMl * 1000).toStringAsFixed(1)} µL';
  }

  double correctedAbsorbance(WesternSampleRow row) {
    final raw = row.rawAbsorbance;
    if (!useBlankCorrection) return raw;
    return raw - blankAbsorbance;
  }

  double calculatedProteinConcentrationUgPerUl(WesternSampleRow row) {
    final corrected = correctedAbsorbance(row);

    if (standardSlope == 0) return 0;

    final concentrationUgPerMl =
        (corrected - standardIntercept) / standardSlope;

    if (concentrationUgPerMl <= 0) return 0;

    final adjustedUgPerMl = concentrationUgPerMl * row.dilutionFactor;

    return adjustedUgPerMl / 1000.0;
  }

  double calculateLoadingVolume(double concentrationUgPerUl) {
    if (concentrationUgPerUl <= 0) return 0;
    return loadingProteinAmountUg / concentrationUgPerUl;
  }

  bool isSampleReady(WesternSampleRow row) {
    final conc = calculatedProteinConcentrationUgPerUl(row);
    return conc > 0 && calculateLoadingVolume(conc) > 0;
  }

  Color sampleStatusColor(WesternSampleRow row) {
    final conc = calculatedProteinConcentrationUgPerUl(row);

    if (row.rawAbsorbance <= 0) {
      return Colors.grey.shade200;
    }
    if (conc <= 0) {
      return Colors.red.shade100;
    }
    if (calculateLoadingVolume(conc) > 30) {
      return Colors.orange.shade100;
    }
    return Colors.green.shade100;
  }

  String sampleStatusText(WesternSampleRow row) {
    final conc = calculatedProteinConcentrationUgPerUl(row);

    if (row.rawAbsorbance <= 0) {
      return 'No BCA result';
    }
    if (conc <= 0) {
      return 'Invalid curve result';
    }
    if (calculateLoadingVolume(conc) > 30) {
      return 'High loading volume';
    }
    return 'Ready';
  }

  Future<void> editSampleDialog(int index) async {
    final row = samples[index];

    final nameController = TextEditingController(text: row.sampleName);
    final dilutionController = TextEditingController(
      text: row.dilutionFactor.toString(),
    );

    final absorbanceControllers = List.generate(
      sampleReplicateCount,
      (i) => TextEditingController(
        text: i < row.absorbances.length && row.absorbances[i] != 0
            ? row.absorbances[i].toString()
            : '',
      ),
    );

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit ${row.sampleName} $sampleWellLabel'),
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
                ...List.generate(sampleReplicateCount, (i) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: TextField(
                      controller: absorbanceControllers[i],
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: 'Raw absorbance ${i + 1} (A562)',
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  );
                }),
                TextField(
                  controller: dilutionController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Dilution factor',
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
                  samples[index] = WesternSampleRow(
                    sampleName: nameController.text.trim().isEmpty
                        ? 'Sample ${index + 1}'
                        : nameController.text.trim(),
                    absorbances: absorbanceControllers
                        .map((c) => double.tryParse(c.text) ?? 0)
                        .toList(),
                    dilutionFactor:
                        double.tryParse(dilutionController.text) ?? 1,
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

    nameController.dispose();
    dilutionController.dispose();
    for (final c in absorbanceControllers) {
      c.dispose();
    }
  }

  Future<void> editStandardDialog(int index) async {
    final row = standards[index];

    final concentrationController = TextEditingController(
      text: row.concentrationUgPerMl.toString(),
    );

    final absorbanceControllers = List.generate(
      standardReplicateCount,
      (i) => TextEditingController(
        text: i < row.absorbances.length && row.absorbances[i] != 0
            ? row.absorbances[i].toString()
            : '',
      ),
    );

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit Standard ${index + 1} $standardWellLabel'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: concentrationController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Concentration (µg/mL)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                ...List.generate(standardReplicateCount, (i) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: TextField(
                      controller: absorbanceControllers[i],
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: 'Absorbance ${i + 1}',
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  );
                }),
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
                  standards[index] = WesternStandardRow(
                    concentrationUgPerMl:
                        double.tryParse(concentrationController.text) ?? 0,
                    absorbances: absorbanceControllers
                        .map((c) => double.tryParse(c.text) ?? 0)
                        .toList(),
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

    concentrationController.dispose();
    for (final c in absorbanceControllers) {
      c.dispose();
    }
  }

  Future<void> exportToExcel() async {
    try {
      final resolvingRecipe = isHandCast ? calculateResolvingRecipe() : null;
      final stackingRecipe = isHandCast ? calculateStackingRecipe() : null;

      final path = await WesternBlotExcelService.export(
        experimentId: experimentIdController.text.trim(),
        operatorName: operatorController.text.trim(),
        sampleCount: sampleCount,
        sampleType: sampleTypeController.text.trim(),
        lysisBuffer: lysisBufferController.text.trim(),
        targetForm: selectedTargetForm,
        bcaFormat: selectedBcaFormat,
        bcaCompleted: bcaCompleted,
        bcaWavelengthNm: double.tryParse(bcaWavelengthController.text) ?? 562,
        bcaIncubationCondition: bcaIncubationController.text.trim(),
        useBlankCorrection: useBlankCorrection,
        blankAbsorbance: blankAbsorbance,
        standardSlope: standardSlope,
        standardIntercept: standardIntercept,
        standardUnit: selectedStandardUnit,
        standardReplicateMode: selectedStandardReplicate,
        sampleReplicateMode: selectedSampleReplicate,
        loadingProteinAmountUg: loadingProteinAmountUg,
        gelType: selectedGelType,
        gelPercent: gelPercent,
        gelPreparationType: selectedGelPreparationType,
        gradientRange: isPrecast ? selectedGradientRange : '',
        gelThickness: selectedGelThickness,
        combTeeth: selectedCombTeeth,
        gelCount: gelCount,
        resolvingPercent: isHandCast ? resolvingPercent : 0,
        stackingPercent: isHandCast ? stackingPercent : 0,
        resolvingVolumePerGelMl: isHandCast ? resolvingVolumePerGelMl : 0,
        stackingVolumePerGelMl: isHandCast ? stackingVolumePerGelMl : 0,
        gelExtraPercent: isHandCast ? gelExtraPercent : 0,
        resolvingTotalMl: isHandCast ? resolvingTotalMl : 0,
        stackingTotalMl: isHandCast ? stackingTotalMl : 0,
        resolvingRecipe: resolvingRecipe == null
            ? null
            : {
                'totalMl': resolvingRecipe.totalMl,
                'acrylamideMl': resolvingRecipe.acrylamideMl,
                'trisMl': resolvingRecipe.trisMl,
                'sdsMl': resolvingRecipe.sdsMl,
                'apsMl': resolvingRecipe.apsMl,
                'temedMl': resolvingRecipe.temedMl,
                'waterMl': resolvingRecipe.waterMl,
              },
        stackingRecipe: stackingRecipe == null
            ? null
            : {
                'totalMl': stackingRecipe.totalMl,
                'acrylamideMl': stackingRecipe.acrylamideMl,
                'trisMl': stackingRecipe.trisMl,
                'sdsMl': stackingRecipe.sdsMl,
                'apsMl': stackingRecipe.apsMl,
                'temedMl': stackingRecipe.temedMl,
                'waterMl': stackingRecipe.waterMl,
              },
        transferMethod: selectedTransferMethod,
        membrane: selectedMembrane,
        transferCondition: transferConditionController.text.trim(),
        blockingBuffer: resolvedBlockingBuffer,
        blockingTimeMin: blockingTimeMin,
        primaryAntibody: primaryAntibodyController.text.trim(),
        primaryHost: selectedPrimaryHost,
        primaryDilution: primaryDilutionController.text.trim(),
        primaryIncubation: primaryIncubationController.text.trim(),
        secondaryAntibody: selectedSecondaryHost,
        secondaryDetail: secondaryAntibodyController.text.trim(),
        secondaryDilution: secondaryDilutionController.text.trim(),
        secondaryIncubation: secondaryIncubationController.text.trim(),
        pbstUsed: pbstUsed,
        washCount: washCount,
        washTimeMin: washTimeMin,
        chemiluminescence: selectedChemiluminescence,
        detectionSystem: selectedDetectionSystem,
        loadingControlIncluded: loadingControlIncluded,
        filmScanSaved: filmScanSaved,
        notes: notesController.text.trim(),
        standards: standards
            .map(
              (e) => {
                ...e.toMap(),
                'correctedAverageAbsorbance': useBlankCorrection
                    ? e.averageAbsorbance - blankAbsorbance
                    : e.averageAbsorbance,
              },
            )
            .toList(),
        samples: samples
            .map(
              (e) => {
                ...e.toMap(),
                'correctedAbsorbance': correctedAbsorbance(e),
                'calculatedConcentrationUgPerUl':
                    calculatedProteinConcentrationUgPerUl(e),
                'loadingVolumeUl': calculateLoadingVolume(
                  calculatedProteinConcentrationUgPerUl(e),
                ),
              },
            )
            .toList(),
      );

      debugPrint('Western blot excel saved path: $path');

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
      debugPrint('Western blot export error: $e');
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
    if (kIsWeb) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('웹에서는 폴더 열기를 지원하지 않습니다.')),
      );
      return;
    }

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
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
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

  Widget buildDropdownField({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      items: items
          .map(
            (e) => DropdownMenuItem(
              value: e,
              child: Text(e),
            ),
          )
          .toList(),
      onChanged: onChanged,
    );
  }

  Widget buildSwitchTile({
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title),
      value: value,
      onChanged: onChanged,
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

  Widget buildSummaryCard() {
    final readyCount = samples.where(isSampleReady).length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            infoRow('Target form', selectedTargetForm),
            infoRow('Sample count', '$sampleCount'),
            infoRow('Sample type', sampleTypeController.text.trim()),
            infoRow('BCA format', selectedBcaFormat),
            infoRow(
              'Standard replicate',
              '$selectedStandardReplicate $standardWellLabel',
            ),
            infoRow(
              'Sample replicate',
              '$selectedSampleReplicate $sampleWellLabel',
            ),
            infoRow('BCA assay', bcaCompleted ? 'Completed' : 'Pending'),
            infoRow(
              'Loading amount',
              '${loadingProteinAmountUg.toStringAsFixed(2)} µg/lane',
            ),
            infoRow('Gel type', selectedGelType),
            infoRow('Gel preparation', selectedGelPreparationType),
            if (isPrecast) infoRow('Gradient range', selectedGradientRange),
            if (isHandCast)
              infoRow(
                'Resolving / stacking',
                '${resolvingPercent.toStringAsFixed(1)}% / ${stackingPercent.toStringAsFixed(1)}%',
              ),
            infoRow('Thickness', selectedGelThickness),
            infoRow('Comb teeth', selectedCombTeeth),
            infoRow('Gel percentage', '${gelPercent.toStringAsFixed(1)} %'),
            infoRow('Transfer method', selectedTransferMethod),
            infoRow('Membrane', selectedMembrane),
            infoRow('Blocking buffer', resolvedBlockingBuffer),
            infoRow('Chemiluminescence', selectedChemiluminescence),
            infoRow('Detection', selectedDetectionSystem),
            infoRow('Ready samples', '$readyCount / ${samples.length}'),
          ],
        ),
      ),
    );
  }

  Widget buildProcessCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            infoRow('Lysis buffer', lysisBufferController.text.trim()),
            infoRow('Primary antibody', primaryAntibodyController.text.trim()),
            infoRow('Primary host', selectedPrimaryHost),
            infoRow('Primary dilution', primaryDilutionController.text.trim()),
            infoRow('Secondary antibody', selectedSecondaryHost),
            infoRow(
              'Secondary detail',
              secondaryAntibodyController.text.trim(),
            ),
            infoRow(
              'Secondary dilution',
              secondaryDilutionController.text.trim(),
            ),
            infoRow('Blocking time', '$blockingTimeMin min'),
            infoRow('Blocking buffer', resolvedBlockingBuffer),
            infoRow(
              'Primary incubation',
              primaryIncubationController.text.trim(),
            ),
            infoRow(
              'Secondary incubation',
              secondaryIncubationController.text.trim(),
            ),
            infoRow(
              'Washing',
              pbstUsed
                  ? 'PBST, $washCount × ${washTimeMin} min'
                  : '$washCount × ${washTimeMin} min',
            ),
            infoRow(
              'Transfer condition',
              transferConditionController.text.trim(),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildBcaProtocolCard() {
    return Card(
      color: Colors.grey.shade100,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            infoRow('BCA format', selectedBcaFormat),
            infoRow(
              'Standard replicate',
              '$selectedStandardReplicate $standardWellLabel',
            ),
            infoRow(
              'Sample replicate',
              '$selectedSampleReplicate $sampleWellLabel',
            ),
            infoRow('Read wavelength', '${bcaWavelengthController.text} nm'),
            infoRow('Blank correction', useBlankCorrection ? 'Yes' : 'No'),
            infoRow('Blank absorbance', blankAbsorbance.toStringAsFixed(3)),
            infoRow(
              'Standard curve',
              'y = ${standardSlope.toStringAsFixed(6)}x + ${standardIntercept.toStringAsFixed(6)}',
            ),
            infoRow('Standard unit', selectedStandardUnit),
            infoRow('BCA incubation', bcaIncubationController.text.trim()),
          ],
        ),
      ),
    );
  }

  Widget buildResultCard() {
    final needsScan = selectedDetectionSystem == 'X-ray film';

    return Card(
      color: Colors.grey.shade100,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            infoRow(
              'Detection output',
              selectedDetectionSystem == 'X-ray film'
                  ? 'Film developing'
                  : 'Digital image capture',
            ),
            infoRow('Film scan required', needsScan ? 'Yes' : 'No'),
            infoRow(
              'Film scan saved',
              needsScan ? (filmScanSaved ? 'Saved' : 'Not saved') : 'N/A',
            ),
            infoRow(
              'Loading control',
              loadingControlIncluded ? 'Included' : 'Not included',
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
              'Corrected absorbance = Average raw absorbance - Blank',
            ),
            infoRow(
              'Formula 2',
              'Protein concentration (µg/mL) = (Corrected absorbance - Intercept) ÷ Slope',
            ),
            infoRow(
              'Formula 3',
              'Adjusted concentration = Calculated concentration × Dilution factor',
            ),
            infoRow(
              'Formula 4',
              'Protein concentration (µg/µL) = Adjusted concentration (µg/mL) ÷ 1000',
            ),
            infoRow(
              'Formula 5',
              'Loading volume (µL) = Target protein amount (µg) ÷ Protein concentration (µg/µL)',
            ),
            infoRow(
              'Formula 6',
              'If X-ray film is used, scan file should be saved after developing',
            ),
          ],
        ),
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
        item(Colors.orange.shade100, 'High loading volume'),
        item(Colors.red.shade100, 'Invalid curve result'),
        item(Colors.grey.shade200, 'No BCA result'),
      ],
    );
  }

  Widget buildGelRecipeCard({
    required String title,
    required String trisLabel,
    required GelMixRecipe recipe,
  }) {
    return Card(
      color: Colors.grey.shade100,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 12),
            infoRow('Total volume', formatMlOrUl(recipe.totalMl)),
            infoRow('30% Acrylamide/Bis', formatMlOrUl(recipe.acrylamideMl)),
            infoRow(trisLabel, formatMlOrUl(recipe.trisMl)),
            infoRow('10% SDS', formatMlOrUl(recipe.sdsMl)),
            infoRow('10% APS', formatMlOrUl(recipe.apsMl)),
            infoRow('TEMED', formatMlOrUl(recipe.temedMl)),
            infoRow('DW', formatMlOrUl(recipe.waterMl)),
          ],
        ),
      ),
    );
  }

  Widget buildSampleCard(int index, WesternSampleRow row) {
    final corrected = correctedAbsorbance(row);
    final conc = calculatedProteinConcentrationUgPerUl(row);
    final loadingVolume = calculateLoadingVolume(conc);

    return Card(
      color: sampleStatusColor(row),
      child: InkWell(
        onTap: () => editSampleDialog(index),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          row.sampleName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${selectedSampleReplicate} $sampleWellLabel',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Chip(
                    label: Text(sampleStatusText(row)),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ...List.generate(row.absorbances.length, (i) {
                return infoRow(
                  'Raw absorbance ${i + 1}',
                  row.absorbances[i].toStringAsFixed(3),
                );
              }),
              infoRow(
                'Average raw absorbance',
                row.averageAbsorbance.toStringAsFixed(3),
              ),
              infoRow('Corrected absorbance', corrected.toStringAsFixed(3)),
              infoRow(
                'Dilution factor',
                row.dilutionFactor.toStringAsFixed(2),
              ),
              infoRow(
                'Protein concentration',
                '${conc.toStringAsFixed(4)} µg/µL',
              ),
              infoRow(
                'Target loading amount',
                '${loadingProteinAmountUg.toStringAsFixed(2)} µg',
              ),
              infoRow(
                'Loading volume',
                '${loadingVolume.toStringAsFixed(2)} µL',
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

  Widget buildStandardCard(int index, WesternStandardRow row) {
    final correctedAvg = useBlankCorrection
        ? row.averageAbsorbance - blankAbsorbance
        : row.averageAbsorbance;

    return Card(
      child: InkWell(
        onTap: () => editStandardDialog(index),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Standard ${index + 1}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${selectedStandardReplicate} $standardWellLabel',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Chip(
                    label: Text(
                      '${row.concentrationUgPerMl.toStringAsFixed(0)} µg/mL',
                    ),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ...List.generate(row.absorbances.length, (i) {
                return infoRow(
                  'Abs ${i + 1}',
                  row.absorbances[i].toStringAsFixed(3),
                );
              }),
              infoRow('Average', row.averageAbsorbance.toStringAsFixed(3)),
              infoRow('Corrected avg', correctedAvg.toStringAsFixed(3)),
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

  Widget buildMicroplateBcaProtocolTextCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            infoRow('Step 1', 'Prepare BSA standards and blank for microplate BCA'),
            infoRow(
              'Step 2',
              'Set replicate mode for standards and samples before reading wells',
            ),
            infoRow('Step 3', 'Dispense standards and diluted samples into plate wells'),
            infoRow('Step 4', 'Add BCA working reagent to each well'),
            infoRow('Step 5', 'Incubate plate under selected condition'),
            infoRow('Step 6', 'Measure absorbance at 562 nm'),
            infoRow(
              'Step 7',
              'Calculate average absorbance from replicate wells',
            ),
            infoRow(
              'Step 8',
              'Subtract blank absorbance from sample average if blank correction is used',
            ),
            infoRow(
              'Step 9',
              'Use standard curve to calculate concentration from absorbance',
            ),
            infoRow(
              'Step 10',
              'Multiply by dilution factor to get original sample concentration',
            ),
            infoRow(
              'Step 11',
              'Convert µg/mL to µg/µL for western blot loading calculation',
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final needsFilmScan = selectedDetectionSystem == 'X-ray film';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Western Blot Template'),
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
                label: 'Sample count',
                controller: sampleCountController,
                keyboardType: TextInputType.number,
                onChanged: syncSamplesFromInput,
              ),
              const SizedBox(height: 12),
              buildTextField(
                label: 'Sample type',
                controller: sampleTypeController,
              ),
              const SizedBox(height: 20),

              buildSectionTitle('Protein Extraction / Microplate BCA'),
              const SizedBox(height: 8),
              buildDropdownField(
                label: 'Target form',
                value: selectedTargetForm,
                items: const [
                  'Phospho form',
                  'Total form',
                ],
                onChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    selectedTargetForm = value;
                    if (value == 'Phospho form' &&
                        selectedBlockingBuffer == '5% Skim milk') {
                      selectedBlockingBuffer = '5% BSA';
                    }
                  });
                },
              ),
              const SizedBox(height: 12),
              buildTextField(
                label: 'Lysis buffer',
                controller: lysisBufferController,
              ),
              const SizedBox(height: 12),
              buildDropdownField(
                label: 'BCA format',
                value: selectedBcaFormat,
                items: const [
                  'Microplate BCA',
                ],
                onChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    selectedBcaFormat = value;
                  });
                },
              ),
              const SizedBox(height: 12),
              buildDropdownField(
                label: 'Standard replicate',
                value: selectedStandardReplicate,
                items: const [
                  'Single',
                  'Duplicate',
                  'Triplicate',
                ],
                onChanged: (value) {
                  if (value == null) return;
                  updateStandardReplicate(value);
                },
              ),
              const SizedBox(height: 12),
              buildDropdownField(
                label: 'Sample replicate',
                value: selectedSampleReplicate,
                items: const [
                  'Single',
                  'Duplicate',
                  'Triplicate',
                ],
                onChanged: (value) {
                  if (value == null) return;
                  updateSampleReplicate(value);
                },
              ),
              const SizedBox(height: 12),
              buildSwitchTile(
                title: 'BCA assay completed',
                value: bcaCompleted,
                onChanged: (value) {
                  setState(() {
                    bcaCompleted = value;
                  });
                },
              ),
              const SizedBox(height: 12),
              buildTextField(
                label: 'Read wavelength (nm)',
                controller: bcaWavelengthController,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              buildTextField(
                label: 'BCA incubation condition',
                controller: bcaIncubationController,
              ),
              const SizedBox(height: 12),
              buildSwitchTile(
                title: 'Use blank correction',
                value: useBlankCorrection,
                onChanged: (value) {
                  setState(() {
                    useBlankCorrection = value;
                  });
                },
              ),
              const SizedBox(height: 12),
              buildDropdownField(
                label: 'Standard curve unit',
                value: selectedStandardUnit,
                items: const [
                  'µg/mL',
                ],
                onChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    selectedStandardUnit = value;
                  });
                },
              ),
              const SizedBox(height: 12),
              buildTextField(
                label: 'Default sample dilution factor',
                controller: sampleDilutionFactorController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
              ),
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
                      onPressed: applyDefaultDilutionFactorToAll,
                      icon: const Icon(Icons.tune),
                      label: const Text('Apply Dilution to All'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              buildSectionTitle(
                'BCA Standard Curve ${selectedStandardReplicate.toLowerCase()} $standardWellLabel',
              ),
              const SizedBox(height: 8),
              if (standards.isEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'Standard curve rows가 없습니다.',
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                  ),
                )
              else
                ...List.generate(
                  standards.length,
                  (index) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: buildStandardCard(index, standards[index]),
                  ),
                ),
              const SizedBox(height: 12),

              buildSectionTitle('Gel / Transfer'),
              const SizedBox(height: 8),
              buildDropdownField(
                label: 'Gel type',
                value: selectedGelType,
                items: const [
                  'SDS-PAGE',
                ],
                onChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    selectedGelType = value;
                  });
                },
              ),
              const SizedBox(height: 12),
              buildDropdownField(
                label: 'Gel preparation',
                value: selectedGelPreparationType,
                items: const [
                  'Mini hand-cast',
                  'Gradient precast',
                ],
                onChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    selectedGelPreparationType = value;
                  });
                },
              ),
              const SizedBox(height: 12),
              if (isPrecast) ...[
                buildDropdownField(
                  label: 'Gradient range',
                  value: selectedGradientRange,
                  items: const [
                    '4-12%',
                    '4-15%',
                    '4-20%',
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() {
                      selectedGradientRange = value;
                    });
                  },
                ),
                const SizedBox(height: 12),
              ],
              buildDropdownField(
                label: 'Gel thickness',
                value: selectedGelThickness,
                items: const [
                  '0.75 mm',
                  '1.0 mm',
                  '1.5 mm',
                ],
                onChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    selectedGelThickness = value;
                    applyDefaultGelVolumes();
                  });
                },
              ),
              const SizedBox(height: 12),
              buildDropdownField(
                label: 'Comb teeth',
                value: selectedCombTeeth,
                items: const [
                  '10',
                  '15',
                ],
                onChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    selectedCombTeeth = value;
                    applyDefaultGelVolumes();
                  });
                },
              ),
              const SizedBox(height: 12),
              if (isHandCast) ...[
                buildTextField(
                  label: 'Number of gels',
                  controller: gelCountController,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                buildTextField(
                  label: 'Resolving gel (%)',
                  controller: resolvingPercentController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                ),
                const SizedBox(height: 12),
                buildTextField(
                  label: 'Stacking gel (%)',
                  controller: stackingPercentController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                ),
                const SizedBox(height: 12),
                buildTextField(
                  label: 'Resolving volume per gel (mL)',
                  controller: resolvingVolumePerGelController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                ),
                const SizedBox(height: 12),
                buildTextField(
                  label: 'Stacking volume per gel (mL)',
                  controller: stackingVolumePerGelController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                ),
                const SizedBox(height: 12),
                buildTextField(
                  label: 'Extra (%)',
                  controller: gelExtraPercentController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                ),
                const SizedBox(height: 12),
                buildTextField(
                  label: 'Acrylamide stock (%)',
                  controller: acrylamideStockPercentController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                ),
                const SizedBox(height: 12),
                buildTextField(
                  label: 'Tris-HCl stock for resolving (M, pH 8.8)',
                  controller: trisResolvingStockController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                ),
                const SizedBox(height: 12),
                buildTextField(
                  label: 'Tris-HCl stock for stacking (M, pH 6.8)',
                  controller: trisStackingStockController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                ),
                const SizedBox(height: 12),
                buildTextField(
                  label: 'SDS stock (%)',
                  controller: sdsStockPercentController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                ),
                const SizedBox(height: 12),
                buildTextField(
                  label: 'APS stock (%)',
                  controller: apsStockPercentController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                ),
                const SizedBox(height: 12),
              ],
              buildTextField(
                label: 'Loading protein amount per lane (µg)',
                controller: proteinAmountController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 12),
              buildTextField(
                label: isHandCast
                    ? 'Default gel percentage (%)'
                    : 'Representative target band gel percentage (%)',
                controller: gelPercentController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 12),
              buildDropdownField(
                label: 'Transfer method',
                value: selectedTransferMethod,
                items: const [
                  'Wet transfer',
                  'Semi-dry transfer',
                ],
                onChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    selectedTransferMethod = value;
                  });
                },
              ),
              const SizedBox(height: 12),
              buildDropdownField(
                label: 'Membrane',
                value: selectedMembrane,
                items: const [
                  'Nitrocellulose',
                  'PVDF',
                ],
                onChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    selectedMembrane = value;
                  });
                },
              ),
              const SizedBox(height: 12),
              buildTextField(
                label: 'Transfer condition',
                controller: transferConditionController,
              ),
              const SizedBox(height: 20),

              buildSectionTitle('Blocking / Antibody'),
              const SizedBox(height: 8),
              buildDropdownField(
                label: 'Blocking buffer',
                value: selectedBlockingBuffer,
                items: const [
                  '5% BSA',
                  '5% Skim milk',
                  '3% BSA',
                  'Custom',
                ],
                onChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    selectedBlockingBuffer = value;
                  });
                },
              ),
              if (selectedBlockingBuffer == 'Custom') ...[
                const SizedBox(height: 12),
                buildTextField(
                  label: 'Custom blocking buffer',
                  controller: customBlockingBufferController,
                ),
              ],
              const SizedBox(height: 12),
              buildTextField(
                label: 'Blocking time (min)',
                controller: blockingTimeController,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              buildTextField(
                label: 'Primary antibody',
                controller: primaryAntibodyController,
              ),
              const SizedBox(height: 12),
              buildDropdownField(
                label: 'Primary host',
                value: selectedPrimaryHost,
                items: const [
                  'Mouse',
                  'Rabbit',
                  'Rat',
                  'Goat',
                ],
                onChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    selectedPrimaryHost = value;
                    switch (value) {
                      case 'Mouse':
                        selectedSecondaryHost = 'Anti-mouse HRP';
                        break;
                      case 'Rabbit':
                        selectedSecondaryHost = 'Anti-rabbit HRP';
                        break;
                      case 'Rat':
                        selectedSecondaryHost = 'Anti-rat HRP';
                        break;
                      case 'Goat':
                        selectedSecondaryHost = 'Anti-goat HRP';
                        break;
                    }
                  });
                },
              ),
              const SizedBox(height: 12),
              buildTextField(
                label: 'Primary dilution',
                controller: primaryDilutionController,
              ),
              const SizedBox(height: 12),
              buildTextField(
                label: 'Primary incubation',
                controller: primaryIncubationController,
              ),
              const SizedBox(height: 12),
              buildDropdownField(
                label: 'Secondary antibody-HRP',
                value: selectedSecondaryHost,
                items: const [
                  'Anti-mouse HRP',
                  'Anti-rabbit HRP',
                  'Anti-rat HRP',
                  'Anti-goat HRP',
                ],
                onChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    selectedSecondaryHost = value;
                  });
                },
              ),
              const SizedBox(height: 12),
              buildTextField(
                label: 'Secondary antibody detail',
                controller: secondaryAntibodyController,
              ),
              const SizedBox(height: 12),
              buildTextField(
                label: 'Secondary dilution',
                controller: secondaryDilutionController,
              ),
              const SizedBox(height: 12),
              buildTextField(
                label: 'Secondary incubation',
                controller: secondaryIncubationController,
              ),
              const SizedBox(height: 20),

              buildSectionTitle('Washing / Detection'),
              const SizedBox(height: 8),
              buildSwitchTile(
                title: 'Use PBST for washing',
                value: pbstUsed,
                onChanged: (value) {
                  setState(() {
                    pbstUsed = value;
                  });
                },
              ),
              const SizedBox(height: 12),
              buildTextField(
                label: 'Wash count',
                controller: washCountController,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              buildTextField(
                label: 'Wash time per wash (min)',
                controller: washTimeController,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              buildDropdownField(
                label: 'Chemiluminescence substrate',
                value: selectedChemiluminescence,
                items: const [
                  'Pico',
                  'Femto',
                ],
                onChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    selectedChemiluminescence = value;
                  });
                },
              ),
              const SizedBox(height: 12),
              buildDropdownField(
                label: 'Detection system',
                value: selectedDetectionSystem,
                items: const [
                  'X-ray film',
                  'LAS system',
                ],
                onChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    selectedDetectionSystem = value;
                    if (value != 'X-ray film') {
                      filmScanSaved = false;
                    }
                  });
                },
              ),
              const SizedBox(height: 12),
              if (needsFilmScan)
                buildSwitchTile(
                  title: 'Film scan saved',
                  value: filmScanSaved,
                  onChanged: (value) {
                    setState(() {
                      filmScanSaved = value;
                    });
                  },
                ),
              buildSwitchTile(
                title: 'Include loading control',
                value: loadingControlIncluded,
                onChanged: (value) {
                  setState(() {
                    loadingControlIncluded = value;
                  });
                },
              ),
              const SizedBox(height: 20),

              buildSectionTitle('Calculated Result'),
              const SizedBox(height: 8),
              buildSummaryCard(),
              const SizedBox(height: 12),

              if (isHandCast) ...[
                buildSectionTitle('SDS-PAGE Gel Recipe'),
                const SizedBox(height: 8),
                buildGelRecipeCard(
                  title: 'Resolving gel',
                  trisLabel: 'Tris-HCl pH 8.8',
                  recipe: calculateResolvingRecipe(),
                ),
                const SizedBox(height: 12),
                buildGelRecipeCard(
                  title: 'Stacking gel',
                  trisLabel: 'Tris-HCl pH 6.8',
                  recipe: calculateStackingRecipe(),
                ),
                const SizedBox(height: 20),
              ] else ...[
                buildSectionTitle('SDS-PAGE Gel Info'),
                const SizedBox(height: 8),
                Card(
                  color: Colors.grey.shade100,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        infoRow('Gel preparation', selectedGelPreparationType),
                        infoRow('Gradient range', selectedGradientRange),
                        infoRow('Thickness', selectedGelThickness),
                        infoRow('Comb teeth', selectedCombTeeth),
                        infoRow(
                          'Note',
                          'Precast gel은 recipe 계산 없이 선택 정보만 기록',
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],

              buildSectionTitle('Microplate BCA Summary'),
              const SizedBox(height: 8),
              buildBcaProtocolCard(),
              const SizedBox(height: 12),

              buildSectionTitle('Microplate BCA Protocol'),
              const SizedBox(height: 8),
              buildMicroplateBcaProtocolTextCard(),
              const SizedBox(height: 12),

              buildSectionTitle('Process Summary'),
              const SizedBox(height: 8),
              buildProcessCard(),
              const SizedBox(height: 12),

              buildSectionTitle('Detection Summary'),
              const SizedBox(height: 8),
              buildResultCard(),
              const SizedBox(height: 20),

              buildSectionTitle(
                'Sample Concentration from Microplate BCA ${selectedSampleReplicate.toLowerCase()} $sampleWellLabel',
              ),
              const SizedBox(height: 8),
              buildLegend(),
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

              buildSectionTitle('Notes'),
              const SizedBox(height: 8),
              buildTextField(
                label: 'Notes',
                controller: notesController,
                maxLines: 4,
              ),
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

class WesternSampleRow {
  final String sampleName;
  final List<double> absorbances;
  final double dilutionFactor;

  const WesternSampleRow({
    required this.sampleName,
    required this.absorbances,
    required this.dilutionFactor,
  });

  WesternSampleRow copyWith({
    String? sampleName,
    List<double>? absorbances,
    double? dilutionFactor,
  }) {
    return WesternSampleRow(
      sampleName: sampleName ?? this.sampleName,
      absorbances: absorbances ?? this.absorbances,
      dilutionFactor: dilutionFactor ?? this.dilutionFactor,
    );
  }

  double get averageAbsorbance {
    if (absorbances.isEmpty) return 0;
    return absorbances.reduce((a, b) => a + b) / absorbances.length;
  }

  double get rawAbsorbance => averageAbsorbance;

  Map<String, dynamic> toMap() {
    return {
      'sampleName': sampleName,
      'absorbances': absorbances,
      'averageAbsorbance': averageAbsorbance,
      'dilutionFactor': dilutionFactor,
    };
  }
}

class WesternStandardRow {
  final double concentrationUgPerMl;
  final List<double> absorbances;

  const WesternStandardRow({
    required this.concentrationUgPerMl,
    required this.absorbances,
  });

  WesternStandardRow copyWith({
    double? concentrationUgPerMl,
    List<double>? absorbances,
  }) {
    return WesternStandardRow(
      concentrationUgPerMl:
          concentrationUgPerMl ?? this.concentrationUgPerMl,
      absorbances: absorbances ?? this.absorbances,
    );
  }

  double get averageAbsorbance {
    if (absorbances.isEmpty) return 0;
    return absorbances.reduce((a, b) => a + b) / absorbances.length;
  }

  Map<String, dynamic> toMap() {
    return {
      'concentrationUgPerMl': concentrationUgPerMl,
      'absorbances': absorbances,
      'averageAbsorbance': averageAbsorbance,
    };
  }
}

class GelMixRecipe {
  final double totalMl;
  final double acrylamideMl;
  final double trisMl;
  final double sdsMl;
  final double apsMl;
  final double temedMl;
  final double waterMl;

  const GelMixRecipe({
    required this.totalMl,
    required this.acrylamideMl,
    required this.trisMl,
    required this.sdsMl,
    required this.apsMl,
    required this.temedMl,
    required this.waterMl,
  });
}