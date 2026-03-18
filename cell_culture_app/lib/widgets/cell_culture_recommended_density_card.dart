import 'package:flutter/material.dart';

import '../models/cell_line_option.dart';

class CellCultureRecommendedDensityCard extends StatelessWidget {
  final double? recommendedDensity;
  final CellLineOption? selectedCellLine;
  final String selectedAssay;
  final VoidCallback onApply;

  const CellCultureRecommendedDensityCard({
    super.key,
    required this.recommendedDensity,
    required this.selectedCellLine,
    required this.selectedAssay,
    required this.onApply,
  });

  @override
  Widget build(BuildContext context) {
    if (recommendedDensity == null) {
      return const SizedBox.shrink();
    }

    return Card(
      color: Colors.orange.shade50,
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.lightbulb_outline),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Recommended seeding density',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Text('${recommendedDensity!.toStringAsFixed(0)} cells/cm²'),
                  const SizedBox(height: 6),
                  Text(
                    selectedCellLine != null
                        ? '${selectedCellLine!.name} / $selectedAssay 기준 추천값'
                        : '$selectedAssay 기본 추천값',
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: onApply,
              child: const Text('적용'),
            ),
          ],
        ),
      ),
    );
  }
}