import 'package:flutter/material.dart';

import '../models/cell_line_option.dart';

class CellCultureSelectedCellLineCard extends StatelessWidget {
  final CellLineOption? selectedCellLine;
  final String selectedSourceFilter;
  final String selectedSpeciesFilter;
  final VoidCallback onOpenSource;

  const CellCultureSelectedCellLineCard({
    super.key,
    required this.selectedCellLine,
    required this.selectedSourceFilter,
    required this.selectedSpeciesFilter,
    required this.onOpenSource,
  });

  Widget _row(String label, String value) {
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

  @override
  Widget build(BuildContext context) {
    if (selectedCellLine == null) return const SizedBox.shrink();

    return Card(
      color: Colors.grey.shade50,
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _row('Selected', selectedCellLine!.name),
            _row('Source', selectedCellLine!.source),
            _row('Catalog No.', selectedCellLine!.catalogNumber),
            _row('Species', selectedCellLine!.species ?? '-'),
            _row('Tissue', selectedCellLine!.tissue ?? '-'),
            _row('Disease', selectedCellLine!.disease ?? '-'),
            _row('Source filter', selectedSourceFilter),
            _row('Species filter', selectedSpeciesFilter),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: onOpenSource,
                icon: const Icon(Icons.open_in_new),
                label: const Text('원문 보기'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}