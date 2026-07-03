class TravalTypeModel {
  final String travelType;

  TravalTypeModel({required this.travelType});

  factory TravalTypeModel.fromJson(Map<String, dynamic> json) {
    return TravalTypeModel(
      travelType: json['travel_type'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'expense_type': travelType,
    };
  }
}
