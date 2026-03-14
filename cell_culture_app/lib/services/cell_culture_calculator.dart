class CellCultureCalculator {
  static int cellsPerUnit({
    required double surfaceArea,
    required double seedingDensity,
  }) {
    return (surfaceArea * seedingDensity).round();
  }

  static int totalSampleUnits({
    required int sampleCount,
    required int replicateCount,
  }) {
    return sampleCount * replicateCount;
  }

  static int totalControlUnits({
    required int blankCount,
    required int negativeControlCount,
    required int vehicleCount,
    required int positiveControlCount,
  }) {
    return blankCount +
        negativeControlCount +
        vehicleCount +
        positiveControlCount;
  }

  static int totalCultureUnits({
    required int totalSampleUnits,
    required int totalControlUnits,
  }) {
    return totalSampleUnits + totalControlUnits;
  }

  static int totalCellsNeeded({
    required int cellsPerUnit,
    required int totalCultureUnits,
  }) {
    return cellsPerUnit * totalCultureUnits;
  }

  static int totalCellsNeededWithExtra({
    required int totalCellsNeeded,
    required double extraPercent,
  }) {
    return (totalCellsNeeded * (1 + extraPercent)).ceil();
  }

  static double totalSeedingVolume({
    required double seedingVolumePerUnit,
    required int totalCultureUnits,
  }) {
    return seedingVolumePerUnit * totalCultureUnits;
  }

  static double totalSeedingVolumeWithExtra({
    required double totalSeedingVolume,
    required double extraPercent,
  }) {
    return totalSeedingVolume * (1 + extraPercent);
  }

  static double requiredCellSuspensionVolume({
    required int totalCellsNeeded,
    required double stockConcentration,
  }) {
    if (stockConcentration <= 0) return 0.0;
    return totalCellsNeeded / stockConcentration;
  }

  static double requiredMediaVolume({
    required double totalSeedingVolume,
    required double requiredCellSuspensionVolume,
  }) {
    final media = totalSeedingVolume - requiredCellSuspensionVolume;
    return media < 0 ? 0.0 : media;
  }
}