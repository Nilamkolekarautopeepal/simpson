class Address {
  final String? currentAddress;
  final String? permanentAddress;
 
  Address({
    this.currentAddress,
    this.permanentAddress,
  });

  factory Address.fromMap(Map<String, dynamic> data) {
    return Address(
      currentAddress: data['current_address'] as String?,
      permanentAddress: data['permanent_address'] as String?,  
    );
  }

  factory Address.empty() {
    return Address(
      currentAddress: '',
      permanentAddress: '',  
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'current_address': currentAddress,
      'permanent_address': permanentAddress,
    };
  }
}
