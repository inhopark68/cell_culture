class MrnaCdnaCalculator {
  static double adjustedReactionCount({
    required int replicateCount,
    required double extraPercent,
  }) {
    return replicateCount * (1 + extraPercent);
  }

  static double totalRequiredRnaNgPerSample({
    required double inputRnaNgPerReaction,
    required int replicateCount,
    required double extraPercent,
  }) {
    return inputRnaNgPerReaction *
        adjustedReactionCount(
          replicateCount: replicateCount,
          extraPercent: extraPercent,
        );
  }

  static double totalYieldNg({
    required double concentrationNgPerUl,
    required double elutionVolumeUl,
  }) {
    return concentrationNgPerUl * elutionVolumeUl;
  }

  static double requiredRnaVolumePerReactionUl({
    required double inputRnaNgPerReaction,
    required double concentrationNgPerUl,
  }) {
    if (concentrationNgPerUl <= 0) return 0;
    return inputRnaNgPerReaction / concentrationNgPerUl;
  }

  static double totalRequiredRnaVolumeUl({
    required double totalRequiredRnaNgPerSample,
    required double concentrationNgPerUl,
  }) {
    if (concentrationNgPerUl <= 0) return 0;
    return totalRequiredRnaNgPerSample / concentrationNgPerUl;
  }

  static double waterPerReactionUl({
    required double reactionVolumeUl,
    required double fixedMixVolumeUl,
    required double requiredRnaVolumePerReactionUl,
  }) {
    return reactionVolumeUl -
        fixedMixVolumeUl -
        requiredRnaVolumePerReactionUl;
  }

  static double remainingRnaNg({
    required double totalYieldNg,
    required double totalRequiredRnaNgPerSample,
  }) {
    return totalYieldNg - totalRequiredRnaNgPerSample;
  }

  static bool isEnoughYield({
    required double totalYieldNg,
    required double totalRequiredRnaNgPerSample,
  }) {
    return totalYieldNg >= totalRequiredRnaNgPerSample;
  }

  static bool isVolumeValid({
    required double waterPerReactionUl,
  }) {
    return waterPerReactionUl >= 0;
  }

  static bool isReady({
    required double concentrationNgPerUl,
    required double totalYieldNg,
    required double totalRequiredRnaNgPerSample,
    required double waterPerReactionUl,
  }) {
    if (concentrationNgPerUl <= 0) return false;
    if (!isEnoughYield(
      totalYieldNg: totalYieldNg,
      totalRequiredRnaNgPerSample: totalRequiredRnaNgPerSample,
    )) {
      return false;
    }
    if (!isVolumeValid(waterPerReactionUl: waterPerReactionUl)) {
      return false;
    }
    return true;
  }
}