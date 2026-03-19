import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:open_filex/open_filex.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  static const String _customCellLinesPrefsKey = 'custom_cell_lines_v1';

  final _formKey = GlobalKey<FormState>();
  final controllerVm = CellCultureTemplateController();

  final TextEditingController cellLineTextController = TextEditingController();
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

  List<CellLineOption> get customCellLines => cellLineOptions
      .where((e) => e.source.toUpperCase() == 'CUSTOM')
      .toList()
    ..sort((a, b) => a.primaryName.compareTo(b.primaryName));

  bool get canUseCustomPicker =>
      selectedSourceFilter == 'All' || selectedSourceFilter == 'Custom';

  void selectCellLine(CellLineOption option) {
    selectedCellLine = option;
    cellLineTextController.text = option.displayLabel;
    applyRecommendedDensity(cellLine: option, force: true);
    autoGenerateLayout = true;
    editablePlateLayout = buildGeneratedLayout();
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

  Future<void> _loadSavedCustomCellLines() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rawList = prefs.getStringList(_customCellLinesPrefsKey) ?? const [];

      final savedItems = rawList
          .map((e) => jsonDecode(e) as Map<String, dynamic>)
          .map(CellLineOption.fromJson)
          .where((e) => e.source.toUpperCase() == 'CUSTOM')
          .toList();

      if (!mounted || savedItems.isEmpty) return;

      final existingIds = cellLineOptions.map(_customCellIdentity).toSet();
      final merged = [...cellLineOptions];

      for (final item in savedItems) {
        if (!existingIds.contains(_customCellIdentity(item))) {
          merged.add(item);
        }
      }

      setState(() {
        cellLineOptions = merged;
      });
    } catch (e) {
      debugPrint('Failed to load saved custom cell lines: $e');
    }
  }

  Future<void> _saveCustomCellLines() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = customCellLines.map((e) => jsonEncode(e.toJson())).toList();
      await prefs.setStringList(_customCellLinesPrefsKey, encoded);
    } catch (e) {
      debugPrint('Failed to save custom cell lines: $e');
    }
  }

  Future<void> _clearAllCustomCellLines() async {
    setState(() {
      cellLineOptions = cellLineOptions
          .where((e) => e.source.toUpperCase() != 'CUSTOM')
          .toList();

      if (selectedCellLine?.source.toUpperCase() == 'CUSTOM') {
        selectedCellLine = null;
        cellLineTextController.clear();
      }
    });

    await _saveCustomCellLines();
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
        cellLineTextController.text = matched?.displayLabel ?? '';
        if (matched != null) {
          autoGenerateLayout = true;
          editablePlateLayout = buildGeneratedLayout();
        }
        isLoadingCellLines = false;
      });

      await _loadSavedCustomCellLines();
    } catch (e) {
      debugPrint('Failed to load cell lines: $e');
      if (!mounted) return;

      setState(() {
        isLoadingCellLines = false;
        selectedCellLine = null;
        cellLineTextController.clear();
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
      cellLineTextController.clear();
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

  CellLineOption? _findExistingCustomCellLineByName(String input) {
    final normalizedInput =
        CellLineCatalogService.normalizeCellLineText(input.trim());

    for (final item in customCellLines) {
      final normalizedName =
          CellLineCatalogService.normalizeCellLineText(item.primaryName);
      if (normalizedName == normalizedInput) {
        return item;
      }
    }
    return null;
  }

  CellLineOption _buildCustomCellLineOption({
    required String primaryName,
    required String source,
    required String catalogNumber,
    required List<String> synonyms,
    String? species,
    String? tissue,
    String? disease,
    String? cvclId,
    String? rrid,
    bool isMisidentified = false,
    String? misidentifiedNote,
  }) {
    return CellLineOption(
      primaryName: primaryName.trim(),
      synonyms: synonyms
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList(),
      source: source.trim().isEmpty ? 'CUSTOM' : source.trim().toUpperCase(),
      catalogNumber: catalogNumber.trim().isEmpty
          ? 'CUSTOM-${primaryName.trim().toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]+'), '-')}'
          : catalogNumber.trim(),
      cvclId: (cvclId?.trim().isEmpty ?? true) ? null : cvclId!.trim(),
      rrid: (rrid?.trim().isEmpty ?? true) ? null : rrid!.trim(),
      species: (species?.trim().isEmpty ?? true) ? null : species!.trim(),
      tissue: (tissue?.trim().isEmpty ?? true) ? null : tissue!.trim(),
      disease: (disease?.trim().isEmpty ?? true) ? null : disease!.trim(),
      isMisidentified: isMisidentified,
      misidentifiedNote: isMisidentified
          ? ((misidentifiedNote?.trim().isEmpty ?? true)
              ? null
              : misidentifiedNote!.trim())
          : null,
    );
  }

  String _customCellIdentity(CellLineOption item) {
    return [
      item.primaryName.trim().toUpperCase(),
      item.source.trim().toUpperCase(),
      item.catalogNumber.trim().toUpperCase(),
    ].join('|');
  }

  void _upsertCustomCellLine(CellLineOption newItem, {CellLineOption? oldItem}) {
    final newId = _customCellIdentity(newItem);
    final oldId = oldItem == null ? null : _customCellIdentity(oldItem);

    final updated = <CellLineOption>[];
    bool replaced = false;

    for (final item in cellLineOptions) {
      final id = _customCellIdentity(item);

      if (oldId != null && id == oldId) {
        updated.add(newItem);
        replaced = true;
        continue;
      }

      if (oldId == null &&
          item.source.toUpperCase() == 'CUSTOM' &&
          id == newId) {
        updated.add(newItem);
        replaced = true;
        continue;
      }

      updated.add(item);
    }

    if (!replaced) {
      updated.add(newItem);
    }

    cellLineOptions = updated;
    selectedSourceFilter = 'Custom';
    selectCellLine(newItem);
    _saveCustomCellLines();
  }

  void _deleteCustomCellLine(CellLineOption item) {
    final deleteId = _customCellIdentity(item);

    cellLineOptions = cellLineOptions.where((e) {
      return _customCellIdentity(e) != deleteId;
    }).toList();

    if (selectedCellLine != null &&
        _customCellIdentity(selectedCellLine!) == deleteId) {
      selectedCellLine = null;
      cellLineTextController.clear();
    }

    _saveCustomCellLines();
  }

  Future<bool> _confirmDeleteCustomCellLine(CellLineOption item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      useRootNavigator: true,
      builder: (context) {
        return AlertDialog(
          title: const Text('Custom cell line 삭제'),
          content: Text('${item.primaryName} 항목을 삭제할까요?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('삭제'),
            ),
          ],
        );
      },
    );

    return confirmed == true;
  }

  Future<bool> _confirmClearAllCustomCellLines() async {
    final confirmed = await showDialog<bool>(
      context: context,
      useRootNavigator: true,
      builder: (context) {
        return AlertDialog(
          title: const Text('전체 삭제'),
          content: const Text('저장된 모든 Custom cell line을 삭제할까요?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('전체 삭제'),
            ),
          ],
        );
      },
    );

    return confirmed == true;
  }

  Future<CellLineOption?> _showCustomCellLineEditor({
    CellLineOption? initial,
  }) async {
    final formKey = GlobalKey<FormState>();

    final primaryNameController =
        TextEditingController(text: initial?.primaryName ?? '');
    final sourceController = TextEditingController(
      text:
          initial?.source == 'CUSTOM' ? 'CUSTOM' : (initial?.source ?? 'CUSTOM'),
    );
    final catalogNumberController =
        TextEditingController(text: initial?.catalogNumber ?? '');
    final speciesController =
        TextEditingController(text: initial?.species ?? '');
    final tissueController =
        TextEditingController(text: initial?.tissue ?? '');
    final diseaseController =
        TextEditingController(text: initial?.disease ?? '');
    final cvclIdController =
        TextEditingController(text: initial?.cvclId ?? '');
    final rridController =
        TextEditingController(text: initial?.rrid ?? '');
    final synonymsController =
        TextEditingController(text: initial?.synonyms.join(', '));
    final misidentifiedNoteController =
        TextEditingController(text: initial?.misidentifiedNote ?? '');

    bool isMisidentified = initial?.isMisidentified ?? false;

    final result = await showDialog<CellLineOption?>(
      context: context,
      useRootNavigator: true,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, modalSetState) {
            return AlertDialog(
              title: Text(
                initial == null ? 'Custom cell line 추가' : 'Custom cell line 수정',
              ),
              content: SizedBox(
                width: 520,
                child: SingleChildScrollView(
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextFormField(
                          controller: primaryNameController,
                          decoration: const InputDecoration(
                            labelText: 'Cell name *',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Cell name을 입력하세요.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: sourceController,
                          decoration: const InputDecoration(
                            labelText: 'Source',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: catalogNumberController,
                          decoration: const InputDecoration(
                            labelText: 'Catalog number',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: speciesController,
                          decoration: const InputDecoration(
                            labelText: 'Species',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: tissueController,
                          decoration: const InputDecoration(
                            labelText: 'Tissue',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: diseaseController,
                          decoration: const InputDecoration(
                            labelText: 'Disease',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: cvclIdController,
                          decoration: const InputDecoration(
                            labelText: 'CVCL ID',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: rridController,
                          decoration: const InputDecoration(
                            labelText: 'RRID',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: synonymsController,
                          decoration: const InputDecoration(
                            labelText: 'Synonyms (comma-separated)',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Misidentified'),
                          value: isMisidentified,
                          onChanged: (value) {
                            modalSetState(() {
                              isMisidentified = value;
                            });
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: misidentifiedNoteController,
                          enabled: isMisidentified,
                          decoration: const InputDecoration(
                            labelText: 'Misidentified note',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, null),
                  child: const Text('취소'),
                ),
                FilledButton(
                  onPressed: () {
                    if (!(formKey.currentState?.validate() ?? false)) {
                      return;
                    }

                    final normalizedName = primaryNameController.text.trim();
                    final existingByName =
                        _findExistingCustomCellLineByName(normalizedName);

                    final isDuplicatedCreate =
                        initial == null && existingByName != null;

                    final isDuplicatedRename = initial != null &&
                        existingByName != null &&
                        _customCellIdentity(existingByName) !=
                            _customCellIdentity(initial);

                    if (isDuplicatedCreate || isDuplicatedRename) {
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        const SnackBar(
                          content: Text('같은 이름의 Custom cell line이 이미 있습니다.'),
                        ),
                      );
                      return;
                    }

                    final synonyms = synonymsController.text
                        .split(',')
                        .map((e) => e.trim())
                        .where((e) => e.isNotEmpty)
                        .toList();

                    final newItem = _buildCustomCellLineOption(
                      primaryName: primaryNameController.text,
                      source: sourceController.text,
                      catalogNumber: catalogNumberController.text,
                      synonyms: synonyms,
                      species: speciesController.text,
                      tissue: tissueController.text,
                      disease: diseaseController.text,
                      cvclId: cvclIdController.text,
                      rrid: rridController.text,
                      isMisidentified: isMisidentified,
                      misidentifiedNote: misidentifiedNoteController.text,
                    );

                    Navigator.pop(dialogContext, newItem);
                  },
                  child: const Text('저장'),
                ),
              ],
            );
          },
        );
      },
    );

    primaryNameController.dispose();
    sourceController.dispose();
    catalogNumberController.dispose();
    speciesController.dispose();
    tissueController.dispose();
    diseaseController.dispose();
    cvclIdController.dispose();
    rridController.dispose();
    synonymsController.dispose();
    misidentifiedNoteController.dispose();

    return result;
  }

  Future<void> _showCustomCellLinePicker() async {
    String keyword = '';

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, modalSetState) {
            final visibleCustomCells = customCellLines.where((cell) {
              final matchesSpecies = controllerVm.speciesMatches(
                cell.species,
                selectedSpeciesFilter,
              );

              final q = keyword.trim().toLowerCase();

              final matchesKeyword = q.isEmpty ||
                  cell.primaryName.toLowerCase().contains(q) ||
                  cell.synonyms.any((s) => s.toLowerCase().contains(q)) ||
                  cell.catalogNumber.toLowerCase().contains(q) ||
                  (cell.species ?? '').toLowerCase().contains(q) ||
                  (cell.tissue ?? '').toLowerCase().contains(q) ||
                  (cell.disease ?? '').toLowerCase().contains(q);

              return matchesSpecies && matchesKeyword;
            }).toList()
              ..sort((a, b) => a.primaryName.compareTo(b.primaryName));

            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: SizedBox(
                height: 560,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Custom cell lines',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ),
                        if (customCellLines.isNotEmpty)
                          TextButton(
                            onPressed: () async {
                              final confirmed =
                                  await _confirmClearAllCustomCellLines();
                              if (!mounted) return;

                              if (confirmed) {
                                await _clearAllCustomCellLines();
                                if (!mounted) return;

                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      '모든 Custom cell line이 삭제되었습니다.',
                                    ),
                                  ),
                                );
                                modalSetState(() {});
                              }
                            },
                            child: const Text('전체 삭제'),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text('직접 추가, 수정, 삭제하거나 목록에서 선택하세요.'),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            decoration: const InputDecoration(
                              labelText: '검색',
                              hintText:
                                  'name, species, tissue, catalog number...',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.search),
                            ),
                            onChanged: (value) {
                              modalSetState(() {
                                keyword = value;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        FilledButton.icon(
                          onPressed: () async {
                            final created = await _showCustomCellLineEditor();
                            if (!mounted) return;

                            if (created != null) {
                              setState(() {
                                _upsertCustomCellLine(created);
                              });

                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Custom cell line이 추가되었습니다.'),
                                ),
                              );
                            }

                            modalSetState(() {});
                          },
                          icon: const Icon(Icons.add),
                          label: const Text('새 Custom'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: visibleCustomCells.isEmpty
                          ? const Center(
                              child: Text('등록된 custom cell line이 없습니다.'),
                            )
                          : ListView.separated(
                              itemCount: visibleCustomCells.length,
                              separatorBuilder: (_, __) =>
                                  const Divider(height: 1),
                              itemBuilder: (context, index) {
                                final cell = visibleCustomCells[index];
                                final isSelected = selectedCellLine != null &&
                                    _customCellIdentity(selectedCellLine!) ==
                                        _customCellIdentity(cell);

                                final meta = <String>[
                                  cell.source,
                                  if (cell.catalogNumber.trim().isNotEmpty)
                                    cell.catalogNumber.trim(),
                                  if ((cell.species ?? '').trim().isNotEmpty)
                                    cell.species!.trim(),
                                  if ((cell.tissue ?? '').trim().isNotEmpty)
                                    cell.tissue!.trim(),
                                ];

                                final subLines = <String>[
                                  meta.join(' • '),
                                  if ((cell.disease ?? '').trim().isNotEmpty)
                                    'Disease: ${cell.disease!.trim()}',
                                  if (cell.synonyms.isNotEmpty)
                                    'Synonyms: ${cell.synonyms.join(', ')}',
                                  if ((cell.cvclId ?? '').trim().isNotEmpty)
                                    'CVCL: ${cell.cvclId!.trim()}',
                                  if ((cell.rrid ?? '').trim().isNotEmpty)
                                    'RRID: ${cell.rrid!.trim()}',
                                  if (cell.isMisidentified)
                                    'Misidentified${(cell.misidentifiedNote ?? '').trim().isNotEmpty ? ' - ${cell.misidentifiedNote!.trim()}' : ''}',
                                ];

                                return ListTile(
                                  isThreeLine: true,
                                  title: Text(cell.primaryName),
                                  subtitle: Text(subLines.join('\n')),
                                  leading: isSelected
                                      ? const Icon(Icons.check_circle)
                                      : const Icon(Icons.biotech_outlined),
                                  onTap: () {
                                    Navigator.of(sheetContext).pop();
                                    setState(() {
                                      selectedSourceFilter = 'Custom';
                                      selectCellLine(cell);
                                    });
                                  },
                                  trailing: SizedBox(
                                    width: 96,
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          tooltip: '수정',
                                          onPressed: () async {
                                            final edited =
                                                await _showCustomCellLineEditor(
                                              initial: cell,
                                            );
                                            if (!mounted) return;

                                            if (edited != null) {
                                              setState(() {
                                                _upsertCustomCellLine(
                                                  edited,
                                                  oldItem: cell,
                                                );
                                              });

                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                    'Custom cell line이 수정되었습니다.',
                                                  ),
                                                ),
                                              );
                                            }

                                            modalSetState(() {});
                                          },
                                          icon:
                                              const Icon(Icons.edit_outlined),
                                        ),
                                        IconButton(
                                          tooltip: '삭제',
                                          onPressed: () async {
                                            final confirmed =
                                                await _confirmDeleteCustomCellLine(
                                              cell,
                                            );
                                            if (!mounted) return;

                                            if (confirmed) {
                                              setState(() {
                                                _deleteCustomCellLine(cell);
                                              });

                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                    'Custom cell line이 삭제되었습니다.',
                                                  ),
                                                ),
                                              );
                                            }

                                            modalSetState(() {});
                                          },
                                          icon:
                                              const Icon(Icons.delete_outline),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            );
          },
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
          content: Text('Cell line은 catalog에서 선택하거나 custom으로 입력해야 합니다.'),
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
    cellLineTextController.dispose();
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
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: CellCultureCellLineAutocomplete(
                        isLoading: isLoadingCellLines,
                        selectedLabel: selectedCellLine?.displayLabel ?? '',
                        controller: cellLineTextController,
                        optionsBuilder: filterCellLineOptions,
                        onSelected: (option) {
                          setState(() {
                            selectCellLine(option);
                          });
                        },
                        onChanged: (text) {
                          if (selectedCellLine != null &&
                              text.trim() == selectedCellLine!.displayLabel) {
                            return;
                          }

                          setState(() {
                            selectedCellLine = null;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      height: 56,
                      child: OutlinedButton.icon(
                        onPressed: canUseCustomPicker
                            ? _showCustomCellLinePicker
                            : null,
                        icon: const Icon(Icons.add_box_outlined),
                        label: const Text('Custom'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Builder(
                  builder: (context) {
                    final visibleCustomCells = customCellLines.where((cell) {
                      final matchesSource = selectedSourceFilter == 'All' ||
                          cell.source.toUpperCase() ==
                              selectedSourceFilter.toUpperCase();

                      final matchesSpecies = controllerVm.speciesMatches(
                        cell.species,
                        selectedSpeciesFilter,
                      );

                      return matchesSource && matchesSpecies;
                    }).toList();

                    if (visibleCustomCells.isEmpty) {
                      return const SizedBox.shrink();
                    }

                    return Align(
                      alignment: Alignment.centerLeft,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Custom cell lines',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: visibleCustomCells.map((cell) {
                              final isSelected =
                                  selectedCellLine?.primaryName ==
                                          cell.primaryName &&
                                      selectedCellLine?.source == cell.source &&
                                      selectedCellLine?.catalogNumber ==
                                          cell.catalogNumber;

                              return OutlinedButton(
                                onPressed: () {
                                  setState(() {
                                    selectCellLine(cell);
                                  });
                                },
                                style: OutlinedButton.styleFrom(
                                  backgroundColor: isSelected
                                      ? Theme.of(context)
                                          .colorScheme
                                          .primaryContainer
                                      : null,
                                ),
                                child: Text(cell.primaryName),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    );
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
                    setState(() {
                      selectedAssay = value;
                      applyRecommendedDensity(
                        cellLine: selectedCellLine,
                        force: true,
                      );
                      autoGenerateLayout = true;
                      editablePlateLayout = buildGeneratedLayout();
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
                      color: Theme.of(context).colorScheme.surfaceVariant,
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