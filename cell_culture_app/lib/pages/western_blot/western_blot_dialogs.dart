import 'package:flutter/material.dart';

import 'western_blot_models.dart';

Future<bool> showReplicateReductionDialog({
  required BuildContext context,
  required String title,
  required String message,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('변경'),
          ),
        ],
      );
    },
  );

  return result ?? false;
}

Future<WesternSampleRow?> showEditSampleDialog({
  required BuildContext context,
  required WesternSampleRow row,
  required int index,
  required int sampleReplicateCount,
  required String sampleWellLabel,
}) async {
  final nameController = TextEditingController(text: row.sampleName);
  final dilutionController = TextEditingController(
    text: row.dilutionFactor.toString(),
  );

  final absorbanceControllers = List.generate(
    sampleReplicateCount,
    (i) => TextEditingController(
      text: i < row.absorbances.length && row.absorbances[i] != 0
          ? row.absorbances[i].toString()
          : '',
    ),
  );

  final result = await showDialog<WesternSampleRow>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text('Edit ${row.sampleName} $sampleWellLabel'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Sample name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              ...List.generate(sampleReplicateCount, (i) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: TextField(
                    controller: absorbanceControllers[i],
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Raw absorbance ${i + 1} (A562)',
                      border: const OutlineInputBorder(),
                    ),
                  ),
                );
              }),
              TextField(
                controller: dilutionController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Dilution factor',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(
                context,
                WesternSampleRow(
                  sampleName: nameController.text.trim().isEmpty
                      ? 'Sample ${index + 1}'
                      : nameController.text.trim(),
                  absorbances: absorbanceControllers
                      .map((c) => double.tryParse(c.text) ?? 0)
                      .toList(),
                  dilutionFactor: double.tryParse(dilutionController.text) ?? 1,
                ),
              );
            },
            child: const Text('저장'),
          ),
        ],
      );
    },
  );

  nameController.dispose();
  dilutionController.dispose();
  for (final c in absorbanceControllers) {
    c.dispose();
  }

  return result;
}

Future<WesternStandardRow?> showEditStandardDialog({
  required BuildContext context,
  required WesternStandardRow row,
  required int index,
  required int standardReplicateCount,
  required String standardWellLabel,
}) async {
  final concentrationController = TextEditingController(
    text: row.concentrationUgPerMl.toString(),
  );

  final absorbanceControllers = List.generate(
    standardReplicateCount,
    (i) => TextEditingController(
      text: i < row.absorbances.length && row.absorbances[i] != 0
          ? row.absorbances[i].toString()
          : '',
    ),
  );

  final result = await showDialog<WesternStandardRow>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text('Edit Standard ${index + 1} $standardWellLabel'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: concentrationController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Concentration (µg/mL)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              ...List.generate(standardReplicateCount, (i) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: TextField(
                    controller: absorbanceControllers[i],
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Absorbance ${i + 1}',
                      border: const OutlineInputBorder(),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(
                context,
                WesternStandardRow(
                  concentrationUgPerMl:
                      double.tryParse(concentrationController.text) ?? 0,
                  absorbances: absorbanceControllers
                      .map((c) => double.tryParse(c.text) ?? 0)
                      .toList(),
                ),
              );
            },
            child: const Text('저장'),
          ),
        ],
      );
    },
  );

  concentrationController.dispose();
  for (final c in absorbanceControllers) {
    c.dispose();
  }

  return result;
}