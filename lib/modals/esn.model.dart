class EsnNumber {
  int? count;
  dynamic next;
  dynamic previous;
  List<Result>? results;

  EsnNumber({
    this.count,
    this.next,
    this.previous,
    this.results,
  });

  factory EsnNumber.fromJson(Map<String, dynamic> json) => EsnNumber(
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
  String? engSlno;
  ModelRef? model;
  ModelRef? subModel;
  bool? isActive;

  Result({
    this.id,
    this.engSlno,
    this.model,
    this.subModel,
    this.isActive,
  });

  factory Result.fromJson(Map<String, dynamic> json) => Result(
        id: json["id"],
        engSlno: json["eng_slno"],
        model: json["model"] == null ? null : ModelRef.fromJson(json["model"]),
        subModel: json["sub_model"] == null
            ? null
            : ModelRef.fromJson(json["sub_model"]),
        isActive: json["is_active"],
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "eng_slno": engSlno,
        "model": model?.toJson(),
        "sub_model": subModel?.toJson(),
        "is_active": isActive,
      };
}

/// Shared shape for both "model" and "sub_model" — both are just
/// {"id": int, "name": String} in the real response.
class ModelRef {
  int? id;
  String? name;

  ModelRef({
    this.id,
    this.name,
  });

  factory ModelRef.fromJson(Map<String, dynamic> json) => ModelRef(
        id: json["id"],
        name: json["name"],
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "name": name,
      };
}