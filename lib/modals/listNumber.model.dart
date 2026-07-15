class ListNumber {
  int? count;
  dynamic next;
  dynamic previous;
  List<Result>? results;

  ListNumber({
    this.count,
    this.next,
    this.previous,
    this.results,
  });

  factory ListNumber.fromJson(Map<String, dynamic> json) => ListNumber(
        count: json["count"],
        next: json["next"],
        previous: json["previous"],
        results: json["results"] == null
            ? []
            : List<Result>.from(
                json["results"]!.map((x) => Result.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "count": count,
        "next": next,
        "previous": previous,
        "results": results == null
            ? []
            : List<dynamic>.from(results!.map((x) => x.toJson())),
      };
}

class Result {
  int? id;
  String? variantCode;
  String? description;
  int? oem;
  String? vinNo;
  IsActive? isActive;
  int? vehicleModel;
  int? subModel;
  int? modelYear;
  List<VariantEcu>? variantEcu;
  List<DatasetEcu>? dDatasetEcu;
  List<DatasetEcu>? tDatasetEcu;

  Result({
    this.id,
    this.variantCode,
    this.description,
    this.oem,
    this.vinNo,
    this.isActive,
    this.vehicleModel,
    this.subModel,
    this.modelYear,
    this.variantEcu,
    this.dDatasetEcu,
    this.tDatasetEcu,
  });

  factory Result.fromJson(Map<String, dynamic> json) => Result(
        id: json["id"],
        variantCode: json["variant_code"],
        description: json["description"],
        oem: json["oem"],
        vinNo: json["vin_no"],
        isActive: isActiveValues.map[json["is_active"]]!,
        vehicleModel: json["vehicle_model"],
        subModel: json["sub_model"],
        modelYear: json["model_year"],
        variantEcu: json["variant_ecu"] == null
            ? []
            : List<VariantEcu>.from(
                json["variant_ecu"]!.map((x) => VariantEcu.fromJson(x))),
        dDatasetEcu: json["d_dataset_ecu"] == null
            ? []
            : List<DatasetEcu>.from(
                json["d_dataset_ecu"]!.map((x) => DatasetEcu.fromJson(x))),
        tDatasetEcu: json["t_dataset_ecu"] == null
            ? []
            : List<DatasetEcu>.from(
                json["t_dataset_ecu"]!.map((x) => DatasetEcu.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "variant_code": variantCode,
        "description": description,
        "oem": oem,
        "vin_no": vinNo,
        "is_active": isActiveValues.reverse[isActive],
        "vehicle_model": vehicleModel,
        "sub_model": subModel,
        "model_year": modelYear,
        "variant_ecu": variantEcu == null
            ? []
            : List<dynamic>.from(variantEcu!.map((x) => x.toJson())),
      };
}

enum IsActive { ACTIVE }

final isActiveValues = EnumValues({"active": IsActive.ACTIVE});

class VariantEcu {
  int? id;
  int? ecu;
  DataFile? dataFile;
  bool? isLatest;
  bool? isActive;

  VariantEcu({
    this.id,
    this.ecu,
    this.dataFile,
    this.isLatest,
    this.isActive,
  });

  factory VariantEcu.fromJson(Map<String, dynamic> json) => VariantEcu(
        id: json["id"],
        ecu: json["ecu"],
        dataFile: json["data_file"] == null
            ? null
            : DataFile.fromJson(json["data_file"]),
        isLatest: json["is_latest"],
        isActive: json["is_active"],
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "ecu": ecu,
        "data_file": dataFile?.toJson(),
        "is_latest": isLatest,
        "is_active": isActive,
      };
}

/// Matches the REAL shape of d_dataset_ecu / t_dataset_ecu entries —
/// data_file here is a plain URL string, not a nested object like
/// VariantEcu's data_file above. Two separate arrays exist per variant
/// result: d_dataset_ecu and t_dataset_ecu (one per dataset type).
class DatasetEcu {
  int? id;
  int? ecu;
  String? dataFile;
  bool? isLatest;
  bool? isActive;

  DatasetEcu({
    this.id,
    this.ecu,
    this.dataFile,
    this.isLatest,
    this.isActive,
  });

  factory DatasetEcu.fromJson(Map<String, dynamic> json) => DatasetEcu(
        id: json["id"],
        ecu: json["ecu"],
        dataFile: json["data_file"],
        isLatest: json["is_latest"],
        isActive: json["is_active"],
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "ecu": ecu,
        "data_file": dataFile,
        "is_latest": isLatest,
        "is_active": isActive,
      };
}

class DataFile {
  int? id;
  int? sequenceFileName;
  String? dataFile;
  String? hexSrecFile;

  DataFile({
    this.id,
    this.sequenceFileName,
    this.dataFile,
    this.hexSrecFile,
  });

  factory DataFile.fromJson(Map<String, dynamic> json) => DataFile(
        id: json["id"],
        sequenceFileName: json["sequence_file_name"],
        dataFile: json["data_file"],
        hexSrecFile: json["hex_srec_file"],
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "sequence_file_name": sequenceFileName,
        "data_file": dataFile,
        "hex_srec_file": hexSrecFile,
      };
}

class EnumValues<T> {
  Map<String, T> map;
  late Map<T, String> reverseMap;

  EnumValues(this.map);

  Map<T, String> get reverse {
    reverseMap = map.map((k, v) => MapEntry(v, k));
    return reverseMap;
  }
}
