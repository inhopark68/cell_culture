import 'package:flutter/material.dart';
import 'cell_culture_template_page_6.dart';

void main() {
  runApp(const CellCultureApp());
}

class CellCultureApp extends StatelessWidget {
  const CellCultureApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Cell Culture Template',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const CellCultureTemplatePage(),
    );
  }
}