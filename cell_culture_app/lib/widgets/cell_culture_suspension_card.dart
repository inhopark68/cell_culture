import 'package:flutter/material.dart';

import '../models/cell_culture_form_data.dart';
import '../models/cell_culture_summary.dart';
import '../models/seeding_input_mode.dart';

class CellCultureSuspensionCard extends StatelessWidget {
  final CellCultureFormData form;
  final CellCultureSummary summary;

  final SeedingInputMode selectedSeedingInputMode;
  final String selectedWellBasisWare;
  final double? basisCellsPerWell;
  final double? actualCellsPerCultureUnit;

  const CellCultureSuspensionCard({
    super.key,
    required this.form,
    required this.summary,
    required this.selectedSeedingInputMode,
    required this.selectedWellBasisWare,
    required this.basisCellsPerWell,
    required this.actualCellsPerCultureUnit,
  });

  String _f0(num? value) {
    if (value == null) return '-';
    return value.toStringAsFixed(0);
  }

  String _f2(num? value) {
    if (value == null) return '-';
    return value.toStringAsFixed(2);
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 5,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 6,
            child: Text(value),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final inputModeLabel =
        selectedSeedingInputMode == SeedingInputMode.cellsPerCm2
            ? 'cells/cm²'
            : 'cells/well';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _row('Input mode', inputModeLabel),
            _row(
              'Input basis',
              '${_f0(basisCellsPerWell)} cells/well ($selectedWellBasisWare)',
            ),
            _row(
              'Actual per culture well',
              '${_f0(actualCellsPerCultureUnit)} cells/well (${form.selectedWare})',
            ),

            const Divider(height: 24),

            _row(
              'Seeding volume per unit',
              '${_f2(form.seedingVolumePerUnit)} mL',
            ),
            _row(
              'Total seeding volume',
              '${_f2(summary.totalSeedingVolume)} mL',
            ),
            _row(
              'Total seeding volume (+extra)',
              '${_f2(summary.totalSeedingVolumeWithExtra)} mL',
            ),

            const Divider(height: 24),

            _row(
              'Stock concentration',
              '${_f0(form.stockConcentration)} cells/mL',
            ),
            _row(
              'Required cell suspension',
              '${_f2(summary.requiredCellSuspensionVolume)} mL',
            ),
            _row(
              'Required cell suspension (+extra)',
              '${_f2(summary.requiredCellSuspensionVolumeWithExtra)} mL',
            ),
            _row(
              'Required media volume',
              '${_f2(summary.requiredMediaVolume)} mL',
            ),
            _row(
              'Required media volume (+extra)',
              '${_f2(summary.requiredMediaVolumeWithExtra)} mL',
            ),
          ],
        ),
      ),
    );
  }
}