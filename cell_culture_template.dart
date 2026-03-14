import 'package:flutter/material.dart';

class CellCultureTemplatePage extends StatefulWidget {
  const CellCultureTemplatePage({super.key});

  @override
  State<CellCultureTemplatePage> createState() =>
      _CellCultureTemplatePageState();
}

class _CellCultureTemplatePageState extends State<CellCultureTemplatePage> {
  final TextEditingController cellLineController =
      TextEditingController(text: 'HeLa');
  final TextEditingController seedingDensityController =
      TextEditingController(text: '50000');
  final TextEditingController wellCountController =
      TextEditingController(text: '6');
  final TextEditingController replicateController =
      TextEditingController(text: '3');
  final TextEditingController targetConfluencyController =
      TextEditingController(text: '70');

  String selectedAssay = 'qPCR';
  String selectedWare = '24-well plate';

  final Map<String, double> cultureWareAreaMap = {
    '6-well plate': 9.6,
    '12-well plate': 3.8,
    '24-well plate': 1.9,
    '48-well plate': 1.0,
    '96-well plate': 0.32,
    'T25 flask': 25.0,
    'T75 flask': 75.0,
  };

  final Map<String, String> cultureWareVolumeMap = {
    '6-well plate': '2–3 mL/well',
    '12-well plate': '1–1.5 mL/well',
    '24-well plate': '0.5–1 mL/well',
    '48-well plate': '0.2–0.5 mL/well',
    '96-well plate': '0.1–0.2 mL/well',
    'T25 flask': '5–7 mL',
    'T75 flask': '12–15 mL',
  };

  final Map<String, double> defaultDensityByAssay = {
    'Viability assay': 20000,
    'qPCR': 50000,
    'ELISA': 40000,
    'Western blot': 80000,
    'Imaging / IF': 30000,
  };

  double get selectedArea => cultureWareAreaMap[selectedWare] ?? 0.0;
  String get selectedVolume => cultureWareVolumeMap[selectedWare] ?? '-';

  double get seedingDensity =>
      double.tryParse(seedingDensityController.text) ?? 0.0;

  int get wellCount => int.tryParse(wellCountController.text) ?? 0;
  int get replicateCount => int.tryParse(replicateController.text) ?? 1;
  int get targetConfluency =>
      int.tryParse(targetConfluencyController.text) ?? 70;

  int get cellsPerWell => (selectedArea * seedingDensity).round();

  int get totalCultureUnits => wellCount * replicateCount;

  int get totalCellsNeeded => cellsPerWell * totalCultureUnits;

  String get recommendationText {
    if (selectedWare.contains('96')) {
      return 'High-throughput assay에 적합합니다.';
    } else if (selectedWare.contains('24')) {
      return 'qPCR, ELISA, imaging assay에 많이 사용됩니다.';
    } else if (selectedWare.contains('6')) {
      return 'Protein/RNA harvest가 필요한 assay에 적합합니다.';
    } else if (selectedWare.contains('T25') || selectedWare.contains('T75')) {
      return 'Expansion 또는 대량 세포 확보에 적합합니다.';
    }
    return '선택한 culture ware 조건을 확인하세요.';
  }

  void applyDefaultDensityByAssay(String assay) {
    final density = defaultDensityByAssay[assay];
    if (density != null) {
      seedingDensityController.text = density.toStringAsFixed(0);
    }
  }

  Widget buildSectionTitle(String title) {
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

  Widget buildTextField({
    required String label,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      onChanged: (_) => setState(() {}),
    );
  }

  Widget infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(label),
          ),
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

  Widget buildResultCard() {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            infoRow('Cell line', cellLineController.text.trim().isEmpty
                ? '-'
                : cellLineController.text.trim()),
            infoRow('Assay type', selectedAssay),
            infoRow('Culture ware', selectedWare),
            infoRow('Surface area', '${selectedArea.toStringAsFixed(2)} cm²'),
            infoRow('Working volume', selectedVolume),
            infoRow(
              'Seeding density',
              '${seedingDensity.toStringAsFixed(0)} cells/cm²',
            ),
            infoRow('Target confluency', '$targetConfluency %'),
            infoRow('Cells / unit', '$cellsPerWell cells'),
            infoRow('Number of units', '$wellCount'),
            infoRow('Replicates', '$replicateCount'),
            infoRow('Total culture units', '$totalCultureUnits'),
            infoRow('Total cells needed', '$totalCellsNeeded cells'),
          ],
        ),
      ),
    );
  }

  Widget buildRecommendationCard() {
    return Card(
      color: Colors.blue.shade50,
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.science_outlined),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                recommendationText,
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildSimpleFormulaCard() {
    return Card(
      elevation: 0,
      color: Colors.grey.shade100,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            infoRow(
              'Formula 1',
              'Cells / well = Surface area × Seeding density',
            ),
            infoRow(
              'Formula 2',
              'Total cells = Cells / well × Number of units × Replicates',
            ),
          ],
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    applyDefaultDensityByAssay(selectedAssay);
  }

  @override
  void dispose() {
    cellLineController.dispose();
    seedingDensityController.dispose();
    wellCountController.dispose();
    replicateController.dispose();
    targetConfluencyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cell Culture Template'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            buildSectionTitle('Basic Information'),
            const SizedBox(height: 8),
            buildTextField(
              label: 'Cell line',
              controller: cellLineController,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: selectedAssay,
              decoration: const InputDecoration(
                labelText: 'Assay type',
                border: OutlineInputBorder(),
              ),
              items: defaultDensityByAssay.keys.map((assay) {
                return DropdownMenuItem<String>(
                  value: assay,
                  child: Text(assay),
                );
              }).toList(),
              onChanged: (value) {
                if (value == null) return;
                setState(() {
                  selectedAssay = value;
                  applyDefaultDensityByAssay(value);
                });
              },
            ),
            const SizedBox(height: 20),

            buildSectionTitle('Culture Ware'),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: selectedWare,
              decoration: const InputDecoration(
                labelText: 'Culture ware',
                border: OutlineInputBorder(),
              ),
              items: cultureWareAreaMap.keys.map((ware) {
                return DropdownMenuItem<String>(
                  value: ware,
                  child: Text(ware),
                );
              }).toList(),
              onChanged: (value) {
                if (value == null) return;
                setState(() {
                  selectedWare = value;
                });
              },
            ),
            const SizedBox(height: 20),

            buildSectionTitle('Seeding Conditions'),
            const SizedBox(height: 8),
            buildTextField(
              label: 'Seeding density (cells/cm²)',
              controller: seedingDensityController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 12),
            buildTextField(
              label: 'Number of wells / flasks used',
              controller: wellCountController,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            buildTextField(
              label: 'Replicates',
              controller: replicateController,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            buildTextField(
              label: 'Target confluency (%)',
              controller: targetConfluencyController,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 20),

            buildSectionTitle('Calculated Result'),
            const SizedBox(height: 8),
            buildResultCard(),
            const SizedBox(height: 12),
            buildRecommendationCard(),
            const SizedBox(height: 12),
            buildSimpleFormulaCard(),
          ],
        ),
      ),
    );
  }
}