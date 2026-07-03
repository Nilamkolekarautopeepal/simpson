class TravalFundingModel {
  final String travelFunding;

  TravalFundingModel({required this.travelFunding});

  factory TravalFundingModel.fromJson(Map<String, dynamic> json) {
    return TravalFundingModel(
      travelFunding: json['travel_funding'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'travel_funding': travelFunding,
    };
  }
}
