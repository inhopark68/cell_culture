import 'package:flutter/material.dart';

import '../models/cell_line_option.dart';
import '../services/cell_line_catalog_service.dart';

class CustomCellManagerResult {
  final List<CellLineOption> items;
  final CellLineOption? selectedItem;

  const CustomCellManagerResult({
    required this.items,
    required this.selectedItem,
  });
}

class CustomCellLineManagerPage extends StatefulWidget {
  final List<CellLineOption> initialItems;
  final CellLineOption? selectedItem;
  final String selectedSpeciesFilter;

  const CustomCellLineManagerPage({
    super.key,
    required this.initialItems,
    required this.selectedItem,
    required this.selectedSpeciesFilter,
  });

  @override
  State<CustomCellLineManagerPage> createState() =>
      _CustomCellLineManagerPageState();
}

class _CustomCellLineManagerPageState
    extends State<CustomCellLineManagerPage> {
  final TextEditingController searchController = TextEditingController();

  late List<CellLineOption> items;
  CellLineOption? selectedItem;
  String keyword = '';

  @override
  void initState() {
    super.initState();
    items = [...widget.initialItems];
    selectedItem = widget.selectedItem;
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  String _identity(CellLineOption item) {
    return [
      item.primaryName.trim().toUpperCase(),
      item.source.trim().toUpperCase(),
      item.catalogNumber.trim().toUpperCase(),
    ].join('|');
  }

  bool _speciesMatches(String? species, String filter) {
    if (filter == 'All') return true;
    return (species ?? '').trim().toLowerCase() == filter.trim().toLowerCase();
  }

  CellLineOption? _findByName(String input) {
    final normalized = CellLineCatalogService.normalizeCellLineText(input.trim());
    for (final item in items) {
      final n = CellLineCatalogService.normalizeCellLineText(item.primaryName);
      if (n == normalized) return item;
    }
    return null;
  }

  CellLineOption _buildItem({
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
      synonyms:
          synonyms.map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
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

  Future<CellLineOption?> _showEditor({CellLineOption? initial}) async {
    final formKey = GlobalKey<FormState>();

    final primaryNameController =
        TextEditingController(text: initial?.primaryName ?? '');
    final sourceController =
        TextEditingController(text: initial?.source ?? 'CUSTOM');
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

    final result = await showDialog<CellLineOption>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setLocalState) {
            return AlertDialog(
              title:
                  Text(initial == null ? 'Custom cell line 추가' : 'Custom cell line 수정'),
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
                            setLocalState(() {
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
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('취소'),
                ),
                FilledButton(
                  onPressed: () {
                    if (!(formKey.currentState?.validate() ?? false)) return;

                    final normalizedName = primaryNameController.text.trim();
                    final existingByName = _findByName(normalizedName);

                    final isDuplicatedCreate =
                        initial == null && existingByName != null;

                    final isDuplicatedRename = initial != null &&
                        existingByName != null &&
                        _identity(existingByName) != _identity(initial);

                    if (isDuplicatedCreate || isDuplicatedRename) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('같은 이름의 Custom cell line이 이미 있습니다.'),
                        ),
                      );
                      return;
                    }

                    final item = _buildItem(
                      primaryName: primaryNameController.text,
                      source: sourceController.text,
                      catalogNumber: catalogNumberController.text,
                      synonyms: synonymsController.text
                          .split(',')
                          .map((e) => e.trim())
                          .where((e) => e.isNotEmpty)
                          .toList(),
                      species: speciesController.text,
                      tissue: tissueController.text,
                      disease: diseaseController.text,
                      cvclId: cvclIdController.text,
                      rrid: rridController.text,
                      isMisidentified: isMisidentified,
                      misidentifiedNote: misidentifiedNoteController.text,
                    );

                    Navigator.pop(dialogContext, item);
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

  Future<bool> _confirmDelete(CellLineOption item) async {
    final confirmed = await showDialog<bool>(
      context: context,
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

  Future<bool> _confirmClearAll() async {
    final confirmed = await showDialog<bool>(
      context: context,
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

  List<CellLineOption> get visibleItems {
    final q = keyword.trim().toLowerCase();

    final filtered = items.where((cell) {
      final matchesSpecies =
          _speciesMatches(cell.species, widget.selectedSpeciesFilter);

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

    return filtered;
  }

  void _saveAndClose() {
    Navigator.of(context).pop(
      CustomCellManagerResult(
        items: items,
        selectedItem: selectedItem,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Custom Cell Lines'),
        actions: [
          TextButton(
            onPressed: _saveAndClose,
            child: const Text('완료'),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final created = await _showEditor();
          if (!mounted || created == null) return;

          setState(() {
            final exists = items.any((e) => _identity(e) == _identity(created));
            if (!exists) {
              items = [...items, created];
            }
            selectedItem = created;
          });
        },
        icon: const Icon(Icons.add),
        label: const Text('새 Custom'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: searchController,
                      decoration: const InputDecoration(
                        labelText: '검색',
                        hintText: 'name, species, tissue, catalog number...',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.search),
                      ),
                      onChanged: (value) {
                        setState(() {
                          keyword = value;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (items.isNotEmpty)
                    OutlinedButton(
                      onPressed: () async {
                        final confirmed = await _confirmClearAll();
                        if (!mounted || !confirmed) return;

                        setState(() {
                          items = [];
                          selectedItem = null;
                        });
                      },
                      child: const Text('전체 삭제'),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: visibleItems.isEmpty
                    ? const Center(
                        child: Text('등록된 custom cell line이 없습니다.'),
                      )
                    : ListView.separated(
                        itemCount: visibleItems.length,
                        separatorBuilder: (_, __) =>
                            const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final cell = visibleItems[index];
                          final isSelected = selectedItem != null &&
                              _identity(selectedItem!) == _identity(cell);

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
                            leading: isSelected
                                ? const Icon(Icons.check_circle)
                                : const Icon(Icons.biotech_outlined),
                            title: Text(cell.primaryName),
                            subtitle: Text(subLines.join('\n')),
                            onTap: () {
                              setState(() {
                                selectedItem = cell;
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
                                          await _showEditor(initial: cell);
                                      if (!mounted || edited == null) return;

                                      setState(() {
                                        items = items.map((e) {
                                          return _identity(e) == _identity(cell)
                                              ? edited
                                              : e;
                                        }).toList();

                                        if (selectedItem != null &&
                                            _identity(selectedItem!) ==
                                                _identity(cell)) {
                                          selectedItem = edited;
                                        }
                                      });
                                    },
                                    icon: const Icon(Icons.edit_outlined),
                                  ),
                                  IconButton(
                                    tooltip: '삭제',
                                    onPressed: () async {
                                      final confirmed =
                                          await _confirmDelete(cell);
                                      if (!mounted || !confirmed) return;

                                      setState(() {
                                        items = items
                                            .where((e) =>
                                                _identity(e) != _identity(cell))
                                            .toList();

                                        if (selectedItem != null &&
                                            _identity(selectedItem!) ==
                                                _identity(cell)) {
                                          selectedItem = null;
                                        }
                                      });
                                    },
                                    icon: const Icon(Icons.delete_outline),
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
      ),
    );
  }
}