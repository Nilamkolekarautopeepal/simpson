

class PurposeoOfTravelModel {
  final String purposeoOfTravel;

  PurposeoOfTravelModel({required this.purposeoOfTravel});

  factory PurposeoOfTravelModel.fromJson(Map<String, dynamic> json) {
    return PurposeoOfTravelModel(
      purposeoOfTravel: json['purpose_of_travel'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'expense_type': purposeoOfTravel,
    };
  }
}
