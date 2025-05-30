import 'package:flutter/material.dart';

class CartsAttributes with ChangeNotifier {
  final String productName;
  final String productId;
  final List imageUrl;
  final int quantity;
  final double productPrice;
  final String productSize;
  final String brandName;
  final String category;
  final String productDescription;
  final String vendorId;
  final int stock;
  

  CartsAttributes({
    required this.productName,
    required this.productId,
    required this.imageUrl,
    required this.quantity,
    required this.productPrice,
    required this.productSize,
    required this.brandName,
    required this.category,
    required this.productDescription,
    required this.vendorId,
    required this.stock,
  });
}
