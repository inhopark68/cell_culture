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

class WesternStandardRow {
  final double concentrationUgPerMl;
  final List<double> absorbances;

  const WesternStandardRow({
    required this.concentrationUgPerMl,
    required this.absorbances,
  });

  WesternStandardRow copyWith({
    double? concentrationUgPerMl,
    List<double>? absorbances,
  }) {
    return WesternStandardRow(
      concentrationUgPerMl:
          concentrationUgPerMl ?? this.concentrationUgPerMl,
      absorbances: absorbances ?? this.absorbances,
    );
  }

  double get averageAbsorbance {
    if (absorbances.isEmpty) return 0;
    return absorbances.reduce((a, b) => a + b) / absorbances.length;
  }

  Map<String, dynamic> toMap() {
    return {
      'concentrationUgPerMl': concentrationUgPerMl,
      'absorbances': absorbances,
      'averageAbsorbance': averageAbsorbance,
    };
  }
}

class GelMixRecipe {
  final double totalMl;
  final double acrylamideMl;
  final double trisMl;
  final double sdsMl;
  final double apsMl;
  final double temedMl;
  final double waterMl;

  const GelMixRecipe({
    required this.totalMl,
    required this.acrylamideMl,
    required this.trisMl,
    required this.sdsMl,
    required this.apsMl,
    required this.temedMl,
    required this.waterMl,
  });
}