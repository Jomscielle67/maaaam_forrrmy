import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CourierController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get courier profile
  Future<Map<String, dynamic>?> getCourierProfile() async {
    try {
      if (_auth.currentUser == null) return null;

      DocumentSnapshot doc = await _firestore
          .collection('couriers')
          .doc(_auth.currentUser!.uid)
          .get();

      if (!doc.exists) return null;
      return {...doc.data() as Map<String, dynamic>, 'id': doc.id};
    } catch (e) {
      print('Error getting courier profile: $e');
      return null;
    }
  }

  // Get assigned orders for courier
  Stream<QuerySnapshot> getAssignedOrders() {
    if (_auth.currentUser == null) {
      throw Exception('User not authenticated');
    }

    return _firestore
        .collection('delivery_orders')
        .where('courierId', isEqualTo: _auth.currentUser!.uid)
        .snapshots();
  }

  // Get current active delivery
  Stream<DocumentSnapshot?> getCurrentDelivery() {
    if (_auth.currentUser == null) {
      throw Exception('User not authenticated');
    }

    return _firestore
        .collection('couriers')
        .doc(_auth.currentUser!.uid)
        .snapshots()
        .asyncMap((courierDoc) async {
      if (!courierDoc.exists) return null;
      
      Map<String, dynamic> courierData = courierDoc.data() as Map<String, dynamic>;
      String? currentOrderId = courierData['currentOrderId'];
      
      if (currentOrderId == null) return null;
      
      return await _firestore
          .collection('delivery_orders')
          .doc(currentOrderId)
          .get();
    });
  }

  // Update delivery status
  Future<String> updateDeliveryStatus(String orderId, String status) async {
    try {
      if (_auth.currentUser == null) {
        return 'User not authenticated';
      }

      // Get delivery order
      DocumentSnapshot deliveryDoc = await _firestore
          .collection('delivery_orders')
          .doc(orderId)
          .get();

      if (!deliveryDoc.exists) {
        return 'Delivery order not found';
      }

      Map<String, dynamic> deliveryData = deliveryDoc.data() as Map<String, dynamic>;
      
      // Verify courier ownership
      if (deliveryData['courierId'] != _auth.currentUser!.uid) {
        return 'Not authorized to update this delivery';
      }

      String currentStatus = deliveryData['status'];
      
      // Validate status transition
      if (!_isValidStatusTransition(currentStatus, status)) {
        return 'Invalid status transition from $currentStatus to $status';
      }

      // Start a batch write
      WriteBatch batch = _firestore.batch();

      // Update delivery order
      DocumentReference deliveryRef = _firestore.collection('delivery_orders').doc(orderId);
      Map<String, dynamic> updateData = {
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Add timestamp based on status
      switch (status) {
        case 'picked_up':
          updateData['pickedUpAt'] = FieldValue.serverTimestamp();
          break;
        case 'on_delivery':
          updateData['startedDeliveryAt'] = FieldValue.serverTimestamp();
          break;
        case 'delivered':
          updateData['deliveredAt'] = FieldValue.serverTimestamp();
          // Update courier stats
          await _updateCourierStats();
          break;
      }

      batch.update(deliveryRef, updateData);

      // Update main order status
      DocumentReference orderRef = _firestore.collection('orders').doc(orderId);
      batch.update(orderRef, {
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // If delivered, update courier availability
      if (status == 'delivered') {
        DocumentReference courierRef = _firestore.collection('couriers').doc(_auth.currentUser!.uid);
        batch.update(courierRef, {
          'isAvailable': true,
          'currentOrderId': FieldValue.delete(),
        });
      }

      // Send notifications
      await _sendStatusNotifications(orderId, status, deliveryData);

      // Commit the batch
      await batch.commit();

      return 'success';
    } catch (e) {
      return 'Error updating delivery status: $e';
    }
  }

  // Update courier statistics
  Future<void> _updateCourierStats() async {
    try {
      DocumentReference courierRef = _firestore.collection('couriers').doc(_auth.currentUser!.uid);
      
      await _firestore.runTransaction((transaction) async {
        DocumentSnapshot courierDoc = await transaction.get(courierRef);
        
        if (!courierDoc.exists) return;

        Map<String, dynamic> courierData = courierDoc.data() as Map<String, dynamic>;
        int totalDeliveries = (courierData['totalDeliveries'] ?? 0) + 1;
        
        transaction.update(courierRef, {
          'totalDeliveries': totalDeliveries,
        });
      });
    } catch (e) {
      print('Error updating courier stats: $e');
    }
  }

  // Helper method to validate status transitions
  bool _isValidStatusTransition(String currentStatus, String newStatus) {
    final validTransitions = {
      'picked_up': ['on_delivery'],
      'on_delivery': ['delivered'],
    };

    return validTransitions[currentStatus]?.contains(newStatus) ?? false;
  }

  // Helper method to send status notifications
  Future<void> _sendStatusNotifications(
    String orderId,
    String status,
    Map<String, dynamic> deliveryData,
  ) async {
    try {
      String notificationTitle = '';
      String notificationBody = '';

      switch (status) {
        case 'on_delivery':
          notificationTitle = 'Order On Delivery';
          notificationBody = 'Your order is on its way with ${deliveryData['courierName']}';
          break;
        case 'delivered':
          notificationTitle = 'Order Delivered';
          notificationBody = 'Your order has been delivered';
          break;
      }

      if (notificationTitle.isNotEmpty) {
        // Notify buyer
        await _firestore.collection('notifications').add({
          'userId': deliveryData['buyerId'],
          'title': notificationTitle,
          'body': notificationBody,
          'read': false,
          'createdAt': FieldValue.serverTimestamp(),
        });

        // Notify vendor
        await _firestore.collection('notifications').add({
          'userId': deliveryData['vendorId'],
          'title': notificationTitle,
          'body': 'Order #${orderId.substring(0, 8)} $notificationBody',
          'read': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      print('Error sending notifications: $e');
    }
  }
}
