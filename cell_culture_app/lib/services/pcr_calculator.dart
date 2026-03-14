class PcrCalculator {
  static int totalWells({
    required int sampleCount,
    required int replicateCount,
    required int controlCount,
  }) {
    return (sampleCount * replicateCount) + controlCount;
  }

  static int mixReactionCount({
    required int totalWells,
    required double extraPercent,
  }) {
    return (totalWells * (1 + extraPercent)).ceil();
  }

  static double waterPerReaction({
    required double reactionVolume,
    required double masterMix2x,
    required double forwardPrimer,
    required double reversePrimer,
    required double templateVolume,
  }) {
    final water = reactionVolume -
        (masterMix2x + forwardPrimer + reversePrimer + templateVolume);
    return water < 0 ? 0 : water;
  }

  static double masterMixPerReaction({
    required double masterMix2x,
    required double forwardPrimer,
    required double reversePrimer,
    required double waterPerReaction,
  }) {
    return masterMix2x + forwardPrimer + reversePrimer + waterPerReaction;
  }

  static double totalReagentVolume({
    required double perReactionVolume,
    required int mixReactionCount,
  }) {
    return perReactionVolume * mixReactionCount;
  }

  static double totalTemplateVolume({
    required double templateVolume,
    required int totalWells,
  }) {
    return templateVolume * totalWells;
  }
}