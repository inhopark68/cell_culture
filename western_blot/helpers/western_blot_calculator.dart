import '../models/gel_mix_recipe.dart';
import '../models/western_sample_row.dart';
import '../models/western_standard_row.dart';

class WesternBlotCalculator {
  static int replicateCountFromLabel(String value) {
    switch (value) {
      case 'Single':
        return 1;
      case 'Duplicate':
        return 2;
      case 'Triplicate':
      default:
        return 3;
    }
  }

  static String wellLabel(int count) {
    if (count == 1) return '(1 well)';
    return '($count wells)';
  }

  static List<double> resizeAbsorbances(List<double> values, int newCount) {
    final resized = List<double>.from(values);
    if (resized.length < newCount) {
      resized.addAll(List.filled(newCount - resized.length, 0));
    } else if (resized.length > newCount) {
      return resized.sublist(0, newCount);
    }
    return resized;
  }

  static double blankAbsorbance(List<WesternStandardRow> standards) {
    final blankRow = standards.firstWhere(
      (e) => e.concentrationUgPerMl == 0,
      orElse: () => const WesternStandardRow(
        concentrationUgPerMl: 0,
        absorbances: [0, 0, 0],
      ),
    );
    return blankRow.averageAbsorbance;
  }

  static double standardSlope({
    required List<WesternStandardRow> standards,
    required bool useBlankCorrection,
  }) {
    final blank = blankAbsorbance(standards);

    final points = standards
        .map(
          (e) => (
            x: e.concentrationUgPerMl,
            y: useBlankCorrection
                ? e.averageAbsorbance - blank
                : e.averageAbsorbance,
          ),
        )
        .toList();

    if (points.length < 2) return 0;

    final n = points.length;
    final sumX = points.fold<double>(0, (sum, p) => sum + p.x);
    final sumY = points.fold<double>(0, (sum, p) => sum + p.y);
    final sumXY = points.fold<double>(0, (sum, p) => sum + (p.x * p.y));
    final sumX2 = points.fold<double>(0, (sum, p) => sum + (p.x * p.x));

    final denominator = (n * sumX2) - (sumX * sumX);
    if (denominator == 0) return 0;

    return ((n * sumXY) - (sumX * sumY)) / denominator;
  }

  static double standardIntercept({
    required List<WesternStandardRow> standards,
    required bool useBlankCorrection,
  }) {
    final blank = blankAbsorbance(standards);

    final points = standards
        .map(
          (e) => (
            x: e.concentrationUgPerMl,
            y: useBlankCorrection
                ? e.averageAbsorbance - blank
                : e.averageAbsorbance,
          ),
        )
        .toList();

    if (points.isEmpty) return 0;

    final n = points.length;
    final sumX = points.fold<double>(0, (sum, p) => sum + p.x);
    final sumY = points.fold<double>(0, (sum, p) => sum + p.y);

    final slope = standardSlope(
      standards: standards,
      useBlankCorrection: useBlankCorrection,
    );
    return (sumY - (slope * sumX)) / n;
  }

  static double correctedAbsorbance({
    required WesternSampleRow row,
    required bool useBlankCorrection,
    required double blankAbsorbance,
  }) {
    final raw = row.rawAbsorbance;
    if (!useBlankCorrection) return raw;
    return raw - blankAbsorbance;
  }

  static double calculatedProteinConcentrationUgPerUl({
    required WesternSampleRow row,
    required bool useBlankCorrection,
    required double blankAbsorbance,
    required double standardSlope,
    required double standardIntercept,
  }) {
    final corrected = correctedAbsorbance(
      row: row,
      useBlankCorrection: useBlankCorrection,
      blankAbsorbance: blankAbsorbance,
    );

    if (standardSlope == 0) return 0;

    final concentrationUgPerMl =
        (corrected - standardIntercept) / standardSlope;

    if (concentrationUgPerMl <= 0) return 0;

    final adjustedUgPerMl = concentrationUgPerMl * row.dilutionFactor;
    return adjustedUgPerMl / 1000.0;
  }

  static double calculateLoadingVolume({
    required double concentrationUgPerUl,
    required double loadingProteinAmountUg,
  }) {
    if (concentrationUgPerUl <= 0) return 0;
    return loadingProteinAmountUg / concentrationUgPerUl;
  }

  static GelMixRecipe calculateResolvingRecipe({
    required double totalMl,
    required double resolvingPercent,
    required double acrylamideStockPercent,
    required double trisResolvingStockM,
    required double sdsStockPercent,
    required double apsStockPercent,
  }) {
    const trisFinalM = 0.375;
    const sdsFinalPercent = 0.1;
    const apsFinalPercent = 0.05;
    const temedFraction = 0.0005;

    final acrylamideMl = totalMl * (resolvingPercent / acrylamideStockPercent);
    final trisMl = totalMl * (trisFinalM / trisResolvingStockM);
    final sdsMl = totalMl * (sdsFinalPercent / sdsStockPercent);
    final apsMl = totalMl * (apsFinalPercent / apsStockPercent);
    final temedMl = totalMl * temedFraction;
    final waterMl =
        totalMl - acrylamideMl - trisMl - sdsMl - apsMl - temedMl;

    return GelMixRecipe(
      totalMl: totalMl,
      acrylamideMl: acrylamideMl,
      trisMl: trisMl,
      sdsMl: sdsMl,
      apsMl: apsMl,
      temedMl: temedMl,
      waterMl: waterMl,
    );
  }

  static GelMixRecipe calculateStackingRecipe({
    required double totalMl,
    required double stackingPercent,
    required double acrylamideStockPercent,
    required double trisStackingStockM,
    required double sdsStockPercent,
    required double apsStockPercent,
  }) {
    const trisFinalM = 0.125;
    const sdsFinalPercent = 0.1;
    const apsFinalPercent = 0.05;
    const temedFraction = 0.0005;

    final acrylamideMl = totalMl * (stackingPercent / acrylamideStockPercent);
    final trisMl = totalMl * (trisFinalM / trisStackingStockM);
    final sdsMl = totalMl * (sdsFinalPercent / sdsStockPercent);
    final apsMl = totalMl * (apsFinalPercent / apsStockPercent);
    final temedMl = totalMl * temedFraction;
    final waterMl =
        totalMl - acrylamideMl - trisMl - sdsMl - apsMl - temedMl;

    return GelMixRecipe(
      totalMl: totalMl,
      acrylamideMl: acrylamideMl,
      trisMl: trisMl,
      sdsMl: sdsMl,
      apsMl: apsMl,
      temedMl: temedMl,
      waterMl: waterMl,
    );
  }

  static String formatMlOrUl(double valueMl) {
    if (valueMl >= 1) {
      return '${valueMl.toStringAsFixed(2)} mL';
    }
    return '${(valueMl * 1000).toStringAsFixed(1)} µL';
  }
}