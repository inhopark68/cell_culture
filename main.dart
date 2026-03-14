import 'package:flutter/material.dart';
import 'cell_culture_template_page.dart';

void main() {
  runApp(const CellCultureApp());
}

class CellCultureApp extends StatelessWidget {
  const CellCultureApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const CellCultureTemplatePage(),
    );
  }
}