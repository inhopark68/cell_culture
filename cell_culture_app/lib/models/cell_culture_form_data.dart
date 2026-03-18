class CellCultureFormData {
  final String selectedAssay;
  final String selectedWare;

  final double seedingDensity;
  final int sampleCount;
  final int replicateCount;
  final int targetConfluency;

  final int blankCount;
  final int vehicleCount;
  final int positiveControlCount;
  final int negativeControlCount;

  final double seedingVolumePerUnit;
  final double stockConcentration;
  final double extraPercent;

  const CellCultureFormData({
    required this.selectedAssay,
    required this.selectedWare,
    required this.seedingDensity,
    required this.sampleCount,
    required this.replicateCount,
    required this.targetConfluency,
    required this.blankCount,
    required this.vehicleCount,
    required this.positiveControlCount,
    required this.negativeControlCount,
    required this.seedingVolumePerUnit,
    required this.stockConcentration,
    required this.extraPercent,
  });

  factory CellCultureFormData.fromRaw({
    required String selectedAssay,
    required String selectedWare,
    required String seedingDensityText,
    required String sampleCountText,
    required String replicateText,
    required String targetConfluencyText,
    required String blankCountText,
    required String vehicleCountText,
    required String positiveControlCountText,
    required String negativeControlCountText,
    required String seedingVolumeText,
    required String stockConcentrationText,
    required String extraPercentText,
  }) {
    return CellCultureFormData(
      selectedAssay: selectedAssay,
      selectedWare: selectedWare,
      seedingDensity: double.tryParse(seedingDensityText) ?? 0,
      sampleCount: int.tryParse(sampleCountText) ?? 0,
      replicateCount: int.tryParse(replicateText) ?? 0,
      targetConfluency: int.tryParse(targetConfluencyText) ?? 0,
      blankCount: int.tryParse(blankCountText) ?? 0,
      vehicleCount: int.tryParse(vehicleCountText) ?? 0,
      positiveControlCount: int.tryParse(positiveControlCountText) ?? 0,
      negativeControlCount: int.tryParse(negativeControlCountText) ?? 0,
      seedingVolumePerUnit: double.tryParse(seedingVolumeText) ?? 0,
      stockConcentration: double.tryParse(stockConcentrationText) ?? 0,
      extraPercent: (double.tryParse(extraPercentText) ?? 0) / 100.0,
    );
  }

  List<String> validate() {
    final errors = <String>[];

    if (seedingDensity <= 0) {
      errors.add('Seeding density는 0보다 커야 합니다.');
    }
    if (sampleCount < 0) {
      errors.add('Sample count는 0 이상이어야 합니다.');
    }
    if (replicateCount <= 0) {
      errors.add('Replicates는 1 이상이어야 합니다.');
    }
    if (targetConfluency < 0 || targetConfluency > 100) {
      errors.add('Target confluency는 0~100 범위여야 합니다.');
    }
    if (blankCount < 0 ||
        vehicleCount < 0 ||
        positiveControlCount < 0 ||
        negativeControlCount < 0) {
      errors.add('Control count는 0 이상이어야 합니다.');
    }
    if (seedingVolumePerUnit <= 0) {
      errors.add('Seeding volume per unit은 0보다 커야 합니다.');
    }
    if (stockConcentration <= 0) {
      errors.add('Cell stock concentration은 0보다 커야 합니다.');
    }
    if (extraPercent < 0) {
      errors.add('Extra(%)는 0 이상이어야 합니다.');
    }

    return errors;
  }
}