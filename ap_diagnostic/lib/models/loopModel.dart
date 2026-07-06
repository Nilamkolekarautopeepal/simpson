class LoopModel {
  int? loopId;
  int? i; // Current iteration index
  int? maxIndex; // Total iterations
  int? loopLocation; // The pointer to the current step in the script

  LoopModel({
    this.loopId,
    this.i,
    this.maxIndex,
    this.loopLocation,
  });

  factory LoopModel.fromJson(Map<String, dynamic> json) {
    return LoopModel(
      loopId: json['loopId'],
      i: json['i'],
      maxIndex: json['maxIndex'],
      loopLocation: json['loopLocation'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'loopId': loopId,
      'i': i,
      'maxIndex': maxIndex,
      'loopLocation': loopLocation,
    };
  }
}