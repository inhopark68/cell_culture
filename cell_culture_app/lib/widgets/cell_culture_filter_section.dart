import 'package:flutter/material.dart';

class CellCultureFilterSection extends StatelessWidget {
  final List<String> sourceFilters;
  final List<String> speciesFilters;
  final String selectedSourceFilter;
  final String selectedSpeciesFilter;
  final ValueChanged<String> onSourceChanged;
  final ValueChanged<String> onSpeciesChanged;

  const CellCultureFilterSection({
    super.key,
    required this.sourceFilters,
    required this.speciesFilters,
    required this.selectedSourceFilter,
    required this.selectedSpeciesFilter,
    required this.onSourceChanged,
    required this.onSpeciesChanged,
  });

  @override
  Widget build(BuildContext context) {
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
            return ChoiceChip(
              label: Text(filter),
              selected: selectedSourceFilter == filter,
              onSelected: (_) => onSourceChanged(filter),
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
            return ChoiceChip(
              label: Text(filter),
              selected: selectedSpeciesFilter == filter,
              onSelected: (_) => onSpeciesChanged(filter),
            );
          }).toList(),
        ),
      ],
    );
  }
}