import 'package:flutter/material.dart';

import 'western_blot_models.dart';

class SectionTitle extends StatelessWidget {
  final String title;

  const SectionTitle(this.title, {super.key});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class AppTextField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final TextInputType keyboardType;
  final VoidCallback? onChanged;
  final int maxLines;

  const AppTextField({
    super.key,
    required this.label,
    required this.controller,
    this.keyboardType = TextInputType.text,
    this.onChanged,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      onChanged: (_) => onChanged?.call(),
    );
  }
}

class AppDropdownField extends StatelessWidget {
  final String label;
  final String value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  const AppDropdownField({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      items: items
          .map(
            (e) => DropdownMenuItem(
              value: e,
              child: Text(e),
            ),
          )
          .toList(),
      onChanged: onChanged,
    );
  }
}

class AppSwitchTile extends StatelessWidget {
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  const AppSwitchTile({
    super.key,
    required this.title,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title),
      value: value,
      onChanged: onChanged,
    );
  }
}

class InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const InfoRow({
    super.key,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
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
}

class SummaryCard extends StatelessWidget {
  final List<Widget> children;

  const SummaryCard({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: children),
      ),
    );
  }
}

class GreyCard extends StatelessWidget {
  final List<Widget> children;
  final double elevation;

  const GreyCard({
    super.key,
    required this.children,
    this.elevation = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: elevation,
      color: Colors.grey.shade100,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: children),
      ),
    );
  }
}

class LegendWidget extends StatelessWidget {
  const LegendWidget({super.key});

  @override
  Widget build(BuildContext context) {
    Widget item(Color color, String label) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 16, height: 16, color: color),
          const SizedBox(width: 6),
          Text(label),
        ],
      );
    }

    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: [
        item(Colors.green.shade100, 'Ready'),
        item(Colors.orange.shade100, 'High loading volume'),
        item(Colors.red.shade100, 'Invalid curve result'),
        item(Colors.grey.shade200, 'No BCA result'),
      ],
    );
  }
}

class GelRecipeCard extends StatelessWidget {
  final String title;
  final String trisLabel;
  final GelMixRecipe recipe;
  final String Function(double valueMl) formatMlOrUl;

  const GelRecipeCard({
    super.key,
    required this.title,
    required this.trisLabel,
    required this.recipe,
    required this.formatMlOrUl,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.grey.shade100,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 12),
            InfoRow(label: 'Total volume', value: formatMlOrUl(recipe.totalMl)),
            InfoRow(
              label: '30% Acrylamide/Bis',
              value: formatMlOrUl(recipe.acrylamideMl),
            ),
            InfoRow(label: trisLabel, value: formatMlOrUl(recipe.trisMl)),
            InfoRow(label: '10% SDS', value: formatMlOrUl(recipe.sdsMl)),
            InfoRow(label: '10% APS', value: formatMlOrUl(recipe.apsMl)),
            InfoRow(label: 'TEMED', value: formatMlOrUl(recipe.temedMl)),
            InfoRow(label: 'DW', value: formatMlOrUl(recipe.waterMl)),
          ],
        ),
      ),
    );
  }
}

class SampleCard extends StatelessWidget {
  final WesternSampleRow row;
  final String selectedSampleReplicate;
  final String sampleWellLabel;
  final Color statusColor;
  final String statusText;
  final double corrected;
  final double concentration;
  final double loadingProteinAmountUg;
  final double loadingVolume;
  final VoidCallback onTap;

  const SampleCard({
    super.key,
    required this.row,
    required this.selectedSampleReplicate,
    required this.sampleWellLabel,
    required this.statusColor,
    required this.statusText,
    required this.corrected,
    required this.concentration,
    required this.loadingProteinAmountUg,
    required this.loadingVolume,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: statusColor,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          row.sampleName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$selectedSampleReplicate $sampleWellLabel',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Chip(
                    label: Text(statusText),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ...List.generate(row.absorbances.length, (i) {
                return InfoRow(
                  label: 'Raw absorbance ${i + 1}',
                  value: row.absorbances[i].toStringAsFixed(3),
                );
              }),
              InfoRow(
                label: 'Average raw absorbance',
                value: row.averageAbsorbance.toStringAsFixed(3),
              ),
              InfoRow(
                label: 'Corrected absorbance',
                value: corrected.toStringAsFixed(3),
              ),
              InfoRow(
                label: 'Dilution factor',
                value: row.dilutionFactor.toStringAsFixed(2),
              ),
              InfoRow(
                label: 'Protein concentration',
                value: '${concentration.toStringAsFixed(4)} µg/µL',
              ),
              InfoRow(
                label: 'Target loading amount',
                value: '${loadingProteinAmountUg.toStringAsFixed(2)} µg',
              ),
              InfoRow(
                label: 'Loading volume',
                value: '${loadingVolume.toStringAsFixed(2)} µL',
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'Tap to edit',
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class StandardCard extends StatelessWidget {
  final int index;
  final WesternStandardRow row;
  final String selectedStandardReplicate;
  final String standardWellLabel;
  final double correctedAvg;
  final VoidCallback onTap;

  const StandardCard({
    super.key,
    required this.index,
    required this.row,
    required this.selectedStandardReplicate,
    required this.standardWellLabel,
    required this.correctedAvg,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Standard ${index + 1}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$selectedStandardReplicate $standardWellLabel',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Chip(
                    label: Text(
                      '${row.concentrationUgPerMl.toStringAsFixed(0)} µg/mL',
                    ),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ...List.generate(row.absorbances.length, (i) {
                return InfoRow(
                  label: 'Abs ${i + 1}',
                  value: row.absorbances[i].toStringAsFixed(3),
                );
              }),
              InfoRow(
                label: 'Average',
                value: row.averageAbsorbance.toStringAsFixed(3),
              ),
              InfoRow(
                label: 'Corrected avg',
                value: correctedAvg.toStringAsFixed(3),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'Tap to edit',
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}