import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class OrderController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Create a new order
  Future<String> createOrder({
    required String vendorId,
    required List<Map<String, dynamic>> products,
    required double totalAmount,
    required String shippingAddress,
    required String paymentMethod,
    required String buyerName,
    required String buyerPhone,
  }) async {
    try {
      if (_auth.currentUser == null) {
        return 'User not authenticated';
      }

      String buyerId = _auth.currentUser!.uid;
      String orderId = _firestore.collection('orders').doc().id;

      // Validate input data
      if (products.isEmpty) {
        return 'No products in order';
      }

      if (totalAmount <= 0) {
        return 'Invalid total amount';
      }

      // Get vendor information
      DocumentSnapshot vendorDoc = await _firestore.collection('vendors').doc(vendorId).get();
      if (!vendorDoc.exists) {
        return 'Vendor not found';
      }
      Map<String, dynamic> vendorData = vendorDoc.data() as Map<String, dynamic>;

      // Create order document
      await _firestore.collection('orders').doc(orderId).set({
        'orderId': orderId,
        'buyerId': buyerId,
        'vendorId': vendorId,
        'vendorName': vendorData['bussinessName'] ?? 'Unknown Vendor',
        'vendorLocation': vendorData['location'],
        'products': products,
        'totalAmount': totalAmount,
        'shippingAddress': shippingAddress,
        'paymentMethod': paymentMethod,
        'buyerName': buyerName,
        'buyerPhone': buyerPhone,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Add order reference to buyer's orders
      await _firestore.collection('buyers').doc(buyerId).collection('orders').doc(orderId).set({
        'orderId': orderId,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Add order reference to vendor's orders
      await _firestore.collection('vendors').doc(vendorId).collection('orders').doc(orderId).set({
        'orderId': orderId,
        'createdAt': FieldValue.serverTimestamp(),
      });

      return 'success';
    } catch (e) {
      return 'Error creating order: $e';
    }
  }

  // Get orders for current buyer
  Stream<QuerySnapshot> getBuyerOrders() {
    if (_auth.currentUser == null) {
      throw Exception('User not authenticated');
    }
    
    String buyerId = _auth.currentUser!.uid;
    return _firestore
        .collection('orders')
        .where('buyerId', isEqualTo: buyerId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // Get orders for a vendor
  Stream<QuerySnapshot>? getVendorOrders(String vendorId) {
    try {
      if (vendorId.isEmpty) {
        return null;
      }

      return _firestore
          .collection('orders')
          .where('vendorId', isEqualTo: vendorId)
          .snapshots();
    } catch (e) {
      print('Error getting vendor orders: $e');
      return null;
    }
  }

  // Helper method to update product quantities when order is delivered
  Future<void> _updateProductQuantities(Map<String, dynamic> orderData) async {
    try {
      final products = orderData['products'] as List;
      final batch = _firestore.batch();

      for (var product in products) {
        final productId = product['productId'] ?? product['id'];
        final orderedQuantity = product['quantity'] as int;

        // Get current product document
        final productRef = _firestore.collection('products').doc(productId);
        final productDoc = await productRef.get();

        if (productDoc.exists) {
          final currentQuantity = productDoc.data()?['quantity'] as int? ?? 0;
          final newQuantity = currentQuantity - orderedQuantity;

          // Update product quantity
          batch.update(productRef, {
            'quantity': newQuantity,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      }

      // Commit all updates
      await batch.commit();
    } catch (e) {
      print('Error updating product quantities: $e');
      throw e;
    }
  }

  // Update order status
  Future<String> updateOrderStatus(String orderId, String status) async {
    try {
      if (orderId.isEmpty) {
        return 'Invalid order ID';
      }

      // Get order document
      DocumentSnapshot orderDoc = await _firestore.collection('orders').doc(orderId).get();

      if (!orderDoc.exists) {
        return 'Order not found';
      }

      Map<String, dynamic> orderData = orderDoc.data() as Map<String, dynamic>;
      String currentStatus = orderData['status'];

      // Validate status transition
      if (!_isValidStatusTransition(currentStatus, status)) {
        return 'Invalid status transition from $currentStatus to $status';
      }

      // If status is being changed to delivered, update product quantities
      if (status == 'delivered') {
        await _updateProductQuantities(orderData);
      }

      // Update order status
      await _firestore.collection('orders').doc(orderId).update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Send notifications based on status change
      await _sendStatusChangeNotifications(orderId, status, orderData);

      return 'success';
    } catch (e) {
      return 'Error updating order status: $e';
    }
  }

  // Helper method to validate status transitions
  bool _isValidStatusTransition(String currentStatus, String newStatus) {
    final validTransitions = {
      'pending': ['processing', 'cancelled'],
      'processing': ['ready_for_pickup', 'cancelled'],
      'ready_for_pickup': ['picked_up', 'cancelled'],
      'picked_up': ['on_delivery'],
      'on_delivery': ['delivered'],
    };

    return validTransitions[currentStatus]?.contains(newStatus) ?? false;
  }

  // Helper method to send notifications for status changes
  Future<void> _sendStatusChangeNotifications(
    String orderId,
    String newStatus,
    Map<String, dynamic> orderData,
  ) async {
    String notificationTitle = '';
    String notificationBody = '';

    switch (newStatus) {
      case 'ready_for_pickup':
        notificationTitle = 'Order Ready for Pickup';
        notificationBody = 'Order #${orderId.substring(0, 8)} is ready for pickup';
        break;
      case 'picked_up':
        notificationTitle = 'Order Picked Up';
        notificationBody = 'Order #${orderId.substring(0, 8)} has been picked up by ${orderData['courierName']}';
        break;
      case 'on_delivery':
        notificationTitle = 'Order On Delivery';
        notificationBody = 'Your order is on its way with ${orderData['courierName']}';
        break;
      case 'delivered':
        notificationTitle = 'Order Delivered';
        notificationBody = 'Your order has been delivered';
        break;
    }

    if (notificationTitle.isNotEmpty) {
      // Notify buyer
      await _firestore.collection('notifications').add({
        'userId': orderData['buyerId'],
        'title': notificationTitle,
        'body': notificationBody,
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Notify vendor
      await _firestore.collection('notifications').add({
        'userId': orderData['vendorId'],
        'title': notificationTitle,
        'body': 'Order #${orderId.substring(0, 8)} $notificationBody',
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  // Get order details
  Future<DocumentSnapshot?> getOrderDetails(String orderId) async {
    try {
      if (orderId.isEmpty) {
        return null;
      }

      return await _firestore.collection('orders').doc(orderId).get();
    } catch (e) {
      print('Error getting order details: $e');
      return null;
    }
  }

  // Cancel order
  Future<String> cancelOrder(String orderId) async {
    try {
      if (orderId.isEmpty) {
        return 'Invalid order ID';
      }

      DocumentSnapshot orderDoc = await _firestore.collection('orders').doc(orderId).get();
      
      if (!orderDoc.exists) {
        return 'Order not found';
      }

      Map<String, dynamic> orderData = orderDoc.data() as Map<String, dynamic>;
      
      // Only allow cancellation if order is pending
      if (orderData['status'] != 'pending') {
        return 'Cannot cancel order. Current status: ${orderData['status']}';
      }

      await _firestore.collection('orders').doc(orderId).update({
        'status': 'cancelled',
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return 'success';
    } catch (e) {
      return 'Error cancelling order: $e';
    }
  }
}
