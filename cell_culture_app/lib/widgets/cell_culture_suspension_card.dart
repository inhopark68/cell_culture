import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/cell_culture_form_data.dart';
import '../models/cell_culture_summary.dart';
import '../models/cell_line_option.dart';
import '../models/seeding_input_mode.dart';

class CellCultureSuspensionCard extends StatelessWidget {
  final CellCultureFormData form;
  final CellCultureSummary summary;
  final CellLineOption? selectedCellLine;

  final SeedingInputMode selectedSeedingInputMode;
  final String selectedWellBasisWare;
  final double? basisCellsPerWell;
  final double? actualCellsPerCultureUnit;

  const CellCultureSuspensionCard({
    super.key,
    required this.form,
    required this.summary,
    required this.selectedCellLine,
    required this.selectedSeedingInputMode,
    required this.selectedWellBasisWare,
    required this.basisCellsPerWell,
    required this.actualCellsPerCultureUnit,
  });

  String _f0(num? value) {
    if (value == null) return '-';
    return NumberFormat('#,###').format(value);
  }

  String _f2(num? value) {
    if (value == null) return '-';
    return NumberFormat('#,##0.00').format(value);
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
    final normalizedDensity = form.seedingDensity;
    final inputModeLabel =
        selectedSeedingInputMode == SeedingInputMode.cellsPerCm2
            ? 'cells/cm²'
            : 'cells/well';

    final supplements = [
      if (form.usePenStrep) 'Pen/Strep',
      if (form.useGlutamax) 'GlutaMAX',
      if (form.useHepes) 'HEPES',
      if (form.useNeaa) 'NEAA',
      if (form.useSodiumPyruvate) 'Sodium pyruvate',
    ].join(', ');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _row('Cell line', selectedCellLine?.displayLabel ?? '-'),
            _row('Assay', form.selectedAssay),
            _row('Culture ware', form.selectedWare),
            _row('Culture medium', form.cultureMedium),
            _row('Serum', '${_f2(form.serumPercent)} %'),
            _row('Supplements', supplements.isEmpty ? '-' : supplements),
            if (form.mediumNote.trim().isNotEmpty)
              _row('Medium note', form.mediumNote),

            const Divider(height: 24),

            _row('Input mode', inputModeLabel),
            _row(
              'Normalized seeding density',
              '${_f2(normalizedDensity)} cells/cm²',
            ),
            _row(
              'Input basis',
              '${_f0(basisCellsPerWell)} cells/well ($selectedWellBasisWare)',
            ),
            _row(
              'Actual per culture well',
              '${_f0(actualCellsPerCultureUnit)} cells/well (${form.selectedWare})',
            ),

            const Divider(height: 24),

            _row('Surface area', '${_f2(summary.surfaceArea)} cm²'),
            _row('Working volume', '${summary.workingVolume} mL'),
            _row('Sample units', _f0(summary.totalSampleUnits)),
            _row('Control units', _f0(summary.totalControlUnits)),
            _row('Total culture units', _f0(summary.totalCultureUnits)),
            _row('Cells per unit', _f0(summary.cellsPerUnit)),
            _row('Total cells needed', _f0(summary.totalCellsNeeded)),
            _row(
              'Total cells needed (+extra)',
              _f0(summary.totalCellsNeededWithExtra),
            ),
            _row(
              'Total seeding volume',
              '${_f2(summary.totalSeedingVolume)} mL',
            ),
            _row(
              'Total seeding volume (+extra)',
              '${_f2(summary.totalSeedingVolumeWithExtra)} mL',
            ),
          ],
        ),
      ),
    );
  }
}