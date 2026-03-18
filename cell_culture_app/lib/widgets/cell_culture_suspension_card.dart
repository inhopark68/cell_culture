import 'package:flutter/material.dart';

import '../models/cell_culture_form_data.dart';
import '../models/cell_culture_summary.dart';

class CellCultureSuspensionCard extends StatelessWidget {
  final CellCultureFormData form;
  final CellCultureSummary summary;

  const CellCultureSuspensionCard({
    super.key,
    required this.form,
    required this.summary,
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
            _row('Seeding volume / unit', '${form.seedingVolumePerUnit.toStringAsFixed(2)} mL'),
            _row('Stock concentration', '${form.stockConcentration.toStringAsFixed(0)} cells/mL'),
            _row('Extra', '${(form.extraPercent * 100).toStringAsFixed(0)} %'),
            _row('Total seeding volume', '${summary.totalSeedingVolume.toStringAsFixed(2)} mL'),
            _row('Total seeding volume (+extra)', '${summary.totalSeedingVolumeWithExtra.toStringAsFixed(2)} mL'),
            _row('Required cell suspension', '${summary.requiredCellSuspensionVolume.toStringAsFixed(2)} mL'),
            _row('Required cell suspension (+extra)', '${summary.requiredCellSuspensionVolumeWithExtra.toStringAsFixed(2)} mL'),
            _row('Required media volume', '${summary.requiredMediaVolume.toStringAsFixed(2)} mL'),
            _row('Required media volume (+extra)', '${summary.requiredMediaVolumeWithExtra.toStringAsFixed(2)} mL'),
          ],
        ),
      ),
    );
  }
}