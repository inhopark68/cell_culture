class CellLineOption {
  final String primaryName;
  final List<String> synonyms;
  final String source;
  final String catalogNumber;
  final String? cvclId;
  final String? rrid;
  final String? species;
  final String? tissue;
  final String? disease;
  final bool isMisidentified;
  final String? misidentifiedNote;

  const CellLineOption({
    required this.primaryName,
    required this.synonyms,
    required this.source,
    required this.catalogNumber,
    this.cvclId,
    this.rrid,
    this.species,
    this.tissue,
    this.disease,
    this.isMisidentified = false,
    this.misidentifiedNote,
  });

  factory CellLineOption.fromJson(Map<String, dynamic> json) {
    return CellLineOption(
      primaryName: (json['primaryName'] ?? json['name'] ?? '').toString(),
      synonyms: ((json['synonyms'] as List?) ?? const [])
          .map((e) => e.toString())
          .toList(),
      source: (json['source'] ?? '').toString(),
      catalogNumber: (json['catalogNumber'] ?? '').toString(),
      cvclId: json['cvclId']?.toString(),
      rrid: json['rrid']?.toString(),
      species: json['species']?.toString(),
      tissue: json['tissue']?.toString(),
      disease: json['disease']?.toString(),
      isMisidentified: json['isMisidentified'] == true,
      misidentifiedNote: json['misidentifiedNote']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'primaryName': primaryName,
      'synonyms': synonyms,
      'source': source,
      'catalogNumber': catalogNumber,
      'cvclId': cvclId,
      'rrid': rrid,
      'species': species,
      'tissue': tissue,
      'disease': disease,
      'isMisidentified': isMisidentified,
      'misidentifiedNote': misidentifiedNote,
    };
  }

  /// 기존 코드 호환용
  String get name => primaryName;

  /// 기존 alias 기반 코드 호환용
  List<String> get aliases => synonyms;

  String get displayLabel => '$primaryName ($source $catalogNumber)';

  String get exportLabel => '$primaryName ($source $catalogNumber)';

  List<String> get searchableTexts => [
        primaryName,
        ...synonyms,
        source,
        catalogNumber,
        if (cvclId != null) cvclId!,
        if (rrid != null) rrid!,
        if (species != null) species!,
        if (tissue != null) tissue!,
        if (disease != null) disease!,
      ];
}