class FlashingMatrix {
  String? jsonStartAddress;
  String? jsonEndAddress;
  String? ecuMemMapStartAddress;
  String? ecuMemMapEndAddress;
  String? jsonCheckSum;
  String? jsonData;

  FlashingMatrix({
    this.jsonStartAddress,
    this.jsonEndAddress,
    this.ecuMemMapStartAddress,
    this.ecuMemMapEndAddress,
    this.jsonCheckSum,
    this.jsonData,
  });

  factory FlashingMatrix.fromJson(Map<String, dynamic> json) => FlashingMatrix(
        jsonStartAddress: json['JsonStartAddress'],
        jsonEndAddress: json['JsonEndAddress'],
        ecuMemMapStartAddress: json['ECUMemMapStartAddress'],
        ecuMemMapEndAddress: json['ECUMemMapEndAddress'],
        jsonCheckSum: json['JsonCheckSum'],
        jsonData: json['JsonData'],
      );

  Map<String, dynamic> toJson() => {
        'JsonStartAddress': jsonStartAddress,
        'JsonEndAddress': jsonEndAddress,
        'ECUMemMapStartAddress': ecuMemMapStartAddress,
        'ECUMemMapEndAddress': ecuMemMapEndAddress,
        'JsonCheckSum': jsonCheckSum,
        'JsonData': jsonData,
      };
}

class FlashingMatrixData {
  int? noOfSectors;
  List<FlashingMatrix>? sectorData;

  FlashingMatrixData({this.noOfSectors, this.sectorData});

  factory FlashingMatrixData.fromJson(Map<String, dynamic> json) => FlashingMatrixData(
        noOfSectors: json['NoOfSectors'],
        sectorData: json['SectorData'] != null
            ? List<FlashingMatrix>.from(json['SectorData'].map((x) => FlashingMatrix.fromJson(x)))
            : [],
      );

  Map<String, dynamic> toJson() => {
        'NoOfSectors': noOfSectors,
        'SectorData': sectorData?.map((x) => x.toJson()).toList(),
      };
}

class SRECFlashingMatrixData {
  int? noOfSectors;
  String? fileStartAddr;
  List<FlashingMatrix>? sectorData;

  SRECFlashingMatrixData({this.noOfSectors, this.fileStartAddr, this.sectorData});

  factory SRECFlashingMatrixData.fromJson(Map<String, dynamic> json) => SRECFlashingMatrixData(
        noOfSectors: json['NoOfSectors'],
        fileStartAddr: json['file_start_addr'],
        sectorData: json['SectorData'] != null
            ? List<FlashingMatrix>.from(json['SectorData'].map((x) => FlashingMatrix.fromJson(x)))
            : [],
      );

  Map<String, dynamic> toJson() => {
        'NoOfSectors': noOfSectors,
        'file_start_addr': fileStartAddr,
        'SectorData': sectorData?.map((x) => x.toJson()).toList(),
      };
}