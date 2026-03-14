class ElisaCalculator {
  static int totalSampleWells({
    required int sampleCount,
    required int replicateCount,
  }) {
    return sampleCount * replicateCount;
  }

  static int totalControlWells({
    required int blankCount,
    required int negativeControlCount,
    required int positiveControlCount,
    required int standardCount,
    required int standardReplicateCount,
  }) {
    return blankCount +
        negativeControlCount +
        positiveControlCount +
        (standardCount * standardReplicateCount);
  }

  static int totalWells({
    required int totalSampleWells,
    required int totalControlWells,
  }) {
    return totalSampleWells + totalControlWells;
  }

  static double totalVolumeNeeded({
    required double volumePerWell,
    required int totalWells,
    required double extraPercent,
  }) {
    return volumePerWell * totalWells * (1 + extraPercent);
  }

  static double dilutionVolumeFromStock({
    required double targetVolume,
    required double dilutionFactor,
  }) {
    if (dilutionFactor <= 0) return 0.0;
    return targetVolume / dilutionFactor;
  }

  static double diluentVolume({
    required double targetVolume,
    required double stockVolume,
  }) {
    final value = targetVolume - stockVolume;
    return value < 0 ? 0 : value;
  }
}