class DtcDataset {
  int? count;
  dynamic next;
  dynamic previous;
  List<Result>? results;

  DtcDataset({
    this.count,
    this.next,
    this.previous,
    this.results,
  });

  factory DtcDataset.fromJson(Map<String, dynamic> json) => DtcDataset(
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
  String? code;
  String? description;
  List<DtcCode>? dtcCode;

  Result({
    this.id,
    this.code,
    this.description,
    this.dtcCode,
  });

  factory Result.fromJson(Map<String, dynamic> json) => Result(
        id: json["id"],
        code: json["code"],
        description: json["description"],
        dtcCode: json["dtc_code"] == null
            ? []
            : List<DtcCode>.from(
                json["dtc_code"]!.map((x) => DtcCode.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "code": code,
        "description": description,
        "dtc_code": dtcCode == null
            ? []
            : List<dynamic>.from(dtcCode!.map((x) => x.toJson())),
      };
}

class DtcCode {
  int? id;
  String? code;
  String? description;
  String? frenchDescription;
  int? pageNo;
  dynamic environmentSnapshot;
  dynamic environmentSnapshot2;
  String? relatedSensor; // NEW — backend sends this as a plain string, e.g. "EGR"

  DtcCode({
    this.id,
    this.code,
    this.description,
    this.frenchDescription,
    this.pageNo,
    this.environmentSnapshot,
    this.environmentSnapshot2,
    this.relatedSensor, // NEW
  });

  factory DtcCode.fromJson(Map<String, dynamic> json) => DtcCode(
        id: json["id"],
        code: json["code"],
        description: json["description"],
        frenchDescription: json["french_description"],
        pageNo: json["page_no"],
        environmentSnapshot: json["environment_snapshot"],
        environmentSnapshot2: json["environment_snapshot2"],
        relatedSensor: json["related_sensor"] as String?, // NEW — plain string, no .map()
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "code": code,
        "description": description,
        "french_description": frenchDescription,
        "page_no": pageNo,
        "environment_snapshot": environmentSnapshot,
        "environment_snapshot2": environmentSnapshot2,
        "related_sensor": relatedSensor, // NEW
      };
}