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
          Expanded(
            flex: 4,
            child: Text(label),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 6,
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

  String _displayOrDash(String? value) {
    if (value == null || value.trim().isEmpty) return '-';
    return value;
  }

  String _displayListOrDash(List<String> values) {
    if (values.isEmpty) return '-';
    return values.join(', ');
  }

  @override
  Widget build(BuildContext context) {
    final cellLine = selectedCellLine;
    if (cellLine == null) return const SizedBox.shrink();

    return Card(
      color: Colors.grey.shade50,
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _row('Selected', cellLine.primaryName),
            _row('Display label', cellLine.displayLabel),
            _row('Source', cellLine.source),
            _row('Catalog No.', cellLine.catalogNumber),
            _row('Synonyms', _displayListOrDash(cellLine.synonyms)),
            _row('CVCL ID', _displayOrDash(cellLine.cvclId)),
            _row('RRID', _displayOrDash(cellLine.rrid)),
            _row('Species', _displayOrDash(cellLine.species)),
            _row('Tissue', _displayOrDash(cellLine.tissue)),
            _row('Disease', _displayOrDash(cellLine.disease)),
            _row(
              'Misidentified',
              cellLine.isMisidentified ? 'Yes' : 'No',
            ),
            if (cellLine.isMisidentified)
              _row(
                'Misidentified note',
                _displayOrDash(cellLine.misidentifiedNote),
              ),
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