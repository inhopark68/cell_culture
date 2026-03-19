import 'package:flutter/material.dart';

import '../models/cell_line_option.dart';

class CellCultureCellLineAutocomplete extends StatelessWidget {
  final bool isLoading;
  final String selectedLabel;
  final TextEditingController controller;
  final Iterable<CellLineOption> Function(String query) optionsBuilder;
  final ValueChanged<CellLineOption> onSelected;
  final ValueChanged<String> onChanged;

  const CellCultureCellLineAutocomplete({
    super.key,
    required this.isLoading,
    required this.selectedLabel,
    required this.controller,
    required this.optionsBuilder,
    required this.onSelected,
    required this.onChanged,
  });

  String _buildSubtitle(CellLineOption option) {
    final parts = <String>[
      '${option.source} ${option.catalogNumber}',
      if (option.species != null && option.species!.trim().isNotEmpty)
        option.species!,
      if (option.tissue != null && option.tissue!.trim().isNotEmpty)
        option.tissue!,
      if (option.disease != null && option.disease!.trim().isNotEmpty)
        option.disease!,
    ];

    return parts.join(' • ');
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
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
      initialValue: TextEditingValue(text: selectedLabel),
      displayStringForOption: (option) => option.displayLabel,
      optionsBuilder: (textEditingValue) {
        return optionsBuilder(textEditingValue.text);
      },
      onSelected: onSelected,
      fieldViewBuilder: (
        BuildContext context,
        TextEditingController textEditingController,
        FocusNode focusNode,
        VoidCallback onFieldSubmitted,
      ) {
        if (controller.text != textEditingController.text) {
          textEditingController.value = controller.value;
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
          onChanged: (value) {
            controller.value = textEditingController.value;
            onChanged(value);
          },
        );
      },
      optionsViewBuilder: (
        BuildContext context,
        AutocompleteOnSelected<CellLineOption> onSelect,
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
                  subtitle: const Text(
                    '다른 이름 또는 catalog 번호로 검색해보세요.\n'
                    '필요하면 Source/Species filter를 All로 바꿔보세요.',
                  ),
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
                maxHeight: 500,
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
                    title: Text(option.primaryName),
                    subtitle: Text(_buildSubtitle(option)),
                    trailing: option.source.toUpperCase() == 'ATCC'
                        ? const Icon(Icons.public, size: 18)
                        : const Icon(Icons.biotech, size: 18),
                    onTap: () => onSelect(option),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}