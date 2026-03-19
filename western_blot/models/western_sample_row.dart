class WesternSampleRow {
  final String sampleName;
  final List<double> absorbances;
  final double dilutionFactor;

  const WesternSampleRow({
    required this.sampleName,
    required this.absorbances,
    required this.dilutionFactor,
  });

  WesternSampleRow copyWith({
    String? sampleName,
    List<double>? absorbances,
    double? dilutionFactor,
  }) {
    return WesternSampleRow(
      sampleName: sampleName ?? this.sampleName,
      absorbances: absorbances ?? this.absorbances,
      dilutionFactor: dilutionFactor ?? this.dilutionFactor,
    );
  }

  double get averageAbsorbance {
    if (absorbances.isEmpty) return 0;
    return absorbances.reduce((a, b) => a + b) / absorbances.length;
  }

  double get rawAbsorbance => averageAbsorbance;

  Map<String, dynamic> toMap() {
    return {
      'sampleName': sampleName,
      'absorbances': absorbances,
      'averageAbsorbance': averageAbsorbance,
      'dilutionFactor': dilutionFactor,
    };
  }
}