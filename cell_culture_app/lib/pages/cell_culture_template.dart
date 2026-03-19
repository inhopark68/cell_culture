import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:open_filex/open_filex.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/cell_culture_form_data.dart';
import '../models/cell_culture_summary.dart';
import '../models/cell_line_option.dart';
import '../models/seeding_input_mode.dart';
import '../services/cell_culture_excel_service.dart';
import '../services/cell_culture_layout_service.dart';
import '../services/cell_line_catalog_service.dart';
import '../viewmodels/cell_culture_template_controller.dart';
import '../widgets/cell_culture_cell_line_autocomplete.dart';
import '../widgets/cell_culture_filter_section.dart';
import '../widgets/cell_culture_plate_layout_section.dart';
import '../widgets/cell_culture_recommended_density_card.dart';
import '../widgets/cell_culture_result_card.dart';
import '../widgets/cell_culture_selected_cell_line_card.dart';
import '../widgets/cell_culture_suspension_card.dart';

class CellCultureTemplatePage extends StatefulWidget {
  const CellCultureTemplatePage({super.key});

  @override
  State<CellCultureTemplatePage> createState() =>
      _CellCultureTemplatePageState();
}

class _CellCultureTemplatePageState extends State<CellCultureTemplatePage> {
  static const int maxCellLineSuggestions = 300;

  final _formKey = GlobalKey<FormState>();
  final controllerVm = CellCultureTemplateController();

  final TextEditingController seedingInputController =
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

  SeedingInputMode selectedSeedingInputMode = SeedingInputMode.cellsPerCm2;
  String selectedWellBasisWare = '24-well plate';

  String selectedSourceFilter = 'All';
  String selectedSpeciesFilter = 'All';

  final List<String> sourceFilters = [
    'All',
    'ATCC',
    'KCLB',
    'JCRB',
    'DSMZ',
    'ECACC',
    'RIKEN BRC',
    'CBCAS',
    'NCCS',
    'Custom',
  ];

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

  double get currentSurfaceArea =>
      controllerVm.cultureWareAreaMap[selectedWare] ?? 1.0;

  double get selectedWellBasisArea =>
      controllerVm.cultureWareAreaMap[selectedWellBasisWare] ?? 1.0;

  double? get normalizedSeedingDensity {
    final raw = double.tryParse(seedingInputController.text.trim());
    if (raw == null || raw <= 0) return null;

    switch (selectedSeedingInputMode) {
      case SeedingInputMode.cellsPerCm2:
        return raw;
      case SeedingInputMode.cellsPerWell:
        return raw / selectedWellBasisArea;
    }
  }

  double? get basisCellsPerWell {
    final density = normalizedSeedingDensity;
    if (density == null) return null;
    return density * selectedWellBasisArea;
  }

  double? get actualCellsPerCultureUnit {
    final density = normalizedSeedingDensity;
    if (density == null) return null;
    return density * currentSurfaceArea;
  }

  CellCultureFormData get formData => CellCultureFormData.fromRaw(
        selectedAssay: selectedAssay,
        selectedWare: selectedWare,
        seedingDensityText: (normalizedSeedingDensity ?? 0).toString(),
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

  double? get recommendedDensity => controllerVm.getRecommendedDensity(
        assay: selectedAssay,
        cellLine: selectedCellLine,
      );

  List<TextInputFormatter> integerInputFormatters() {
    return [
      FilteringTextInputFormatter.digitsOnly,
    ];
  }

  List<TextInputFormatter> decimalInputFormatters({int decimalRange = 2}) {
    return [
      FilteringTextInputFormatter.allow(
        RegExp(r'^\d*\.?\d{0,' + decimalRange.toString() + r'}'),
      ),
    ];
  }

  String? validateRequiredNumber(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName 값을 입력하세요.';
    }

    final n = double.tryParse(value.trim());
    if (n == null) {
      return '$fieldName 숫자 형식이 올바르지 않습니다.';
    }

    return null;
  }

  String? validatePositiveNumber(String? value, String fieldName) {
    final basic = validateRequiredNumber(value, fieldName);
    if (basic != null) return basic;

    final n = double.tryParse(value!.trim())!;
    if (n <= 0) {
      return '$fieldName 0보다 커야 합니다.';
    }

    return null;
  }

  String? validateNonNegativeInteger(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName 값을 입력하세요.';
    }

    final n = int.tryParse(value.trim());
    if (n == null) {
      return '$fieldName 정수를 입력하세요.';
    }

    if (n < 0) {
      return '$fieldName 0 이상이어야 합니다.';
    }

    return null;
  }

  String? validatePositiveInteger(String? value, String fieldName) {
    final basic = validateNonNegativeInteger(value, fieldName);
    if (basic != null) return basic;

    final n = int.parse(value!.trim());
    if (n <= 0) {
      return '$fieldName 1 이상이어야 합니다.';
    }

    return null;
  }

  String? validatePercent0to100(String? value, String fieldName) {
    final basic = validateRequiredNumber(value, fieldName);
    if (basic != null) return basic;

    final n = double.parse(value!.trim());
    if (n < 0 || n > 100) {
      return '$fieldName 0~100 범위여야 합니다.';
    }

    return null;
  }

  void applyRecommendedDensity({
    CellLineOption? cellLine,
    bool force = false,
  }) {
    final recommended = controllerVm.getRecommendedDensity(
      assay: selectedAssay,
      cellLine: cellLine,
    );

    if (recommended == null) return;

    final current = double.tryParse(seedingInputController.text);
    if (force || current == null || current <= 0) {
      final displayValue =
          selectedSeedingInputMode == SeedingInputMode.cellsPerCm2
              ? recommended
              : recommended * selectedWellBasisArea;

      seedingInputController.text = displayValue.toStringAsFixed(0);
    }
  }

  void applyDefaultDensityByAssay(String assay) {
    final density = controllerVm.defaultDensityForAssay(assay);
    if (density != null) {
      final displayValue =
          selectedSeedingInputMode == SeedingInputMode.cellsPerCm2
              ? density
              : density * selectedWellBasisArea;

      seedingInputController.text = displayValue.toStringAsFixed(0);
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

      for (final item in items) {
        if (CellLineCatalogService.hasAlias(item, 'hela')) {
          matched = item;
          break;
        }
      }

      if (matched != null) {
        applyRecommendedDensity(cellLine: matched, force: true);
      }

      setState(() {
        cellLineOptions = items;
        selectedCellLine = matched;
        if (matched != null) {
          autoGenerateLayout = true;
          editablePlateLayout = buildGeneratedLayout();
        }
        isLoadingCellLines = false;
      });
    } catch (e) {
      debugPrint('Failed to load cell lines: $e');
      if (!mounted) return;

      setState(() {
        isLoadingCellLines = false;
        selectedCellLine = null;
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
    }
  }

  Iterable<CellLineOption> filterCellLineOptions(String query) {
    final normalizedQuery = CellLineCatalogService.normalizeCellLineText(query);

    final filtered = cellLineOptions.where((item) {
      final matchesQuery = CellLineCatalogService.matchesQuery(item, query);

      final matchesSource = selectedSourceFilter == 'All' ||
          item.source.toUpperCase() == selectedSourceFilter.toUpperCase();

      final matchesSpecies = controllerVm.speciesMatches(
        item.species,
        selectedSpeciesFilter,
      );

      return matchesQuery && matchesSource && matchesSpecies;
    }).toList();

    filtered.sort((a, b) {
      final aStarts = normalizedQuery.isNotEmpty &&
              (CellLineCatalogService.normalizeCellLineText(a.primaryName)
                      .startsWith(normalizedQuery) ||
                  a.synonyms.any(
                    (s) => CellLineCatalogService.normalizeCellLineText(s)
                        .startsWith(normalizedQuery),
                  ))
          ? 0
          : 1;

      final bStarts = normalizedQuery.isNotEmpty &&
              (CellLineCatalogService.normalizeCellLineText(b.primaryName)
                      .startsWith(normalizedQuery) ||
                  b.synonyms.any(
                    (s) => CellLineCatalogService.normalizeCellLineText(s)
                        .startsWith(normalizedQuery),
                  ))
          ? 0
          : 1;

      if (aStarts != bStarts) return aStarts.compareTo(bStarts);
      if (a.source != b.source) return a.source.compareTo(b.source);
      return a.primaryName.compareTo(b.primaryName);
    });

    return filtered.take(maxCellLineSuggestions);
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

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit Well ${String.fromCharCode(65 + row)}${col + 1}'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'Label',
              border: OutlineInputBorder(),
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
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('입력값을 다시 확인해주세요.')),
      );
      return;
    }

    final data = formData;
    final result = summary;

    if (selectedCellLine == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cell line은 ATCC 또는 KCLB catalog에서 선택해야 합니다.'),
        ),
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
            onPressed: () async => openSavedExcelFile(path),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('엑셀 저장 중 오류 발생: $e')),
      );
    }
  }

  Future<void> openSavedExcelFile(String path) async {
    final result = await OpenFilex.open(path);
    debugPrint('Open file result: ${result.type} / ${result.message}');
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
    ValueChanged<String>? onChanged,
    String? Function(String?)? validator,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      autovalidateMode: AutovalidateMode.onUserInteraction,
      validator: validator,
      onChanged: onChanged,
    );
  }

  @override
  void initState() {
    super.initState();
    selectedWellBasisWare = selectedWare;
    applyDefaultDensityByAssay(selectedAssay);
    applyDefaultSeedingVolumeByWare(selectedWare);
    editablePlateLayout = buildGeneratedLayout();
    _loadCellLines();
  }

  @override
  void dispose() {
    seedingInputController.dispose();
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
    final data = formData;
    final result = summary;

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
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                buildSectionTitle('Basic Information'),
                const SizedBox(height: 8),
                CellCultureFilterSection(
                  sourceFilters: sourceFilters,
                  speciesFilters: speciesFilters,
                  selectedSourceFilter: selectedSourceFilter,
                  selectedSpeciesFilter: selectedSpeciesFilter,
                  onSourceChanged: (value) {
                    setState(() {
                      selectedSourceFilter = value;
                      clearSelectedCellLineIfFilteredOut();
                    });
                  },
                  onSpeciesChanged: (value) {
                    setState(() {
                      selectedSpeciesFilter = value;
                      clearSelectedCellLineIfFilteredOut();
                    });
                  },
                ),
                const SizedBox(height: 12),
                CellCultureCellLineAutocomplete(
                  isLoading: isLoadingCellLines,
                  selectedLabel: selectedCellLine?.displayLabel ?? '',
                  optionsBuilder: filterCellLineOptions,
                  onSelected: (option) {
                    selectedCellLine = option;
                    applyRecommendedDensity(cellLine: option, force: true);
                    autoGenerateLayout = true;
                    editablePlateLayout = buildGeneratedLayout();
                    setState(() {});
                  },
                  onChanged: (_) {
                    setState(() {
                      selectedCellLine = null;
                    });
                  },
                ),
                const SizedBox(height: 12),
                CellCultureSelectedCellLineCard(
                  selectedCellLine: selectedCellLine,
                  selectedSourceFilter: selectedSourceFilter,
                  selectedSpeciesFilter: selectedSpeciesFilter,
                  onOpenSource: openSelectedCellLineSource,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedAssay,
                  decoration: const InputDecoration(
                    labelText: 'Assay type',
                    border: OutlineInputBorder(),
                  ),
                  items: controllerVm.defaultDensityByAssay.keys.map((assay) {
                    return DropdownMenuItem(value: assay, child: Text(assay));
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
                    return DropdownMenuItem(value: ware, child: Text(ware));
                  }).toList(),
                  onChanged: (value) {
                    if (value == null) return;

                    setState(() {
                      selectedWare = value;
                      applyDefaultSeedingVolumeByWare(value);
                      autoGenerateLayout = true;
                      editablePlateLayout = buildGeneratedLayout();
                    });
                  },
                ),
                const SizedBox(height: 20),
                buildSectionTitle('Seeding Conditions'),
                const SizedBox(height: 8),
                DropdownButtonFormField<SeedingInputMode>(
                  value: selectedSeedingInputMode,
                  decoration: const InputDecoration(
                    labelText: 'Seeding input mode',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: SeedingInputMode.cellsPerCm2,
                      child: Text('cells/cm²'),
                    ),
                    DropdownMenuItem(
                      value: SeedingInputMode.cellsPerWell,
                      child: Text('cells/well'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value == null) return;

                    final currentRaw =
                        double.tryParse(seedingInputController.text.trim());

                    setState(() {
                      if (currentRaw != null && currentRaw > 0) {
                        if (selectedSeedingInputMode ==
                                SeedingInputMode.cellsPerCm2 &&
                            value == SeedingInputMode.cellsPerWell) {
                          seedingInputController.text =
                              (currentRaw * selectedWellBasisArea)
                                  .toStringAsFixed(0);
                        } else if (selectedSeedingInputMode ==
                                SeedingInputMode.cellsPerWell &&
                            value == SeedingInputMode.cellsPerCm2) {
                          seedingInputController.text =
                              (currentRaw / selectedWellBasisArea)
                                  .toStringAsFixed(2);
                        }
                      }

                      selectedSeedingInputMode = value;
                    });
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedWellBasisWare,
                  decoration: const InputDecoration(
                    labelText: 'Well basis plate',
                    border: OutlineInputBorder(),
                  ),
                  items: controllerVm.cultureWareAreaMap.keys.map((ware) {
                    return DropdownMenuItem(
                      value: ware,
                      child: Text(ware),
                    );
                  }).toList(),
                  onChanged:
                      selectedSeedingInputMode == SeedingInputMode.cellsPerWell
                          ? (value) {
                              if (value == null) return;

                              final currentRaw = double.tryParse(
                                seedingInputController.text.trim(),
                              );

                              setState(() {
                                if (currentRaw != null && currentRaw > 0) {
                                  final density =
                                      currentRaw / selectedWellBasisArea;
                                  selectedWellBasisWare = value;
                                  final newDisplay =
                                      density * selectedWellBasisArea;
                                  seedingInputController.text =
                                      newDisplay.toStringAsFixed(0);
                                } else {
                                  selectedWellBasisWare = value;
                                }
                              });
                            }
                          : null,
                ),
                const SizedBox(height: 12),
                buildTextField(
                  label: selectedSeedingInputMode == SeedingInputMode.cellsPerCm2
                      ? 'Seeding density (cells/cm²)'
                      : 'Seeding amount (cells/well, based on $selectedWellBasisWare)',
                  controller: seedingInputController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: decimalInputFormatters(decimalRange: 2),
                  validator: (value) => validatePositiveNumber(
                    value,
                    selectedSeedingInputMode == SeedingInputMode.cellsPerCm2
                        ? 'Seeding density'
                        : 'Seeding amount',
                  ),
                  onChanged: (_) => onCalculationInputChanged(),
                ),
                const SizedBox(height: 8),
                if (normalizedSeedingDensity != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Normalized: ${normalizedSeedingDensity!.toStringAsFixed(2)} cells/cm²\n'
                      'Basis plate: ${basisCellsPerWell?.toStringAsFixed(0) ?? '-'} cells/well ($selectedWellBasisWare)\n'
                      'Actual culture ware: ${actualCellsPerCultureUnit?.toStringAsFixed(0) ?? '-'} cells/well ($selectedWare)',
                    ),
                  ),
                const SizedBox(height: 12),
                buildTextField(
                  label: 'Sample count',
                  controller: sampleCountController,
                  keyboardType: TextInputType.number,
                  inputFormatters: integerInputFormatters(),
                  validator: (value) =>
                      validateNonNegativeInteger(value, 'Sample count'),
                  onChanged: (_) => onLayoutRelevantInputChanged(),
                ),
                const SizedBox(height: 12),
                buildTextField(
                  label: 'Replicates',
                  controller: replicateController,
                  keyboardType: TextInputType.number,
                  inputFormatters: integerInputFormatters(),
                  validator: (value) =>
                      validatePositiveInteger(value, 'Replicates'),
                  onChanged: (_) => onLayoutRelevantInputChanged(),
                ),
                const SizedBox(height: 12),
                buildTextField(
                  label: 'Blank count',
                  controller: blankCountController,
                  keyboardType: TextInputType.number,
                  inputFormatters: integerInputFormatters(),
                  validator: (value) =>
                      validateNonNegativeInteger(value, 'Blank count'),
                  onChanged: (_) => onLayoutRelevantInputChanged(),
                ),
                const SizedBox(height: 12),
                buildTextField(
                  label: 'Negative control count',
                  controller: negativeControlCountController,
                  keyboardType: TextInputType.number,
                  inputFormatters: integerInputFormatters(),
                  validator: (value) => validateNonNegativeInteger(
                    value,
                    'Negative control count',
                  ),
                  onChanged: (_) => onLayoutRelevantInputChanged(),
                ),
                const SizedBox(height: 12),
                buildTextField(
                  label: 'Vehicle count',
                  controller: vehicleCountController,
                  keyboardType: TextInputType.number,
                  inputFormatters: integerInputFormatters(),
                  validator: (value) =>
                      validateNonNegativeInteger(value, 'Vehicle count'),
                  onChanged: (_) => onLayoutRelevantInputChanged(),
                ),
                const SizedBox(height: 12),
                buildTextField(
                  label: 'Positive control count',
                  controller: positiveControlCountController,
                  keyboardType: TextInputType.number,
                  inputFormatters: integerInputFormatters(),
                  validator: (value) => validateNonNegativeInteger(
                    value,
                    'Positive control count',
                  ),
                  onChanged: (_) => onLayoutRelevantInputChanged(),
                ),
                const SizedBox(height: 12),
                buildTextField(
                  label: 'Target confluency (%)',
                  controller: targetConfluencyController,
                  keyboardType: TextInputType.number,
                  inputFormatters: integerInputFormatters(),
                  validator: (value) =>
                      validatePercent0to100(value, 'Target confluency'),
                  onChanged: (_) => onCalculationInputChanged(),
                ),
                const SizedBox(height: 12),
                buildTextField(
                  label: 'Seeding volume per unit (mL)',
                  controller: seedingVolumeController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: decimalInputFormatters(decimalRange: 2),
                  validator: (value) => validatePositiveNumber(
                    value,
                    'Seeding volume per unit',
                  ),
                  onChanged: (_) => onCalculationInputChanged(),
                ),
                const SizedBox(height: 12),
                buildTextField(
                  label: 'Cell stock concentration (cells/mL)',
                  controller: stockConcentrationController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: decimalInputFormatters(decimalRange: 2),
                  validator: (value) => validatePositiveNumber(
                    value,
                    'Cell stock concentration',
                  ),
                  onChanged: (_) => onCalculationInputChanged(),
                ),
                const SizedBox(height: 12),
                buildTextField(
                  label: 'Extra (%)',
                  controller: extraPercentController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: decimalInputFormatters(decimalRange: 2),
                  validator: (value) => validateRequiredNumber(value, 'Extra'),
                  onChanged: (_) => onCalculationInputChanged(),
                ),
                const SizedBox(height: 20),
                CellCultureRecommendedDensityCard(
                  recommendedDensity: recommendedDensity,
                  selectedCellLine: selectedCellLine,
                  selectedAssay: selectedAssay,
                  onApply: () {
                    if (recommendedDensity == null) return;

                    final displayValue =
                        selectedSeedingInputMode == SeedingInputMode.cellsPerCm2
                            ? recommendedDensity!
                            : recommendedDensity! * selectedWellBasisArea;

                    seedingInputController.text =
                        displayValue.toStringAsFixed(0);

                    setState(() {});
                  },
                ),
                const SizedBox(height: 12),
                buildSectionTitle('Calculated Result'),
                const SizedBox(height: 8),
                CellCultureResultCard(
                  form: data,
                  summary: result,
                  selectedCellLine: selectedCellLine,
                  selectedSeedingInputMode: selectedSeedingInputMode,
                  selectedWellBasisWare: selectedWellBasisWare,
                  basisCellsPerWell: basisCellsPerWell,
                  actualCellsPerCultureUnit: actualCellsPerCultureUnit,
                ),
                const SizedBox(height: 12),
                buildSectionTitle('Suspension Preparation'),
                const SizedBox(height: 8),
                CellCultureSuspensionCard(
                  form: data,
                  summary: result,
                  selectedSeedingInputMode: selectedSeedingInputMode,
                  selectedWellBasisWare: selectedWellBasisWare,
                  basisCellsPerWell: basisCellsPerWell,
                  actualCellsPerCultureUnit: actualCellsPerCultureUnit,
                ),
                const SizedBox(height: 12),
                buildSectionTitle('Plate Layout'),
                const SizedBox(height: 8),
                CellCulturePlateLayoutSection(
                  layout: editablePlateLayout,
                  autoGenerateLayout: autoGenerateLayout,
                  onRegenerate: regenerateLayout,
                  onClear: clearLayout,
                  onEditWell: (row, col) => editWellDialog(row: row, col: col),
                  onSwap: (fromRow, fromCol, toRow, toCol) {
                    setState(() {
                      CellCultureLayoutService.swapWells(
                        layout: editablePlateLayout,
                        fromRow: fromRow,
                        fromCol: fromCol,
                        toRow: toRow,
                        toCol: toCol,
                      );
                      autoGenerateLayout = false;
                    });
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}