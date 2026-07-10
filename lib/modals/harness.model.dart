class HarnessName {
  int? count;
  dynamic next;
  dynamic previous;
  List<Result>? results;

  HarnessName({
    this.count,
    this.next,
    this.previous,
    this.results,
  });

  factory HarnessName.fromJson(Map<String, dynamic> json) => HarnessName(
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
  String? name;
  Model? model;
  Model? subModel;
  String? stationType;
  String? harnessType;
  bool? isActive;
  List<Receipe>? receipes;

  Result({
    this.id,
    this.name,
    this.model,
    this.subModel,
    this.stationType,
    this.harnessType,
    this.isActive,
    this.receipes,
  });

  factory Result.fromJson(Map<String, dynamic> json) => Result(
        id: json["id"],
        name: json["name"],
        model: json["model"] == null ? null : Model.fromJson(json["model"]),
        subModel: json["sub_model"] == null
            ? null
            : Model.fromJson(json["sub_model"]),
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
        "model": model?.toJson(),
        "sub_model": subModel?.toJson(),
        "station_type": stationType,
        "harness_type": harnessType,
        "is_active": isActive,
        "receipes": receipes == null
            ? []
            : List<dynamic>.from(receipes!.map((x) => x.toJson())),
      };
}

class Model {
  int? id;
  String? name;

  Model({
    this.id,
    this.name,
  });

  factory Model.fromJson(Map<String, dynamic> json) => Model(
        id: json["id"],
        name: json["name"],
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "name": name,
      };
}

class Receipe {
  int? id;
  String? sensorName;
  int? regAddress;
  String? type;
  String? value;
  String? unit;
  String? pinNo;
  bool? isActive;

  Receipe({
    this.id,
    this.sensorName,
    this.regAddress,
    this.type,
    this.value,
    this.unit,
    this.isActive,
  });

  factory Receipe.fromJson(Map<String, dynamic> json) => Receipe(
        id: json["id"],
        sensorName: json["sensor_name"],
        regAddress: json["reg_address"],
        type: json["type"],
        value: json["value"],
        unit: json["unit"],
        isActive: json["is_active"],
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "sensor_name": sensorName,
        "reg_address": regAddress,
        "type": type,
        "value": value,
        "unit": unit,
        "is_active": isActive,
      };
}
