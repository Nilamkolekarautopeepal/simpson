import 'package:simpson/modals/esn_ds.dart';
import 'package:simpson/modals/listNumber.model.dart' as list_ds;

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


class ProdbudVariantHarness {
  int? id;
  String? name;
  String? stationType;
  String? harnessType;
  bool? isActive;
  List<list_ds.Receipe>? receipes;

  ProdbudVariantHarness({
    this.id,
    this.name,
    this.stationType,
    this.harnessType,
    this.isActive,
    this.receipes,
  });

  factory ProdbudVariantHarness.fromJson(Map<String, dynamic> json) => ProdbudVariantHarness(
        id: json["id"],
        name: json["name"],
        stationType: json["station_type"],
        harnessType: json["harness_type"],
        isActive: json["is_active"],
        receipes: json["receipes"] == null
            ? []
            : List<list_ds.Receipe>.from(json["receipes"].map((x) => list_ds.Receipe.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "name": name,
        "station_type": stationType,
        "harness_type": harnessType,
        "is_active": isActive,
        "receipes": receipes?.map((x) => x.toJson()).toList(),
      };
}

class Result {
  int? id;
  String? engSlno;
  ProdbudVariant? prodbudVariant;
  bool? isActive;

  Result({
    this.id,
    this.engSlno,
    this.prodbudVariant,
    this.isActive,
  });

  factory Result.fromJson(Map<String, dynamic> json) => Result(
        id: json["id"],
        engSlno: json["eng_slno"],
        prodbudVariant: json["prodbud_variant"] == null
            ? null
            : ProdbudVariant.fromJson(json["prodbud_variant"]),
        isActive: json["is_active"],
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "eng_slno": engSlno,
        "prodbud_variant": prodbudVariant?.toJson(),
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