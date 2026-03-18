class CellCultureSummary {
  final double surfaceArea;
  final String workingVolume;

  final int cellsPerUnit;
  final int totalSampleUnits;
  final int totalControlUnits;
  final int totalCultureUnits;
  final int totalCellsNeeded;
  final int totalCellsNeededWithExtra;

  final double totalSeedingVolume;
  final double totalSeedingVolumeWithExtra;
  final double requiredCellSuspensionVolume;
  final double requiredCellSuspensionVolumeWithExtra;
  final double requiredMediaVolume;
  final double requiredMediaVolumeWithExtra;

  const CellCultureSummary({
    required this.surfaceArea,
    required this.workingVolume,
    required this.cellsPerUnit,
    required this.totalSampleUnits,
    required this.totalControlUnits,
    required this.totalCultureUnits,
    required this.totalCellsNeeded,
    required this.totalCellsNeededWithExtra,
    required this.totalSeedingVolume,
    required this.totalSeedingVolumeWithExtra,
    required this.requiredCellSuspensionVolume,
    required this.requiredCellSuspensionVolumeWithExtra,
    required this.requiredMediaVolume,
    required this.requiredMediaVolumeWithExtra,
  });
}