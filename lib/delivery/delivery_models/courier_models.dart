import 'package:cloud_firestore/cloud_firestore.dart';

class Courier {
  final String id;
  final String name;
  final String phone;
  final String email;
  final bool isAvailable;
  final GeoPoint? currentLocation;
  final List<String> assignedOrders;
  final double rating;
  final int totalDeliveries;

  Courier({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    this.isAvailable = true,
    this.currentLocation,
    this.assignedOrders = const [],
    this.rating = 0.0,
    this.totalDeliveries = 0,
  });

  factory Courier.fromMap(Map<String, dynamic> map) {
    return Courier(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      phone: map['phone'] ?? '',
      email: map['email'] ?? '',
      isAvailable: map['isAvailable'] ?? true,
      currentLocation: map['currentLocation'],
      assignedOrders: List<String>.from(map['assignedOrders'] ?? []),
      rating: (map['rating'] ?? 0.0).toDouble(),
      totalDeliveries: map['totalDeliveries'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'email': email,
      'isAvailable': isAvailable,
      'currentLocation': currentLocation,
      'assignedOrders': assignedOrders,
      'rating': rating,
      'totalDeliveries': totalDeliveries,
    };
  }
}

class DeliveryOrder {
  final String orderId;
  final String courierId;
  final String courierName;
  final String status;
  final String vendorId;
  final String vendorName;
  final String buyerId;
  final String buyerName;
  final String buyerPhone;
  final String shippingAddress;
  final double totalAmount;
  final Timestamp createdAt;
  final Timestamp? pickedUpAt;
  final Timestamp? deliveredAt;

  DeliveryOrder({
    required this.orderId,
    required this.courierId,
    required this.courierName,
    required this.status,
    required this.vendorId,
    required this.vendorName,
    required this.buyerId,
    required this.buyerName,
    required this.buyerPhone,
    required this.shippingAddress,
    required this.totalAmount,
    required this.createdAt,
    this.pickedUpAt,
    this.deliveredAt,
  });

  factory DeliveryOrder.fromMap(Map<String, dynamic> map) {
    return DeliveryOrder(
      orderId: map['orderId'] ?? '',
      courierId: map['courierId'] ?? '',
      courierName: map['courierName'] ?? '',
      status: map['status'] ?? '',
      vendorId: map['vendorId'] ?? '',
      vendorName: map['vendorName'] ?? '',
      buyerId: map['buyerId'] ?? '',
      buyerName: map['buyerName'] ?? '',
      buyerPhone: map['buyerPhone'] ?? '',
      shippingAddress: map['shippingAddress'] ?? '',
      totalAmount: (map['totalAmount'] ?? 0.0).toDouble(),
      createdAt: map['createdAt'] ?? Timestamp.now(),
      pickedUpAt: map['pickedUpAt'],
      deliveredAt: map['deliveredAt'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'orderId': orderId,
      'courierId': courierId,
      'courierName': courierName,
      'status': status,
      'vendorId': vendorId,
      'vendorName': vendorName,
      'buyerId': buyerId,
      'buyerName': buyerName,
      'buyerPhone': buyerPhone,
      'shippingAddress': shippingAddress,
      'totalAmount': totalAmount,
      'createdAt': createdAt,
      'pickedUpAt': pickedUpAt,
      'deliveredAt': deliveredAt,
    };
  }
}
