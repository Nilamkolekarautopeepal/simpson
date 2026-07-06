class FlashCurtisModel {
  String? type;
  int? noOfSectors;
  List<SectorData1>? sectorData;

  FlashCurtisModel({
    this.type,
    this.noOfSectors,
    this.sectorData,
  });

  factory FlashCurtisModel.fromJson(Map<String, dynamic> json) {
    return FlashCurtisModel(
      type: json['Type'],
      noOfSectors: json['NoOfSectors'],
      sectorData: json['SectorData'] != null
          ? (json['SectorData'] as List)
              .map((i) => SectorData1.fromJson(i))
              .toList()
          : null,
    );
  }
}

class SectorData1 {
  String? sectorLength;
  String? jsonData; // This likely contains the actual hex payload or path

  SectorData1({
    this.sectorLength,
    this.jsonData,
  });

  factory SectorData1.fromJson(Map<String, dynamic> json) {
    return SectorData1(
      sectorLength: json['SectorLength'],
      jsonData: json['JsonData'],
    );
  }
}