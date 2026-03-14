import 'package:flutter/material.dart';
import 'pages/pcr_template.dart';
import 'pages/cell_culture_template.dart';
import 'pages/elisa_template.dart';
import 'pages/mrna_cdna_template.dart';
import 'pages/western_blot_template.dart';

void main() {
  runApp(const LabTemplateApp());
}

class LabTemplateApp extends StatelessWidget {
  const LabTemplateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Lab Template App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const TemplateHomePage(),
    );
  }
}

class TemplateHomePage extends StatelessWidget {
  const TemplateHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Experiment Templates'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _menuButton(
              context: context,
              title: 'Cell Culture Template',
              icon: Icons.biotech,
              page: const CellCultureTemplatePage(),
            ),
            const SizedBox(height: 12),
            _menuButton(
              context: context,
              title: 'Western Blot Template',
              icon: Icons.blur_on,
              page: const WesternBlotTemplatePage(),
            ),
            const SizedBox(height: 12),
            _menuButton(
              context: context,
              title: 'mRNA → cDNA Template',
              icon: Icons.medical_information,
              page: const MrnaCdnaTemplatePage(),
            ),
            const SizedBox(height: 12),
            _menuButton(
              context: context,
              title: 'PCR Template',
              icon: Icons.science,
              page: const PcrTemplatePage(),
            ),
            const SizedBox(height: 12),
            _menuButton(
              context: context,
              title: 'ELISA Template',
              icon: Icons.analytics,
              page: const ElisaTemplatePage(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _menuButton({
    required BuildContext context,
    required String title,
    required IconData icon,
    required Widget page,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 64,
      child: ElevatedButton.icon(
        icon: Icon(icon),
        label: Text(
          title,
          style: const TextStyle(fontSize: 16),
        ),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => page),
          );
        },
      ),
    );
  }
}