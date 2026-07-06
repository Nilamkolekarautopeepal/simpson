

enum FlashIndexType {
  greavesBoschBs6,
  greavesAdvantekBs6A46, UDS,
}

/// Extension to help with UI display or string mapping if needed
extension FlashIndexTypeExtension on FlashIndexType {
  String get name {
    switch (this) {
      case FlashIndexType.greavesBoschBs6:
        return "GREAVES_BOSCH_BS6";
      case FlashIndexType.greavesAdvantekBs6A46:
        return "GREAVES_ADVANTEK_BS6_A46";
      case FlashIndexType.UDS:

        throw UnimplementedError();
    }
  }
}