class CellLineOption {
  final String name;
  final String source;
  final String catalogNumber;
  final String? species;
  final String? tissue;
  final String? disease;

  const CellLineOption({
    required this.name,
    required this.source,
    required this.catalogNumber,
    this.species,
    this.tissue,
    this.disease,
  });

  factory CellLineOption.fromJson(Map<String, dynamic> json) {
    return CellLineOption(
      name: json['name'] as String,
      source: json['source'] as String,
      catalogNumber: json['catalogNumber'] as String,
      species: json['species'] as String?,
      tissue: json['tissue'] as String?,
      disease: json['disease'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'source': source,
        'catalogNumber': catalogNumber,
        'species': species,
        'tissue': tissue,
        'disease': disease,
      };

  String get displayLabel => '$name ($source $catalogNumber)';
  String get exportLabel => '$name | $source $catalogNumber';
}