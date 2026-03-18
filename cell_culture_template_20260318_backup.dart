import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/cell_line_option.dart';
import '../models/plate_drag_data.dart';
import '../services/cell_culture_excel_service.dart';
import '../services/cell_line_catalog_service.dart';
import '../services/cell_culture_layout_service.dart';
import '../services/cell_culture_calculator.dart';

class CellCultureFormData {
  final String selectedAssay;
  final String selectedWare;

  final double seedingDensity;
  final int sampleCount;
  final int replicateCount;
  final int targetConfluency;

  final int blankCount;
  final int vehicleCount;
  final int positiveControlCount;
  final int negativeControlCount;

  final double seedingVolumePerUnit;
  final double stockConcentration;
  final double extraPercent;

  const CellCultureFormData({
    required this.selectedAssay,
    required this.selectedWare,
    required this.seedingDensity,
    required this.sampleCount,
    required this.replicateCount,
    required this.targetConfluency,
    required this.blankCount,
    required this.vehicleCount,
    required this.positiveControlCount,
    required this.negativeControlCount,
    required this.seedingVolumePerUnit,
    required this.stockConcentration,
    required this.extraPercent,
  });

  factory CellCultureFormData.fromRaw({
    required String selectedAssay,
    required String selectedWare,
    required String seedingDensityText,
    required String sampleCountText,
    required String replicateText,
    required String targetConfluencyText,
    required String blankCountText,
    required String vehicleCountText,
    required String positiveControlCountText,
    required String negativeControlCountText,
    required String seedingVolumeText,
    required String stockConcentrationText,
    required String extraPercentText,
  }) {
    return CellCultureFormData(
      selectedAssay: selectedAssay,
      selectedWare: selectedWare,
      seedingDensity: double.tryParse(seedingDensityText) ?? 0,
      sampleCount: int.tryParse(sampleCountText) ?? 0,
      replicateCount: int.tryParse(replicateText) ?? 0,
      targetConfluency: int.tryParse(targetConfluencyText) ?? 0,
      blankCount: int.tryParse(blankCountText) ?? 0,
      vehicleCount: int.tryParse(vehicleCountText) ?? 0,
      positiveControlCount: int.tryParse(positiveControlCountText) ?? 0,
      negativeControlCount: int.tryParse(negativeControlCountText) ?? 0,
      seedingVolumePerUnit: double.tryParse(seedingVolumeText) ?? 0,
      stockConcentration: double.tryParse(stockConcentrationText) ?? 0,
      extraPercent: (double.tryParse(extraPercentText) ?? 0) / 100.0,
    );
  }

  List<String> validate() {
    final errors = <String>[];

    if (seedingDensity <= 0) {
      errors.add('Seeding density는 0보다 커야 합니다.');
    }
    if (sampleCount < 0) {
      errors.add('Sample count는 0 이상이어야 합니다.');
    }
    if (replicateCount <= 0) {
      errors.add('Replicates는 1 이상이어야 합니다.');
    }
    if (targetConfluency < 0 || targetConfluency > 100) {
      errors.add('Target confluency는 0~100 범위여야 합니다.');
    }
    if (blankCount < 0 ||
        vehicleCount < 0 ||
        positiveControlCount < 0 ||
        negativeControlCount < 0) {
      errors.add('Control count는 0 이상이어야 합니다.');
    }
    if (seedingVolumePerUnit <= 0) {
      errors.add('Seeding volume per unit은 0보다 커야 합니다.');
    }
    if (stockConcentration <= 0) {
      errors.add('Cell stock concentration은 0보다 커야 합니다.');
    }
    if (extraPercent < 0) {
      errors.add('Extra(%)는 0 이상이어야 합니다.');
    }

    return errors;
  }
}

class CellCultureSummary {
  final double surfaceArea;
  final String workingVolume;

  final int cellsPerUnit;
  final int totalSampleUnits;
  final int totalControlUnits;
  final int totalCultureUnits;
  final int totalCellsNeeded;
  final int totalCellsNeededWithExtra;

  final double totalSeedingVolume;
  final double totalSeedingVolumeWithExtra;
  final double requiredCellSuspensionVolume;
  final double requiredCellSuspensionVolumeWithExtra;
  final double requiredMediaVolume;
  final double requiredMediaVolumeWithExtra;

  const CellCultureSummary({
    required this.surfaceArea,
    required this.workingVolume,
    required this.cellsPerUnit,
    required this.totalSampleUnits,
    required this.totalControlUnits,
    required this.totalCultureUnits,
    required this.totalCellsNeeded,
    required this.totalCellsNeededWithExtra,
    required this.totalSeedingVolume,
    required this.totalSeedingVolumeWithExtra,
    required this.requiredCellSuspensionVolume,
    required this.requiredCellSuspensionVolumeWithExtra,
    required this.requiredMediaVolume,
    required this.requiredMediaVolumeWithExtra,
  });
}

class CellCultureTemplateControllerVm {
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

  final Map<String, double> recommendedDensityByCellLine = {
    'HeLa': 50000,
    'HEK293': 40000,
    'A549': 45000,
    'MCF-7': 50000,
    'NIH/3T3': 30000,
    'L929': 30000,
    'PC-12': 60000,
    'H9c2': 40000,
    'CHO-K1': 35000,
    'BHK-21': 35000,
    'Vero': 30000,
    'COS-7': 35000,
    'CV-1': 35000,
    'MDCK': 40000,
    'D-17': 50000,
    'CRFK': 40000,
    'Fcwf-4': 40000,
  };

  final Map<String, Map<String, double>> recommendedDensityBySpeciesAndAssay = {
    'Human': {
      'Viability assay': 20000,
      'qPCR': 50000,
      'ELISA': 40000,
      'Western blot': 80000,
      'Imaging / IF': 30000,
    },
    'Mouse': {
      'Viability assay': 18000,
      'qPCR': 35000,
      'ELISA': 30000,
      'Western blot': 60000,
      'Imaging / IF': 25000,
    },
    'Rat': {
      'Viability assay': 20000,
      'qPCR': 45000,
      'ELISA': 35000,
      'Western blot': 70000,
      'Imaging / IF': 30000,
    },
    'Hamster': {
      'Viability assay': 18000,
      'qPCR': 35000,
      'ELISA': 30000,
      'Western blot': 60000,
      'Imaging / IF': 25000,
    },
    'Monkey': {
      'Viability assay': 18000,
      'qPCR': 30000,
      'ELISA': 30000,
      'Western blot': 55000,
      'Imaging / IF': 25000,
    },
    'Dog': {
      'Viability assay': 20000,
      'qPCR': 40000,
      'ELISA': 35000,
      'Western blot': 65000,
      'Imaging / IF': 30000,
    },
    'Cat': {
      'Viability assay': 20000,
      'qPCR': 40000,
      'ELISA': 35000,
      'Western blot': 65000,
      'Imaging / IF': 30000,
    },
  };

  double selectedArea(String ware) => cultureWareAreaMap[ware] ?? 0.0;
  String selectedVolume(String ware) => cultureWareVolumeMap[ware] ?? '-';

  double? defaultDensityForAssay(String assay) => defaultDensityByAssay[assay];
  double? defaultVolumeForWare(String ware) => defaultSeedingVolumeByWare[ware];

  String? normalizeSpeciesKey(String? species) {
    if (species == null || species.trim().isEmpty) return null;
    final s = species.toLowerCase().trim();

    if (s == 'human' || s.contains('homo sapiens')) return 'Human';
    if (s == 'mouse' || s.contains('mus musculus')) return 'Mouse';
    if (s == 'rat' || s.contains('rattus')) return 'Rat';
    if (s == 'dog' || s == 'canine' || s.contains('canis')) return 'Dog';
    if (s == 'cat' || s == 'feline' || s.contains('felis')) return 'Cat';

    if (s == 'monkey' ||
        s.contains('african green monkey') ||
        s.contains('chlorocebus') ||
        s.contains('cercopithecus')) {
      return 'Monkey';
    }

    if (s == 'hamster' ||
        s.contains('chinese hamster') ||
        s.contains('syrian hamster') ||
        s.contains('cricetulus') ||
        s.contains('mesocricetus')) {
      return 'Hamster';
    }

    return null;
  }

  bool speciesMatches(String? species, String filter) {
    if (filter == 'All') return true;
    return normalizeSpeciesKey(species) == filter;
  }

  double? getRecommendedDensity({
    CellLineOption? cellLine,
    required String assay,
  }) {
    if (cellLine != null) {
      final byName = recommendedDensityByCellLine[cellLine.name];
      if (byName != null) return byName;

      final normalizedSpecies = normalizeSpeciesKey(cellLine.species);
      if (normalizedSpecies != null) {
        final bySpecies = recommendedDensityBySpeciesAndAssay[normalizedSpecies];
        if (bySpecies != null) {
          final value = bySpecies[assay];
          if (value != null) return value;
        }
      }
    }

    return defaultDensityByAssay[assay];
  }

  CellCultureSummary buildSummary(CellCultureFormData form) {
    final area = selectedArea(form.selectedWare);
    final volume = selectedVolume(form.selectedWare);

    final cellsPerUnit = CellCultureCalculator.cellsPerUnit(
      surfaceArea: area,
      seedingDensity: form.seedingDensity,
    );

    final totalSampleUnits = CellCultureCalculator.totalSampleUnits(
      sampleCount: form.sampleCount,
      replicateCount: form.replicateCount,
    );

    final totalControlUnits = CellCultureCalculator.totalControlUnits(
      blankCount: form.blankCount,
      negativeControlCount: form.negativeControlCount,
      vehicleCount: form.vehicleCount,
      positiveControlCount: form.positiveControlCount,
    );

    final totalCultureUnits = CellCultureCalculator.totalCultureUnits(
      totalSampleUnits: totalSampleUnits,
      totalControlUnits: totalControlUnits,
    );

    final totalCellsNeeded = CellCultureCalculator.totalCellsNeeded(
      cellsPerUnit: cellsPerUnit,
      totalCultureUnits: totalCultureUnits,
    );

    final totalCellsNeededWithExtra =
        CellCultureCalculator.totalCellsNeededWithExtra(
      totalCellsNeeded: totalCellsNeeded,
      extraPercent: form.extraPercent,
    );

    final totalSeedingVolume = CellCultureCalculator.totalSeedingVolume(
      seedingVolumePerUnit: form.seedingVolumePerUnit,
      totalCultureUnits: totalCultureUnits,
    );

    final totalSeedingVolumeWithExtra =
        CellCultureCalculator.totalSeedingVolumeWithExtra(
      totalSeedingVolume: totalSeedingVolume,
      extraPercent: form.extraPercent,
    );

    final requiredCellSuspensionVolume =
        CellCultureCalculator.requiredCellSuspensionVolume(
      totalCellsNeeded: totalCellsNeeded,
      stockConcentration: form.stockConcentration,
    );

    final requiredCellSuspensionVolumeWithExtra =
        CellCultureCalculator.requiredCellSuspensionVolume(
      totalCellsNeeded: totalCellsNeededWithExtra,
      stockConcentration: form.stockConcentration,
    );

    final requiredMediaVolume = CellCultureCalculator.requiredMediaVolume(
      totalSeedingVolume: totalSeedingVolume,
      requiredCellSuspensionVolume: requiredCellSuspensionVolume,
    );

    final requiredMediaVolumeWithExtra = CellCultureCalculator.requiredMediaVolume(
      totalSeedingVolume: totalSeedingVolumeWithExtra,
      requiredCellSuspensionVolume: requiredCellSuspensionVolumeWithExtra,
    );

    return CellCultureSummary(
      surfaceArea: area,
      workingVolume: volume,
      cellsPerUnit: cellsPerUnit,
      totalSampleUnits: totalSampleUnits,
      totalControlUnits: totalControlUnits,
      totalCultureUnits: totalCultureUnits,
      totalCellsNeeded: totalCellsNeeded,
      totalCellsNeededWithExtra: totalCellsNeededWithExtra,
      totalSeedingVolume: totalSeedingVolume,
      totalSeedingVolumeWithExtra: totalSeedingVolumeWithExtra,
      requiredCellSuspensionVolume: requiredCellSuspensionVolume,
      requiredCellSuspensionVolumeWithExtra:
          requiredCellSuspensionVolumeWithExtra,
      requiredMediaVolume: requiredMediaVolume,
      requiredMediaVolumeWithExtra: requiredMediaVolumeWithExtra,
    );
  }

  List<List<String>> buildGeneratedLayout(CellCultureFormData form) {
    return CellCultureLayoutService.generatePlateLayout(
      ware: form.selectedWare,
      sampleCount: form.sampleCount,
      replicates: form.replicateCount,
      blankCount: form.blankCount,
      vehicleCount: form.vehicleCount,
      positiveControlCount: form.positiveControlCount,
      negativeControlCount: form.negativeControlCount,
    );
  }

  String recommendationText(String ware) {
    switch (ware) {
      case '96-well plate':
        return 'High-throughput assay에 적합합니다.';
      case '24-well plate':
        return 'qPCR, ELISA, imaging assay에 많이 사용됩니다.';
      case '6-well plate':
        return 'Protein/RNA harvest가 필요한 assay에 적합합니다.';
      case 'T25 flask':
      case 'T75 flask':
        return 'Expansion 또는 대량 세포 확보에 적합합니다.';
      default:
        return '선택한 culture ware 조건을 확인하세요.';
    }
  }
}

class CellCultureTemplatePage extends StatefulWidget {
  const CellCultureTemplatePage({super.key});

  @override
  State<CellCultureTemplatePage> createState() =>
      _CellCultureTemplatePageState();
}

class _CellCultureTemplatePageState extends State<CellCultureTemplatePage> {
  final controllerVm = CellCultureTemplateControllerVm();

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

  String selectedSourceFilter = 'All';
  String selectedSpeciesFilter = 'All';

  final List<String> sourceFilters = ['All', 'ATCC', 'KCLB'];
  final List<String> speciesFilters = [
    'All',
    'Human',
    'Mouse',
    'Rat',
    'Hamster',
    'Monkey',
    'Dog',
    'Cat',
  ];

  List<List<String>> editablePlateLayout = [];
  bool autoGenerateLayout = true;

  List<CellLineOption> cellLineOptions = [];
  CellLineOption? selectedCellLine;
  bool isLoadingCellLines = true;

  CellCultureFormData get formData => CellCultureFormData.fromRaw(
        selectedAssay: selectedAssay,
        selectedWare: selectedWare,
        seedingDensityText: seedingDensityController.text,
        sampleCountText: sampleCountController.text,
        replicateText: replicateController.text,
        targetConfluencyText: targetConfluencyController.text,
        blankCountText: blankCountController.text,
        vehicleCountText: vehicleCountController.text,
        positiveControlCountText: positiveControlCountController.text,
        negativeControlCountText: negativeControlCountController.text,
        seedingVolumeText: seedingVolumeController.text,
        stockConcentrationText: stockConcentrationController.text,
        extraPercentText: extraPercentController.text,
      );

  CellCultureSummary get summary => controllerVm.buildSummary(formData);

  void applyRecommendedDensity({
    CellLineOption? cellLine,
    bool force = false,
  }) {
    final recommended = controllerVm.getRecommendedDensity(
      cellLine: cellLine,
      assay: selectedAssay,
    );

    if (recommended == null) return;

    final current = double.tryParse(seedingDensityController.text);

    if (force || current == null || current <= 0) {
      seedingDensityController.text = recommended.toStringAsFixed(0);
    }
  }

  void applyDefaultDensityByAssay(String assay) {
    final density = controllerVm.defaultDensityForAssay(assay);
    if (density != null) {
      seedingDensityController.text = density.toStringAsFixed(0);
    }
  }

  void applyDefaultSeedingVolumeByWare(String ware) {
    final volume = controllerVm.defaultVolumeForWare(ware);
    if (volume != null) {
      seedingVolumeController.text = volume.toStringAsFixed(1);
    }
  }

  List<List<String>> buildGeneratedLayout() {
    return controllerVm.buildGeneratedLayout(formData);
  }

  void onLayoutRelevantInputChanged() {
    if (!autoGenerateLayout) {
      setState(() {});
      return;
    }

    editablePlateLayout = buildGeneratedLayout();
    setState(() {});
  }

  void onCalculationInputChanged() {
    setState(() {});
  }

  void regenerateLayout() {
    editablePlateLayout = buildGeneratedLayout();
    setState(() {
      autoGenerateLayout = true;
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

  Future<void> _loadCellLines() async {
    try {
      final items = await CellLineCatalogService.loadCatalog();
      if (!mounted) return;

      CellLineOption? matched;
      final initialText = cellLineController.text.trim().toLowerCase();

      for (final item in items) {
        if (item.name.toLowerCase() == initialText) {
          matched = item;
          break;
        }
      }

      setState(() {
        cellLineOptions = items;
        selectedCellLine = matched;
        if (matched != null) {
          cellLineController.text = matched.displayLabel;
          applyRecommendedDensity(cellLine: matched, force: true);
        } else {
          cellLineController.clear();
        }
        isLoadingCellLines = false;
      });
    } catch (e) {
      debugPrint('Failed to load cell lines: $e');
      if (!mounted) return;
      setState(() {
        isLoadingCellLines = false;
        selectedCellLine = null;
        cellLineController.clear();
      });
    }
  }

  void clearSelectedCellLineIfFilteredOut() {
    if (selectedCellLine == null) return;

    final sourceOk = selectedSourceFilter == 'All' ||
        selectedCellLine!.source.toUpperCase() ==
            selectedSourceFilter.toUpperCase();

    final speciesOk = controllerVm.speciesMatches(
      selectedCellLine!.species,
      selectedSpeciesFilter,
    );

    if (!sourceOk || !speciesOk) {
      selectedCellLine = null;
      cellLineController.clear();
    }
  }

  Iterable<CellLineOption> _filterCellLineOptions(String query) {
    final q = query.trim().toLowerCase();

    final filtered = cellLineOptions.where((item) {
      final matchesQuery = q.isEmpty ||
          item.name.toLowerCase().contains(q) ||
          item.catalogNumber.toLowerCase().contains(q) ||
          item.source.toLowerCase().contains(q) ||
          (item.species?.toLowerCase().contains(q) ?? false) ||
          (item.tissue?.toLowerCase().contains(q) ?? false) ||
          (item.disease?.toLowerCase().contains(q) ?? false);

      final matchesSource = selectedSourceFilter == 'All' ||
          item.source.toUpperCase() == selectedSourceFilter.toUpperCase();

      final matchesSpecies = controllerVm.speciesMatches(
        item.species,
        selectedSpeciesFilter,
      );

      return matchesQuery && matchesSource && matchesSpecies;
    }).toList();

    filtered.sort((a, b) {
      final aStarts = q.isNotEmpty && a.name.toLowerCase().startsWith(q) ? 0 : 1;
      final bStarts = q.isNotEmpty && b.name.toLowerCase().startsWith(q) ? 0 : 1;
      if (aStarts != bStarts) return aStarts.compareTo(bStarts);

      if (a.source != b.source) {
        return a.source.compareTo(b.source);
      }

      return a.name.compareTo(b.name);
    });

    return filtered.take(20);
  }

  Uri? buildCellLineSourceUri(CellLineOption option) {
    if (option.source.toUpperCase() == 'KCLB') {
      return Uri.parse(
        'https://cellbank.snu.ac.kr/cellline/search?q=${Uri.encodeComponent(option.catalogNumber)}&sc=y',
      );
    }

    if (option.source.toUpperCase() == 'ATCC') {
      return Uri.parse(
        'https://www.atcc.org/search#q=${Uri.encodeComponent(option.catalogNumber)}',
      );
    }

    return null;
  }

  Future<void> openSelectedCellLineSource() async {
    if (selectedCellLine == null) return;

    final uri = buildCellLineSourceUri(selectedCellLine!);
    if (uri == null) return;

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('원문 페이지를 열 수 없습니다.')),
      );
    }
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
    final data = formData;
    final result = summary;
    final errors = data.validate();

    if (selectedCellLine == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cell line은 ATCC 또는 KCLB catalog에서 선택해야 합니다.'),
        ),
      );
      return;
    }

    if (errors.isNotEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errors.first)),
      );
      return;
    }

    try {
      final path = await CellCultureExcelService.export(
        cellLine: selectedCellLine!.exportLabel,
        assayType: data.selectedAssay,
        cultureWare: data.selectedWare,
        surfaceArea: result.surfaceArea,
        workingVolume: result.workingVolume,
        seedingDensity: data.seedingDensity,
        sampleCount: data.sampleCount,
        replicateCount: data.replicateCount,
        blankCount: data.blankCount,
        negativeControlCount: data.negativeControlCount,
        vehicleCount: data.vehicleCount,
        positiveControlCount: data.positiveControlCount,
        totalControlUnits: result.totalControlUnits,
        totalSampleUnits: result.totalSampleUnits,
        totalCultureUnits: result.totalCultureUnits,
        cellsPerUnit: result.cellsPerUnit,
        totalCellsNeeded: result.totalCellsNeeded,
        totalCellsNeededWithExtra: result.totalCellsNeededWithExtra,
        targetConfluency: data.targetConfluency,
        seedingVolumePerUnit: data.seedingVolumePerUnit,
        totalSeedingVolume: result.totalSeedingVolume,
        totalSeedingVolumeWithExtra: result.totalSeedingVolumeWithExtra,
        stockConcentration: data.stockConcentration,
        requiredCellSuspensionVolume: result.requiredCellSuspensionVolume,
        requiredCellSuspensionVolumeWithExtra:
            result.requiredCellSuspensionVolumeWithExtra,
        requiredMediaVolume: result.requiredMediaVolume,
        requiredMediaVolumeWithExtra: result.requiredMediaVolumeWithExtra,
        extraPercent: data.extraPercent,
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
    int maxLines = 1,
    bool readOnly = false,
    ValueChanged<String>? onChanged,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      readOnly: readOnly,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
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

  Widget buildCellLineFilterSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Catalog filter',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: sourceFilters.map((filter) {
            final selected = selectedSourceFilter == filter;
            return ChoiceChip(
              label: Text(filter),
              selected: selected,
              onSelected: (_) {
                setState(() {
                  selectedSourceFilter = filter;
                  clearSelectedCellLineIfFilteredOut();
                });
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 12),
        const Text(
          'Species filter',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: speciesFilters.map((filter) {
            final selected = selectedSpeciesFilter == filter;
            return ChoiceChip(
              label: Text(filter),
              selected: selected,
              onSelected: (_) {
                setState(() {
                  selectedSpeciesFilter = filter;
                  clearSelectedCellLineIfFilteredOut();
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget buildCellLineAutocomplete() {
    if (isLoadingCellLines) {
      return const TextField(
        enabled: false,
        decoration: InputDecoration(
          labelText: 'Cell line',
          border: OutlineInputBorder(),
          suffixIcon: Padding(
            padding: EdgeInsets.all(12),
            child: SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
      );
    }

    return Autocomplete<CellLineOption>(
      displayStringForOption: (option) => option.displayLabel,
      optionsBuilder: (TextEditingValue textEditingValue) {
        return _filterCellLineOptions(textEditingValue.text);
      },
      onSelected: (CellLineOption option) {
        selectedCellLine = option;
        cellLineController.text = option.displayLabel;
        applyRecommendedDensity(cellLine: option, force: true);
        autoGenerateLayout = true;
        editablePlateLayout = buildGeneratedLayout();
        setState(() {});
      },
      fieldViewBuilder: (
        BuildContext context,
        TextEditingController textEditingController,
        FocusNode focusNode,
        VoidCallback onFieldSubmitted,
      ) {
        if (textEditingController.text.isEmpty &&
            cellLineController.text.isNotEmpty) {
          textEditingController.text = cellLineController.text;
        }

        return TextField(
          controller: textEditingController,
          focusNode: focusNode,
          decoration: const InputDecoration(
            labelText: 'Cell line',
            hintText: '이름, catalog 번호, source로 검색 후 선택',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.search),
          ),
          onChanged: (_) {
            setState(() {
              selectedCellLine = null;
            });
          },
        );
      },
      optionsViewBuilder: (
        BuildContext context,
        AutocompleteOnSelected<CellLineOption> onSelected,
        Iterable<CellLineOption> options,
      ) {
        final optionList = options.toList();

        if (optionList.isEmpty) {
          return Align(
            alignment: Alignment.topLeft,
            child: Material(
              elevation: 4,
              child: SizedBox(
                width: 420,
                child: ListTile(
                  title: const Text('검색 결과 없음'),
                  subtitle: const Text('다른 이름 또는 catalog 번호로 검색해보세요.'),
                ),
              ),
            ),
          );
        }

        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4,
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 700,
                maxHeight: 320,
              ),
              child: ListView.separated(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: optionList.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final option = optionList[index];
                  return ListTile(
                    dense: true,
                    title: Text(option.name),
                    subtitle: Text(
                      '${option.source} ${option.catalogNumber}'
                      '${option.species != null ? ' • ${option.species}' : ''}'
                      '${option.tissue != null ? ' • ${option.tissue}' : ''}'
                      '${option.disease != null ? ' • ${option.disease}' : ''}',
                    ),
                    trailing: option.source.toUpperCase() == 'ATCC'
                        ? const Icon(Icons.public, size: 18)
                        : const Icon(Icons.biotech, size: 18),
                    onTap: () => onSelected(option),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget buildSelectedCellLineCard() {
    if (selectedCellLine == null) return const SizedBox.shrink();

    return Card(
      color: Colors.grey.shade50,
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            infoRow('Selected', selectedCellLine!.name),
            infoRow('Source', selectedCellLine!.source),
            infoRow('Catalog No.', selectedCellLine!.catalogNumber),
            infoRow('Species', selectedCellLine!.species ?? '-'),
            infoRow('Tissue', selectedCellLine!.tissue ?? '-'),
            infoRow('Disease', selectedCellLine!.disease ?? '-'),
            infoRow('Source filter', selectedSourceFilter),
            infoRow('Species filter', selectedSpeciesFilter),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: openSelectedCellLineSource,
                icon: const Icon(Icons.open_in_new),
                label: const Text('원문 보기'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildRecommendedDensityCard() {
    final recommended = controllerVm.getRecommendedDensity(
      cellLine: selectedCellLine,
      assay: selectedAssay,
    );

    if (recommended == null) return const SizedBox.shrink();

    return Card(
      color: Colors.orange.shade50,
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.lightbulb_outline),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Recommended seeding density',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Text('${recommended.toStringAsFixed(0)} cells/cm²'),
                  const SizedBox(height: 6),
                  Text(
                    selectedCellLine != null
                        ? '${selectedCellLine!.name} / $selectedAssay 기준 추천값'
                        : '$selectedAssay 기본 추천값',
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: () {
                seedingDensityController.text = recommended.toStringAsFixed(0);
                setState(() {});
              },
              child: const Text('적용'),
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
    final data = formData;
    final result = summary;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            infoRow(
              'Cell line',
              selectedCellLine?.displayLabel ?? 'Not selected',
            ),
            infoRow('Assay type', data.selectedAssay),
            infoRow('Culture ware', data.selectedWare),
            infoRow('Surface area', '${result.surfaceArea.toStringAsFixed(2)} cm²'),
            infoRow('Working volume', result.workingVolume),
            infoRow(
              'Seeding density',
              '${data.seedingDensity.toStringAsFixed(0)} cells/cm²',
            ),
            infoRow('Target confluency', '${data.targetConfluency} %'),
            infoRow('Cells / unit', '${result.cellsPerUnit} cells'),
            infoRow('Sample count', '${data.sampleCount}'),
            infoRow('Replicates', '${data.replicateCount}'),
            infoRow('Blank', '${data.blankCount}'),
            infoRow('Negative control', '${data.negativeControlCount}'),
            infoRow('Vehicle', '${data.vehicleCount}'),
            infoRow('Positive control', '${data.positiveControlCount}'),
            infoRow('Total controls', '${result.totalControlUnits}'),
            infoRow('Total sample units', '${result.totalSampleUnits}'),
            infoRow('Total culture units', '${result.totalCultureUnits}'),
            infoRow('Total cells needed', '${result.totalCellsNeeded} cells'),
            infoRow(
              'Total cells needed (+extra)',
              '${result.totalCellsNeededWithExtra} cells',
            ),
          ],
        ),
      ),
    );
  }

  Widget buildSuspensionCard() {
    final data = formData;
    final result = summary;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            infoRow(
              'Seeding volume / unit',
              '${data.seedingVolumePerUnit.toStringAsFixed(2)} mL',
            ),
            infoRow(
              'Stock concentration',
              '${data.stockConcentration.toStringAsFixed(0)} cells/mL',
            ),
            infoRow(
              'Extra',
              '${(data.extraPercent * 100).toStringAsFixed(0)} %',
            ),
            infoRow(
              'Total seeding volume',
              '${result.totalSeedingVolume.toStringAsFixed(2)} mL',
            ),
            infoRow(
              'Total seeding volume (+extra)',
              '${result.totalSeedingVolumeWithExtra.toStringAsFixed(2)} mL',
            ),
            infoRow(
              'Required cell suspension',
              '${result.requiredCellSuspensionVolume.toStringAsFixed(2)} mL',
            ),
            infoRow(
              'Required cell suspension (+extra)',
              '${result.requiredCellSuspensionVolumeWithExtra.toStringAsFixed(2)} mL',
            ),
            infoRow(
              'Required media volume',
              '${result.requiredMediaVolume.toStringAsFixed(2)} mL',
            ),
            infoRow(
              'Required media volume (+extra)',
              '${result.requiredMediaVolumeWithExtra.toStringAsFixed(2)} mL',
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
                controllerVm.recommendationText(selectedWare),
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
    _loadCellLines();
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
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              buildSectionTitle('Basic Information'),
              const SizedBox(height: 8),
              buildCellLineFilterSection(),
              const SizedBox(height: 12),
              buildCellLineAutocomplete(),
              const SizedBox(height: 12),
              buildSelectedCellLineCard(),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: selectedAssay,
                decoration: const InputDecoration(
                  labelText: 'Assay type',
                  border: OutlineInputBorder(),
                ),
                items: controllerVm.defaultDensityByAssay.keys.map((assay) {
                  return DropdownMenuItem<String>(
                    value: assay,
                    child: Text(assay),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value == null) return;
                  selectedAssay = value;
                  applyRecommendedDensity(
                    cellLine: selectedCellLine,
                    force: true,
                  );
                  autoGenerateLayout = true;
                  editablePlateLayout = buildGeneratedLayout();
                  setState(() {});
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
                items: controllerVm.cultureWareAreaMap.keys.map((ware) {
                  return DropdownMenuItem<String>(
                    value: ware,
                    child: Text(ware),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value == null) return;
                  selectedWare = value;
                  applyDefaultSeedingVolumeByWare(value);
                  autoGenerateLayout = true;
                  editablePlateLayout = buildGeneratedLayout();
                  setState(() {});
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
                onChanged: (_) => onCalculationInputChanged(),
              ),
              const SizedBox(height: 12),
              buildTextField(
                label: 'Sample count',
                controller: sampleCountController,
                keyboardType: TextInputType.number,
                onChanged: (_) => onLayoutRelevantInputChanged(),
              ),
              const SizedBox(height: 12),
              buildTextField(
                label: 'Replicates',
                controller: replicateController,
                keyboardType: TextInputType.number,
                onChanged: (_) => onLayoutRelevantInputChanged(),
              ),
              const SizedBox(height: 12),
              buildTextField(
                label: 'Blank count',
                controller: blankCountController,
                keyboardType: TextInputType.number,
                onChanged: (_) => onLayoutRelevantInputChanged(),
              ),
              const SizedBox(height: 12),
              buildTextField(
                label: 'Negative control count',
                controller: negativeControlCountController,
                keyboardType: TextInputType.number,
                onChanged: (_) => onLayoutRelevantInputChanged(),
              ),
              const SizedBox(height: 12),
              buildTextField(
                label: 'Vehicle count',
                controller: vehicleCountController,
                keyboardType: TextInputType.number,
                onChanged: (_) => onLayoutRelevantInputChanged(),
              ),
              const SizedBox(height: 12),
              buildTextField(
                label: 'Positive control count',
                controller: positiveControlCountController,
                keyboardType: TextInputType.number,
                onChanged: (_) => onLayoutRelevantInputChanged(),
              ),
              const SizedBox(height: 12),
              buildTextField(
                label: 'Target confluency (%)',
                controller: targetConfluencyController,
                keyboardType: TextInputType.number,
                onChanged: (_) => onCalculationInputChanged(),
              ),
              const SizedBox(height: 12),
              buildTextField(
                label: 'Seeding volume per unit (mL)',
                controller: seedingVolumeController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                onChanged: (_) => onCalculationInputChanged(),
              ),
              const SizedBox(height: 12),
              buildTextField(
                label: 'Cell stock concentration (cells/mL)',
                controller: stockConcentrationController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                onChanged: (_) => onCalculationInputChanged(),
              ),
              const SizedBox(height: 12),
              buildTextField(
                label: 'Extra (%)',
                controller: extraPercentController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                onChanged: (_) => onCalculationInputChanged(),
              ),
              const SizedBox(height: 20),

              buildRecommendedDensityCard(),
              const SizedBox(height: 12),

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
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}