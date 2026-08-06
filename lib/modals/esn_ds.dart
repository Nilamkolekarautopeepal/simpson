class ProdbudVariant {
  int? id;
  String? variantCode;
  String? description;
  int? oem;
  String? vinNo;
  int? vehicleModel;
  int? subModel;
  int? modelYear;
  List<DatasetEcu>? dDatasetEcu;
  List<DatasetEcu>? tDatasetEcu;
  bool? isActive;

  ProdbudVariant({
    this.id,
    this.variantCode,
    this.description,
    this.oem,
    this.vinNo,
    this.vehicleModel,
    this.subModel,
    this.modelYear,
    this.dDatasetEcu,
    this.tDatasetEcu,
    this.isActive,
  });

  factory ProdbudVariant.fromJson(Map<String, dynamic> json) => ProdbudVariant(
        id: json["id"],
        variantCode: json["variant_code"]?.toString(),
        description: json["description"]?.toString(),
        oem: json["oem"],
        vinNo: json["vin_no"],
        vehicleModel: json["vehicle_model"],
        subModel: json["sub_model"],
        modelYear: json["model_year"],
        dDatasetEcu: json["d_dataset_ecu"] == null
            ? []
            : List<DatasetEcu>.from(
                json["d_dataset_ecu"].map((x) => DatasetEcu.fromJson(x))),
        tDatasetEcu: json["t_dataset_ecu"] == null
            ? []
            : List<DatasetEcu>.from(
                json["t_dataset_ecu"].map((x) => DatasetEcu.fromJson(x))),
        isActive: json["is_active"] is bool ? json["is_active"] : null,
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "variant_code": variantCode,
        "description": description,
        "oem": oem,
        "vin_no": vinNo,
        "vehicle_model": vehicleModel,
        "sub_model": subModel,
        "model_year": modelYear,
        "d_dataset_ecu": dDatasetEcu?.map((x) => x.toJson()).toList(),
        "t_dataset_ecu": tDatasetEcu?.map((x) => x.toJson()).toList(),
        "is_active": isActive,
      };
}

class DatasetEcu {
  int? id;
  int? ecu;
  String? dataFile;
  bool? isLatest;
  bool? isActive;

  DatasetEcu({this.id, this.ecu, this.dataFile, this.isLatest, this.isActive});

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