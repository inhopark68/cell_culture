import 'package:flutter/material.dart';

import '../models/cell_culture_form_data.dart';
import '../models/cell_culture_summary.dart';
import '../models/cell_line_option.dart';

class CellCultureResultCard extends StatelessWidget {
  final CellCultureFormData form;
  final CellCultureSummary summary;
  final CellLineOption? selectedCellLine;

  const CellCultureResultCard({
    super.key,
    required this.form,
    required this.summary,
    required this.selectedCellLine,
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _row('Cell line', selectedCellLine?.displayLabel ?? 'Not selected'),
            _row('Assay type', form.selectedAssay),
            _row('Culture ware', form.selectedWare),
            _row('Surface area', '${summary.surfaceArea.toStringAsFixed(2)} cm²'),
            _row('Working volume', summary.workingVolume),
            _row('Seeding density', '${form.seedingDensity.toStringAsFixed(0)} cells/cm²'),
            _row('Target confluency', '${form.targetConfluency} %'),
            _row('Cells / unit', '${summary.cellsPerUnit} cells'),
            _row('Sample count', '${form.sampleCount}'),
            _row('Replicates', '${form.replicateCount}'),
            _row('Blank', '${form.blankCount}'),
            _row('Negative control', '${form.negativeControlCount}'),
            _row('Vehicle', '${form.vehicleCount}'),
            _row('Positive control', '${form.positiveControlCount}'),
            _row('Total controls', '${summary.totalControlUnits}'),
            _row('Total sample units', '${summary.totalSampleUnits}'),
            _row('Total culture units', '${summary.totalCultureUnits}'),
            _row('Total cells needed', '${summary.totalCellsNeeded} cells'),
            _row('Total cells needed (+extra)', '${summary.totalCellsNeededWithExtra} cells'),
          ],
        ),
      ),
    );
  }
}