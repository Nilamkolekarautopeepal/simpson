// class ListNumber {
//   int? count;
//   dynamic next;
//   dynamic previous;
//   List<Result>? results;

//   ListNumber({
//     this.count,
//     this.next,
//     this.previous,
//     this.results,
//   });

//   factory ListNumber.fromJson(Map<String, dynamic> json) => ListNumber(
//         count: json["count"],
//         next: json["next"],
//         previous: json["previous"],
//         results: json["results"] == null
//             ? []
//             : List<Result>.from(
//                 json["results"]!.map((x) => Result.fromJson(x))),
//       );

//   Map<String, dynamic> toJson() => {
//         "count": count,
//         "next": next,
//         "previous": previous,
//         "results": results == null
//             ? []
//             : List<dynamic>.from(results!.map((x) => x.toJson())),
//       };
// }

// class Result {
//   int? id;
//   String? variantCode;
//   String? description;
//   int? oem;
//   dynamic vinNo;
//   String? isActive;
//   int? vehicleModel;
//   int? subModel;
//   int? modelYear;
//   List<DatasetEcu>? dDatasetEcu;
//   List<DatasetEcu>? tDatasetEcu;
//   List<ProdbudVariantHarness>? prodbudVariantHarness;

//   Result({
//     this.id,
//     this.variantCode,
//     this.description,
//     this.oem,
//     this.vinNo,
//     this.isActive,
//     this.vehicleModel,
//     this.subModel,
//     this.modelYear,
//     this.dDatasetEcu,
//     this.tDatasetEcu,
//     this.prodbudVariantHarness,
//   });

//   factory Result.fromJson(Map<String, dynamic> json) => Result(
//         id: json["id"],
//         variantCode: json["variant_code"],
//         description: json["description"],
//         oem: json["oem"],
//         vinNo: json["vin_no"],
//         isActive: json["is_active"],
//         vehicleModel: json["vehicle_model"],
//         subModel: json["sub_model"],
//         modelYear: json["model_year"],
//         dDatasetEcu: json["d_dataset_ecu"] == null
//             ? []
//             : List<DatasetEcu>.from(
//                 json["d_dataset_ecu"]!.map((x) => DatasetEcu.fromJson(x))),
//         tDatasetEcu: json["t_dataset_ecu"] == null
//             ? []
//             : List<DatasetEcu>.from(
//                 json["t_dataset_ecu"]!.map((x) => DatasetEcu.fromJson(x))),
//         prodbudVariantHarness: json["prodbud_variant_harness"] == null
//             ? []
//             : List<ProdbudVariantHarness>.from(json["prodbud_variant_harness"]!
//                 .map((x) => ProdbudVariantHarness.fromJson(x))),
//       );

//   Map<String, dynamic> toJson() => {
//         "id": id,
//         "variant_code": variantCode,
//         "description": description,
//         "oem": oem,
//         "vin_no": vinNo,
//         "is_active": isActive,
//         "vehicle_model": vehicleModel,
//         "sub_model": subModel,
//         "model_year": modelYear,
//         "d_dataset_ecu": dDatasetEcu == null
//             ? []
//             : List<dynamic>.from(dDatasetEcu!.map((x) => x.toJson())),
//         "t_dataset_ecu": tDatasetEcu == null
//             ? []
//             : List<dynamic>.from(tDatasetEcu!.map((x) => x.toJson())),
//         "prodbud_variant_harness": prodbudVariantHarness == null
//             ? []
//             : List<dynamic>.from(prodbudVariantHarness!.map((x) => x.toJson())),
//       };
// }

// class DatasetEcu {
//   int? id;
//   int? ecu;
//   String? dataFile;
//   bool? isLatest;
//   bool? isActive;

//   DatasetEcu({
//     this.id,
//     this.ecu,
//     this.dataFile,
//     this.isLatest,
//     this.isActive,
//   });

//   factory DatasetEcu.fromJson(Map<String, dynamic> json) => DatasetEcu(
//         id: json["id"],
//         ecu: json["ecu"],
//         dataFile: json["data_file"],
//         isLatest: json["is_latest"],
//         isActive: json["is_active"],
//       );

//   Map<String, dynamic> toJson() => {
//         "id": id,
//         "ecu": ecu,
//         "data_file": dataFile,
//         "is_latest": isLatest,
//         "is_active": isActive,
//       };
// }

// class ProdbudVariantHarness {
//   int? id;
//   String? name;
//   String? stationType;
//   String? harnessType;
//   bool? isActive;
//   List<Receipe>? receipes;

//   ProdbudVariantHarness({
//     this.id,
//     this.name,
//     this.stationType,
//     this.harnessType,
//     this.isActive,
//     this.receipes,
//   });

//   factory ProdbudVariantHarness.fromJson(Map<String, dynamic> json) =>
//       ProdbudVariantHarness(
//         id: json["id"],
//         name: json["name"],
//         stationType: json["station_type"],
//         harnessType: json["harness_type"],
//         isActive: json["is_active"],
//         receipes: json["receipes"] == null
//             ? []
//             : List<Receipe>.from(
//                 json["receipes"]!.map((x) => Receipe.fromJson(x))),
//       );

//   Map<String, dynamic> toJson() => {
//         "id": id,
//         "name": name,
//         "station_type": stationType,
//         "harness_type": harnessType,
//         "is_active": isActive,
//         "receipes": receipes == null
//             ? []
//             : List<dynamic>.from(receipes!.map((x) => x.toJson())),
//       };
// }

// class Receipe {
//   int? id;
//   String? sensorName;
//   int? regAddress;
//   String? type;
//   String? value;
//   String? unit;
//   int? pinNo;
//   bool? isActive;

//   Receipe({
//     this.id,
//     this.sensorName,
//     this.regAddress,
//     this.type,
//     this.value,
//     this.unit,
//     this.pinNo,
//     this.isActive,
//   });

//   factory Receipe.fromJson(Map<String, dynamic> json) => Receipe(
//         id: json["id"],
//         sensorName: json["sensor_name"],
//         regAddress: json["reg_address"],
//         type: json["type"],
//         value: json["value"],
//         unit: json["unit"],
//         pinNo: json["pin_no"],
//         isActive: json["is_active"],
//       );

//   Map<String, dynamic> toJson() => {
//         "id": id,
//         "sensor_name": sensorName,
//         "reg_address": regAddress,
//         "type": type,
//         "value": value,
//         "unit": unit,
//         "pin_no": pinNo,
//         "is_active": isActive,
//       };
// }
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

/// NOTE: this Result merges TWO real, confirmed API shapes seen from
/// this endpoint:
///  - variant_ecu (nested DataFile object, .dataFile.dataFile) — used
///    by the Test Station's home_page_controller.dart.
///  - d_dataset_ecu / t_dataset_ecu (plain string data_file) — used by
///    PFS's List Number resolution.
/// Both are parsed here so neither station's code breaks; a given API
/// response may populate one, the other, or both.
class Result {
  int? id;
  String? variantCode;
  String? description;
  int? oem;
  dynamic vinNo;
  String? isActive;
  int? vehicleModel;
  int? subModel;
  int? modelYear;
  List<VariantEcu>? variantEcu;
  List<DatasetEcu>? dDatasetEcu;
  List<DatasetEcu>? tDatasetEcu;
  List<ProdbudVariantHarness>? prodbudVariantHarness;

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
    this.prodbudVariantHarness,
  });

  factory Result.fromJson(Map<String, dynamic> json) => Result(
        id: json["id"],
        variantCode: json["variant_code"],
        description: json["description"],
        oem: json["oem"],
        vinNo: json["vin_no"],
        isActive: json["is_active"],
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
        prodbudVariantHarness: json["prodbud_variant_harness"] == null
            ? []
            : List<ProdbudVariantHarness>.from(json["prodbud_variant_harness"]!
                .map((x) => ProdbudVariantHarness.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "variant_code": variantCode,
        "description": description,
        "oem": oem,
        "vin_no": vinNo,
        "is_active": isActive,
        "vehicle_model": vehicleModel,
        "sub_model": subModel,
        "model_year": modelYear,
        "variant_ecu": variantEcu == null
            ? []
            : List<dynamic>.from(variantEcu!.map((x) => x.toJson())),
        "d_dataset_ecu": dDatasetEcu == null
            ? []
            : List<dynamic>.from(dDatasetEcu!.map((x) => x.toJson())),
        "t_dataset_ecu": tDatasetEcu == null
            ? []
            : List<dynamic>.from(tDatasetEcu!.map((x) => x.toJson())),
        "prodbud_variant_harness": prodbudVariantHarness == null
            ? []
            : List<dynamic>.from(prodbudVariantHarness!.map((x) => x.toJson())),
      };
}



/// The Test Station's original shape — data_file is a nested object.
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

/// PFS's confirmed shape — data_file is a plain URL string, and
/// there are two separate arrays (d/t dataset) instead of one.
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

class ProdbudVariantHarness {
  int? id;
  String? name;
  String? stationType;
  String? harnessType;
  bool? isActive;
  List<Receipe>? receipes;

  ProdbudVariantHarness({
    this.id,
    this.name,
    this.stationType,
    this.harnessType,
    this.isActive,
    this.receipes,
  });

  factory ProdbudVariantHarness.fromJson(Map<String, dynamic> json) =>
      ProdbudVariantHarness(
        id: json["id"],
        name: json["name"],
        stationType: json["station_type"],
        harnessType: json["harness_type"],
        isActive: json["is_active"],
        receipes: json["receipes"] == null
            ? []
            : List<Receipe>.from(
                json["receipes"]!.map((x) => Receipe.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "name": name,
        "station_type": stationType,
        "harness_type": harnessType,
        "is_active": isActive,
        "receipes": receipes == null
            ? []
            : List<dynamic>.from(receipes!.map((x) => x.toJson())),
      };
}

class Receipe {
  int? id;
  String? sensorName;
  int? regAddress;
  String? type;
  String? value;
  String? unit;
  int? pinNo;
  bool? isActive;

  Receipe({
    this.id,
    this.sensorName,
    this.regAddress,
    this.type,
    this.value,
    this.unit,
    this.pinNo,
    this.isActive,
  });

  factory Receipe.fromJson(Map<String, dynamic> json) => Receipe(
        id: json["id"],
        sensorName: json["sensor_name"],
        regAddress: json["reg_address"],
        type: json["type"],
        value: json["value"],
        unit: json["unit"],
        pinNo: json["pin_no"],
        isActive: json["is_active"],
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "sensor_name": sensorName,
        "reg_address": regAddress,
        "type": type,
        "value": value,
        "unit": unit,
        "pin_no": pinNo,
        "is_active": isActive,
      };
}

