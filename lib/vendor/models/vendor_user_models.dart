class VendorUserModels {
  final bool? approved;
  final String? bussinessName;
  final String? cityValue;
  final String? email;
  final String? storeImage;
  final String? validIdImage;
  final String? phoneNumber;
  final String? stateValue;
  final String? taxValue;
  final String? taxRegistered;
  final String? userId;

  VendorUserModels({
    required this.approved,
    required this.bussinessName,
    required this.cityValue,
    required this.email,
    required this.storeImage,
    required this.validIdImage,
    required this.phoneNumber,
    required this.stateValue,
    required this.taxValue,
    required this.taxRegistered,
    required this.userId,
  });

  // Factory constructor to create a model from Firestore data
  factory VendorUserModels.fromJson(Map<String, dynamic> json) {
    return VendorUserModels(
      approved: json['approved'] as bool?,
      bussinessName: json['bussinessName'] as String?,
      cityValue: json['cityValue'] as String?,
      email: json['email'] as String?,
      storeImage: json['storeImage'] as String?,
      validIdImage: json['validIdImage'] as String?,
      phoneNumber: json['phoneNumber'] as String?,
      stateValue: json['stateValue'] as String?,
      taxValue: json['taxValue'] as String?,
      taxRegistered: json['taxRegistered'] as String?,
      userId: json['userId'] as String?,
    );
  }

  // Method to convert model to a map (useful for saving to Firestore)
  Map<String, dynamic> toJson() {
    return {
      'approved': approved,
      'bussinessName': bussinessName,
      'cityValue': cityValue,
      'email': email,
      'storeImage': storeImage,
      'validIdImage': validIdImage,
      'phoneNumber': phoneNumber,
      'stateValue': stateValue,
      'taxValue': taxValue,
      'taxRegistered': taxRegistered,
      'userId': userId,
    };
  }
}
