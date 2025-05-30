import 'package:flutter/material.dart';
//

class ProductProvider extends ChangeNotifier {
  Map<String, dynamic> productData = {};
  bool _isFormDirty = false;

  bool get isFormDirty => _isFormDirty;

  getFormData({
    String? productName,
    String? productDescription,
    String? category,
    double? productPrice,
    int? quantity,
    DateTime? scheduleDate,
    List<String>? imageUrlList,
    bool? chargeShipping,
    int? shippingCharge,
    String? brandName,
    String? size,
    List<String>? sizeList,
  }) {
    _isFormDirty = true;
    
    if (productName != null) {
      productData['productName'] = productName;
    }

    if (productDescription != null) {
      productData['productDescription'] = productDescription;
    }

    if (productPrice != null) {
      productData['productPrice'] = productPrice;
    }

    if (quantity != null) {
      productData['quantity'] = quantity;
    }

    if (category != null) {
      productData['category'] = category;
    }
    if (scheduleDate != null) {
      productData['scheduleDate'] = scheduleDate;
    }
    if (imageUrlList != null) {
      productData['imageUrlList'] = imageUrlList;
    }
    if (chargeShipping != null) {
      productData['chargeShipping'] = chargeShipping;
    }
    if (shippingCharge != null) {
      productData['shippingCharge'] = shippingCharge;
    }
    if (brandName != null) {
      productData['brandName'] = brandName;
    }
    if (size != null) {
      productData['size'] = size;
    }
    if (sizeList != null) {
      productData['sizeList'] = sizeList;
    }
    notifyListeners();
  }

  void clearAllData() {
    productData = {
      'productName': '',
      'productDescription': '',
      'category': '',
      'productPrice': 0.0,
      'quantity': 0,
      'scheduleDate': null,
      'imageUrlList': [],
      'chargeShipping': false,
      'shippingCharge': 0,
      'brandName': '',
      'size': '',
      'sizeList': [],
    };
    _isFormDirty = false;
    notifyListeners();
  }

  bool validateForm() {
    if (productData['productName'] == null || productData['productName'].toString().isEmpty) {
      return false;
    }
    if (productData['productDescription'] == null || productData['productDescription'].toString().isEmpty) {
      return false;
    }
    if (productData['category'] == null || productData['category'].toString().isEmpty) {
      return false;
    }
    if (productData['quantity'] == null || productData['quantity'] <= 0) {
      return false;
    }
    if (productData['productPrice'] == null || productData['productPrice'] <= 0) {
      return false;
    }
    if (productData['imageUrlList'] == null || (productData['imageUrlList'] as List).isEmpty) {
      return false;
    }
    if (productData['brandName'] == null || productData['brandName'].toString().isEmpty) {
      return false;
    }
    if (productData['sizeList'] == null || (productData['sizeList'] as List).isEmpty) {
      return false;
    }
    if (productData['chargeShipping'] == true && (productData['shippingCharge'] == null || productData['shippingCharge'] <= 0)) {
      return false;
    }
    return true;
  }
}
