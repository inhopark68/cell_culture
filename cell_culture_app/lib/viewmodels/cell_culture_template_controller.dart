import '../models/cell_culture_form_data.dart';
import '../models/cell_culture_summary.dart';
import '../models/cell_line_option.dart';
import '../services/cell_culture_calculator.dart';
import '../services/cell_culture_layout_service.dart';

class CellCultureTemplateController {
  final Map<String, double> cultureWareAreaMap = {
    '6-well plate': 9.6,
    '12-well plate': 3.8,
    '24-well plate': 1.9,
    '48-well plate': 1.0,
    '96-well plate': 0.32,
    'T25 flask': 25.0,
    'T75 flask': 75.0,
  };

  final Map<String, String> cultureWareVolumeMap = {
    '6-well plate': '2–3 mL/well',
    '12-well plate': '1–1.5 mL/well',
    '24-well plate': '0.5–1 mL/well',
    '48-well plate': '0.2–0.5 mL/well',
    '96-well plate': '0.1–0.2 mL/well',
    'T25 flask': '5–7 mL',
    'T75 flask': '12–15 mL',
  };

  final Map<String, double> defaultDensityByAssay = {
    'Viability assay': 20000,
    'qPCR': 50000,
    'ELISA': 40000,
    'Western blot': 80000,
    'Imaging / IF': 30000,
  };

  final Map<String, double> defaultSeedingVolumeByWare = {
    '6-well plate': 2.0,
    '12-well plate': 1.0,
    '24-well plate': 0.5,
    '48-well plate': 0.3,
    '96-well plate': 0.1,
    'T25 flask': 5.0,
    'T75 flask': 12.0,
  };

  final Map<String, double> recommendedDensityByCellLine = {
    'HeLa': 50000,
    'HEK293': 40000,
    'A549': 45000,
    'MCF-7': 50000,
    'NIH/3T3': 30000,
    'L929': 30000,
    'PC-12': 60000,
    'H9c2': 40000,
    'CHO-K1': 35000,
    'BHK-21': 35000,
    'Vero': 30000,
    'COS-7': 35000,
    'CV-1': 35000,
    'MDCK': 40000,
    'D-17': 50000,
    'CRFK': 40000,
    'Fcwf-4': 40000,
  };

  final Map<String, Map<String, double>> recommendedDensityBySpeciesAndAssay = {
    'Human': {
      'Viability assay': 20000,
      'qPCR': 50000,
      'ELISA': 40000,
      'Western blot': 80000,
      'Imaging / IF': 30000,
    },
    'Mouse': {
      'Viability assay': 18000,
      'qPCR': 35000,
      'ELISA': 30000,
      'Western blot': 60000,
      'Imaging / IF': 25000,
    },
    'Rat': {
      'Viability assay': 20000,
      'qPCR': 45000,
      'ELISA': 35000,
      'Western blot': 70000,
      'Imaging / IF': 30000,
    },
    'Hamster': {
      'Viability assay': 18000,
      'qPCR': 35000,
      'ELISA': 30000,
      'Western blot': 60000,
      'Imaging / IF': 25000,
    },
    'Monkey': {
      'Viability assay': 18000,
      'qPCR': 30000,
      'ELISA': 30000,
      'Western blot': 55000,
      'Imaging / IF': 25000,
    },
    'Dog': {
      'Viability assay': 20000,
      'qPCR': 40000,
      'ELISA': 35000,
      'Western blot': 65000,
      'Imaging / IF': 30000,
    },
    'Cat': {
      'Viability assay': 20000,
      'qPCR': 40000,
      'ELISA': 35000,
      'Western blot': 65000,
      'Imaging / IF': 30000,
    },
  };

  double selectedArea(String ware) => cultureWareAreaMap[ware] ?? 0.0;
  String selectedVolume(String ware) => cultureWareVolumeMap[ware] ?? '-';

  double? defaultDensityForAssay(String assay) => defaultDensityByAssay[assay];
  double? defaultVolumeForWare(String ware) => defaultSeedingVolumeByWare[ware];

  String? normalizeSpeciesKey(String? species) {
    if (species == null || species.trim().isEmpty) return null;
    final s = species.toLowerCase().trim();

    if (s == 'human' || s.contains('homo sapiens')) return 'Human';
    if (s == 'mouse' || s.contains('mus musculus')) return 'Mouse';
    if (s == 'rat' || s.contains('rattus')) return 'Rat';
    if (s == 'dog' || s == 'canine' || s.contains('canis')) return 'Dog';
    if (s == 'cat' || s == 'feline' || s.contains('felis')) return 'Cat';

    if (s == 'monkey' ||
        s.contains('african green monkey') ||
        s.contains('chlorocebus') ||
        s.contains('cercopithecus')) {
      return 'Monkey';
    }

    if (s == 'hamster' ||
        s.contains('chinese hamster') ||
        s.contains('syrian hamster') ||
        s.contains('cricetulus') ||
        s.contains('mesocricetus')) {
      return 'Hamster';
    }

    return null;
  }

  bool speciesMatches(String? species, String filter) {
    if (filter == 'All') return true;
    return normalizeSpeciesKey(species) == filter;
  }

  double? getRecommendedDensity({
    required String assay,
    CellLineOption? cellLine,
  }) {
    if (cellLine != null) {
      final byPrimaryName =
          recommendedDensityByCellLine[cellLine.primaryName];
      if (byPrimaryName != null) return byPrimaryName;

      for (final synonym in cellLine.synonyms) {
        final bySynonym = recommendedDensityByCellLine[synonym];
        if (bySynonym != null) return bySynonym;
      }

      final normalizedSpecies = normalizeSpeciesKey(cellLine.species);
      if (normalizedSpecies != null) {
        final bySpecies =
            recommendedDensityBySpeciesAndAssay[normalizedSpecies];
        if (bySpecies != null) return bySpecies[assay];
      }
    }

    return defaultDensityByAssay[assay];
  }

  CellCultureSummary buildSummary(CellCultureFormData form) {
    final area = selectedArea(form.selectedWare);
    final volume = selectedVolume(form.selectedWare);

    final cellsPerUnit = CellCultureCalculator.cellsPerUnit(
      surfaceArea: area,
      seedingDensity: form.seedingDensity,
    );

    final totalSampleUnits = CellCultureCalculator.totalSampleUnits(
      sampleCount: form.sampleCount,
      replicateCount: form.replicateCount,
    );

    final totalControlUnits = CellCultureCalculator.totalControlUnits(
      blankCount: form.blankCount,
      negativeControlCount: form.negativeControlCount,
      vehicleCount: form.vehicleCount,
      positiveControlCount: form.positiveControlCount,
    );

    final totalCultureUnits = CellCultureCalculator.totalCultureUnits(
      totalSampleUnits: totalSampleUnits,
      totalControlUnits: totalControlUnits,
    );

    final totalCellsNeeded = CellCultureCalculator.totalCellsNeeded(
      cellsPerUnit: cellsPerUnit,
      totalCultureUnits: totalCultureUnits,
    );

    final totalCellsNeededWithExtra =
        CellCultureCalculator.totalCellsNeededWithExtra(
      totalCellsNeeded: totalCellsNeeded,
      extraPercent: form.extraPercent,
    );

    final totalSeedingVolume = CellCultureCalculator.totalSeedingVolume(
      seedingVolumePerUnit: form.seedingVolumePerUnit,
      totalCultureUnits: totalCultureUnits,
    );

    final totalSeedingVolumeWithExtra =
        CellCultureCalculator.totalSeedingVolumeWithExtra(
      totalSeedingVolume: totalSeedingVolume,
      extraPercent: form.extraPercent,
    );

    final requiredCellSuspensionVolume =
        CellCultureCalculator.requiredCellSuspensionVolume(
      totalCellsNeeded: totalCellsNeeded,
      stockConcentration: form.stockConcentration,
    );

    final requiredCellSuspensionVolumeWithExtra =
        CellCultureCalculator.requiredCellSuspensionVolume(
      totalCellsNeeded: totalCellsNeededWithExtra,
      stockConcentration: form.stockConcentration,
    );

    final requiredMediaVolume = CellCultureCalculator.requiredMediaVolume(
      totalSeedingVolume: totalSeedingVolume,
      requiredCellSuspensionVolume: requiredCellSuspensionVolume,
    );

    final requiredMediaVolumeWithExtra =
        CellCultureCalculator.requiredMediaVolume(
      totalSeedingVolume: totalSeedingVolumeWithExtra,
      requiredCellSuspensionVolume: requiredCellSuspensionVolumeWithExtra,
    );

    return CellCultureSummary(
      surfaceArea: area,
      workingVolume: volume,
      cellsPerUnit: cellsPerUnit,
      totalSampleUnits: totalSampleUnits,
      totalControlUnits: totalControlUnits,
      totalCultureUnits: totalCultureUnits,
      totalCellsNeeded: totalCellsNeeded,
      totalCellsNeededWithExtra: totalCellsNeededWithExtra,
      totalSeedingVolume: totalSeedingVolume,
      totalSeedingVolumeWithExtra: totalSeedingVolumeWithExtra,
      requiredCellSuspensionVolume: requiredCellSuspensionVolume,
      requiredCellSuspensionVolumeWithExtra:
          requiredCellSuspensionVolumeWithExtra,
      requiredMediaVolume: requiredMediaVolume,
      requiredMediaVolumeWithExtra: requiredMediaVolumeWithExtra,
    );
  }

  List<List<String>> buildGeneratedLayout(CellCultureFormData form) {
    return CellCultureLayoutService.generatePlateLayout(
      ware: form.selectedWare,
      sampleCount: form.sampleCount,
      replicates: form.replicateCount,
      blankCount: form.blankCount,
      vehicleCount: form.vehicleCount,
      positiveControlCount: form.positiveControlCount,
      negativeControlCount: form.negativeControlCount,
    );
  }

  String recommendationText(String ware) {
    switch (ware) {
      case '96-well plate':
        return 'High-throughput assay에 적합합니다.';
      case '24-well plate':
        return 'qPCR, ELISA, imaging assay에 많이 사용됩니다.';
      case '6-well plate':
        return 'Protein/RNA harvest가 필요한 assay에 적합합니다.';
      case 'T25 flask':
      case 'T75 flask':
        return 'Expansion 또는 대량 세포 확보에 적합합니다.';
      default:
        return '선택한 culture ware 조건을 확인하세요.';
    }
  }
}